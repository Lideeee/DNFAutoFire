param(
    [string]$Mode = ""
)

$ErrorActionPreference = "Stop"

function Get-AhkFiles {
    param([string]$Root)
    Get-ChildItem -Path $Root -Recurse -Filter *.ahk | Sort-Object FullName
}

function Test-Utf8Bom {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    return ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

function Get-NoBomFiles {
    param([string]$Root)
    $bad = @()
    foreach ($f in (Get-AhkFiles -Root $Root)) {
        if (-not (Test-Utf8Bom -Path $f.FullName)) {
            $bad += $f.FullName
        }
    }
    return $bad
}

function Show-CheckResult {
    param([string[]]$BadFiles)

    if ($BadFiles.Count -eq 0) {
        Write-Host ""
        Write-Host "ALL_UTF8_WITH_BOM" -ForegroundColor Green
        return
    }

    Write-Host ""
    Write-Host "FOUND_FILES_WITHOUT_UTF8_BOM:" -ForegroundColor Yellow
    foreach ($path in $BadFiles) {
        Write-Host $path
    }
}

function Fix-NoBomFiles {
    param([string[]]$BadFiles)

    if ($BadFiles.Count -eq 0) {
        Write-Host ""
        Write-Host "No .ahk files need fixing." -ForegroundColor Green
        return
    }

    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    foreach ($path in $BadFiles) {
        $text = [System.IO.File]::ReadAllText($path)
        [System.IO.File]::WriteAllText($path, $text, $utf8Bom)
        Write-Host ("Fixed: " + $path) -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "Fix complete." -ForegroundColor Green
}

$root = Split-Path -Parent $PSScriptRoot

if ($Mode -eq "check") {
    $bad = @(Get-NoBomFiles -Root $root)
    Show-CheckResult -BadFiles $bad
    if ($bad.Count -eq 0) {
        exit 0
    }
    exit 1
}

if ($Mode -eq "fix") {
    $bad = @(Get-NoBomFiles -Root $root)
    Show-CheckResult -BadFiles $bad
    Write-Host ""
    Fix-NoBomFiles -BadFiles $bad
    $after = @(Get-NoBomFiles -Root $root)
    Write-Host ""
    Show-CheckResult -BadFiles $after
    if ($after.Count -eq 0) {
        exit 0
    }
    exit 1
}

Write-Host ""
Write-Host "AHK BOM check / fix tool" -ForegroundColor Cyan
Write-Host "1. Check only"
Write-Host "2. Check and fix"
Write-Host "3. Exit"
Write-Host ""
$choice = Read-Host "Choose an option"

switch ($choice) {
    "1" {
        $bad = @(Get-NoBomFiles -Root $root)
        Show-CheckResult -BadFiles $bad
        if ($bad.Count -eq 0) {
            exit 0
        }
        exit 1
    }
    "2" {
        $bad = @(Get-NoBomFiles -Root $root)
        Show-CheckResult -BadFiles $bad
        Write-Host ""
        Fix-NoBomFiles -BadFiles $bad
        $after = @(Get-NoBomFiles -Root $root)
        Write-Host ""
        Show-CheckResult -BadFiles $after
        if ($after.Count -eq 0) {
            exit 0
        }
        exit 1
    }
    default {
        exit 0
    }
}
