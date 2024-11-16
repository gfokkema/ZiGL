const std = @import("std");

const GLFW = @import("glfw.zig");
const System = GLFW.System;
const c = GLFW.c;

const ImGui = @This();

context: *c.ImGuiContext,

pub fn init(window: *c.GLFWwindow) !ImGui {
    const context = c.igCreateContext(null) orelse return error.InitImGuiContext;
    errdefer c.igDestroyContext(context);

    if (!c.ImGui_ImplGlfw_InitForOpenGL(window, true)) return error.InitImGuiGlfw;
    errdefer c.ImGui_ImplGlfw_Shutdown();

    if (!c.ImGui_ImplOpenGL3_Init("#version 130")) return error.InitImGuiOgl;
    errdefer c.ImGui_ImplOpenGL3_Shutdown();

    return .{ .context = context };
}

pub fn deinit(self: *ImGui) void {
    c.ImGui_ImplOpenGL3_Shutdown();
    c.ImGui_ImplGlfw_Shutdown();
    c.igDestroyContext(self.context);
}

pub fn render(_: *ImGui) void {
    c.ImGui_ImplOpenGL3_NewFrame();
    c.ImGui_ImplGlfw_NewFrame();
    c.igNewFrame();

    if (c.igCollapsingHeader_TreeNodeFlags("a", c.ImGuiTreeNodeFlags_DefaultOpen))
        c.igText("debug1");

    if (c.igCollapsingHeader_TreeNodeFlags("b", c.ImGuiTreeNodeFlags_DefaultOpen)) {
        if (!c.igBeginTable("table", 4, 0, c.ImVec2{}, 0)) return;
        c.igTableNextRow(0, 0);
        if (c.igTableNextColumn()) c.igText("Key");
        if (c.igTableNextColumn()) c.igText("Value");
        c.igEndTable();
    }

    if (c.igCollapsingHeader_TreeNodeFlags("c", c.ImGuiTreeNodeFlags_DefaultOpen))
        c.igText("debug2");

    c.igRender();
    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}
