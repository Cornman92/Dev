$root = "D:\My-Win[PE][RE]"
$wim = "$root\WinRE\base\boot.wim"
$mount = "$root\WinRE\mount"

dism /Mount-WIM /WimFile:$wim /index:1 /MountDir:$mount

.\Inject-Drivers.ps1 -MountDir $mount -DriverDir "$root\WinRE\drivers"
.\Add-Tools.ps1 -MountDir $mount -ToolsDir "$root\WinRE\tools"

dism /Unmount-WIM /MountDir:$mount /Commit
Copy-Item $wim "$root\Output\WIMs\WinRE_Custom.wim" -Force