const std = @import("std");
const Allocator = std.mem.Allocator;

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

const OpType = enum(u8) {
    NOP = 0x0,

    LD_D16_HL = 0x21, // Load u16 into HL
    LD_D8_H = 0x26, // Load u8 into h
    LD_D16_SP = 0x31, // Load u16 into SP
    LD_D8_A = 0x3e, // Load d8 into a

    LD_L_A = 0x7d, // Load L into A

    LD_HL_A = 0x7e, // Load [HL] into A
    JP_16 = 0xc3, // Jump to u16
    CALL_16 = 0xcd,
    LD_A_MEM_8 = 0xe0, // Store A into short address
    LD_A_MEM_16 = 0xea, // Store A into op address
    DI = 0xf3, // Disable Interrupts
    _,
};

pc: Register = .{ .u16 = 0x100 }, // program counter
sp: Register = Zero, // stack pointer

af: Register = Zero,
bc: Register = Zero,
de: Register = Zero,
hl: Register = Zero,

pub fn range(_: *CPU, data: []u8, comptime T: type, start: u16) T {
    return std.mem.readInt(T, @ptrCast(data[start .. start + @sizeOf(T)]), .little);
}

pub fn step(self: *CPU, data: []u8, memory: []u8) void {
    std.debug.print("{f}\n", .{self});
    std.debug.print("--\n", .{});

    // switch (op) |o| {
    //     inline else => o =
    // }
    const op: OpType = @enumFromInt(data[self.pc.u16]);
    std.debug.print("op: {any}\n", .{op});
    switch (op) {
        .NOP => self.pc.u16 += 1,
        .LD_D16_HL => { // 0x21
            const val = self.range(data, u16, self.pc.u16 + 1);
            self.hl.u16 = val;
            self.pc.u16 += 3;
        },
        .LD_D8_H => { // 0x26
            const val = self.range(data, u8, self.pc.u16 + 1);
            self.hl.u8.a = val;
            self.pc.u16 += 2;
        },
        .LD_D16_SP => { // 0x31
            const val = self.range(data, u16, self.pc.u16 + 1);
            self.sp.u16 = val;
            self.pc.u16 += 3;
        },
        .LD_D8_A => { // 0x3e
            const val = self.range(data, u8, self.pc.u16 + 1);
            self.af.u8.a = val;
            self.pc.u16 += 2;
        },
        .LD_L_A => {
            self.hl.u8.b = self.af.u8.a;
            self.pc.u16 += 1;
        },
        .LD_HL_A => { // 0x7e
            const addr = self.range(data, u8, self.hl.u16 + 1);
            self.af.u8.a = memory[addr];
            self.pc.u16 += 1;
        },
        .JP_16 => { // 0xc3
            const addr = self.range(data, u16, self.pc.u16 + 1);
            self.pc.u16 = addr;
        },
        .LD_A_MEM_8 => { // 0xe0
            const addr = self.range(data, u8, self.pc.u16 + 1);
            memory[0xFF00 + @as(u16, @intCast(addr))] = self.af.u8.a;
            self.pc.u16 += 2;
        },
        .LD_A_MEM_16 => { // 0xea
            const addr = self.range(data, u8, self.pc.u16 + 1);
            memory[addr] = self.af.u8.a;
            self.pc.u16 += 3;
        },
        .CALL_16 => { // 0xcd
            // push current pc onto stack
            memory[self.sp.u16 - 1] = self.pc.u8.a;
            memory[self.sp.u16 - 2] = self.pc.u8.b;
            self.sp.u16 -= 2;

            // std.debug.print("memory: 0x{x}\n", .{memory[0xdff0..0xe000]});
            // std.debug.print("current [sp]: {x}\n", .{memory[self.sp.u16]});

            // jump to function
            const addr = self.range(data, u16, self.pc.u16 + 1);
            self.pc.u16 = addr;
        },
        .DI => { // 0xf3
            self.pc.u16 += 1;
        },
        else => std.debug.panic("Unsupported instruction: 0x{x}", .{op}),
    }
}

pub fn format(self: CPU, writer: *std.io.Writer) std.io.Writer.Error!void {
    try writer.print("cpu:\n", .{});
    try writer.print(" pointers:\n", .{});
    try writer.print("  pc: {f}   sp: {f}\n", .{ self.pc, self.sp });
    try writer.print(" registers:\n", .{});
    try writer.print("  af: {f}   bc: {f}\n", .{ self.af, self.bc });
    try writer.print("  de: {f}   hl: {f}", .{ self.de, self.hl });
}
