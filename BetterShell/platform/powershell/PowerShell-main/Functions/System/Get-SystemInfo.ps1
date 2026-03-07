function Get-SystemInfo {
    [CmdletBinding()]
    param()

    Get-ComputerInfo | Select-Object OSName, OSVersion, CsTotalPhysicalMemory, CsProcessorCount
}
