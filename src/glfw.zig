const c = @import("c").c;
const std = @import("std");
const zlm = @import("zlm").SpecializeOn(f32);
const zobj = @import("zobj");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;

const GL = @import("gl/gl.zig");
const GLFW = @import("glfw/glfw.zig");
const Camera = @import("camera.zig");

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
    var vertices = try std.ArrayListUnmanaged(Vertex).initCapacity(alloc, 1024);
    for (model.meshes) |m| {
        std.debug.print("{?s}\n", .{m.name});
        for (m.indices) |i| {
            const v: *align(4) Vec3 = @ptrCast(@constCast(&model.vertices[i.vertex.? * 3]));
            const t: *align(4) Vec2 = @ptrCast(@constCast(&model.tex_coords[i.tex_coord.? * 2]));
            try vertices.append(alloc, .{
                .pos = v.*,
                .tex = t.*,
                .tex_id = 0,
            });
        }
        for (m.indices) |i| {
            const v: *align(4) Vec3 = @ptrCast(@constCast(&model.vertices[i.vertex.? * 3]));
            const t: *align(4) Vec2 = @ptrCast(@constCast(&model.tex_coords[i.tex_coord.? * 2]));
            try vertices.append(alloc, .{
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
    defer glfw.deinit(alloc);

    var window = try glfw.window(alloc);
    defer window.deinit();

    var context = GL.Context(GLFW.Window).init(window);
    defer context.deinit();

    try context.viewport();
    try context.create_program(alloc, "res/cube.vs", "res/cube.fs");

    var vertices = try load_model(
        alloc,
        @embedFile("res/cube.obj"),
        @embedFile("res/cube.mtl"),
    );
    defer vertices.deinit(alloc);

    const vao = GL.VAO.init();
    defer vao.deinit();
    const vbo = ArrayBuffer.init();
    defer vbo.deinit();

    vao.bind();
    vbo.bind();
    try vao.attrib(f32, 0, 3, @sizeOf(Vertex), 0);
    try vao.attrib(f32, 1, 2, @sizeOf(Vertex), @sizeOf(Vec3));
    try vao.attrib(u32, 2, 1, @sizeOf(Vertex), @sizeOf(Vec3) + @sizeOf(Vec2));
    vao.unbind();

    vbo.upload(vertices.items);
    vbo.unbind();

    const image_1 = GL.Image.init("res/debug_texture.jpg");
    defer image_1.deinit();
    var texture_1 = context.create_texture();
    defer texture_1.deinit();

    const image_2 = GL.Image.init("res/debug2.jpeg");
    defer image_2.deinit();
    var texture_2 = context.create_texture();
    defer texture_2.deinit();

    texture_1.bind(.UNIT_0);
    texture_1.upload(0, image_1);
    texture_2.bind(.UNIT_1);
    texture_2.upload(0, image_2);

    var camera = Camera.init(.{});
    var program = context.state.program.?;
    program.use();
    try program.uniform("mvp", .Mat4).set(&camera.mvp());
    try program.uniform("tex[0]", .Sampler2D).set(texture_1);
    try program.uniform("tex[1]", .Sampler2D).set(texture_2);

    while (!window.is_close()) {
        while (glfw.next()) |e| {
            std.debug.print("event: {any}\n", .{e});
            switch (e) {
                .err => {},
                .frame => {},
                .key_down => |k| switch (k) {
                    .ESC, .Q => window.close(),
                    .UP => camera.move(zlm.vec3(0, 0, -0.1)),
                    .DOWN => camera.move(zlm.vec3(0, 0, 0.1)),
                    .RIGHT => camera.move(zlm.vec3(0.1, 0, 0)),
                    .LEFT => camera.move(zlm.vec3(-0.1, 0, 0)),
                    else => std.debug.print("key: `{any}` not implemented yet\n", .{k}),
                },
                .key_repeat => {},
                .key_up => {},
                .mouse_down => {},
                .mouse_up => {},
            }
        }

        context.clearColor(.{});
        context.clear();

        program.use();
        try program.uniform("mvp", .Mat4).set(&camera.mvp());

        vao.bind();
        context.draw(.Triangles, 72);
        vao.unbind();

        window.render();
        window.swap();
        window.poll();
    }
}
