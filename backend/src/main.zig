const std = @import("std");
const httpz = @import("httpz");

const Config = struct {
    port: u16 = 0,
};

fn usage() void {
    std.debug.print("Usage: backend --port <number>\n\n", .{});
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
            const port_str = args.next() orelse {
                usage();
                std.log.err("Expected a port number after --port", .{});
                return error.MissingPortValue;
            };
            config.port = std.fmt.parseInt(u16, port_str, 10) catch |err| switch (err) {
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
        } else if (std.mem.eql(u8, arg, "--help")) {
            usage();
        } else {
            std.log.warn("Unknown argument: {s}, this is not being used", .{arg});
        }
    }

    std.log.info("Hello, world! Got --port={d}", .{config.port});

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
