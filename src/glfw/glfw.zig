const c = @import("c").c;
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Event = @import("event.zig").Event;
pub const ImGui = @import("imgui.zig");
pub const Window = @import("window.zig");

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
pub const Queue = Fifo(Event, 128);

const GLFW = @This();

queue: *Queue,

pub fn init(alloc: Allocator) !GLFW {
    _ = c.glfwSetErrorCallback(error_callback);
    if (c.glfwInit() != c.GLFW_TRUE) return error.InitError;

    return .{
        .queue = try Queue.init(alloc),
    };
}

pub fn deinit(self: *GLFW, alloc: Allocator) void {
    c.glfwTerminate();
    self.queue.deinit(alloc);
}

pub fn window(self: *GLFW, alloc: Allocator) !*Window {
    return try Window.init(alloc, self.queue, .{});
}

pub fn error_callback(err: c_int, c_desc: [*c]const u8) callconv(.c) void {
    const desc = std.mem.span(c_desc);
    std.debug.panic("ERROR {d}: {s}\n", .{ err, desc });
}
