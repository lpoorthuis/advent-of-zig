const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const input_file_name = "input.txt";
const input_data = @embedFile(input_file_name);

const Direction = enum {
    right,
    up,
    left,
    down,

    fn turnCost(from: Direction, to: Direction) u32 {
        if (from == to) return 0;
        return 1000;
    }

    fn toString(self: Direction) []const u8 {
        return switch (self) {
            .right => "→",
            .up => "↑",
            .left => "←",
            .down => "↓",
        };
    }
};

const Position = struct {
    x: usize,
    y: usize,

    fn eql(self: Position, other: Position) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const State = struct {
    pos: Position,
    dir: Direction,
};

const Path = struct {
    positions: ArrayList(Position),
    cost: u32,

    fn init(allocator: std.mem.Allocator) Path {
        return .{
            .positions = ArrayList(Position).init(allocator),
            .cost = 0,
        };
    }

    fn deinit(self: *Path) void {
        self.positions.deinit();
    }
};

const QueueItem = struct {
    state: State,
    cost: u32,
    path: ArrayList(Position),

    fn printDebug(self: QueueItem, map: []const []const u8, writer: anytype) !void {
        try writer.print("\n=== Queue Item Debug Info ===\n", .{});
        try writer.print("Cost: {}\n", .{self.cost});
        try writer.print("Current Position: ({}, {})\n", .{ self.state.pos.x, self.state.pos.y });
        try writer.print("Direction: {} ({})\n", .{ self.state.dir, self.state.dir.toString() });

        try writer.print("Path Length: {}\n", .{self.path.items.len});
        try writer.print("Path: ", .{});
        for (self.path.items) |pos| {
            try writer.print("({},{}) ", .{ pos.x, pos.y });
        }
        try writer.print("\n", .{});

        try writer.print("\nMap Visualization:\n", .{});

        var path_positions = AutoHashMap(Position, void).init(std.heap.page_allocator);
        defer path_positions.deinit();

        for (self.path.items) |pos| {
            path_positions.put(pos, {}) catch continue;
        }

        for (map, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                const pos = Position{ .x = x, .y = y };
                const is_current = pos.eql(self.state.pos);
                const is_in_path = path_positions.contains(pos);

                if (is_current) {
                    try writer.print("{s}", .{self.state.dir.toString()});
                } else if (is_in_path) {
                    try writer.print("•", .{});
                } else {
                    try writer.print("{c}", .{cell});
                }
            }
            try writer.print("\n", .{});
        }
        try writer.print("\n=========================\n", .{});
    }
};

const VisitedKey = struct {
    pos: Position,
    dir: Direction,
};

const VisitedInfo = struct {
    cost: u32,
    keep_exploring: bool,
};

pub fn findPaths(
    allocator: std.mem.Allocator,
    map: []const []const u8,
) !void {
    var start_pos: Position = undefined;
    var end_pos: Position = undefined;

    for (map, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == 'S') {
                start_pos = .{ .x = x, .y = y };
            } else if (cell == 'E') {
                end_pos = .{ .x = x, .y = y };
            }
        }
    }

    var queue = ArrayList(QueueItem).init(allocator);
    defer queue.deinit();

    var visited = AutoHashMap(VisitedKey, VisitedInfo).init(allocator);
    defer visited.deinit();

    var optimal_paths = ArrayList(Path).init(allocator);
    defer {
        for (optimal_paths.items) |*path| {
            path.deinit();
        }
        optimal_paths.deinit();
    }

    var initial_path = ArrayList(Position).init(allocator);
    try initial_path.append(start_pos);

    try queue.append(.{
        .state = .{
            .pos = start_pos,
            .dir = .right,
        },
        .cost = 0,
        .path = initial_path,
    });

    var min_cost: ?u32 = null;

    while (queue.items.len > 0) {
        var min_idx: usize = 0;
        for (queue.items, 0..) |item, i| {
            if (item.cost < queue.items[min_idx].cost) {
                min_idx = i;
            }
        }
        const current = queue.swapRemove(min_idx);

        if (min_cost != null and current.cost > min_cost.?) {
            current.path.deinit();
            continue;
        }

        if (current.state.pos.x == end_pos.x and current.state.pos.y == end_pos.y) {
            if (min_cost == null or current.cost <= min_cost.?) {
                min_cost = current.cost;
                var new_path = Path.init(allocator);
                new_path.cost = current.cost;
                try new_path.positions.appendSlice(current.path.items);
                try optimal_paths.append(new_path);
            }
            current.path.deinit();
            continue;
        }

        const dirs = [_]Direction{ .right, .up, .left, .down };
        for (dirs) |new_dir| {
            const turn_cost = Direction.turnCost(current.state.dir, new_dir);
            var new_pos = current.state.pos;

            switch (new_dir) {
                .right => new_pos.x += 1,
                .left => new_pos.x -= 1,
                .up => new_pos.y -= 1,
                .down => new_pos.y += 1,
            }

            if (new_pos.y >= map.len or new_pos.x >= map[0].len) continue;
            if (map[new_pos.y][new_pos.x] == '#') continue;

            const new_state = State{
                .pos = new_pos,
                .dir = new_dir,
            };

            const new_cost = current.cost + turn_cost + 1;

            const visited_key = VisitedKey{
                .pos = new_pos,
                .dir = new_dir,
            };

            if (visited.get(visited_key)) |info| {
                if (new_cost > info.cost) continue;
                if (new_cost == info.cost and !info.keep_exploring) continue;
            }

            try visited.put(visited_key, .{
                .cost = new_cost,
                .keep_exploring = true,
            });

            var new_path = ArrayList(Position).init(allocator);
            try new_path.appendSlice(current.path.items);
            try new_path.append(new_pos);

            try queue.append(.{
                .state = new_state,
                .cost = new_cost,
                .path = new_path,
            });
        }
        current.path.deinit();
    }

    var unique_tiles = AutoHashMap(Position, void).init(allocator);
    defer unique_tiles.deinit();

    if (min_cost) |cost| {
        print("Found {} optimal paths with cost: {}\n", .{ optimal_paths.items.len, cost });

        for (optimal_paths.items, 0..) |path, i| {
            print("\nPath {}:\n", .{i + 1});
            for (path.positions.items) |pos| {
                try unique_tiles.put(pos, {});
                print("({}, {})->", .{ pos.x, pos.y });
            }
        }

        print("\n\nTotal unique tiles visited across all optimal paths: {}\n", .{unique_tiles.count()});
    } else {
        print("No path found!\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var timer = try std.time.Timer.start();

    var lines = std.mem.tokenizeSequence(u8, input_data, "\n");
    var maze = std.ArrayList([]const u8).init(allocator);
    defer maze.deinit();

    while (lines.next()) |line| {
        const mut: []u8 = try allocator.alloc(u8, line.len);
        @memcpy(mut, line);
        try maze.append(mut);
    }
    const map = try maze.toOwnedSlice();
    defer {
        for (map) |row| {
            allocator.free(row);
        }
        allocator.free(map);
    }

    try findPaths(allocator, map);
    std.debug.print("solving took    {d}ms\n", .{timer.lap() / std.time.ns_per_ms});
}
