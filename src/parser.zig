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

    curToken: Token,
    peekToken: Token,

    pub fn init(lexer: *Lexer) Parser {
        const cur_token = lexer.nextToken();
        const peek_token = lexer.nextToken();

        const p = Parser{
            .lexer = lexer,
            .curToken = cur_token,
            .peekToken = peek_token,
        };

        return p;
    }

    pub fn parseProgram(self: *Parser, allocator: Allocator) !ast.Program {
        var stmts = std.ArrayList(ast.Statement).init(allocator);
        defer stmts.deinit();
        errdefer stmts.deinit();

        while (self.curToken.tokenType != Token.TokenType.EOF) {
            const stmt: ?ast.Statement = self.parseStatement() catch null;
            if (stmt) |s| {
                try stmts.append(s);
            }

            self.nextToken();
        }

        self.nextToken();

        return ast.Program{
            .statements = try stmts.toOwnedSlice(),
        };
    }

    fn parseStatement(self: *Parser) !ast.Statement {
        switch (self.curToken.tokenType) {
            .LET => {
                const ltstmt = try self.parseLetStatement();
                return ast.Statement{
                    .letStatement = ltstmt,
                };
            },

            else => {
                return error.NotSupported;
            },
        }
    }

    fn parseLetStatement(self: *Parser) !ast.LetStatement {
        const token = self.curToken;

        try self.expectPeek(Token.TokenType.IDENT);
        self.nextToken();

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
            return error.UnexpectedPeek;
        }
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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        assert(check == .ok, "leaked memory") catch @panic("leaked memory");
    }

    const allocator = gpa.allocator();

    var lex = Lexer.init(input);
    var psr = Parser.init(&lex);

    const program: ?ast.Program = psr.parseProgram(allocator) catch null;

    if (program) |prog| {
        try assert(prog.statements.len == 3, "program.Statements does not contain 3 statements");

        defer allocator.free(prog.statements[0..prog.statements.len]);
        errdefer allocator.free(prog.statements[0..prog.statements.len]);

        const Test = struct {
            expectedIdentifier: []const u8,
        };

        const tests = [_]Test{
            Test{ .expectedIdentifier = "x" },
            Test{ .expectedIdentifier = "y" },
            Test{ .expectedIdentifier = "foobar" },
        };

        for (tests, 0..) |tst, i| {
            const stmt = prog.statements[i];
            try testLetStatement(tst.expectedIdentifier, stmt);
        }
    } else {
        try assert(false, "ParseProgram() returned null");
    }
}

fn testLetStatement(name: []const u8, s: ast.Statement) !void {
    switch (s) {
        .letStatement => {
            try std.testing.expectEqual(@TypeOf(s.letStatement), ast.LetStatement);
            try std.testing.expectEqualStrings(s.letStatement.name.tokenLiteral(), name);
        },
    }
}
