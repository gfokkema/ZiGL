const std = @import("std");
const Allocator = std.mem.Allocator;
const Memory = @import("memory.zig");
const Ops = @import("operations.zig");

const CPU = @This();

const Flags = packed union {
    v: u8,
    f: packed struct(u8) {
        c: bool = false,
        z: bool = false,
        i: bool = false,
        d: bool = false,
        v: bool = false,
        n: bool = false,
        _: u2,
    },

    pub fn format(self: Flags, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print(
            "{{ n: {}, v: {}, d: {} i: {}, z: {}, c: {} }}",
            .{ self.f.n, self.f.v, self.f.d, self.f.i, self.f.z, self.f.c },
        );
    }
};

const Register = packed union {
    u8: packed struct { a: u8, b: u8 },
    u16: u16,

    pub fn format(self: Register, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print("0x{x:0>4} [0x{x:0>2}, 0x{x:0>2}]", .{ self.u16, self.u8.a, self.u8.b });
    }
};
const Zero = Register{ .u16 = 0 };

flags: Flags = .{ .v = 0 },
pc: Register = .{ .u16 = 0x100 }, // program counter
sp: Register = Zero, // stack pointer

af: Register = Zero,
bc: Register = Zero,
de: Register = Zero,
hl: Register = Zero,

pub fn next(self: *CPU, mem: *Memory) !Ops.Ops {
    const opt = std.meta.intToEnum(Ops.OpType, try mem.get(self.pc.u16)) catch {
        std.debug.panic("Unsupported instruction: 0x{x}", .{try mem.get(self.pc.u16)});
    };
    return switch (opt) {
        inline else => |t| try Ops.Ops.init(t, mem.slice(self.pc.u16)),
    };
}

pub fn step(self: *CPU, mem: *Memory) !void {
    const op = try self.next(mem);
    try op.exec(self, mem);
    // std.debug.print("{f}\n", .{cpu});
}

pub fn format(self: CPU, writer: *std.io.Writer) std.io.Writer.Error!void {
    try writer.print("pc: {f}   sp: {f}\n", .{ self.pc, self.sp });
    try writer.print("af: {f}   bc: {f}\n", .{ self.af, self.bc });
    try writer.print("de: {f}   hl: {f}\n", .{ self.de, self.hl });
    try writer.print("flags: {f}", .{self.flags});
}
