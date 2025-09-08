const std = @import("std");
const Allocator = std.mem.Allocator;
const Memory = @import("memory.zig");
const Ops = @import("operations.zig");

const CPU = @This();

const Flags = packed struct {
    _: u4 = 0,
    c: bool = false,
    h: bool = false,
    n: enum(u1) { dec = 1, inc = 0 },
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

        .af = Register.init_u8(0x01, @bitCast(Flags{
            .c = true,
            .h = true,
            .n = .inc,
            .z = true,
        })),
        .bc = Register.init_u8(0x00, 0x13),
        .de = Register.init_u8(0x00, 0xd8),
        .hl = Register.init_u8(0x01, 0x4d),
    };
}

pub fn next(self: *CPU, mem: anytype) !Ops.Ops {
    const opcode = try mem.get(self.pc.u16);
    const opt = std.meta.intToEnum(Ops.OpType, opcode) catch {
        std.debug.panic("Unsupported instruction: 0x{x}", .{opcode});
    };
    return switch (opt) {
        inline else => |t| try Ops.Ops.init(t, mem.slice(self.pc.u16)),
    };
}

pub fn format(self: CPU, writer: *std.io.Writer) std.io.Writer.Error!void {
    try writer.print("pc: {f}   sp: {f}\n", .{ self.pc, self.sp });
    try writer.print("af: {f}   bc: {f}\n", .{ self.af, self.bc });
    try writer.print("de: {f}   hl: {f}\n", .{ self.de, self.hl });
    try writer.print("flags: {f}\n", .{self.af.fu8.flags});
    try writer.print("ime: {s}", .{@tagName(self.ime)});
}

const TestData = struct {
    const State = struct {
        const RAM = struct { u16, u8 };
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
        ram: []const RAM,
    };

    const Cycle = struct { u16, u16, []const u8 };

    const TestCase = struct {
        name: []const u8,
        initial: State,
        final: State,
        cycles: []const Cycle,
    };
};

fn run_test(data: []const u8) !void {
    const alloc = std.testing.allocator;
    const json = try std.json.parseFromSlice([]const TestData.TestCase, alloc, data, .{});
    defer json.deinit();

    for (json.value) |case| {
        // std.debug.print("name: {s}\n\n", .{case.name});

        var cpu_a = CPU{
            .pc = Register.init_u16(case.initial.pc),
            .sp = Register.init_u16(case.initial.sp),
            .af = Register.init_u8(case.initial.a, case.initial.f),
            .bc = Register.init_u8(case.initial.b, case.initial.c),
            .de = Register.init_u8(case.initial.d, case.initial.e),
            .hl = Register.init_u8(case.initial.h, case.initial.l),
            .ime = @enumFromInt(case.initial.ime),
        };
        // std.debug.print("start: {f}\n\n", .{cpu_a});

        var mem = Memory.Linear{};
        for (case.initial.ram) |v| mem.data[v[0]] = v[1];

        const op = try cpu_a.next(&mem);
        // std.debug.print("op: {f}\n", .{op});

        try op.exec(&cpu_a, &mem);

        const cpu_b = CPU{
            .pc = Register.init_u16(case.final.pc),
            .sp = Register.init_u16(case.final.sp),
            .af = Register.init_u8(case.final.a, case.final.f),
            .bc = Register.init_u8(case.final.b, case.final.c),
            .de = Register.init_u8(case.final.d, case.final.e),
            .hl = Register.init_u8(case.final.h, case.final.l),
            .ime = @enumFromInt(case.initial.ime),
        };
        // std.debug.print("\ncpu: {f}\n\n", .{cpu_a});
        // std.debug.print("expect: {f}\n\n", .{cpu_b});

        try std.testing.expectEqual(cpu_a, cpu_b);

        for (0.., mem.data) |a_idx, a_val| {
            var found = false;
            for (case.final.ram[0..]) |b| {
                if (a_idx == b[0]) {
                    std.testing.expect(a_val == b[1]) catch {
                        std.debug.print("a_ram: {any}\n", .{case.initial.ram});
                        std.debug.print("b_ram: {any}\n", .{case.final.ram});
                        std.debug.print("a: {d}\n", .{a_idx});
                        std.debug.print("b: {d}\n", .{b[0]});
                        std.debug.print("a_val: {any}: ", .{a_val});
                        std.debug.print("b_val: {any}: ", .{b[1]});
                    };
                    found = true;
                    break;
                }
            }
            if (!found) try std.testing.expectEqual(a_val, 0);
        }
    }
}

test "test_NOP" {
    const data = @embedFile("./sm83/v1/00.json");
    try run_test(data);
}

test "test_LD_BC_D16" {
    const data = @embedFile("./sm83/v1/01.json");
    try run_test(data);
}

test "test_LD_BC_A" {
    const data = @embedFile("./sm83/v1/02.json");
    try run_test(data);
}

test "test_INC_BC" {
    const data = @embedFile("./sm83/v1/03.json");
    try run_test(data);
}

test "test_INC_B" {
    const data = @embedFile("./sm83/v1/04.json");
    try run_test(data);
}

test "test_DEC_B" {
    const data = @embedFile("./sm83/v1/05.json");
    try run_test(data);
}
