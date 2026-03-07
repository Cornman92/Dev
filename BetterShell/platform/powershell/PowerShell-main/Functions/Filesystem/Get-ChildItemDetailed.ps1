function Get-ChildItemDetailed {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string]$Path = '.', [switch]$Force)

    Get-ChildItem @PSBoundParameters
}
