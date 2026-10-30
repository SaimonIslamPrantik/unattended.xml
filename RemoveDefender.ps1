
param([switch]$Confirmed)

Add-Type -AssemblyName System.Windows.Forms

# ============================================
# WINDOWS DEFENDER REMOVER
# Source: ionuttbara/windows-defender-remover
# ============================================

# 1. First confirmation
if (-not $Confirmed) {

    $answer = [System.Windows.Forms.MessageBox]::Show(
        "DO YOU WANT TO UNINSTALL MICROSOFT DEFENDER (ANTIVIRUS)?",
        "Windows Defender Uninstaller",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        exit
    }

    # 2. Second confirmation
    $answer = [System.Windows.Forms.MessageBox]::Show(
        "CAUTION:`n`nA system restore point is recommended before you run the script.`n`nThis operation can permanently remove Windows security components.`n`nAre you absolutely sure?",
        "FINAL WARNING",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        exit
    }
}

# 3. Administrator privileges
$admin = ([Security.Principal.WindowsPrincipal](
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $admin) {

    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`"",
        "-Confirmed"
    )

    exit
}

$ProgressPreference = 'SilentlyContinue'

$tempDir = Join-Path $env:TEMP "DefenderRemover"
$exePath = Join-Path $tempDir "Defender.Remover.exe"

try {

    # 4. Attempt to disable Defender real-time protection
    Write-Host "[1/4] Attempting to disable real-time protection..." -ForegroundColor Cyan

    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop

        Write-Host "Real-time protection disable command succeeded." -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not disable real-time protection. Tamper Protection or policy may be blocking it."
    }

    # 5. Fetch latest GitHub release
    Write-Host "[2/4] Fetching latest GitHub release..." -ForegroundColor Cyan

    $release = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/ionuttbara/windows-defender-remover/releases/latest" `
        -Headers @{ "User-Agent" = "PowerShell" }

    $asset = @($release.assets | Where-Object {
        $_.name -match '\.exe$'
    }) | Select-Object -First 1

    if (-not $asset) {
        throw "No EXE asset found in the latest GitHub release."
    }

    Write-Host "Version: $($release.tag_name)" -ForegroundColor Green
    Write-Host "Asset: $($asset.name)"

    # 6. Download executable
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    Write-Host "[3/4] Downloading Defender Remover..." -ForegroundColor Cyan

    Invoke-WebRequest `
        -Uri $asset.browser_download_url `
        -OutFile $exePath

    # 7. Verify SHA256 if provided by GitHub
    if ($asset.digest -match '^sha256:(.+)$') {

        $expectedHash = $Matches[1]
        $actualHash = (Get-FileHash $exePath -Algorithm SHA256).Hash

        if ($actualHash -ne $expectedHash) {
            throw "SHA256 verification failed! Download rejected."
        }

        Write-Host "SHA256 verified." -ForegroundColor Green
    }

    # 8. Execute remover
    Write-Host "[4/4] Running Defender Remover with /r..." -ForegroundColor Cyan

    $process = Start-Process `
        -FilePath $exePath `
        -ArgumentList "/r" `
        -WorkingDirectory $tempDir `
        -Wait `
        -PassThru

    Write-Host "Remover exit code: $($process.ExitCode)" -ForegroundColor Yellow

}
catch {

    [System.Windows.Forms.MessageBox]::Show(
        "ERROR:`n$($_.Exception.Message)",
        "Defender Remover",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )

}
finally {

    # 9. Delete downloaded executable
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan

    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

}

Write-Host "`nProcess finished." -ForegroundColor Green
