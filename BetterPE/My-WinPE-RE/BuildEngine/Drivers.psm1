function Detect-Drivers {
    Write-Host "Detecting drivers..."
    $drv = Get-WindowsDriver -Online | Select-Object Driver, ClassName
    return $drv
}

function Inject-Drivers {
    param($MountDir, $DriverFolder)

    Write-Log "Injecting drivers..."

    dism /Image:$MountDir /Add-Driver /Driver:$DriverFolder /Recurse
}