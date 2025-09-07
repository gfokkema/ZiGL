const std = @import("std");
const zlm = @import("zlm").SpecializeOn(f32);
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const Camera = @import("camera.zig");
const GL = @import("gl/gl.zig");
const GLFW = @import("glfw/glfw.zig");
const System = @import("system/system.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var glfw = try GLFW.init(alloc);
    defer glfw.deinit(alloc);

    var window = try glfw.window(alloc);
    defer window.deinit(alloc);

    var context = GL.Context(GLFW.Window).init(window);
    defer context.deinit(alloc);
    try context.viewport(window.size());

    var memory = try System.Memory.init(alloc, "res/tetris.gb");
    defer memory.deinit(alloc);

    // try rom.check();
    // rom.header().checksum();

    var cpu = System.CPU{};
    var camera = Camera.init(.{});
    while (!window.is_close()) {
        while (glfw.queue.pop()) |e| {
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    .ESC, .Q => window.close(),
                    .UP => camera.move(zlm.vec3(0, 0, -0.1)),
                    .DOWN => camera.move(zlm.vec3(0, 0, 0.1)),
                    .RIGHT => camera.move(zlm.vec3(0.1, 0, 0)),
                    .LEFT => camera.move(zlm.vec3(-0.1, 0, 0)),
                    .P, .R => std.debug.print("{f}\n", .{cpu}),
                    .S, .N => try cpu.step(&memory),
                    else => std.debug.print("key: `{any}` not implemented yet\n", .{k}),
                },
                .key_repeat => {},
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        context.draw(camera.mvp(), 72);

        window.render();
        window.swap();
        window.poll();
    }
}
