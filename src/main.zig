const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GLFW = @import("glfw/glfw.zig");
const Context = @import("gl/context.zig");

const System = @import("system/system.zig");
const CPU = System.CPU;
const ROM = System.ROM;

const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

pub fn create_window(alloc: Allocator, system: *System) !void {
    var glfw = try GLFW.init(alloc);
    defer glfw.deinit();

    var context = Context.init();
    defer context.deinit();

    var window = try glfw.window(alloc);
    defer window.deinit();

    const vao = Context.VAO.init();
    defer vao.deinit();
    const vbo = Context.VBO.vbo(.Array, f32).init();
    defer vbo.deinit();

    vao.attrib(f32, 0, 3, 3 * @sizeOf(f32), 0);
    vbo.upload(&vertices);

    try context.program(alloc, "res/shader.vs", "res/shader.fs");
    var program = context.state.program.?;

    while (!window.is_close()) {
        while (glfw.next()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    .ESC, .Q => window.close(),
                    .R => system.cpu.print(),
                    else => std.log.debug("key `{}` not implemented yet\n", .{k}),
                },
                .key_repeat => {},
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        Context.clearColor(.{});
        Context.clear();
        program.use();
        vao.bind();
        Context.draw(.Triangles, @sizeOf(@TypeOf(vertices)));
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
}
