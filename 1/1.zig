const std = @import("std");
const fs = std.fs;
const io = std.io;
const debug = std.debug;
const ArrayList = std.ArrayList;

fn countOccurences(list: std.ArrayList(i32), target: i32) i32 {
    var count: i32 = 0;
    for (list.items) |item| {
        if (item == target) {
            count += 1;
        }
    }
    return count;
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

    var list1 = ArrayList(i32).init(allocator);
    defer list1.deinit();
    var list2 = ArrayList(i32).init(allocator);
    defer list2.deinit();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iterator = std.mem.split(u8, line, "   ");

        const first_str = iterator.next() orelse continue;
        const first_num = try std.fmt.parseInt(i32, first_str, 10);
        try list1.append(first_num);

        const second_str = iterator.next() orelse continue;
        const second_num = try std.fmt.parseInt(i32, second_str, 10);
        try list2.append(second_num);
    }

    std.mem.sort(i32, list1.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, list2.items, {}, comptime std.sort.asc(i32));

    if (list1.items.len != list2.items.len) {
        std.debug.print("Lists are not the same length\n", .{});
        return;
    }

    var distance: u32 = 0;
    for (list1.items, 0..) |item, i| {
        distance += @abs(item - list2.items[i]);
    }
    std.debug.print("Distance: {d}\n", .{distance});

    var similarity: i32 = 0;
    for (list1.items) |item| {
        similarity += item * countOccurences(list2, item);
    }
    std.debug.print("Similarity: {d}\n", .{similarity});
}
