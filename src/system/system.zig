const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CPU = @import("cpu.zig");
pub const Memory = @import("memory.zig");
pub const ROM = @import("rom.zig");

pub const System = GenericSystem(Memory.Mapper);
pub const MemorySystem = GenericSystem(Memory.Linear);

pub fn GenericSystem(comptime M: type) type {
    return struct {
        const Self = @This();
        cpu: CPU,
        memory: M,

        pub fn init(cpu: CPU, memory: M) !System {
            return .{
                .cpu = cpu,
                .memory = memory,
            };
        }

        pub fn initAlloc(alloc: Allocator, path: []const u8) !Self {
            const rom = try ROM.init(alloc, path);
            std.debug.print("{f}\n", .{rom.header()});
            // try rom.check();
            // rom.header).checksum();
            return init(CPU.init_dmg(), Memory.Mapper.init(rom));
        }

        pub fn deinit(self: *Self, alloc: Allocator) void {
            self.memory.deinit(alloc);
        }

        pub fn step(self: *Self) !void {
            const op = try self.cpu.next(&self.memory);
            try op.exec(&self.cpu, &self.memory);

            std.debug.print("0x{x:0>4}: {f}\n", .{ self.cpu.pc.u16, try self.cpu.next(&self.memory) });
        }
    };
}
