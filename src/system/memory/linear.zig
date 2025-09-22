const std = @import("std");
const Allocator = std.mem.Allocator;

const Memory = @import("../memory.zig");

pub const ffget = Memory.ffget;
pub const ffset = Memory.ffset;

const Linear = @This();

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
