const std = @import("std");
const c = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("epoxy/glx.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("imgui.h");
});

fn error_callback(err: c_int, c_desc: [*c]const u8) callconv(.C) void {
    const desc = std.mem.span(c_desc);
    std.debug.print("ERROR {d}: {s}\n", .{ err, desc });
    @panic("");
}

pub fn init() !void {
    _ = c.glfwSetErrorCallback(error_callback);
    if (c.glfwInit() == 0) return error.InitError;
}

pub fn deinit() void {
    c.glfwTerminate();
}

pub const Window = struct {
    window: *c.GLFWwindow,

    fn key_callback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        _ = mods;
        if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS)
            c.glfwSetWindowShouldClose(window, 1);
    }

    pub fn init() !Window {
        const window = c.glfwCreateWindow(640, 480, "My Title", null, null) orelse return error.CreateWindowError;
        errdefer c.glfwDestroyWindow(window);

        _ = c.glfwSetKeyCallback(window, key_callback);
        c.glfwMakeContextCurrent(window);
        c.glfwSwapInterval(1);

        return .{ .window = window };
    }

    pub fn deinit(self: *Window) void {
        c.glfwDestroyWindow(self.window);
    }

    pub fn activate(self: *Window) void {
        if (self.is_active()) return;

        std.debug.print("activating: {}\n", .{self});
        c.glfwMakeContextCurrent(self.window);
    }

    pub fn is_active(self: *Window) bool {
        return c.glfwGetCurrentContext() == self.window;
    }

    pub fn should_close(self: *Window) bool {
        return c.glfwWindowShouldClose(self.window) == 1;
    }

    pub fn render(self: *Window) void {
        var width: c_int = 0;
        var height: c_int = 0;
        c.glfwGetFramebufferSize(self.window, &width, &height);
        // const ratio: f32 = width / height;

        c.glViewport(0, 0, width, height);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // draw here

        c.glfwSwapBuffers(self.window);
        c.glfwPollEvents();
    }
};
