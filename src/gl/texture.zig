const c = @import("c").c;
const zlm = @import("zlm");

const Image = @import("image.zig");

pub const TextureType = enum(u16) {
    Texture2D = c.GL_TEXTURE_2D,
    Texture2DArray = c.GL_TEXTURE_2D_ARRAY,
    _,
};
pub const TextureUnit = enum(u16) {
    UNIT_0 = c.GL_TEXTURE0,
    UNIT_1 = c.GL_TEXTURE1,

    pub fn index(self: TextureUnit) i32 {
        return @intFromEnum(self) - @intFromEnum(TextureUnit.UNIT_0);
    }
};
const TextureLevel = u8;

pub const Texture2D = Texture(.Texture2D);
pub const Texture2DArray = Texture(.Texture2DArray);

pub fn Texture(T: TextureType) type {
    return struct {
        const Self = @This();

        handle: u32,
        unit: ?TextureUnit = undefined,

        pub fn init() Self {
            var handle: u32 = undefined;
            c.glGenTextures(1, &handle);
            return .{ .handle = handle };
        }

        pub fn deinit(self: *const Self) void {
            c.glDeleteTextures(1, &self.handle);
        }

        pub fn bind(self: *Self, unit: TextureUnit) void {
            c.glActiveTexture(@intFromEnum(unit));
            c.glBindTexture(@intFromEnum(T), self.handle);
            self.unit = unit;
        }

        pub fn index(self: Self) !i32 {
            if (self.unit) |u| return u.index();
            return error.TextureNotBoundToUnit;
        }

        pub fn unbind(_: *const Self) void {
            c.glBindTexture(@intFromEnum(T), 0);
        }

        pub fn upload(_: *const Self, level: TextureLevel, image: Image) void {
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
