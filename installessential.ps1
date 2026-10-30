# ==============================================================================
# Setup Script: Choco, Scoop, WinGet (wget, curl), Sudo, Helium, Brave
# ==============================================================================

# 1. Ensure Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Administrator privileges required. Attempting to relaunch as Administrator..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = 'Continue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Set-ExecutionPolicy Bypass -Scope Process -Force

# Helper function to refresh session PATH variable without restarting PowerShell
function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path    = "$machinePath;$userPath"
}

# ------------------------------------------------------------------------------
# STEP 1: Install Chocolatey
# ------------------------------------------------------------------------------
Write-Host "`n[1/5] Checking Chocolatey..." -ForegroundColor Cyan
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Update-SessionPath
} else {
    Write-Host "Chocolatey is already installed." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# STEP 2: Install Scoop (configured for Admin session)
# ------------------------------------------------------------------------------
Write-Host "`n[2/5] Checking Scoop..." -ForegroundColor Cyan
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Yellow
    $scoopInstaller = "$env:TEMP\install-scoop.ps1"
    Invoke-RestMethod -Uri 'https://get.scoop.it' -OutFile $scoopInstaller
    & $scoopInstaller -RunAsAdmin
    Remove-Item $scoopInstaller -Force -ErrorAction SilentlyContinue
    Update-SessionPath
} else {
    Write-Host "Scoop is already installed." -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# STEP 3: Update WinGet and install wget & curl
# ------------------------------------------------------------------------------
Write-Host "`n[3/5] Updating WinGet and installing wget & curl..." -ForegroundColor Cyan
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Updating WinGet sources..." -ForegroundColor Yellow
    winget source update

    Write-Host "Installing wget..." -ForegroundColor Yellow
    winget install --id JernejSimoncic.Wget -e --accept-source-agreements --accept-package-agreements

    Write-Host "Installing curl..." -ForegroundColor Yellow
    winget install --id cURL.cURL -e --accept-source-agreements --accept-package-agreements
} else {
    Write-Warning "WinGet not found. Falling back to Chocolatey for wget and curl..."
    choco install wget curl -y
}

# ------------------------------------------------------------------------------
# STEP 4: Install sudo via Scoop
# ------------------------------------------------------------------------------
Write-Host "`n[4/5] Installing sudo via Scoop..." -ForegroundColor Cyan
Update-SessionPath
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop install sudo
} else {
    # Direct fallback if scoop path didn't register in the current shell
    $scoopPath = "$env:USERPROFILE\scoop\shims\scoop.ps1"
    if (Test-Path $scoopPath) {
        & $scoopPath install sudo
    } else {
        Write-Error "Scoop shim was not found. Please run 'scoop install sudo' in a new terminal."
    }
}

# ------------------------------------------------------------------------------
# STEP 5: Install Helium and Brave via Chocolatey
# ------------------------------------------------------------------------------
Write-Host "`n[5/5] Installing Helium and Brave Browser via Chocolatey..." -ForegroundColor Cyan
choco install helium brave -y

# ------------------------------------------------------------------------------
# FINISH
# ------------------------------------------------------------------------------
Update-SessionPath
Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " Installation completed successfully!" -ForegroundColor Green
Write-Host " Restart your terminal window to ensure all PATHs reload." -ForegroundColor Green
Write-Host "========================================================`n" -ForegroundColor Green
