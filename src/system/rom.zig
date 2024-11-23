const std = @import("std");
const Allocator = std.mem.Allocator;

const HDROFFS = 0x8000 - 0x40;
const VECOFFS = 0x8000 - 0x20;
const MAXBUFF = 16 * 1024 * 1024;

pub const Mode = enum(u8) {
    lorom = 0x20,
    hirom = 0x21,
    sa1rom = 0x23,
    fastlorom = 0x30,
    fasthirom = 0x31,
    sdd1rom = 0x32,
    exhirom = 0x35,
};

const Header = extern struct {
    const Vector = enum(u16) {
        NM_COP = 0xFFE4,
        NM_BRK = 0xFFE6,
        NM_NMI = 0xFFEA,
        NM_IRQ = 0xFFEE,
        EM_COP = 0xFFF4,
        EM_NMI = 0xFFFA,
        EM_RST = 0xFFFC,
        EM_IRQ = 0xFFFE,
    };

    title: [21]u8,
    mode: Mode,
    romtype: u8,
    romsize: u8,
    sramsize: u8,
    devid: u8,
    version: u8,
    chksumc: u16,
    chksum: u16,
    vectors: [16]u16,

    pub fn checksum(self: *Header, sum: u16) void {
        self.chksumc = sum ^ 0xFFFF;
        self.chksum = sum ^ 0x0000;
    }

    pub fn print(self: *const Header) void {
        std.debug.print("title:     {s}\n", .{self.title});
        std.debug.print("mode:      {s}\n", .{@tagName(self.mode)});
        std.debug.print("type:      {b:0>8}\n", .{self.romtype});
        std.debug.print("rom size:  {d}\n", .{std.math.shl(u32, 0x400, self.romsize)});
        std.debug.print("sram size: {d}\n", .{std.math.shl(u32, 0x400, self.sramsize)});
        std.debug.print("devid:     0x{x:0>2}\n", .{self.devid});
        std.debug.print("version:   0x{x:0>2}\n", .{self.version});
        std.debug.print("chksumc:   0x{x:0>4}\n", .{std.mem.bigToNative(u16, self.chksumc)});
        std.debug.print("chksum:    0x{x:0>4}\n", .{std.mem.bigToNative(u16, self.chksum)});
        std.debug.print("vectors:\n", .{});
        for (0.., self.vectors) |i, v| {
            std.debug.print(" [0x{x:0>2}] 0x{x:0>4}\n", .{ VECOFFS + i * 2, v });
        }
        std.debug.print("\n", .{});
    }
};

const ROM = @This();

alloc: Allocator,
data: []u8,

pub fn init(alloc: Allocator, rom: []const u8) !ROM {
    const data = try std.fs.cwd().readFileAlloc(alloc, rom, MAXBUFF);
    return ROM{ .alloc = alloc, .data = data };
}

pub fn clone(self: *ROM, alloc: Allocator) !ROM {
    const data = try alloc.alloc(u8, self.data.len);
    @memcpy(data, self.data);
    return ROM{ .data = data };
}

pub fn deinit(self: *ROM) void {
    self.alloc.free(self.data);
}

pub fn header(self: *const ROM) *Header {
    return @ptrCast(@alignCast(self.data[HDROFFS .. HDROFFS + 0x40].ptr));
}

pub fn check(self: *const ROM) !void {
    const h = self.header();
    std.debug.assert(h.chksum == h.chksumc ^ 0xFFFF);

    var chk: u16 = 0;
    for (self.data) |elem| {
        chk = @addWithOverflow(chk, elem)[0];
    }

    if (h.chksum != chk) return error.CRCError;
}

pub fn args(self: *const ROM, instr: usize, bytes: usize) []u8 {
    return self.data[instr + 1 .. instr + bytes];
}
