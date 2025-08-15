const c = @import("c").c;
const std = @import("std");

const ImGui = @This();

const Menu = struct {
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

    fn init(name: []const u8, items: []const Item) @This() {
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
    tree,
    text,
    table,
};

const Node = union(NodeType) {
    root: Root,
    tree: Tree,
    text: Text,
    table: Table,

    fn draw(self: Node) void {
        switch (self) {
            inline else => |e| e.draw(),
        }
    }
};

const Root = struct {
    children: []const Node,

    fn init(children: []const Node) Node {
        return .{ .root = .{
            .children = children,
        } };
    }

    fn draw(self: Root) void {
        for (self.children) |e| e.draw();
    }
};

const Tree = struct {
    label: []const u8,
    children: []const Node,

    fn init(label: []const u8, children: []const Node) Node {
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

const Table = struct {
    const Row = struct {
        cells: []const Node,

        fn init(cells: []const Node) Row {
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

    fn init(rows: []const Row) Node {
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

const Text = struct {
    label: []const u8,

    fn init(label: []const u8) Node {
        return .{ .text = .{
            .label = label,
        } };
    }

    fn draw(self: Text) void {
        c.igText(@ptrCast(self.label));
    }
};

context: *c.ImGuiContext,
menu: Menu,
root: Node,

pub fn init(window: *c.GLFWwindow) !ImGui {
    const context = c.igCreateContext(null) orelse return error.InitImGuiContext;
    errdefer c.igDestroyContext(context);

    if (!c.ImGui_ImplGlfw_InitForOpenGL(window, true)) return error.InitImGuiGlfw;
    errdefer c.ImGui_ImplGlfw_Shutdown();

    if (!c.ImGui_ImplOpenGL3_Init("#version 130")) return error.InitImGuiOgl;
    errdefer c.ImGui_ImplOpenGL3_Shutdown();

    return .{
        .context = context,
        .menu = Menu.init("File", &.{
            .{ .label = "Create" },
            .{ .label = "Open", .shortcut = "Ctrl+O" },
            .{ .label = "Save", .shortcut = "Ctrl+S" },
            .{ .label = "Save as.." },
        }),
        .root = Root.init(&.{
            Tree.init("a", &.{
                Text.init("debug1"),
            }),
            Tree.init("b", &.{
                Table.init(&.{
                    Table.Row.init(&.{ Text.init("Key"), Text.init("Value") }),
                    Table.Row.init(&.{ Text.init("a"), Text.init("1") }),
                }),
            }),
            Tree.init("c", &.{
                Text.init("debug2"),
            }),
        }),
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

    self.menu.draw();
    var t = Root.init(&.{
        Tree.init("a", &.{
            Text.init("debug1"),
        }),
        Tree.init("b", &.{
            Table.init(&.{
                Table.Row.init(&.{ Text.init("Key"), Text.init("Value") }),
                Table.Row.init(&.{ Text.init("a"), Text.init("1") }),
            }),
        }),
        Tree.init("c", &.{
            Text.init("debug2"),
        }),
    });
    t.draw();

    c.igRender();
    c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
}
