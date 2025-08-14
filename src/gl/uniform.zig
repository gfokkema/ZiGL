const c = @import("c");
const std = @import("std");
const zlm = @import("zlm");
const Allocator = std.mem.Allocator;
const Program = @import("program.zig");

const Vec1 = @Vector(1, f32);
const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);

pub const UniformType = enum(u32) {
    Int = c.GL_INT,
    UInt = c.GL_UNSIGNED_INT,
    Vec2 = c.GL_FLOAT_VEC2,
    Vec3 = c.GL_FLOAT_VEC3,
    Vec4 = c.GL_FLOAT_VEC4,
    Mat4 = c.GL_FLOAT_MAT4,
    Sampler2D = c.GL_SAMPLER_2D,
    _,
};

pub fn Uniform(T: UniformType) type {
    return struct {
        program: *Program,
        name: []const u8,
        loc: i32,

        const Self = @This();

        pub fn init(program: *Program, name: []const u8) Self {
            return .{
                .program = program,
                .name = name,
                .loc = c.glGetUniformLocation(program.handle, name.ptr),
            };
        }

        pub fn set(self: Self, val: anytype) void {
            switch (T) {
                .Int, .Sampler2D => _ = c.glUniform1i(self.loc, val),
                .UInt => _ = c.glUniform1ui(self.loc, val),
                .Mat4 => _ = c.glUniformMatrix4fv(self.loc, 1, c.GL_FALSE, @ptrCast(val)),
                else => unreachable,
            }
        }
    };
}
