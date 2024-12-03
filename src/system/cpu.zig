const std = @import("std");
const Allocator = std.mem.Allocator;

const ROM = @import("rom.zig");

const CPU = @This();

pub const Memory = struct {
    pub const Bank = [0x10000]u8;

    banks: []Bank,

    pub fn init(alloc: Allocator) !Memory {
        return .{ .banks = try alloc.alloc(Bank, 0x100) };
    }

    pub fn deinit(self: *Memory, alloc: Allocator) void {
        alloc.free(self.banks);
    }
};

const Mode = enum(u1) {
    NORMAL = 0,
    EMULATION = 1,
};

const RegMode = enum(u1) {
    u16 = 0,
    u8 = 1,

    fn size(self: RegMode) u16 {
        return switch (self) {
            .u8 => 1,
            .u16 => 2,
        };
    }
};

const Flags = packed union {
    val: u8,
    flags: packed struct(u8) {
        c: bool = false,
        z: bool = false,
        i: bool = false,
        d: bool = false,
        x: RegMode = RegMode.u16,
        m: RegMode = RegMode.u16,
        v: bool = false,
        n: bool = false,
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

const Register = struct {
    val: u16 = 0,
};

memory: Memory,
mode: Mode = Mode.NORMAL,

dp: u16 = 0, // direct page pointer
sp: u16 = 0, // stack pointer

db: u8 = 0, // data bank
pb: u8 = 0x80, // program bank
pc: u16 = 0x8000, // program counter

p: Flags = .{ .val = 0 }, // p flags

a: Register = .{}, // accumulator
x: Register = .{}, // register
y: Register = .{}, // register

pub fn print(self: *const CPU) void {
    std.debug.print("\nCPU:\n", .{});
    std.debug.print(" registers:\n", .{});
    std.debug.print("   a: 0x{x:0>4}\n", .{self.a.val});
    std.debug.print("   x: 0x{x:0>4}    y: 0x{x:0>4}\n", .{ self.x.val, self.y.val });
    std.debug.print(" pointers:\n", .{});
    std.debug.print("  dp: 0x{x:0>4}\n", .{self.dp});
    std.debug.print("  db: 0x{x:0>4}   sp: 0x{x:0>4}\n", .{ self.db, self.sp });
    std.debug.print("  pb: 0x{x:0>4}   pc: 0x{x:0>4}\n", .{ self.pb, self.pc });
    std.debug.print(" mode: {}\n", .{self.mode});
    self.p.print();
    std.debug.print("\n", .{});
}

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
    _,
};

pub fn arg(self: *CPU, t: type) t {
    const a: t = self.memory.banks[self.pb][self.pc + 1];
    std.debug.print(" 0x{x}", .{a});
    return a;
}

pub fn push(self: *CPU, t: type, data: t) void {
    defer self.sp += 1;
    self.memory.banks[0][self.sp] = data;
}

pub fn pull(self: *CPU, t: type) t {
    defer self.sp -= 1;
    return self.memory.banks[0][self.sp];
}

fn _get(self: *CPU, t: type) t {
    const res = std.mem.readInt(
        t,
        @ptrCast(self.memory.banks[self.pb][self.pc + 1 ..]),
        .little,
    );
    std.debug.print(" 0x{x}", .{res});
    return res;
}

fn get(self: *CPU, r: RegMode) u16 {
    return switch (r) {
        .u8 => self._get(u8),
        .u16 => self._get(u16),
    };
}

pub fn step(self: *CPU) void {
    const b = self.memory.banks[self.pb][self.pc];
    const instr = std.meta.intToEnum(InstrType, b) catch {
        std.debug.panic("Unknown instr: 0x{x:0>2}", .{b});
    };
    std.debug.print("{any}", .{instr});

    switch (instr) {
        .SEI => {
            self.p.flags.i = true;
            self.pc += 1;
        },
        .CLD => {
            self.p.flags.d = false;
            self.pc += 1;
        },
        .CLC => {
            self.p.flags.c = false;
            self.pc += 1;
        },
        .XCE => {
            const t = self.mode;
            self.mode = @enumFromInt(@intFromBool(self.p.flags.c));
            self.p.flags.c = @bitCast(@intFromEnum(t));
            self.pc += 1;
        },
        .SEP => {
            self.p.val = self.p.val | self.arg(u8);
            self.pc += 2;
        },
        .REP => {
            self.p.val = self.p.val ^ self.arg(u8);
            self.pc += 2;
        },
        .LDA => {
            self.a.val = self.get(self.p.flags.m);
            self.pc += 1 + self.p.flags.m.size();
        },
        .LDX => {
            self.x.val = self.get(self.p.flags.x);
            self.pc += 1 + self.p.flags.x.size();
        },
        .STA => {
            // self.set(@truncate(self.a.val));
            self.memory.banks[self.pb][self.arg(u16)] = @truncate(self.a.val);
            self.pc += 3;
        },
        .STZ => {
            self.memory.banks[self.pb][self.arg(u16)] = 0;
            self.pc += 3;
        },
        .PHA => {
            self.push(u8, @truncate(self.a.val));
            self.pc += 1;
        },
        .PLB => {
            self.db = self.pull(u8);
            self.pc += 1;
        },
        else => {
            std.debug.print(" (unimplemented)", .{});
            self.pc += 1;
        },
    }
    std.debug.print("\n", .{});
}
