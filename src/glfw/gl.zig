const std = @import("std");
const Allocator = std.mem.Allocator;

const GLFW = @import("glfw.zig");
pub const c = GLFW.c;

pub const VAO = @import("vao.zig");
pub const VBO = @import("vbo.zig");
pub const Program = @import("program.zig");

const GL = @This();

const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

const vertexShaderSource =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\};
;
const fragmentShaderSource =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

program: Program,
vao: VAO,
vbo: VBO,

pub fn init(vs: []const u8, fs: []const u8) !GL {
    const program = try Program.init_path(vs, fs);
    const vao = GL.VAO.init();
    const vbo = GL.VBO.init(.Array);
    {
        vao.bind();
        defer vao.unbind();

        vbo.bind();
        defer vbo.unbind();

        vbo.upload(f32, &vertices);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);
    }
    return .{
        .program = program,
        .vao = vao,
        .vbo = vbo,
    };
}

pub fn deinit(self: *GL) void {
    defer self.vbo.deinit();
    defer self.vao.deinit();
    defer self.program.deinit();
}

pub fn clearColor(_: *GL, color: Color) void {
    c.glClearColor(color.r, color.g, color.b, color.a);
}

pub fn clear(_: *GL) void {
    c.glClear(c.GL_COLOR_BUFFER_BIT);
}

pub fn draw(self: *GL) void {
    self.program.use();
    self.vao.bind();
    c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    self.vao.unbind();
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
