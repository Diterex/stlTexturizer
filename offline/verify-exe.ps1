# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diterex
# Prints a SHA-256 of a Windows .exe with the per-build random fields blanked:
# the PE header timestamp, the debug-directory timestamps and the CodeView (PDB) GUID.
# The Zig compiler writes new random values there on every build, so two builds
# of the same source differ in those few bytes only. Two files with the same
# normalised hash contain identical program code and data.
# Usage:  powershell -File offline\verify-exe.ps1 path\to\bumpmesh-server.exe
param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
$b = [IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
function U16($o) { [BitConverter]::ToUInt16($b, $o) }
function U32($o) { [BitConverter]::ToUInt32($b, $o) }
function Zero($o, $n) { for ($i = 0; $i -lt $n; $i++) { $b[$o + $i] = 0 } }
$pe = U32 0x3c
if ([Text.Encoding]::ASCII.GetString($b, $pe, 4) -ne "PE`0`0") { throw "Not a PE file" }
Zero ($pe + 8) 4                                   # file header TimeDateStamp
$nSec = U16 ($pe + 6); $optSize = U16 ($pe + 20); $opt = $pe + 24
$magic = U16 $opt
$ddBase = if ($magic -eq 0x20b) { $opt + 112 } else { $opt + 96 }
$dbgRva = U32 ($ddBase + 6 * 8); $dbgSize = U32 ($ddBase + 6 * 8 + 4)
$sec = $opt + $optSize
function RvaToOff($rva) {
  for ($s = 0; $s -lt $nSec; $s++) {
    $h = $sec + 40 * $s; $va = U32 ($h + 12); $raw = U32 ($h + 16); $ptr = U32 ($h + 20)
    if ($rva -ge $va -and $rva -lt $va + [Math]::Max($raw, 1)) { return $ptr + ($rva - $va) }
  }
  throw "RVA not mapped"
}
if ($dbgRva -ne 0) {
  $off = RvaToOff $dbgRva
  for ($e = 0; $e -lt [int]($dbgSize / 28); $e++) {
    $d = $off + 28 * $e
    Zero ($d + 4) 4                                # debug entry TimeDateStamp
    if ((U32 ($d + 12)) -eq 2) {                   # type 2 = CodeView
      $raw = U32 ($d + 24)
      if ([Text.Encoding]::ASCII.GetString($b, $raw, 4) -eq 'RSDS') { Zero ($raw + 4) 16 }   # PDB GUID
    }
  }
}
$sha = [Security.Cryptography.SHA256]::Create()
([BitConverter]::ToString($sha.ComputeHash($b)) -replace '-', '')
