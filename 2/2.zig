const std = @import("std");
const fs = std.fs;
const io = std.io;
const debug = std.debug;
const ArrayList = std.ArrayList;

fn isDescending(numbers: []const i32) bool {
    if (numbers.len <= 1) return true;

    var i: usize = 1;
    while (i < numbers.len) : (i += 1) {
        const pos_diff: i32 = numbers[i] - numbers[i - 1];
        if (1 > pos_diff or pos_diff > 3) return false;
    }
    return true;
}

fn isAscending(numbers: []const i32) bool {
    if (numbers.len <= 1) return true;

    var i: usize = 1;
    while (i < numbers.len) : (i += 1) {
        const pos_diff: i32 = numbers[i] - numbers[i - 1];
        if (-3 > pos_diff or pos_diff > -1) return false;
    }
    return true;
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

    var buf: [1024]u8 = undefined;
    var safe_reports: i32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iterator = std.mem.split(u8, line, " ");

        var list1 = ArrayList(i32).init(allocator);
        while (iterator.next()) |item| {
            const num = try std.fmt.parseInt(i32, item, 10);
            try list1.append(num);
        }

        if (isAscending(list1.items) or isDescending(list1.items)) {
            std.debug.print("Safe report{any}\n", .{list1.items});
            safe_reports += 1;
        }
        list1.deinit();
    }
    std.debug.print("Safe reports: {d}\n", .{safe_reports});
}
