const c = @import("c");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GL = @import("glfw/gl.zig");
const GLFW = @import("glfw/glfw.zig");
const Key = GLFW.Key;

fn Vec2(T: type) type {
    return packed struct {
        x: T,
        y: T,
        fn init(x: T, y: T) Vec2(T) {
            return .{ .x = x, .y = y };
        }
    };
}
fn Vec3(T: type) type {
    return packed struct {
        x: T,
        y: T,
        z: T,
        fn init(x: T, y: T, z: T) Vec3(T) {
            return .{ .x = x, .y = y, .z = z };
        }
    };
}
fn Vertex(T: type) type {
    return packed struct {
        pos: Vec3(T),
        tex: Vec2(T),
    };
}

const vertices = [_]Vertex(f32){
    .{
        .pos = Vec3(f32).init(-0.5, -0.5, 0),
        .tex = Vec2(f32).init(0, 0),
    },
    .{
        .pos = Vec3(f32).init(-0.5, 1, 0),
        .tex = Vec2(f32).init(0, 1),
    },
    .{
        .pos = Vec3(f32).init(0.5, 1, 0),
        .tex = Vec2(f32).init(1, 1),
    },
    .{
        .pos = Vec3(f32).init(-0.5, -0.5, 0),
        .tex = Vec2(f32).init(0, 0),
    },
    .{
        .pos = Vec3(f32).init(0.5, 1, 0),
        .tex = Vec2(f32).init(1, 1),
    },
    .{
        .pos = Vec3(f32).init(0.5, -0.5, 0),
        .tex = Vec2(f32).init(1, 0),
    },
};
const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var queue = GLFW.Queue.init(alloc);
    defer queue.deinit();

    try GLFW.init();
    defer GLFW.deinit();

    var window: GLFW.Window = undefined;
    try GLFW.Window.init(&window, &queue, .{});
    defer window.deinit();

    const vao = GL.VAO.init();
    defer vao.deinit();
    const vbo = GL.VBO.init(.Array);
    defer vbo.deinit();

    vao.attrib(&vbo, 0, 3, @sizeOf(Vertex(f32)));
    vao.attrib(&vbo, 1, 2, @sizeOf(Vertex(f32)));
    vbo.upload(Vertex(f32), &vertices);

    const program = try GL.program(
        alloc,
        "res/texture.vs",
        "res/texture.fs",
    );
    defer program.deinit();

    const texture = GL.texture();
    defer texture.deinit();

    program.attribs();
    std.debug.print("uniforms: {}\n", .{program.get(.ACTIVE_UNIFORMS)});

    while (!window.is_close()) {
        while (queue.readItem()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    Key.ESC, Key.Q => window.close(),
                    else => std.log.debug("key `{}` not implemented yet\n", .{k}),
                },
                .key_repeat => {},
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        GL.clearColor(.{});
        GL.clear();
        program.use();
        vao.bind();
        GL.draw(.GL_TRIANGLES);
        vao.unbind();

        window.render();
        window.swap();
        window.poll();
    }
}
