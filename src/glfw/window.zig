const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;

const GL = @import("gl.zig");
const GLFW = @import("glfw.zig");
const Action = GLFW.Action;
const Event = GLFW.Event;
const ImGui = GLFW.ImGui;

const Window = @This();

alloc: Allocator,
gui: ImGui = undefined,
queue: *GLFW.Queue = undefined,
window: *c.GLFWwindow = undefined,

const WindowArgs = struct {
    width: c_int = 1280,
    height: c_int = 720,
};
pub fn init(alloc: Allocator, queue: *GLFW.Fifo(Event), args: WindowArgs) !*Window {
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(
        args.width,
        args.height,
        "My Title",
        null,
        null,
    ) orelse return error.CreateWindowError;
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    var width: c_int = undefined;
    var height: c_int = undefined;
    c.glfwGetFramebufferSize(window, &width, &height);
    c.glViewport(0, 0, width, height);

    const self = try alloc.create(Window);
    c.glfwSetWindowUserPointer(window, self);
    _ = c.glfwSetKeyCallback(window, key_callback);
    _ = c.glfwSetMouseButtonCallback(window, mouse_callback);
    _ = c.glfwSetFramebufferSizeCallback(window, resize_callback);

    self.* = .{
        .alloc = alloc,
        .gui = try ImGui.init(window),
        .queue = queue,
        .window = window,
    };
    return self;
}

pub fn deinit(self: *Window) void {
    self.gui.deinit();
    self.destroy();
    self.alloc.destroy(self);
}

pub fn is_active(self: *Window) bool {
    return c.glfwGetCurrentContext() == self.window;
}

pub fn is_close(self: *Window) bool {
    return c.glfwWindowShouldClose(self.window) == 1;
}

pub fn close(self: *Window) void {
    c.glfwSetWindowShouldClose(self.window, c.GLFW_TRUE);
}

pub fn poll(_: *Window) void {
    c.glfwPollEvents();
}

pub fn activate(self: *Window) void {
    if (self.is_active()) return;
    c.glfwMakeContextCurrent(self.window);
}

pub fn deactivate(self: *Window) void {
    if (self.is_active()) c.glfwMakeContextCurrent(null);
}

pub fn destroy(self: *Window) void {
    c.glfwDestroyWindow(self.window);
}

pub fn render(self: *Window) void {
    // draw here
    self.gui.render();
}

pub fn swap(self: *Window) void {
    c.glfwSwapBuffers(self.window);
}

fn resize_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    // const ratio: f32 = width / height;
    c.glViewport(0, 0, width, height);
}

pub fn key_callback(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
    if (c.igGetIO().*.WantCaptureKeyboard) return;

    const self: *Window = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
    const event: Event = switch (@as(Action, @enumFromInt(action))) {
        Action.PRESS => .{ .key_down = @enumFromInt(key) },
        Action.REPEAT => .{ .key_repeat = @enumFromInt(key) },
        Action.RELEASE => .{ .key_up = @enumFromInt(key) },
        _ => .err,
    };
    self.queue.writeItem(event) catch {};
}

pub fn mouse_callback(window: ?*c.GLFWwindow, button: c_int, action: c_int, _: c_int) callconv(.C) void {
    if (c.igGetIO().*.WantCaptureMouse) return;

    const self: *Window = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
    const event: GLFW.Event = switch (@as(Action, @enumFromInt(action))) {
        Action.PRESS => .{ .mouse_down = @enumFromInt(button) },
        Action.RELEASE => .{ .mouse_up = @enumFromInt(button) },
        else => .err,
    };
    self.queue.writeItem(event) catch {};
}
