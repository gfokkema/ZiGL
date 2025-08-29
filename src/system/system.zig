const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CPU = @import("cpu.zig");
pub const ROM = @import("rom.zig");
pub const Memory = struct {
    data: [0x10000]u8,
};

const System = @This();

cpu: CPU,
memory: Memory,

pub fn init() !System {
    return .{
        .cpu = .{},
        .memory = std.mem.zeroes(Memory),
    };
}

pub fn deinit(_: System) void {}

pub fn step(self: System, rom: ROM) void {
    self.cpu.step(rom.data, Memory.data);
}
