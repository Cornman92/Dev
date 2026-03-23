$root = "D:\My-Win[PE][RE]"
$wim = "$root\Hybrid\base\boot.wim"
$mount = "$root\Hybrid\mount"

dism /Mount-WIM /WimFile:$wim /index:1 /MountDir:$mount

.\Inject-Drivers.ps1 -MountDir $mount -DriverDir "$root\Hybrid\drivers"
.\Add-Tools.ps1 -MountDir $mount -ToolsDir "$root\Hybrid\tools"

dism /Unmount-WIM /MountDir:$mount /Commit
Copy-Item $wim "$root\Output\WIMs\Hybrid_Custom.wim" -Force