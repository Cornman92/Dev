<#
.SYNOPSIS
    Finds duplicate files by comparing file hashes.
.DESCRIPTION
    This function searches for duplicate files in the specified path by comparing
    file hashes. It can use different hash algorithms and supports filtering by
    file size and extension.
.PARAMETER Path
    The directory to search for duplicate files.
.PARAMETER Recurse
    Search in subdirectories.
.PARAMETER Algorithm
    The hash algorithm to use (MD5, SHA1, SHA256, SHA384, SHA512).
.PARAMETER MinSizeMB
    Minimum file size in MB to consider.
.PARAMETER MaxSizeMB
    Maximum file size in MB to consider.
.PARAMETER IncludeExtension
    File extensions to include (e.g., '.jpg', '.png').
.PARAMETER ExcludeExtension
    File extensions to exclude.
.EXAMPLE
    Find-DuplicateFiles -Path "C:\Pictures" -Recurse -Algorithm SHA256 -MinSizeMB 1
    
    Finds duplicate files larger than 1MB using SHA256 hashing.
.OUTPUTS
    PSCustomObject[]
    Returns an array of objects containing information about duplicate files.
#>
function Find-DuplicateFiles {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $true, 
                 ValueFromPipeline = $true,
                 ValueFromPipelineByPropertyName = $true,
                 Position = 0)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Path '$_' does not exist or is not a directory."
            }
            $true
        })]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'SHA256',
        
        [Parameter()]
        [double]$MinSizeMB = 0,
        
        [Parameter()]
        [double]$MaxSizeMB = [double]::MaxValue,
        
        [Parameter()]
        [string[]]$IncludeExtension = @('*'),
        
        [Parameter()]
        [string[]]$ExcludeExtension = @()
    )
    
    begin {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $minBytes = [int]($MinSizeMB * 1MB)
        $maxBytes = if ($MaxSizeMB -eq [double]::MaxValue) { [long]::MaxValue } else { [int]($MaxSizeMB * 1MB) }
        $fileHashes = @{}
        $duplicates = @()
        
        # Initialize progress tracking
        $progressParams = @{
            Activity = 'Finding duplicate files'
            Status = 'Initializing...'
            PercentComplete = 0
        }
        
        # Create hash algorithm instance
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
        if (-not $hashAlgorithm) {
            throw "Unsupported hash algorithm: $Algorithm"
        }
        
        # Build filter for file extensions
        $includeFilter = $IncludeExtension | ForEach-Object { 
            if ($_ -eq '*') { '*' } 
            else { "*$($_.TrimStart('*'))" } 
        }
        
        $excludeFilter = $ExcludeExtension | ForEach-Object { 
            if ($_ -eq '*') { '*' } 
            else { "*$($_.TrimStart('*'))" } 
        }
    }
    
    process {
        try {
            # Get all files matching criteria
            $files = Get-ChildItem -Path $Path -Recurse:$Recurse -File | 
                    Where-Object { 
                        $_.Length -ge $minBytes -and 
                        $_.Length -le $maxBytes -and
                        ($IncludeExtension -contains '*' -or $_.Extension -in $includeFilter) -and
                        ($ExcludeExtension -notcontains '*' -and $_.Extension -notin $excludeFilter)
                    }
            
            $totalFiles = $files.Count
            $processed = 0
            
            # Process files and calculate hashes
            foreach ($file in $files) {
                $processed++
                $percentComplete = [math]::Min(99, [int](($processed / $totalFiles) * 100))
                $progressParams.Status = "Processing: $($file.Name)"
                $progressParams.PercentComplete = $percentComplete
                Write-Progress @progressParams
                
                try {
                    # Calculate file hash
                    $fileStream = [System.IO.File]::OpenRead($file.FullName)
                    $hashBytes = $hashAlgorithm.ComputeHash($fileStream)
                    $hashString = [BitConverter]::ToString($hashBytes).Replace('-', '')
                    
                    # Add to hash table
                    if (-not $fileHashes.ContainsKey($hashString)) {
                        $fileHashes[$hashString] = @()
                    }
                    
                    $fileHashes[$hashString] += [PSCustomObject]@{
                        Path = $file.FullName
                        Size = $file.Length
                        LastWriteTime = $file.LastWriteTime
                    }
                }
                catch {
                    Write-Warning "Failed to process file '$($file.FullName)': $_"
                }
                finally {
                    if ($fileStream) { $fileStream.Dispose() }
                }
            }
            
            # Find duplicates (files with the same hash)
            $duplicates = $fileHashes.GetEnumerator() | 
                Where-Object { $_.Value.Count -gt 1 } |
                ForEach-Object {
                    [PSCustomObject]@{
                        Hash = $_.Key
                        Files = $_.Value
                        Count = $_.Value.Count
                        TotalSize = ($_.Value | Measure-Object -Property Size -Sum).Sum
                    }
                } | Sort-Object -Property TotalSize -Descending
                
            # Output the results
            $duplicates | ForEach-Object {
                [PSCustomObject]@{
                    PSTypeName = 'FileSystem.DuplicateFile.Info'
                    Hash = $_.Hash
                    FileCount = $_.Count
                    TotalSize = $_.TotalSize
                    SizeMB = [math]::Round($_.TotalSize / 1MB, 2)
                    Files = $_.Files | Select-Object Path, @{
                        Name = 'SizeMB'; Expression = { [math]::Round($_.Size / 1MB, 2) }
                    }, LastWriteTime
                }
            }
        }
        catch {
            throw "Failed to find duplicate files: $_"
        }
        finally {
            # Clean up
            if ($hashAlgorithm) { $hashAlgorithm.Dispose() }
            Write-Progress -Activity 'Completed' -Completed
            $stopwatch.Stop()
            
            Write-Verbose "Processed $processed files in $($stopwatch.Elapsed.TotalSeconds) seconds"
            Write-Verbose "Found $($duplicates.Count) sets of duplicate files"
        }
    }
}

# Export the function
Export-ModuleMember -Function Find-DuplicateFiles
