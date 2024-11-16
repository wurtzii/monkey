const std = @import("std");
const isLetter = @import("lib/ascii.zig").isLetter;
const isDigit = @import("lib/ascii.zig").isDigit;

const NEWLINE: u8 = 10;
const CARRIAGE_RETURN: u8 = 13;

const EQ = "==";
const NOT_EQ = "!=";
const LT_EQ = "<=";
const GT_EQ = ">=";

pub const Lexer = struct {
    const Self = @This();
    const keywords = std.StaticStringMap(Token.TokenType).initComptime(.{
        .{ "fn", Token.TokenType.FUNCTION },
        .{ "let", Token.TokenType.LET },
        .{ "if", Token.TokenType.IF },
        .{ "else", Token.TokenType.ELSE },
        .{ "true", Token.TokenType.TRUE },
        .{ "false", Token.TokenType.FALSE },
        .{ "return", Token.TokenType.RETURN },
    });

    input: []const u8,
    position: u32 = 0,
    readPosition: u32 = 0,
    ch: u8 = 0,

    pub fn init(input: []const u8) Lexer {
        var l = Lexer{
            .input = input,
        };

        l.read_char();

        return l;
    }

    pub fn lookupIdent(ident: []const u8) Token.TokenType {
        if (keywords.get(ident)) |tok| {
            return tok;
        }

        return Token.TokenType.IDENT;
    }

    fn read_char(self: *Self) void {
        if (self.readPosition >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.readPosition];
        }

        self.position = self.readPosition;
        self.readPosition += 1;
    }

    fn peek_char(self: *Self) u8 {
        if (self.readPosition >= self.input.len) {
            return 0;
        }

        return self.input[self.readPosition];
    }

    pub fn skipWhiteSpace(self: *Self) void {
        while (self.ch == ' ' or self.ch == NEWLINE or self.ch == CARRIAGE_RETURN) {
            self.read_char();
        }
    }

    pub fn nextToken(self: *Self) Token {
        self.skipWhiteSpace();

        var tok: Token = undefined;
        switch (self.ch) {
            '=' => {
                if (self.peek_char() == '=') {
                    tok = Token{ .tokenType = Token.TokenType.EQ, .literal = "==" };
                    self.read_char();
                } else {
                    tok = Token{ .tokenType = Token.TokenType.ASSIGN, .literal = "=" };
                }
            },
            ';' => {
                tok = Token{ .tokenType = Token.TokenType.SEMICOLON, .literal = ";" };
            },
            '(' => {
                tok = Token{ .tokenType = Token.TokenType.LPAREN, .literal = "(" };
            },
            ')' => {
                tok = Token{ .tokenType = Token.TokenType.RPAREN, .literal = ")" };
            },
            ',' => {
                tok = Token{ .tokenType = Token.TokenType.COMMA, .literal = "," };
            },
            '+' => {
                tok = Token{ .tokenType = Token.TokenType.PLUS, .literal = "+" };
            },
            '-' => {
                tok = Token{ .tokenType = Token.TokenType.MINUS, .literal = "-" };
            },
            '/' => {
                tok = Token{ .tokenType = Token.TokenType.SLASH, .literal = "/" };
            },
            '*' => {
                tok = Token{ .tokenType = Token.TokenType.ASTERISK, .literal = "*" };
            },
            '!' => {
                if (self.peek_char() == '=') {
                    tok = Token{ .tokenType = Token.TokenType.NOT_EQ, .literal = "!=" };
                    self.read_char();
                } else {
                    tok = Token{ .tokenType = Token.TokenType.BANG, .literal = "!" };
                }
            },
            '{' => {
                tok = Token{ .tokenType = Token.TokenType.LBRACE, .literal = "{" };
            },
            '}' => {
                tok = Token{ .tokenType = Token.TokenType.RBRACE, .literal = "}" };
            },
            '<' => {
                if (self.peek_char() == '=') {
                    tok = Token{ .tokenType = Token.TokenType.LT_EQ, .literal = "<=" };
                    self.read_char();
                } else {
                    tok = Token{ .tokenType = Token.TokenType.LT, .literal = "<" };
                }
            },
            '>' => {
                if (self.peek_char() == '=') {
                    tok = Token{ .tokenType = Token.TokenType.GT_EQ, .literal = ">=" };
                    self.read_char();
                } else {
                    tok = Token{ .tokenType = Token.TokenType.GT, .literal = ">" };
                }
            },
            0 => {
                tok = Token{ .tokenType = Token.TokenType.EOF, .literal = "" };
            },

            else => {
                if (isLetter(self.ch)) {
                    const keyword = self.readIdentifier();
                    const toktype = lookupIdent(keyword);
                    tok = Token{
                        .tokenType = toktype,
                        .literal = keyword,
                    };
                    return tok;
                } else if (isDigit(self.ch)) {
                    const num = self.readNumber();
                    tok = Token{
                        .tokenType = Token.TokenType.INT,
                        .literal = num,
                    };
                    return tok;
                } else {
                    tok = Token{
                        .tokenType = Token.TokenType.ILLEGAL,
                        .literal = &[_]u8{self.ch},
                    };
                }
            },
        }

        self.read_char();
        return tok;
    }

    pub fn readIdentifier(self: *Self) []const u8 {
        const position = self.position;
        while (isLetter(self.ch)) : (self.read_char()) {}
        return self.input[position..self.position];
    }

    pub fn readNumber(self: *Self) []const u8 {
        const position = self.position;
        while (isDigit(self.ch)) : (self.read_char()) {}
        return self.input[position..self.position];
    }
};

pub const Token = struct {
    pub const TokenType = enum {
        ILLEGAL,
        EOF,
        IDENT,
        INT,
        ASSIGN,

        PLUS,
        MINUS,
        BANG,
        SLASH,

        EQ,
        NOT_EQ,
        LT_EQ,
        GT_EQ,

        ASTERISK,
        COMMA,
        SEMICOLON,

        LPAREN,
        RPAREN,
        LBRACE,
        RBRACE,

        FUNCTION,
        LET,

        TRUE,
        FALSE,

        LT,
        GT,

        IF,
        ELSE,
        RETURN,
    };

    tokenType: TokenType,
    literal: []const u8,
};

test "test next token" {
    const expect = struct {
        expectedType: Token.TokenType,
        expectedLiteral: []const u8,
    };
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\if (5 < 10) {
        \\return true;
        \\} else {
        \\return false;
        \\}
        \\10 == 10;
        \\10 != 9;
    ;
    const tests = [_]expect{
        expect{ .expectedType = Token.TokenType.LET, .expectedLiteral = "let" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "five" },
        expect{ .expectedType = Token.TokenType.ASSIGN, .expectedLiteral = "=" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "5" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.LET, .expectedLiteral = "let" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "ten" },
        expect{ .expectedType = Token.TokenType.ASSIGN, .expectedLiteral = "=" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "10" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.LET, .expectedLiteral = "let" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "add" },
        expect{ .expectedType = Token.TokenType.ASSIGN, .expectedLiteral = "=" },
        expect{ .expectedType = Token.TokenType.FUNCTION, .expectedLiteral = "fn" },
        expect{ .expectedType = Token.TokenType.LPAREN, .expectedLiteral = "(" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "x" },
        expect{ .expectedType = Token.TokenType.COMMA, .expectedLiteral = "," },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "y" },
        expect{ .expectedType = Token.TokenType.RPAREN, .expectedLiteral = ")" },
        expect{ .expectedType = Token.TokenType.LBRACE, .expectedLiteral = "{" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "x" },
        expect{ .expectedType = Token.TokenType.PLUS, .expectedLiteral = "+" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "y" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.RBRACE, .expectedLiteral = "}" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.LET, .expectedLiteral = "let" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "result" },
        expect{ .expectedType = Token.TokenType.ASSIGN, .expectedLiteral = "=" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "add" },
        expect{ .expectedType = Token.TokenType.LPAREN, .expectedLiteral = "(" },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "five" },
        expect{ .expectedType = Token.TokenType.COMMA, .expectedLiteral = "," },
        expect{ .expectedType = Token.TokenType.IDENT, .expectedLiteral = "ten" },
        expect{ .expectedType = Token.TokenType.RPAREN, .expectedLiteral = ")" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.BANG, .expectedLiteral = "!" },
        expect{ .expectedType = Token.TokenType.MINUS, .expectedLiteral = "-" },
        expect{ .expectedType = Token.TokenType.SLASH, .expectedLiteral = "/" },
        expect{ .expectedType = Token.TokenType.ASTERISK, .expectedLiteral = "*" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "5" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "5" },
        expect{ .expectedType = Token.TokenType.LT, .expectedLiteral = "<" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "10" },
        expect{ .expectedType = Token.TokenType.GT, .expectedLiteral = ">" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "5" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.IF, .expectedLiteral = "if" },
        expect{ .expectedType = Token.TokenType.LPAREN, .expectedLiteral = "(" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "5" },
        expect{ .expectedType = Token.TokenType.LT, .expectedLiteral = "<" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "10" },
        expect{ .expectedType = Token.TokenType.RPAREN, .expectedLiteral = ")" },
        expect{ .expectedType = Token.TokenType.LBRACE, .expectedLiteral = "{" },
        expect{ .expectedType = Token.TokenType.RETURN, .expectedLiteral = "return" },
        expect{ .expectedType = Token.TokenType.TRUE, .expectedLiteral = "true" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.RBRACE, .expectedLiteral = "}" },
        expect{ .expectedType = Token.TokenType.ELSE, .expectedLiteral = "else" },
        expect{ .expectedType = Token.TokenType.LBRACE, .expectedLiteral = "{" },
        expect{ .expectedType = Token.TokenType.RETURN, .expectedLiteral = "return" },
        expect{ .expectedType = Token.TokenType.FALSE, .expectedLiteral = "false" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.RBRACE, .expectedLiteral = "}" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "10" },
        expect{ .expectedType = Token.TokenType.EQ, .expectedLiteral = "==" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "10" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "10" },
        expect{ .expectedType = Token.TokenType.NOT_EQ, .expectedLiteral = "!=" },
        expect{ .expectedType = Token.TokenType.INT, .expectedLiteral = "9" },
        expect{ .expectedType = Token.TokenType.SEMICOLON, .expectedLiteral = ";" },
        expect{ .expectedType = Token.TokenType.EOF, .expectedLiteral = "" },
    };

    var l = Lexer.init(input);

    for (tests) |t| {
        const tok = l.nextToken();
        try std.testing.expectEqual(t.expectedType, tok.tokenType);
        try std.testing.expectEqualStrings(t.expectedLiteral, tok.literal);
    }
}
