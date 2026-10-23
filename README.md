# BumpMesh Offline (unofficial build)

**This is an unofficial offline build of [BumpMesh](https://bumpmesh.com), made by Stefan Hermann of [CNC Kitchen](https://www.youtube.com/@CNCKitchen). All of the real work here is his.** The original source code is at <https://github.com/CNCKitchen/stlTexturizer>. This repository is a fork of it and is not affiliated with, endorsed by, or supported by CNC Kitchen. If you want BumpMesh, use the official site. This build exists only so BumpMesh can run on a PC with no internet connection.

Based on BumpMesh v1.4.3 (upstream commit `a6d6d6e`). Modified 2026-10-23 by Diterex. The original README is kept as [README-upstream.md](README-upstream.md).

## What was changed from upstream

1. **Web libraries ship locally.** Three.js 0.170.0, fflate 0.8.2 and the STEP reader meshStep 0.1.0 were loaded from a public CDN (jsDelivr). Unmodified copies are now in `vendor/`, and the page and the background workers point at them.
2. **STEP/STP import works offline.** The official page fetches the STEP reader at the moment you pick a STEP file, which an offline PC cannot do. This build includes the same release (see "STEP files" below). STL, OBJ, 3MF and STEP all open.
3. **The Imprint and Privacy popup was replaced** by an "About this unofficial build" notice. The original names Stefan Hermann as the operator of the official website, which is not true of this build. His original text is untouched in upstream.
4. **The build is marked unofficial** in the header and in the source-code links.
5. **`CNAME` was removed** so that turning on GitHub Pages here cannot claim bumpmesh.com.
6. **A small local server and launcher were added (not upstream code).** `offline/server/main.zig` is a static file server that listens on 127.0.0.1 only. `START BumpMesh.bat` starts it and opens your browser.

Every change is a separate commit on the `offline-build` branch, so `git diff a6d6d6e offline-build` shows exactly what differs from upstream. The full list is in [offline/LICENCES-AND-CREDITS.txt](offline/LICENCES-AND-CREDITS.txt).

## STEP files

In the official BumpMesh, opening a STEP or STP file loads a separate library called [meshStep](https://github.com/CNCKitchen/meshStep) (also by CNC Kitchen, AGPL-3.0, plain JavaScript with no dependencies and no WebAssembly) from a public CDN, at the moment you pick the file. This offline build ships an unmodified copy of the same release (meshstep 0.1.0, about 800 KB of runtime files in `vendor/meshstep/`) and loads it from there. The copy comes from the npm registry package, and its download matched npm's published SHA-512 and SHA-1 checksums. The only code change is the import address in `js/stepWorker.js`.

Tested 2026-10-23: a STEP part made in FreeCAD (30 x 20 x 10 mm block with a 8 mm hole) imported offline at the right size with no network requests.

## Download and run

Download `BumpMesh-Offline.zip` from the [Releases page](https://github.com/Diterex/stlTexturizer/releases), unzip it, and double-click `START BumpMesh.bat`. Each release lists the SHA-256 checksum of the zip and of the exe in `SHA256SUMS.txt`. Full instructions are inside the zip in `README.txt`. To build the zip yourself from this branch, run `offline/make-offline-zip.ps1` (it needs `bumpmesh-server.exe`, see below).

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
- **meshStep 0.1.0** in `vendor/meshstep/`: Copyright CNC Kitchen and contributors, AGPL-3.0-only, with its licence file. Unmodified.
- **Textures** (`textures/`): mixed. 29 are based on Hero Patterns by Steve Schoger (CC BY 4.0, attribution required, converted to height maps), 11 are CC0 from ambientCG and Poly Haven, 6 were made with Filter Forge, and the rest ship with BumpMesh.
- **`offline/` additions** (server, launcher, scripts): MIT, Copyright (c) 2026 Diterex. See [offline/LICENSE-additions.txt](offline/LICENSE-additions.txt).

Because BumpMesh is AGPL-3.0, anyone who passes this software on, or lets other people use it over a network, must offer them the complete source under the same licence.
