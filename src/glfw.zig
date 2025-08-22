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
    defer window.deinit(alloc);

    var context = GL.Context(GLFW.Window).init(window);
    defer context.deinit();
    try context.viewport(window.size());

    var vertices = try load_model(alloc, @embedFile("res/cube.obj"), @embedFile("res/cube.mtl"));
    defer vertices.deinit(alloc);

    const vao = GL.VAO.init();
    defer vao.deinit();
    const vbo = GL.ArrayBuffer(Vertex).init();
    defer vbo.deinit();

    vao.bind();
    vbo.bind();
    try vao.attrib(f32, 0, 3, @sizeOf(Vertex), 0);
    try vao.attrib(f32, 1, 2, @sizeOf(Vertex), @sizeOf(Vec3));
    try vao.attrib(u32, 2, 1, @sizeOf(Vertex), @sizeOf(Vec3) + @sizeOf(Vec2));
    vao.unbind();

    vbo.upload(vertices.items);
    vbo.unbind();

    const texture_1 = context.create_texture(.UNIT_0, "res/debug_texture.jpg");
    defer texture_1.deinit();
    const texture_2 = context.create_texture(.UNIT_1, "res/debug2.jpeg");
    defer texture_2.deinit();

    try context.create_program(alloc, "res/cube.vs", "res/cube.fs");
    context.program.use();
    try context.program.uniform("tex[0]", .Sampler2D).set(texture_1);
    try context.program.uniform("tex[1]", .Sampler2D).set(texture_2);

    var camera = Camera.init(.{});

    while (!window.is_close()) {
        while (glfw.queue.pop()) |e| {
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

        context.draw(vao, camera.mvp(), 72);

        window.render();
        window.swap();
        window.poll();
    }
}
