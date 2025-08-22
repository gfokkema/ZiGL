const c = @import("c").c;
const zlm = @import("zlm");

const GL = @import("gl.zig");
const Image = @import("image.zig");

pub const TextureUnit = enum(u16) {
    UNIT_0 = c.GL_TEXTURE0,
    UNIT_1 = c.GL_TEXTURE1,
    _,

    pub fn index(self: TextureUnit) i32 {
        return @intFromEnum(self) - @intFromEnum(TextureUnit.UNIT_0);
    }
};

pub const TextureType = enum(u16) {
    Texture2D = c.GL_TEXTURE_2D,
    Texture2DArray = c.GL_TEXTURE_2D_ARRAY,
    _,
};

const TextureOptions = struct {
    level: u8 = 0,
    dtype: GL.DataType = .u8,
    internal: i32 = c.GL_RGB,
    format: u32 = c.GL_RGB,
    width: i32,
    height: i32,
};

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

        pub fn upload_image(self: Self, path: []const u8) void {
            const image = Image.init(path);
            defer image.deinit();

            self.upload(.{
                .width = image.params.width,
                .height = image.params.height,
            }, image.image);
        }

        pub fn upload(_: *const Self, opts: TextureOptions, data: *anyopaque) void {
            // set the texture wrapping/filtering options (on the currently bound texture object)
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
            c.glTexParameteri(@intFromEnum(T), c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
            // load and generate the texture
            c.glTexImage2D(
                @intFromEnum(T),
                opts.level,
                opts.internal,
                opts.width,
                opts.height,
                0,
                opts.format,
                @intFromEnum(opts.dtype),
                data,
            );
        }
    };
}
