const c = @import("c").c;
const std = @import("std");
const Allocator = std.mem.Allocator;

const GL = @import("gl.zig");
const Program = @import("program.zig");
const Shader = @import("shader.zig");
const Texture = @import("texture.zig");

pub fn Context(comptime C: type) type {
    return struct {
        const Self = @This();

        state: struct {
            context: *C,
            program: ?Program = undefined,
        },

        pub fn init(context: *C) Self {
            return .{
                .state = .{
                    .context = context,
                },
            };
        }

        pub fn deinit(self: Self) void {
            if (self.state.program) |p| p.deinit();
        }

        pub fn activate(self: Self) void {
            return self.state.context.activate();
        }

        pub fn create_program(self: *Self, alloc: Allocator, vs_path: []const u8, fs_path: []const u8) !void {
            var vs = try Shader.init_path(alloc, .VS, vs_path);
            defer vs.deinit();

            var fs = try Shader.init_path(alloc, .FS, fs_path);
            defer fs.deinit();

            const p = try Program.init();
            p.link(vs, fs) catch |e| {
                p.log();
                std.debug.panic("Program: {any}\n", .{e});
            };

            p.attribs();
            p.uniforms();

            self.state.program = p;
        }

        pub fn create_texture(_: Self) Texture.Texture2D {
            return Texture.Texture2D.init();
        }

        pub fn clearColor(_: Self, color: GL.Color) void {
            c.glClearColor(color.r, color.g, color.b, color.a);
        }

        pub fn clear(_: Self) void {
            c.glClear(@intFromEnum(GL.ClearMode.Color) | @intFromEnum(GL.ClearMode.Depth));
        }

        pub fn draw(_: Self, mode: GL.DrawMode, count: usize) void {
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

        pub fn viewport(self: Self) !void {
            const size = self.state.context.size();
            c.glViewport(0, 0, size.width, size.height);
            c.glEnable(c.GL_DEPTH_TEST);
        }
    };
}

pub fn getError() !void {
    const err: GL.Error = @enumFromInt(c.glGetError());
    std.debug.print("ERROR: {any}\n", .{err});
}
