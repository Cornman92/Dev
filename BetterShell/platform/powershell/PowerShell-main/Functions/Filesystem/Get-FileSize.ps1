function Get-FileSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path,
        [ValidateSet('KB','MB','GB','TB')]
        [string]$Unit = 'MB'
    )
    
    $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $item) {
        Write-Error "Path not found: $Path"
        return
    }
    
    $size = if ($item.PSIsContainer) {
        (Get-ChildItem -Path $Path -Recurse -File | Measure-Object -Property Length -Sum).Sum
    } else {
        $item.Length
    }
    
    $result = switch ($Unit) {
        'KB' { $size / 1KB; break }
        'MB' { $size / 1MB; break }
        'GB' { $size / 1GB; break }
        'TB' { $size / 1TB; break }
    }
    
    [math]::Round($result, 2)
}
