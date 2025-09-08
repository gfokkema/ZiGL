const std = @import("std");
const Allocator = std.mem.Allocator;
const Memory = @import("memory.zig");
const Ops = @import("operations.zig");

const CPU = @This();

const Flags = packed struct {
    _: u4 = 0,
    c: bool = false,
    h: bool = false,
    n: bool = false,
    z: bool = false,

    pub fn format(self: Flags, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print(
            "{{ c: {}, h: {}, n: {} z: {} }}",
            .{ self.c, self.h, self.n, self.z },
        );
    }
};

const InterruptEnable = enum(u1) {
    false = 0,
    true = 1,
};

const Register = packed union {
    const Zero = Register{ .u16 = 0 };

    u8: packed struct { b: u8, a: u8 },
    fu8: packed struct { flags: Flags, a: u8 },
    u16: u16,

    pub fn init_u8(a: u8, b: u8) Register {
        return .{ .u8 = .{ .a = a, .b = b } };
    }

    pub fn init_u16(v: u16) Register {
        return .{ .u16 = v };
    }

    pub fn format(self: Register, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print("0x{x:0>4} [0x{x:0>2}, 0x{x:0>2}]", .{ self.u16, self.u8.a, self.u8.b });
    }
};

pc: Register = Register.Zero,
sp: Register = Register.Zero, // stack pointer

af: Register = Register.Zero,
bc: Register = Register.Zero,
de: Register = Register.Zero,
hl: Register = Register.Zero,

ime: InterruptEnable = .false,

pub fn init_dmg() CPU {
    return .{
        .pc = Register.init_u16(0x100),
        .sp = Register.init_u16(0xfffe),

        .af = Register.init_u8(0x01, @bitCast(Flags{ .c = true, .h = true, .n = false, .z = true })),
        .bc = Register.init_u8(0x00, 0x13),
        .de = Register.init_u8(0x00, 0xd8),
        .hl = Register.init_u8(0x01, 0x4d),
    };
}

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
    try writer.print("flags: {f}\n", .{self.af.fu8.flags});
    try writer.print("ime: {s}", .{@tagName(self.ime)});
}
