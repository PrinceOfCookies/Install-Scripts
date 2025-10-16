# install.ps1 - PC setup script

# --- Utility function to check for installed programs ---
function Is-ProgramInstalled {
    param ([string]$ProgramName)
    Get-ItemProperty @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    ) | Where-Object { $_.DisplayName -like "*$ProgramName*" }
}

# --- Helper function for EXE installs ---
function Install-Executable {
    param (
        [string]$Name,
        [string]$Url,
        [string]$InstallerName,
        [string]$Args = "/S"
    )
    if (-not (Is-ProgramInstalled $Name)) {
        Write-Host "Installing $Name..."
        $path = "$env:TEMP\$InstallerName"
        Invoke-WebRequest -Uri $Url -OutFile $path
        Start-Process -FilePath $path -ArgumentList $Args -Wait
        Remove-Item $path
    }
    else {
        Write-Host "$Name is already installed."
    }
}

# --- Helper function for MSI installs ---
function Install-MSI {
    param (
        [string]$Name,
        [string]$Url,
        [string]$InstallerName
    )
    if (-not (Is-ProgramInstalled $Name)) {
        Write-Host "Installing $Name..."
        $path = "$env:TEMP\$InstallerName"
        Invoke-WebRequest -Uri $Url -OutFile $path
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$path`" /quiet" -Wait
        Remove-Item $path
    }
    else {
        Write-Host "$Name is already installed."
    }
}

# --- Helper function for installing .ZIP files ---
function Install-ZIP {
    param (
        [string]$Name,
        [string]$Url,
        [string]$ZipName,
        [string]$Args = "/S"
    )
    # Internally just run this, I just wanted this to have an accurate name
    Install-Executable( $Name, $Url, $ZipName, $Args)
}

# --- Helper function to install additional PS1 Scripts ---
function Install-PS1 {
    param(
        [string]$FileName = '',
        [string]$Url,
        [switch]$Force
    )

    $desktop = [Environment]::GetFolderPath('Desktop')

    if (-not $FileName) {
        try {
            $uri = [Uri]$Url
            $FileName = [IO.Path]::GetFileName($uri.AbsolutePath)
        }
        catch {
            $FileName = ''
        }
        if (-not $FileName) { $FileName = 'downloaded-script.ps1' }
    }
    if (-not $FileName.EndsWith('.ps1')) { $FileName += '.ps1' }

    $dest = Join-Path $desktop $FileName

    if (Test-Path $dest -and -not $Force) {
        Write-Host "Script already exists at $dest. Use -Force to overwrite."
        return
    }

    try {
        Write-Host "Downloading script from $Url to $dest..."
        Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing
        Unblock-File -Path $dest -ErrorAction SilentlyContinue
        Write-Host "Saved script to $dest"
    }
    catch {
        Write-Error "Failed to download script: $_"
    }
}

# --- Setup taskbar position and center icons ---
function TaskbarSetup {
    # Move taskbar to bottom
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
    $data = (Get-ItemProperty -Path $regPath).Settings
    $modified = $data.Clone()
    $modified[12] = 0x03
    Set-ItemProperty -Path $regPath -Name Settings -Value $modified

    # Search box style
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 1

    Stop-Process -Name explorer -Force
    Start-Process explorer
}



# --- Installations ---
Install-Executable "Google Chrome" "https://dl.google.com/chrome/install/latest/chrome_installer.exe" "chrome_installer.exe" "/silent /install" # Auto up to date
Install-Executable "Discord" "https://discord.com/api/download?platform=win" "DiscordSetup.exe" "/silent /install"# Auto up to date
Install-Executable "Visual Studio Code" "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user" "VSCodeSetup.exe" "/silent /install" # Auto up to date
Install-Executable "Steam" "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe" "SteamSetup.exe" "/silent /install" # Auto up to date
Install-Executable "LGHub" "https://download01.logi.com/web/ftp/pub/techsupport/gaming/lghub_installer.exe" "LGHubSetup.exe" "/silent /install" # Auto up to date
Install-Executable "Parsec" "https://builds.parsec.app/package/parsec-windows.exe" "ParsecSetup.exe" "/silent /install" # Auto up to date
Install-Executable "EA App" "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" "EAAppSetup.exe" "/silent /install" # Auto up to date
Install-MSI "Epic Games Launcher" "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi" "EpicGamesLauncher.msi" # Auto up to date
Install-Executable "Malwarebytes" "https://downloads.malwarebytes.com/file/mb-windows" "MalwarebytesSetup.exe" "/silent" "/install" # Auto up to date
Install-Executable "Lunar Client" "https://api.lunarclientprod.com/site/download?os=windows" "LunarClientSetup.exe" "/silent /install" # Auto up to date
Install-Executable "WinRAR" "https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-712.exe" "WinRARSetup.exe" "/silent /install" # Up to date: 7-28-25
Install-Executable "Beekeeper Studio" "https://github.com/beekeeper-studio/beekeeper-studio/releases/download/v5.3.2/Beekeeper-Studio-Setup-5.3.2.exe" "BeekeeperStudioSetup.exe" "/silent /install" # Up to date: 7-28-25
Install-Executable "OBS Studio" "https://cdn-fastly.obsproject.com/downloads/OBS-Studio-31.1.1-Windows-x64-Installer.exe" "OBSStudioSetup.exe" "/silent /install" # Up to date: 7-28-25
Install-Executable "GDLauncher" "https://cdn-raw.gdl.gg/launcher/GDLauncher__2.0.24__win__x64.exe" "GDLauncherSetup.exe" "/silent /install" # Up to date: 7-28-25
Install-Executable "WinSCP" "https://winscp.net/download/WinSCP-6.5.3-Setup.exe/download" "WinSCPSetup.exe" "/silent" "/install" # Up to date: 7-28-25
Install-Executable "Radmin VPN" "https://download.radmin-vpn.com/download/files/Radmin_VPN_1.4.4642.1.exe" "RadminVPN.exe" "/silent /install" # Up to date: 7-28-25
Install-Executable "RaiDrive" "https://app.raidrive.com/download/raidrive.mount/release/RaiDrive.Mount_2025.7.16_x64.exe" "RaiDriveSetup.exe" "/silent /install" # Up to date: 7-28-25
Install-MSI "Node" "https://nodejs.org/dist/v22.17.1/node-v22.17.1-x64.msi" "node v22.17.1 x64.msi" # Up to date: 7-28-25
Install-ZIP "TF2 Bot Detector" "https://github.com/surepy/tf2_bot_detector/releases/download/v1.6.4/tf2-bot-detector_windows-latest_x64-windows_1.6.4.210_Release.zip" "tf2-bot-detector.zip" "/silent /install" # Up to date: 7-28-25
Install-PS1 "git-clones.ps1" "https://pastebin.com/raw/r3mm7c3s"
# Taskbar
TaskbarSetup

# WinDirStat via winget (uses its own package manager)
if (-not (Is-ProgramInstalled "WinDirStat")) {
    Write-Host "Installing WinDirStat..."
    winget install -e --id WinDirStat.WinDirStat --silent
}
else {
    Write-Host "WinDirStat is already installed."
}

if (-not (Is-ProgramInstalled "git")) {
    Write-Host "Instaling Git..."
    winget install --id Git.Git -e --source winget
}
else {
    Write-Host "Git is already installed."
}


# Vencord (no install check since it’s a mod)
Write-Host "Installing Vencord..."
$vcPath = "$env:TEMP\VencordInstaller.exe"
Invoke-WebRequest -Uri "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstaller.exe" -OutFile $vcPath
Start-Process -FilePath $vcPath -Wait
Remove-Item $vcPath

# Remove Edge
if (Is-ProgramInstalled "Edge") {
    Write-Host "Removing Edge..."
    $edgeScript = "$env:TEMP\remove_edge.ps1"
    Invoke-WebRequest -Uri "https://code.ravendevteam.org/talon/edge_vanisher.ps1" -OutFile $edgeScript
    Start-Process -FilePath $edgeScript -Wait
    Remove-Item $edgeScript
}
else {
    Write-Host "Edge is already removed."
}

Write-Host "All installations are complete."
