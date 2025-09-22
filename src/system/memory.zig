const std = @import("std");
const Allocator = std.mem.Allocator;
const IO = @import("io.zig");
const ROM = @import("rom.zig");

pub const Linear = @import("memory/linear.zig");

const Memory = @This();

pub fn ffget(self: anytype, addr: u8) !u8 {
    return self.get(@as(u16, @intCast(addr)) + 0xFF00);
}

pub fn ffset(self: anytype, addr: u8, value: anytype) !void {
    try self.set(@as(u16, @intCast(addr)) + 0xFF00, value);
}

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

    pub fn init(alloc: Allocator, rom: ROM) !*Mapper {
        const ret = try alloc.create(Mapper);
        ret.* = .{
            .rom = rom,
            .io = IO.init(&ret.data, @intFromEnum(Section.IO)),
        };
        return ret;
    }

    pub fn deinit(self: *Mapper, alloc: Allocator) void {
        self.rom.deinit(alloc);
        alloc.destroy(self);
    }

    pub fn get(self: *Mapper, addr: u16) !u8 {
        return switch (Section.init(addr)) {
            .BANK_0 => self.rom.data[addr],
            .IO => self.io.get(addr - @intFromEnum(Section.IO)),
            else => self.data[addr],
        };
    }

    pub fn set(self: *Mapper, addr: u16, value: anytype) !void {
        switch (Section.init(addr)) {
            .BANK_0 => return error.ReadOnlyROM,
            .IO => try self.io.set(addr - @intFromEnum(Section.IO), value),
            else => self.data[addr] = value,
        }
    }

    pub fn slice(self: *Mapper, addr: u16) []u8 {
        return switch (Section.init(addr)) {
            .BANK_0 => self.rom.data[addr..],
            // else => |e| std.debug.panic("Not implemented: {any}", .{e}),
            else => self.data[addr..],
        };
    }
};
