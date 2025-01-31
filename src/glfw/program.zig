const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Shader = @import("shader.zig");

const Param = enum(u16) {
    DELETE = c.GL_DELETE_STATUS,
    LINK = c.GL_LINK_STATUS,
    VALIDATE = c.GL_VALIDATE_STATUS,
    LOG_LENGTH = c.GL_INFO_LOG_LENGTH,
    ATTACHED = c.GL_ATTACHED_SHADERS,
    ACTIVE_ATTRS = c.GL_ACTIVE_ATTRIBUTES,
    ACTIVE_ATTRS_MAX = c.GL_ACTIVE_ATTRIBUTE_MAX_LENGTH,
    ACTIVE_UNIFORMS = c.GL_ACTIVE_UNIFORMS,
    ACTIVE_UNIFORMS_MAX = c.GL_ACTIVE_UNIFORM_MAX_LENGTH,
    _,

    pub fn int(self: Param) c_uint {
        return @intFromEnum(self);
    }
};

const Program = @This();

handle: c_uint,

pub fn init(vs: Shader, fs: Shader) !Program {
    const handle = c.glCreateProgram();
    errdefer c.glDeleteProgram(handle);

    const program: Program = .{ .handle = handle };
    program.attach(&vs);
    program.attach(&fs);
    program.link() catch |e| {
        program.log();
        std.debug.panic("{any}", .{e});
    };

    return program;
}

pub fn deinit(self: *const Program) void {
    c.glDeleteProgram(self.handle);
}

pub fn attach(self: *const Program, shader: *const Shader) void {
    c.glAttachShader(self.handle, shader.handle);
}

pub fn link(self: *const Program) !void {
    c.glLinkProgram(self.handle);

    var success: c_int = undefined;
    c.glGetProgramiv(self.handle, Param.LINK.int(), &success);
    if (success == c.GL_FALSE) return error.FailedLinkingProgram;
}

pub fn log(self: *const Program) void {
    var loglen: c_int = undefined;
    var logbuf: [512]u8 = .{0} ** 512;
    c.glGetProgramiv(self.handle, Param.LOG_LENGTH.int(), &loglen);
    c.glGetProgramInfoLog(
        self.handle,
        loglen,
        null,
        @ptrCast(&logbuf),
    );
    std.debug.print("program:\n{s}", .{logbuf});
}

pub fn use(self: *const Program) void {
    c.glUseProgram(self.handle);
}
