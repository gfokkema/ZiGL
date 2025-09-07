const std = @import("std");
const zlm = @import("zlm").SpecializeOn(f32);
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const Camera = @import("camera.zig");
const GL = @import("gl/gl.zig");
const GLFW = @import("glfw/glfw.zig");
const System = @import("system/system.zig");

const Args = struct {
    const path = "res/tetris.gb";
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var glfw = try GLFW.init(alloc);
    defer glfw.deinit(alloc);

    var system = try System.init(alloc, Args.path);
    defer system.deinit(alloc);

    const menu = GLFW.ImGui.Menu.init("File", &.{
        .{ .label = "Create" },
        .{ .label = "Open", .shortcut = "Ctrl+O" },
        .{ .label = "Save", .shortcut = "Ctrl+S" },
        .{ .label = "Save as.." },
    });

    const path = try std.fmt.allocPrint(alloc, "path: {s}\n", .{Args.path});
    defer alloc.free(path);
    const name = try std.fmt.allocPrint(alloc, "name: {s}\n", .{system.rom.header().title});
    defer alloc.free(name);

    const DescCPU = struct {
        pub fn desc(ctx: *anyopaque, buf: []u8) []const u8 {
            const cpu: *System.CPU = @ptrCast(@alignCast(ctx));
            return std.fmt.bufPrint(buf, "{f}", .{cpu}) catch {
                return "ERROR: NO CPU";
            };
        }
    };

    const root = GLFW.ImGui.Root.init(&.{
        GLFW.ImGui.Tree.init("ROM", &.{
            GLFW.ImGui.Text.init(path),
            GLFW.ImGui.Text.init(name),
        }),
        GLFW.ImGui.Tree.init("CPU", &.{
            GLFW.ImGui.DynamicText.init(&system.cpu, DescCPU.desc),
        }),
    });

    var window = try glfw.window(alloc, .{ .layout = .{ .menu = menu, .root = root } });
    defer window.deinit(alloc);

    var context = GL.Context(GLFW.Window).init(window);
    defer context.deinit(alloc);
    try context.viewport(window.size());

    var camera = Camera.init(.{});
    while (!window.is_close()) {
        while (glfw.queue.pop()) |e| {
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    .ESC, .Q => window.close(),
                    .UP => camera.move(zlm.vec3(0, 0, -0.1)),
                    .DOWN => camera.move(zlm.vec3(0, 0, 0.1)),
                    .RIGHT => camera.move(zlm.vec3(0.1, 0, 0)),
                    .LEFT => camera.move(zlm.vec3(-0.1, 0, 0)),
                    .P, .R => std.debug.print("{f}\n", .{system.cpu}),
                    .S, .N => try system.step(),
                    else => std.debug.print("key: `{any}` not implemented yet\n", .{k}),
                },
                .key_repeat => {},
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        context.draw(camera.mvp(), 72);

        window.render();
        window.swap();
        window.poll();
    }
}
