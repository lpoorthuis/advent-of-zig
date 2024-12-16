const std = @import("std");

const input_file_name = "input.txt";
const input_data = @embedFile(input_file_name);

fn calculate_token(input: []const u8, debug: bool) !usize {
    if (debug) {
        std.debug.print("calced: {s}\n", .{input});
    }
    var start_index: usize = 0;
    var result: usize = 0;
    while (std.mem.indexOfPos(u8, input, start_index, "mul(")) |offset_index| {
        //std.debug.print("start_index: {d}; offset_index: {d}\n", .{ start_index, offset_index });
        start_index = offset_index + 4;
        //std.debug.print("{s}\n", .{input[start_index..]});

        const local_end_index = std.mem.indexOfPos(u8, input, start_index, ")");
        if (local_end_index == null) {
            continue;
        }
        var tokens = std.mem.tokenizeSequence(u8, input[start_index..local_end_index.?], ",");

        //std.debug.print("tokens: {s}\n", .{tokens.peek().?});
        const a: u32 = std.fmt.parseInt(u32, tokens.next().?, 10) catch continue;
        //std.debug.print("tokens: {s}\n", .{tokens.peek().?});
        const b: u32 = std.fmt.parseInt(u32, tokens.next().?, 10) catch continue;

        if (tokens.next() == null) {
            result += a * b;
        }
    }
    std.debug.print("\n", .{});
    return result;
}

fn part2(input: []const u8) !usize {
    var result: usize = 0;
    var tokens = std.mem.tokenizeSequence(u8, input, "don't()");
    var i: i32 = -1;
    while (tokens.next()) |token| {
        i += 1;

        std.debug.print("{d} token: {s}\n\n\n", .{ i, token });
        std.debug.print("bruh\n", .{});
        //std.debug.print("token: {s}\n{d}\n\n", .{ token, i });
        if (@mod(i, 2) == 0) {
            //std.debug.print("do\n", .{});
            result += calculate_token(token, false) catch continue;
            //std.debug.print("res: {d}\n\n", .{result});
        } else {
            std.debug.print("not do\n", .{});
            if (std.mem.containsAtLeast(u8, token, 1, "do()")) {
                const do_index = std.mem.indexOf(u8, token, "do()");
                const do_token = token[do_index.?..];
                result += calculate_token(do_token, true) catch continue;
                std.debug.print("res: {d}\n\n", .{result});
            }
        }
    }
    return result;
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    var cleaned_data: [input_data.len]u8 = undefined;
    _ = std.mem.replace(u8, input_data, "\n", " ", cleaned_data[0..]);

    const result = try calculate_token(input_data, false);

    std.debug.print("result1 {d}    {d}ms\n", .{ result, timer.lap() / std.time.ns_per_ms });

    const result2 = try part2(input_data);

    std.debug.print("result1 {d}    {d}ms\n", .{ result, timer.lap() / std.time.ns_per_ms });
    std.debug.print("result2 {d}    {d}ms\n", .{ result2, timer.lap() / std.time.ns_per_ms });
}
