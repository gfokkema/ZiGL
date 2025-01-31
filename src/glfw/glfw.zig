const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ImGui = @import("imgui.zig");
pub const Window = @import("window.zig");

pub fn Fifo(comptime T: type) type {
    return std.fifo.LinearFifo(T, .Dynamic);
}
pub const Queue = Fifo(Event);

pub const Action = enum(u8) {
    PRESS = c.GLFW_PRESS,
    REPEAT = c.GLFW_REPEAT,
    RELEASE = c.GLFW_RELEASE,
    _,
};
pub const Key = enum(i16) {
    ESC = c.GLFW_KEY_ESCAPE,
    A = c.GLFW_KEY_A,
    D = c.GLFW_KEY_D,
    Q = c.GLFW_KEY_Q,
    R = c.GLFW_KEY_R,
    S = c.GLFW_KEY_S,
    W = c.GLFW_KEY_W,
    _,
};
pub const Mouse = enum(i8) {
    B1 = c.GLFW_MOUSE_BUTTON_1,
    B2 = c.GLFW_MOUSE_BUTTON_2,
    _,
};
pub const FrameEvent = struct {};
pub const Event = union(enum) {
    err,
    frame: FrameEvent,
    key_down: Key,
    key_repeat: Key,
    key_up: Key,
    mouse_down: Mouse,
    mouse_up: Mouse,
};

pub fn init() !void {
    _ = c.glfwSetErrorCallback(error_callback);
    if (c.glfwInit() != c.GLFW_TRUE) return error.InitError;
}

pub fn deinit() void {
    c.glfwTerminate();
}

pub fn error_callback(err: c_int, c_desc: [*c]const u8) callconv(.C) void {
    const desc = std.mem.span(c_desc);
    std.debug.panic("ERROR {d}: {s}\n", .{ err, desc });
}
