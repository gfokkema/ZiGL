const std = @import("std");

const CFlags = &.{};
const Options = struct {
    t: std.Build.ResolvedTarget,
    o: std.builtin.OptimizeMode,
};

pub fn build_exe(b: *std.Build, o: Options) void {
    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = o.t,
        .optimize = o.o,
    });
    exe.addCSourceFiles(.{
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
    exe.addIncludePath(b.path("cimgui"));
    exe.addIncludePath(b.path("cimgui/generator/output"));
    exe.addIncludePath(b.path("cimgui/imgui/backends"));
    exe.addIncludePath(b.path("cimgui/imgui"));
    exe.defineCMacro("IMGUI_IMPL_API", "extern \"C\"");

    exe.linkLibC();
    exe.linkLibCpp();
    exe.linkSystemLibrary("epoxy");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("imgui");
    b.installArtifact(exe);
}

pub fn build_gtk(b: *std.Build, o: Options) void {
    const gobject = b.dependency("gobject", .{
        .target = o.t,
        .optimize = o.o,
    });

    const gtk_exe = b.addExecutable(.{
        .name = "gtk",
        .root_source_file = b.path("src/gtk.zig"),
        .target = o.t,
        .optimize = o.o,
    });
    gtk_exe.linkLibC();
    gtk_exe.linkSystemLibrary("epoxy");
    gtk_exe.root_module.addImport("glib", gobject.module("glib2"));
    gtk_exe.root_module.addImport("gobject", gobject.module("gobject2"));
    gtk_exe.root_module.addImport("gio", gobject.module("gio2"));
    gtk_exe.root_module.addImport("cairo", gobject.module("cairo1"));
    gtk_exe.root_module.addImport("pango", gobject.module("pango1"));
    gtk_exe.root_module.addImport("pangocairo", gobject.module("pangocairo1"));
    gtk_exe.root_module.addImport("gdk", gobject.module("gdk4"));
    gtk_exe.root_module.addImport("gtk", gobject.module("gtk4"));
    b.installArtifact(gtk_exe);
}

// exe.addIncludePath(.{ .cwd_relative = "/usr/include/SDL3" });
// exe.linkSystemLibrary("SDL3");
pub fn build(b: *std.Build) void {
    const opt = .{
        .t = b.standardTargetOptions(.{}),
        .o = b.standardOptimizeOption(.{}),
    };
    build_exe(b, opt);
    build_gtk(b, opt);
}
