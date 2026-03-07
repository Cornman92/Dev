param(
    [string]$MountDir,
    [string]$ToolsDir
)

Copy-Item "$ToolsDir\*" "$MountDir\Tools\" -Recurse -Force
``