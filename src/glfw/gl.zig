const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const VAO = @import("vao.zig");
pub const VBO = @import("vbo.zig");
pub const Program = @import("program.zig");
pub const Shader = @import("shader.zig");
pub const Texture = @import("texture.zig");

const Color = struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,
};

pub const DrawMode = enum(u16) {
    GL_POINTS = c.GL_POINTS,
    GL_TRIANGLES = c.GL_TRIANGLES,
};

pub const ClearMode = enum(u16) {
    GL_COLOR = c.GL_COLOR_BUFFER_BIT,
    GL_DEPTH = c.GL_DEPTH_BUFFER_BIT,
    GL_STENCIL = c.GL_STENCIL_BUFFER_BIT,
};

const State = struct {
    program: ?Program = undefined,
};

const GL = @This();

state: State = .{},

pub fn clearColor(color: Color) void {
    c.glClearColor(color.r, color.g, color.b, color.a);
}

pub fn clear() void {
    c.glClear(@intFromEnum(ClearMode.GL_COLOR));
}

pub fn draw(mode: DrawMode) void {
    c.glDrawArrays(@intFromEnum(mode), 0, 6);
}

pub fn program(alloc: Allocator, vs_path: []const u8, fs_path: []const u8) !Program {
    var vs = try Shader.init_path(alloc, .VS, vs_path);
    defer vs.deinit();

    var fs = try Shader.init_path(alloc, .FS, fs_path);
    defer fs.deinit();

    var p = try Program.init();
    p.link(vs, fs) catch |e| {
        p.log();
        std.debug.panic("Program: {any}\n", .{e});
    };
    return p;
}

pub fn texture() Texture {
    return Texture.init();
}
