<#
.SYNOPSIS
    Computes file hashes for one or more files or an entire directory.

.DESCRIPTION
    Wraps Get-FileHash to support batch operations on directories,
    multiple paths, and wildcard patterns. Returns a structured list
    of file paths, hash values, and algorithms.

.PARAMETER Path
    One or more file or directory paths. Supports wildcards.

.PARAMETER Algorithm
    Hashing algorithm to use. Defaults to SHA256.
    Valid: SHA1, SHA256, SHA384, SHA512, MD5.

.PARAMETER Recurse
    If a directory is specified, include files in subdirectories.

.PARAMETER Filter
    Optional wildcard filter for file names (e.g., "*.ps1").

.EXAMPLE
    Get-FileHashBatch -Path "C:\Dev\Scripts"
    Hashes all files in the Scripts directory.

.EXAMPLE
    Get-FileHashBatch -Path "C:\Dev\Functions" -Filter "*.ps1" -Recurse
    Hashes all .ps1 files recursively.

.EXAMPLE
    Get-FileHashBatch -Path "C:\Dev\README.md" -Algorithm MD5
    Returns the MD5 hash of a single file.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
function Get-FileHashBatch {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$Path,

        [Parameter()]
        [ValidateSet('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')]
        [string]$Algorithm = 'SHA256',

        [Parameter()]
        [switch]$Recurse,

        [Parameter()]
        [string]$Filter
    )

    begin {
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        foreach ($item in $Path) {
            $resolvedPaths = Resolve-Path -Path $item -ErrorAction SilentlyContinue
            if (-not $resolvedPaths) {
                Write-Warning "Path not found: $item"
                continue
            }

            foreach ($resolved in $resolvedPaths) {
                $fullPath = $resolved.ProviderPath

                if (Test-Path $fullPath -PathType Container) {
                    # Directory: get child files
                    $gciParams = @{
                        Path = $fullPath
                        File = $true
                    }
                    if ($Recurse) { $gciParams['Recurse'] = $true }
                    if ($Filter)  { $gciParams['Filter'] = $Filter }

                    $files = Get-ChildItem @gciParams
                }
                else {
                    # Single file
                    $files = Get-Item $fullPath
                }

                foreach ($file in $files) {
                    try {
                        $hash = Get-FileHash -Path $file.FullName -Algorithm $Algorithm
                        $results.Add([PSCustomObject]@{
                            Path      = $file.FullName
                            Name      = $file.Name
                            Algorithm = $hash.Algorithm
                            Hash      = $hash.Hash
                            SizeKB    = [math]::Round($file.Length / 1KB, 2)
                        })
                    }
                    catch {
                        Write-Warning "Failed to hash $($file.FullName): $_"
                    }
                }
            }
        }
    }

    end {
        return $results
    }
}
