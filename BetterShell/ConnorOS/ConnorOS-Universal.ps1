# ConnorOS-Universal.ps1 (Windows)
Write-Host "=== ConnorOS Universal Post-Install Starting ===" -ForegroundColor Cyan
$os = (Get-CimInstance Win32_OperatingSystem).Caption
if ($os -like "*Windows*") { & "C:\Winutil\ConnorOS-PostInstall.ps1" } else { Write-Host "Use ConnorOS-Universal.sh for Linux/macOS." }
