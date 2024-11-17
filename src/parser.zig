const std = @import("std");
const ast = @import("ast.zig");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const statement = ast.Statement;
const eql = std.mem.eql;
const assert = @import("lib/assert.zig").testAssert;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const Parser = struct {
    lexer: *Lexer,
    errors: std.ArrayList([]u8),
    curToken: Token,
    peekToken: Token,
    allocator: Allocator,

    pub fn init(allocator: Allocator, lexer: *Lexer) Parser {
        const cur_token = lexer.nextToken();
        const peek_token = lexer.nextToken();

        const p = Parser{
            .lexer = lexer,
            .errors = std.ArrayList([]u8).init(allocator),
            .curToken = cur_token,
            .peekToken = peek_token,
            .allocator = allocator,
        };

        return p;
    }

    pub fn deinit(self: *Parser) void {
        for (self.errors.items) |item| {
            self.allocator.free(item);
        }

        self.errors.deinit();
    }

    pub fn parseProgram(self: *Parser) !ast.Program {
        var stmts = std.ArrayList(ast.Statement).init(self.allocator);

        while (self.curToken.tokenType != Token.TokenType.EOF) {
            const stmt: ?ast.Statement = self.parseStatement() catch null;
            if (stmt) |s| {
                try stmts.append(s);
            }

            self.nextToken();
        }

        self.nextToken();

        return ast.Program{
            .statements = stmts,
        };
    }

    fn peekError(self: *Parser, tokenType: Token.TokenType) void {
        const str: ?[]u8 = std.fmt.allocPrint(self.allocator, "expected {s} found {s}", .{ @tagName(self.curToken.tokenType), @tagName(tokenType) }) catch return;
        if (str) |strn| {
            self.errors.append(strn) catch {};
        }
    }

    fn parseStatement(self: *Parser) !ast.Statement {
        switch (self.curToken.tokenType) {
            .LET => {
                const ltstmt = try self.parseLetStatement();
                return ast.Statement{
                    .letStatement = ltstmt,
                };
            },
            .RETURN => {
                const rstmt = try self.parseReturnStatement();
                return ast.Statement{
                    .returnStatement = rstmt,
                };
            },
            else => {
                return error.NotSupported;
            },
        }
    }

    fn parseReturnStatement(self: *Parser) !ast.ReturnStatement {
        const token = self.curToken;

        const rtstmt = ast.ReturnStatement{
            .token = token,
            .expression = null,
        };

        while (self.curToken.tokenType != Token.TokenType.SEMICOLON) {
            self.nextToken();
        }

        return rtstmt;
    }

    fn parseLetStatement(self: *Parser) !ast.LetStatement {
        const token = self.curToken;

        try self.expectPeek(Token.TokenType.IDENT);

        // std.debug.print("{any}", self.curToken);
        const name = ast.Identifier{
            .token = self.curToken,
            .value = self.curToken.literal,
        };

        const stmt = ast.LetStatement{
            .token = token,
            .name = name,
            .value = null,
        };

        try self.expectPeek(Token.TokenType.ASSIGN);

        while (self.curToken.tokenType != Token.TokenType.SEMICOLON) {
            self.nextToken();
        }

        return stmt;
    }

    fn expectPeek(self: *Parser, expected: Token.TokenType) !void {
        if (self.peekToken.tokenType != expected) {
            self.peekError(expected);
            return error.UnexpectedPeek;
        }

        self.nextToken();
    }

    fn nextToken(self: *Parser) void {
        self.curToken = self.peekToken;
        self.peekToken = self.lexer.nextToken();
    }
};

test "let statement parses correctly" {
    const input =
        \\let x = 5;
        \\let y = 10;
        \\let foobar = 8383838;
    ;

    const allocator = std.testing.allocator;

    var lex = Lexer.init(input);
    var psr = Parser.init(allocator, &lex);

    if (psr.errors.items.len > 0) {
        for (psr.errors.items) |item| {
            std.log.err("{s}", .{item});
        }

        return error.ParserErrorsFound;
    }

    defer psr.deinit();

    const program: ?ast.Program = psr.parseProgram() catch null;

    if (program) |prog| {
        try assert(prog.statements.items.len == 3, "program.Statements does not contain 3 statements");

        defer prog.statements.deinit();

        const Test = struct {
            expectedIdentifier: []const u8,
        };

        const tests = [_]Test{
            Test{ .expectedIdentifier = "x" },
            Test{ .expectedIdentifier = "y" },
            Test{ .expectedIdentifier = "foobar" },
        };

        for (tests, 0..) |tst, i| {
            const stmt = prog.statements.items[i];
            try testLetStatement(tst.expectedIdentifier, stmt);
        }
    } else {
        return error.NullProgram;
    }
}

test "test return statement found" {
    const a = std.testing.allocator;
    const input =
        \\return 5;
        \\return 10;
        \\return 993322;
    ;
    var lexer = Lexer.init(input);
    var parser = Parser.init(a, &lexer);
    const program: ?ast.Program = parser.parseProgram() catch null;

    if (program) |prog| {
        defer prog.statements.deinit();

        try std.testing.expectEqual(prog.statements.items.len, 3);
        for (prog.statements.items) |stmt| {
            switch (stmt) {
                .returnStatement => |stm| {
                    try std.testing.expectEqual(@TypeOf(stm), ast.ReturnStatement);
                    try std.testing.expectEqualStrings(stm.tokenLiteral(), "return");
                },
                else => {
                    return error.NotReturnStatement;
                },
            }
        }
    } else {
        return error.NullProgram;
    }
}

fn testLetStatement(name: []const u8, s: ast.Statement) !void {
    switch (s) {
        .letStatement => {
            try std.testing.expectEqual(@TypeOf(s.letStatement), ast.LetStatement);
            try std.testing.expectEqualStrings(s.letStatement.name.tokenLiteral(), name);
        },

        else => {
            return error.NotLetStatement;
        },
    }
}
