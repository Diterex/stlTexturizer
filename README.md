# BumpMesh Offline (unofficial build)

**This is an unofficial offline build of [BumpMesh](https://bumpmesh.com), made by Stefan Hermann of [CNC Kitchen](https://www.youtube.com/@CNCKitchen). All of the real work here is his.** The original source code is at [github.com/CNCKitchen/stlTexturizer](https://github.com/CNCKitchen/stlTexturizer). This repository is a fork of it. It is not affiliated with, endorsed by, or supported by CNC Kitchen. If you want BumpMesh, use the official site. This build exists only so BumpMesh can run on a PC with no internet connection.

It is based on BumpMesh version 1.4.3 (upstream commit `a6d6d6e`) and was changed on October 23, 2026 by Diterex. The original README is kept as [README-upstream.md](README-upstream.md).

## What was changed from the original

1. **Web libraries ship locally.** Three.js 0.170.0, fflate 0.8.2 and the STEP reader meshStep 0.1.0 used to load from a public CDN called jsDelivr. Unmodified copies are now in `vendor/`, and the page and the background workers point at them.
2. **STEP files work offline.** The official page fetches the STEP reader at the moment you pick a STEP file, which an offline PC cannot do. This build includes the same release (see the STEP files section below). STL, OBJ, 3MF and STEP files all open.
3. **The Imprint and Privacy popup was replaced** by an About this unofficial build notice. The original names Stefan Hermann as the operator of the official website, and that is not true of this build. His original text is untouched in his own repository.
4. **The build is marked unofficial** in the page title, the header and the source code links.
5. **The `CNAME` file was removed**, so turning on GitHub Pages here cannot claim bumpmesh.com.
6. **A small local server and launcher were added.** They are not part of the original. `offline/server/main.zig` is a file server that listens on 127.0.0.1 only. `START BumpMesh.bat` starts it and opens your browser.

Every change is a separate commit on the `offline-build` branch, so `git diff a6d6d6e offline-build` shows exactly what differs from the original. The full list is in [offline/LICENCES-AND-CREDITS.txt](offline/LICENCES-AND-CREDITS.txt).

## STEP files

In the official BumpMesh, opening a STEP file loads a separate library called [meshStep](https://github.com/CNCKitchen/meshStep) from a public CDN at the moment you pick the file. It is also by CNC Kitchen, it is plain JavaScript, and it has no dependencies and no WebAssembly. This offline build ships an unmodified copy of the same release (meshStep 0.1.0, about 800 KB of runtime files in `vendor/meshstep/`) and loads it from there. The copy comes from the npm registry package, and the download matched the SHA512 and SHA1 checksums that npm publishes. The only code change is the import address in `js/stepWorker.js`.

Tested on October 23, 2026. A STEP part made in FreeCAD, a 30 by 20 by 10 mm block with an 8 mm hole, imported offline at the right size with no network requests.

## Download and run

Download `BumpMesh-Offline.zip` from the [Releases page](https://github.com/Diterex/stlTexturizer/releases) and unzip it. Then double click `START BumpMesh.bat`. Each release lists the SHA256 checksum of the zip and of the exe in `SHA256SUMS.txt`. Full instructions are inside the zip in `README.txt`. To build the zip yourself from this branch, run `offline/make-offline-zip.ps1`. It needs `bumpmesh-server.exe`, which is explained next.

**About `bumpmesh-server.exe`.** It is built from `offline/server/main.zig` with the [Zig](https://ziglang.org) compiler. The exe is not stored in git. It is attached to releases together with its checksum. You do not need it to run BumpMesh, because any simple web server that serves this folder works. You can also build the exe yourself.

```
zig build-exe offline/server/main.zig -O ReleaseSafe -target x86_64-windows-gnu
```

Use Zig version 0.14.1. The source needs Zig 0.14 or older. Zig writes a new random timestamp and debug file ID into every build, so the raw SHA256 differs each time. The script `offline/verify-exe.ps1` blanks exactly those fields before hashing, so two builds of the same source give the same value. Checked on October 23, 2026.

* The exe from the original bundle and three rebuilds of its original source all give `7CA9AE7411F13A304495D0730CC6DFAD8E45098B73254B12C9F4974BC27203AC`. The program code was identical byte for byte. A build in a different optimisation mode gives a different value, so the check does tell builds apart.
* The current `offline/server/main.zig` adds stricter path checks, described below. Three fresh builds of it give `D819DA03068D85C92F8DFAEC926EA74AE0602F10BB02E0DAA4BD8A2261DD54C0`. That is the value to expect from the exe on the Releases page.

**Server hardening added in this build.** The server refuses any part of a path that starts or ends with a dot, ends with a space, contains one of the characters `<>"|*?`, or is a Windows device name such as CON, NUL or COM1. It also refuses requests whose Host header is not `127.0.0.1` or `localhost`. This was tested live on October 23, 2026. Normal files returned 200. Paths with `..`, `.. `, `...` or an encoded `..`, the names `CON` and `NUL.js`, and a foreign Host header all returned 403. Nothing outside the `app` folder could be read.

## Licences

* **BumpMesh** is everything except `vendor/`, `offline/` and the textures, which have their own terms. It is Copyright (c) 2026 CNCKitchen (Stefan Hermann) and contributors, under the GNU Affero General Public License version 3 only. See [LICENSE](LICENSE). It is unmodified.
* **Three.js 0.170.0** and **fflate 0.8.2** in `vendor/` are MIT, with their licence files.
* **meshStep 0.1.0** in `vendor/meshstep/` is Copyright CNC Kitchen and contributors, under the same AGPL version 3 licence, with its licence file. It is unmodified.
* **Textures** in `textures/` have mixed licences. 29 are based on Hero Patterns by Steve Schoger, under CC BY 4.0 (credit is required) and converted to height maps. 11 are CC0 from ambientCG and Poly Haven. 6 were made with Filter Forge. The rest ship with BumpMesh.
* **The `offline/` additions** (server, launcher and scripts) are MIT, Copyright (c) 2026 Diterex. See [offline/LICENSE-additions.txt](offline/LICENSE-additions.txt).

Because BumpMesh is under the AGPL version 3, anyone who passes this software on, or lets other people use it over a network, must offer them the complete source under the same licence.
