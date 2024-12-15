const std = @import("std");
const fs = std.fs;
const io = std.io;
const debug = std.debug;

const input_file_name = "input.txt";
const input_data = @embedFile(input_file_name);

const Move = [2]i8;

fn charToMove(c: u8) Move {
    return switch (c) {
        '>' => .{ 0, 1 },
        '<' => .{ 0, -1 },
        '^' => .{ -1, 0 },
        'v' => .{ 1, 0 },
        else => unreachable,
    };
}

const Vec2 = struct {
    r: isize,
    c: isize,
    pub fn add(self: Vec2, drdc: [2]i8) Vec2 {
        return .{
            .r = self.r + drdc[0],
            .c = self.c + drdc[1],
        };
    }

    pub fn left(self: Vec2) Vec2 {
        return .{
            .r = self.r,
            .c = self.c - 1,
        };
    }

    pub fn right(self: Vec2) Vec2 {
        return .{
            .r = self.r,
            .c = self.c + 1,
        };
    }
};

fn parseWarehouse(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var warehouse = std.ArrayList([]u8).init(allocator);

    while (lines.next()) |line| {
        const mut: []u8 = try allocator.alloc(u8, line.len);
        @memcpy(mut, line);
        try warehouse.append(mut);
    }

    return warehouse.toOwnedSlice();
}

fn parseInflatedWarehouse(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var warehouse = std.ArrayList([]u8).init(allocator);

    while (lines.next()) |line| {
        const new_row: []u8 = try allocator.alloc(u8, line.len * 2);
        for (line, 0..) |c, j| {
            if (c == '#') {
                new_row[2 * j] = '#';
                new_row[2 * j + 1] = '#';
            } else if (c == 'O') {
                new_row[2 * j] = '[';
                new_row[2 * j + 1] = ']';
            } else if (c == '.') {
                new_row[2 * j] = '.';
                new_row[2 * j + 1] = '.';
            } else if (c == '@') {
                new_row[2 * j] = '@';
                new_row[2 * j + 1] = '.';
            }
        }
        try warehouse.append(new_row);
    }

    return warehouse.toOwnedSlice();
}

fn swapByteMap(map: anytype, pos1: Vec2, pos2: Vec2) void {
    std.mem.swap(u8, ptrMap(map, pos1), ptrMap(map, pos2));
}

fn readCell(map: anytype, pos: Vec2) u8 {
    return map[@intCast(pos.r)][@intCast(pos.c)];
}

fn ptrMap(map: anytype, pos: Vec2) *u8 {
    return &map[@intCast(pos.r)][@intCast(pos.c)];
}

fn parseMoves(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var moves = std.ArrayList(u8).init(allocator);

    while (lines.next()) |line| {
        try moves.appendSlice(line);
    }

    return moves.toOwnedSlice();
}

fn printMap(map: anytype) void {
    for (map) |line| {
        for (line) |cell| {
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var timer = try std.time.Timer.start();

    var sections = std.mem.tokenizeSequence(u8, input_data, "\n\n");

    const warehouse_section = sections.next().?;
    const warehouse = try parseWarehouse(allocator, warehouse_section);
    defer {
        for (warehouse) |line| {
            allocator.free(line);
        }
        allocator.free(warehouse);
    }

    const moves = try parseMoves(allocator, sections.next().?);
    defer allocator.free(moves);

    var robot_position: Vec2 = blk: {
        for (0..warehouse.len) |r| {
            for (0..warehouse[r].len) |c| {
                if (warehouse[r][c] == '@') {
                    break :blk .{ .r = @intCast(r), .c = @intCast(c) };
                }
            }
        }
        unreachable;
    };

    for (moves) |move| {
        const next_pos = robot_position.add(charToMove(move));

        const next_cell = readCell(warehouse, next_pos);

        if (next_cell == '.') {
            swapByteMap(warehouse, robot_position, next_pos);
            robot_position = next_pos;
        } else if (next_cell == '#') {
            continue;
        } else if (next_cell == 'O') {
            var times: u32 = 0;
            var slide_coord = next_pos;

            while (readCell(warehouse, slide_coord) == 'O') {
                times += 1;
                slide_coord = slide_coord.add(charToMove(move));
            }
            const what_after_boxes = readCell(warehouse, slide_coord);
            if (what_after_boxes == '.') {
                const reversed_move = .{ charToMove(move)[0] * -1, charToMove(move)[1] * -1 };
                var caret = slide_coord;
                times += 1;
                while (times > 0) : (times -= 1) {
                    const prev_caret = caret.add(reversed_move);
                    swapByteMap(warehouse, caret, prev_caret);
                    caret = prev_caret;
                }
                robot_position = caret.add(charToMove(move));
            }
        }
    }

    var res: usize = 0;
    for (warehouse, 0..) |line, y| {
        for (line, 0..) |cell, x| {
            if (cell == 'O') {
                res += 100 * y + x;
            }
        }
    }

    std.debug.print("GPS sum {d}    {d}ms\n", .{ res, timer.lap() / std.time.ns_per_ms });
    std.debug.print("warehouselen {d}\n", .{warehouse.len});
    std.debug.print("warehouselen {d}\n", .{warehouse[0].len});

    // part2
    const inflated_warehouse = try parseInflatedWarehouse(allocator, warehouse_section);
    defer {
        for (inflated_warehouse) |line| {
            allocator.free(line);
        }
        allocator.free(inflated_warehouse);
    }

    std.debug.print("warehouselen {d}\n", .{inflated_warehouse.len});
    std.debug.print("warehouselen {d}\n", .{inflated_warehouse[0].len});

    robot_position = blk: {
        for (0..inflated_warehouse.len) |r| {
            for (0..inflated_warehouse[r].len) |c| {
                if (inflated_warehouse[r][c] == '@') {
                    break :blk .{ .r = @intCast(r), .c = @intCast(c) };
                }
            }
        }
        unreachable;
    };

    for (moves) |move| {
        const dmove = charToMove(move);
        const next_pos = robot_position.add(dmove);

        const next_cell = readCell(inflated_warehouse, next_pos);

        if (next_cell == '.') {
            swapByteMap(inflated_warehouse, robot_position, next_pos);
            robot_position = next_pos;
        } else if (next_cell == '#') {
            continue;
        } else if (next_cell == '[' or next_cell == ']') {
            if (dmove[0] == 0) {
                var times: u32 = 0;
                var slide_coord = next_pos;

                while (true) {
                    const c = readCell(inflated_warehouse, slide_coord);
                    if (!(c == ']' or c == '[')) break;

                    times += 1;
                    slide_coord = slide_coord.add(dmove);
                }
                const what_after_boxes = readCell(inflated_warehouse, slide_coord);
                if (what_after_boxes == '.') {
                    const reversed_dmove = .{ dmove[0] * -1, dmove[1] * -1 };
                    var caret = slide_coord;
                    times += 1;
                    while (times > 0) : (times -= 1) {
                        const prev_caret = caret.add(reversed_dmove);
                        swapByteMap(inflated_warehouse, caret, prev_caret);
                        caret = prev_caret;
                    }
                    robot_position = caret.add(dmove);
                }
            } else {
                const MapType = @TypeOf(inflated_warehouse);
                const check_map = struct {
                    pub fn check_map_fn(map: MapType, pos: Vec2, dir: [2]i8) bool {
                        const c = readCell(map, pos);
                        if (c == '.') return true;
                        if (c == '#') return false;
                        if (c == '[') return check_map_fn(map, pos.right().add(dir), dir) and check_map_fn(map, pos.add(dir), dir);
                        if (c == ']') return check_map_fn(map, pos.left().add(dir), dir) and check_map_fn(map, pos.add(dir), dir);
                        if (c == '@') return false;
                        unreachable;
                    }
                }.check_map_fn;

                const move_map = struct {
                    pub fn move_map_fn(map: MapType, pos: Vec2, dir: [2]i8, second_part: bool) bool {
                        const c = readCell(map, pos);
                        if (c == '.') {
                            const reversed_dir = .{ dir[0] * -1, dir[1] * -1 };
                            const prev_pos = pos.add(reversed_dir);
                            swapByteMap(map, pos, prev_pos);
                            return true;
                        }
                        if (c == '#') return false;
                        if (c == '[') return move_map_fn(map, pos.add(dir), dir, second_part) and move_map_fn(map, pos.right(), dir, second_part);
                        if (c == ']') return move_map_fn(map, pos.add(dir), dir, second_part) and move_map_fn(map, pos.left(), dir, second_part);

                        unreachable;
                    }
                }.move_map_fn;

                const next_map_coord = robot_position.add(dmove);
                if (check_map(inflated_warehouse, next_map_coord, dmove)) {
                    _ = move_map(inflated_warehouse, next_map_coord, dmove, false);
                    robot_position = robot_position.add(dmove);
                }
            }
        }
    }

    printMap(inflated_warehouse);
    var result: u64 = 0;
    for (inflated_warehouse, 0..) |line, y| {
        for (line, 0..) |cell, x| {
            if (cell == '[') {
                result += 100 * y + x;
            }
        }
    }
    std.debug.print("GPS sum2 {d}    {d}ms\n", .{ result, timer.lap() / std.time.ns_per_ms });
}
