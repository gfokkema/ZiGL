const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const VAO = @import("vao.zig");
pub const VBO = @import("vbo.zig");
pub const Program = @import("program.zig");
pub const Shader = @import("shader.zig");
pub const Texture = @import("texture.zig");

const Color = struct {
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

pub const Type = enum(u16) {
    u32 = c.GL_UNSIGNED_INT,
    u16 = c.GL_UNSIGNED_SHORT,
    u8 = c.GL_UNSIGNED_BYTE,
    f32 = c.GL_FLOAT,

    pub fn as(T: type) Type {
        return switch (T) {
            u8 => Type.u8,
            u16 => Type.u16,
            u32 => Type.u32,
            f32 => Type.f32,
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

const State = struct {
    program: ?Program = undefined,
};

const GL = @This();

state: State = .{},

pub fn clearColor(color: Color) void {
    c.glClearColor(color.r, color.g, color.b, color.a);
}

pub fn clear() void {
    c.glClear(@intFromEnum(ClearMode.Color));
}

pub fn draw(mode: DrawMode) void {
    c.glDrawArrays(@intFromEnum(mode), 0, 6);
}

pub fn drawElements(
    mode: DrawMode,
    count: usize,
    T: type,
    offs: usize,
) void {
    c.glDrawElements(
        @intFromEnum(mode),
        @intCast(count),
        @intFromEnum(Type.as(T)),
        @ptrFromInt(offs),
    );
}

pub fn getError() !void {
    const err: Error = @enumFromInt(c.glGetError());
    std.debug.print("ERROR: {any}\n", .{err});
}

pub fn program(alloc: Allocator, vs_path: []const u8, fs_path: []const u8) !Program {
    var vs = try Shader.init_path(alloc, .VS, vs_path);
    defer vs.deinit();

    var fs = try Shader.init_path(alloc, .FS, fs_path);
    defer fs.deinit();

    var p = try Program.init();
    p.link(vs, fs) catch |e| {
        p.log();
        std.debug.panic("Program: {any}\n", .{e});
    };
    return p;
}

pub fn texture() Texture {
    return Texture.init();
}
