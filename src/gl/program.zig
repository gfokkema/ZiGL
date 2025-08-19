const c = @import("c").c;
const std = @import("std");
const Allocator = std.mem.Allocator;

const GL = @import("gl.zig");
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

    pub fn int(self: Param) u32 {
        return @intFromEnum(self);
    }
};

const Attrib = struct {
    program: *const Program,
    name: [128]u8,
    dtype: GL.DataType,

    const Self = @This();

    pub fn init(program: *const Program, index: u32) Self {
        var name = std.mem.zeroes([128]u8);
        var name_len: i32 = 0;
        var attr_size: i32 = 0;
        var attr_dtype: u32 = 0;
        c.glGetActiveAttrib(
            program.handle,
            index,
            name.len,
            &name_len,
            &attr_size,
            &attr_dtype,
            @ptrCast(&name),
        );

        return .{
            .program = program,
            .name = name,
            .dtype = @enumFromInt(attr_dtype),
        };
    }

    pub fn format(self: Self, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print(
            "Attrib{{ .handle = {d}, .name = \"{s}\", .dtype = {any} }}",
            .{ self.program.handle, self.name, self.dtype },
        );
    }
};

pub fn Uniform(comptime T: GL.DataType) type {
    return struct {
        program: *const Program,
        name: []const u8,
        loc: i32,
        dtype: GL.DataType = T,

        const Self = @This();

        pub fn init(program: *const Program, name: []const u8) Self {
            return .{
                .program = program,
                .name = name,
                .loc = c.glGetUniformLocation(program.handle, name.ptr),
                .dtype = T,
            };
        }

        pub fn init_index(program: *const Program, index: u32) Self {
            var name = std.mem.zeroes([128]u8);
            var name_len: i32 = 0;
            var uni_size: i32 = 0;
            var uni_dtype: u32 = 0;
            c.glGetActiveUniform(
                program.handle,
                index,
                name.len,
                &name_len,
                &uni_size,
                &uni_dtype,
                @ptrCast(&name),
            );

            return .{
                .program = program,
                .name = name,
                .loc = -1,
                .dtype = @enumFromInt(uni_dtype),
            };
        }

        pub fn set(self: Self, val: anytype) !void {
            switch (T) {
                .u32 => _ = c.glUniform1i(self.loc, val),
                .i32 => _ = c.glUniform1ui(self.loc, val),
                .Sampler2D => _ = c.glUniform1i(self.loc, try val.index()),
                .Mat4 => _ = c.glUniformMatrix4fv(self.loc, 1, c.GL_FALSE, @ptrCast(val)),
                else => unreachable,
            }
        }

        pub fn format(self: Self, writer: *std.io.Writer) !void {
            try writer.print(
                "Uniform{{ .handle = {d}, .name = \"{s}\", .dtype = {any} }}",
                .{ self.program.handle, self.name, self.dtype },
            );
        }
    };
}

const Program = @This();

handle: u32,

pub fn init() !Program {
    return .{ .handle = c.glCreateProgram() };
}

pub fn deinit(self: *const Program) void {
    c.glDeleteProgram(self.handle);
}

pub fn get(self: *const Program, param: Param) u31 {
    var retval: i32 = undefined;
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
    for (0..count) |idx| {
        const attrib = Attrib.init(self, @intCast(idx));
        std.debug.print("  {d}: {f}\n", .{ idx, attrib });
    }
}

pub fn uniforms(self: *const Program) void {
    const count = self.get(.ACTIVE_UNIFORMS);
    std.debug.print("uniforms: {}\n", .{count});
    // for (0..count) |idx| {
    //     const u = Uniform.init_index(self, @intCast(idx));
    //     std.debug.print("  {d}: {any}\n", .{ idx, u });
    // }
}

pub fn uniform(self: *const Program, name: []const u8, comptime T: GL.DataType) Uniform(T) {
    return Uniform(T).init(self, name);
}

pub fn use(self: *const Program) void {
    c.glUseProgram(self.handle);
}
