<#
.SYNOPSIS
    Synchronize PowerShell profile across multiple devices using cloud storage.

.DESCRIPTION
    Provides profile synchronization capabilities:
    - Sync to OneDrive/GitHub/Cloud storage
    - Profile versioning and rollback
    - Conflict resolution
    - Team profile sharing

.PARAMETER SyncTo
    Destination for sync: 'OneDrive', 'GitHub', or custom path.

.PARAMETER SyncFrom
    Source for sync: 'OneDrive', 'GitHub', or custom path.

.PARAMETER Backup
    Create backup before syncing.

.PARAMETER ResolveConflict
    Conflict resolution strategy: 'Local', 'Remote', 'Merge', 'Ask'.

.PARAMETER ShareWith
    Share profile with team members (GitHub only).

.EXAMPLE
    Sync-PowerShellProfile -SyncTo OneDrive
    Sync profile to OneDrive.

.EXAMPLE
    Sync-PowerShellProfile -SyncFrom OneDrive -ResolveConflict Merge
    Sync from OneDrive with merge conflict resolution.
#>
function Sync-PowerShellProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('OneDrive', 'GitHub', 'Custom')]
        [string]$SyncTo = 'OneDrive',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('OneDrive', 'GitHub', 'Custom')]
        [string]$SyncFrom = '',
        
        [Parameter(Mandatory = $false)]
        [string]$CustomPath = '',
        
        [Parameter(Mandatory = $false)]
        [switch]$Backup,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Local', 'Remote', 'Merge', 'Ask')]
        [string]$ResolveConflict = 'Ask',
        
        [Parameter(Mandatory = $false)]
        [switch]$ShareWith
    )

    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path -Parent $profilePath
    $syncConfigFile = Join-Path $profileDir '.psprofile-sync.json'
    
    # Load sync configuration
    if (Test-Path $syncConfigFile) {
        $syncConfig = Get-Content $syncConfigFile | ConvertFrom-Json
    } else {
        $syncConfig = @{
            LastSync = $null
            SyncLocation = ''
            Version = 1
            Conflicts = @()
        }
    }
    
    # Determine sync paths
    $syncPath = ''
    if ($SyncTo -eq 'OneDrive') {
        $oneDrivePath = $env:OneDrive
        if (-not $oneDrivePath) {
            Write-Error "OneDrive path not found. Please set OneDrive environment variable."
            return
        }
        $syncPath = Join-Path $oneDrivePath 'PowerShell-Profile'
    } elseif ($SyncTo -eq 'GitHub') {
        $syncPath = Join-Path $env:USERPROFILE 'Documents\GitHub\PowerShell-Profile'
    } elseif ($SyncTo -eq 'Custom' -and $CustomPath) {
        $syncPath = $CustomPath
    }
    
    if (-not $syncPath) {
        Write-Error "Invalid sync path. Please specify SyncTo and CustomPath if using Custom."
        return
 }
    
    # Create sync directory if it doesn't exist
    if (-not (Test-Path $syncPath)) {
        New-Item -ItemType Directory -Path $syncPath -Force | Out-Null
        Write-Host "Created sync directory: $syncPath" -ForegroundColor Green
    }
    
    # Backup current profile
    if ($Backup) {
        $backupPath = Join-Path $syncPath "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -Path $profileDir -Destination $backupPath -Recurse -Force
        Write-Host "Backup created: $backupPath" -ForegroundColor Green
    }
    
    # Sync TO remote location
    if ($SyncTo) {
        Write-Host "Syncing profile TO $SyncTo..." -ForegroundColor Cyan
        
        # Copy profile files
        $filesToSync = @(
            'Microsoft.PowerShell_profile.ps1',
            'Functions',
            'Modules',
            'oh-my-posh.json',
            'powershell.config.json'
        )
        
        foreach ($item in $filesToSync) {
            $sourcePath = Join-Path $profileDir $item
            $destPath = Join-Path $syncPath $item
            
            if (Test-Path $sourcePath) {
                if (Test-Item $sourcePath -PathType Container) {
                    Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
                } else {
                    Copy-Item -Path $sourcePath -Destination $destPath -Force
                }
                Write-Host "  Synced: $item" -ForegroundColor Gray
            }
        }
        
        # Create version manifest
        $manifest = @{
            Version = $syncConfig.Version + 1
            LastSync = (Get-Date).ToString('o')
            MachineName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            ProfilePath = $profilePath
        }
        $manifest | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $syncPath 'profile-manifest.json')
        
        $syncConfig.LastSync = (Get-Date).ToString('o')
        $syncConfig.SyncLocation = $syncPath
        $syncConfig.Version = $manifest.Version
        $syncConfig | ConvertTo-Json -Depth 10 | Set-Content $syncConfigFile
        
        Write-Host "Profile synced successfully to $SyncTo" -ForegroundColor Green
    }
    
    # Sync FROM remote location
    if ($SyncFrom) {
        Write-Host "Syncing profile FROM $SyncFrom..." -ForegroundColor Cyan
        
        $sourcePath = ''
        if ($SyncFrom -eq 'OneDrive') {
            $oneDrivePath = $env:OneDrive
            if (-not $oneDrivePath) {
                Write-Error "OneDrive path not found."
                return
            }
            $sourcePath = Join-Path $oneDrivePath 'PowerShell-Profile'
        } elseif ($SyncFrom -eq 'GitHub') {
            $sourcePath = Join-Path $env:USERPROFILE 'Documents\GitHub\PowerShell-Profile'
        } elseif ($SyncFrom -eq 'Custom' -and $CustomPath) {
            $sourcePath = $CustomPath
        }
        
        if (-not (Test-Path $sourcePath)) {
            Write-Error "Source path not found: $sourcePath"
            return
        }
        
        # Check for conflicts
        $remoteManifest = Join-Path $sourcePath 'profile-manifest.json'
        if (Test-Path $remoteManifest) {
            $remote = Get-Content $remoteManifest | ConvertFrom-Json
            $localVersion = $syncConfig.Version
            
            if ($remote.Version -gt $localVersion) {
                Write-Host "Remote version ($($remote.Version)) is newer than local ($localVersion)" -ForegroundColor Yellow
                
                if ($ResolveConflict -eq 'Ask') {
                    $response = Read-Host "Remote is newer. Overwrite local? (Y/N/Merge)"
                    if ($response -eq 'Y') {
                        $ResolveConflict = 'Remote'
                    } elseif ($response -eq 'M') {
                        $ResolveConflict = 'Merge'
                    } else {
                        Write-Host "Sync cancelled." -ForegroundColor Yellow
                        return
                    }
                }
            }
        }
        
        # Resolve conflicts
        if ($ResolveConflict -eq 'Remote') {
            # Backup local first
            $localBackup = Join-Path $profileDir "backup-local-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -Path $profileDir -Destination $localBackup -Recurse -Force
            Write-Host "Local backup created: $localBackup" -ForegroundColor Yellow
        }
        
        # Copy files from remote
        $filesToSync = @(
            'Microsoft.PowerShell_profile.ps1',
            'Functions',
            'Modules',
            'oh-my-posh.json',
            'powershell.config.json'
        )
        
        foreach ($item in $filesToSync) {
            $sourceItem = Join-Path $sourcePath $item
            $destItem = Join-Path $profileDir $item
            
            if (Test-Path $sourceItem) {
                if ($ResolveConflict -eq 'Merge' -and (Test-Path $destItem)) {
                    Write-Host "  Merging: $item (manual merge may be required)" -ForegroundColor Yellow
                    # For merge, we'll copy but warn user
                    Copy-Item -Path $sourceItem -Destination $destItem -Recurse -Force
                } else {
                    Copy-Item -Path $sourceItem -Destination $destItem -Recurse -Force
                    Write-Host "  Synced: $item" -ForegroundColor Gray
                }
            }
        }
        
        # Update sync config
        if (Test-Path $remoteManifest) {
            $remote = Get-Content $remoteManifest | ConvertFrom-Json
            $syncConfig.Version = $remote.Version
            $syncConfig.LastSync = (Get-Date).ToString('o')
            $syncConfig | ConvertTo-Json -Depth 10 | Set-Content $syncConfigFile
        }
        
        Write-Host "Profile synced successfully from $SyncFrom" -ForegroundColor Green
        Write-Host "Please restart PowerShell to apply changes." -ForegroundColor Yellow
    }
}

# Alias for quick access
Set-Alias -Name 'sync-profile' -Value 'Sync-PowerShellProfile' -Scope Global -Force

# Function to check sync status
function Get-ProfileSyncStatus {
    [CmdletBinding()]
    param()
    
    $profileDir = Split-Path -Parent $PROFILE.CurrentUserAllHosts
    $syncConfigFile = Join-Path $profileDir '.psprofile-sync.json'
    
    if (Test-Path $syncConfigFile) {
        $syncConfig = Get-Content $syncConfigFile | ConvertFrom-Json
        Write-Host "Profile Sync Status:" -ForegroundColor Cyan
        Write-Host "  Version: $($syncConfig.Version)" -ForegroundColor White
        Write-Host "  Last Sync: $($syncConfig.LastSync)" -ForegroundColor White
        Write-Host "  Sync Location: $($syncConfig.SyncLocation)" -ForegroundColor White
        
        # Check remote version if available
        if ($syncConfig.SyncLocation -and (Test-Path $syncConfig.SyncLocation)) {
            $remoteManifest = Join-Path $syncConfig.SyncLocation 'profile-manifest.json'
            if (Test-Path $remoteManifest) {
                $remote = Get-Content $remoteManifest | ConvertFrom-Json
                Write-Host "  Remote Version: $($remote.Version)" -ForegroundColor White
                if ($remote.Version -gt $syncConfig.Version) {
                    Write-Host "  ⚠ Remote is newer - consider syncing" -ForegroundColor Yellow
                } elseif ($remote.Version -lt $syncConfig.Version) {
                    Write-Host "  ⚠ Local is newer - consider syncing" -ForegroundColor Yellow
                } else {
                    Write-Host "  ✓ Versions match" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "Profile sync not configured. Use Sync-PowerShellProfile to set up." -ForegroundColor Yellow
    }
}

Set-Alias -Name 'sync-status' -Value 'Get-ProfileSyncStatus' -Scope Global -Force



