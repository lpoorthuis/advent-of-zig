const std = @import("std");

const input_file_name = "input.txt";
const input_data = @embedFile(input_file_name);

pub fn main() !void {
    var timer = try std.time.Timer.start();

    std.debug.print("input_data: {s}\n", .{input_data});

    var start_index: usize = 0;
    var result: usize = 0;
    while (std.mem.indexOfPos(u8, input_data, start_index, "mul(")) |offset_index| {
        //std.debug.print("start_index: {d}; offset_index: {d}\n", .{ start_index, offset_index });
        start_index = offset_index + 4;
        //std.debug.print("{s}\n", .{input_data[start_index..]});

        const local_end_index = std.mem.indexOfPos(u8, input_data, start_index, ")");
        var tokens = std.mem.tokenizeSequence(u8, input_data[start_index..local_end_index.?], ",");

        //std.debug.print("tokens: {s}\n", .{tokens.peek().?});
        const a: u32 = std.fmt.parseInt(u32, tokens.next().?, 10) catch continue;
        //std.debug.print("tokens: {s}\n", .{tokens.peek().?});
        const b: u32 = std.fmt.parseInt(u32, tokens.next().?, 10) catch continue;

        if (tokens.next() == null) {
            //std.debug.print("success\n", .{});
            result += a * b;
        }
    }
    std.debug.print("result {d}    {d}ms\n", .{ result, timer.lap() / std.time.ns_per_ms });
}
