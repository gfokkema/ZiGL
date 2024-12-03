const std = @import("std");
const gio = @import("gio");
const gdk = @import("gdk");
const gtk = @import("gtk");
const gobject = @import("gobject");

const c = @cImport({
    @cInclude("epoxy/glx.h");
});

pub fn main() void {
    var app = gtk.Application.new("org.gtk.example", .{});
    defer app.unref();
    _ = gio.Application.signals.activate.connect(app, ?*anyopaque, &activate, null, .{});
    const status = gio.Application.run(app.as(gio.Application), @intCast(std.os.argv.len), std.os.argv.ptr);
    std.process.exit(@intCast(status));
}

fn activate(app: *gtk.Application, _: ?*anyopaque) callconv(.C) void {
    var window = gtk.ApplicationWindow.new(app);
    gtk.Window.setTitle(window.as(gtk.Window), "Window");
    gtk.Window.setDefaultSize(window.as(gtk.Window), 1280, 720);

    var box = gtk.Box.new(gtk.Orientation.vertical, 0);
    gtk.Widget.setHalign(box.as(gtk.Widget), gtk.Align.center);
    gtk.Widget.setValign(box.as(gtk.Widget), gtk.Align.center);
    gtk.Window.setChild(window.as(gtk.Window), box.as(gtk.Widget));

    var area = gtk.GLArea.new();
    gtk.Box.append(box, area.as(gtk.Widget));

    _ = gtk.GLArea.signals.create_context.connect(area, ?*anyopaque, &initialize, window, .{});

    gtk.Widget.show(window.as(gtk.Widget));
}

pub fn initialize(area: *gtk.GLArea, _: ?*anyopaque) callconv(.C) *gdk.GLContext {
    std.debug.print("init\n", .{});
    gtk.GLArea.makeCurrent(area);
    return gtk.GLArea.getContext(area) orelse std.debug.panic("PANIC", .{});
}

pub fn print(_: *gtk.Button, _: ?*anyopaque) callconv(.C) void {
    std.debug.print("print\n", .{});
}

pub fn render(_: *gtk.GLArea, _: *gdk.GLContext, _: ?*anyopaque) callconv(.C) c_int {
    c.glClearColour(255, 0, 0, 0);
    std.debug.print("render\n", .{});
    return 0;
}
