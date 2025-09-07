const std = @import("std");
const Allocator = std.mem.Allocator;
const CPU = @import("cpu.zig");

const ROM = @This();

const HDR_OFFS = 0x100;
const HDR_END = 0x14F;
const MAX_BUFF = 16 * 1024 * 1024;

const Size = u8;
const Cartridge = enum(u8) {
    ROM_ONLY = 0x00,
    MBC1 = 0x01,
    _,
};

const RamSize = enum(u8) {
    NO_RAM = 0x0,
    UNUSED = 0x01,
    SIZE_8KB = 0x02,
    SIZE_32KB = 0x03,
    SIZE_128KB = 0x04,
    SIZE_64KB = 0x05,
};

const Header = extern struct {
    entrypoint: [0x4]u8, // 0x00
    logo: [0x30]u8, // 0x04
    title: [0x10]u8, // 0x134
    _1: [2]u8, // 0x144
    sgb: u8, // 0x146
    cartridge: Cartridge,
    rom_size: Size,
    ram_size: RamSize,
    country: enum(u8) { JAPAN = 0x0, WORLD = 0x1 },
    _2: u8,
    version: u8,
    chksum_header: u8,
    chksum_global: u16,

    pub fn check(self: Header) void {
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
    }

    pub fn checksum(self: *Header) void {
        const data: *[0x50]u8 = @ptrCast(self);
        var total: u8 = 0;
        for (data[0x34..0x4C]) |b| total = total -% b -% 1;
        std.debug.print("checksum: {x}\n", .{total});

        var all_total: u16 = 0;
        for (data[0..0x4E]) |b| all_total = all_total +% @as(u16, @intCast(b));
        std.debug.print("checksum: {x}\n", .{all_total});
        std.debug.print("endian: {x}\n", .{std.mem.readInt(u16, @ptrCast(&all_total), .big)});
    }

    pub fn format(self: Header, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print(
            \\Header {{
            \\  .entrypoint = {x},
            \\  .title = "{s}",
            \\  .cartridge = {any},
            \\  .rom = {any},
            \\  .ram = {any},
            \\  .checksums = {{
            \\    header: {any}
            \\    global: {x}
            \\  }}
            \\}}
        , .{ self.entrypoint, self.title, self.cartridge, self.rom_size, self.ram_size, self.chksum_header, self.chksum_global });
    }
};

data: []u8,

pub fn init(alloc: Allocator, path: []const u8) !ROM {
    const data = try std.fs.cwd().readFileAlloc(alloc, path, MAX_BUFF);
    return .{ .data = data };
}

pub fn deinit(self: ROM, alloc: Allocator) void {
    alloc.free(self.data);
}

pub fn header(self: *const ROM) *Header {
    return @ptrCast(@alignCast(self.data[HDR_OFFS .. HDR_OFFS + HDR_END].ptr));
}
