$nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeInstalled) {
    Write-Host "Installing Node.js..."
    $temp = "$env:TEMP\node-v22.17.1-x64.msi"
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v22.17.1/node-v22.17.1-x64.msi" -OutFile $temp
    Start-Process "msiexec.exe" -ArgumentList "/i `"$temp`" /quiet" -Wait
    Remove-Item $temp -Force
}

$setupJsUrl = "https://raw.githubusercontent.com/PrinceOfCookies/Install-Scripts/master/install.js"
$localJs = "$env:TEMP\setup.js"

Write-Host "Downloading setup script..."
Invoke-WebRequest -Uri $setupJsUrl -OutFile $localJs

Write-Host "Running setup script..."
Start-Process "node" -ArgumentList "`"$localJs`"" -Wait
