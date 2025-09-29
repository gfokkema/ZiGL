const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Fifo(comptime T: type, comptime S: comptime_int) type {
    return struct {
        const Self = @This();

        buffer: [S]T,
        stack: std.ArrayListUnmanaged(T),

        pub fn init(alloc: Allocator) !*Self {
            const self = try alloc.create(Self);
            self.* = .{
                .buffer = undefined,
                .stack = std.ArrayListUnmanaged(T).initBuffer(&self.buffer),
            };
            return self;
        }

        pub fn deinit(self: *Self, alloc: Allocator) void {
            alloc.destroy(self);
        }

        pub fn pop(self: *Self) ?T {
            return self.stack.pop();
        }
    };
}
