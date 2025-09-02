const std = @import("std");
const CPU = @import("cpu.zig");

pub const OpType = enum(u8) {
    NOP = 0x0,
    LD_BC_D16 = 0x01,

    LD_C_D8 = 0xe, // C = arg
    LD_DE_D16 = 0x11, // DE = arg
    LD_IDE_A = 0x12, // [DE] = arg
    JR_S8 = 0x18,
    INC_E = 0x1C,
    JR_NZ = 0x20,

    LD_HL_D16 = 0x21, // HL = arg
    LD_H_D8 = 0x26, // H = arg
    LD_A_IHL_INC = 0x2a, // A = [HL+]
    LD_SP_D16 = 0x31, // SP = arg
    LD_A_D8 = 0x3e, // A = arg

    LD_B_A = 0x47, // A = B

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

pub const Ops = union(OpType) {
    NOP: struct {
        const Op = OpDesc(void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_BC_D16: struct {
        const Op = OpDesc(u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.bc.u16 = self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_C_D8: struct {
        const Op = OpDesc(u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.bc.u8.b = self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_DE_D16: struct {
        const Op = OpDesc(u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.de.u16 += self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_IDE_A: struct {
        const Op = OpDesc(u16, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, data: []u8) void {
            data[cpu.de.u16] += cpu.af.u8.a;
            cpu.pc.u16 += Op.bytes;
        }
    },
    JR_S8: struct {
        const Op = OpDesc(i8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.pc.u16 = @intCast(@as(i32, @intCast(cpu.pc.u16)) + self.op.arg);
        }
    },
    INC_E: struct {
        const Op = OpDesc(void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
            cpu.de.u8.b += 1;
            cpu.pc.u16 += Op.bytes;
        }
    },
    JR_NZ: struct {
        const Op = OpDesc(i8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            switch (cpu.flags.f.z) {
                false => cpu.pc.u16 = @intCast(@as(i32, @intCast(cpu.pc.u16)) + self.op.arg),
                true => cpu.pc.u16 += 1,
            }
        }
    },
    LD_HL_D16: struct {
        const Op = OpDesc(u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.hl.u16 = self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_H_D8: struct {
        const Op = OpDesc(u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.hl.u8.a = self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_A_IHL_INC: struct {
        const Op = OpDesc(u16, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, data: []u8) void {
            cpu.af.u8.a = data[cpu.hl.u16];
            cpu.hl.u16 += 1;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_SP_D16: struct {
        const Op = OpDesc(u16, 3, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.sp.u16 = self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_A_D8: struct {
        const Op = OpDesc(u8, 2, 2);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.af.u8.a = self.op.arg;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_B_A: struct {
        const Op = OpDesc(void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
            cpu.bc.u8.a = cpu.af.u8.a;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_A_H: struct {
        const Op = OpDesc(void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
            cpu.af.u8.a = cpu.hl.u8.a;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_A_L: struct {
        const Op = OpDesc(void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
            cpu.af.u8.a = cpu.hl.u8.b;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_A_IHL: struct {
        const Op = OpDesc(void, 1, 2);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, data: []u8) void {
            cpu.af.u8.a = data[cpu.hl.u16];
            cpu.pc.u16 += Op.bytes;
        }
    },
    JP_16: struct {
        const Op = OpDesc(u16, 3, 4);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, _: []u8) void {
            cpu.pc.u16 = self.op.arg;
        }
    },
    CALL_16: struct {
        const Op = OpDesc(u16, 3, 6);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, data: []u8) void {
            // push current pc onto stack
            data[cpu.sp.u16 - 1] = cpu.pc.u8.a;
            cpu.sp.u16 -= 1;
            data[cpu.sp.u16 - 2] = cpu.pc.u8.b;
            cpu.sp.u16 -= 1;
            // std.debug.print("memory: 0x{x}\n", .{memory[0xdff0..0xe000]});
            // std.debug.print("current [sp]: {x}\n", .{memory[cpu.sp.u16]});

            // jump to function
            cpu.pc.u16 = self.op.arg;
        }
    },
    LD_I8_A: struct {
        const Op = OpDesc(u8, 2, 3);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, data: []u8) void {
            const addr: u16 = @intCast(@as(i32, @intCast(0xFF00)) + self.op.arg);
            // std.debug.print("{any} {x}\n", .{ self, addr });
            data[addr] = cpu.af.u8.a;
            cpu.pc.u16 += Op.bytes;
        }
    },
    LD_I16_A: struct {
        const Op = OpDesc(u16, 3, 4);
        op: Op,

        pub fn exec(self: @This(), cpu: *CPU, data: []u8) void {
            data[self.op.arg] = cpu.af.u8.a;
            cpu.pc.u16 += Op.bytes;
        }
    },
    DI: struct {
        const Op = OpDesc(void, 1, 1);
        op: Op,

        pub fn exec(_: @This(), cpu: *CPU, _: []u8) void {
            cpu.pc.u16 += Op.bytes;
        }
    },

    pub fn format(self: Ops, writer: *std.io.Writer) std.io.Writer.Error!void {
        try writer.print(".{s:<10} (0x{x:0>2})", .{ @tagName(self), @intFromEnum(self) });
        switch (self) {
            .JR_S8 => |e| try writer.print(" -> [0x{x:0>2}]", .{e.op.arg}),
            .LD_H_D8 => |e| try writer.print(" -> H = 0x{x:0>2}", .{e.op.arg}),
            .LD_HL_D16 => |e| try writer.print(" -> H = 0x{x:0>4}", .{e.op.arg}),
            .LD_A_D8 => |e| try writer.print(" -> A = 0x{x:0>2}", .{e.op.arg}),
            .LD_C_D8 => |e| try writer.print(" -> C = 0x{x:0>2}", .{e.op.arg}),
            .LD_DE_D16 => |e| try writer.print(" -> DE = 0x{x:0>4}", .{e.op.arg}),
            .LD_SP_D16 => |e| try writer.print(" -> SP = 0x{x:0>4}", .{e.op.arg}),
            .LD_I8_A => |e| try writer.print(" -> [0x{x:0>4}] = A", .{0xFF00 + @as(u16, @intCast(e.op.arg))}),
            .LD_I16_A => |e| try writer.print(" -> [0x{x:0>4}] = A", .{e.op.arg}),
            .JP_16 => |e| try writer.print(" -> [0x{x:0>4}]", .{e.op.arg}),
            .CALL_16 => |e| try writer.print(" -> [0x{x:0>4}]", .{e.op.arg}),
            else => {},
        }
    }

    fn create_op(comptime Opt: OpType, data: []u8) !Ops {
        inline for (std.meta.fields(Ops)) |field| {
            if (std.mem.eql(u8, @tagName(Opt), field.name)) {
                const Op: type = field.type;
                return @unionInit(Ops, field.name, Op{ .op = Op.Op.cast(data) });
            }
        }
        return error.OpNotFound;
    }

    pub fn init(data: []u8, start: u16) !Ops {
        const opt = std.meta.intToEnum(OpType, data[start]) catch {
            std.debug.panic("Unsupported instruction: 0x{x}", .{data[start]});
        };
        return switch (opt) {
            inline else => |t| try create_op(t, data[start..]),
        };
    }

    pub fn exec(self: Ops, cpu: *CPU, data: []u8) void {
        switch (self) {
            inline else => |o| o.exec(cpu, data),
        }
    }
};

pub fn OpDesc(comptime Arg: type, b: comptime_int, c: comptime_int) align(1) type {
    return packed struct {
        const bytes = b;
        const cycles = c;

        op: OpType,
        arg: Arg,

        fn cast(data: []u8) @This() {
            return @bitCast(data[0 .. @sizeOf(OpType) + @sizeOf(Arg)].*);
        }
    };
}
