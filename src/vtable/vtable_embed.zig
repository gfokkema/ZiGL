const std = @import("std");

const Animal = struct {
    funcFn: *const fn (*Animal) void,

    inline fn func(self: *Animal) void {
        self.funcFn(self);
    }
};

const Dog = struct {
    const Self = @This();

    animal: Animal,

    fn init() Self {
        const impl = struct {
            fn func(ptr: *Animal) void {
                const self: *Self = @ptrCast(@alignCast(ptr));
                self.func();
            }
        };
        return .{
            .animal = .{
                .funcFn = impl.func,
            },
        };
    }

    fn func(_: *Self) void {
        // const self: *Self = @ptrCast(@alignCast(context));
        std.debug.print("bark\n", .{});
    }
};

const Cat = struct {
    const Self = @This();

    animal: Animal,

    fn init() Self {
        return .{
            .animal = .{
                .funcFn = func,
            },
        };
    }

    fn func(_: *Animal) void {
        // const self: *Self = @ptrCast(@alignCast(context));
        std.debug.print("meow\n", .{});
    }
};

pub fn main() !void {
    var c = Cat.init();
    var d = Dog.init();
    c.animal.func();
    d.animal.func();
    Cat.func(&c.animal);
    d.func();
}
