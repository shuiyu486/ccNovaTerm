<#
.SYNOPSIS
    Integration test suite for install.ps1
.DESCRIPTION
    Simulates different user environments by overriding $env:USERPROFILE
    to a temp directory, with various combinations of preinstalled software
    and existing config files.
#>

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptUnderTest = Join-Path $RepoRoot "install.ps1"
$TestRoot = Join-Path $env:TEMP "cct-test-$(Get-Date -Format 'HHmmss')"
$Passed = 0; $Failed = 0

function TestCase([string]$name, [scriptblock]$test) {
    Write-Host "`n=== TEST: $name ===" -ForegroundColor Cyan
    try {
        & $test
        Write-Host "  PASS: $name" -ForegroundColor Green
        $script:Passed++
    } catch {
        Write-Host "  FAIL: $name -- $_" -ForegroundColor Red
        $script:Failed++
    }
}

# ============================================================
# Setup: create minimal fake environment
# ============================================================
Write-Host "Test root: $TestRoot" -ForegroundColor Gray
Remove-Item $TestRoot -Recurse -Force -EA SilentlyContinue
New-Item -ItemType Directory $TestRoot -Force | Out-Null

# ============================================================
# Test 1: Fresh user, all software detected
# ============================================================
TestCase "Fresh install, all software present" {
    $fakeHome = Join-Path $TestRoot "t1-fresh"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    # Override USERPROFILE to simulate another user
    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome
        $output = & $ScriptUnderTest -Force -NoFont 2>&1 | Out-String

        # Verify all config files were created
        $checks = @(
            (Join-Path $fakeHome ".wezterm.lua"),
            (Join-Path $fakeHome "AppData\Roaming\nushell\config.nu"),
            (Join-Path $fakeHome "AppData\Roaming\nushell\env.nu"),
            (Join-Path $fakeHome ".config\starship.toml"),
            (Join-Path $fakeHome "AppData\Roaming\yazi\config\yazi.toml"),
            (Join-Path $fakeHome "AppData\Roaming\yazi\config\keymap.toml"),
            (Join-Path $fakeHome "AppData\Roaming\yazi\config\package.toml")
        )
        foreach ($f in $checks) {
            if (-not (Test-Path $f)) { throw "Missing: $f" }
            $s = (Get-Item $f).Length
            if ($s -lt 20) { throw "File too small: $f ($s bytes)" }
        }

        # Verify placeholder replacement in wezterm.lua
        $w = Get-Content (Join-Path $fakeHome ".wezterm.lua") -Raw
        if ($w -match '__NU_PATH__') { throw "NU_PATH placeholder not replaced" }
        if ($w -notmatch "nu\.exe") { throw "nu.exe not found in wezterm config" }

        # Verify placeholder replacement in env.nu
        $e = Get-Content (Join-Path $fakeHome "AppData\Roaming\nushell\env.nu") -Raw
        if ($e -match '__GIT_USR_BIN__') { throw "GIT_USR_BIN placeholder not replaced" }
        if ($e -notmatch 'file\.exe') { throw "env.nu missing concrete file.exe path" }

    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 2: Existing configs, backup works
# ============================================================
TestCase "Backup of existing configs" {
    $fakeHome = Join-Path $TestRoot "t2-backup"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome

        # Create pre-existing configs with "old" content
        $oldWezterm = Join-Path $fakeHome ".wezterm.lua"
        $oldClaudeDir = Join-Path $fakeHome ".claude"
        New-Item -ItemType Directory $oldClaudeDir -Force | Out-Null
        "OLD_CONFIG" | Set-Content $oldWezterm -Encoding UTF8

        # Run install
        & $ScriptUnderTest -Force -NoFont 2>&1 | Out-Null

        # Check backup was created
        $backupRoot = Join-Path $fakeHome "ccNovaTerm-backup"
        if (-not (Test-Path $backupRoot)) { throw "Backup directory not created" }
        $backupDirs = Get-ChildItem $backupRoot -Directory
        if ($backupDirs.Count -eq 0) { throw "No backup timestamp directory" }

        # Find the backup of .wezterm.lua
        $bakFile = Join-Path $backupDirs[0].FullName ".wezterm.lua"
        if (-not (Test-Path $bakFile)) { throw "Backup .wezterm.lua not found" }
        $bakContent = (Get-Content $bakFile -Raw).Trim()
        if ($bakContent -ne "OLD_CONFIG") { throw "Backup content mismatch: '$bakContent'" }

        # Verify NEW content was written (not the old)
        $newContent = Get-Content $oldWezterm -Raw -Encoding UTF8
        if ($newContent -eq "OLD_CONFIG") { throw "Old config was not overwritten" }

        Write-Host "    (INFO) Verified backup + overwrite" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 3: NoBackup flag
# ============================================================
TestCase "NoBackup flag skips backup" {
    $fakeHome = Join-Path $TestRoot "t4-nobackup"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome

        # Create a file that would be backed up
        "OLD" | Set-Content (Join-Path $fakeHome ".wezterm.lua") -Encoding UTF8

        & $ScriptUnderTest -Force -NoFont -NoBackup 2>&1 | Out-Null

        $backupRoot = Join-Path $fakeHome "ccNovaTerm-backup"
        if (Test-Path $backupRoot) { throw "Backup directory created despite -NoBackup!" }
        Write-Host "    (INFO) No backup directory as expected" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 5: DryRun makes zero changes
# ============================================================
TestCase "DryRun makes no file changes" {
    $fakeHome = Join-Path $TestRoot "t5-dryrun"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome
        & $ScriptUnderTest -DryRun -NoFont 2>&1 | Out-Null

        # No files should exist
        $anyFile = $false
        foreach ($p in @(".wezterm.lua", ".claude", ".config", "AppData")) {
            if (Test-Path (Join-Path $fakeHome $p)) { $anyFile = $true; break }
        }
        if ($anyFile) { throw "DryRun should not create any files!" }
        Write-Host "    (INFO) No files created as expected" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 6: WezTerm placeholder with nu.exe fallback
# ============================================================
TestCase "wezterm.lua uses nu.exe fallback when nu not found" {
    $fakeHome = Join-Path $TestRoot "t6-nufallback"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome
        $output = & $ScriptUnderTest -Force -NoFont 2>&1 | Out-String

        $w = Get-Content (Join-Path $fakeHome ".wezterm.lua") -Raw -Encoding UTF8
        # Should contain nu.exe path (either full or fallback)
        if ($w -notmatch "'[^']*nu\.exe'") {
            throw "wezterm.lua does not contain a valid nu.exe path: $w"
        }
        Write-Host "    (INFO) nu.exe path in wezterm.lua: OK" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 7: Config directory validation (missing config/)
# ============================================================
TestCase "Graceful error when config/ is missing" {
    $fakeHome = Join-Path $TestRoot "t7-noconfig"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    # Create a copy of install.ps1 in an isolated dir (no config/)
    $isolatedDir = Join-Path $TestRoot "t7-isolated"
    New-Item -ItemType Directory $isolatedDir -Force | Out-Null
    Copy-Item $ScriptUnderTest $isolatedDir
    $isolatedScript = Join-Path $isolatedDir "install.ps1"

    $origHome = $env:USERPROFILE
    $exitCode = 0
    try {
        $env:USERPROFILE = $fakeHome
        # Invoke in a child process to capture exit code properly
        $psCmd = "Set-Location '$isolatedDir'; .\install.ps1 -Force -NoFont"
        $result = powershell -NoProfile -Command $psCmd 2>&1
        $exitCode = $LASTEXITCODE
        # exit 1 expected when config/ is missing
        if ($exitCode -ne 1) { throw "Should exit with code 1 when config/ missing. Got: $exitCode" }
        Write-Host "    (INFO) Correctly exited with error code 1" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 8: All config files have valid syntax (smoke test)
# ============================================================
TestCase "Config files have valid syntax" {
    $fakeHome = Join-Path $TestRoot "t9-syntax"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome
        & $ScriptUnderTest -Force -NoFont 2>&1 | Out-Null

        # WezTerm: should be valid Lua (at least check key patterns)
        $w = Get-Content (Join-Path $fakeHome ".wezterm.lua") -Raw -Encoding UTF8
        if ($w -notmatch "return config") { throw "wezterm.lua missing 'return config'" }
        if ($w -notmatch "JetBrainsMono") { throw "wezterm.lua missing font config" }

        # Starship: TOML format check
        $s = Get-Content (Join-Path $fakeHome ".config\starship.toml") -Raw -Encoding UTF8
        if ($s -notmatch "starship\.rs") { throw "starship.toml missing schema reference" }

        # Nushell env: check key lines
        $e = Get-Content (Join-Path $fakeHome "AppData\Roaming\nushell\env.nu") -Raw -Encoding UTF8
        if ($e -notmatch "STARSHIP_SHELL") { throw "env.nu missing STARShip_SHELL" }
        if ($e -notmatch "YAZI_FILE_ONE") { throw "env.nu missing YAZI_FILE_ONE" }

        # Nushell config: check y function
        $c = Get-Content (Join-Path $fakeHome "AppData\Roaming\nushell\config.nu") -Raw -Encoding UTF8
        if ($c -notmatch "def.*env.*y") { throw "config.nu missing yazi function" }

        # Yazi config: check preview shortcut and package lock
        $yk = Get-Content (Join-Path $fakeHome "AppData\Roaming\yazi\config\keymap.toml") -Raw -Encoding UTF8
        if ($yk -notmatch "toggle-pane max-preview") { throw "keymap.toml missing toggle-pane preview shortcut" }
        $yp = Get-Content (Join-Path $fakeHome "AppData\Roaming\yazi\config\package.toml") -Raw -Encoding UTF8
        if ($yp -notmatch "yazi-rs/plugins:toggle-pane") { throw "package.toml missing toggle-pane dependency" }

        Write-Host "    (INFO) All config files pass syntax smoke test" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Test 10: Special characters in home path
# ============================================================
TestCase "Home path with spaces and special chars" {
    $fakeHome = Join-Path $TestRoot "t10-user name!test"
    New-Item -ItemType Directory $fakeHome -Force | Out-Null

    $origHome = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome
        $output = & $ScriptUnderTest -Force -NoFont 2>&1 | Out-String

        # Check all files were created despite spaces in path
        $checks = @(
            (Join-Path $fakeHome ".wezterm.lua"),
            (Join-Path $fakeHome "AppData\Roaming\nushell\config.nu")
        )
        foreach ($f in $checks) {
            if (-not (Test-Path $f)) { throw "Missing file with space-path: $f" }
        }

        Write-Host "    (INFO) Handles special characters in path" -ForegroundColor Gray
    } finally {
        $env:USERPROFILE = $origHome
    }
}

# ============================================================
# Report
# ============================================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  Results: $Passed passed, $Failed failed" -ForegroundColor $(if ($Failed -eq 0) { "Green" } else { "Red" })
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Test data at: $TestRoot" -ForegroundColor Gray
Write-Host "(Files kept for manual inspection. Remove manually when done.)" -ForegroundColor Gray

if ($Failed -gt 0) { exit 1 } else { exit 0 }
