const c = @import("c").c;
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Action = enum(u8) {
    PRESS = c.GLFW_PRESS,
    REPEAT = c.GLFW_REPEAT,
    RELEASE = c.GLFW_RELEASE,

    pub fn format(self: Action, writer: *std.io.Writer) !void {
        try writer.print("Action{{ .{s} }}", .{std.enums.tagName(Event, self) orelse @intCast(self)});
    }
};
pub const Key = enum(i16) {
    ESC = c.GLFW_KEY_ESCAPE,
    RIGHT = c.GLFW_KEY_RIGHT,
    LEFT = c.GLFW_KEY_LEFT,
    UP = c.GLFW_KEY_UP,
    DOWN = c.GLFW_KEY_DOWN,
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

pub const EventType = enum {
    err,
    frame,
    key_down,
    key_repeat,
    key_up,
    mouse_down,
    mouse_up,
};

pub const Event = union(EventType) {
    err,
    frame: FrameEvent,
    key_down: Key,
    key_repeat: Key,
    key_up: Key,
    mouse_down: Mouse,
    mouse_up: Mouse,
};
