function Move-Up {
    [CmdletBinding()]
    param([int]$Level = 1)

    for ($i = 0; $i -lt $Level; $i++) {
        Set-Location ..
    }
}
