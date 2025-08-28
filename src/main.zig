const std = @import("std");
const Allocator = std.mem.Allocator;
const Check = std.heap.Check;
const System = @import("system/system.zig");
const ROM = System.ROM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == Check.ok);
    const alloc = gpa.allocator();

    var system = try System.init(alloc);
    defer system.deinit(alloc);

    var rom = try ROM.init(alloc, "res/cpu_instrs.gb");
    defer rom.deinit();
    // try rom.check();
    std.debug.print("{f}\n", .{rom.header()});

    std.debug.print("debug: {*}\n", .{system.memory.banks});
    std.debug.print("debug: {*}\n", .{system.cpu.memory.banks});

    // system.load(&rom);
    // for (0..20) |_| {
    //     // if (i % 5 == 0) system.cpu.print();
    //     system.cpu.step();
    // }
}
