const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;
const System = @import("system/system.zig");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa.deinit() == Check.ok);
    // const alloc = gpa.allocator();

    var memory = System.Memory.init();
    defer memory.deinit();

    const rom = try System.ROM.init("res/tetris.gb", memory.data[0..]);
    defer rom.deinit();

    // try rom.check();
    std.debug.print("{f}\n", .{rom.header()});
    std.debug.print("{any}\n", .{System.Memory.Section.init(0x4100)});
    // rom.header().checksum();

    var cpu = System.CPU{};
    for (0..20000) |_| {
        // if (i % 5 == 0) system.cpu.print();
        try cpu.step(&memory);
    }
}
