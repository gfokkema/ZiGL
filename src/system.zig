const std = @import("std");
const Allocator = std.mem.Allocator;

const CPU = @import("cpu.zig");
const Memory = CPU.Memory;
const ROM = @import("rom.zig");
const System = @This();

cpu: CPU,
memory: Memory,
rom: ROM,

pub fn init(alloc: Allocator, path: []const u8) !System {
    const memory = try Memory.init(alloc);
    return .{
        .cpu = .{ .memory = memory },
        .memory = memory,
        .rom = try ROM.init(alloc, path),
    };
}

pub fn deinit(self: *System, alloc: Allocator) void {
    self.rom.deinit();
    self.memory.deinit(alloc);
}

pub fn check(self: *System) !void {
    self.rom.header().print();
    try self.rom.check();
}

pub fn cpu_status(self: *System) void {
    self.cpu.print();
}
