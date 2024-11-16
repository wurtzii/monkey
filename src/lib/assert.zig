const print = @import("std").debug.print;

pub fn assert(ok: bool, str: []const u8) void {
    if (!ok) {
        print("{s}", .{str});
        unreachable;
    }
}

pub fn testAssert(ok: bool, str: []const u8) !void {
    if (!ok) {
        print("{s}\n", .{str});
        return error.AssertionFailed;
    }
}
