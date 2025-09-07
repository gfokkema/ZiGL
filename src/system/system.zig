const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CPU = @import("cpu.zig");
pub const Memory = @import("memory.zig");
pub const ROM = @import("rom.zig");

const System = @This();

cpu: CPU,
memory: Memory,
rom: ROM,

pub fn init(alloc: Allocator, path: []const u8) !System {
    const rom = try ROM.init(alloc, path);
    std.debug.print("{f}\n", .{rom.header()});
    // try rom.check();
    // rom.header().checksum();
    return .{
        .cpu = CPU{},
        .memory = try Memory.init(rom),
        .rom = rom,
    };
}

pub fn deinit(self: System, alloc: Allocator) void {
    self.rom.deinit(alloc);
    self.memory.deinit();
}

pub fn step(self: *System) !void {
    try self.cpu.step(&self.memory);
}
