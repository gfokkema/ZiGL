const std = @import("std");
const Allocator = std.mem.Allocator;
const IO = @import("io.zig");
const ROM = @import("rom.zig");

const Memory = @This();

pub fn ffget(self: anytype, addr: u8) !u8 {
    return self.get(@as(u16, @intCast(addr)) + 0xFF00);
}

pub fn ffset(self: anytype, addr: u8, value: anytype) !void {
    try self.set(@as(u16, @intCast(addr)) + 0xFF00, value);
}

pub const Linear = struct {
    pub const ffget = Memory.ffget;
    pub const ffset = Memory.ffset;

    data: [0x10000]u8 = std.mem.zeroes([0x10000]u8),

    pub fn init() !Linear {
        return .{};
    }

    pub fn deinit(_: Linear) void {}

    pub fn get(self: Linear, addr: u16) !u8 {
        return self.data[addr];
    }

    pub fn set(self: *Linear, addr: u16, value: anytype) !void {
        self.data[addr] = value;
    }

    pub fn slice(self: *Linear, addr: u16) []u8 {
        return self.data[addr..];
    }
};

pub const Mapper = struct {
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
    pub const ffget = Memory.ffget;
    pub const ffset = Memory.ffset;

    data: [0x10000]u8 = std.mem.zeroes([0x10000]u8),
    rom: ROM,
    io: IO,

    pub fn init(rom: ROM) Mapper {
        return .{
            .rom = rom,
            .io = IO{},
        };
    }

    pub fn deinit(self: *Mapper, alloc: Allocator) void {
        self.rom.deinit(alloc);
    }

    pub fn get(self: Mapper, addr: u16) !u8 {
        return switch (Section.init(addr)) {
            .BANK_0 => self.rom.data[addr],
            .IO => return self.io.get(addr),
            else => self.data[addr],
        };
    }

    pub fn set(self: *Mapper, addr: u16, value: anytype) !void {
        switch (Section.init(addr)) {
            .BANK_0 => return error.ReadOnlyROM,
            .IO => return self.io.set(addr, value),
            else => self.data[addr] = value,
        }
    }

    pub fn slice(self: *Mapper, addr: u16) []u8 {
        return switch (Section.init(addr)) {
            .BANK_0 => self.rom.data[addr..],
            else => |e| std.debug.panic("Not implemented: {any}", .{e}),
            // else => self.data[addr..],
        };
    }
};
