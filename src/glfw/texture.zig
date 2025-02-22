const c = @import("c");
const Image = @import("image.zig");
const zlm = @import("zlm");

const Type = enum(u16) {
    Texture2D = c.GL_TEXTURE_2D,
    Texture2DArray = c.GL_TEXTURE_2D_ARRAY,
    _,
};
const Level = u8;

pub const Texture2D = texture(.Texture2D);
pub const Texture2DArray = texture(.Texture2DArray);

pub fn texture(T: Type) type {
    return struct {
        const Self = @This();

        handle: c_uint,

        pub fn init() Self {
            var handle: c_uint = undefined;
            c.glGenTextures(1, &handle);
            return .{ .handle = handle };
        }

        pub fn deinit(self: *const Self) void {
            c.glDeleteTextures(1, &self.handle);
        }

        pub fn bind(self: *const Self) void {
            c.glBindTexture(@intFromEnum(T), self.handle);
        }

        pub fn unbind(_: *const Self) void {
            c.glBindTexture(0);
        }

        pub fn upload(_: *const Self, level: Level, image: Image) void {
            // set the texture wrapping/filtering options (on the currently bound texture object)
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
            // load and generate the texture
            c.glTexImage2D(
                @intFromEnum(T),
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
    };
}
