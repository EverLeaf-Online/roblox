$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $RepoRoot "build"
$PluginPath = Join-Path $BuildDir "EverLeafPBRInstaller.rbxm"
$RobloxPluginDir = Join-Path $env:LOCALAPPDATA "Roblox\Plugins"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
New-Item -ItemType Directory -Force -Path $RobloxPluginDir | Out-Null

Push-Location $RepoRoot
try {
    rojo build studio-pbr-plugin.project.json -o $PluginPath
} finally {
    Pop-Location
}

$InstalledPath = Join-Path $RobloxPluginDir "EverLeafPBRInstaller.rbxm"
Copy-Item -Force $PluginPath $InstalledPath
Write-Host "Installed EverLeaf PBR Studio plugin to: $InstalledPath"
Write-Host "Restart Roblox Studio, or disable/re-enable local plugins. If Play is active, the plugin queues the PBR refresh and installs automatically when Play stops."
