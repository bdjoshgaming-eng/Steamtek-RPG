$ErrorActionPreference = "Stop"

if ($env:STEAMTEK_BLENDER_EXE -and (Test-Path -LiteralPath $env:STEAMTEK_BLENDER_EXE)) {
    Write-Output $env:STEAMTEK_BLENDER_EXE
    exit 0
}

$localOverride = Join-Path $PSScriptRoot "blender.local.txt"
if (Test-Path -LiteralPath $localOverride) {
    $candidate = (Get-Content -LiteralPath $localOverride -Raw).Trim()
    if (Test-Path -LiteralPath $candidate) {
        Write-Output $candidate
        exit 0
    }
}

$fixedCandidates = @(
    "C:\Program Files\Blender Foundation\Blender 4.5\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.4\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe"
)
foreach ($candidate in $fixedCandidates) {
    if (Test-Path -LiteralPath $candidate) {
        Write-Output $candidate
        exit 0
    }
}

$foundation = "C:\Program Files\Blender Foundation"
if (Test-Path -LiteralPath $foundation) {
    $found = Get-ChildItem -LiteralPath $foundation -Filter blender.exe -Recurse -File |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if ($found) {
        Write-Output $found.FullName
        exit 0
    }
}

throw "Blender was not found. Put the full blender.exe path in blender.local.txt or set STEAMTEK_BLENDER_EXE."

