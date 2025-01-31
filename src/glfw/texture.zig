const c = @import("c");
const Texture = @This();

const Target = enum(u16) {
    GL_TEXTURE_2D = c.GL_TEXTURE_2D,
    _,
};

handle: c_uint,

pub fn init() Texture {
    var handle: c_uint = undefined;
    c.glGenTextures(1, &handle);
    return .{ .handle = handle };
}

pub fn deinit(self: *const Texture) void {
    c.glDeleteTextures(1, &self.handle);
}

pub fn bind(self: *const Texture, target: Target) void {
    c.glBindTexture(@intFromEnum(target), self.handle);
}

pub fn unbind(_: *const Texture) void {
    c.glBindTexture(0);
}
