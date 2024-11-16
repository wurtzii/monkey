const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;

pub fn start(allocator: *Allocator, reader: anytype, writer: anytype) !void {
    var quit = false;

    try writer.print(">> ", .{});
    while (!quit) {
        const input = reader.readUntilDelimiterAlloc(allocator.*, '\n', 50) catch {
            continue;
        };

        defer allocator.free(input);

        if (eql(u8, input, "quit")) {
            try writer.print("goodbye\n", .{});
            quit = true;
        } else {
            var l = Lexer.init(input);

            while (true) {
                const tok = l.nextToken();
                if (tok.tokenType == Token.TokenType.EOF) {
                    break;
                }

                try writer.print("{{Type: {s} Literal: {s}}}\n", .{ @tagName(tok.tokenType), tok.literal });
            }
            try writer.print(">> ", .{});
        }
    }
}
