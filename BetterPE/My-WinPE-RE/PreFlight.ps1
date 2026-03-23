# ================================
# PreFlight.ps1
# ================================

Write-Host "Running PreFlight checks..."

# Check CPU
Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors

# Check RAM
Get-WmiObject Win32_PhysicalMemory | Select-Object Manufacturer, Capacity, Speed

# Check disk status
Get-PhysicalDisk | Select-Object FriendlyName, Size, MediaType, HealthStatus

# Check network
Get-NetAdapter | Select-Object Name, Status, LinkSpeed

# Check storage drivers
dism /Get-Drivers /Online

Write-Host "PreFlight complete."
Pause