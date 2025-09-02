const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;
const System = @import("system/system.zig");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() == Check.ok);
    // const alloc = gpa.allocator();

    var system = try System.init();
    defer system.deinit();

    var memory = std.mem.zeroes([0xFFFFF]u8);
    const rom = try System.ROM.init("res/cpu_instrs.gb", memory[0..]);
    defer rom.deinit();

    // try rom.check();
    std.debug.print("{f}\n", .{rom.header()});
    // rom.header().checksum();

    var cpu = System.CPU{};
    for (0..200) |_| {
        // if (i % 5 == 0) system.cpu.print();
        try cpu.step(rom.data);
    }
}
