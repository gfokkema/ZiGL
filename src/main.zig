const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GLFW = @import("glfw/glfw.zig");
const Key = GLFW.Key;
const c = GLFW.c;

const GL = @import("glfw/gl.zig");
const Program = GL.Program;

const System = @import("system/system.zig");
const CPU = System.CPU;
const ROM = System.ROM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var system = try System.init(alloc);
    defer system.deinit(alloc);
    system.cpu_status();

    var rom = try ROM.init(alloc, "lufia.sfc");
    defer rom.deinit();
    rom.header().print();
    try rom.check();

    system.load(&rom);

    std.debug.print("entry? {x}\n", .{
        @as(CPU.InstrType, @enumFromInt(system.memory.banks[0x00][0x8000])),
    });

    var queue = GLFW.Fifo(GLFW.Event).init(alloc);
    defer queue.deinit();

    try GLFW.init();
    defer GLFW.deinit();

    var window = GLFW.Window{};
    try window.init(&queue, .{});
    defer window.deinit();

    var gl = try GL.init("res/shader.vs", "res/shader.fs");
    defer gl.deinit();

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
        gl.draw();

        window.render();
        window.swap();
        window.poll();
    }
}
