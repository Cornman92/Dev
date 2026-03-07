param(
    [string]$MountDir,
    [string]$ToolRoot = "D:\My-Win[PE][RE]"
)

$targets = @(
    "$MountDir\Windows\System32\Tools",
    "$MountDir\Windows\System32\Scripts",
    "$MountDir\Windows\System32\Modules",
    "$MountDir\Windows\System32\Menu"
)

foreach ($target in $targets) {
    New-Item -ItemType Directory -Force -Path $target
}

Copy-Item "$ToolRoot\WinPE\tools\*" "$MountDir\Windows\System32\Tools" -Recurse -Force
Copy-Item "$ToolRoot\WinPE\scripts\*" "$MountDir\Windows\System32\Scripts" -Recurse -Force
Copy-Item "$ToolRoot\WinPE\modules\*" "$MountDir\Windows\System32\Modules" -Recurse -Force

Write-Host "Tools and scripts integrated successfully."