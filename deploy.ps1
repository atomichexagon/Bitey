$src = $PSScriptRoot
$dest = "$env:APPDATA\factorio\mods\biter-pet"
$info = Join-Path $src "info.json"
$esc = [char]27

$json = Get-Content $info -Raw | ConvertFrom-Json

$parts = $json.version.Split('.')
$major = [int]$parts[0]
$minor = [int]$parts[1] + 1
$patch = [int]$parts[2]

$json.version = "$major.$minor.$patch"
$json | ConvertTo-Json -Depth 10 | Set-Content $info

Clear-Host
Write-Host "$esc[1;32mVersion$esc[0m: Updated to $esc[1;36m$($json.version)$esc[0m"

if (Test-Path $dest) {
	Remove-Item $dest -Recurse -Force
}
Copy-Item $src $dest -Recurse -Force
Remove-Item (Join-Path $dest "deploy.ps1") -ErrorAction SilentlyContinue

Write-Host "$esc[1;32mSuccess$esc[0m: Folder synchronization complete!"
Write-Host "$esc[1;31mNote$esc[0m: Debugging $esc[1;4mrate limiter$esc[0m may suppress log spam."