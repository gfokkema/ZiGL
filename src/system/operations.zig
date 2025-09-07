const std = @import("std");
const CPU = @import("cpu.zig");
const Memory = @import("memory.zig");

pub fn OpDesc(comptime n: []const u8, comptime Arg: type, b: comptime_int, c: comptime_int) align(1) type {
    return packed struct {
        const name = n;
        const bytes = b;
        const cycles = c;

        op: OpType,
        arg: Arg,

        fn cast(data: []const u8) @This() {
            return @bitCast(data[0 .. @sizeOf(OpType) + @sizeOf(Arg)].*);
        }
    };
}

pub const OpType = enum(u8) {
    NOP = 0x0,
    LD_BC_D16 = 0x01,
    LD_M_BC_D16 = 0x02,
    INC_BC = 0x03,
    INC_B = 0x04,
    DEC_B = 0x05,
    LD_B_D8 = 0x06,

    DEC_C = 0x0d,
    LD_C_D8 = 0x0e, // C = arg
    LD_DE_D16 = 0x11, // DE = arg
    LD_M_DE_A = 0x12, // [DE] = arg
    JR_S8 = 0x18,
    INC_E = 0x1C,
    JR_NZ = 0x20,

    LD_HL_D16 = 0x21, // HL = arg
    LD_H_D8 = 0x26, // H = arg
    LD_A_M_HL_INC = 0x2a, // A = [HL+]
    LD_SP_D16 = 0x31, // SP = arg
    LD_M_HLD_A = 0x32, // [HL-] = A
    LD_A_D8 = 0x3e, // A = arg

    LD_B_A = 0x47, // A = B

    LD_A_H = 0x7c, // A = H
    LD_A_L = 0x7d, // A = L

    LD_A_M_HL = 0x7e, // A = [HL]
    SUB_H = 0x94,
    XOR_A = 0xaf,
    JP_16 = 0xc3,
    CALL_16 = 0xcd,

    LD_M_8_A = 0xe0, // [0xff00 + arg] = A
    LD_M_16_A = 0xea, // [arg] = A
    LD_A_M8 = 0xf0,
    DI = 0xf3, // Disable Interrupts
    CP_D8 = 0xfe,
    UNKNOWN_1 = 0xfc,
    // _,
};

pub const Ops = union(OpType) {
    NOP: struct {
        const Op = OpDesc("NOP", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), _: *CPU, _: *Memory) !void {}
    },
    LD_BC_D16: struct {
        const Op = OpDesc("LD", u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.bc.u16 = self.op.arg;
        }
    },
    LD_M_BC_D16: struct {
        const Op = OpDesc("LD", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, mem: *Memory) !void {
            try mem.set(cpu.bc.u16, cpu.af.u8.a);
        }
    },
    INC_BC: struct {
        const Op = OpDesc("INC bc", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.bc.u16 += 1;
        }
    },
    INC_B: struct {
        const Op = OpDesc("INC b", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            const res = @addWithOverflow(cpu.bc.u8.a, 1);
            cpu.bc.u8.a = res[0];
            cpu.flags.f.c = res[1] > 0;
            cpu.flags.f.z = res[1] == 0;
        }
    },
    DEC_B: struct {
        const Op = OpDesc("DEC    b", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            const res = @subWithOverflow(cpu.bc.u8.a, 1);
            cpu.bc.u8.a = res[0];
            cpu.flags.f.z = res[0] == 0;
            cpu.flags.f.c = res[1] > 0;
        }
    },
    LD_B_D8: struct {
        const Op = OpDesc("LD", u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.bc.u8.a = self.op.arg;
        }
    },
    DEC_C: struct {
        const Op = OpDesc("DEC    c", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            const res = @subWithOverflow(cpu.bc.u8.b, 1);
            std.debug.print("{any}\n", .{res});
            cpu.bc.u8.b = res[0];
            cpu.flags.f.z = res[0] == 0;
            cpu.flags.f.c = res[1] > 0;
        }
    },
    LD_C_D8: struct {
        const Op = OpDesc("LD", u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.bc.u8.b = self.op.arg;
        }
    },
    LD_DE_D16: struct {
        const Op = OpDesc("LD", u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.de.u16 += self.op.arg;
        }
    },
    LD_M_DE_A: struct {
        const Op = OpDesc("LD", u16, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, mem: *Memory) !void {
            try mem.set(cpu.de.u16, cpu.af.u8.a);
        }
    },
    JR_S8: struct {
        const Op = OpDesc("JP", i8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            // TODO: something is wrong here ... either:
            //   - pc needs to be incremented first
            //   - Arg is read incorrectly as -4 instead of -2
            cpu.pc.u16 = @intCast(@as(i32, @intCast(cpu.pc.u16)) + self.op.arg);
        }
    },
    INC_E: struct {
        const Op = OpDesc("INC e", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            const res = @addWithOverflow(cpu.de.u8.b, 1);
            cpu.de.u8.b = res[0];
            cpu.flags.f.z = res[0] == 0;
            cpu.flags.f.c = res[1] > 0;
        }
    },
    JR_NZ: struct {
        const Op = OpDesc("JR NZ", i8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            switch (cpu.flags.f.z) {
                false => {
                    const pc: i32 = @as(i32, @intCast(cpu.pc.u16)) + self.op.arg;
                    cpu.pc.u16 = @intCast(pc);
                },
                true => {},
            }
        }
    },
    LD_HL_D16: struct {
        const Op = OpDesc("LD", u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.hl.u16 = self.op.arg;
        }
    },
    LD_H_D8: struct {
        const Op = OpDesc("LD", u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.hl.u8.a = self.op.arg;
        }
    },
    LD_A_M_HL_INC: struct {
        const Op = OpDesc("LD", u16, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, mem: *Memory) !void {
            cpu.af.u8.a = try mem.get(cpu.hl.u16);
            cpu.hl.u16 += 1;
        }
    },
    LD_SP_D16: struct {
        const Op = OpDesc("LD", u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.sp.u16 = self.op.arg;
        }
    },
    LD_M_HLD_A: struct {
        const Op = OpDesc("LD", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, mem: *Memory) !void {
            try mem.set(cpu.hl.u16, cpu.af.u8.a);
            cpu.hl.u16 -= 1;
        }
    },
    LD_A_D8: struct {
        const Op = OpDesc("LD", u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.af.u8.a = self.op.arg;
        }
    },
    LD_B_A: struct {
        const Op = OpDesc("LD", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.bc.u8.a = cpu.af.u8.a;
        }
    },
    LD_A_H: struct {
        const Op = OpDesc("LD", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.af.u8.a = cpu.hl.u8.a;
        }
    },
    LD_A_L: struct {
        const Op = OpDesc("LD", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.af.u8.a = cpu.hl.u8.b;
        }
    },
    LD_A_M_HL: struct {
        const Op = OpDesc("LD", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, mem: *Memory) !void {
            cpu.af.u8.a = try mem.get(cpu.hl.u16);
        }
    },
    SUB_H: struct {
        const Op = OpDesc("SUB     a, h    c", void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            const res = @subWithOverflow(cpu.af.u8.a, cpu.hl.u8.a);
            cpu.af.u8.a = res[0];
            cpu.flags.f.z = res[0] == 0;
            cpu.flags.f.c = res[1] > 0;
        }
    },
    XOR_A: struct {
        const Op = OpDesc("XOR    a", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.af.u8.a = 0;
            cpu.flags.f.z = true;
        }
    },

    JP_16: struct {
        const Op = OpDesc("JP", u16, 3, 4);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.pc.u16 = self.op.arg;
        }
    },
    CALL_16: struct {
        const Op = OpDesc("CALL", u16, 3, 6);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, mem: *Memory) !void {
            // push current pc onto stack
            cpu.sp.u16 -= 1;
            try mem.set(cpu.sp.u16, cpu.pc.u8.a);
            cpu.sp.u16 -= 1;
            try mem.set(cpu.sp.u16, cpu.pc.u8.b);
            // std.debug.print("memory: 0x{x}\n", .{memory[0xdff0..0xe000]});
            // std.debug.print("current [sp]: {x}\n", .{memory[cpu.sp.u16]});

            // jump to function
            cpu.pc.u16 = self.op.arg;
        }
    },
    LD_M_8_A: struct {
        const Op = OpDesc("LD", u8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, mem: *Memory) !void {
            // std.debug.print("{any} {x}\n", .{ self, addr });
            try mem.ffset(self.op.arg, cpu.af.u8.a);
        }
    },
    LD_M_16_A: struct {
        const Op = OpDesc("LD", u16, 3, 4);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, mem: *Memory) !void {
            try mem.set(self.op.arg, cpu.af.u8.a);
        }
    },
    LD_A_M8: struct {
        const Op = OpDesc("LD", u8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, mem: *Memory) !void {
            cpu.af.u8.a = try mem.ffget(self.op.arg);
        }
    },
    DI: struct {
        const Op = OpDesc("DI", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: *Memory) !void {
            cpu.flags.f.i = true;
        }
    },
    CP_D8: struct {
        const Op = OpDesc("CP", u8, 1, 1);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: *Memory) !void {
            // std.debug.print("{f}\n", .{cpu});
            const res = @subWithOverflow(cpu.af.u8.a, self.op.arg);
            cpu.flags.f.z = res[0] == 0;
            cpu.flags.f.c = res[1] > 0;
            // std.debug.print("{f}\n", .{cpu});
        }
    },
    UNKNOWN_1: struct {
        const Op = OpDesc("UKN", void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), _: *CPU, _: *Memory) !void {}
    },

    pub fn format(self: Ops, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print("(0x{x:0>2}) ", .{@intFromEnum(self)});
        switch (self) {
            .JR_S8 => |e| try writer.print("{s:<6} ${x:0>2}", .{ @TypeOf(e.op).name, e.op.arg }),
            .JP_16 => |e| try writer.print("{s:<6} ${x:0>4}", .{ @TypeOf(e.op).name, e.op.arg }),
            .JR_NZ => |e| try writer.print("{s:<6} ${x:0>2}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_H_D8 => |e| try writer.print("{s:<6} h, ${x:0>2}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_HL_D16 => |e| try writer.print("{s:<6} hl, ${x:0>4}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_A_D8 => |e| try writer.print("{s:<6} a, ${x:0>2}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_B_D8 => |e| try writer.print("{s:<6} b, ${x:0>2}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_C_D8 => |e| try writer.print("{s:<6} c, ${x:0>2}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_DE_D16 => |e| try writer.print("{s:<6} de, ${x:0>4}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_SP_D16 => |e| try writer.print("{s:<6} sp, ${x:0>4}", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_A_M8 => |e| try writer.print("{s:<6} a, [${x:0>4}]", .{ @TypeOf(e.op).name, 0xFF00 + @as(u16, @intCast(e.op.arg)) }),
            .LD_M_8_A => |e| try writer.print("{s:<6} [${x:0>4}], a", .{ @TypeOf(e.op).name, 0xFF00 + @as(u16, @intCast(e.op.arg)) }),
            .LD_M_16_A => |e| try writer.print("{s:<6} [${x:0>4}], a", .{ @TypeOf(e.op).name, e.op.arg }),
            .LD_M_HLD_A => |e| try writer.print("{s:<6} [HLD], a", .{@TypeOf(e.op).name}),
            .CALL_16 => |e| try writer.print("{s:<6} ${x:0>4}", .{ @TypeOf(e.op).name, e.op.arg }),
            inline else => |e| try writer.print("{s:<6}", .{@TypeOf(e.op).name}),
        }
    }

    pub fn init(comptime Opt: OpType, data: []u8) !Ops {
        inline for (std.meta.fields(Ops)) |field| {
            if (std.mem.eql(u8, @tagName(Opt), field.name)) {
                const Op: type = field.type;
                return @unionInit(Ops, field.name, Op{ .op = Op.Op.cast(data) });
            }
        }
        return error.OpNotFound;
    }

    pub fn exec(self: Ops, cpu: *CPU, mem: *Memory) !void {
        switch (self) {
            inline else => |o| {
                cpu.pc.u16 += @TypeOf(o).Op.bytes;
                try o.exec(cpu, mem);
            },
        }
    }
};
