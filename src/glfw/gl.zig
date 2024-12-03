const std = @import("std");
const Allocator = std.mem.Allocator;

pub const c = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("epoxy/glx.h");
});

pub const VAO = @import("vao.zig");
pub const VBO = @import("vbo.zig");
pub const Program = @import("program.zig");
pub const Shader = @import("shader.zig");

const Color = struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,
};

const GL = @This();

const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

program: Program,
vao: VAO,
vbo: VBO,

pub fn init(alloc: Allocator, vs: []const u8, fs: []const u8) !GL {
    const program = try Program.init_path(alloc, vs, fs);
    const vao = GL.VAO.init();
    const vbo = GL.VBO.init(.Array);

    vao.attrib(&vbo, 0, 3);
    vbo.upload(f32, &vertices);

    return .{
        .program = program,
        .vao = vao,
        .vbo = vbo,
    };
}

pub fn deinit(self: *GL) void {
    defer self.vbo.deinit();
    defer self.vao.deinit();
    defer self.program.deinit();
}

pub fn clearColor(_: *GL, color: Color) void {
    c.glClearColor(color.r, color.g, color.b, color.a);
}

pub fn clear(_: *GL) void {
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn draw(self: *GL) void {
    self.program.use();
    self.vao.bind();
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    self.vao.unbind();
}
