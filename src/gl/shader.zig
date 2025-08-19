const c = @import("c").c;
const std = @import("std");
const Allocator = std.mem.Allocator;

const ShaderType = enum(u16) {
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

    pub fn int(self: Param) u32 {
        return @intFromEnum(self);
    }
};

const Shader = @This();

handle: u32,
t: ShaderType,

pub fn init(t: ShaderType) Shader {
    return .{
        .handle = c.glCreateShader(@intFromEnum(t)),
        .t = t,
    };
}

pub fn init_path(alloc: Allocator, t: ShaderType, path: []const u8) !Shader {
    const shader = Shader.init(t);
    errdefer shader.deinit();

    var buf: [512]u8 = undefined;
    const src = try std.fs.cwd().readFile(path, &buf);
    shader.compile(src) catch |e| {
        try shader.log(alloc);
        std.debug.panic("Shader: {any}", .{e});
    };
    return shader;
}

pub fn deinit(self: *const Shader) void {
    c.glDeleteShader(self.handle);
}

pub fn compile(self: *const Shader, src: []const u8) !void {
    c.glShaderSource(self.handle, 1, &src.ptr, null);
    c.glCompileShader(self.handle);

    var success: i32 = undefined;
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
