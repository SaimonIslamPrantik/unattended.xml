<#
.SYNOPSIS
    Uninstalls Microsoft Edge using the official installer trick.
.DESCRIPTION
    Creates a dummy MicrosoftEdge.exe in the legacy SystemApps directory 
    to bypass removal restrictions, then invokes setup.exe with uninstall flags.
#>

# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please restart PowerShell as Administrator."
    Exit 1
}

$EdgeAppDir = "$Env:ProgramFiles (x86)\Microsoft\Edge\Application"
$InstallerPath = $null

if (Test-Path -LiteralPath $EdgeAppDir -ErrorAction SilentlyContinue) {
    $InstallerPattern = Join-Path $EdgeAppDir "*\Installer\setup.exe"
    if (Test-Path -Path $InstallerPattern -ErrorAction SilentlyContinue) {
        $InstallerPath = (Resolve-Path -Path $InstallerPattern -ErrorAction SilentlyContinue | Select-Object -Last 1).Path
    }
}

if ($InstallerPath) {
    Write-Host "Edge installer found: $InstallerPath" -ForegroundColor Cyan
    Write-Host "Applying bypass and initiating uninstall..." -ForegroundColor Yellow

    # Ensure target directory exists and place dummy legacy exe to unlock the uninstaller
    $DummyDir = "$Env:SystemRoot\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
    if (-not (Test-Path $DummyDir)) {
        New-Item -Path $DummyDir -ItemType Directory -Force | Out-Null
    }
    New-Item -Path (Join-Path $DummyDir "MicrosoftEdge.exe") -ItemType File -Force | Out-Null

    # Execute silent, system-level removal
    Start-Process -FilePath $InstallerPath -ArgumentList "--uninstall --system-level --force-uninstall --delete-profile" -Wait

    Write-Host "Microsoft Edge was successfully removed." -ForegroundColor Green
} else {
    Write-Host "Microsoft Edge is not installed or installer could not be located." -ForegroundColor Red
}
