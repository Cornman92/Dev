function Get-DriverList {
    $drivers = Get-WindowsDriver -Online | Select-Object Driver, ProviderName, ClassName
    return $drivers
}

function Inject-DetectedDrivers {
    param($MountDir)

    $drivers = Get-DriverList

    foreach ($d in $drivers) {
        if ($d.ClassName -like "*USB*" -or $d.ClassName -like "*NVME*") {
            Write-Host "Injecting $($d.Driver)"
            dism /Image:$MountDir /Add-Driver /Driver:$d.Driver /Recurse
        }
    }
}