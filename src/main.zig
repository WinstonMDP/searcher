const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

pub fn main() !void {}

/// Returns names of files with content including `in` strings excluding `ex` strings.
fn search(in: []const []const u8, ex: []const []const u8) ![]const []const u8 {
    _ = ex;
    return &.{};
}

test "search for files with a string 'we'" {
    try (try std.fs.cwd().openDir("test", .{})).setAsCwd();
    const filenames = try search(&.{"we"}, &.{});
    try expectEqual(2, filenames.len);
    try expect(eql(u8, filenames[0], "second") and eql(u8, filenames[1], "third") or
        eql(u8, filenames[0], "third") and eql(u8, filenames[1], "second"));
}
