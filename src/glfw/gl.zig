const std = @import("std");
const Allocator = std.mem.Allocator;

const GLFW = @import("glfw.zig");
pub const c = GLFW.c;

pub const VAO = @import("vao.zig");
pub const VBO = @import("vbo.zig");
pub const Program = @import("program.zig");

const GL = @This();

pub fn init() !GL {
    return .{};
}

pub fn deinit(_: *GL) void {}

pub fn clearColor(_: *GL, color: Color) void {
    c.glClearColor(color.r, color.g, color.b, color.a);
}

pub fn clear(_: *GL) void {
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

const Color = struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,
};

pub const Shader = struct {
    pub const Type = enum(u16) {
        VS = c.GL_VERTEX_SHADER,
        FS = c.GL_FRAGMENT_SHADER,
    };
    const Param = enum(u16) {
        TYPE = c.GL_SHADER_TYPE,
        DELETE = c.GL_DELETE_STATUS,
        COMPILE = c.GL_COMPILE_STATUS,
        LOG_LENGTH = c.GL_INFO_LOG_LENGTH,
        SRC_LENGTH = c.GL_SHADER_SOURCE_LENGTH,
        _,

        pub fn int(self: Param) c_uint {
            return @intFromEnum(self);
        }
    };

    handle: c_uint,
    t: Type,

    pub fn init(t: Type, path: []const u8) !Shader {
        var buf: [512]u8 = undefined;
        const src = try std.fs.cwd().readFile(path, &buf);
        const handle = c.glCreateShader(@intFromEnum(t));
        errdefer c.glDeleteShader(handle);

        c.glShaderSource(handle, 1, &src.ptr, null);
        c.glCompileShader(handle);

        var success: c_int = undefined;
        c.glGetShaderiv(handle, Param.COMPILE.int(), &success);
        if (success == c.GL_TRUE) return .{ .handle = handle, .t = t };

        var loglen: c_int = undefined;
        var logbuf: [512]u8 = .{0} ** 512;
        c.glGetShaderiv(handle, Param.LOG_LENGTH.int(), &loglen);
        c.glGetShaderInfoLog(
            handle,
            loglen,
            null,
            @ptrCast(&logbuf),
        );
        std.debug.print("shader:\n{s}", .{logbuf});

        return error.FailedCompilingShader;
    }

    pub fn deinit(self: *const Shader) void {
        c.glDeleteShader(self.handle);
    }

    // pub fn compile(self: *Shader, alloc: Allocator, path: []const u8) !void {
    //     const data = try std.fs.cwd().readFileAlloc(alloc, path, 1024 * 1024);
    // }
};
