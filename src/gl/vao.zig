const c = @import("c").c;
const GL = @import("gl.zig");
const VBO = @import("vbo.zig");

const VAO = @This();

handle: u32,

// fn Attrib(V: type, T: type)

pub fn init() VAO {
    var handle: u32 = undefined;
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
    _: *const VAO,
    T: type,
    idx: u32,
    elems: i32,
    stride: i32,
    offset: usize,
) !void {
    const ty = GL.DataType.from(T);

    c.glEnableVertexAttribArray(@truncate(idx));
    switch (ty) {
        .f32 => c.glVertexAttribPointer(
            idx,
            elems,
            @intFromEnum(ty), // type
            c.GL_FALSE, // normalized
            stride, // stride
            @ptrFromInt(offset), // offset
        ),
        .u32, .u16, .u8 => c.glVertexAttribIPointer(
            idx,
            elems,
            @intFromEnum(ty),
            stride,
            @ptrFromInt(offset),
        ),
        else => return error.UnsupportedParam,
    }
}
