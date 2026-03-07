<#
.SYNOPSIS
    Synchronizes the contents of two directories.
.DESCRIPTION
    This function synchronizes the contents of a source directory to a destination directory.
    It can perform one-way or two-way synchronization and includes options for filtering and logging.
.PARAMETER SourcePath
    The path to the source directory.
.PARAMETER DestinationPath
    The path to the destination directory.
.PARAMETER Recurse
    If specified, synchronizes all subdirectories recursively.
.PARAMETER WhatIf
    Shows what would happen if the cmdlet runs without actually performing the synchronization.
.EXAMPLE
    Sync-Directory -SourcePath "C:\Source" -DestinationPath "D:\Backup" -Recurse
    Synchronizes all files and subdirectories from C:\Source to D:\Backup.
#>
function Sync-Directory {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Source path '$_' does not exist or is not a directory."
            }
            $true
        })]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        
        [switch]$Recurse,
        
        [switch]$Force,
        
        [switch]$WhatIf
    )
    
    begin {
        # Resolve paths to full paths
        $SourcePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($SourcePath)
        $DestinationPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($DestinationPath)
        
        # Ensure source exists
        if (-not (Test-Path -Path $SourcePath -PathType Container)) {
            throw "Source directory '$SourcePath' does not exist or is not a directory."
        }
        
        # Create destination if it doesn't exist
        if (-not (Test-Path -Path $DestinationPath)) {
            if ($PSCmdlet.ShouldProcess($DestinationPath, 'Create destination directory')) {
                try {
                    $null = New-Item -Path $DestinationPath -ItemType Directory -Force:$Force -ErrorAction Stop
                    Write-Verbose "Created destination directory: $DestinationPath"
                }
                catch {
                    throw "Failed to create destination directory '$DestinationPath': $_"
                }
            }
        }
        
        # Initialize counters
        $stats = [PSCustomObject]@{
            FilesCopied = 0
            FilesUpdated = 0
            FilesSkipped = 0
            DirectoriesCreated = 0
            Errors = 0
            StartTime = Get-Date
            EndTime = $null
        }
        
        Write-Verbose "Starting directory synchronization from '$SourcePath' to '$DestinationPath'"
    }
    
    process {
        try {
            # Get all items in source directory
            $sourceItems = Get-ChildItem -Path $SourcePath -Force
            $destItems = @{}
            
            # Create hashtable of destination items for faster lookup
            if (Test-Path -Path $DestinationPath) {
                Get-ChildItem -Path $DestinationPath -Force | ForEach-Object {
                    $destItems[$_.Name] = $_
                }
            }
            
            # Process each item in source
            foreach ($item in $sourceItems) {
                $destPath = Join-Path -Path $DestinationPath -ChildPath $item.Name
                
                if ($item.PSIsContainer) {
                    # Handle directories
                    if ($Recurse) {
                        # Recursively sync subdirectories
                        if ($PSCmdlet.ShouldProcess($destPath, 'Synchronize directory')) {
                            try {
                                $syncParams = @{
                                    SourcePath = $item.FullName
                                    DestinationPath = $destPath
                                    Recurse = $true
                                    Force = $Force
                                    WhatIf = $WhatIf
                                    Verbose = $VerbosePreference
                                    ErrorAction = 'Stop'
                                }
                                $subStats = Sync-Directory @syncParams
                                
                                # Update statistics
                                $stats.FilesCopied += $subStats.FilesCopied
                                $stats.FilesUpdated += $subStats.FilesUpdated
                                $stats.FilesSkipped += $subStats.FilesSkipped
                                $stats.DirectoriesCreated += $subStats.DirectoriesCreated + 1
                                $stats.Errors += $subStats.Errors
                            }
                            catch {
                                $stats.Errors++
                                Write-Error "Failed to synchronize directory '$($item.FullName)': $_"
                            }
                        }
                    }
                }
                else {
                    # Handle files
                    $shouldCopy = $false
                    $operation = 'Skipped'
                    
                    if (-not $destItems.ContainsKey($item.Name)) {
                        # File doesn't exist in destination
                        $shouldCopy = $true
                        $operation = 'Copy'
                    }
                    else {
                        # File exists, check if it needs updating
                        $destItem = $destItems[$item.Name]
                        $sourceLastWrite = $item.LastWriteTime
                        $destLastWrite = $destItem.LastWriteTime
                        
                        if ($sourceLastWrite -gt $destLastWrite -or 
                            $item.Length -ne $destItem.Length) {
                            $shouldCopy = $true
                            $operation = 'Update'
                        }
                    }
                    
                    if ($shouldCopy) {
                        if ($PSCmdlet.ShouldProcess($destPath, "$operation file")) {
                            try {
                                Copy-Item -Path $item.FullName -Destination $destPath -Force:$Force -ErrorAction Stop
                                
                                # Update statistics
                                if ($operation -eq 'Copy') {
                                    $stats.FilesCopied++
                                    Write-Verbose "Copied: $($item.FullName) -> $destPath"
                                }
                                else {
                                    $stats.FilesUpdated++
                                    Write-Verbose "Updated: $($item.FullName) -> $destPath"
                                }
                            }
                            catch {
                                $stats.Errors++
                                Write-Error "Failed to $($operation.ToLower()) file '$($item.FullName)': $_"
                            }
                        }
                    }
                    else {
                        $stats.FilesSkipped++
                        Write-Verbose "Skipped (up to date): $($item.FullName)"
                    }
                }
            }
            
            return $stats
        }
        catch {
            $stats.Errors++
            Write-Error "Error during synchronization: $_"
            throw
        }
    }
    
    end {
        # Update end time
        $stats.EndTime = Get-Date
        $stats.Duration = $stats.EndTime - $stats.StartTime
        
        # Output summary
        Write-Verbose "Synchronization completed in $($stats.Duration.TotalSeconds.ToString('0.00')) seconds"
        Write-Verbose "  Files copied: $($stats.FilesCopied)"
        Write-Verbose "  Files updated: $($stats.FilesUpdated)"
        Write-Verbose "  Files skipped: $($stats.FilesSkipped)"
        Write-Verbose "  Directories created: $($stats.DirectoriesCreated)"
        Write-Verbose "  Errors: $($stats.Errors)"
        
        return $stats
    }
}
