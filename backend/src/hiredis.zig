const std = @import("std");

// TODO: I'd prefer to import as hiredis/hiredis.h and hiredis/async.h
pub const hiredis = @cImport({
    @cInclude("hiredis.h");
    @cInclude("async.h");
    @cInclude("adapters/poll.h");
});

pub const RedisAsyncConnectStatus = struct {
    // null = awaiting callback, false = error, true = success
    success: ?bool = null,
    mut: std.Thread.Mutex = .{},
};

pub fn asyncRedisConnectCallback(ctx: [*c]const hiredis.struct_redisAsyncContext, status: c_int) callconv(.c) void {
    std.debug.print("connect callback reached!\n", .{});
    var connection_status: *RedisAsyncConnectStatus = @ptrCast(@alignCast(ctx.*.data));
    connection_status.mut.lock();
    defer connection_status.mut.unlock();

    connection_status.success = false;
    if (status == hiredis.REDIS_OK) {
        connection_status.success = true;
    }
    std.debug.print("  status: {any}\n", .{connection_status.success});
}

pub const RedisAsyncSubscribe = struct {
    // The RESP command to execute
    cmd: [*:0]const u8,
    mut: std.Thread.Mutex = .{},
    reply: [256]u8 = undefined,
    reply_len: usize = 0,
    reply_ready: bool = false,
    reply_error: bool = false,

    pub fn getReply(self: *RedisAsyncSubscribe) ?[]u8 {
        self.mut.lock();
        defer self.mut.unlock();
        if (!self.reply_ready) {
            return null;
        }
        var resp: ?[]u8 = null;
        if (!self.reply_error) {
            resp = self.reply[0..self.reply_len];
        }

        // reset
        self.reply_ready = false;
        self.reply_error = false;

        return resp;
    }
};

pub fn subscribe_callback(_: [*c]hiredis.struct_redisAsyncContext, reply_opaque: ?*anyopaque, data: ?*anyopaque) callconv(.c) void {
    if (reply_opaque == null) {
        std.log.err("Expected non-null reply in SUBSCRIBE callback", .{});
        return;
    }
    // Cast the opaque pointer to the known type once
    const reply_typed = @as(*hiredis.redisReply, @ptrCast(@alignCast(reply_opaque.?)));

    if (reply_typed.type != hiredis.REDIS_REPLY_ARRAY or reply_typed.elements != 3) {
        std.log.err("For a SUBSCRIBE callback, we expect the reply type to be an array with three elements. Instead, got {d} type and {d} elements", .{ reply_typed.type, reply_typed.elements });
        return;
    }
    if (reply_typed.element[0] == null or reply_typed.element[1] == null or reply_typed.element[2] == null) {
        std.log.err("Expected non-null elements in SUBSCRIBE reply. Got e1: {any}, e2: {any}, e3: {any}", .{ reply_typed.element[0], reply_typed.element[1], reply_typed.element[2] });
        return;
    }
    if (data == null) {
        std.log.err("Hiredis gave us a null data in command_callback - this is unexpected", .{});
        return;
    }
    const redis_async_command: *RedisAsyncSubscribe = @ptrCast(@alignCast(data.?));
    redis_async_command.mut.lock();
    defer redis_async_command.mut.unlock();

    const type_str = reply_typed.element[0].*.str[0..reply_typed.element[0].*.len];
    const is_message = std.mem.eql(u8, type_str, "message");
    const is_subscribe = std.mem.eql(u8, type_str, "subscribe");
    if (!is_message and !is_subscribe) {
        std.log.err("Expected \"message\" or \"subscribe\" type in SUBSCRIBE response, got {s}", .{type_str});
        redis_async_command.reply_error = true;
        redis_async_command.reply_ready = true;
        return;
    }

    if (is_subscribe) {
        const msg = "subscribe successful!";
        for (0.., msg) |idx, c| {
            redis_async_command.reply[idx] = c;
        }
        redis_async_command.reply_len = msg.len;
        redis_async_command.reply_ready = true;
        return;
    }

    // const channel_str = reply_typed.element[1].*.str[0..reply_typed.element[1].*.len];
    const reply_str = reply_typed.element[2].*.str;
    const reply_str_len = reply_typed.element[2].*.len;
    if (reply_str_len > redis_async_command.reply.len) {
        std.log.err("Reply is too long: got {d} bytes, buffer is {d} bytes big. reply: {s}", .{ reply_str_len, redis_async_command.reply.len, reply_str });
        redis_async_command.reply_error = true;
        redis_async_command.reply_ready = true;
        return;
    }

    for (0..reply_str_len) |idx| {
        redis_async_command.reply[idx] = reply_str[idx];
    }
    redis_async_command.reply_len = reply_str_len;

    redis_async_command.reply_ready = true;
}

pub const Context = struct {
    ptr: [*c]hiredis.redisAsyncContext,

    pub fn connect(allocator: std.mem.Allocator, ip: []const u8, port: u16) !Context {
        const ip_cstr = try allocator.dupeZ(u8, ip);
        defer allocator.free(ip_cstr);

        const ctx_ptr = hiredis.redisAsyncConnect(ip_cstr.ptr, @intCast(port));

        if (hiredis.redisPollAttach(ctx_ptr) != hiredis.REDIS_OK) {
            return error.RedisPollAttachFailed;
        }
        if (hiredis.redisAsyncSetConnectCallback(ctx_ptr, asyncRedisConnectCallback) != hiredis.REDIS_OK) {
            return error.RedisAttachConnectCallbackFailed;
        }
        var connection_status = RedisAsyncConnectStatus{};
        ctx_ptr.*.data = &connection_status;

        // The connection also happens asynchronously, so wait until it succeeds
        // or fails
        var ctx = Context{ .ptr = ctx_ptr };
        while (true) {
            ctx.tick();

            connection_status.mut.lock();
            defer connection_status.mut.unlock();

            if (connection_status.success) |success| {
                if (!success) {
                    if (ctx_ptr) |p| {
                        std.log.err("Hiredis connection error: {s}", .{p.*.errstr});
                        hiredis.redisAsyncFree(p);
                    } else {
                        std.log.err("Hiredis connection error: can't allocate redis context", .{});
                    }
                    return error.RedisConnectionFailed;
                }
                break;
            }

            std.Thread.sleep(100 * std.time.ns_per_ms);
        }
        return ctx;
    }

    pub fn deinit(self: *Context) void {
        hiredis.redisAsyncFree(self.ptr);
    }

    pub fn subscribe(self: *Context, cmd: *RedisAsyncSubscribe) !void {
        const ret = hiredis.redisAsyncCommand(self.ptr, subscribe_callback, cmd, cmd.cmd);
        if (ret != hiredis.REDIS_OK) {
            return error.RedisAsyncCommandFailed;
        }
    }

    pub fn tick(self: *Context) void {
        // return is bitmask of e.g. HANDLED_READ, HANDLED_WRITE, but we
        // don't care
        _ = hiredis.redisPollTick(self.ptr, 0.1);
    }

    pub fn broadcast(self: *Context, channel: []const u8, message: []const u8) !void {
        const ret = hiredis.redisAsyncCommand(self.ptr, null, null, "PUBLISH %s %s", channel.ptr, message.ptr);
        if (ret != hiredis.REDIS_OK) {
            return error.RedisAsyncCommandFailed;
        }
    }
};
