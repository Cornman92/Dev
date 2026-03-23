function Get-InstalledPrograms {
    [CmdletBinding()]
    param()

    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher | Where-Object { $_.DisplayName } | Sort-Object DisplayName
}
