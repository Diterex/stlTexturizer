/*
 * Copyright (c) 2026 CNCKitchen (Stefan Hermann) and contributors
 * SPDX-License-Identifier: AGPL-3.0-only
 */

// Builds an offline copy of BumpMesh that runs on a PC with no internet.
//
//   node offline/make-offline.mjs [--out dist-offline] [--exe path/to/bumpmesh-server.exe]
//
// Nothing in the source tree is changed. The script copies the app files into
// <out>/BumpMesh-Offline/app, downloads the pinned libraries listed in
// offline/libs.json (three.js, fflate, meshStep), checks each one against its
// SHA256, and then makes the small address changes that point the page and its
// workers at the local copies instead of the CDN. If upstream changes one of
// those lines the script stops and says so, instead of guessing.

import { createHash } from 'node:crypto';
import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync, copyFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
};
const outRoot = resolve(opt('--out', join(root, 'dist-offline')));
const exePath = opt('--exe', null);
const dest = join(outRoot, 'BumpMesh-Offline');
const app = join(dest, 'app');

function fail(msg) {
  console.error('\nStopped. ' + msg);
  process.exit(1);
}

// 1. A clean output folder.
if (existsSync(dest)) rmSync(dest, { recursive: true, force: true });
mkdirSync(app, { recursive: true });

// 2. Copy the app files exactly as they are in the checkout.
for (const name of ['index.html', 'changelog.html', 'style.css', 'logo.png', 'LICENSE', 'js', 'textures']) {
  const src = join(root, name);
  if (!existsSync(src)) fail('Missing ' + name + ' in the checkout.');
  cpSync(src, join(app, name), { recursive: true });
}

// 3. Download the pinned libraries and verify every file.
const libs = JSON.parse(readFileSync(join(root, 'offline', 'libs.json'), 'utf8'));
let n = 0;
for (const f of libs.files) {
  const res = await fetch(f.url);
  if (!res.ok) fail('Could not download ' + f.url + ' (HTTP ' + res.status + ').');
  const bytes = Buffer.from(await res.arrayBuffer());
  const sum = createHash('sha256').update(bytes).digest('hex');
  if (sum !== f.sha256) fail('Checksum mismatch for ' + f.url + '\n  expected ' + f.sha256 + '\n  got      ' + sum);
  const target = join(app, f.dest);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, bytes);
  n++;
}
console.log('Downloaded and verified ' + n + ' library files.');

// 4. Point the page and the workers at the local copies. Each replacement must
//    match exactly once, so a change upstream cannot slip through unnoticed.
const CDN = 'https://cdn.jsdelivr.net/npm/';
const patches = {
  'index.html': [
    ['<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>', ''],
    ['"three": "' + CDN + 'three@0.170.0/build/three.module.js"', '"three": "./vendor/three/build/three.module.js"'],
    ['"three/addons/": "' + CDN + 'three@0.170.0/examples/jsm/"', '"three/addons/": "./vendor/three/examples/jsm/"'],
    ['"fflate": "' + CDN + 'fflate@0.8.2/esm/browser.js"', '"fflate": "./vendor/fflate/esm/browser.js"'],
    ['<link rel="modulepreload" href="' + CDN + 'three@0.170.0/build/three.module.js">', '<link rel="modulepreload" href="./vendor/three/build/three.module.js">'],
  ],
  'js/threeCompat.js': [
    ["const CDN_THREE = '" + CDN + "three@0.170.0/build/three.module.js';", "const CDN_THREE = '../vendor/three/build/three.module.js';"],
  ],
  'js/stepWorker.js': [
    ["} from '" + CDN + "meshstep@0.1.0/+esm';", "} from '../vendor/meshstep/dist/index.js';"],
  ],
};
for (const [file, list] of Object.entries(patches)) {
  const p = join(app, file);
  let text = readFileSync(p, 'utf8');
  for (const [from, to] of list) {
    const count = text.split(from).length - 1;
    if (count !== 1) fail(file + ': expected to find this exactly once but found it ' + count + ' times\n  ' + from);
    text = text.replace(from, () => to);
  }
  writeFileSync(p, text);
}

// 5. Make sure nothing in the app still reaches for the CDN.
const left = [];
(function scan(dir) {
  for (const e of readdirSync(dir)) {
    const p = join(dir, e);
    if (statSync(p).isDirectory()) { if (e !== 'vendor' && e !== 'textures') scan(p); continue; }
    if (/\.(html|js|css)$/.test(e) && /cdn\.jsdelivr\.net/.test(readFileSync(p, 'utf8'))) left.push(p.replace(dest, ''));
  }
})(app);
if (left.length) fail('These files still mention the CDN:\n  ' + left.join('\n  '));

// 6. The launcher, the server source, the instructions and (optionally) the server program.
mkdirSync(join(dest, 'server-source'), { recursive: true });
copyFileSync(join(root, 'offline', 'server', 'main.zig'), join(dest, 'server-source', 'main.zig'));
copyFileSync(join(root, 'offline', 'START BumpMesh.bat'), join(dest, 'START BumpMesh.bat'));
copyFileSync(join(root, 'offline', 'user-readme.txt'), join(dest, 'README.txt'));
if (exePath) {
  if (!existsSync(exePath)) fail('The file given to --exe does not exist.');
  copyFileSync(exePath, join(dest, 'bumpmesh-server.exe'));
} else {
  console.log('No --exe given. Build the server with Zig (see offline/README.md) and copy it next to START BumpMesh.bat.');
}

console.log('\nDone. Your offline copy is in ' + dest);
