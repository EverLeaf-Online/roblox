$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$rokit = Get-Command rokit -ErrorAction SilentlyContinue
$aftman = Get-Command aftman -ErrorAction SilentlyContinue

if ($rokit) {
    Write-Host "[1/3] Using Rokit"
    rokit trust UpliftGames/wally
    rokit install
} elseif ($aftman) {
    Write-Host "[1/3] Using Aftman"
    aftman install
} else {
    throw "Neither Rokit nor Aftman is available in PATH. Install one of them before continuing."
}

Write-Host "[2/3] Verifying Wally"
$wally = Get-Command wally -ErrorAction SilentlyContinue
if (-not $wally) {
    throw "Wally was not installed or is not available in PATH after toolchain setup."
}

Write-Host "[3/3] Installing React Lua packages"
wally install

Write-Host "EverLeaf Roblox development dependencies are ready."
