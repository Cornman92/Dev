# ================================
# DeployConsole.ps1
# ================================

function Show-Menu {
    Clear-Host
    Write-Host "======== Deployment Console ========"
    Write-Host "1. Apply Image (WIM/ESD)"
    Write-Host "2. Capture Image"
    Write-Host "3. Partition Disk (DiskPart)"
    Write-Host "4. Open File Explorer++"
    Write-Host "5. Run PreFlight Checks"
    Write-Host "6. Repair Windows Installation"
    Write-Host "7. Exit"
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Choose an option"

    switch ($choice) {

        "1" { & "$($ENV.Scripts)\Apply-WIM.ps1" }
        "2" { & "$($ENV.Scripts)\Capture-WIM.ps1" }
        "3" { Start-Process diskpart -Wait }
        "4" { Start-Process "$($ENV.Tools)\Explorer++.exe" }
        "5" { & "$($ENV.Scripts)\PreFlight.ps1" }
        "6" { & "$($ENV.Scripts)\HealthRepair.ps1" }
        "7" { break }
        default { Write-Host "Invalid selection." }
    }
}