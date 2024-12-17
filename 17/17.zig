const std = @import("std");

const input_file_name = "input.txt";
const input_data = @embedFile(input_file_name);

fn parse_computer(input: []const u8, allocator: std.mem.Allocator) !struct { a: u32, b: u32, c: u32, opcodes: []u8 } {
    var a: u32 = 0;
    var b: u32 = 0;
    var c: u32 = 0;
    var opcodes: []u8 = undefined;

    var line_no: usize = 0;
    var lines = std.mem.splitSequence(u8, input, "\n");
    while (lines.next()) |line| {
        switch (line_no) {
            0 => {
                var split = std.mem.splitSequence(u8, line, ": ");
                _ = split.next().?;
                a = try std.fmt.parseInt(u32, split.next().?, 10);
            },
            1 => {
                var split = std.mem.splitSequence(u8, line, ": ");
                _ = split.next().?;
                b = try std.fmt.parseInt(u32, split.next().?, 10);
            },
            2 => {
                var split = std.mem.splitSequence(u8, line, ": ");
                _ = split.next().?;
                c = try std.fmt.parseInt(u32, split.next().?, 10);
            },
            3 => {},
            4 => {
                var split = std.mem.splitSequence(u8, line, " ");
                _ = split.next().?;
                var opcode_tokens = std.mem.splitSequence(u8, split.next().?, ",");
                var opcode_list = std.ArrayList(u8).init(allocator);
                errdefer opcode_list.deinit();
                while (opcode_tokens.next()) |token| {
                    const opcode = std.fmt.parseInt(u8, token, 10) catch continue;
                    try opcode_list.append(opcode);
                }
                opcodes = try opcode_list.toOwnedSlice();
            },
            else => break,
        }
        line_no += 1;
    }
    return .{ .a = a, .b = b, .c = c, .opcodes = opcodes };
}

fn combo_operand_value(combo_operand: u32, A: u32, B: u32, C: u32) u32 {
    return switch (combo_operand) {
        0 => 0,
        1 => 1,
        2 => 2,
        3 => 3,
        4 => A,
        5 => B,
        6 => C,
        else => 0,
    };
}

fn run_computer(a: u32, b: u32, c: u32, opcodes: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var A = a;
    var B = b;
    var C = c;

    var result = std.ArrayList(u8).init(allocator);
    errdefer result.deinit();

    var instruction_pointer: usize = 0;
    while (instruction_pointer < opcodes.len) {
        const opcode = opcodes[instruction_pointer];
        const operand = opcodes[instruction_pointer + 1];

        const literal = operand;
        const combo = combo_operand_value(operand, A, B, C);

        switch (opcode) {
            0 => {
                A = @divTrunc(A, std.math.pow(u32, 2, combo));
                instruction_pointer += 2;
            },
            1 => {
                B = B ^ literal;
                instruction_pointer += 2;
            },
            2 => {
                B = combo % 8;
                instruction_pointer += 2;
            },
            3 => {
                instruction_pointer = if (A == 0) instruction_pointer + 2 else literal;
            },
            4 => {
                B = B ^ C;
                instruction_pointer += 2;
            },
            5 => {
                try result.append(@as(u8, @intCast(combo % 8)));
                instruction_pointer += 2;
            },
            6 => {
                B = @divTrunc(A, std.math.pow(u32, 2, combo));
                instruction_pointer += 2;
            },
            7 => {
                C = @divTrunc(A, std.math.pow(u32, 2, combo));
                instruction_pointer += 2;
            },
            else => instruction_pointer += 2,
        }
    }
    return result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var timer = try std.time.Timer.start();

    const computer_data = try parse_computer(input_data, allocator);
    defer allocator.free(computer_data.opcodes);

    const solution = try run_computer(
        computer_data.a,
        computer_data.b,
        computer_data.c,
        computer_data.opcodes,
        allocator,
    );
    defer allocator.free(solution);
    std.debug.print("part1 {any}   {d}ms\n\n", .{ solution, timer.lap() / std.time.ns_per_ms });

    std.debug.print("{any}\n", .{computer_data.opcodes});

    var moving_a: u32 = 0;
    var target_index = computer_data.opcodes.len;
    while (target_index > 0) {
        target_index -= 1;

        moving_a <<= 3;
        std.debug.print("target_index: {d} a: {d}\n", .{ target_index, moving_a });

        while (true) {
            const soli = try run_computer(moving_a, computer_data.b, computer_data.c, computer_data.opcodes, allocator);
            defer allocator.free(soli);

            if (std.mem.eql(u8, soli, computer_data.opcodes[target_index..])) {
                break;
            }
            moving_a += 1;
        }
    }

    std.debug.print("part2 {d}   {d}ms\n", .{ moving_a, timer.lap() / std.time.ns_per_ms });
}
