# ============================================================================
# install_masm.ps1 — Automatic MASM (ML64) installer for Tower Defense Arena
# ============================================================================
#
# USAGE (run one of these in PowerShell as Administrator):
#
#   Option A — bypass execution policy for just this script:
#     powershell -ExecutionPolicy Bypass -File install_masm.ps1
#
#   Option B — allow scripts permanently for your user account:
#     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#     .\install_masm.ps1
#
# What this script does:
#   1. Checks that winget is available
#   2. Installs Visual Studio 2022 Build Tools (includes ml64.exe + nmake.exe)
#   3. Finds the installed ml64.exe path
#   4. Adds that path to your user PATH permanently
#   5. Creates dev_env.bat — a one-click build console shortcut
#   6. Verifies that ml64 and nmake work
# ============================================================================

param(
    [switch]$SkipInstall   # Pass -SkipInstall if VS Build Tools are already installed
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ─── Colour helpers ──────────────────────────────────────────────────────────
function Write-Header { param([string]$t) Write-Host "`n>>> $t" -ForegroundColor Cyan }
function Write-OK     { param([string]$t) Write-Host "  [OK]  $t" -ForegroundColor Green }
function Write-Info   { param([string]$t) Write-Host "  [..]  $t" -ForegroundColor White }
function Write-Warn   { param([string]$t) Write-Host "  [!!]  $t" -ForegroundColor Yellow }
function Write-Fail   { param([string]$t) Write-Host "  [ERR] $t" -ForegroundColor Red; exit 1 }

# ─── Banner ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  =============================================================" -ForegroundColor Magenta
Write-Host "   Tower Defense Arena — MASM Installer" -ForegroundColor Magenta
Write-Host "  =============================================================" -ForegroundColor Magenta
Write-Host ""

# ─── Step 1: Windows version ─────────────────────────────────────────────────
Write-Header "Step 1 — Checking Windows version"
$os = [System.Environment]::OSVersion.Version
if ($os.Major -lt 10) {
    Write-Fail "Windows 10 or later is required. Found: $os"
}
Write-OK "Windows $($os.Major).$($os.Minor) — OK"

# ─── Step 2: winget check ────────────────────────────────────────────────────
Write-Header "Step 2 — Checking for winget"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Fail @"
  winget not found on this system.
  
  Fix: Open the Microsoft Store, search for 'App Installer', and install it.
  Then re-run this script.
  
  Direct link: https://aka.ms/getwinget
"@
}
$wingetVer = winget --version 2>&1
Write-OK "winget $wingetVer"

# ─── Step 3: Install VS 2022 Build Tools ─────────────────────────────────────
Write-Header "Step 3 — Installing Visual Studio 2022 Build Tools"

if ($SkipInstall) {
    Write-Warn "Skipping install (--SkipInstall flag set). Searching for existing installation..."
} else {
    Write-Info "Starting download and install. This typically takes 5-20 minutes..."
    Write-Info "A separate installer window may appear — that is normal."
    Write-Host ""

    # The components we need:
    #   Microsoft.VisualStudio.Workload.VCTools        — C++ build tools (contains ml64, nmake, link)
    #   Microsoft.VisualStudio.Component.VC.Tools.x86.x64 — MSVC compiler toolset
    #   Microsoft.VisualStudio.Component.Windows11SDK.22000 — Windows SDK (headers + libs)
    $overrideArgs = (
        "--quiet",
        "--norestart",
        "--add Microsoft.VisualStudio.Workload.VCTools",
        "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "--add Microsoft.VisualStudio.Component.Windows11SDK.22000"
    ) -join " "

    try {
        winget install `
            --id    "Microsoft.VisualStudio.2022.BuildTools" `
            --silent `
            --override $overrideArgs
        Write-OK "Installation complete (or already up to date)."
    } catch {
        Write-Warn "winget returned a non-zero exit code: $_"
        Write-Warn "This is often normal (already installed). Continuing..."
    }
}

# ─── Step 4: Locate ml64.exe ─────────────────────────────────────────────────
Write-Header "Step 4 — Locating ml64.exe"

# Common installation roots (in priority order)
$candidateRoots = @(
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools",
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community",
    "C:\Program Files\Microsoft Visual Studio\2022\Community",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional",
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
)

$vsRoot = $candidateRoots | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $vsRoot) {
    Write-Fail @"
  Could not find a Visual Studio 2022 installation.
  
  Please try one of the following:
    a) Run this script again without --SkipInstall
    b) Manually install 'VS 2022 Build Tools' from:
       https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
       (make sure to select 'C++ build tools' workload during install)
"@
}
Write-OK "VS root: $vsRoot"

# Find the latest MSVC toolset (the folder name is the version, e.g. 14.38.33130)
$msvcRoot = Join-Path $vsRoot "VC\Tools\MSVC"
if (-not (Test-Path $msvcRoot)) {
    Write-Fail "MSVC folder not found: $msvcRoot — the workload may not have been installed."
}

$latestToolset = Get-ChildItem $msvcRoot -Directory |
    Sort-Object { [Version]$_.Name } -Descending |
    Select-Object -First 1

if (-not $latestToolset) {
    Write-Fail "No MSVC toolset found under $msvcRoot"
}
Write-OK "MSVC toolset: $($latestToolset.Name)"

# ML64 lives in the x64 host, x64 target sub-folder
$binDir  = Join-Path $latestToolset.FullName "bin\HostX64\x64"
$ml64    = Join-Path $binDir "ml64.exe"
$nmake   = Join-Path $binDir "nmake.exe"
$linkExe = Join-Path $binDir "link.exe"

if (-not (Test-Path $ml64)) {
    Write-Fail "ml64.exe not found at: $ml64`nEnsure 'VC++ tools' workload is installed."
}
Write-OK "ml64.exe  : $ml64"

if (Test-Path $nmake)   { Write-OK "nmake.exe : $nmake" }
else                    { Write-Warn "nmake.exe not found — use the x64 Native Tools Command Prompt." }

if (Test-Path $linkExe) { Write-OK "link.exe  : $linkExe" }
else                    { Write-Warn "link.exe not found at expected path." }

# ─── Step 5: Also locate the Windows SDK libs ────────────────────────────────
Write-Header "Step 5 — Locating Windows SDK libraries (kernel32.lib)"

$kitRoot = "C:\Program Files (x86)\Windows Kits\10\Lib"
$sdkLib  = $null

if (Test-Path $kitRoot) {
    $latestSDK = Get-ChildItem $kitRoot -Directory |
        Sort-Object { [Version]$_.Name } -Descending |
        Select-Object -First 1
    if ($latestSDK) {
        $sdkLib = Join-Path $latestSDK.FullName "um\x64"
        Write-OK "Windows SDK lib: $sdkLib"
    }
}

if (-not $sdkLib -or -not (Test-Path $sdkLib)) {
    Write-Warn "Windows SDK x64 libs not found. You may see 'kernel32.lib not found' errors."
    Write-Warn "Install SDK from: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/"
}

# ─── Step 6: Add binDir to user PATH ─────────────────────────────────────────
Write-Header "Step 6 — Updating user PATH"

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($null -eq $userPath) { $userPath = "" }

if ($userPath -like "*$binDir*") {
    Write-OK "PATH already contains the ml64 directory — no change needed."
} else {
    $newPath = ($userPath.TrimEnd(";") + ";" + $binDir).TrimStart(";")
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-OK "Added to user PATH: $binDir"
    Write-Warn "Open a NEW terminal window for the PATH change to take effect."
}

# Also update current session so the verify step works
$env:PATH = $env:PATH + ";" + $binDir

# ─── Step 7: Create dev_env.bat ───────────────────────────────────────────────
Write-Header "Step 7 — Creating dev_env.bat (one-click build console)"

$vcvars = Join-Path $vsRoot "VC\Auxiliary\Build\vcvars64.bat"

$batLines = @(
    "@echo off",
    "REM dev_env.bat — Opens an x64 MASM build console for Tower Defense Arena",
    "REM Double-click this file to start building.",
    "",
    "if not exist `"$vcvars`" (",
    "    echo ERROR: vcvars64.bat not found. Please re-run install_masm.ps1",
    "    pause",
    "    exit /b 1",
    ")",
    "",
    "call `"$vcvars`"",
    "",
    "echo.",
    "echo  =============================================================",
    "echo   Tower Defense Arena ^| x64 MASM Build Environment",
    "echo  =============================================================",
    "echo.",
    "echo   Build:   nmake /f Makefile.win",
    "echo   Run:     nmake /f Makefile.win run",
    "echo   Clean:   nmake /f Makefile.win clean",
    "echo.",
    "echo   Or just run:  tower_defense.exe",
    "echo.",
    "",
    "cd /d `"%~dp0`"",
    "cmd /k"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$batPath   = Join-Path $scriptDir "dev_env.bat"
$batLines -join "`r`n" | Set-Content $batPath -Encoding ASCII
Write-OK "Created: $batPath"

# ─── Step 8: Verify ───────────────────────────────────────────────────────────
Write-Header "Step 8 — Verifying installation"

try {
    $ml64Out = & $ml64 2>&1 | Select-Object -First 2
    Write-OK "ml64 responds: $($ml64Out[0]) $($ml64Out[1])"
} catch {
    Write-Warn "Could not invoke ml64.exe in this session. Open a new terminal and try: ml64 /?"
}

if (Test-Path $nmake) {
    try {
        $nmakeOut = & $nmake /? 2>&1 | Select-Object -First 1
        Write-OK "nmake responds: $nmakeOut"
    } catch {
        Write-Warn "nmake verification failed — use x64 Native Tools Command Prompt."
    }
}

# ─── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  =============================================================" -ForegroundColor Green
Write-Host "   Installation Complete!" -ForegroundColor Green
Write-Host "  =============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  OPTION A (easiest):" -ForegroundColor Cyan
Write-Host "    Double-click  dev_env.bat  in this folder." -ForegroundColor White
Write-Host "    Then type:    nmake /f Makefile.win" -ForegroundColor Yellow
Write-Host ""
Write-Host "  OPTION B (manual):" -ForegroundColor Cyan
Write-Host "    Open Start Menu -> search 'x64 Native Tools Command Prompt for VS 2022'" -ForegroundColor White
Write-Host "    cd to this project folder" -ForegroundColor White
Write-Host "    nmake /f Makefile.win" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Run the game:" -ForegroundColor Cyan
Write-Host "    tower_defense.exe" -ForegroundColor Yellow
Write-Host ""
