<#
.SYNOPSIS
    Compares two files and returns the differences.
.DESCRIPTION
    This function compares two files and returns an object that represents the differences
    between them. It can compare file content, size, and timestamps.
.PARAMETER Path1
    The path to the first file to compare.
.PARAMETER Path2
    The path to the second file to compare.
.PARAMETER CompareContent
    If specified, performs a byte-by-byte comparison of file contents.
    If not specified, only file metadata (size, timestamps) is compared.
.EXAMPLE
    Compare-File -Path1 "C:\file1.txt" -Path2 "C:\file2.txt" -CompareContent
    Compares both metadata and content of the two files.
.OUTPUTS
    PSCustomObject with comparison results
#>
function Compare-File {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "File '$_' does not exist or is not a file."
            }
            $true
        })]
        [string]$Path1,
        
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "File '$_' does not exist or is not a file."
            }
            $true
        })]
        [string]$Path2,
        
        [switch]$CompareContent
    )
    
    begin {
        # Resolve paths to full paths
        $Path1 = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path1)
        $Path2 = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path2)
        
        # Get file information
        $file1 = Get-Item -Path $Path1 -Force
        $file2 = Get-Item -Path $Path2 -Force
        
        # Initialize result object
        $result = [PSCustomObject]@{
            Path1 = $Path1
            Path2 = $Path2
            Match = $false
            Differences = @()
            SizeMatch = $false
            LastWriteTimeMatch = $false
            ContentMatch = $null  # Will be $true, $false, or $null if not compared
        }
    }
    
    process {
        try {
            # Compare basic properties
            $result.SizeMatch = ($file1.Length -eq $file2.Length)
            $result.LastWriteTimeMatch = ($file1.LastWriteTime -eq $file2.LastWriteTime)
            
            # If sizes don't match, files are definitely different
            if (-not $result.SizeMatch) {
                $result.Differences += "File sizes differ: $($file1.Length) bytes vs $($file2.Length) bytes"
            }
            
            # Compare content if requested and sizes match
            if ($CompareContent) {
                if ($result.SizeMatch) {
                    # Compare file hashes for content comparison
                    $hash1 = Get-FileHash -Path $Path1 -Algorithm SHA256
                    $hash2 = Get-FileHash -Path $Path2 -Algorithm SHA256
                    $result.ContentMatch = ($hash1.Hash -eq $hash2.Hash)
                    
                    if (-not $result.ContentMatch) {
                        $result.Differences += "File contents are different (SHA256 hash comparison)"
                    }
                } else {
                    $result.ContentMatch = $false
                    $result.Differences += "Skipped content comparison due to different file sizes"
                }
            }
            
            # Determine overall match
            $result.Match = $result.SizeMatch -and 
                           $result.LastWriteTimeMatch -and 
                           ($null -eq $result.ContentMatch -or $result.ContentMatch)
            
            # If no differences found but we compared content, add a note
            if ($result.Match -and $CompareContent -and $result.Differences.Count -eq 0) {
                $result.Differences += "Files are identical"
            }
            
            return $result
        }
        catch {
            Write-Error "Error comparing files: $_"
            throw
        }
    }
}
