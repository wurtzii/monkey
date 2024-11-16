const std = @import("std");

pub fn isLetter(char: u8) bool {
    return ('a' <= char and char <= 'z') or ('A' <= char and char <= 'Z') or (char == '_');
}

pub fn isDigit(char: u8) bool {
    return ('0' <= char and char <= '9');
}

test "123456789 are numbers" {
    const nums = "0123456789";
    for (nums) |n| {
        try std.testing.expect(isDigit(n));
    }
}

test "not numbers" {
    const nums = "\\asfqwjobpaa";
    for (nums) |n| {
        try std.testing.expect(!isDigit(n));
    }
}

test "abcd are all letters" {
    const abcd: []const u8 = "abcd";
    for (abcd) |l| {
        try std.testing.expect(isLetter(l));
    }
}

test ";' are not letters" {
    const symbols = ";'";
    for (symbols) |s| {
        try std.testing.expect(!isLetter(s));
    }
}
