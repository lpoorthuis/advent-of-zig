const std = @import("std");
const fs = std.fs;
const io = std.io;
const debug = std.debug;
const ArrayList = std.ArrayList;

const Point = struct {
    x: i64,
    y: i64,
};

const TriggerResult = struct {
    aPresses: i64,
    bPresses: i64,
};

const Machine = struct {
    pointA: Point,
    pointB: Point,
    target: Point,
};

fn parsePoint(line: []const u8) !Point {
    // Find the X and Y positions
    const x_start = std.mem.indexOf(u8, line, "X") orelse return error.InvalidFormat;
    const y_start = std.mem.indexOf(u8, line, "Y") orelse return error.InvalidFormat;

    // Extract X value
    var x_str = line[x_start + 1 ..];
    if (x_str[0] == '=') x_str = x_str[1..];
    if (x_str[0] == '+') x_str = x_str[1..];
    x_str = x_str[0..std.mem.indexOf(u8, x_str, ",").?];

    // Extract Y value
    var y_str = line[y_start + 1 ..];
    if (y_str[0] == '=') y_str = y_str[1..];
    if (y_str[0] == '+') y_str = y_str[1..];

    // Parse the numbers
    const x = try std.fmt.parseInt(i64, x_str, 10);
    const y = try std.fmt.parseInt(i64, y_str, 10);

    return Point{ .x = x, .y = y };
}

fn pressedButtons(pointA: Point, pointB: Point, target: Point) ?TriggerResult {
    const aPresses = std.math.divExact(i64, target.x * pointB.y - target.y * pointB.x, pointA.x * pointB.y - pointA.y * pointB.x) catch {
        return null;
    };
    const bPresses = std.math.divExact(i64, target.x - pointA.x * aPresses, pointB.x) catch {
        return null;
    };

    const reachableTarget = aPresses * pointA.x + bPresses * pointB.x == target.x and aPresses * pointA.y + bPresses * pointB.y == target.y;

    return if (reachableTarget) TriggerResult{ .aPresses = aPresses, .bPresses = bPresses } else null;
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

    var machines = ArrayList(Machine).init(allocator);
    defer machines.deinit();

    var buf: [1024]u8 = undefined;
    var line_count: u32 = 0;
    var current_machine: Machine = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        const point = try parsePoint(line);

        switch (line_count % 3) {
            0 => current_machine.pointA = point,
            1 => current_machine.pointB = point,
            2 => {
                current_machine.target = point;
                try machines.append(current_machine);
            },
            else => unreachable,
        }

        line_count += 1;
    }

    var tokens: i64 = 0;
    for (machines.items) |machine| {
        const result = pressedButtons(machine.pointA, machine.pointB, machine.target);
        if (result != null) {
            tokens += 3 * result.?.aPresses + result.?.bPresses;
        }
    }
    std.debug.print("Tokens: {d}\n", .{tokens});

    var tokenInflation: i64 = 0;
    for (machines.items) |machine| {
        const result = pressedButtons(machine.pointA, machine.pointB, Point{ .x = machine.target.x + 10000000000000, .y = machine.target.y + 10000000000000 });
        if (result != null) {
            tokenInflation += 3 * result.?.aPresses + result.?.bPresses;
        }
    }
    std.debug.print("TokenInflation: {d}\n", .{tokenInflation});
}
