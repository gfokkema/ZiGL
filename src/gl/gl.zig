const c = @import("c").c;

pub const Context = @import("context.zig").Context;
pub const VAO = @import("vao.zig");
pub const VBO = @import("vbo.zig").VBO;
pub const ArrayBuffer = VBO(.Array);
pub const ElementBuffer = VBO(.Element);
pub const Image = @import("image.zig");
pub const Program = @import("program.zig");
pub const Shader = @import("shader.zig");
pub const Texture = @import("texture.zig");

pub const Color = struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,
};

pub const Error = enum(u16) {
    NoError = c.GL_NO_ERROR,
    InvalidEnum = c.GL_INVALID_ENUM,
    InvalidValue = c.GL_INVALID_VALUE,
    InvalidOp = c.GL_INVALID_OPERATION,
    InvalidFBOp = c.GL_INVALID_FRAMEBUFFER_OPERATION,
    OOM = c.GL_OUT_OF_MEMORY,
    StackUnderFlow = c.GL_STACK_UNDERFLOW,
    StackOverFlow = c.GL_STACK_OVERFLOW,
};

pub const DataType = enum(u32) {
    f32 = c.GL_FLOAT,
    i8 = c.GL_BYTE,
    i16 = c.GL_SHORT,
    i32 = c.GL_INT,
    u8 = c.GL_UNSIGNED_BYTE,
    u16 = c.GL_UNSIGNED_SHORT,
    u32 = c.GL_UNSIGNED_INT,
    Vec2 = c.GL_FLOAT_VEC2,
    Vec3 = c.GL_FLOAT_VEC3,
    Vec4 = c.GL_FLOAT_VEC4,
    Mat4 = c.GL_FLOAT_MAT4,
    Sampler2D = c.GL_SAMPLER_2D,
    _,

    pub fn from(T: type) DataType {
        return switch (T) {
            u8 => DataType.u8,
            u16 => DataType.u16,
            u32 => DataType.u32,
            f32 => DataType.f32,
            else => @compileError("Invalid type " ++ @tagName(@typeInfo(T))),
        };
    }
};

pub const DrawMode = enum(u16) {
    Points = c.GL_POINTS,
    Triangles = c.GL_TRIANGLES,
};

pub const ClearMode = enum(u16) {
    Color = c.GL_COLOR_BUFFER_BIT,
    Depth = c.GL_DEPTH_BUFFER_BIT,
    Stencil = c.GL_STENCIL_BUFFER_BIT,
};

const TextureType = enum(u16) {
    Texture2D = c.GL_TEXTURE_2D,
    Texture2DArray = c.GL_TEXTURE_2D_ARRAY,
    _,
};

const TextureUnit = enum(u16) {
    UNIT_0 = c.GL_TEXTURE0,
    UNIT_1 = c.GL_TEXTURE1,
};
