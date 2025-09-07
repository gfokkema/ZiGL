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
    B = c.GLFW_KEY_B,
    C = c.GLFW_KEY_C,
    D = c.GLFW_KEY_D,
    E = c.GLFW_KEY_E,
    F = c.GLFW_KEY_F,
    G = c.GLFW_KEY_G,
    H = c.GLFW_KEY_H,
    I = c.GLFW_KEY_I,
    J = c.GLFW_KEY_J,
    K = c.GLFW_KEY_K,
    L = c.GLFW_KEY_L,
    M = c.GLFW_KEY_M,
    N = c.GLFW_KEY_N,
    O = c.GLFW_KEY_O,
    P = c.GLFW_KEY_P,
    Q = c.GLFW_KEY_Q,
    R = c.GLFW_KEY_R,
    S = c.GLFW_KEY_S,
    T = c.GLFW_KEY_T,
    U = c.GLFW_KEY_U,
    V = c.GLFW_KEY_V,
    W = c.GLFW_KEY_W,
    X = c.GLFW_KEY_X,
    Y = c.GLFW_KEY_Y,
    Z = c.GLFW_KEY_Z,
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
