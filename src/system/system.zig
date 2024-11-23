const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CPU = @import("cpu.zig");
pub const Memory = CPU.Memory;
pub const ROM = @import("rom.zig");

const System = @This();

cpu: CPU,
memory: Memory,

pub fn init(alloc: Allocator) !System {
    const memory = try Memory.init(alloc);
    return .{
        .cpu = .{ .memory = memory },
        .memory = memory,
    };
}

pub fn deinit(self: *System, alloc: Allocator) void {
    self.memory.deinit(alloc);
}

pub fn cpu_status(self: *System) void {
    self.cpu.print();
}

pub fn load(self: *System, rom: *ROM) void {
    switch (rom.header().mode) {
        ROM.Mode.lorom => {
            self.load_lo(rom);
        },
        else => |t| std.debug.panic("unimplemented: {any}", .{t}),
    }
}

pub fn load_lo(self: *System, rom: *ROM) void {
    var start: usize = 0;
    for (self.memory.banks[0x80..]) |*b| {
        if (start >= rom.data.len) return;
        const end = @min(start + 0x8000, rom.data.len);
        @memcpy(b[0x8000..0x10000], rom.data[start .. start + 0x8000]);
        start += end;
    }
}
