const std = @import("std");
const httpz = @import("httpz");
const okredis = @import("okredis");

const COMMUNITY_COUNTER = "community_counter";

const Context = struct {
    allocator: std.mem.Allocator,
    redis_client_pool: RedisClientPool,
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
    pool: std.ArrayList(RedisClient),
    mut: std.Thread.Mutex,

    fn init(allocator: std.mem.Allocator, n: u32, addrs: []std.net.Address) !RedisClientPool {
        var pool = RedisClientPool{ .pool = .{}, .mut = .{} };
        for (0..n) |_| {
            var stderr_buffer: [1024]u8 = undefined;
            var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
            const stderr = &stderr_writer.interface;
            try stderr.print("  Resolved redis address: ", .{});

            var connection: ?std.net.Stream = null;
            for (addrs) |addr| {
                try stderr.print("  Trying to connect to address:", .{});
                try addr.format(stderr);
                try stderr.print("\n", .{});
                try stderr.flush();
                connection = std.net.tcpConnectToAddress(addr) catch continue;
                break;
            }
            if (connection == null) {
                try stderr.print("  Unable to find connection to backend redis server.\n", .{});
                try stderr.flush();
                return error.UnableToConnect;
            }
            const client = try pool.pool.addOne(allocator);
            client.client = try okredis.Client.init(connection.?, .{
                .reader_buffer = &client.read_buffer,
                .writer_buffer = &client.write_buffer,
            });
        }

        return pool;
    }

    fn deinit(self: *RedisClientPool, allocator: std.mem.Allocator) void {
        for (self.pool.items) |client| {
            client.client.close();
        }
        self.pool.deinit(allocator);
    }

    fn reserve(self: *RedisClientPool) ?RedisClient {
        self.mut.lock();
        defer self.mut.unlock();
        return self.pool.pop();
    }

    fn release(self: *RedisClientPool, allocator: std.mem.Allocator, client: RedisClient) !void {
        self.mut.lock();
        defer self.mut.unlock();
        try self.pool.append(allocator, client);
    }
};

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

    var context = Context{ .allocator = allocator, .redis_client_pool = redis_client_pool };
    defer context.redis_client_pool.deinit(allocator);

    std.log.info("Hello, world!\n  Listening on port: {d}\n  Requested redis server: {s}:{d}", .{ config.port, config.redis_ip, config.redis_port });

    var server = try httpz.Server(*Context).init(allocator, server_config, &context);
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});

    router.post("/increment_counter", increment_counter, .{});
    router.get("/get_count", get_count, .{});

    try server.listen();
}

fn increment_counter(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    const cmd = okredis.commands.strings.INCR.init(COMMUNITY_COUNTER);
    var redis_client = ctx.redis_client_pool.reserve() orelse {
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

fn get_count(ctx: *Context, _: *httpz.Request, res: *httpz.Response) !void {
    const cmd = okredis.commands.strings.GET.init(COMMUNITY_COUNTER);
    var redis_client = ctx.redis_client_pool.reserve() orelse {
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
