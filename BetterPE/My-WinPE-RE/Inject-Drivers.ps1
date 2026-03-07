param(
    [string]$MountDir,
    [string]$DriverDir
)

Get-ChildItem $DriverDir -Recurse -Filter *.inf | ForEach-Object {
    dism /Image:$MountDir /Add-Driver /Driver:$_.FullName /ForceUnsigned
}

### Usage: ###
###.\Inject-Drivers.ps1 -MountDir D:\My-Win[PE][RE]\WinPE\mount -DriverDir D:\My-Win[PE][RE]\WinPE\drivers\   ####