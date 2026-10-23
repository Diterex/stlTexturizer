# BumpMesh Offline (unofficial build)

**This is an unofficial offline build of [BumpMesh](https://bumpmesh.com), made by Stefan Hermann of [CNC Kitchen](https://www.youtube.com/@CNCKitchen). All of the real work here is his.** The original source code is at <https://github.com/CNCKitchen/stlTexturizer>. This repository is a fork of it and is not affiliated with, endorsed by, or supported by CNC Kitchen. If you want BumpMesh, use the official site. This build exists only so BumpMesh can run on a PC with no internet connection.

Based on BumpMesh v1.4.3 (upstream commit `a6d6d6e`). Modified 2026-10-23 by Diterex. The original README is kept as [README-upstream.md](README-upstream.md).

## What was changed from upstream

1. **Web libraries ship locally.** Three.js 0.170.0 and fflate 0.8.2 were loaded from a public CDN. Unmodified copies are now in `vendor/`, and the page and the background workers point at them.
2. **STEP/STP import is stubbed out.** Upstream downloads a further library when you import a STEP file, which cannot work offline. Choosing a STEP file now reports that it is not included. STL, OBJ and 3MF still work.
3. **The Imprint and Privacy popup was replaced** by an "About this unofficial build" notice. The original names Stefan Hermann as the operator of the official website, which is not true of this build. His original text is untouched in upstream.
4. **The build is marked unofficial** in the header and in the source-code links.
5. **`CNAME` was removed** so that turning on GitHub Pages here cannot claim bumpmesh.com.
6. **A small local server and launcher were added (not upstream code).** `offline/server/main.zig` is a static file server that listens on 127.0.0.1 only. `START BumpMesh.bat` starts it and opens your browser.

Every change is a separate commit on the `offline-build` branch, so `git diff a6d6d6e offline-build` shows exactly what differs from upstream. The full list is in [offline/LICENCES-AND-CREDITS.txt](offline/LICENCES-AND-CREDITS.txt).

## Download and run

Download `BumpMesh-Offline.zip` from the Releases page, unzip it, and double-click `START BumpMesh.bat`. Full instructions are inside the zip in `README.txt`. To build the zip yourself from this branch, run `offline/make-offline-zip.ps1` (it needs `bumpmesh-server.exe`, see below).

**About `bumpmesh-server.exe`.** It is compiled from `offline/server/main.zig` with the [Zig](https://ziglang.org) compiler. The exe is not stored in git, only attached to releases with its SHA-256 checksum. The Zig version used for the first build was not recorded, so a third party cannot yet reproduce the checksum from source. Treat the exe as unverified and prefer to build it yourself. You do not need it to run BumpMesh: any static web server that serves this folder works.

## Licences

- **BumpMesh** (everything except `vendor/`, `offline/` and the textures' own terms): Copyright (c) 2026 CNCKitchen (Stefan Hermann) and contributors, **AGPL-3.0-only**. See [LICENSE](LICENSE). Unmodified.
- **Three.js 0.170.0** and **fflate 0.8.2** in `vendor/`: MIT, with their licence files.
- **Textures** (`textures/`): mixed. 29 are based on Hero Patterns by Steve Schoger (CC BY 4.0, attribution required, converted to height maps), 11 are CC0 from ambientCG and Poly Haven, 6 were made with Filter Forge, and the rest ship with BumpMesh.
- **`offline/` additions** (server, launcher, scripts): MIT, Copyright (c) 2026 Diterex. See [offline/LICENSE-additions.txt](offline/LICENSE-additions.txt).

Because BumpMesh is AGPL-3.0, anyone who passes this software on, or lets other people use it over a network, must offer them the complete source under the same licence.
