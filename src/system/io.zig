const std = @import("std");

const IO = @This();

const IntFlags = extern struct {
    vlank: bool,
    lcd: bool,
    timer: bool,
    serial: bool,
    joypad: bool,
    _1: bool,
    _2: bool,
    _3: bool,
};

const IOMapper = extern union {
    val: [0x80]u8,
    m: extern struct {
        // 0xFF00
        joypad: u8,
        // 0xFF01
        serial: [2]u8,
        _1: u8,
        // 0xFF04 - 0xFF07
        timer: [4]u8,
        _2: [7]u8,
        // 0xFF0F
        int_flags: IntFlags, // u8

        // 0xFF10
        audio: [0x26]u8,
        // 0xFF26
        _3: [0xA]u8,
        // 0xFF30
        wave: [0x10]u8,
        // 0xFF40
        lcd: extern struct { _: [0xB]u8 }, // 0x40
        _4: [0x3]u8,
        // 0xFF4F
        vram_bank: u8, // 0x4F
        // 0xFF50
        boot_map: u8, // 0x50
        // 0xFF51
        vram_dma: [4]u8, // 0x51
        _5: [0x12]u8, // 0x55
        // 0xFF68
        bg_obj: [0x04]u8, // 0x6B
        _6: [4]u8,
        // 0x70
        wram_bank: u8, // 0x70
    },
};

const IOTarget = enum(u8) {
    JOYPAD,
    SERIAL,
    TIMER,
    INTERRUPT,
    AUDIO,
    WAVE,
    LCD,
    VRAM_BANK,
    BOOT,
    VRMA_DMA,
    BG_OBJ,
    WRAM_BANK,
    _,
};

mapper: *IOMapper,

pub fn init(data: []u8, start: u16) IO {
    return .{ .mapper = @ptrCast(data[start..]) };
}

pub fn get(self: *IO, addr: u16) !u8 {
    return self.mapper.val[addr];
}

pub fn set(self: *IO, addr: u16, value: anytype) !void {
    self.mapper.val[addr] = value;
}
