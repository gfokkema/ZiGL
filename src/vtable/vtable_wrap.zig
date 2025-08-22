const std = @import("std");

const Animal = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        func: *const fn (*anyopaque) void,
    };
    // wrapping vtable calls
    inline fn func(self: Self) void {
        self.vtable.func(self.ptr);
    }

    fn init(pointer: anytype) Self {
        const Ptr = @TypeOf(pointer);
        if (@typeInfo(Ptr) != .pointer) @compileError("Must be a pointer");
        if (@typeInfo(Ptr).pointer.size != .one) @compileError("Must be a single-item pointer");
        if (@typeInfo(@typeInfo(Ptr).pointer.child) != .@"struct") @compileError("Must point to a struct");
        const impl = struct {
            pub fn funcImpl(ptr: *anyopaque) void {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                self.func();
            }
        };

        return .{
            .ptr = pointer,
            .vtable = &.{
                .func = impl.funcImpl,
            },
        };
    }
};

const Dog = struct {
    const Self = @This();

    fn init() Self {
        return .{};
    }

    fn animal(self: *Self) Animal {
        return Animal.init(self);
    }

    fn func(_: Self) void {
        std.debug.print("bark\n", .{});
    }
};

const Cat = struct {
    const Self = @This();

    fn init() Self {
        return .{};
    }

    fn animal(self: *Self) Animal {
        return Animal.init(self);
    }

    fn func(_: Self) void {
        std.debug.print("meow\n", .{});
    }
};

pub fn main() !void {
    @constCast(&Cat.init()).animal().func();
    @constCast(&Dog.init()).animal().func();
}
