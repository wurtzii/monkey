const std = @import("std");
const repl = @import("repl.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const stdin = std.io.getStdIn();
    const reader = stdin.reader();
    const writer = stdin.writer();

    try repl.start(&allocator, reader, writer);
}
