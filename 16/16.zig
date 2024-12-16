const std = @import("std");

const input_file_name = "input2.txt";
const input_data = @embedFile(input_file_name);

const INF = 999999999;

const directions = [_][2]i32{
    [_]i32{ 1, 0 }, // right
    [_]i32{ 0, 1 }, // down
    [_]i32{ -1, 0 }, // left
    [_]i32{ 0, -1 }, // up
};

const Direction = enum {
    Up,
    Down,
    Left,
    Right,
};

const Coord = struct {
    x: usize,
    y: usize,

    pub fn manhattan_distance(self: Coord, other: Coord) usize {
        const dx = if (self.x > other.x) self.x - other.x else other.x - self.x;
        const dy = if (self.y > other.y) self.y - other.y else other.y - self.y;
        return dx + dy;
    }

    pub fn equals(self: Coord, other: Coord) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const Node = struct {
    coord: Coord,
    path_cost: usize,
    heuristic_distance: usize,
    direction: Direction,
    parent_idx: ?usize,

    pub fn f_score(self: Node) usize {
        return self.path_cost + self.heuristic_distance;
    }

    pub fn pretty_print(self: Node) void {
        std.debug.print("Node{{coord: {d} {d}, path_cost: {d}, heuristic_distance: {d}, direction: {s}}}\n", .{ self.coord.x, self.coord.y, self.path_cost, self.heuristic_distance, @tagName(self.direction) });
    }
};

fn print2DArray(map: anytype) void {
    for (map) |line| {
        for (line) |cell| {
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}

fn findCharCoord(map: anytype, target: u8) !Coord {
    for (map, 0..) |line, y| {
        for (line, 0..) |cell, x| {
            if (cell == target) {
                return Coord{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
    }
    unreachable;
}

fn findNodeWithLowestF(nodes: []const Node) ?usize {
    if (nodes.len == 0) return null;
    var lowest_idx: usize = 0;
    var lowest_f = nodes[0].f_score();

    for (nodes, 0..) |node, i| {
        const f = node.f_score();
        if (f < lowest_f) {
            lowest_f = f;
            lowest_idx = i;
        }
    }
    return lowest_idx;
}

fn getDirectionFromMove(from: Coord, to: Coord) Direction {
    if (to.x > from.x) return .Right;
    if (to.x < from.x) return .Left;
    if (to.y > from.y) return .Down;
    return .Up;
}

fn getMovementCost(current_dir: Direction, new_dir: Direction) usize {
    const base_cost: usize = 1;
    if (current_dir != new_dir) {
        return base_cost + 1000; // Direction change penalty
    }
    return base_cost;
}

fn findNode(nodes: []const Node, pos: Coord, dir: Direction) ?usize {
    for (nodes, 0..) |node, i| {
        if (node.coord.x == pos.x and node.coord.y == pos.y and node.direction == dir) {
            return i;
        }
    }
    return null;
}

const Path = struct {
    coords: []Coord,
    cost: usize,

    pub fn pretty_print(self: Path) void {
        std.debug.print("Path{{cost: {d}, coords: [", .{self.cost});
        for (self.coords) |coord| {
            std.debug.print("({d}, {d}), ", .{ coord.x, coord.y });
        }
        std.debug.print("]}}\n", .{});
    }
};

const PathList = struct {
    paths: std.ArrayList(Path),
    min_cost: ?usize,

    pub fn init(allocator: std.mem.Allocator) PathList {
        return .{
            .paths = std.ArrayList(Path).init(allocator),
            .min_cost = null,
        };
    }

    pub fn deinit(self: *PathList) void {
        for (self.paths.items) |path| {
            self.paths.allocator.free(path.coords);
        }
        self.paths.deinit();
    }

    pub fn addPath(self: *PathList, coords: []Coord, cost: usize) !void {
        // If this is the first path or matches current min cost
        if (self.min_cost == null or cost == self.min_cost.?) {
            try self.paths.append(.{
                .coords = coords,
                .cost = cost,
            });
            self.min_cost = cost;
        } else if (cost < self.min_cost.?) {
            // If this is a better path, clear existing paths
            self.clearPaths();
            try self.paths.append(.{
                .coords = coords,
                .cost = cost,
            });
            self.min_cost = cost;
        } else {
            // Cost is higher than min, don't keep this path
            self.paths.allocator.free(coords);
        }
    }

    fn clearPaths(self: *PathList) void {
        for (self.paths.items) |path| {
            self.paths.allocator.free(path.coords);
        }
        self.paths.clearRetainingCapacity();
    }
};

fn reconstructPath(closed_list: []const Node, end_node: Node, allocator: std.mem.Allocator) ![]Coord {
    var path = std.ArrayList(Coord).init(allocator);
    errdefer path.deinit();

    var node_idx: ?usize = closed_list.len - 1;
    var current_node = end_node;

    try path.insert(0, current_node.coord);
    while (node_idx) |idx| : (node_idx = current_node.parent_idx) {
        current_node = closed_list[idx];
        try path.insert(0, current_node.coord);
    }

    return path.toOwnedSlice();
}

fn solveMazePaths(maze: anytype, start: Coord, end: Coord, allocator: std.mem.Allocator) !PathList {
    var open_list = std.ArrayList(Node).init(allocator);
    defer open_list.deinit();

    var closed_list = std.ArrayList(Node).init(allocator);
    defer closed_list.deinit();

    var path_list = PathList.init(allocator);
    defer path_list.deinit();

    try open_list.append(Node{ .coord = start, .path_cost = 0, .heuristic_distance = INF, .parent_idx = null, .direction = Direction.Right });

    while (open_list.items.len > 0) {
        const current_coord = findNodeWithLowestF(open_list.items) orelse break;
        const current_node = open_list.items[current_coord];

        // Remove current node by moving last item to its position
        if (current_coord < open_list.items.len - 1) {
            open_list.items[current_coord] = open_list.items[open_list.items.len - 1];
        }
        _ = open_list.pop();

        const current_closed_idx = closed_list.items.len;
        try closed_list.append(current_node);

        if (current_node.coord.equals(end)) {
            const path = try reconstructPath(closed_list.items, current_node, allocator);
            try path_list.addPath(path, current_node.path_cost);
            continue;
        }

        // skip if path gets to expensive
        if (path_list.min_cost) |min_cost| {
            if (current_node.path_cost > min_cost) {
                continue;
            }
        }

        for (directions) |direction| {
            const new_x = @as(i32, @intCast(current_node.coord.x)) + direction[0];
            const new_y = @as(i32, @intCast(current_node.coord.y)) + direction[1];

            if (new_x < 0 or new_y < 0 or new_x >= maze[0].len or new_y >= maze.len) {
                continue;
            }

            const new_pos = Coord{
                .x = @intCast(new_x),
                .y = @intCast(new_y),
            };

            //std.debug.print("{c}\n", .{maze[new_pos.x][new_pos.y]});
            if (maze[new_pos.y][new_pos.x] == '#') {
                continue;
            }

            const new_direction = getDirectionFromMove(current_node.coord, new_pos);

            // Skip if in closed list with same direction
            if (findNode(closed_list.items, new_pos, new_direction) != null) {
                continue;
            }

            const movement_cost = getMovementCost(current_node.direction, new_direction);
            const path_cost = current_node.path_cost + movement_cost;
            const heuristic_distance = new_pos.manhattan_distance(end);

            // Check if already in open list
            if (findNode(open_list.items, new_pos, new_direction)) |existing_idx| {
                // Update if new path is better
                if (path_cost < open_list.items[existing_idx].path_cost) {
                    open_list.items[existing_idx].path_cost = path_cost;
                    open_list.items[existing_idx].parent_idx = current_closed_idx;
                }
            } else {
                // Add to open list
                try open_list.append(Node{
                    .coord = new_pos,
                    .path_cost = path_cost,
                    .heuristic_distance = heuristic_distance,
                    .parent_idx = current_closed_idx,
                    .direction = new_direction,
                });
            }
        }
    }

    for (path_list.paths.items) |path| {
        path.pretty_print();
    }
    return path_list;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var timer = try std.time.Timer.start();

    var lines = std.mem.tokenizeSequence(u8, input_data, "\n");

    var maze = std.ArrayList([]u8).init(allocator);
    defer maze.deinit();
    while (lines.next()) |line| {
        const mut: []u8 = try allocator.alloc(u8, line.len);
        @memcpy(mut, line);
        try maze.append(mut);
    }
    const maze_map = try maze.toOwnedSlice();
    defer {
        for (maze_map) |line| {
            allocator.free(line);
        }
        allocator.free(maze_map);
    }

    print2DArray(maze_map);

    const start_position = try findCharCoord(maze_map, 'S');
    const end_position = try findCharCoord(maze_map, 'E');

    std.debug.print("start_position: {d} {d}\n", .{ start_position.x, start_position.y });
    std.debug.print("end_position: {d} {d}\n", .{ end_position.x, end_position.y });

    const result = try solveMazePaths(maze_map, start_position, end_position, allocator);

    std.debug.print("score {d}    {d}ms\n", .{ result.min_cost.?, timer.lap() / std.time.ns_per_ms });
}
