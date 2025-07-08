const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

fn println(comptime format: []const u8, args: anytype) !void {
    try stdout.print(format ++ "\n", args);
}

pub fn main() !void {
    defer bw.flush() catch |err| {
        std.debug.print("Ошибка при flush: {s}\n", .{@errorName(err)});
    };

    const nStrBytes = [_]u8{ 0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0xa };
    try stdout.print("{s}", .{nStrBytes});
}
