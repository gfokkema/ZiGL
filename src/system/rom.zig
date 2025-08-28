const std = @import("std");
const Allocator = std.mem.Allocator;

const HDROFFS = 0x100;
const MAXBUFF = 16 * 1024 * 1024;

const Header = extern struct {
    entrypoint: [4]u8,
    logo: [48]u8,
    title: [16]u8,
    _1: [2]u8,
    sgb: u8,
    cartridge: u8,
    rom_size: u8,
    ram_size: u8,
    country: u8,
    _2: u8,
    version: u8,
    chksum_header: u8,
    chksum_global: [2]u8,

    pub fn format(self: Header, writer: *std.io.Writer) std.io.Writer.Error!void {
        const logo: [12]u32 = [_]u32{
            0xceed6666,
            0xcc0d000b,
            0x03730083,
            0x000c000d,
            0x0008111f,
            0x8889000e,
            0xdccc6ee6,
            0xddddd999,
            0xbbbb6763,
            0x6e0eeccc,
            0xdddc999f,
            0xbbb9333e,
        };

        for (logo, 0..) |l, i| {
            const lh = std.mem.readInt(u32, self.logo[i * 4 ..][0..4], .big);
            std.debug.assert(l == lh);
        }
        try writer.print(
            \\Header {{
            \\  .entrypoint = {x}, .title = "{s}", .cartridge = {x}
            \\}}
        , .{ self.entrypoint, self.title, self.cartridge });
    }
};

const ROM = @This();

alloc: Allocator,
data: []u8,

pub fn init(alloc: Allocator, rom: []const u8) !ROM {
    const data = try std.fs.cwd().readFileAlloc(alloc, rom, MAXBUFF);
    return ROM{ .alloc = alloc, .data = data };
}

pub fn deinit(self: *ROM) void {
    self.alloc.free(self.data);
}

pub fn header(self: *const ROM) *Header {
    return @ptrCast(@alignCast(self.data[HDROFFS .. HDROFFS + 0x40].ptr));
}
