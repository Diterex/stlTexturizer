# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diterex
# Builds BumpMesh-Offline.zip from the files committed on this branch.
# Usage:  powershell -File offline\make-offline-zip.ps1 -Exe C:\path\bumpmesh-server.exe [-Out BumpMesh-Offline.zip]
param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [string]$Out = "BumpMesh-Offline.zip"
)
$ErrorActionPreference = 'Stop'
$repo  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$stage = Join-Path ([IO.Path]::GetTempPath()) ("bumpmesh-stage-" + [guid]::NewGuid())
$root  = Join-Path $stage 'BumpMesh-Offline'
New-Item -ItemType Directory (Join-Path $root 'app') | Out-Null
New-Item -ItemType Directory (Join-Path $root 'server-source') | Out-Null
Push-Location $repo
try {
  # App files = exactly what git tracks, so the zip matches the branch.
  $appFiles = git ls-files -- index.html changelog.html style.css logo.png js textures vendor
  foreach ($f in $appFiles) {
    $dest = Join-Path (Join-Path $root 'app') $f
    New-Item -ItemType Directory (Split-Path $dest) -Force | Out-Null
    Copy-Item $f $dest
  }
  Copy-Item 'LICENSE' (Join-Path (Join-Path $root 'app') 'LICENSE')
  Copy-Item 'LICENSE' (Join-Path $root 'LICENSE')
  Copy-Item 'offline/server/main.zig' (Join-Path $root 'server-source/main.zig')
  Copy-Item 'offline/START BumpMesh.bat' $root
  Copy-Item 'offline/README.txt' $root
  Copy-Item 'offline/LICENCES-AND-CREDITS.txt' $root
  Copy-Item 'offline/LICENSE-additions.txt' $root
  Copy-Item $Exe (Join-Path $root 'bumpmesh-server.exe')
  $outPath = if ([IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path $repo $Out }
  if (Test-Path $outPath) { Remove-Item $outPath }
  Compress-Archive -Path $root -DestinationPath $outPath
  "Built $outPath"
  (Get-FileHash $outPath -Algorithm SHA256).Hash
} finally { Pop-Location; Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue }
