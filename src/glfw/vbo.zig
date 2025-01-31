const c = @import("c");
const VBO = @This();

const Type = enum(u16) {
    Array = c.GL_ARRAY_BUFFER,
    Element = c.GL_ELEMENT_ARRAY_BUFFER,
    _,
};

handle: c_uint,
vbotype: Type,

pub fn init(vbotype: Type) VBO {
    var handle: c_uint = undefined;
    c.glGenBuffers(1, &handle);
    return .{ .handle = handle, .vbotype = vbotype };
}

pub fn deinit(self: *const VBO) void {
    c.glDeleteBuffers(1, &self.handle);
}

pub fn bind(self: *const VBO) void {
    c.glBindBuffer(@intFromEnum(self.vbotype), self.handle);
}

pub fn unbind(self: *const VBO) void {
    c.glBindBuffer(@intFromEnum(self.vbotype), 0);
}

pub fn upload(self: *const VBO, T: type, data: []const T) void {
    self.bind();
    defer self.unbind();

    c.glBufferData(
        @intFromEnum(self.vbotype),
        @intCast(data.len * @sizeOf(T)),
        data.ptr,
        c.GL_STATIC_DRAW,
    );
}
