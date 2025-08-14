const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Shader = @import("shader.zig");
const Uniform = @import("uniform.zig");

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

pub fn init() !Program {
    return .{ .handle = c.glCreateProgram() };
}

pub fn deinit(self: *const Program) void {
    c.glDeleteProgram(self.handle);
}

pub fn get(self: *const Program, param: Param) u31 {
    var retval: c_int = undefined;
    c.glGetProgramiv(self.handle, @intFromEnum(param), &retval);
    return @intCast(retval);
}

pub fn attach(self: *const Program, shader: *const Shader) void {
    c.glAttachShader(self.handle, shader.handle);
}

pub fn link(self: *const Program, vs: Shader, fs: Shader) !void {
    self.attach(&vs);
    self.attach(&fs);
    c.glLinkProgram(self.handle);

    const success = self.get(.LINK);
    if (success == c.GL_FALSE) return error.FailedLinkingProgram;
}

pub fn log(self: *const Program) void {
    var logbuf = std.mem.zeroes([512]u8);
    const loglen = self.get(.LOG_LENGTH);
    c.glGetProgramInfoLog(
        self.handle,
        loglen,
        null,
        @ptrCast(&logbuf),
    );
    std.debug.print("program:\n{s}", .{logbuf});
}

pub fn attribs(self: *const Program) void {
    const count = self.get(.ACTIVE_ATTRS);
    std.debug.print("attrs: {}\n", .{count});

    var len: c_int = undefined;
    var attr_size: c_int = undefined;
    var attr_type: c_uint = undefined;
    var buf: [4096]u8 = std.mem.zeroes([4096]u8);
    for (0..count) |i| {
        c.glGetActiveAttrib(self.handle, @intCast(i), buf.len, &len, &attr_size, &attr_type, @ptrCast(&buf));
        std.debug.print("  {d}: {s}\n", .{ i, buf[0..@intCast(len)] });
    }
}

pub fn uniforms(self: *const Program) void {
    const count = self.get(.ACTIVE_UNIFORMS);
    std.debug.print("uniforms: {}\n", .{count});

    var len: c_int = undefined;
    var uni_size: c_int = undefined;
    var uni_type: Uniform.UniformType = undefined;
    var buf: [4096]u8 = std.mem.zeroes([4096]u8);
    for (0..count) |i| {
        c.glGetActiveUniform(
            self.handle,
            @intCast(i),
            buf.len,
            &len,
            &uni_size,
            @ptrCast(&uni_type),
            @ptrCast(&buf),
        );
        std.debug.print("  {d}: {s}  ({any})\n", .{ i, buf[0..@intCast(len)], uni_type });
    }
}

pub fn uniform(self: *Program, name: []const u8, comptime T: Uniform.UniformType) Uniform.Uniform(T) {
    return Uniform.Uniform(T).init(self, name);
}

pub fn use(self: *const Program) void {
    c.glUseProgram(self.handle);
}
