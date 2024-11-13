const std = @import("std");
const Allocator = std.mem.Allocator;

const CPU = @import("cpu.zig");
const Memory = []u8;
const ROM = @import("rom.zig");
const System = @This();

cpu: CPU,
memory: Memory,
rom: ROM,

pub fn init(alloc: Allocator, path: []const u8) !System {
    const rom = try ROM.init(alloc, path);
    return .{
        .cpu = .{},
        .memory = try alloc.alloc(u8, 0xFF * 0xFFFF),
        .rom = rom,
    };
}

pub fn deinit(self: *System, alloc: Allocator) void {
    self.rom.deinit();
    alloc.free(self.memory);
}

pub fn check(self: *System) !void {
    self.rom.header().print();
    try self.rom.check();
}

pub fn cpu_status(self: *System) void {
    self.cpu.print();
}
