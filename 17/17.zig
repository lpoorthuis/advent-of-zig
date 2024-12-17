const std = @import("std");

const input_file_name = "input3.txt";
const input_data = @embedFile(input_file_name);

const Computer = struct {
    A: u32 = 0,
    B: u32 = 0,
    C: u32 = 0,

    opcodes: []u8 = undefined,

    instruction_pointer: usize = 0,

    result: std.ArrayList(u8),

    fn solution(self: *Computer) ![]u8 {
        var result = std.ArrayList(u8).init(std.heap.page_allocator);
        defer result.deinit();

        // Iterate through numbers and add commas
        for (self.result.items, 0..) |num, i| {
            try std.fmt.format(result.writer(), "{d}", .{num});

            if (i < self.result.items.len - 1) {
                try result.append(',');
            }
        }
        return result.toOwnedSlice();
    }

    fn combo_operand_value(self: *Computer, combo_operand: u32) u32 {
        const value = switch (combo_operand) {
            0 => 0,
            1 => 1,
            2 => 2,
            3 => 3,
            4 => self.A,
            5 => self.B,
            6 => self.C,
            else => 0,
        };
        return value;
    }

    fn run_opcode(self: *Computer, opcode: u8, operand: u32) !void {
        //std.debug.print("opcode: {d}; operand: {d}\n", .{ opcode, operand });
        const literal = operand;
        const combo = self.combo_operand_value(operand);
        //std.debug.print("literal: {d}; combo: {d}\n", .{ literal, combo });
        switch (opcode) {
            0 => {
                // computer.A = std.math.trunc(A / ( 2 ** combo))
                self.A = @divTrunc(self.A, std.math.pow(u32, 2, combo));
                self.instruction_pointer += 2;
            },
            1 => {
                // computer.B = computer.B ^ literal
                self.B = self.B ^ literal;
                self.instruction_pointer += 2;
            },
            2 => {
                // B = combo % 8
                self.B = combo % 8;
                self.instruction_pointer += 2;
            },
            3 => {
                // if A == 0 { pointer += 2 } else { pointer = opcode }
                if (self.A == 0) {
                    self.instruction_pointer += 2;
                } else {
                    self.instruction_pointer = literal;
                }
            },
            4 => {
                // B = B ^ C
                self.B = self.B ^ self.C;
                self.instruction_pointer += 2;
            },
            5 => {
                // print combo % 8
                try self.result.append(@as(u8, @intCast(combo % 8)));
                self.instruction_pointer += 2;
            },
            6 => { //
                // computer.B = std.math.trunc(A / ( 2 ** combo ))
                self.B = @divTrunc(self.A, std.math.pow(u32, 2, combo));
                self.instruction_pointer += 2;
            },
            7 => {
                // computer.C = std.math.trunc(A / ( 2 ** combo))
                self.C = @divTrunc(self.A, std.math.pow(u32, 2, combo));
                self.instruction_pointer += 2;
            },
            else => {},
        }
    }

    fn run(self: *Computer) !void {
        const literal_operand = self.opcodes[self.instruction_pointer];
        const combo_operand = self.opcodes[self.instruction_pointer + 1];
        try self.run_opcode(literal_operand, combo_operand);
    }

    fn run_computer(self: *Computer) !void {
        while (self.instruction_pointer < self.opcodes.len) {
            //std.debug.print("instruction_pointer: {d}\n", .{self.instruction_pointer});
            try self.run();
            //std.debug.print("{any}\n", .{self});
        }
        //std.debug.print("\nfin\n\n", .{});
    }
};

fn parse_computer(input: []const u8) !Computer {
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
                var opcode_list = std.ArrayList(u8).init(std.heap.page_allocator);
                defer opcode_list.deinit();
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
    return Computer{ .A = a, .B = b, .C = c, .opcodes = opcodes, .instruction_pointer = 0, .result = std.ArrayList(u8).init(std.heap.page_allocator) };
}

pub fn main() !void {
    var timer = try std.time.Timer.start();
    //var c = try parse_computer("Register A: 0\nRegister B: 0\nRegister C: 9\n\nProgram: 2,6");
    //try c.run_computer();
    //std.debug.print("{any}\n", .{c});
    //c = try parse_computer("Register A: 10\nRegister B: 0\nRegister C: 0\n\nProgram: 5,0,5,1,5,4");
    //try c.run_computer();
    //std.debug.print("{any}\n", .{c});
    //c = try parse_computer("Register A: 2024\nRegister B: 0\nRegister C: 0\n\nProgram: 0,1,5,4,3,0");
    //try c.run_computer();
    //std.debug.print("{any}\n", .{c});

    std.debug.print("{s}\n\n", .{input_data});
    const computer_clean = try parse_computer(input_data);
    var computer = computer_clean;
    //std.debug.print("{any}\n", .{computer});
    try computer.run_computer();
    //std.debug.print("{any}\n", .{computer});
    const solution = try computer.solution();
    std.debug.print("part1 {s}   {d}ms\n", .{ solution, timer.lap() / std.time.ns_per_ms });

    //const target = "2,4,1,1,7,5,1,5,4,2,5,5,0,3,3,0";
    const target = "0,3,5,4,3,0";
    computer = computer_clean;
    var moving_a: u32 = computer.A;
    while (true) {
        var soli: []u8 = undefined;
        while (computer.instruction_pointer < computer.opcodes.len) {
            try computer.run();
            //soli = try computer.solution();
            //if (!std.mem.eql(u8, soli, target[0..soli.len])) {
            //    continue :outer;
            //}
        }

        soli = try computer.solution();
        if (std.mem.eql(u8, soli, target)) {
            break;
        } else {
            computer = computer_clean;
            moving_a += 1;
            computer.A = moving_a;
        }
    }

    std.debug.print("part2 {d}   {d}ms\n", .{ moving_a, timer.lap() / std.time.ns_per_ms });
}
