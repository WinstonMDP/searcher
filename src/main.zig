const std = @import("std");
const eql = std.mem.eql;
const containsAtLeast = std.mem.containsAtLeast;
const ArrayList = std.ArrayList;
const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;
const expect = std.testing.expect;
var buf: [1024 * 1024]u8 = undefined;
var allocator_buf: [128 * 1024 * 1024]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&allocator_buf);
const allocator = fba.allocator();

pub fn main() !void {
    var in = ArrayList([]const u8).init(allocator);
    var ex = ArrayList([]const u8).init(allocator);
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut();
    while (true) {
        var line = try stdin.readUntilDelimiter(&buf, '\n');
        if (eql(u8, line[0..3], "in ")) {
            try in.append(try allocator.dupe(u8, line[3..]));
            _ = try stdout.writeAll("ok\n");
        } else if (eql(u8, line[0..3], "ex ")) {
            try ex.append(try allocator.dupe(u8, line[3..]));
            _ = try stdout.writeAll("ok\n");
        } else if (eql(u8, line[0..4], "exit")) {
            break;
        } else {
            const cwd = try std.fs.cwd().realpath(".", &buf);
            const filenames = try search(cwd, in.items, ex.items);
            const stdout_writer = stdout.writer();
            for (filenames) |filename| {
                try stdout_writer.print("{s}\n", .{filename});
            }
        }
    }
}

/// Returns names of files with content including `in` strings excluding `ex` strings.
fn search(dir_path: []const u8, in: []const []const u8, ex: []const []const u8) ![]const []const u8 {
    if (in.len == 0) {
        return &.{};
    }
    const cwd =
        try std.fs.openDirAbsolute(
        dir_path,
        .{ .iterate = true },
    );
    var proper_file_names = ArrayList([]const u8).init(allocator);
    var dir_walker = try cwd.walk(allocator);
    while (try dir_walker.next()) |entry| {
        if (entry.kind != .file) {
            continue;
        }
        const file = try cwd.openFile(entry.path, .{});
        defer file.close();
        const size = try file.readAll(&buf);
        const heystack = buf[0..size];
        var is_proper_file = true;
        for (in) |str| {
            if (!containsAtLeast(u8, heystack, 1, str)) {
                is_proper_file = false;
                break;
            }
        }
        if (!is_proper_file) {
            continue;
        }
        for (ex) |str| {
            if (containsAtLeast(u8, heystack, 1, str)) {
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

const test_dir_path = "/home/WinstonMDPLinux/it/searcher/test";

test "search for files with a string 'we'" {
    const filenames = try search(test_dir_path, &.{"we"}, &.{});
    try expectEqual(2, filenames.len);
    try expect(eql(u8, filenames[0], "second") and eql(u8, filenames[1], "third") or
        eql(u8, filenames[0], "third") and eql(u8, filenames[1], "second"));
}

test "search for files with a string 'I' without 'not'" {
    const filenames = try search(test_dir_path, &.{"I"}, &.{"not"});
    try expectEqual(1, filenames.len);
    try expectEqualDeep("first", filenames[0]);
}

test "search with empty args" {
    const filenames = try search(test_dir_path, &.{}, &.{});
    try expectEqual(0, filenames.len);
}
