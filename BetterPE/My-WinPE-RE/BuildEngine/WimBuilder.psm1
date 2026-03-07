function Build-WinPE {
    Write-Log "Building WinPE..."
    Show-ProgressBar -Percent 10 -Message "Mounting WIM..."

    dism /Mount-WIM /WimFile:D:\My-Win[PE][RE]\WinPE\base\boot.wim /index:1 /MountDir:D:\My-Win[PE][RE]\WinPE\mount

    Show-ProgressBar -Percent 40 -Message "Injecting Tools..."
    powershell -ExecutionPolicy Bypass -File D:\My-Win[PE][RE]\Tool-AutoSetup.ps1 -MountDir D:\My-Win[PE][RE]\WinPE\mount -ToolRoot D:\My-Win[PE][RE]

    Show-ProgressBar -Percent 70 -Message "Injecting Drivers..."
    Inject-Drivers -MountDir D:\My-Win[PE][RE]\WinPE\mount -DriverFolder D:\My-Win[PE][RE]\WinPE\drivers

    Show-ProgressBar -Percent 100 -Message "Committing..."
    dism /Unmount-WIM /MountDir:D:\My-Win[PE][RE]\WinPE\mount /Commit
}

function Build-WinRE { ... }   # Same format

function Build-Hybrid { ... }  # Same format

function Build-Combined {
    Write-Log "Building Combined WIM..."

    dism /Export-Image /SourceImageFile:D:\My-Win[PE][RE]\Output\WIMs\WinPE_Custom.wim /SourceIndex:1 /DestinationImageFile:D:\My-Win[PE][RE]\Output\WIMs\Combined.wim /Compress:max
    dism /Export-Image /SourceImageFile:D:\My-Win[PE][RE]\Output\WIMs\WinRE_Custom.wim /SourceIndex:1 /DestinationImageFile:D:\My-Win[PE][RE]\Output\WIMs\Combined.wim /Compress:max
    dism /Export-Image /SourceImageFile:D:\My-Win[PE][RE]\Output\WIMs\Hybrid_Custom.wim /SourceIndex:1 /DestinationImageFile:D:\My-Win[PE][RE]\Output\WIMs\Combined.wim /Compress:max
}