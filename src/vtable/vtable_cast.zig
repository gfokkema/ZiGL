const std = @import("std");

const Animal = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        func: *const fn (*anyopaque) void,
    };

    inline fn func(self: Self) void {
        self.vtable.func(self.ptr);
    }
};

const Dog = struct {
    const Self = @This();

    const vtable: Animal.VTable = .{
        .func = func,
    };

    fn init() Self {
        return .{};
    }

    fn animal(self: *Self) Animal {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }

    fn func(_: *anyopaque) void {
        // const self: *Self = @ptrCast(@alignCast(context));
        std.debug.print("bark\n", .{});
    }
};

const Cat = struct {
    const Self = @This();

    fn init() Self {
        return .{};
    }

    fn animal(self: *Self) Animal {
        return .{
            .ptr = self,
            .vtable = &.{
                .func = func,
            },
        };
    }

    fn func(_: *anyopaque) void {
        // const self: *Self = @ptrCast(@alignCast(context));
        std.debug.print("meow\n", .{});
    }
};

pub fn main() !void {
    @constCast(&Cat.init()).animal().func();
    @constCast(&Dog.init()).animal().func();
}
