const std = @import("std");
const ROM = @import("rom.zig");

const CPU = @This();

pub const InstrType = enum(u8) {
    CLC = 0x18,
    TCS = 0x1B,
    ORA = 0x1F,
    PHA = 0x48,
    TCD = 0x5B,
    SEI = 0x78,
    STA = 0x8D,
    BCC = 0x90,
    STAY = 0x99,
    STZ = 0x9C,
    STAX = 0x9D,
    LDX = 0xA2,
    LDA = 0xA9,
    PLB = 0xAB,
    LDAL = 0xBF,
    REP = 0xC2,
    CLD = 0xD8,
    CPX = 0xE0,
    SEP = 0xE2,
    INX = 0xE8,
    XCE = 0xFB,
};

const Instr = struct {
    cycles: u8,
    data: []u8,

    pub fn bytes(self: *const Instr) usize {
        return 1 + self.data.len;
    }
};

const Flags = packed union {
    val: u8,
    flags: packed struct(u8) {
        c: bool,
        z: bool,
        i: bool,
        d: bool,
        x: bool,
        m: bool,
        v: bool,
        n: bool,
    },

    pub fn print(self: *const Flags) void {
        std.debug.print(" flags:\n", .{});
        std.debug.print("  n: {} (negative)\n", .{self.flags.n});
        std.debug.print("  v: {} (overflow)\n", .{self.flags.v});
        std.debug.print("  m: {} (acc_mode)\n", .{self.flags.m});
        std.debug.print("  x: {} (reg_mode)\n", .{self.flags.x});
        std.debug.print("  d: {} (decimal)\n", .{self.flags.d});
        std.debug.print("  d: {} (irq disable)\n", .{self.flags.i});
        std.debug.print("  d: {} (zero)\n", .{self.flags.z});
        std.debug.print("  c: {} (carry)\n", .{self.flags.c});
    }
};

a: u16 = 0, // accumulator
x: u16 = 0, // register
y: u16 = 0, // register

dp: u16 = 0, // direct page pointer
sp: u16 = 0, // stack pointer

db: u8 = 0, // data bank
pb: u8 = 0, // program bank
pc: u16 = 0, // program counter

p: Flags = .{ .val = 0 }, // p flags

pub fn print(self: *const CPU) void {
    std.debug.print("CPU:\n", .{});
    std.debug.print(" registers:\n", .{});
    std.debug.print("   a: 0x{x:0>4}\n", .{self.a});
    std.debug.print("   x: 0x{x:0>4}    y: 0x{x:0>4}\n", .{ self.x, self.y });
    std.debug.print(" pointers:\n", .{});
    std.debug.print("  dp: 0x{x:0>4}\n", .{self.dp});
    std.debug.print("  db: 0x{x:0>4}   sp: 0x{x:0>4}\n", .{ self.db, self.sp });
    std.debug.print("  pb: 0x{x:0>4}   pc: 0x{x:0>4}\n", .{ self.pb, self.pc });
    self.p.print();
}

pub fn LDX(self: *CPU) Instr {
    const args = if (self.p.flags.idx_mode)
        self.rom.args(self.pc, 2)
    else
        self.rom.args(self.pc, 3);
    return .{ .cycles = 2, .data = args };
}

pub fn LDA(self: *CPU) Instr {
    const args = if (self.p.flags.acc_mode)
        self.rom.args(self.pc, 2)
    else
        self.rom.args(self.pc, 3);
    return .{ .cycles = 2, .data = args };
}

pub fn REP(self: *CPU) Instr {
    const args = self.rom.args(self.pc, 2);
    self.p.val = self.p.val ^ args[0];
    return .{ .cycles = 3, .data = args };
}

pub fn CPX(self: *CPU) Instr {
    const args = if (self.p.flags.idx_mode)
        self.rom.args(self.pc, 2)
    else
        self.rom.args(self.pc, 3);
    return .{ .cycles = 2, .data = args };
}

pub fn SEP(self: *CPU) Instr {
    const args = self.rom.args(self.pc, 2);
    self.p.val = self.p.val | args[0];
    return .{ .cycles = 3, .data = args };
}

pub fn step(self: *CPU) void {
    while (self.pc < 0x40) {
        const instr = std.meta.intToEnum(InstrType, self.rom.data[self.pc]) catch {
            std.debug.panic("Unknown instr: 0x{x:0>2}", .{self.rom.data[self.pc]});
        };

        const ins: Instr = switch (instr) {
            .CLC => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
            .TCS => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
            .ORA => .{ .cycles = 2, .data = self.rom.args(self.pc, 3) },
            .PHA => .{ .cycles = 3, .data = self.rom.args(self.pc, 1) },
            .TCD => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
            .SEI => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
            .STA => .{ .cycles = 4, .data = self.rom.args(self.pc, 3) },
            .BCC => .{ .cycles = 2, .data = self.rom.args(self.pc, 2) },
            .STAY => .{ .cycles = 5, .data = self.rom.args(self.pc, 3) },
            .STZ => .{ .cycles = 4, .data = self.rom.args(self.pc, 3) },
            .STAX => .{ .cycles = 5, .data = self.rom.args(self.pc, 3) },
            .LDX => self.LDX(),
            .LDA => self.LDA(),
            .PLB => .{ .cycles = 4, .data = self.rom.args(self.pc, 1) },
            .LDAL => .{ .cycles = 5, .data = self.rom.args(self.pc, 4) },
            .REP => self.REP(),
            .CLD => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
            .CPX => self.CPX(),
            .SEP => self.SEP(),
            .INX => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
            .XCE => .{ .cycles = 2, .data = self.rom.args(self.pc, 1) },
        };

        std.debug.print("{d}: {s} [{x:0>2}]: {x}\n", .{ self.pc, @tagName(instr), self.rom.data[self.pc], ins.data });
        self.pc += ins.bytes();
    }
}
