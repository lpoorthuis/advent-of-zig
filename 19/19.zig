const std = @import("std");

const file_name = "input.txt";
const file = @embedFile(file_name);

fn solve(allocator: std.mem.Allocator, remaining_pattern: []u8, towels: std.ArrayList([]u8)) !bool {
    //std.debug.print("solve towels: {s}\n", .{remaining_pattern});
    if (remaining_pattern.len == 0) {
        return true;
    }
    for (towels.items) |towel| {
        //std.debug.print("try towel: {s}\n", .{towel});
        if (towel.len > remaining_pattern.len) {
            continue;
        }

        const towel_fits = std.mem.eql(u8, remaining_pattern[0..towel.len], towel);
        if (towel_fits) {
            if (try solve(allocator, remaining_pattern[towel.len..], towels)) {
                return true;
            }
        }
    }
    return false;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var timer = try std.time.Timer.start();

    var towel_patterns: std.ArrayList([]u8) = undefined;
    towel_patterns = std.ArrayList([]u8).init(allocator);
    defer {
        for (towel_patterns.items) |pattern| allocator.free(pattern);
        towel_patterns.deinit();
    }
    var patterns: std.ArrayList([]u8) = undefined;
    patterns = std.ArrayList([]u8).init(allocator);
    defer {
        for (patterns.items) |pattern| allocator.free(pattern);
        patterns.deinit();
    }

    var tokens = std.mem.tokenizeSequence(u8, file, "\n");
    var line_no: usize = 0;
    while (tokens.next()) |token| {
        switch (line_no) {
            0 => {
                var towels = std.mem.splitSequence(u8, token, ", ");
                while (towels.next()) |towel| {
                    var mut: []u8 = undefined;
                    mut = try allocator.alloc(u8, towel.len);
                    @memcpy(mut, towel);
                    try towel_patterns.append(mut);
                }
            },
            1...500 => {
                var mut: []u8 = undefined;
                mut = try allocator.alloc(u8, token.len);
                @memcpy(mut, token);
                try patterns.append(mut);
            },
            else => {},
        }
        line_no += 1;
    }

    var solved_patterns: usize = 0;
    for (patterns.items) |pattern| {
        if (try solve(allocator, pattern, towel_patterns)) {
            //std.debug.print("solved: {s}\n", .{pattern});
            solved_patterns += 1;
        }
    }
    std.debug.print("solved {} patterns in {d}ms\n", .{ solved_patterns, timer.lap() / std.time.ns_per_ms });
}