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

pub fn build_exe(b: *std.Build, o: Options) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = o.t,
        .optimize = o.o,
    });
}

pub fn build_gtk(b: *std.Build, o: Options) *std.Build.Step.Compile {
    const gobject = b.dependency("gobject", .{
        .target = o.t,
        .optimize = o.o,
    });

    const exe = b.addExecutable(.{
        .name = "gtk",
        .root_source_file = b.path("src/gtk.zig"),
        .target = o.t,
        .optimize = o.o,
    });
    exe.linkLibC();
    exe.root_module.addImport("glib", gobject.module("glib2"));
    exe.root_module.addImport("gobject", gobject.module("gobject2"));
    exe.root_module.addImport("gio", gobject.module("gio2"));
    exe.root_module.addImport("cairo", gobject.module("cairo1"));
    exe.root_module.addImport("pango", gobject.module("pango1"));
    exe.root_module.addImport("pangocairo", gobject.module("pangocairo1"));
    exe.root_module.addImport("gdk", gobject.module("gdk4"));
    exe.root_module.addImport("gtk", gobject.module("gtk4"));
    return exe;
}

pub fn build_glfw(b: *std.Build, o: Options) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = "glfw",
        .root_source_file = b.path("src/glfw.zig"),
        .target = o.t,
        .optimize = o.o,
    });
}

// exe.addIncludePath(.{ .cwd_relative = "/usr/include/SDL3" });
// exe.linkSystemLibrary("SDL3");
pub fn build(b: *std.Build) void {
    const opt = .{
        .t = b.standardTargetOptions(.{}),
        .o = b.standardOptimizeOption(.{}),
    };

    const c = build_c(b, opt);

    const exe = build_exe(b, opt);
    exe.root_module.addImport("c", c);
    b.installArtifact(exe);

    const glfw_exe = build_glfw(b, opt);
    glfw_exe.root_module.addImport("c", c);
    b.installArtifact(glfw_exe);

    const run_cmd = b.addRunArtifact(glfw_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
