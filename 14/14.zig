const std = @import("std");
const fs = std.fs;
const io = std.io;
const debug = std.debug;
const ArrayList = std.ArrayList;

const Robot = struct {
    x: i32,
    y: i32,
    vX: i32,
    vY: i32,
};

const QuadrantCounts = struct {
    top_left: usize,
    top_right: usize,
    bottom_left: usize,
    bottom_right: usize,
};

const Grid = struct {
    data: [][]u32,
    width: usize,
    height: usize,

    fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Grid {
        var data = try allocator.alloc([]u32, height);
        for (data, 0..) |_, i| {
            data[i] = try allocator.alloc(u32, width);
            @memset(data[i], 0);
        }
        return Grid{
            .data = data,
            .width = width,
            .height = height,
        };
    }

    fn deinit(self: *Grid, allocator: std.mem.Allocator) void {
        for (self.data) |row| {
            allocator.free(row);
        }
        allocator.free(self.data);
    }

    fn placeRobot(self: *Grid, x: i32, y: i32) void {
        const wrapped_x = @mod(x, @as(i32, @intCast(self.width)));
        const wrapped_y = @mod(y, @as(i32, @intCast(self.height)));
        self.data[@intCast(wrapped_y)][@intCast(wrapped_x)] += 1;
    }

    fn print(self: Grid) void {
        for (self.data) |row| {
            for (row) |count| {
                if (count == 0) {
                    std.debug.print(".", .{});
                } else {
                    std.debug.print("{}", .{count});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    fn countRobotsInQuadrants(self: Grid) QuadrantCounts {
        var counts = QuadrantCounts{
            .top_left = 0,
            .top_right = 0,
            .bottom_left = 0,
            .bottom_right = 0,
        };

        const mid_x = self.width / 2;
        const mid_y = self.height / 2;

        for (self.data, 0..) |row, y| {
            for (row, 0..) |count, x| {
                if (count == 0) continue;

                if (y < mid_y) {
                    if (x < mid_x) {
                        counts.top_left += count;
                    } else if (x > mid_x) {
                        counts.top_right += count;
                    }
                } else if (y > mid_y) {
                    if (x < mid_x) {
                        counts.bottom_left += count;
                    } else if (x > mid_x) {
                        counts.bottom_right += count;
                    }
                }
            }
        }

        return counts;
    }

    fn printQuadrantCounts(self: Grid) void {
        const counts = self.countRobotsInQuadrants();
        const total = counts.top_left + counts.top_right +
            counts.bottom_left + counts.bottom_right;

        std.debug.print("\nRobots in each quadrant:\n", .{});
        std.debug.print("Top Left: {} robots\n", .{counts.top_left});
        std.debug.print("Top Right: {} robots\n", .{counts.top_right});
        std.debug.print("Bottom Left: {} robots\n", .{counts.bottom_left});
        std.debug.print("Bottom Right: {} robots\n", .{counts.bottom_right});
        std.debug.print("Safety Score: {}\n", .{counts.top_left * counts.bottom_right *
            counts.top_right * counts.bottom_left});
        std.debug.print("Total: {} robots\n", .{total});
    }

    fn clear(self: *Grid) void {
        for (self.data) |row| {
            @memset(row, 0);
        }
    }
};

fn parseRobot(line: []const u8) !Robot {
    const start = std.mem.indexOf(u8, line, "p=") orelse return error.InvalidFormat;
    const v_start = std.mem.indexOf(u8, line, "v=") orelse return error.InvalidFormat;

    const str = line[start + 2 .. v_start - 1];
    const comma = std.mem.indexOf(u8, str, ",") orelse return error.InvalidFormat;
    const x = try std.fmt.parseInt(i32, str[0..comma], 10);
    const y = try std.fmt.parseInt(i32, str[comma + 1 ..], 10);

    const v_str = line[v_start + 2 ..];
    const v_comma = std.mem.indexOf(u8, v_str, ",") orelse return error.InvalidFormat;
    const vX = try std.fmt.parseInt(i32, v_str[0..v_comma], 10);
    const vY = try std.fmt.parseInt(i32, v_str[v_comma + 1 ..], 10);

    return Robot{
        .x = x,
        .y = y,
        .vX = vX,
        .vY = vY,
    };
}

fn moveRobots(robots: []Robot, grid: *Grid) void {
    grid.clear();

    for (robots) |*robot| {
        robot.x = @mod(robot.x + robot.vX, @as(i32, @intCast(grid.width)));
        robot.y = @mod(robot.y + robot.vY, @as(i32, @intCast(grid.height)));

        grid.placeRobot(robot.x, robot.y);
    }
}

pub fn main() !void {
    const path = "input.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var file = try fs.cwd().openFile(path, .{ .mode = fs.File.OpenMode.read_only });
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var in_stream = buffered.reader();

    var arr = ArrayList(u8).init(allocator);
    defer arr.deinit();

    var robots = ArrayList(Robot).init(allocator);
    defer robots.deinit();

    var buf: [1024]u8 = undefined;
    var line_count: u32 = 0;
    var current_robot: Robot = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        current_robot = try parseRobot(line);
        try robots.append(current_robot);

        line_count += 1;
    }

    var grid = try Grid.init(allocator, 101, 103);
    defer grid.deinit(allocator);

    for (robots.items) |robot| {
        grid.placeRobot(robot.x, robot.y);
    }

    std.debug.print("Initial state:\n", .{});
    grid.print();

    for (0..6876) |seconds| {
        moveRobots(robots.items, &grid);
        std.debug.print("\nAfter {} seconds:\n", .{seconds + 1});
        grid.print();
    }

    std.debug.print("\nAfter moving:\n", .{});
    grid.printQuadrantCounts();
}
