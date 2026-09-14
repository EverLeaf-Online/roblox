$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "[1/3] Trusting Wally in Rokit"
rokit trust UpliftGames/wally

Write-Host "[2/3] Installing pinned tools"
rokit install

Write-Host "[3/3] Installing Wally packages"
wally install

Write-Host "EverLeaf Roblox development dependencies are ready."
