const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Token = @import("lexer.zig").Token;

pub const LetStatement = struct {
    token: Token,
    name: Identifier,
    value: ?Expression,

    pub fn statementNode(self: LetStatement) void {
        _ = self;
    }

    pub fn tokenLiteral(self: LetStatement) []const u8 {
        return self.token.literal;
    }
};

pub const Identifier = struct {
    token: Token,
    value: []const u8,

    pub fn expressionNode(self: Identifier) void {
        _ = self;
    }

    pub fn tokenLiteral(self: Identifier) []const u8 {
        return self.token.literal;
    }
};

pub const Program = struct {
    statements: []Statement,

    pub fn tokenLiteral(self: *Program) []const u8 {
        if (self.statements.len > 0) {
            return self.statements[0].tokenLiteral();
        } else {
            return "";
        }
    }
};

pub const Node = union(enum) {
    statement: Statement,
    expression: Expression,

    pub fn tokenLiteral(self: *Node) []const u8 {
        switch (self.*) {
            inline else => |*it| return it.tokenLiteral(),
        }
    }
};

pub const Statement = union(enum) {
    letStatement: LetStatement,

    pub fn tokenLiteral(self: *Node) []const u8 {
        switch (self.*) {
            inline else => |*it| return it.tokenLiteral(),
        }
    }

    pub fn statementNode(self: *Statement) void {
        switch (self.*) {
            inline else => |*it| return it.statementNode(),
        }
    }
};

pub const Expression = union(enum) {
    Identifier: Identifier,

    pub fn tokenLiteral(self: *Node) []const u8 {
        switch (self.*) {
            inline else => |*it| return it.tokenLiteral(),
        }
    }

    pub fn expressionNode(self: *Expression) void {
        switch (self.*) {
            inline else => |it| return it.expressionNode(),
        }
    }
};
