<#
.SYNOPSIS
    Claude Code Windows Terminal -- One-click install script
.DESCRIPTION
    Installs WezTerm + Nushell + Starship + Yazi terminal config.
    Includes Pastel Powerline prompt and Yazi cd-on-exit.
.PARAMETER Force
    Skip confirmation prompts
.PARAMETER DryRun
    Show what would be done without making changes
.PARAMETER NoBackup
    Skip backing up existing configs
.PARAMETER NoFont
    Skip font installation check
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Force
    .\install.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoBackup,
    [switch]$NoFont
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
# Resolve script/config location
# ============================================================
# Redirect macOS users to install.sh
if ($IsMacOS -or (-not (Get-Command powershell.exe -EA SilentlyContinue) -and (Get-Command sw_vers -EA SilentlyContinue))) {
    Write-Host "  ccNovaTerm" -ForegroundColor Cyan
    Write-Host "  macOS detected — please use the macOS installer:" -ForegroundColor Yellow
    Write-Host "    ./install.sh"
    Write-Host "  If you have PowerShell Core installed, you may also use install.ps1 on macOS."
    exit 0
}

$ScriptPath = try { $MyInvocation.MyCommand.Path } catch { "" }
if (-not $ScriptPath) {
    $ScriptPath = Join-Path $env:USERPROFILE "install.ps1"
}
$ScriptDir = Split-Path -Parent $ScriptPath
$ConfigDir = Join-Path $ScriptDir "config"

$HomeDir = $env:USERPROFILE
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupDir = Join-Path $HomeDir "ccNovaTerm-backup\$Timestamp"

# ============================================================
# Helper functions
# ============================================================
function Write-Step([string]$msg) {
    Write-Host ("`n>> " + $msg) -ForegroundColor Cyan
}
function Write-OK([string]$msg) {
    Write-Host ("    [OK] " + $msg) -ForegroundColor Green
}
function Write-Warn([string]$msg) {
    Write-Host ("    [!!] " + $msg) -ForegroundColor Yellow
}
function Write-Fail([string]$msg) {
    Write-Host ("    [X] " + $msg) -ForegroundColor Red
}
function Write-Info([string]$msg) {
    Write-Host ("    .. " + $msg) -ForegroundColor Gray
}
function Write-FileUtf8NoBom([string]$Path, [string]$Content) {
    # .NET UTF8 does NOT write BOM, unlike PS5.1 Set-Content -Encoding UTF8
    # BOM breaks Nushell alias parsing and corrupts Nerd Font PUA chars
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
}

# ============================================================
# Banner
# ============================================================
Write-Host "  ccNovaTerm" -ForegroundColor Cyan
Write-Host "  Beautiful Terminal for Claude Code on Windows" -ForegroundColor Cyan
Write-Host "  WezTerm + Nushell + Starship + Yazi" -ForegroundColor Gray
if ($DryRun) {
    Write-Host "  *** DRY RUN mode - no files will be modified ***" -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# Validate config directory
# ============================================================
if (-not (Test-Path (Join-Path $ConfigDir ".wezterm.lua"))) {
    Write-Fail ("Config directory not found: " + $ConfigDir)
    Write-Info "Make sure you run this script from the cloned repo directory:"
    Write-Info "  git clone https://github.com/shuiyu486/ccNovaTerm.git"
    Write-Info "  cd ccNovaTerm"
    Write-Info "  .\install.ps1"
    exit 1
}

# ============================================================
# Confirmation
# ============================================================
if (-not $Force -and -not $DryRun) {
    Write-Host "This will install terminal config files."
    Write-Host "Existing configs will be backed up to: $BackupDir"
    Write-Host ""
    $confirm = Read-Host "Continue? (Y/n)"
    if ($confirm -ne "" -and $confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# ============================================================
# Detect installed software and paths
# ============================================================
Write-Step "Checking installed software"

# Find nu.exe
$nuPath = ""
try { $nuPath = (Get-Command nu.exe -EA SilentlyContinue).Source } catch {}
if (-not $nuPath) {
    $commonNu = Join-Path $HomeDir "AppData\Local\Programs\nu\bin\nu.exe"
    if (Test-Path $commonNu) { $nuPath = $commonNu }
}
# Also check winget install location
if (-not $nuPath) {
    $altNu = Join-Path ${env:ProgramFiles} "nu\bin\nu.exe"
    if (Test-Path $altNu) { $nuPath = $altNu }
}

# Find git.exe and file.exe (for Yazi)
$gitPath = ""
$gitUsrBin = ""
$fileExePath = ""
try { $gitPath = (Get-Command git.exe -EA SilentlyContinue).Source } catch {}
if ($gitPath) {
    $gitBase = Split-Path -Parent $gitPath
    # git.exe may be in .../cmd/ or .../bin/ — go up to Git root
    if ((Split-Path -Leaf $gitBase) -in @('cmd', 'bin')) {
        $gitBase = Split-Path -Parent $gitBase
    }
    $gitUsrBin = Join-Path $gitBase "usr\bin"
    $fileExePath = Join-Path $gitUsrBin "file.exe"
} else {
    # Check default Git install paths
    $defaultGitPaths = @(
        "${env:ProgramFiles}\Git",
        "${env:ProgramFiles(x86)}\Git",
        "C:\Program Files\Git"
    )
    foreach ($p in $defaultGitPaths) {
        $f = Join-Path $p "usr\bin\file.exe"
        if (Test-Path $f) {
            $gitUsrBin = Join-Path $p "usr\bin"
            $fileExePath = $f
            break
        }
    }
}

# Find wezterm.exe
$weztermFound = $false
try { Get-Command wezterm.exe -EA SilentlyContinue | Out-Null; $weztermFound = $true } catch {}

# Find starship.exe
$starshipFound = $false
try { Get-Command starship.exe -EA SilentlyContinue | Out-Null; $starshipFound = $true } catch {}

# Find yazi.exe
$yaziFound = $false
try { Get-Command yazi.exe -EA SilentlyContinue | Out-Null; $yaziFound = $true } catch {}

# Find claude.exe
$claudeFound = $false
try { Get-Command claude.exe -EA SilentlyContinue | Out-Null; $claudeFound = $true } catch {}

# Report status
function Check-Item([string]$name, [bool]$ok, [string]$installHint) {
    if ($ok) { Write-OK $name }
    else      { Write-Fail ($name + " -- not found. Install: " + $installHint) }
}

Check-Item "WezTerm"     $weztermFound   "winget install wez.wezterm"
Check-Item "Nushell"     ($nuPath -ne "") "winget install Nushell.Nushell"
Check-Item "Starship"    $starshipFound   "winget install Starship.Starship"
Check-Item "Yazi"        $yaziFound       "scoop install yazi  or  https://github.com/sxyazi/yazi/releases"
Check-Item "Claude Code" $claudeFound     "npm install -g @anthropic-ai/claude-code"
Check-Item "Git"         ($gitPath -ne "")"winget install Git.Git"

$missingCount = 0
if (-not $weztermFound) { $missingCount++ }
if ($nuPath -eq "")     { $missingCount++ }
if (-not $starshipFound) { $missingCount++ }
if (-not $yaziFound)     { $missingCount++ }
if (-not $claudeFound)   { $missingCount++ }
if ($gitPath -eq "")     { $missingCount++ }

if ($missingCount -gt 0) {
    Write-Host ""
    Write-Warn ("$missingCount software(s) not installed. You can still install configs now and install software later.")
    if (-not $Force -and -not $DryRun) {
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") { exit 0 }
    }
}

# ============================================================
# Font check
# ============================================================
if (-not $NoFont) {
    Write-Step "Checking Nerd Font"
    $fontInstalled = $false
    try {
        Add-Type -AssemblyName System.Drawing -EA SilentlyContinue
        $fontCollection = [System.Drawing.Text.InstalledFontCollection]::new()
        foreach ($f in $fontCollection.Families) {
            if ($f.Name -like "*JetBrainsMono*") { $fontInstalled = $true; break }
        }
    } catch {}
    if ($fontInstalled) {
        Write-OK "JetBrainsMono Nerd Font installed"
    } else {
        Write-Warn "JetBrainsMono Nerd Font not installed"
        Write-Info "Download: https://github.com/ryanoasis/nerd-fonts/releases"
        Write-Info "Search JetBrainsMono.zip, extract, right-click .ttf -> Install for all users"
        Write-Info "(Close WezTerm before installing the font)"
    }
}

# ============================================================
# Prepare paths (escape for target file formats)
# ============================================================
# Luacheck: double backslash for Lua string
$weztermNuPath = ""
if ($nuPath) {
    $weztermNuPath = $nuPath -replace '\\', '\\'
} else {
    $weztermNuPath = "nu.exe"
}
Write-Info ("WezTerm default_prog = " + $weztermNuPath)

# Nushell env.nu: double backslash for Nushell string
$fileExeNushell = ""
if ($fileExePath -and (Test-Path $fileExePath)) {
    $fileExeNushell = $fileExePath -replace '\\', '\\'
} elseif ($gitUsrBin) {
    $fileExeNushell = (Join-Path $gitUsrBin "file.exe") -replace '\\', '\\'
} else {
    $fileExeNushell = "C:\\Program Files\\Git\\usr\\bin\\file.exe"
    if (-not $DryRun) {
        Write-Warn "file.exe not found. Using default path in env.nu. Verify it after install."
    }
}
Write-Info ("YAZI_FILE_ONE = " + $fileExeNushell)

# ============================================================
# Target config files
# ============================================================
$targets = @()

$targets += @{
    Title = "WezTerm"
    Src   = Join-Path $ConfigDir ".wezterm.lua"
    Dst   = Join-Path $HomeDir ".wezterm.lua"
    Type  = "copy"
}
$targets += @{
    Title = "Nushell config"
    Src   = Join-Path $ConfigDir "config.nu"
    Dst   = Join-Path $HomeDir "AppData\Roaming\nushell\config.nu"
    Type  = "copy"
}
$targets += @{
    Title = "Nushell env"
    Src   = Join-Path $ConfigDir "env.nu"
    Dst   = Join-Path $HomeDir "AppData\Roaming\nushell\env.nu"
    Type  = "copy"
}
$targets += @{
    Title = "Starship"
    Src   = Join-Path $ConfigDir "starship.toml"
    Dst   = Join-Path $HomeDir ".config\starship.toml"
    Type  = "copy"
}
$targets += @{
    Title = "Yazi config"
    Src   = Join-Path $ConfigDir "yazi\yazi.toml"
    Dst   = Join-Path $HomeDir "AppData\Roaming\yazi\config\yazi.toml"
    Type  = "copy"
}
$targets += @{
    Title = "Yazi keymap"
    Src   = Join-Path $ConfigDir "yazi\keymap.toml"
    Dst   = Join-Path $HomeDir "AppData\Roaming\yazi\config\keymap.toml"
    Type  = "copy"
}
$targets += @{
    Title = "Yazi packages"
    Src   = Join-Path $ConfigDir "yazi\package.toml"
    Dst   = Join-Path $HomeDir "AppData\Roaming\yazi\config\package.toml"
    Type  = "copy"
}

# ============================================================
# Backup
# ============================================================
if (-not $NoBackup -and -not $DryRun) {
    Write-Step ("Backing up existing configs -> " + $BackupDir)
    $hasBackup = $false
    foreach ($t in $targets) {
        if (Test-Path $t.Dst) {
            if (-not $hasBackup) {
                New-Item -ItemType Directory -Force $BackupDir | Out-Null
                $hasBackup = $true
            }
            $leaf = Split-Path -Leaf $t.Dst
            Copy-Item $t.Dst (Join-Path $BackupDir $leaf) -Force
            Write-OK ("Backed up: " + $leaf)
        }
    }
    if (-not $hasBackup) {
        Write-Info "No existing configs to backup"
    }
} elseif ($DryRun) {
    Write-Step ("(DRY RUN) Would backup to: " + $BackupDir)
}

# ============================================================
# Install
# ============================================================
Write-Step "Installing config files"

if ($DryRun) { Write-Info "(DRY RUN -- no files written below)" }

$installedCount = 0
$failedCount = 0

foreach ($t in $targets) {
    if ($t.Type -eq "copy") {
        if (-not (Test-Path $t.Src)) {
            Write-Fail ($t.Title + ": source not found: " + $t.Src)
            $failedCount++
            continue
        }

        $content = $null
        try { $content = Get-Content $t.Src -Raw -Encoding UTF8 } catch {}

        if (-not $content) {
            Write-Fail ($t.Title + ": cannot read source file")
            $failedCount++
            continue
        }

        # Placeholder replacement
        if ($t.Dst -match '\.wezterm\.lua$') {
            $content = $content.Replace('__NU_PATH__', $weztermNuPath)
        }
        if ($t.Dst -match 'env\.nu$') {
            if ($gitUsrBin) {
                $content = $content.Replace('__GIT_USR_BIN__', ($gitUsrBin -replace '\\', '\\'))
            }
            # If git not found, keep the default placeholder path (C:\Program Files\Git\usr\bin)
        }

        if ($DryRun) {
            Write-Info ("Would write: " + $t.Dst)
        } else {
            $dstDir = Split-Path -Parent $t.Dst
            try {
                New-Item -ItemType Directory -Force $dstDir | Out-Null
                Write-FileUtf8NoBom $t.Dst $content
                Write-OK ($t.Title + " -> " + $t.Dst)
                $installedCount++
            } catch {
                Write-Fail ($t.Title + ": write failed: " + $_.Exception.Message)
                $failedCount++
            }
        }
    }
}

if ($yaziFound) {
    if ($DryRun) {
        Write-Info "Would install Yazi plugins from package.toml: ya pkg install"
    } else {
        Write-Step "Installing Yazi plugins"
        try {
            $oldYaziConfigHome = $env:YAZI_CONFIG_HOME
            $env:YAZI_CONFIG_HOME = Join-Path $HomeDir "AppData\Roaming\yazi\config"
            ya pkg install
            if ($LASTEXITCODE -eq 0) {
                Write-OK "Yazi plugins installed from package.toml"
            } else {
                Write-Warn "ya pkg install exited with a non-zero status. Run it manually after install."
            }
        } catch {
            Write-Warn ("Cannot run ya pkg install: " + $_.Exception.Message)
        } finally {
            $env:YAZI_CONFIG_HOME = $oldYaziConfigHome
        }
    }
} else {
    Write-Warn "Yazi not found. After installing Yazi, run: ya pkg install"
}

# ============================================================
# Verify
# ============================================================
if (-not $DryRun -and $installedCount -gt 0) {
    Write-Step "Verifying installed files"
    foreach ($t in $targets) {
        if (Test-Path $t.Dst) {
            $size = (Get-Item $t.Dst).Length
            if ($size -gt 10) {
                Write-OK ((Split-Path -Leaf $t.Dst) + " (" + $size + " bytes)")
            } else {
                Write-Warn ((Split-Path -Leaf $t.Dst) + " is very small (" + $size + " bytes), may be corrupted")
            }
        }
    }
}

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  DRY RUN complete" -ForegroundColor Yellow
} elseif ($failedCount -eq 0) {
    Write-Host "  Installation complete!" -ForegroundColor Green
} else {
    Write-Host ("  Done with " + $failedCount + " warning(s)") -ForegroundColor Yellow
}
Write-Host "============================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    Write-Host ""
    Write-Warn ("$failedCount file(s) could not be installed. Check permissions and retry.")
}

if (-not $NoBackup -and -not $DryRun) {
    Write-Host ("  Backup: " + $BackupDir) -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart WezTerm"
Write-Host "  2. Verify font: wezterm ls-fonts --list-system"
Write-Host "  3. Configure proxy in: $HomeDir\AppData\Roaming\nushell\env.nu"
Write-Host "  4. If Yazi plugins were skipped, run: ya pkg install"
Write-Host "  5. Install status line: /plugin install cc-statusline && /cc-statusline:setup"

if (-not $weztermFound) {
    Write-Host ""
    Write-Warn "WezTerm not detected. Add wezterm.exe to PATH after installation."
}
