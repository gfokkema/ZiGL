const std = @import("std");
const zlm = @import("zlm").as(f32);

proj: zlm.Mat4,
params: CameraParams,

const Self = @This();

const CameraParams = struct {
    pos: zlm.Vec3 = zlm.vec3(0, 0, 0),
    dir: zlm.Vec3 = zlm.vec3(0, 0, -1),
    up: zlm.Vec3 = zlm.vec3(0, 1, 0),
};

pub fn init(params: CameraParams) Self {
    return .{
        .params = params,
        .proj = zlm.Mat4.createPerspective(
            std.math.degreesToRadians(90),
            1.25,
            0.1,
            1000,
        ),
    };
}

pub fn mvp(self: Self) zlm.Mat4 {
    return self.view().mul(self.proj);
}

pub fn move(self: *Self, dir: zlm.Vec3) void {
    self.params.pos = self.params.pos.add(dir);
}

pub fn view(self: Self) zlm.Mat4 {
    return zlm.Mat4.createLook(
        self.params.pos,
        self.params.dir,
        self.params.up,
    );
}
