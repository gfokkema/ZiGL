const std = @import("std");
const CPU = @import("cpu.zig");

pub const OpType = enum(u8) {
    NOP = 0x0,

    JR_S8 = 0x18,

    LD_HL_D16 = 0x21, // HL = arg
    LD_H_D8 = 0x26, // H = arg
    LD_SP_D16 = 0x31, // SP = arg
    LD_A_D8 = 0x3e, // A = arg

    LD_A_H = 0x7c, // A = H
    LD_A_L = 0x7d, // A = L

    LD_A_IHL = 0x7e, // A = [HL]
    JP_16 = 0xc3,
    CALL_16 = 0xcd,

    LD_I8_A = 0xe0, // [0xff00 + arg] = A
    LD_I16_A = 0xea, // [arg] = A
    DI = 0xf3, // Disable Interrupts
    // _,
};

const NOP = packed struct {
    const bytes = 1;
    const cycles = 1;

    op: OpType = .NOP,

    pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
        cpu.pc.u16 += bytes;
    }
};

const JR_S8 = packed struct {
    const bytes = 2;
    const cycles = 3;

    op: OpType = .JR_S8,
    arg: i8,

    pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
        cpu.pc.u16 = @intCast(@as(i32, @intCast(cpu.pc.u16)) + self.arg);
    }
};

const LD_HL_D16 = packed struct {
    const bytes = 3;
    const cycles = 3;

    op: OpType = .LD_HL_D16,
    arg: u16,

    pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
        cpu.hl.u16 = self.arg;
        cpu.pc.u16 += bytes;
    }
};

const LD_H_D8 = packed struct {
    const bytes = 2;
    const cycles = 2;

    op: OpType = .LD_H_D8,
    arg: u8,

    pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
        cpu.hl.u8.a = self.arg;
        cpu.pc.u16 += bytes;
    }
};
const LD_SP_D16 = packed struct {
    const bytes = 3;
    const cycles = 3;

    op: OpType = .LD_SP_D16,
    arg: u16,

    pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
        cpu.sp.u16 = self.arg;
        cpu.pc.u16 += bytes;
    }
};

const LD_A_D8 = packed struct {
    const bytes = 2;
    const cycles = 2;

    op: OpType = OpType.LD_A_D8,
    arg: u8,

    pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
        cpu.af.u8.a = self.arg;
        cpu.pc.u16 += bytes;
    }
};

const LD_A_H = packed struct {
    const bytes = 1;
    const cycles = 1;

    op: OpType = OpType.LD_A_H,

    pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
        cpu.af.u8.a = cpu.hl.u8.a;
        cpu.pc.u16 += bytes;
    }
};

const LD_A_L = packed struct {
    const bytes = 1;
    const cycles = 1;

    op: OpType = OpType.LD_A_L,

    pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
        cpu.af.u8.a = cpu.hl.u8.b;
        cpu.pc.u16 += bytes;
    }
};

const LD_A_IHL = packed struct {
    const bytes = 1;
    const cycles = 2;

    op: OpType = OpType.LD_A_IHL,

    pub fn exec(_: @This(), cpu: *CPU, data: []u8) void {
        cpu.af.u8.a = data[cpu.hl.u16];
        cpu.pc.u16 += bytes;
    }
};

const JP_16 = packed struct {
    const bytes = 3;
    const cycles = 4;

    op: OpType = OpType.JP_16,
    arg: u16,

    pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
        cpu.pc.u16 = self.arg;
    }
};

const CALL_16 = packed struct {
    const bytes = 3;
    const cycles = 6;

    op: OpType = .CALL_16,
    arg: u16,

    pub fn exec(self: @This(), cpu: *CPU, data: []u8) void {
        // push current pc onto stack
        data[cpu.sp.u16 - 1] = cpu.pc.u8.a;
        cpu.sp.u16 -= 1;
        data[cpu.sp.u16 - 2] = cpu.pc.u8.b;
        cpu.sp.u16 -= 1;
        // std.debug.print("memory: 0x{x}\n", .{memory[0xdff0..0xe000]});
        // std.debug.print("current [sp]: {x}\n", .{memory[cpu.sp.u16]});

        // jump to function
        cpu.pc.u16 = self.arg;
    }
};

pub const LD_I8_A = packed struct {
    const bytes = 2;
    const cycles = 3;

    op: OpType = .LD_I8_A,
    arg: u8 = undefined,

    pub fn exec(self: @This(), cpu: *CPU, data: []u8) void {
        data[@intCast(@as(i32, @intCast(0xFF00)) + self.arg)] = cpu.af.u8.a;
        cpu.pc.u16 += bytes;
    }
};

pub const LD_I16_A = packed struct {
    const bytes = 3;
    const cycles = 4;

    op: OpType = .LD_I16_A,
    arg: u16 = undefined,

    pub fn exec(self: @This(), cpu: *CPU, data: []u8) void {
        data[self.arg] = cpu.af.u8.a;
        cpu.pc.u16 += bytes;
    }
};

pub const DI = packed struct {
    const bytes = 1;
    const cycles = 1;

    op: OpType = .DI,

    pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
        cpu.pc.u16 += bytes;
    }
};

pub const Ops = union(OpType) {
    NOP: NOP,
    JR_S8: JR_S8,
    LD_HL_D16: LD_HL_D16,
    LD_H_D8: LD_H_D8,
    LD_SP_D16: LD_SP_D16,
    LD_A_D8: LD_A_D8,
    LD_A_H: LD_A_H,
    LD_A_L: LD_A_L,
    LD_A_IHL: LD_A_IHL,
    JP_16: JP_16,
    CALL_16: CALL_16,
    LD_I8_A: LD_I8_A,
    LD_I16_A: LD_I16_A,
    DI: DI,

    pub fn init(data: []u8, start: u16) Ops {
        const opt = std.meta.intToEnum(OpType, data[start]) catch {
            std.debug.panic("Unsupported instruction: 0x{x}", .{data[start]});
        };
        const inner = struct {
            fn cast(comptime T: type, d: []u8) T {
                return @bitCast(d[0..T.bytes].*);
            }
        };
        return switch (opt) {
            .NOP => .{ .NOP = inner.cast(NOP, data[start..]) },
            .JR_S8 => .{ .JR_S8 = inner.cast(JR_S8, data[start..]) },
            .LD_HL_D16 => .{ .LD_HL_D16 = inner.cast(LD_HL_D16, data[start..]) },
            .LD_H_D8 => .{ .LD_H_D8 = inner.cast(LD_H_D8, data[start..]) },
            .LD_SP_D16 => .{ .LD_SP_D16 = inner.cast(LD_SP_D16, data[start..]) },
            .LD_A_D8 => .{ .LD_A_D8 = inner.cast(LD_A_D8, data[start..]) },
            .LD_A_H => .{ .LD_A_H = inner.cast(LD_A_H, data[start..]) },
            .LD_A_L => .{ .LD_A_L = inner.cast(LD_A_L, data[start..]) },
            .LD_A_IHL => .{ .LD_A_IHL = inner.cast(LD_A_IHL, data[start..]) },
            .JP_16 => .{ .JP_16 = inner.cast(JP_16, data[start..]) },
            .CALL_16 => .{ .CALL_16 = inner.cast(CALL_16, data[start..]) },
            .LD_I8_A => .{ .LD_I8_A = inner.cast(LD_I8_A, data[start..]) },
            .LD_I16_A => .{ .LD_I16_A = inner.cast(LD_I16_A, data[start..]) },
            .DI => .{ .DI = inner.cast(DI, data[start..]) },
        };
    }

    pub fn exec(self: Ops, cpu: *CPU, data: []u8) void {
        switch (self) {
            inline else => |o| o.exec(cpu, data),
        }
    }

    pub fn format(self: Ops, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print(".{s:<10} (0x{x:0>2})", .{ @tagName(self), @intFromEnum(self) });
        switch (self) {
            .JR_S8 => |e| try writer.print(" -> [0x{x:0>2}]", .{e.arg}),
            .LD_HL_D16 => |e| try writer.print(" -> H = 0x{x:0>4}", .{e.arg}),
            .LD_H_D8 => |e| try writer.print(" -> H = 0x{x:0>2}", .{e.arg}),
            .LD_A_D8 => |e| try writer.print(" -> A = 0x{x:0>2}", .{e.arg}),
            .LD_SP_D16 => |e| try writer.print(" -> SP = 0x{x:0>4}", .{e.arg}),
            .LD_I8_A => |e| try writer.print(" -> [0x{x:0>4}] = A", .{0xFF00 + @as(u16, @intCast(e.arg))}),
            .LD_I16_A => |e| try writer.print(" -> [0x{x:0>4}] = A", .{e.arg}),
            .JP_16 => |e| try writer.print(" -> [0x{x:0>4}]", .{e.arg}),
            .CALL_16 => |e| try writer.print(" -> [0x{x:0>4}]", .{e.arg}),
            else => {},
        }
    }
};

pub fn range(comptime T: type, data: []u8, start: u16) T {
    return std.mem.readInt(T, @ptrCast(data[start .. start + @sizeOf(T)]), .little);
}
