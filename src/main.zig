const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;
const System = @import("system/system.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var system = try System.init();
    defer system.deinit();

    var rom = try System.ROM.init(alloc, "res/cpu_instrs.gb");
    defer rom.deinit();

    // try rom.check();
    std.debug.print("{f}\n", .{rom.header()});
    // rom.header().checksum();

    var cpu = System.CPU{};
    for (0..200) |_| {
        // if (i % 5 == 0) system.cpu.print();
        cpu.step(rom.data, &system.memory.data);
    }
}
