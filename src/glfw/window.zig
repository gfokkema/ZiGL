const c = @import("c").c;
const std = @import("std");
const Allocator = std.mem.Allocator;

const GLFW = @import("glfw.zig");
const Event = @import("event.zig");
const ImGui = @import("imgui.zig");

const Window = @This();

alloc: Allocator,
gui: ImGui = undefined,
queue: *GLFW.Queue = undefined,
window: *c.GLFWwindow = undefined,

const Layout = struct {
    menu: ?ImGui.Menu = undefined,
    root: ?ImGui.Root = undefined,
};

pub const WindowArgs = struct {
    width: c_int = 1280,
    height: c_int = 720,
    title: []const u8 = "My Title",
    layout: Layout = .{},
};

pub fn init(alloc: Allocator, queue: *GLFW.Queue, args: WindowArgs) !*Window {
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window = c.glfwCreateWindow(
        args.width,
        args.height,
        @ptrCast(args.title),
        null,
        null,
    ) orelse return error.CreateWindowError;
    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    const self = try alloc.create(Window);
    c.glfwSetWindowUserPointer(window, self);
    _ = c.glfwSetKeyCallback(window, key_callback);
    _ = c.glfwSetMouseButtonCallback(window, mouse_callback);
    _ = c.glfwSetFramebufferSizeCallback(window, resize_callback);

    self.* = .{
        .alloc = alloc,
        .gui = try ImGui.init(window, args.layout.menu, args.layout.root),
        .queue = queue,
        .window = window,
    };
    return self;
}

pub fn deinit(self: *Window, alloc: Allocator) void {
    self.gui.deinit();
    self.destroy();
    alloc.destroy(self);
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

pub fn size(self: *Window) @Vector(2, i32) {
    var width: i32 = undefined;
    var height: i32 = undefined;
    c.glfwGetFramebufferSize(self.window, &width, &height);
    return .{ width, height };
}

pub fn render(self: *Window) void {
    // draw here
    self.gui.render();
}

pub fn swap(self: *Window) void {
    c.glfwSwapBuffers(self.window);
}

// TODO: remove last call to gl
fn resize_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    // const ratio: f32 = width / height;
    c.glViewport(0, 0, width, height);
}

pub fn key_callback(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.c) void {
    if (c.igGetIO().*.WantCaptureKeyboard) return;

    const self: *Window = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
    const ev_action: Event.Action = @enumFromInt(action);
    const event: Event.Event = switch (ev_action) {
        .PRESS => .{ .key_down = @enumFromInt(key) },
        .REPEAT => .{ .key_repeat = @enumFromInt(key) },
        .RELEASE => .{ .key_up = @enumFromInt(key) },
    };
    self.queue.stack.appendBounded(event) catch {};
}

pub fn mouse_callback(window: ?*c.GLFWwindow, button: c_int, action_c: c_int, _: c_int) callconv(.c) void {
    if (c.igGetIO().*.WantCaptureMouse) return;

    const self: *Window = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
    const action: Event.Action = @enumFromInt(action_c);
    const event: Event.Event = switch (action) {
        .PRESS => .{ .mouse_down = @enumFromInt(button) },
        .RELEASE => .{ .mouse_up = @enumFromInt(button) },
        else => .err,
    };
    self.queue.stack.appendBounded(event) catch {};
}
