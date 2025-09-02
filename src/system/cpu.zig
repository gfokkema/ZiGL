const std = @import("std");
const Allocator = std.mem.Allocator;
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
            " flags: {{ n: {}, v: {}, d: {} i: {}, z: {}, c: {} }}",
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

pub fn step(cpu: *CPU, data: []u8) !void {
    // std.debug.print("{f}\n", .{cpu});
    // std.debug.print("--\n", .{});

    const op = try Ops.Ops.init(data, cpu.pc.u16);
    std.debug.print("{f}\n", .{op});
    op.exec(cpu, data);
    // std.debug.print("{f}\n", .{cpu});
}

pub fn format(self: CPU, writer: *std.io.Writer) std.io.Writer.Error!void {
    try writer.print("   flags: {f}\n", .{self.flags});
    try writer.print("   pc: {f}   sp: {f}\n", .{ self.pc, self.sp });
    try writer.print("   af: {f}   bc: {f}   de: {f}   hl: {f} }} }}", .{ self.af, self.bc, self.de, self.hl });
}
