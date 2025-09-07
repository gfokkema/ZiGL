const c = @import("c").c;
const std = @import("std");

const ImGui = @This();

pub const Menu = struct {
    const Item = struct {
        label: []const u8,
        shortcut: ?[]const u8 = null,

        fn init(label: []const u8, shortcut: ?[]const u8) @This() {
            return .{ .label = label, .shortcut = shortcut };
        }

        fn draw(self: Item) void {
            _ = c.igMenuItemEx(@ptrCast(self.label), null, @ptrCast(self.shortcut), false, true);
        }
    };

    name: []const u8,
    items: []const Item,

    pub fn init(name: []const u8, items: []const Item) @This() {
        return .{ .name = name, .items = items };
    }

    fn draw(self: Menu) void {
        if (!c.igBeginMainMenuBar()) return;
        defer c.igEndMainMenuBar();

        if (!c.igBeginMenu(@ptrCast(self.name), true)) return;
        defer c.igEndMenu();

        for (self.items) |i| i.draw();
    }
};

const NodeType = enum {
    root,
    dynamic,
    tree,
    text,
    table,
};

const Node = union(NodeType) {
    root: Root,
    dynamic: DynamicText,
    tree: Tree,
    text: Text,
    table: Table,

    fn draw(self: Node) void {
        switch (self) {
            inline else => |e| e.draw(),
        }
    }
};

pub const Root = struct {
    children: []const Node,

    pub fn init(children: []const Node) Root {
        return .{
            .children = children,
        };
    }

    fn draw(self: Root) void {
        for (self.children) |e| e.draw();
    }
};

pub const Tree = struct {
    label: []const u8,
    children: []const Node,

    pub fn init(label: []const u8, children: []const Node) Node {
        return .{ .tree = .{
            .label = label,
            .children = children,
        } };
    }

    fn draw(self: Tree) void {
        if (!c.igCollapsingHeader_TreeNodeFlags(@ptrCast(self.label), c.ImGuiTreeNodeFlags_DefaultOpen)) return;
        for (self.children) |e| e.draw();
    }
};

pub const Table = struct {
    pub const Row = struct {
        cells: []const Node,

        pub fn init(cells: []const Node) Row {
            return .{ .cells = cells };
        }

        fn draw(self: Row) void {
            c.igTableNextRow(0, 0);
            for (self.cells) |e| {
                if (c.igTableNextColumn()) e.draw();
            }
        }
    };

    rows: []const Row,

    pub fn init(rows: []const Row) Node {
        return .{ .table = .{
            .rows = rows,
        } };
    }

    fn draw(self: Table) void {
        if (!c.igBeginTable("table", 4, 0, c.ImVec2{}, 0)) return;
        defer c.igEndTable();

        for (self.rows) |r| r.draw();
    }
};

pub const Text = struct {
    label: []const u8,

    pub fn init(label: []const u8) Node {
        return .{ .text = .{
            .label = label,
        } };
    }

    fn draw(self: Text) void {
        c.igText(@ptrCast(self.label));
    }
};

pub const DynamicText = struct {
    const Func = fn (*anyopaque, buf: []u8) []const u8;

    ctx: *anyopaque,
    func: *const Func,

    pub fn init(ctx: *anyopaque, func: *const Func) Node {
        return .{
            .dynamic = .{
                .ctx = ctx,
                .func = func,
            },
        };
    }

    fn draw(self: DynamicText) void {
        var buf = std.mem.zeroes([1024]u8);
        const text = self.func(self.ctx, @ptrCast(&buf));
        c.igText(@ptrCast(text));
    }
};

context: *c.ImGuiContext,
menu: ?Menu,
root: ?Root,

pub fn init(window: *c.GLFWwindow, menu: ?Menu, root: ?Root) !ImGui {
    const context = c.igCreateContext(null) orelse return error.InitImGuiContext;
    errdefer c.igDestroyContext(context);

    if (!c.ImGui_ImplGlfw_InitForOpenGL(window, true)) return error.InitImGuiGlfw;
    errdefer c.ImGui_ImplGlfw_Shutdown();

    if (!c.ImGui_ImplOpenGL3_Init("#version 130")) return error.InitImGuiOgl;
    errdefer c.ImGui_ImplOpenGL3_Shutdown();

    return .{
        .context = context,
        .menu = menu,
        .root = root,
    };
}

pub fn deinit(self: *ImGui) void {
    c.ImGui_ImplOpenGL3_Shutdown();
    c.ImGui_ImplGlfw_Shutdown();
    c.igDestroyContext(self.context);
}

pub fn render(self: ImGui) void {
    c.ImGui_ImplOpenGL3_NewFrame();
    c.ImGui_ImplGlfw_NewFrame();
    c.igNewFrame();

    if (self.menu) |m| m.draw();
    if (self.root) |r| r.draw();

    c.igRender();
    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}
