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

pub fn load(self: *System, rom: *ROM) void {
    switch (rom.header().mode) {
        ROM.Mode.lorom => {
            self.load_lo(rom);
        },
        else => |t| std.debug.panic("unimplemented: {any}", .{t}),
    }
}

pub fn load_lo(self: *System, rom: *ROM) void {
    var pos: usize = 0;
    for (self.memory.banks[0x80..]) |*b| {
        if (pos >= rom.data.len) return;
        const end = @min(pos + 0x8000, rom.data.len);
        @memcpy(b[0x8000..0x10000], rom.data[pos..end]);
        pos = end;
    }
}

const Range = struct {
    bank: usize = 0x80,
    start: usize = 0x0000,
    len: usize = 0x10000,
    line: usize = 0x20,
};

pub fn print_range(self: *System, range: Range) void {
    const b = self.memory.banks[range.bank];
    var start = range.start;
    while (start < range.start + range.len) {
        std.debug.print("{x:0>2}{x:0>4}  ", .{ range.bank, start });
        const end = start + range.line;
        for (b[start..end]) |e| std.debug.print("{x:0>2} ", .{e});
        std.debug.print("\n", .{});
        start = end;
    }
}
