const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GLFW = @import("glfw/glfw.zig");
const Key = GLFW.Key;

const GL = @import("glfw/gl.zig");
const Program = GL.Program;

const System = @import("system/system.zig");
const CPU = System.CPU;
const ROM = System.ROM;

const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

pub fn create_window(alloc: Allocator, system: *System) !void {
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
                    Key.R => system.cpu.print(),
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var system = try System.init(alloc);
    defer system.deinit(alloc);

    var rom = try ROM.init(alloc, "lufia.sfc");
    defer rom.deinit();
    try rom.check();

    std.debug.print("debug: {*}\n", .{system.memory.banks});
    std.debug.print("debug: {*}\n", .{system.cpu.memory.banks});

    system.load(&rom);
    for (0..20) |_| {
        // if (i % 5 == 0) system.cpu.print();
        system.cpu.step();
    }

    try create_window(alloc, &system);
}
