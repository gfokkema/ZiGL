const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_render.h");
});

const SDLError = error{
    FailedInit,
    FailedCreatingWindow,
    FailedCreatingRenderer,
    FailedGettingEvent,
    FailedDraw,
    FailedScreenUpdate,
};

const SDL = @This();
const Event = struct {
    ptr: c.SDL_Event,
};

window: *c.SDL_Window,
renderer: *c.SDL_Renderer,

fn event_filter(_: ?*anyopaque, event: [*c]c.SDL_Event) callconv(.C) bool {
    return switch (event.*.type) {
        c.SDL_EVENT_KEY_DOWN => true,
        c.SDL_EVENT_QUIT => true,
        else => false,
    };
}

pub fn init() SDLError!SDL {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS)) {
        std.debug.print("Initialising SDL failed: {s}\n", .{c.SDL_GetError()});
        return SDLError.FailedInit;
    }
    errdefer c.SDL_Quit();

    const window = c.SDL_CreateWindow("SDL test", 640, 480, c.SDL_WINDOW_RESIZABLE) orelse {
        std.debug.print("Creating Window failed: {s}\n", .{c.SDL_GetError()});
        return SDLError.FailedCreatingWindow;
    };
    errdefer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, null) orelse {
        std.debug.print("Creating Renderer failed: {s}\n", .{c.SDL_GetError()});
        return SDLError.FailedCreatingRenderer;
    };
    errdefer c.SDL_DestroyRenderer(renderer);

    c.SDL_SetEventFilter(event_filter, null);
    _ = c.SDL_SetRenderDrawColor(renderer, 255, 0.0, 0, c.SDL_ALPHA_OPAQUE);
    _ = c.SDL_ShowWindow(window);
    return SDL{ .window = window, .renderer = renderer };
}

pub fn deinit(self: *SDL) void {
    c.SDL_DestroyRenderer(self.renderer);
    c.SDL_DestroyWindow(self.window);
    c.SDL_Quit();
}

pub fn clear(self: *SDL) SDLError!void {
    _ = c.SDL_RenderClear(self.renderer);
    _ = c.SDL_RenderPresent(self.renderer);
}

pub fn is_quit(_: *SDL, event: *Event) bool {
    return switch (event.ptr.type) {
        c.SDL_EVENT_QUIT => true,
        c.SDL_EVENT_KEY_DOWN => {
            return switch (event.ptr.key.key) {
                c.SDLK_ESCAPE => true,
                c.SDLK_Q => true,
                else => false,
            };
        },
        else => false,
    };
}

pub fn renderers(_: *SDL) void {
    std.debug.print("Renderers:\n", .{});
    for (0..@intCast(c.SDL_GetNumRenderDrivers())) |i| {
        std.debug.print(" * {s}\n", .{c.SDL_GetRenderDriver(@intCast(i))});
    }
}

pub fn wait_event(_: *SDL) SDLError!Event {
    var event: c.SDL_Event = undefined;
    if (!c.SDL_WaitEvent(&event)) {
        std.debug.print("Getting next event failed: {s}\n", .{c.SDL_GetError()});
        return SDLError.FailedGettingEvent;
    }

    return Event{ .ptr = event };
}
