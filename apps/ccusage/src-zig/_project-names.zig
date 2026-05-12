const std = @import("std");

pub fn formatProjectName(project: []const u8, aliases: ?[]const u8, buf: []u8) []const u8 {
    if (aliasForProject(project, aliases)) |alias| return alias;
    if (project.len == 0 or std.mem.eql(u8, project, "unknown")) return "Unknown Project";
    if (std.mem.indexOfScalar(u8, project, '/') != null) {
        return lastPathComponent(project);
    }
    if (std.mem.startsWith(u8, project, "-")) {
        var last = project;
        var it = std.mem.splitScalar(u8, project, '-');
        while (it.next()) |part| {
            if (part.len > 0) last = part;
        }
        if (last.len > 0 and last.len <= buf.len) return last;
    }
    return project;
}

pub fn projectHeaderLabel(project: []const u8, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "Project: {s}", .{project}) catch "Project:";
}

fn aliasForProject(project: []const u8, aliases: ?[]const u8) ?[]const u8 {
    const raw_aliases = aliases orelse return null;
    var pairs = std.mem.splitScalar(u8, raw_aliases, ',');
    while (pairs.next()) |raw_pair| {
        const pair = std.mem.trim(u8, raw_pair, " \t\r\n");
        const eq = std.mem.indexOfScalar(u8, pair, '=') orelse continue;
        const key = std.mem.trim(u8, pair[0..eq], " \t\r\n");
        const value = std.mem.trim(u8, pair[eq + 1 ..], " \t\r\n");
        if (key.len > 0 and value.len > 0 and std.mem.eql(u8, key, project)) return value;
    }
    return null;
}

fn lastPathComponent(path: []const u8) []const u8 {
    var it = std.mem.splitAny(u8, path, "/\\");
    var last = path;
    while (it.next()) |part| {
        if (part.len > 0) last = part;
    }
    return last;
}

test "project name aliases match daily table behavior" {
    var buf: [128]u8 = undefined;
    try std.testing.expectEqualStrings("Project A", formatProjectName("project-a", "project-a=Project A", &buf));
    try std.testing.expectEqualStrings("Unknown Project", formatProjectName("unknown", null, &buf));
    try std.testing.expectEqualStrings("ccusage", formatProjectName("/Users/example/ccusage", null, &buf));
    try std.testing.expectEqualStrings("ccusage", formatProjectName("-Users-example-ccusage", null, &buf));
}
