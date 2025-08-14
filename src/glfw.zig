const c = @import("c");
const std = @import("std");
const zlm = @import("zlm");
const zobj = @import("zobj");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GL = @import("gl/gl.zig");
const GLFW = @import("glfw/glfw.zig");

const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);
const Vertex = extern struct {
    pos: Vec3,
    tex: Vec2,
    tex_id: i32,
};
const ArrayBuffer = GL.VBO.vbo(.Array, Vertex);
const ElementBuffer = GL.VBO.vbo(.Element, u32);

fn load_model(alloc: Allocator, obj: []const u8, mtl: []const u8) !std.ArrayList(Vertex) {
    var model = try zobj.parseObj(alloc, obj);
    defer model.deinit(alloc);
    var material = try zobj.parseMtl(alloc, mtl);
    defer material.deinit(alloc);
    var vertices = std.ArrayList(Vertex).init(alloc);
    for (model.meshes) |m| {
        std.debug.print("{?s}\n", .{m.name});
        for (m.indices) |i| {
            const v: *align(4) Vec3 = @ptrCast(@constCast(&model.vertices[i.vertex.? * 3]));
            const t: *align(4) Vec2 = @ptrCast(@constCast(&model.tex_coords[i.tex_coord.? * 2]));
            try vertices.append(.{
                .pos = v.*,
                .tex = t.*,
                .tex_id = 0,
            });
        }
        for (m.indices) |i| {
            const v: *align(4) Vec3 = @ptrCast(@constCast(&model.vertices[i.vertex.? * 3]));
            const t: *align(4) Vec2 = @ptrCast(@constCast(&model.tex_coords[i.tex_coord.? * 2]));
            try vertices.append(.{
                .pos = .{ v[0] + 4, v[1], v[2] },
                .tex = t.*,
                .tex_id = 1,
            });
        }
    }
    return vertices;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var glfw = try GLFW.init(alloc);
    defer glfw.deinit();

    var window = try glfw.window(alloc);
    defer window.deinit();

    const vertices = try load_model(
        alloc,
        @embedFile("res/cube.obj"),
        @embedFile("res/cube.mtl"),
    );
    defer vertices.deinit();

    var program = try GL.program(
        alloc,
        "res/cube.vs",
        "res/cube.fs",
    );
    defer program.deinit();

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

    const image_1 = GL.Image.init("res/debug_texture.jpg");
    defer image_1.deinit();
    const texture_1 = GL.texture();
    defer texture_1.deinit();

    const image_2 = GL.Image.init("res/debug2.jpeg");
    defer image_2.deinit();
    const texture_2 = GL.texture();
    defer texture_2.deinit();

    texture_1.bind(.UNIT_0);
    texture_1.upload(0, image_1);
    texture_2.bind(.UNIT_1);
    texture_2.upload(0, image_2);

    const mvp = zlm.Mat4.createPerspective(
        std.math.degreesToRadians(90),
        1.25,
        0.1,
        1000,
    );

    program.use();
    program.uniform("mvp", .Mat4).set(&mvp);
    program.uniform("tex[0]", .Sampler2D).set(0);
    program.uniform("tex[1]", .Sampler2D).set(1);

    while (!window.is_close()) {
        while (glfw.next()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    .ESC, .Q => window.close(),
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
        GL.draw(.Triangles, 72);
        vao.unbind();

        window.render();
        window.swap();
        window.poll();
    }
}
