# ================================
# RecoverySuite.ps1
# ================================

Clear-Host
Write-Host "====== Advanced Recovery Suite ======"

$WindowsDrive = (Get-WmiObject Win32_OperatingSystem).SystemDrive

Write-Host "Detected Windows Drive: $WindowsDrive"
Write-Host "Running DISM / SFC repair..."

dism /Image:$WindowsDrive /Cleanup-Image /RestoreHealth

sfc /scannow /offbootdir=$WindowsDrive /offwindir=$WindowsDrive\Windows

Write-Host "Repairs complete."
Pause