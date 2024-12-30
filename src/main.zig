const std = @import("std");
const eql = std.mem.eql;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;
var buffer: [1024 * 1024]u8 = undefined;

pub fn main() !void {}

/// Returns names of files with content including `in` strings excluding `ex` strings.
fn search(in: []const []const u8, ex: []const []const u8) ![]const []const u8 {
    _ = ex;
    const cwd =
        try std.fs.cwd().openDir(
        ".",
        .{ .iterate = true },
    );
    var proper_file_names = std.ArrayList([]const u8).init(allocator);
    var dir_walker = try cwd.walk(allocator);
    while (try dir_walker.next()) |entry| {
        if (entry.kind != .file) {
            continue;
        }
        const file = try cwd.openFile(entry.path, .{});
        const size = try file.readAll(&buffer);
        var is_proper_file = true;
        for (in) |str| {
            if (!std.mem.containsAtLeast(u8, buffer[0..size], 1, str)) {
                is_proper_file = false;
                break;
            }
        }
        if (is_proper_file) {
            try proper_file_names.append(try allocator.dupe(u8, entry.path));
        }
    }
    return proper_file_names.items;
}

test "search for files with a string 'we'" {
    try (try std.fs.cwd().openDir("test", .{})).setAsCwd();
    const filenames = try search(&.{"we"}, &.{});
    try expectEqual(2, filenames.len);
    try expect(eql(u8, filenames[0], "second") and eql(u8, filenames[1], "third") or
        eql(u8, filenames[0], "third") and eql(u8, filenames[1], "second"));
}
