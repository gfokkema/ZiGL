const std = @import("std");

const CFlags = &.{};
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
    c.addIncludePath(b.path("cimgui"));
    c.addIncludePath(b.path("cimgui/generator/output"));
    c.addIncludePath(b.path("cimgui/imgui/backends"));
    c.addIncludePath(b.path("cimgui/imgui"));
    c.addCSourceFiles(.{
        .files = &.{
            "cimgui/cimgui.cpp",
            "cimgui/imgui/imgui.cpp",
            "cimgui/imgui/imgui_draw.cpp",
            "cimgui/imgui/imgui_demo.cpp",
            "cimgui/imgui/imgui_tables.cpp",
            "cimgui/imgui/imgui_widgets.cpp",
            "cimgui/imgui/backends/imgui_impl_glfw.cpp",
            "cimgui/imgui/backends/imgui_impl_opengl3.cpp",
        },
    });
    c.linkSystemLibrary("epoxy", .{});
    c.linkSystemLibrary("glfw", .{});
    return c;
}

pub fn build(b: *std.Build) void {
    const opt = .{
        .t = b.standardTargetOptions(.{}),
        .o = b.standardOptimizeOption(.{}),
    };

    const c = build_c(b, opt);
    const zlm = b.dependency("zlm", .{});
    const zobj = b.dependency("zobj", .{});

    // const exe = build_exe(b, opt);
    // exe.root_module.addImport("c", c);
    // b.installArtifact(exe);

    const exe = b.addExecutable(.{
        .name = "glfw",
        .root_source_file = b.path("src/glfw.zig"),
        .target = opt.t,
        .optimize = opt.o,
    });
    exe.root_module.addImport("c", c);
    exe.root_module.addImport("zlm", zlm.module("zlm"));
    exe.root_module.addImport("zobj", zobj.module("obj"));
    exe.addIncludePath(b.path("stb"));
    exe.addCSourceFile(.{ .file = b.path("src/stb.c") });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
