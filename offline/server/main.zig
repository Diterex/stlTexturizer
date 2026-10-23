// BumpMesh Offline — minimal localhost-only static file server.
// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Diterex. Written for the unofficial BumpMesh offline build; contains no BumpMesh code.
const std = @import("std");
const builtin = @import("builtin");

const FIRST_PORT: u16 = 8731;
const LAST_PORT: u16 = 8745;

var g_root: []const u8 = ".";

fn mimeFor(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path);
    const map = [_]struct { e: []const u8, m: []const u8 }{
        .{ .e = ".html", .m = "text/html; charset=utf-8" },
        .{ .e = ".htm", .m = "text/html; charset=utf-8" },
        .{ .e = ".js", .m = "text/javascript; charset=utf-8" },
        .{ .e = ".mjs", .m = "text/javascript; charset=utf-8" },
        .{ .e = ".css", .m = "text/css; charset=utf-8" },
        .{ .e = ".json", .m = "application/json; charset=utf-8" },
        .{ .e = ".map", .m = "application/json; charset=utf-8" },
        .{ .e = ".svg", .m = "image/svg+xml" },
        .{ .e = ".png", .m = "image/png" },
        .{ .e = ".webp", .m = "image/webp" },
        .{ .e = ".jpg", .m = "image/jpeg" },
        .{ .e = ".jpeg", .m = "image/jpeg" },
        .{ .e = ".gif", .m = "image/gif" },
        .{ .e = ".ico", .m = "image/x-icon" },
        .{ .e = ".wasm", .m = "application/wasm" },
        .{ .e = ".txt", .m = "text/plain; charset=utf-8" },
        .{ .e = ".md", .m = "text/plain; charset=utf-8" },
        .{ .e = ".woff2", .m = "font/woff2" },
        .{ .e = ".woff", .m = "font/woff" },
        .{ .e = ".ttf", .m = "font/ttf" },
        .{ .e = ".stl", .m = "model/stl" },
        .{ .e = ".obj", .m = "text/plain; charset=utf-8" },
        .{ .e = ".3mf", .m = "application/vnd.ms-package.3dmanufacturing-3dmodel+xml" },
        .{ .e = ".zip", .m = "application/zip" },
        .{ .e = ".xml", .m = "application/xml" },
    };
    for (map) |kv| {
        if (std.ascii.eqlIgnoreCase(ext, kv.e)) return kv.m;
    }
    return "application/octet-stream";
}

fn sendSimple(stream: std.net.Stream, status: []const u8, body: []const u8) void {
    var buf: [512]u8 = undefined;
    const head = std.fmt.bufPrint(&buf,
        "HTTP/1.1 {s}\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n",
        .{ status, body.len }) catch return;
    stream.writeAll(head) catch return;
    stream.writeAll(body) catch return;
}

fn percentDecode(out: []u8, in: []const u8) []u8 {
    var i: usize = 0;
    var j: usize = 0;
    while (i < in.len and j < out.len) {
        if (in[i] == '%' and i + 2 < in.len) {
            const hi = std.fmt.charToDigit(in[i + 1], 16) catch {
                out[j] = in[i];
                i += 1;
                j += 1;
                continue;
            };
            const lo = std.fmt.charToDigit(in[i + 2], 16) catch {
                out[j] = in[i];
                i += 1;
                j += 1;
                continue;
            };
            out[j] = hi * 16 + lo;
            i += 3;
            j += 1;
        } else {
            out[j] = in[i];
            i += 1;
            j += 1;
        }
    }
    return out[0..j];
}

fn handle(conn: std.net.Server.Connection) void {
    defer conn.stream.close();

    var req: [8192]u8 = undefined;
    var n: usize = 0;
    // Read until end of headers.
    while (n < req.len) {
        const got = conn.stream.read(req[n..]) catch return;
        if (got == 0) break;
        n += got;
        if (std.mem.indexOf(u8, req[0..n], "\r\n\r\n") != null) break;
    }
    if (n == 0) return;

    const line_end = std.mem.indexOfAny(u8, req[0..n], "\r\n") orelse return;
    const line = req[0..line_end];
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    const method = it.next() orelse return;
    const raw_target = it.next() orelse return;

    const is_head = std.mem.eql(u8, method, "HEAD");
    if (!std.mem.eql(u8, method, "GET") and !is_head) {
        sendSimple(conn.stream, "405 Method Not Allowed", "Only GET and HEAD are supported.\n");
        return;
    }

    // Strip query/fragment.
    var target = raw_target;
    if (std.mem.indexOfAny(u8, target, "?#")) |q| target = target[0..q];

    var dec_buf: [4096]u8 = undefined;
    var rel: []const u8 = percentDecode(&dec_buf, target);
    if (rel.len == 0 or rel[0] != '/') {
        sendSimple(conn.stream, "400 Bad Request", "Bad request target.\n");
        return;
    }
    rel = rel[1..];
    if (rel.len == 0) rel = "index.html";

    // Reject traversal, backslashes, NULs, drive letters.
    if (std.mem.indexOfScalar(u8, rel, 0) != null or
        std.mem.indexOfScalar(u8, rel, '\\') != null or
        std.mem.indexOfScalar(u8, rel, ':') != null)
    {
        sendSimple(conn.stream, "400 Bad Request", "Bad path.\n");
        return;
    }
    var seg_it = std.mem.splitScalar(u8, rel, '/');
    while (seg_it.next()) |seg| {
        if (std.mem.eql(u8, seg, "..")) {
            sendSimple(conn.stream, "403 Forbidden", "Forbidden.\n");
            return;
        }
    }

    var path_buf: [4096]u8 = undefined;
    var full = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ g_root, rel }) catch {
        sendSimple(conn.stream, "414 URI Too Long", "Path too long.\n");
        return;
    };

    var file = std.fs.cwd().openFile(full, .{}) catch {
        // Directory request -> try index.html inside it.
        var alt_buf: [4096]u8 = undefined;
        const alt = std.fmt.bufPrint(&alt_buf, "{s}/{s}/index.html", .{ g_root, rel }) catch {
            sendSimple(conn.stream, "404 Not Found", "Not found.\n");
            return;
        };
        const f2 = std.fs.cwd().openFile(alt, .{}) catch {
            sendSimple(conn.stream, "404 Not Found", "Not found.\n");
            return;
        };
        full = alt;
        serve(conn.stream, f2, full, is_head);
        return;
    };
    const st = file.stat() catch {
        file.close();
        sendSimple(conn.stream, "500 Internal Server Error", "Stat failed.\n");
        return;
    };
    if (st.kind == .directory) {
        file.close();
        var alt_buf: [4096]u8 = undefined;
        const alt = std.fmt.bufPrint(&alt_buf, "{s}/{s}/index.html", .{ g_root, rel }) catch {
            sendSimple(conn.stream, "404 Not Found", "Not found.\n");
            return;
        };
        const f2 = std.fs.cwd().openFile(alt, .{}) catch {
            sendSimple(conn.stream, "404 Not Found", "Not found.\n");
            return;
        };
        serve(conn.stream, f2, alt, is_head);
        return;
    }
    serve(conn.stream, file, full, is_head);
}

fn serve(stream: std.net.Stream, file: std.fs.File, path: []const u8, is_head: bool) void {
    defer file.close();
    const st = file.stat() catch {
        sendSimple(stream, "500 Internal Server Error", "Stat failed.\n");
        return;
    };
    var head_buf: [1024]u8 = undefined;
    const head = std.fmt.bufPrint(&head_buf,
        "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nCache-Control: no-cache\r\nCross-Origin-Opener-Policy: same-origin\r\nConnection: close\r\n\r\n",
        .{ mimeFor(path), st.size }) catch return;
    stream.writeAll(head) catch return;
    if (is_head) return;

    var buf: [64 * 1024]u8 = undefined;
    while (true) {
        const got = file.read(&buf) catch return;
        if (got == 0) break;
        stream.writeAll(buf[0..got]) catch return;
    }
}

fn openBrowser(alloc: std.mem.Allocator, port: u16) void {
    const url = std.fmt.allocPrint(alloc, "http://127.0.0.1:{d}/", .{port}) catch return;
    defer alloc.free(url);
    const argv: []const []const u8 = switch (builtin.os.tag) {
        .windows => &[_][]const u8{ "cmd", "/c", "start", "", url },
        .macos => &[_][]const u8{ "open", url },
        else => &[_][]const u8{ "xdg-open", url },
    };
    var child = std.process.Child.init(argv, alloc);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;
    _ = child.spawn() catch return;
    _ = child.wait() catch return;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    // Web root: <dir of this executable>/app  (or ./app, or . as last resort)
    const exe_dir = std.fs.selfExeDirPathAlloc(alloc) catch try alloc.dupe(u8, ".");
    const candidate = try std.fmt.allocPrint(alloc, "{s}/app", .{exe_dir});
    var root = candidate;
    if (std.fs.cwd().access(candidate, .{})) |_| {} else |_| {
        if (std.fs.cwd().access("app", .{})) |_| {
            root = try alloc.dupe(u8, "app");
        } else |_| {
            root = exe_dir;
        }
    }
    // Sanity: index.html must exist under root.
    {
        const idx = try std.fmt.allocPrint(alloc, "{s}/index.html", .{root});
        std.fs.cwd().access(idx, .{}) catch {
            try stdout.print(
                \\
                \\  PROBLEM: BumpMesh's files were not found.
                \\
                \\  This program expects a folder named "app" sitting next to it.
                \\  Make sure you extracted the whole BumpMesh-Offline folder and
                \\  did not move this program out of it.
                \\
                \\  Looked in: {s}
                \\
                \\  Press Ctrl+C or close this window.
                \\
            , .{root});
            std.time.sleep(60 * std.time.ns_per_s);
            return error.AppFolderMissing;
        };
    }
    g_root = root;

    var server: std.net.Server = undefined;
    var port: u16 = FIRST_PORT;
    var bound = false;
    while (port <= LAST_PORT) : (port += 1) {
        const addr = std.net.Address.parseIp4("127.0.0.1", port) catch unreachable;
        server = addr.listen(.{}) catch continue;
        bound = true;
        break;
    }
    if (!bound) {
        try stdout.print(
            \\
            \\  PROBLEM: could not start. Ports {d} to {d} are all in use.
            \\  Restarting the PC usually clears this.
            \\
        , .{ FIRST_PORT, LAST_PORT });
        std.time.sleep(60 * std.time.ns_per_s);
        return error.NoFreePort;
    }
    defer server.deinit();

    try stdout.print(
        \\
        \\  ======================================================
        \\    BumpMesh is running.  Leave this window OPEN.
        \\
        \\    Address:  http://127.0.0.1:{d}/
        \\
        \\    TO STOP:  close this window.
        \\  ======================================================
        \\
        \\  (This serves files only to this PC. Nothing is sent
        \\   to the internet and nothing is downloaded.)
        \\
    , .{port});

    openBrowser(alloc, port);

    while (true) {
        const conn = server.accept() catch continue;
        const t = std.Thread.spawn(.{}, handle, .{conn}) catch {
            handle(conn);
            continue;
        };
        t.detach();
    }
}
