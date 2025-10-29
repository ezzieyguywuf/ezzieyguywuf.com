const std = @import("std");
const httpz = @import("httpz");
const okredis = @import("okredis");

const Config = struct {
    port: u16 = 0,
    redis_ip: []const u8 = "",
    redis_port: u16 = 0,
};

fn usage() void {
    std.debug.print("Usage: backend --port <number> --redis_server <ip> --redis_port <port>\n\n", .{});
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
    // const redis_ip = try std.net.Address.resolveIp(config.redis_ip, config.redis_port);
    const addresses = try std.net.getAddressList(allocator, config.redis_ip, config.redis_port);
    defer addresses.deinit();
    if (addresses.addrs.len == 0) {
        std.log.err("Did not resolve '{s}:{d}' to any ip addresses", .{ config.redis_ip, config.redis_port });
    }
    const addr_index = std.crypto.random.intRangeLessThan(usize, 0, addresses.addrs.len);
    const address = addresses.addrs[addr_index];
    std.log.info("Hello, world!\n  Listening on port: {d}\n  Requested redis server: {s}:{d}", .{ config.port, config.redis_ip, config.redis_port });

    var stderr_buffer: [1024]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;
    try stderr.print("  Resolved redis address: ", .{});
    try address.format(stderr);
    try stderr.print("\n", .{});
    try stderr.flush();

    var server = try httpz.Server(void).init(allocator, .{
        .port = config.port,
        .request = .{},
    }, {});
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});

    router.post("/increment_counter", increment_counter, .{});

    try server.listen();
}

fn increment_counter(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
}
