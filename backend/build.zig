const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "backend",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const httpz_dep = b.dependency("httpz", .{}).module("httpz");
    exe.root_module.addImport("httpz", httpz_dep);

    const okredis_dep = b.dependency("okredis", .{}).module("okredis");
    exe.root_module.addImport("okredis", okredis_dep);

    const hiredis_path = "../vendor/hiredis-1.3.0";

    const hiredis_lib = b.addLibrary(.{
        .name = "hiredis",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/hiredis.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });

    hiredis_lib.addCSourceFiles(.{
        .files = &.{
            hiredis_path ++ "/alloc.c",
            hiredis_path ++ "/async.c",
            hiredis_path ++ "/hiredis.c",
            hiredis_path ++ "/net.c",
            hiredis_path ++ "/read.c",
            hiredis_path ++ "/sds.c",
            hiredis_path ++ "/sockcompat.c",
        },
    });

    hiredis_lib.addIncludePath(b.path(hiredis_path));
    // hiredis_lib.linkLibC();

    exe.linkLibrary(hiredis_lib);
    exe.addIncludePath(b.path(hiredis_path));

    // if (exe.target.isWindows()) {
    //     hiredis_lib.addCSourceFlags("-DWIN32_LEAN_AND_MEAN");
    //     exe.linkSystemLibrary("ws2_32");
    // }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
