# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diterex
# Builds BumpMesh-Offline.zip from the files COMMITTED on this branch (HEAD).
# Refuses to run if there are uncommitted changes, so the zip always matches a commit.
# Usage:  powershell -File offline\make-offline-zip.ps1 -Exe C:\path\bumpmesh-server.exe [-Out BumpMesh-Offline.zip]
param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [string]$Out = "BumpMesh-Offline.zip"
)
$ErrorActionPreference = 'Stop'
# Resolve caller-relative paths BEFORE changing directory.
$exePath = (Resolve-Path -LiteralPath $Exe).Path
$outPath = if ([IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location).Path $Out }
$repo  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$stage = Join-Path ([IO.Path]::GetTempPath()) ("bumpmesh-stage-" + [guid]::NewGuid())
$root  = Join-Path $stage 'BumpMesh-Offline'
$app   = Join-Path $root 'app'
New-Item -ItemType Directory $app | Out-Null
New-Item -ItemType Directory (Join-Path $root 'server-source') | Out-Null
Push-Location $repo
try {
  if (git status --porcelain) { throw "Uncommitted changes in $repo. Commit or stash them first so the zip matches a commit." }
  $commit = (git rev-parse --short HEAD).Trim()
  # App files straight from the commit, byte for byte (autocrlf is switched off so LICENSE etc. match upstream exactly).
  $tmpZip = Join-Path $stage 'app.zip'
  git -c core.autocrlf=false -c core.eol=lf archive --format=zip -o $tmpZip HEAD -- index.html changelog.html style.css logo.png js textures vendor LICENSE
  if ($LASTEXITCODE -ne 0) { throw "git archive failed" }
  Expand-Archive $tmpZip $app
  Copy-Item (Join-Path $app 'LICENSE') (Join-Path $root 'LICENSE')
  Copy-Item 'offline/server/main.zig' (Join-Path $root 'server-source/main.zig')
  Copy-Item 'offline/START BumpMesh.bat' $root
  Copy-Item 'offline/README.txt' $root
  Copy-Item 'offline/LICENCES-AND-CREDITS.txt' $root
  Copy-Item 'offline/LICENSE-additions.txt' $root
  Copy-Item $exePath (Join-Path $root 'bumpmesh-server.exe')
  if (Test-Path $outPath) { Remove-Item $outPath }
  Compress-Archive -Path $root -DestinationPath $outPath
  "Built $outPath from commit $commit"
  "Zip SHA-256: " + (Get-FileHash $outPath -Algorithm SHA256).Hash
  "Exe normalised hash (offline\verify-exe.ps1): " + (& powershell -NoProfile -File (Join-Path $PSScriptRoot 'verify-exe.ps1') $exePath)
} finally { Pop-Location; Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue }
