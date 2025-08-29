const std = @import("std");
const Allocator = std.mem.Allocator;
const Ops = @import("operations.zig");

const CPU = @This();

const Flags = packed union {
    val: u8,
    flags: packed struct(u8) {
        c: bool = false,
        z: bool = false,
        i: bool = false,
        d: bool = false,
        v: bool = false,
        n: bool = false,
    },

    pub fn format(self: Flags, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.write(" flags:\n", .{});
        try writer.write("  n: {} (negative)\n", .{self.flags.n});
        try writer.write("  v: {} (overflow)\n", .{self.flags.v});
        try writer.write("  d: {} (decimal)\n", .{self.flags.d});
        try writer.write("  m: {} (acc_mode)\n", .{self.flags.m});
        try writer.write("  i: {} (irq disable)\n", .{self.flags.i});
        try writer.write("  z: {} (zero)\n", .{self.flags.z});
        try writer.write("  c: {} (carry)\n", .{self.flags.c});
    }
};

const Register = packed union {
    u8: packed struct { a: u8, b: u8 },
    u16: u16,

    pub fn format(self: Register, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print("0x{x} [0x{x}, 0x{x}]", .{ self.u16, self.u8.a, self.u8.b });
    }
};
const Zero = Register{ .u16 = 0 };

pc: Register = .{ .u16 = 0x100 }, // program counter
sp: Register = Zero, // stack pointer

af: Register = Zero,
bc: Register = Zero,
de: Register = Zero,
hl: Register = Zero,

pub fn step(cpu: *CPU, data: []u8) void {
    // std.debug.print("{f}\n", .{cpu});
    // std.debug.print("--\n", .{});

    const op = Ops.Ops.init(data, cpu.pc.u16);
    std.debug.print("{f}\n", .{op});
    op.exec(cpu, data);
}

pub fn format(self: CPU, writer: *std.io.Writer) std.io.Writer.Error!void {
    try writer.print("cpu:\n", .{});
    try writer.print(" pointers:\n", .{});
    try writer.print("  pc: {f}   sp: {f}\n", .{ self.pc, self.sp });
    try writer.print(" registers:\n", .{});
    try writer.print("  af: {f}   bc: {f}\n", .{ self.af, self.bc });
    try writer.print("  de: {f}   hl: {f}", .{ self.de, self.hl });
}
