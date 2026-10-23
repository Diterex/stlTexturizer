# BumpMesh Offline (unofficial build)

**This is an unofficial offline build of [BumpMesh](https://bumpmesh.com), made by Stefan Hermann of [CNC Kitchen](https://www.youtube.com/@CNCKitchen). All of the real work here is his.** The original source code is at <https://github.com/CNCKitchen/stlTexturizer>. This repository is a fork of it and is not affiliated with, endorsed by, or supported by CNC Kitchen. If you want BumpMesh, use the official site. This build exists only so BumpMesh can run on a PC with no internet connection.

Based on BumpMesh v1.4.3 (upstream commit `a6d6d6e`). Modified 2026-10-23 by Diterex. The original README is kept as [README-upstream.md](README-upstream.md).

## What was changed from upstream

1. **Web libraries ship locally.** Three.js 0.170.0 and fflate 0.8.2 were loaded from a public CDN. Unmodified copies are now in `vendor/`, and the page and the background workers point at them.
2. **STEP/STP import is stubbed out.** Choosing a STEP file now shows a message that it is not included. STL, OBJ and 3MF still work. See "Why STEP files are not supported" below.
3. **The Imprint and Privacy popup was replaced** by an "About this unofficial build" notice. The original names Stefan Hermann as the operator of the official website, which is not true of this build. His original text is untouched in upstream.
4. **The build is marked unofficial** in the header and in the source-code links.
5. **`CNAME` was removed** so that turning on GitHub Pages here cannot claim bumpmesh.com.
6. **A small local server and launcher were added (not upstream code).** `offline/server/main.zig` is a static file server that listens on 127.0.0.1 only. `START BumpMesh.bat` starts it and opens your browser.

Every change is a separate commit on the `offline-build` branch, so `git diff a6d6d6e offline-build` shows exactly what differs from upstream. The full list is in [offline/LICENCES-AND-CREDITS.txt](offline/LICENCES-AND-CREDITS.txt).

## Why STEP files are not supported

In the official BumpMesh, opening a STEP or STP file loads a separate library called [meshStep](https://github.com/CNCKitchen/meshStep) (also by CNC Kitchen, licensed AGPL-3.0, plain JavaScript with no dependencies and no WebAssembly). The official page fetches it from a public CDN (jsDelivr) at the moment you pick the file. An offline PC cannot reach the CDN, and this build did not bundle a copy, so the STEP reader is replaced by a clear message instead of failing silently.

This is a limit of this build, not of BumpMesh. The library is small (roughly 2 MB) and has the same licence, so a future version of this build could include it. Until then, export your model as STL, OBJ or 3MF from your CAD program, or use the official site while online.

## Download and run

A ready-made `BumpMesh-Offline.zip` will be attached to a GitHub Release (none yet). Unzip it and double-click `START BumpMesh.bat`. Full instructions are inside the zip in `README.txt`. To build the zip yourself from this branch, run `offline/make-offline-zip.ps1` (it needs `bumpmesh-server.exe`, see below).

**About `bumpmesh-server.exe`.** It is compiled from `offline/server/main.zig` with the [Zig](https://ziglang.org) compiler. The exe is not stored in git, only attached to releases with its SHA-256 checksum. You do not need it to run BumpMesh: any static web server that serves this folder works, and you can build the exe yourself:

```
zig build-exe offline/server/main.zig -O ReleaseSafe -target x86_64-windows-gnu
```

Use Zig **0.14.1** (the source needs Zig 0.14 or older). Zig writes a new random timestamp and debug-file ID into every build, so the raw SHA-256 differs each time. `offline/verify-exe.ps1` blanks exactly those fields before hashing, so two builds of the same source give the same value. Checked on 2026-10-23:

- The exe from the original bundle and three rebuilds of its original source all give `7CA9AE7411F13A304495D0730CC6DFAD8E45098B73254B12C9F4974BC27203AC` (program code byte for byte identical). A build in a different optimisation mode gives a different value, so the check does tell builds apart.
- The current `offline/server/main.zig` adds stricter path checks (see below). Three fresh builds of it give `D819DA03068D85C92F8DFAEC926EA74AE0602F10BB02E0DAA4BD8A2261DD54C0`. That is the value to expect from the exe on the Releases page.

**Server hardening added in this build.** The server refuses any path part that starts or ends with a dot, ends with a space, contains `<>"|*?`, or is a Windows device name (CON, NUL, COM1 and so on). It also refuses requests whose Host header is not `127.0.0.1` or `localhost`. Tested live on 2026-10-23: normal files return 200; `..`, `.. `, `...`, encoded `..`, `CON` and `NUL.js` and a foreign Host header all return 403; nothing outside the `app` folder was readable.

## Licences

- **BumpMesh** (everything except `vendor/`, `offline/` and the textures' own terms): Copyright (c) 2026 CNCKitchen (Stefan Hermann) and contributors, **AGPL-3.0-only**. See [LICENSE](LICENSE). Unmodified.
- **Three.js 0.170.0** and **fflate 0.8.2** in `vendor/`: MIT, with their licence files.
- **Textures** (`textures/`): mixed. 29 are based on Hero Patterns by Steve Schoger (CC BY 4.0, attribution required, converted to height maps), 11 are CC0 from ambientCG and Poly Haven, 6 were made with Filter Forge, and the rest ship with BumpMesh.
- **`offline/` additions** (server, launcher, scripts): MIT, Copyright (c) 2026 Diterex. See [offline/LICENSE-additions.txt](offline/LICENSE-additions.txt).

Because BumpMesh is AGPL-3.0, anyone who passes this software on, or lets other people use it over a network, must offer them the complete source under the same licence.
