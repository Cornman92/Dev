# ================================
# HealthRepair.ps1
# ================================

Write-Host "Offline Repair Assistant"

$drive = Read-Host "Enter Windows drive letter (e.g. C:)"

dism /Image:$drive\ /Cleanup-Image /RestoreHealth
sfc /scannow /offbootdir=$drive\ /offwindir=$drive\Windows

Write-Host "Offline repair complete."
Pause