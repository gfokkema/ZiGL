const std = @import("std");
const Allocator = std.mem.Allocator;
const ROM = @import("rom.zig");

pub const Section = enum(u16) {
    IE = 0xFFFF,
    HRAM = 0xFF80,
    IO = 0xFF00,
    _2 = 0xFEA0,
    OAM = 0xFE00,
    _1 = 0xE000,
    WRAM_2 = 0xD000,
    WRAM_1 = 0xC000,
    ERAM = 0xA000,
    VRAM = 0x8000,
    BANK_X = 0x4000,
    BANK_0 = 0x0000,

    pub fn init(addr: u16) Section {
        for (std.enums.values(Section)) |e| {
            if (addr >= @intFromEnum(e)) return e;
        } else return .BANK_0;
    }
};
const Memory = @This();

data: [0x10000]u8 = std.mem.zeroes([0x10000]u8),
rom: ROM,

pub fn init(rom: ROM) !Memory {
    return .{
        .rom = rom,
    };
}

pub fn deinit(_: Memory) void {}

pub fn get(self: Memory, addr: u16) !u8 {
    return switch (Section.init(addr)) {
        .BANK_0 => self.rom.data[addr],
        else => self.data[addr],
    };
}

pub fn ffget(self: Memory, addr: u8) !u8 {
    return self.get(@intCast(@as(i32, @intCast(0xFF00)) + addr));
}

pub fn set(self: *Memory, addr: u16, value: anytype) !void {
    return switch (Section.init(addr)) {
        .BANK_0 => return error.ReadOnlyROM,
        else => self.data[addr] = value,
    };
}

pub fn ffset(self: *Memory, addr: u8, value: anytype) !void {
    try self.set(@intCast(@as(i32, @intCast(0xFF00)) + addr), value);
}

pub fn slice(self: *Memory, addr: u16) []u8 {
    return switch (Section.init(addr)) {
        .BANK_0 => self.rom.data[addr..],
        else => |e| std.debug.panic("Not implemented: {any}", .{e}),
    };
}
