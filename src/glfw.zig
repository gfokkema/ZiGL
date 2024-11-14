const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("epoxy/glx.h");
    @cInclude("GLFW/glfw3.h");

    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cDefine("CIMGUI_USE_GLFW", "");
    @cDefine("CIMGUI_USE_OPENGL3", "");

    @cInclude("cimgui.h");
    @cInclude("cimgui_impl.h");
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

const Imgui = struct {
    context: *c.ImGuiContext,

    fn init(window: *c.GLFWwindow) !Imgui {
        const context = c.igCreateContext(null).?;
        errdefer c.igDestroyContext(context);

        if (!c.ImGui_ImplGlfw_InitForOpenGL(window, false)) return error.InitImGuiGlfw;
        errdefer c.ImGui_ImplGlfw_Shutdown();

        if (!c.ImGui_ImplOpenGL3_Init("#version 130")) return error.InitImGuiOgl;
        errdefer c.ImGui_ImplOpenGL3_Shutdown();

        return .{ .context = context };
    }

    fn deinit(self: *Imgui) void {
        c.ImGui_ImplOpenGL3_Shutdown();
        c.ImGui_ImplGlfw_Shutdown();
        c.igDestroyContext(self.context);
    }

    fn render(_: *Imgui) void {
        c.ImGui_ImplOpenGL3_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();

        _ = c.igBegin("Hello, world!", null, 0);
        c.igText("This is some useful text.");
        c.igEnd();

        c.igRender();
        c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
    }
};

pub const Window = struct {
    gui: Imgui = undefined,
    queue: Fifo = undefined,
    window: *c.GLFWwindow = undefined,

    const FrameEvent = struct {};
    const KeyEvent = struct { key: c_int };
    const MouseEvent = struct {};
    const Event = union(enum) {
        err,
        frame: FrameEvent,
        key_down: KeyEvent,
        key_up: KeyEvent,
        mouse_down: MouseEvent,
        mouse_up: MouseEvent,
    };
    const Fifo = std.fifo.LinearFifo(Event, .Dynamic);

    fn key_callback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        _ = mods;

        const self: *Window = @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window)));
        switch (action) {
            c.GLFW_PRESS => self.queue.writeItem(.{
                .key_down = .{ .key = key },
            }) catch {},
            c.GLFW_RELEASE => self.queue.writeItem(.{
                .key_up = .{ .key = key },
            }) catch {},
            else => {},
        }
    }

    pub fn init(self: *Window, alloc: Allocator) !void {
        const window = c.glfwCreateWindow(640, 480, "My Title", null, null) orelse return error.CreateWindowError;
        errdefer c.glfwDestroyWindow(window);

        _ = c.glfwSetKeyCallback(window, key_callback);
        c.glfwMakeContextCurrent(window);
        c.glfwSwapInterval(1);

        var gui = try Imgui.init(window);
        errdefer gui.deinit();

        c.glfwSetWindowUserPointer(window, self);

        self.* = .{
            .gui = gui,
            .queue = Fifo.init(alloc),
            .window = window,
        };
    }

    pub fn deinit(self: *Window) void {
        self.queue.deinit();
        self.gui.deinit();
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

    pub fn process(self: *Window) void {
        while (self.queue.readItem()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| {
                    switch (k.key) {
                        c.GLFW_KEY_ESCAPE, c.GLFW_KEY_Q => {
                            c.glfwSetWindowShouldClose(self.window, 1);
                        },
                        else => {},
                    }
                },
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }
    }

    pub fn clear(self: *Window) void {
        var width: c_int = 0;
        var height: c_int = 0;
        c.glfwGetFramebufferSize(self.window, &width, &height);
        // const ratio: f32 = width / height;
        c.glViewport(0, 0, width, height);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    }

    pub fn render(self: *Window) void {
        // draw here
        self.gui.render();
    }

    pub fn swap(self: *Window) void {
        c.glfwSwapBuffers(self.window);
        c.glfwPollEvents();
    }
};
