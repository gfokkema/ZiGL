const c = @import("c");
const std = @import("std");
const zlm = @import("zlm");
const zobj = @import("zobj");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GL = @import("glfw/gl.zig");
const GLFW = @import("glfw/glfw.zig");
const Key = GLFW.Key;
const Image = @import("glfw/image.zig");

const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);
const Vertex = extern struct {
    pos: Vec3,
    tex: Vec2,
    tex_id: i32 = 0,
};
const ArrayBuffer = GL.VBO.vbo(.Array, Vertex);
const ElementBuffer = GL.VBO.vbo(.Element, u32);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var queue = GLFW.Queue.init(alloc);
    defer queue.deinit();

    try GLFW.init();
    defer GLFW.deinit();

    var window = try GLFW.Window.init(alloc, &queue, .{});
    defer window.deinit();

    var model = try zobj.parseObj(alloc, @embedFile("res/cube.obj"));
    defer model.deinit(alloc);
    var material = try zobj.parseMtl(alloc, @embedFile("res/cube.mtl"));
    defer material.deinit(alloc);
    var vertices = std.ArrayList(Vertex).init(alloc);
    defer vertices.deinit();
    for (model.meshes) |m| {
        std.debug.print("{any}\n", .{m.name});
        for (m.indices) |i| {
            const v: *align(4) Vec3 = @ptrCast(@constCast(&model.vertices[i.vertex.? * 3]));
            const t: *align(4) Vec2 = @ptrCast(@constCast(&model.tex_coords[i.tex_coord.? * 2]));
            try vertices.append(.{
                .pos = v.*,
                .tex = t.*,
            });
        }
    }

    const program = try GL.program(
        alloc,
        "res/cube.vs",
        "res/cube.fs",
    );
    defer program.deinit();
    program.attribs();
    program.uniforms();

    const vao = GL.VAO.init();
    defer vao.deinit();
    const vbo = ArrayBuffer.init();
    defer vbo.deinit();

    vao.bind();
    vbo.bind();
    vao.attrib(f32, 0, 3, @sizeOf(Vertex), 0);
    vao.attrib(f32, 1, 2, @sizeOf(Vertex), @sizeOf(Vec3));
    vao.attrib(u32, 2, 1, @sizeOf(Vertex), @sizeOf(Vec3) + @sizeOf(Vec2));

    vao.unbind();
    vbo.upload(vertices.items);
    vbo.unbind();

    const image = Image.init("res/debug_texture.jpg");
    defer image.deinit();

    const texture = GL.texture();
    defer texture.deinit();
    texture.bind();
    texture.upload(0, image);

    const mvp = zlm.Mat4.createPerspective(
        std.math.degreesToRadians(90),
        1.25,
        0.1,
        1000,
    );

    program.use();
    const loc = c.glGetUniformLocation(program.handle, "mvp");
    _ = c.glUniformMatrix4fv(loc, 1, c.GL_FALSE, @ptrCast(&mvp));
    std.debug.print("loc: {d}, {any}\n", .{ loc, mvp });

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
        texture.bind();

        vao.bind();
        GL.draw(.Triangles, 36);
        vao.unbind();

        window.render();
        window.swap();
        window.poll();
    }
}
