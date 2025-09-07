const std = @import("std");

const IO = @This();

const IOType = enum(u16) {
    INTERRUPT = 0xFF0F,
    _,
};

data: [0x100]u8 = [_]u8{0} ** 0x100,

pub fn get(self: IO, addr: u16) u8 {
    const iot: IOType = @enumFromInt(addr);
    switch (iot) {
        .INTERRUPT => |e| std.debug.print("IO::Get: Handle {any}\n", .{e}),
        else => |e| std.debug.panic("IO: Unknown addr: 0x{x:0>4}", .{e}),
    }
    return self.data[addr - 0xFF00];
}

pub fn set(self: *IO, addr: u16, value: u8) void {
    const iot: IOType = @enumFromInt(addr);
    switch (iot) {
        .INTERRUPT => |e| std.debug.print("IO::Set: Handle {any}\n", .{e}),
        else => |e| std.debug.panic("IO: Unknown addr: 0x{x:0>4}", .{e}),
    }
    self.data[addr - 0xFF00] = value;
}
