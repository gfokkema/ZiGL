const std = @import("std");

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

pub fn init() Memory {
    return .{};
}

pub fn deinit(_: Memory) void {}

pub fn get(self: Memory, addr: u16) u8 {
    const section = Section.init(addr);
    return switch (section) {
        else => self.data[addr],
    };
}

pub fn fget(self: Memory, addr: u8) u8 {
    return self.get(@intCast(@as(i32, @intCast(0xFF00)) + addr));
}

pub fn set(self: *Memory, addr: u16, value: anytype) void {
    const section = Section.init(addr);
    return switch (section) {
        else => self.data[addr] = value,
    };
}

pub fn fset(self: *Memory, addr: u8, value: anytype) void {
    self.set(@intCast(@as(i32, @intCast(0xFF00)) + addr), value);
}

pub fn slice(self: *Memory, addr: u16) []u8 {
    const section = Section.init(addr);
    return switch (section) {
        else => self.data[addr..],
    };
}
