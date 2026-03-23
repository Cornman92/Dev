function Set-B11PasswordPolicy {
    [CmdletBinding(SupportsShouldProcess)] [OutputType([bool])]
    param([Parameter(Mandatory)] [int]$MinLength, [Parameter(Mandatory)] [bool]$Complexity, [Parameter(Mandatory)] [int]$MaxAgeDays)
    if (-not $PSCmdlet.ShouldProcess('Password Policy', "MinLen=$MinLength Complexity=$Complexity MaxAge=$MaxAgeDays")) { return $false }
    try {
        $null = net accounts /minpwlen:$MinLength /maxpwage:$MaxAgeDays 2>&1
        return $true
    } catch { Write-Error "Failed: $_"; return $false }
}
