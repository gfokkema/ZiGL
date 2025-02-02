const c = @import("c");
const Image = @import("image.zig");
const Texture = @This();

const Target = enum(u16) {
    GL_TEXTURE_2D = c.GL_TEXTURE_2D,
    _,
};
const Level = u8;

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

pub fn upload(_: *const Texture, target: Target, level: Level, image: Image) void {
    // set the texture wrapping/filtering options (on the currently bound texture object)
    c.glTexParameteri(@intFromEnum(target), c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(@intFromEnum(target), c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(@intFromEnum(target), c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(@intFromEnum(target), c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    // load and generate the texture
    c.glTexImage2D(
        @intFromEnum(target),
        level,
        c.GL_RGB,
        image.params.width,
        image.params.height,
        0,
        c.GL_RGB,
        c.GL_UNSIGNED_BYTE,
        image.image,
    );
}
