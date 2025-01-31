const c = @import("c");
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
    vbo: *const VBO,
    idx: usize,
    elems: usize,
) void {
    self.bind();
    defer self.unbind();

    vbo.bind();
    defer vbo.unbind();

    c.glVertexAttribPointer(
        @truncate(idx),
        @as(c_int, @intCast(elems)),
        c.GL_FLOAT, // type
        c.GL_FALSE, // normalized
        3 * @sizeOf(f32), // stride
        null, // offset
    );
    c.glEnableVertexAttribArray(@truncate(idx));
}
