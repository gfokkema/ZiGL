const std = @import("std");
const Allocator = std.mem.Allocator;
const GL = @import("gl.zig");
const c = GL.c;

const Type = enum(u16) {
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

const Shader = @This();

handle: c_uint,
t: Type,

pub fn init(alloc: Allocator, t: Type, src: []const u8) !Shader {
    const handle = c.glCreateShader(@intFromEnum(t));
    errdefer c.glDeleteShader(handle);

    const shader: Shader = .{ .handle = handle, .t = t };
    shader.compile(src) catch |e| {
        try shader.log(alloc);
        std.debug.panic("{any}", .{e});
    };

    return shader;
}

pub fn init_path(alloc: Allocator, t: Type, path: []const u8) !Shader {
    var buf: [512]u8 = undefined;
    const src = try std.fs.cwd().readFile(path, &buf);
    return Shader.init(alloc, t, src);
}

pub fn deinit(self: *const Shader) void {
    c.glDeleteShader(self.handle);
}

pub fn compile(self: *const Shader, src: []const u8) !void {
    c.glShaderSource(self.handle, 1, &src.ptr, null);
    c.glCompileShader(self.handle);

    var success: c_int = undefined;
    c.glGetShaderiv(self.handle, Param.COMPILE.int(), &success);
    if (success == c.GL_FALSE) return error.FailedCompilingShader;
}

pub fn log(self: *const Shader, alloc: Allocator) !void {
    var loglen: usize = 0;
    c.glGetShaderiv(self.handle, Param.LOG_LENGTH.int(), @ptrCast(&loglen));

    const logbuf = try alloc.alloc(u8, loglen);
    defer alloc.free(logbuf);

    c.glGetShaderInfoLog(
        self.handle,
        @intCast(loglen),
        null,
        @ptrCast(logbuf),
    );
    std.debug.print("shader:\n{s}", .{logbuf});
}
