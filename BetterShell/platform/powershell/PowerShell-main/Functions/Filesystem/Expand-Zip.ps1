function Expand-Zip {
    [CmdletBinding()]
    param([string]$ZipFile, [string]$Destination)

    Expand-Archive -Path $ZipFile -DestinationPath $Destination
}
