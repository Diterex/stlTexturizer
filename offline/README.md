# Offline copy of BumpMesh

This folder holds a small, optional way to build a copy of BumpMesh that runs on a PC with no internet connection, for example from a USB stick. It changes nothing in the app itself. The live site works exactly as before.

## What it does

`make-offline.mjs` builds a folder you can zip and hand to someone.

```
node offline/make-offline.mjs --out dist-offline --exe path/to/bumpmesh-server.exe
```

It does these steps.

1. Copies the app files from your checkout into `BumpMesh-Offline/app`.
2. Downloads three.js, fflate and meshStep at the exact versions BumpMesh uses, and checks every file against the SHA256 listed in `libs.json`. If one file does not match, it stops.
3. Changes the five CDN addresses in `index.html`, one in `js/threeCompat.js` and one in `js/stepWorker.js` so they point at the local copies. Each replacement must match exactly once. If a line changes upstream, the script stops and says which one.
4. Checks that no file in the app still mentions the CDN.
5. Adds the launcher `START BumpMesh.bat`, the server source and a short guide for the person who receives the folder.

The `--exe` part is optional. Without it the script tells you to build the server first.

## The small server

`server/main.zig` is a static file server written in Zig. It listens on 127.0.0.1 only, serves the `app` folder, and opens your browser. It refuses path parts that start or end with a dot, end with a space, contain reserved characters or are Windows device names such as CON and NUL. It also refuses requests whose Host header is not 127.0.0.1 or localhost.

Build it with Zig 0.14 or older. This was tested with 0.14.1.

```
zig build-exe offline/server/main.zig -O ReleaseSafe -target x86_64-windows-gnu
```

Zig writes a new random timestamp and debug ID into every build, so the file hash changes each time. `verify-exe.ps1` blanks those fields and prints a hash that stays the same for the same source, so two people can compare builds.

## Why STEP files work offline

The page normally loads meshStep from the CDN when you open a STEP file. This script downloads the same release (0.1.0) from the same CDN once, at build time, and the worker loads it from the `vendor` folder instead.

## Licence

Everything in this folder is under the same licence as the rest of the project, AGPL 3.0 only. The libraries the script downloads keep their own licences, and the script downloads their licence files too.
