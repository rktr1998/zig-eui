const Eui48 = @This();

const std = @import("std");
const testing = std.testing;
const Io = std.Io;
const Writer = std.Io.Writer;

pub const Error = error{
    InvalidLiteral,
};

bytes: [6]u8,

/// Format MAC address as "XX-XX-XX-XX-XX-XX".
pub fn format(self: *const Eui48, writer: *Writer) Writer.Error!void {
    try writer.print(
        "{X:02}-{X:02}-{X:02}-{X:02}-{X:02}-{X:02}",
        .{ self.bytes[0], self.bytes[1], self.bytes[2], self.bytes[3], self.bytes[4], self.bytes[5] },
    );
    try writer.flush();
}

test "format" {
    const eui48: Eui48 = .{
        .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB },
    };
    const formatted = std.fmt.comptimePrint("{f}", .{eui48});
    try std.testing.expect(std.mem.eql(u8, formatted, "01-23-45-67-89-AB"));
}

/// Accepts "-" or ":" as separators (e.g. 01-23-45-AB-CD-EF).
pub fn fromLiteral(literal: []const u8) Error!Eui48 {
    if (literal.len != 17) return Error.InvalidLiteral;

    // Expect either ':' or '-'
    const sep: u8 = literal[2];
    if (sep != ':' and sep != '-') return Error.InvalidLiteral;

    // Ensure all separators are the same
    var i: usize = 2;
    while (i < literal.len) : (i += 3) {
        if (literal[i] != sep) return Error.InvalidLiteral;
    }

    var iter = std.mem.tokenizeSequence(u8, literal, &.{sep});
    var bytes: [6]u8 = undefined;
    var idx: usize = 0;

    while (iter.next()) |mac_part| {
        if (idx >= 6) return Error.InvalidLiteral;
        bytes[idx] = std.fmt.parseInt(u8, mac_part, 16) catch return Error.InvalidLiteral;
        idx += 1;
    }

    if (idx != 6) return Error.InvalidLiteral;

    return Eui48{
        .bytes = bytes,
    };
}

test "fromLiteral" {
    try testing.expectEqual(try Eui48.fromLiteral("01:23:45:67:89:ab"), Eui48{ .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab } });
    try testing.expectEqual(try Eui48.fromLiteral("01:23:45:67:89:Ab"), Eui48{ .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab } });
    try testing.expectEqual(try Eui48.fromLiteral("01:23:45:67:89:AB"), Eui48{ .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab } });
    try testing.expectEqual(try Eui48.fromLiteral("01-23-45-67-89-ab"), Eui48{ .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB } });
    try testing.expectEqual(try Eui48.fromLiteral("01-23-45-67-89-Ab"), Eui48{ .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB } });
    try testing.expectEqual(try Eui48.fromLiteral("01-23-45-67-89-AB"), Eui48{ .bytes = [6]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB } });

    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("0123456789AB")); // No separators
    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("01:23:45:67:89")); // Too short
    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("01:23:45:67:89:AB:CD")); // Too long
    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("01:23:45:67:89:GG")); // Invalid hex
    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("01-23:45-67:89:AB")); // Mixed separators
    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("01::23:45:67:89:AB")); // Extra colon
    try testing.expectError(Error.InvalidLiteral, Eui48.fromLiteral("")); // Empty string
}

/// Generates a random EUI-48 address.
pub fn random(io: Io) Eui48 {
    var bytes: [6]u8 = undefined;
    Io.random(io, &bytes);
    return Eui48{
        .bytes = bytes,
    };
}
