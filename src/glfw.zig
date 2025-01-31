const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GLFW = @import("glfw/glfw.zig");
const Key = GLFW.Key;

const GL = @import("glfw/gl.zig");
const Program = GL.Program;

const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var queue = GLFW.Queue.init(alloc);
    defer queue.deinit();

    try GLFW.init();
    defer GLFW.deinit();

    var window: GLFW.Window = undefined;
    try GLFW.Window.init(&window, &queue, .{});
    defer window.deinit();

    const vao = GL.VAO.init();
    defer vao.deinit();
    const vbo = GL.VBO.init(.Array);
    defer vbo.deinit();

    vao.attrib(&vbo, 0, 3);
    vbo.upload(f32, &vertices);

    const program = try GL.program(alloc, "res/shader.vs", "res/shader.fs");
    defer program.deinit();

    while (!window.is_close()) {
        while (queue.readItem()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    Key.ESC, Key.Q => window.close(),
                    else => std.log.debug("key `{}` not implemented yet\n", .{k}),
                },
                .key_repeat => {},
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        GL.clearColor(.{});
        GL.clear();
        program.use();
        vao.bind();
        GL.draw(.GL_TRIANGLES);
        vao.unbind();

        window.render();
        window.swap();
        window.poll();
    }
}
