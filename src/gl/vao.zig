const c = @import("c").c;
const GL = @import("gl.zig");
const VBO = @import("vbo.zig");

const VAO = @This();

handle: u32,

pub const Attribs = struct {
    const Element = struct {
        elems: i32,
        size: usize,
        gl_type: GL.DataType,
    };

    stride: i32,
    elements: []const Element,

    fn offset(self: Attribs, index: usize) usize {
        var total: usize = 0;
        for (self.elements, 0..) |e, i| {
            if (i >= index) break;
            total += e.size;
        }
        return total;
    }
};

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

pub fn attribs(self: VAO, vbo: anytype, attrs: Attribs) !void {
    self.bind();
    vbo.bind();
    for (attrs.elements, 0..) |a, a_idx| {
        c.glEnableVertexAttribArray(@truncate(a_idx));
        switch (a.gl_type) {
            .f32 => c.glVertexAttribPointer(
                @intCast(a_idx),
                a.elems,
                @intFromEnum(a.gl_type), // type
                c.GL_FALSE, // normalized
                attrs.stride, // stride
                @ptrFromInt(attrs.offset(a_idx)), // offset
            ),
            .u32, .u16, .u8 => c.glVertexAttribIPointer(
                @intCast(a_idx),
                a.elems,
                @intFromEnum(a.gl_type),
                attrs.stride,
                @ptrFromInt(attrs.offset(a_idx)),
            ),
            else => return error.UnsupportedParam,
        }
    }
    self.unbind();
    vbo.unbind();
}
