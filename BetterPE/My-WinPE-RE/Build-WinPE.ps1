$root = "D:\My-Win[PE][RE]"
$wim = "$root\WinPE\base\boot.wim"
$mount = "$root\WinPE\mount"

dism /Mount-WIM /WimFile:$wim /index:1 /MountDir:$mount

.\Inject-Drivers.ps1 -MountDir $mount -DriverDir "$root\WinPE\drivers"
.\Add-Tools.ps1 -MountDir $mount -ToolsDir "$root\WinPE\tools"

dism /Unmount-WIM /MountDir:$mount /Commit
Copy-Item $wim "$root\Output\WIMs\WinPE_Custom.wim" -Force