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

fn swapByteMap(map: anytype, pos1: Vec2, pos2: Vec2) void {
    std.mem.swap(u8, ptrMap(map, pos1), ptrMap(map, pos2));
}

fn readCell(map: [][]u8, pos: Vec2) u8 {
    return map[@intCast(pos.r)][@intCast(pos.c)];
}

fn ptrMap(map: *const [][]u8, pos: Vec2) *u8 {
    return &map.*[@intCast(pos.r)][@intCast(pos.c)];
}

fn parseMoves(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var lines = std.mem.tokenizeSequence(u8, input, "\n");
    var moves = std.ArrayList(u8).init(allocator);

    while (lines.next()) |line| {
        try moves.appendSlice(line);
    }

    return moves.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var timer = try std.time.Timer.start();

    var sections = std.mem.tokenizeSequence(u8, input_data, "\n\n");

    const warehouse = try parseWarehouse(allocator, sections.next().?);
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
            swapByteMap(&warehouse, robot_position, next_pos);
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
                    swapByteMap(&warehouse, caret, prev_caret);
                    caret = prev_caret;
                }
                robot_position = caret.add(charToMove(move));
            }
        }
    }

    var res: usize = 0;
    for (warehouse, 0..) |line, l| {
        for (line, 0..) |cell, c| {
            if (cell == 'O') {
                res += 100 * l + c;
            }
        }
    }

    std.debug.print("GPS sum {d}    {d}ms\n", .{ res, timer.lap() / std.time.ns_per_ms });
}
