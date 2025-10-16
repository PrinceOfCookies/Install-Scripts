Set-Location -Path 'E:\' -ErrorAction Stop

$projectsPath = Join-Path -Path 'E:\' -ChildPath 'Projects'
if (-not (Test-Path -Path $projectsPath)) {
    New-Item -Path $projectsPath -ItemType Directory -Force | Out-Null
}
Set-Location -Path $projectsPath

# Check for git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not installed or not on PATH. Install Git from https://git-scm.com/ and retry."
    Read-Host -Prompt 'Press Enter to exit'
    exit 1
}

Write-Host "Git found. Beginning cloning..." -ForegroundColor Green

$repos = @(
    "https://github.com/PrinceOfCookies/princeofcookies.com.git",
    "https://github.com/PrinceOfCookies/CookieOS.git",
    "https://github.com/PrinceOfCookies/StrwRemastered.git",
    "https://github.com/PrinceOfCookies/Skateboard.git",
    "https://github.com/PrinceOfCookies/factorio-bot-congestion-visualizer.git",
    "https://github.com/PrinceOfCookies/peak-soulmates.git",
    "https://github.com/PrinceOfCookies/fudgy-drp.git",
    "https://github.com/PrinceOfCookies/CommandRelay.git",
    "https://github.com/PrinceOfCookies/GmodChatRelay.git"
)

if ($repos.Count -eq 0) {
    Write-Host "No repositories specified in `$repos. Nothing to clone." -ForegroundColor Yellow
    Read-Host -Prompt 'Press Enter to exit'
    exit 0
}

foreach ($repo in $repos) {
    if (-not $repo) { continue }
    $name = ($repo -split '/|:')[-1] -replace '\.git$',''
    if (-not $name) {
        Write-Warning "Could not determine folder name for '$repo'. Skipping."
        continue
    }

    if (Test-Path -Path (Join-Path -Path $projectsPath -ChildPath $name)) {
        Write-Host "Skipping '$name' (already exists)." -ForegroundColor Yellow
        continue
    }

    Write-Host "Cloning $repo ..."
    $proc = Start-Process -FilePath git -ArgumentList "clone", $repo -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -eq 0) {
        Write-Host " done." -ForegroundColor Green
    } else {
        Write-Host " failed (exit code $($proc.ExitCode))." -ForegroundColor Red
    }
}

Write-Host "Cloning finished." -ForegroundColor Green
Read-Host -Prompt 'Press Enter to exit'