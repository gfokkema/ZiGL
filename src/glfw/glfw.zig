const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Event = @import("event.zig");
pub const ImGui = @import("imgui.zig");
pub const Window = @import("window.zig");

const GLFW = @This();

queue: Event.Queue,

pub fn init(alloc: Allocator) !GLFW {
    _ = c.glfwSetErrorCallback(error_callback);
    if (c.glfwInit() != c.GLFW_TRUE) return error.InitError;

    return .{
        .queue = Event.Queue.init(alloc),
    };
}

pub fn deinit(self: *GLFW) void {
    c.glfwTerminate();
    self.queue.deinit();
}

pub fn next(self: *GLFW) ?Event.Event {
    return self.queue.readItem();
}

pub fn window(self: *GLFW, alloc: Allocator) !*Window {
    return try Window.init(alloc, &self.queue, .{});
}

pub fn error_callback(err: c_int, c_desc: [*c]const u8) callconv(.C) void {
    const desc = std.mem.span(c_desc);
    std.debug.panic("ERROR {d}: {s}\n", .{ err, desc });
}
