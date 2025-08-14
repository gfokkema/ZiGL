const std = @import("std");

const Options = struct {
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
};

pub fn build_c(b: *std.Build, o: Options) *std.Build.Module {
    const c = b.addModule("c", .{
        .optimize = o.o,
        .target = o.t,
        .link_libc = true,
        .link_libcpp = true,
        .root_source_file = b.path("src/c.zig"),
    });
    c.addCMacro("IMGUI_IMPL_API", "extern \"C\"");
    c.addIncludePath(b.path("res/cimgui"));
    c.addIncludePath(b.path("res/cimgui/generator/output"));
    c.addIncludePath(b.path("res/cimgui/imgui/backends"));
    c.addIncludePath(b.path("res/cimgui/imgui"));
    c.addIncludePath(b.path("res/stb"));
    c.addCSourceFiles(.{
        .files = &.{
            "res/cimgui/cimgui.cpp",
            "res/cimgui/imgui/imgui.cpp",
            "res/cimgui/imgui/imgui_draw.cpp",
            "res/cimgui/imgui/imgui_demo.cpp",
            "res/cimgui/imgui/imgui_tables.cpp",
            "res/cimgui/imgui/imgui_widgets.cpp",
            "res/cimgui/imgui/backends/imgui_impl_glfw.cpp",
            "res/cimgui/imgui/backends/imgui_impl_opengl3.cpp",
            "src/stb.c",
        },
    });
    c.linkSystemLibrary("epoxy", .{});
    c.linkSystemLibrary("glfw", .{});
    return c;
}

const Properties = struct {
    name: []const u8,
    source: []const u8,
    opt: Options,
    modules: []const struct {
        name: []const u8,
        module: *std.Build.Module,
    },
};

fn build_exe(b: *std.Build, p: Properties) void {
    const exe = b.addExecutable(.{
        .name = p.name,
        .root_source_file = b.path(p.source),
        .target = p.opt.t,
        .optimize = p.opt.o,
    });

    for (p.modules) |m| exe.root_module.addImport(m.name, m.module);

    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());

    const run_step = b.step(p.name, "Run the app");
    run_step.dependOn(&run.step);
}

pub fn build(b: *std.Build) void {
    const opt = Options{
        .t = b.standardTargetOptions(.{}),
        .o = b.standardOptimizeOption(.{}),
    };

    const c = build_c(b, opt);
    const zlm = b.dependency("zlm", .{});
    const zobj = b.dependency("zobj", .{});

    build_exe(b, .{
        .name = "glfw",
        .source = "src/glfw.zig",
        .opt = opt,
        .modules = &.{
            .{ .name = "c", .module = c },
            .{ .name = "zlm", .module = zlm.module("zlm") },
            .{ .name = "zobj", .module = zobj.module("obj") },
        },
    });

    build_exe(b, .{
        .name = "main",
        .source = "src/main.zig",
        .opt = opt,
        .modules = &.{
            .{ .name = "c", .module = c },
            .{ .name = "zlm", .module = zlm.module("zlm") },
            .{ .name = "zobj", .module = zobj.module("obj") },
        },
    });
}
