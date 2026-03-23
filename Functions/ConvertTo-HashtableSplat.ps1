<#
.SYNOPSIS
    Converts named parameters into a hashtable for splatting.

.DESCRIPTION
    Takes a hashtable of parameters and removes any keys with $null
    values, making it easy to build clean splatting hashtables for
    cmdlet calls. Optionally filters to only include keys that match
    valid parameter names on a target command.

.PARAMETER Parameters
    A hashtable of parameter name/value pairs.

.PARAMETER CommandName
    Optional. If specified, filters the hashtable to only include
    keys that are valid parameter names for this command.

.PARAMETER RemoveEmpty
    If specified, also removes keys with empty string values.

.EXAMPLE
    $params = @{ Path = "C:\Temp"; Filter = $null; Recurse = $true }
    $splat = ConvertTo-HashtableSplat -Parameters $params
    Get-ChildItem @splat
    # Results in: Get-ChildItem -Path "C:\Temp" -Recurse

.EXAMPLE
    $params = @{ Path = "C:\Temp"; Recurse = $true; FakeParam = "test" }
    $splat = ConvertTo-HashtableSplat -Parameters $params -CommandName 'Get-ChildItem'
    # $splat only contains Path and Recurse (FakeParam is filtered out)

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
function ConvertTo-HashtableSplat {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [hashtable]$Parameters,

        [Parameter()]
        [string]$CommandName,

        [Parameter()]
        [switch]$RemoveEmpty
    )

    $result = @{}

    # Get valid parameter names if a command is specified
    $validParams = $null
    if ($CommandName) {
        $cmdInfo = Get-Command $CommandName -ErrorAction SilentlyContinue
        if ($cmdInfo) {
            $validParams = $cmdInfo.Parameters.Keys
        }
        else {
            Write-Warning "Command '$CommandName' not found. Skipping parameter validation."
        }
    }

    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]

        # Skip null values
        if ($null -eq $value) { continue }

        # Skip empty strings if requested
        if ($RemoveEmpty -and $value -is [string] -and [string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        # Skip parameters not valid for the target command
        if ($validParams -and $key -notin $validParams) { continue }

        $result[$key] = $value
    }

    return $result
}
