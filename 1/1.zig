const std = @import("std");
const fs = std.fs;
const io = std.io;
const debug = std.debug;
const ArrayList = std.ArrayList;

pub fn main() !void {
    const path = "input.txt";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var file = try fs.cwd().openFile(path, .{ .mode = fs.File.OpenMode.read_only });
    defer file.close();

    // Things are _a lot_ slower if we don't use a BufferedReader
    var buffered = std.io.bufferedReader(file.reader());
    var reader = buffered.reader();

    // lines will get read into this
    var arr = ArrayList(u8).init(allocator);
    defer arr.deinit();

    var list1 = ArrayList(u32).init(allocator);
    var list2 = ArrayList(u32).init(allocator);
    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        std.debug.print("{s}\n", .{arr.items});
        const first = arr.items[0];
        const second = arr.items[1];
        list1.append(first) catch {};
        list2.append(second) catch {};
        arr.clearRetainingCapacity();
    }

    std.debug.print("Before sorting:\n", .{});
    std.debug.print("{d}\n", .{list1.items[0]});
    std.mem.sort(u32, list1.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, list2.items, {}, comptime std.sort.asc(u32));
    std.debug.print("{d}\n", .{list1.items[0]});

    list1.deinit();
    list2.deinit();
}
