const c = @import("c").c;
const std = @import("std");
const zlm = @import("zlm").SpecializeOn(f32);
const Allocator = std.mem.Allocator;

const GL = @import("gl.zig");
const Program = @import("program.zig");
const Shader = @import("shader.zig");
const Texture = @import("texture.zig");
const Texture2D = Texture.Texture2D;

pub fn Context(comptime C: type) type {
    return struct {
        const Self = @This();

        context: *C,
        program: Program = undefined,
        textures: std.ArrayList(Texture2D),
        vao: GL.VAO,
        vbo: GL.ArrayBuffer,

        pub fn init(context: *C) Self {
            return .{
                .context = context,
                .vao = GL.VAO.init(),
                .vbo = GL.ArrayBuffer.init(),
                .textures = std.ArrayListUnmanaged(Texture2D){},
            };
        }

        pub fn deinit(self: *Self, alloc: Allocator) void {
            for (self.textures.items) |t| t.deinit();
            self.textures.deinit(alloc);
            self.program.deinit();
            self.vao.deinit();
            self.vbo.deinit();
        }

        pub fn activate(self: Self) void {
            return self.context.activate();
        }

        pub fn attribs(self: Self, attrs: GL.VAO.Attribs) !void {
            try self.vao.attribs(self.vbo, attrs);
        }

        const Params = struct {
            vs: []const u8,
            fs: []const u8,
            attribs: GL.VAO.Attribs,
        };

        pub fn create_program(self: *Self, alloc: Allocator, params: Params) !void {
            var vs = try Shader.init_path(alloc, .VS, params.vs);
            defer vs.deinit();

            var fs = try Shader.init_path(alloc, .FS, params.fs);
            defer fs.deinit();

            const p = try Program.init();
            p.link(vs, fs) catch |e| {
                p.log();
                std.debug.panic("Program: {any}\n", .{e});
            };

            p.attribs();
            p.uniforms();

            self.program = p;
        }

        pub fn create_texture(self: *Self, alloc: Allocator, unit: Texture.TextureUnit, path: []const u8) !Texture.Texture2D {
            var texture = Texture.Texture2D.init();
            texture.bind(unit);
            texture.upload_image(path);
            try self.textures.append(alloc, texture);
            return texture;
        }

        pub fn clearColor(_: Self, color: GL.Color) void {
            c.glClearColor(color.r, color.g, color.b, color.a);
        }

        pub fn clear(_: Self) void {
            c.glClear(@intFromEnum(GL.ClearMode.Color) | @intFromEnum(GL.ClearMode.Depth));
        }

        pub fn draw(self: Self, mvp: zlm.Mat4, count: usize) void {
            self.clearColor(.{});
            self.clear();

            self.program.use();
            try self.program.uniform("mvp", .Mat4).set(&mvp);

            self.vao.bind();
            self.drawArrays(.Triangles, count);
            self.vao.unbind();
        }

        pub fn drawArrays(_: Self, mode: GL.DrawMode, count: usize) void {
            c.glDrawArrays(
                @intFromEnum(mode),
                0,
                @intCast(count),
            );
        }

        pub fn drawElements(_: Self, mode: GL.DrawMode, count: usize, T: type, offs: usize) void {
            c.glDrawElements(
                @intFromEnum(mode),
                @intCast(count),
                @intFromEnum(GL.DataType.from(T)),
                @ptrFromInt(offs),
            );
        }

        pub fn upload(self: Self, comptime V: type, data: []V) !void {
            self.vbo.bind();
            self.vbo.upload(V, data);
            self.vbo.unbind();
        }

        pub fn viewport(_: Self, size: @Vector(2, i32)) !void {
            c.glViewport(0, 0, size[0], size[1]);
            c.glEnable(c.GL_DEPTH_TEST);
        }
    };
}

pub fn getError() !void {
    const err: GL.Error = @enumFromInt(c.glGetError());
    std.debug.print("ERROR: {any}\n", .{err});
}
