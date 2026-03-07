function Compress-Folder {
    [CmdletBinding()]
    param([string]$Source, [string]$Destination)

    Compress-Archive -Path $Source -DestinationPath $Destination
}
