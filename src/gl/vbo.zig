const c = @import("c").c;
const gl = @import("gl.zig");

const Type = enum(u16) {
    Array = c.GL_ARRAY_BUFFER,
    Element = c.GL_ELEMENT_ARRAY_BUFFER,
    _,
};

pub fn VBO(V: Type, T: type) type {
    return struct {
        const Self = @This();

        handle: u32,

        pub fn init() Self {
            var handle: u32 = undefined;
            c.glGenBuffers(1, &handle);
            return .{ .handle = handle };
        }

        pub fn deinit(self: *const Self) void {
            c.glDeleteBuffers(1, &self.handle);
        }

        pub fn bind(self: *const Self) void {
            c.glBindBuffer(@intFromEnum(V), self.handle);
        }

        pub fn unbind(_: *const Self) void {
            c.glBindBuffer(@intFromEnum(V), 0);
        }

        pub fn upload(_: *const Self, data: []const T) void {
            c.glBufferData(
                @intFromEnum(V),
                @intCast(data.len * @sizeOf(T)),
                data.ptr,
                c.GL_STATIC_DRAW,
            );
        }
    };
}
