const std = @import("std");
const stb = @cImport({
    @cInclude("stb_image.h");
});

const Params = struct {
    width: i32 = 0,
    height: i32 = 0,
    components: Channels = .default,
};

const Channels = enum(u32) {
    default = 0,
    grey = 1,
    grey_alpha = 2,
    rgb = 3,
    rgb_alpha = 4,
};

const Image = @This();

image: *anyopaque,
params: Params,

pub fn init(path: []const u8) Image {
    var params = Params{};
    stb.stbi_set_flip_vertically_on_load(1);
    const image: *u8 = @ptrCast(stb.stbi_load(
        path.ptr,
        &params.width,
        &params.height,
        @ptrCast(&params.components),
        stb.STBI_rgb,
    ));
    std.debug.print("{any}\n", .{image});

    return .{
        .image = @ptrCast(image),
        .params = params,
    };
}

pub fn deinit(self: *const Image) void {
    stb.stbi_image_free(self.image);
}
