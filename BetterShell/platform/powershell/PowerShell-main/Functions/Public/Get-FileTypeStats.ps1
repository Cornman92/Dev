<#
.SYNOPSIS
    Gets statistics about file types in a directory.
.DESCRIPTION
    This function analyzes a directory and returns statistics about the file types it contains,
    including count, total size, and average size for each file extension.
.PARAMETER Path
    The path to the directory to analyze.
.PARAMETER Recurse
    If specified, includes all subdirectories in the analysis.
.PARAMETER Top
    Limits the results to the specified number of most common file types.
.EXAMPLE
    Get-FileTypeStats -Path "C:\Documents" -Recurse -Top 10
    Gets statistics for the top 10 most common file types in C:\Documents and all subdirectories.
.OUTPUTS
    PSCustomObject with file type statistics
#>
function Get-FileTypeStats {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Path '$_' does not exist or is not a directory."
            }
            $true
        })]
        [string]$Path,
        
        [switch]$Recurse,
        
        [int]$Top = 0
    )
    
    begin {
        # Resolve path to full path
        $Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
        
        # Initialize hashtable to store file type statistics
        $fileTypes = @{}
        $totalFiles = 0
        $totalSize = 0L
        $startTime = Get-Date
        
        Write-Verbose "Analyzing file types in '$Path' $(if ($Recurse) { '(recursively)' })"
    }
    
    process {
        try {
            # Get all files in the directory
            $files = Get-ChildItem -Path $Path -File -Recurse:$Recurse -Force -ErrorAction SilentlyContinue
            $fileCount = $files.Count
            
            Write-Progress -Activity 'Analyzing files' -Status "Found $fileCount files" -PercentComplete 0
            
            # Process each file
            for ($i = 0; $i -lt $fileCount; $i++) {
                $file = $files[$i]
                $extension = [System.IO.Path]::GetExtension($file.Name).ToLower()
                
                # Handle files without extension
                if ([string]::IsNullOrEmpty($extension)) {
                    $extension = "(no extension)"
                }
                
                # Initialize file type entry if it doesn't exist
                if (-not $fileTypes.ContainsKey($extension)) {
                    $fileTypes[$extension] = @{
                        Count = 0
                        TotalSize = 0L
                        MinSize = [long]::MaxValue
                        MaxSize = 0L
                    }
                }
                
                # Update statistics for this file type
                $fileSize = $file.Length
                $fileTypes[$extension].Count++
                $fileTypes[$extension].TotalSize += $fileSize
                
                if ($fileSize -lt $fileTypes[$extension].MinSize) {
                    $fileTypes[$extension].MinSize = $fileSize
                }
                
                if ($fileSize -gt $fileTypes[$extension].MaxSize) {
                    $fileTypes[$extension].MaxSize = $fileSize
                }
                
                # Update progress
                if (($i % 100) -eq 0) {
                    $percentComplete = [int](($i / $fileCount) * 100)
                    Write-Progress -Activity 'Analyzing files' -Status "Processed $i of $fileCount files" -PercentComplete $percentComplete
                }
                
                $totalFiles++
                $totalSize += $fileSize
            }
            
            # Convert hashtable to array of custom objects
            $results = foreach ($extension in $fileTypes.Keys) {
                $stats = $fileTypes[$extension]
                $avgSize = [math]::Round($stats.TotalSize / $stats.Count, 2)
                $percentage = [math]::Round(($stats.Count / $totalFiles) * 100, 2)
                $sizePercentage = [math]::Round(($stats.TotalSize / $totalSize) * 100, 2)
                
                [PSCustomObject]@{
                    Extension = $extension
                    Count = $stats.Count
                    Percentage = $percentage
                    TotalSize = $stats.TotalSize
                    TotalSizeMB = [math]::Round($stats.TotalSize / 1MB, 2)
                    SizePercentage = $sizePercentage
                    AverageSize = [math]::Round($avgSize / 1KB, 2)
                    AverageSizeUnit = 'KB'
                    MinSize = [math]::Round($stats.MinSize / 1KB, 2)
                    MinSizeUnit = 'KB'
                    MaxSize = [math]::Round($stats.MaxSize / 1MB, 2)
                    MaxSizeUnit = 'MB'
                }
            }
            
            # Sort by count (descending)
            $sortedResults = $results | Sort-Object -Property Count -Descending
            
            # Apply Top filter if specified
            if ($Top -gt 0) {
                $sortedResults = $sortedResults | Select-Object -First $Top
            }
            
            # Add summary information
            $endTime = Get-Date
            $duration = $endTime - $startTime
            
            $summary = [PSCustomObject]@{
                Path = $Path
                TotalFiles = $totalFiles
                TotalSize = $totalSize
                TotalSizeGB = [math]::Round($totalSize / 1GB, 2)
                UniqueFileTypes = $fileTypes.Count
                AnalysisDuration = $duration.TotalSeconds.ToString('0.00') + ' seconds'
                Timestamp = $endTime
            }
            
            # Return results with summary as a note property
            $sortedResults | Add-Member -MemberType NoteProperty -Name 'Summary' -Value $summary -Force
            
            return $sortedResults
        }
        catch {
            Write-Error "Error analyzing file types: $_"
            throw
        }
        finally {
            Write-Progress -Activity 'Analyzing files' -Completed
        }
    }
    
    end {
        Write-Verbose "File type analysis completed in $([math]::Round($duration.TotalSeconds, 2)) seconds"
    }
}
