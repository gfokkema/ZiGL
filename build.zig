const std = @import("std");

const CFlags = &.{};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // exe.addIncludePath(.{ .cwd_relative = "/usr/include/SDL3" });
    // exe.linkSystemLibrary("SDL3");
    const exe = b.addExecutable(.{
        .name = "learn-zig-4",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
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
