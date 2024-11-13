const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const System = @import("system.zig");
const GLFW = @import("glfw.zig");
const SDL = @import("sdl.zig");

fn window_sdl() !void {
    var sdl = try SDL.init();
    defer sdl.deinit();

    while (true) {
        try sdl.clear();
        var event = try sdl.wait_event();
        if (sdl.is_quit(&event)) break;
    }
}

pub fn main() !void {
    try GLFW.init();
    defer GLFW.deinit();

    var window = try GLFW.Window.init();
    defer window.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var system = try System.init(alloc, "lufia.sfc");
    defer system.deinit(alloc);

    try system.check();
    system.cpu_status();

    while (!window.should_close()) {
        window.activate();
        window.render();
    }
}
