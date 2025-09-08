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

pub fn step(self: *CPU, mem: *Memory, op: Ops.Ops) !void {
    try op.exec(self, mem);
    // std.debug.print("{f}\n", .{cpu});
}

pub fn equals(self: CPU, other: CPU) bool {
    return self.pc.u16 == other.pc.u16 and
        self.sp.u16 == other.sp.u16 and
        self.af.u16 == other.af.u16 and
        self.bc.u16 == other.bc.u16 and
        self.de.u16 == other.de.u16 and
        self.hl.u16 == other.hl.u16 and
        self.ime == other.ime;
}

pub fn format(self: CPU, writer: *std.io.Writer) std.io.Writer.Error!void {
    try writer.print("pc: {f}   sp: {f}\n", .{ self.pc, self.sp });
    try writer.print("af: {f}   bc: {f}\n", .{ self.af, self.bc });
    try writer.print("de: {f}   hl: {f}\n", .{ self.de, self.hl });
    try writer.print("flags: {f}\n", .{self.af.fu8.flags});
    try writer.print("ime: {s}", .{@tagName(self.ime)});
}

test "test_1" {
    const State = struct {
        pc: u16,
        sp: u16,
        a: u8,
        b: u8,
        c: u8,
        d: u8,
        e: u8,
        f: u8,
        h: u8,
        l: u8,
        ime: u8,
        ie: u8 = 0,
        ram: []const []u16,
    };
    const Cycle = struct { u16, u16, []const u8 };
    const TestCase = struct {
        name: []const u8,
        initial: State,
        final: State,
        cycles: []const Cycle,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const data = @embedFile("./sm83/v1/00.json");
    const json = try std.json.parseFromSlice([]const TestCase, alloc, data, .{});
    defer json.deinit();

    for (json.value) |case| {
        std.debug.print("name: {s}\n", .{case.name});
        const i = case.initial;
        var initial = CPU{
            .pc = Register.init_u16(i.pc),
            .sp = Register.init_u16(i.sp),
            .af = Register.init_u8(i.a, i.f),
            .bc = Register.init_u8(i.b, i.c),
            .de = Register.init_u8(i.d, i.e),
            .hl = Register.init_u8(i.h, i.l),
            .ime = @enumFromInt(i.ime),
        };

        // var mem = Memory{ .io = undefined, .rom = undefined };

        const f = case.final;
        const final = CPU{
            .pc = Register.init_u16(f.pc),
            .sp = Register.init_u16(f.sp),
            .af = Register.init_u8(f.a, f.f),
            .bc = Register.init_u8(f.b, f.c),
            .de = Register.init_u8(f.d, f.e),
            .hl = Register.init_u8(f.h, f.l),
        };
        try std.testing.expect(initial.equals(final));
    }
}
