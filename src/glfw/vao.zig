const c = @import("c");
const GL = @import("gl.zig");
const VBO = @import("vbo.zig");
const VAO = @This();

handle: c_uint,

pub fn init() VAO {
    var handle: c_uint = undefined;
    c.glGenVertexArrays(1, &handle);
    return .{ .handle = handle };
}

pub fn deinit(self: *const VAO) void {
    c.glDeleteVertexArrays(1, &self.handle);
}

pub fn bind(self: *const VAO) void {
    c.glBindVertexArray(self.handle);
}

pub fn unbind(_: *const VAO) void {
    c.glBindVertexArray(0);
}

pub fn attrib(
    self: *const VAO,
    T: type,
    vbo: *const VBO,
    idx: usize,
    elems: usize,
    stride: usize,
    offset: usize,
) void {
    self.bind();
    defer self.unbind();

    vbo.bind();
    defer vbo.unbind();

    c.glEnableVertexAttribArray(@truncate(idx));
    c.glVertexAttribPointer(
        @truncate(idx),
        @as(c_int, @intCast(elems)),
        @intFromEnum(GL.Type.as(T)), // type
        c.GL_FALSE, // normalized
        @intCast(stride), // stride
        @ptrFromInt(offset), // offset
    );
}
