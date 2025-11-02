const std = @import("std");
const httpz = @import("httpz");
const okredis = @import("okredis");
const hiredis = @import("hiredis.zig");

const COMMUNITY_COUNTER = "community_counter";
// const COUNTER_CHANNEL = "community_counter_channel";

const Context = struct {
    allocator: std.mem.Allocator,
    redis_client_pool: RedisClientPool,
    listener_registry: SSEListenerRegistry,
};

const Config = struct {
    port: u16 = 0,
    redis_ip: []const u8 = "",
    redis_port: u16 = 0,
};

fn usage() void {
    std.debug.print("Usage: backend --port <number> --redis_server <ip> --redis_port <port>\n\n", .{});
}

const RedisClient = struct {
    read_buffer: [1024]u8,
    write_buffer: [1024]u8,
    client: okredis.Client,
};

const RedisClientPool = struct {
    pool: std.ArrayList(*RedisClient),
    mut: std.Thread.Mutex,
    total_clients: u64,
    addrs: []std.net.Address,

    fn init(allocator: std.mem.Allocator, n: u32, addrs: []std.net.Address) !RedisClientPool {
        var pool = RedisClientPool{
            .pool = .{},
            .mut = .{},
            .total_clients = 0,
            .addrs = addrs,
        };
        for (0..n) |_| {
            try pool._add_client(allocator);
        }

        return pool;
    }

    fn _add_client(self: *RedisClientPool, allocator: std.mem.Allocator) !void {
        var connection: ?std.net.Stream = null;
        for (self.addrs) |addr| {
            connection = std.net.tcpConnectToAddress(addr) catch continue;
            break;
        }
        if (connection == null) {
            std.log.err("Unable to find connection to backend redis server.\n", .{});
            return error.UnableToConnect;
        }
        const client = try allocator.create(RedisClient);
        errdefer allocator.destroy(client);
        client.client = try okredis.Client.init(connection.?, .{
            .reader_buffer = &client.read_buffer,
            .writer_buffer = &client.write_buffer,
        });
        try self.pool.append(allocator, client);
        self.total_clients += 1;
    }

    fn deinit(self: *RedisClientPool, allocator: std.mem.Allocator) void {
        for (self.pool.items) |client| {
            client.client.close();
            allocator.destroy(client);
        }
        self.pool.deinit(allocator);
    }

    fn reserve(self: *RedisClientPool, allocator: std.mem.Allocator) ?*RedisClient {
        self.mut.lock();
        defer self.mut.unlock();
        if (self.pool.items.len == 0) {
            if (self.total_clients >= 64) {
                std.log.err("Redis client pool is exhausted, but it's too big. Not creating a new one. total: {d}", .{self.total_clients});
                return null;
            }
            self.total_clients += 1;
            std.log.info("Redis client pool is exhausted, creating a new one. total: {d}", .{self.total_clients});
            self._add_client(allocator) catch return null;
        }
        return self.pool.pop();
    }

    fn release(self: *RedisClientPool, allocator: std.mem.Allocator, client: *RedisClient) !void {
        self.mut.lock();
        defer self.mut.unlock();
        try self.pool.append(allocator, client);
    }
};

fn pubsub_listener(allocator: std.mem.Allocator, redis_ip: []const u8, redis_port: u16, registry: *SSEListenerRegistry) !void {
    var hiredis_subscribe_ctx = try hiredis.Context.connect(allocator, redis_ip, redis_port);
    defer hiredis_subscribe_ctx.deinit();

    // Subscribe to a channel and consume the initial reply
    var subscribe_cmd = hiredis.RedisAsyncSubscribe{ .cmd = "SUBSCRIBE community_counter_channel" };
    try hiredis_subscribe_ctx.subscribe(&subscribe_cmd);

    var last_heartbeat = std.time.nanoTimestamp();
    while (true) {
        hiredis_subscribe_ctx.tick();

        if (subscribe_cmd.getReply()) |reply| {
            try registry.broadcast(allocator, reply);
        }

        if (std.time.nanoTimestamp() - last_heartbeat >= std.time.ns_per_s) {
            try registry.heartbeat(allocator);
            last_heartbeat = std.time.nanoTimestamp();
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config = Config{};
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    // first arg is the executable path
    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--port")) {
            const port_str = try parseNext(&args, "--port");
            config.port = try parsePort(port_str);
        } else if (std.mem.eql(u8, arg, "--redis_server")) {
            config.redis_ip = try parseNext(&args, "--redis_server");
        } else if (std.mem.eql(u8, arg, "--redis_port")) {
            const port_str = try parseNext(&args, "--redis_port");
            config.redis_port = try parsePort(port_str);
        } else if (std.mem.eql(u8, arg, "--help")) {
            usage();
        } else {
            std.log.warn("Unknown argument: {s}, this is not being used", .{arg});
        }
    }

    const addresses = try std.net.getAddressList(allocator, config.redis_ip, config.redis_port);
    defer addresses.deinit();
    if (addresses.addrs.len == 0) {
        std.log.err("Did not resolve '{s}:{d}' to any ip addresses", .{ config.redis_ip, config.redis_port });
    }

    const server_config = httpz.Config{
        .port = config.port,
        .request = .{},
    };
    const redis_client_pool = try RedisClientPool.init(allocator, server_config.workerCount(), addresses.addrs);

    var context = Context{
        .allocator = allocator,
        .redis_client_pool = redis_client_pool,
        .listener_registry = SSEListenerRegistry.init(),
    };
    defer context.redis_client_pool.deinit(allocator);

    // --- Pub/Sub Listener Thread ---
    const pubsub_thread = try std.Thread.spawn(.{}, pubsub_listener, .{ allocator, config.redis_ip, config.redis_port, &context.listener_registry });
    // In a real app, you might not join immediately, but for this demo it's fine.
    // If the main thread exits, this child thread will be terminated.
    // defer pubsub_thread.join();
    _ = pubsub_thread; // To avoid unused variable warning
    // --- End Pub/Sub Listener Thread ---

    std.log.info("Hello, world!\n  Listening on port: {d}\n  Requested redis server: {s}:{d}", .{ config.port, config.redis_ip, config.redis_port });

    var server = try httpz.Server(*Context).init(allocator, server_config, &context);
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});

    router.post("/increment_counter", increment_counter, .{});
    router.get("/get_count", get_count, .{});
    router.get("/listen_count", listen_count, .{});

    try server.listen();
}

fn increment_counter(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    const cmd = okredis.commands.strings.INCR.init(COMMUNITY_COUNTER);
    var redis_client = ctx.redis_client_pool.reserve(ctx.allocator) orelse {
        res.setStatus(std.http.Status.internal_server_error);
        try res.json(.{ .err = "Unable to get redis client from pool" }, .{});
        std.log.err("Unable to get redis client from pool", .{});
        return;
    };
    const reply = try redis_client.client.sendAlloc(okredis.types.OrFullErr(i64), res.arena, cmd);

    var total: ?i64 = null;
    switch (reply) {
        .Ok => |val| {
            res.setStatus(std.http.Status.ok);
            try res.json(.{ .totalCount = val }, .{});
            total = val;
        },
        .Nil => {
            res.setStatus(std.http.Status.internal_server_error);
            try res.json(.{ .err = "Redis unexpectedly returned Nil" }, .{});
            std.log.err("Redis unexpectedly returned Nil", .{});
        },
        .Err => |err| {
            res.setStatus(std.http.Status.internal_server_error);
            try res.json(.{ .err = err.message }, .{});
            std.log.err("Some other error {any}", .{err});
        },
    }

    if (total) |val| {
        _ = try redis_client.client.sendAlloc(okredis.types.OrFullErr(void), res.arena, .{ "PUBLISH", "community_counter_channel", val });
    }

    try ctx.redis_client_pool.release(ctx.allocator, redis_client);

    // trailing newline makes e.g. curl output friendlier on the command line
    try res.writer().writeByte('\n');
}

fn get_count(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    const cmd = okredis.commands.strings.GET.init(COMMUNITY_COUNTER);
    var redis_client = ctx.redis_client_pool.reserve(ctx.allocator) orelse {
        res.setStatus(std.http.Status.internal_server_error);
        try res.json(.{ .err = "Unable to get redis client from pool" }, .{});
        return;
    };
    const reply = try redis_client.client.sendAlloc(okredis.types.OrFullErr(i64), res.arena, cmd);
    try ctx.redis_client_pool.release(ctx.allocator, redis_client);

    switch (reply) {
        .Ok => |val| {
            res.setStatus(std.http.Status.ok);
            try res.json(.{ .totalCount = val }, .{});
        },
        .Nil => {
            res.setStatus(std.http.Status.internal_server_error);
            try res.json(.{ .err = "Redis unexpectedly returned Nil" }, .{});
        },
        .Err => |err| {
            res.setStatus(std.http.Status.internal_server_error);
            try res.json(.{ .err = err.message }, .{});
        },
    }
    // trailing newline makes e.g. curl output friendlier on the command line
    try res.writer().writeByte('\n');
}

const SSEListener = struct {
    registry_index: usize = 0,
    buf: [128]u8 = undefined,
    stream: std.net.Stream,

    // returns whether the write succeeded
    fn try_write(self: *SSEListener, str: []const u8) bool {
        var writer = self.stream.writer(&self.buf);
        _ = writer.interface.print("data: {s}\n\n", .{str}) catch |err| {
            switch (err) {
                error.WriteFailed => return false,
            }
        };
        writer.interface.flush() catch |err| {
            switch (err) {
                error.WriteFailed => return false,
            }
        };
        return true;
    }

    fn deinit(self: *SSEListener) void {
        self.stream.close();
    }
};

const SSEListenerRegistry = struct {
    mut: std.Thread.Mutex,
    listeners: std.AutoHashMapUnmanaged(std.net.Stream.Handle, SSEListener),

    fn init() SSEListenerRegistry {
        return .{
            .mut = .{},
            .listeners = .{},
        };
    }

    fn deinit(self: *SSEListenerRegistry, allocator: std.mem.Allocator) void {
        for (self.listeners) |listener| {
            listener.deinit();
        }
        self.listeners.deinit(allocator);
    }

    fn broadcast(self: *SSEListenerRegistry, allocator: std.mem.Allocator, msg: []u8) !void {
        self.mut.lock();
        defer self.mut.unlock();

        var keys = std.ArrayList(std.net.Stream.Handle){};
        defer keys.deinit(allocator);
        var it = self.listeners.keyIterator();
        while (it.next()) |key| {
            try keys.append(allocator, key.*);
        }
        for (keys.items) |key| {
            var listener = self.listeners.getPtr(key).?;
            if (!listener.try_write(msg)) {
                std.log.err("Unable to write message to listener", .{});
            }
        }
    }

    fn heartbeat(self: *SSEListenerRegistry, allocator: std.mem.Allocator) !void {
        self.mut.lock();
        defer self.mut.unlock();

        var keys = std.ArrayList(std.net.Stream.Handle){};
        defer keys.deinit(allocator);
        var it = self.listeners.keyIterator();
        while (it.next()) |key| {
            try keys.append(allocator, key.*);
        }
        for (keys.items) |key| {
            var listener = self.listeners.get(key).?;
            if (!listener.try_write(": heartbeat\n\n")) {
                std.log.info("Failed to write heartbeat, assuming connection closed", .{});
                _ = self.listeners.remove(key);
                continue;
            }
        }
    }

    // We take ownership of the listener
    fn add(self: *SSEListenerRegistry, allocator: std.mem.Allocator, listener: SSEListener) !void {
        self.mut.lock();
        defer self.mut.unlock();

        try self.listeners.put(allocator, listener.stream.handle, listener);
    }
};

fn listen_count(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    const listener = SSEListener{
        .stream = try res.startEventStreamSync(),
        .buf = undefined,
    };

    try ctx.listener_registry.add(ctx.allocator, listener);
    std.log.info("SSE demo client connected.", .{});
}

fn parsePort(port_str: []const u8) !u16 {
    return std.fmt.parseInt(u16, port_str, 10) catch |err| switch (err) {
        error.Overflow => {
            usage();
            std.log.err("Port number '{s}' is out of the valid range (0-65535).", .{port_str});
            std.process.exit(1);
            return error.Overflow;
        },
        error.InvalidCharacter => {
            usage();
            std.log.err("String '{s}' cannot be converted to an integer", .{port_str});
            return error.InvalidCharacter;
        },
    };
}

fn parseNext(args: *std.process.ArgIterator, flag: []const u8) ![:0]const u8 {
    return args.next() orelse {
        usage();
        std.log.err("Expected a port number after {s}", .{flag});
        return error.MissingPortValue;
    };
}
