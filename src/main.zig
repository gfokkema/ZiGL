const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GLFW = @import("glfw/glfw.zig");
const Key = GLFW.Key;
const c = GLFW.c;

const GL = @import("glfw/gl.zig");
const Program = GL.Program;

const System = @import("system.zig");

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var system = try System.init(alloc, "lufia.sfc");
    defer system.deinit(alloc);

    try system.check();
    system.cpu_status();

    var queue = GLFW.Fifo(GLFW.Event).init(alloc);
    defer queue.deinit();

    try GLFW.init();
    defer GLFW.deinit();

    var window = GLFW.Window{};
    try window.init(&queue, .{});
    defer window.deinit();

    var gl = try GL.init();
    defer gl.deinit();
    const program = try Program.init_path(
        "res/shader.vs",
        "res/shader.fs",
    );
    defer program.deinit();
    const vao = GL.VAO.init();
    defer vao.deinit();
    const vbo = GL.VBO.init(.Array);
    defer vbo.deinit();
    {
        vao.bind();
        defer vao.unbind();

        vbo.bind();
        defer vbo.unbind();

        vbo.upload(f32, &vertices);
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);
    }

    while (!window.is_close()) {
        while (queue.readItem()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    Key.ESC, Key.Q => window.close(),
                    Key.R => system.cpu.print(),
                    else => std.log.debug("key `{}` not implemented yet\n", .{k}),
                },
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        gl.clearColor(.{});
        gl.clear();

        // draw our first triangle
        program.use();
        vao.bind();
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        vao.unbind();

        window.render();
        window.swap();
        window.poll();
    }
}
