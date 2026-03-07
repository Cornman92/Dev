#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Safe Registry Management Module for Better11 Suite
.DESCRIPTION
    Comprehensive registry operations with backup, validation, and safety features
.AUTHOR
    Better11 Development Team
.VERSION
    1.0.0
#>

#region Registry Safety

$Script:BackupPath = "$env:USERPROFILE\Documents\RegistryBackups"
$Script:DangerousKeys = @(
    'HKLM:\SAM',
    'HKLM:\SECURITY',
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
)

function Test-RegistryKeyDangerous {
    [CmdletBinding()]
    param(
        [string]$Path
    )
    
    foreach ($dangerousKey in $Script:DangerousKeys) {
        if ($Path -like "$dangerousKey*") {
            return $true
        }
    }
    
    return $false
}

function Initialize-RegistryBackupSystem {
    <#
    .SYNOPSIS
        Initializes the registry backup system
    .EXAMPLE
        Initialize-RegistryBackupSystem
    #>
    [CmdletBinding()]
    param(
        [string]$BackupPath = "$env:USERPROFILE\Documents\RegistryBackups"
    )
    
    $Script:BackupPath = $BackupPath
    
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        Write-Host "✓ Created backup directory: $BackupPath" -ForegroundColor Green
    }
    
    # Create backup index
    $indexPath = Join-Path $BackupPath "index.json"
    if (-not (Test-Path $indexPath)) {
        @{
            Backups = @()
            LastBackup = $null
        } | ConvertTo-Json | Out-File -FilePath $indexPath -Encoding UTF8
    }
    
    return $BackupPath
}

#endregion

#region Registry Backup & Restore

function Backup-RegistryKey {
    <#
    .SYNOPSIS
        Creates a backup of a registry key
    .DESCRIPTION
        Exports registry key to .reg file with metadata
    .EXAMPLE
        Backup-RegistryKey -Path "HKLM:\SOFTWARE\MyApp" -Description "Before update"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string]$Description,
        [switch]$Recursive
    )
    
    if (-not (Test-Path $Script:BackupPath)) {
        Initialize-RegistryBackupSystem
    }
    
    # Validate path
    if (-not (Test-Path $Path)) {
        throw "Registry key not found: $Path"
    }
    
    if (Test-RegistryKeyDangerous -Path $Path) {
        throw "Cannot backup dangerous registry key: $Path"
    }
    
    # Generate backup filename
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $safeName = ($Path -replace '[\\/:*?"<>|]', '_')
    $backupFile = Join-Path $Script:BackupPath "$safeName`_$timestamp.reg"
    
    try {
        # Convert PowerShell path to registry path
        $regPath = $Path -replace 'HKLM:', 'HKEY_LOCAL_MACHINE' `
                           -replace 'HKCU:', 'HKEY_CURRENT_USER' `
                           -replace 'HKCR:', 'HKEY_CLASSES_ROOT' `
                           -replace 'HKU:', 'HKEY_USERS' `
                           -replace 'HKCC:', 'HKEY_CURRENT_CONFIG'
        
        # Export registry key
        $args = @('export', $regPath, $backupFile)
        if (-not $Recursive) { $args += '/y' }
        
        & reg.exe @args | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            throw "Registry export failed with exit code: $LASTEXITCODE"
        }
        
        # Create metadata
        $metadata = [PSCustomObject]@{
            BackupId = [guid]::NewGuid().ToString()
            Timestamp = Get-Date
            RegistryPath = $Path
            BackupFile = $backupFile
            Description = $Description
            Size = (Get-Item $backupFile).Length
            Recursive = $Recursive
        }
        
        # Update index
        $indexPath = Join-Path $Script:BackupPath "index.json"
        $index = Get-Content $indexPath | ConvertFrom-Json
        $index.Backups += $metadata
        $index.LastBackup = $metadata.Timestamp
        $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding UTF8
        
        Write-Host "✓ Backed up: $Path" -ForegroundColor Green
        Write-Host "  File: $backupFile" -ForegroundColor Gray
        
        return $metadata
    }
    catch {
        Write-Error "Failed to backup registry key: $_"
        return $null
    }
}

function Restore-RegistryKey {
    <#
    .SYNOPSIS
        Restores a registry key from backup
    .EXAMPLE
        Restore-RegistryKey -BackupId "abc123..."
    .EXAMPLE
        Get-RegistryBackup -Path "HKLM:\SOFTWARE\MyApp" | Restore-RegistryKey
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$BackupId,
        
        [switch]$Force
    )
    
    process {
        $indexPath = Join-Path $Script:BackupPath "index.json"
        
        if (-not (Test-Path $indexPath)) {
            throw "Backup index not found"
        }
        
        $index = Get-Content $indexPath | ConvertFrom-Json
        $backup = $index.Backups | Where-Object BackupId -eq $BackupId | Select-Object -First 1
        
        if (-not $backup) {
            throw "Backup not found: $BackupId"
        }
        
        if (-not (Test-Path $backup.BackupFile)) {
            throw "Backup file not found: $($backup.BackupFile)"
        }
        
        if ($PSCmdlet.ShouldProcess($backup.RegistryPath, "Restore from backup")) {
            try {
                # Import registry key
                & reg.exe import $backup.BackupFile | Out-Null
                
                if ($LASTEXITCODE -ne 0) {
                    throw "Registry import failed with exit code: $LASTEXITCODE"
                }
                
                Write-Host "✓ Restored: $($backup.RegistryPath)" -ForegroundColor Green
                Write-Host "  From: $($backup.BackupFile)" -ForegroundColor Gray
                
                return $true
            }
            catch {
                Write-Error "Failed to restore registry key: $_"
                return $false
            }
        }
    }
}

function Get-RegistryBackup {
    <#
    .SYNOPSIS
        Lists available registry backups
    .EXAMPLE
        Get-RegistryBackup -Path "HKLM:\SOFTWARE\MyApp"
    .EXAMPLE
        Get-RegistryBackup -Since (Get-Date).AddDays(-7)
    #>
    [CmdletBinding()]
    param(
        [string]$Path,
        [datetime]$Since,
        [datetime]$Before,
        [int]$Last = 0
    )
    
    $indexPath = Join-Path $Script:BackupPath "index.json"
    
    if (-not (Test-Path $indexPath)) {
        return @()
    }
    
    $index = Get-Content $indexPath | ConvertFrom-Json
    $backups = $index.Backups
    
    if ($Path) {
        $backups = $backups | Where-Object RegistryPath -eq $Path
    }
    
    if ($Since) {
        $backups = $backups | Where-Object { [datetime]$_.Timestamp -ge $Since }
    }
    
    if ($Before) {
        $backups = $backups | Where-Object { [datetime]$_.Timestamp -le $Before }
    }
    
    if ($Last -gt 0) {
        $backups = $backups | Sort-Object Timestamp -Descending | Select-Object -First $Last
    }
    
    return $backups
}

function Remove-RegistryBackup {
    <#
    .SYNOPSIS
        Removes old registry backups
    .EXAMPLE
        Remove-RegistryBackup -OlderThan 30
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [int]$OlderThan = 90,
        [string]$BackupId
    )
    
    $indexPath = Join-Path $Script:BackupPath "index.json"
    
    if (-not (Test-Path $indexPath)) {
        return
    }
    
    $index = Get-Content $indexPath | ConvertFrom-Json
    
    if ($BackupId) {
        $toRemove = $index.Backups | Where-Object BackupId -eq $BackupId
    }
    else {
        $cutoff = (Get-Date).AddDays(-$OlderThan)
        $toRemove = $index.Backups | Where-Object { [datetime]$_.Timestamp -lt $cutoff }
    }
    
    foreach ($backup in $toRemove) {
        if ($PSCmdlet.ShouldProcess($backup.RegistryPath, "Remove backup")) {
            if (Test-Path $backup.BackupFile) {
                Remove-Item $backup.BackupFile -Force
            }
            $index.Backups = $index.Backups | Where-Object BackupId -ne $backup.BackupId
            Write-Host "✓ Removed backup: $($backup.BackupFile)" -ForegroundColor Yellow
        }
    }
    
    $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding UTF8
}

#endregion

#region Registry Operations

function Get-RegistryKeyValue {
    <#
    .SYNOPSIS
        Gets registry key values with detailed information
    .EXAMPLE
        Get-RegistryKeyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [string]$Name,
        [switch]$Recurse
    )
    
    if (-not (Test-Path $Path)) {
        Write-Error "Registry key not found: $Path"
        return
    }
    
    try {
        $key = Get-Item $Path
        
        if ($Name) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            
            return [PSCustomObject]@{
                Path = $Path
                Name = $Name
                Value = $value.$Name
                Type = $key.GetValueKind($Name)
            }
        }
        else {
            $properties = Get-ItemProperty -Path $Path
            $values = @()
            
            foreach ($prop in $properties.PSObject.Properties) {
                if ($prop.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                    try {
                        $values += [PSCustomObject]@{
                            Path = $Path
                            Name = $prop.Name
                            Value = $prop.Value
                            Type = $key.GetValueKind($prop.Name)
                        }
                    }
                    catch {
                        # Skip properties that can't be retrieved
                    }
                }
            }
            
            if ($Recurse) {
                $childKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
                foreach ($childKey in $childKeys) {
                    $values += Get-RegistryKeyValue -Path $childKey.PSPath -Recurse
                }
            }
            
            return $values
        }
    }
    catch {
        Write-Error "Failed to get registry value: $_"
    }
}

function Set-RegistryKeyValue {
    <#
    .SYNOPSIS
        Sets a registry value with automatic backup
    .EXAMPLE
        Set-RegistryKeyValue -Path "HKCU:\Software\MyApp" -Name "Setting" -Value "Enabled" -Type String
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [object]$Value,
        
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'QWord', 'MultiString')]
        [string]$Type = 'String',
        
        [switch]$Force,
        [switch]$NoBackup
    )
    
    if (Test-RegistryKeyDangerous -Path $Path) {
        throw "Cannot modify dangerous registry key: $Path"
    }
    
    # Create backup unless explicitly disabled
    if (-not $NoBackup) {
        $backup = Backup-RegistryKey -Path $Path -Description "Before setting $Name"
        if (-not $backup) {
            Write-Warning "Backup failed. Continue? (Use -Force to override)"
            if (-not $Force) {
                return
            }
        }
    }
    
    # Create key if it doesn't exist
    if (-not (Test-Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Create registry key")) {
            New-Item -Path $Path -Force | Out-Null
        }
    }
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set value to: $Value")) {
        try {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
            Write-Host "✓ Set: $Path\$Name = $Value" -ForegroundColor Green
            
            return [PSCustomObject]@{
                Path = $Path
                Name = $Name
                Value = $Value
                Type = $Type
                BackupId = if ($backup) { $backup.BackupId } else { $null }
                Success = $true
            }
        }
        catch {
            Write-Error "Failed to set registry value: $_"
            
            # Attempt restore if backup exists
            if ($backup -and -not $NoBackup) {
                Write-Host "Attempting to restore from backup..." -ForegroundColor Yellow
                Restore-RegistryKey -BackupId $backup.BackupId -Force
            }
            
            return [PSCustomObject]@{
                Path = $Path
                Name = $Name
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
}

function Remove-RegistryKeyValue {
    <#
    .SYNOPSIS
        Removes a registry value with automatic backup
    .EXAMPLE
        Remove-RegistryKeyValue -Path "HKCU:\Software\MyApp" -Name "OldSetting"
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [switch]$Force,
        [switch]$NoBackup
    )
    
    if (Test-RegistryKeyDangerous -Path $Path) {
        throw "Cannot modify dangerous registry key: $Path"
    }
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Registry key not found: $Path"
        return
    }
    
    # Create backup
    if (-not $NoBackup) {
        $backup = Backup-RegistryKey -Path $Path -Description "Before removing $Name"
    }
    
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Remove value")) {
        try {
            Remove-ItemProperty -Path $Path -Name $Name -Force
            Write-Host "✓ Removed: $Path\$Name" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to remove registry value: $_"
            
            # Restore if backup exists
            if ($backup) {
                Restore-RegistryKey -BackupId $backup.BackupId -Force
            }
            
            return $false
        }
    }
}

function New-RegistryKey {
    <#
    .SYNOPSIS
        Creates a new registry key
    .EXAMPLE
        New-RegistryKey -Path "HKCU:\Software\MyApp\Settings"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$Force
    )
    
    if (Test-Path $Path) {
        Write-Warning "Registry key already exists: $Path"
        return
    }
    
    if ($PSCmdlet.ShouldProcess($Path, "Create registry key")) {
        try {
            New-Item -Path $Path -Force:$Force | Out-Null
            Write-Host "✓ Created: $Path" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to create registry key: $_"
            return $false
        }
    }
}

function Remove-RegistryKey {
    <#
    .SYNOPSIS
        Removes a registry key with automatic backup
    .EXAMPLE
        Remove-RegistryKey -Path "HKCU:\Software\MyApp" -Recurse
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [switch]$Recurse,
        [switch]$Force,
        [switch]$NoBackup
    )
    
    if (Test-RegistryKeyDangerous -Path $Path) {
        throw "Cannot remove dangerous registry key: $Path"
    }
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Registry key not found: $Path"
        return
    }
    
    # Create backup
    if (-not $NoBackup) {
        $backup = Backup-RegistryKey -Path $Path -Description "Before removing key" -Recursive:$Recurse
    }
    
    if ($PSCmdlet.ShouldProcess($Path, "Remove registry key")) {
        try {
            Remove-Item -Path $Path -Recurse:$Recurse -Force:$Force
            Write-Host "✓ Removed: $Path" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to remove registry key: $_"
            
            # Restore if backup exists
            if ($backup) {
                Restore-RegistryKey -BackupId $backup.BackupId -Force
            }
            
            return $false
        }
    }
}

#endregion

#region Search & Analysis

function Search-Registry {
    <#
    .SYNOPSIS
        Searches the registry for keys or values
    .EXAMPLE
        Search-Registry -Pattern "MyApp" -SearchIn Both
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,
        
        [ValidateSet('Keys', 'Values', 'Both')]
        [string]$SearchIn = 'Both',
        
        [string]$RootPath = 'HKCU:\Software',
        
        [int]$MaxResults = 100
    )
    
    $results = @()
    $count = 0
    
    Write-Host "Searching registry for: $Pattern" -ForegroundColor Cyan
    
    function Search-RegistryRecursive {
        param($Path)
        
        if ($count -ge $MaxResults) { return }
        
        try {
            # Search key names
            if ($SearchIn -in @('Keys', 'Both')) {
                if ((Split-Path $Path -Leaf) -match $Pattern) {
                    $results += [PSCustomObject]@{
                        Type = 'Key'
                        Path = $Path
                        Match = Split-Path $Path -Leaf
                    }
                    $count++
                }
            }
            
            # Search values
            if ($SearchIn -in @('Values', 'Both')) {
                $values = Get-RegistryKeyValue -Path $Path
                foreach ($value in $values) {
                    if ($value.Name -match $Pattern -or $value.Value -match $Pattern) {
                        $results += [PSCustomObject]@{
                            Type = 'Value'
                            Path = $Path
                            Name = $value.Name
                            Value = $value.Value
                            Match = if ($value.Name -match $Pattern) { $value.Name } else { $value.Value }
                        }
                        $count++
                        
                        if ($count -ge $MaxResults) { return }
                    }
                }
            }
            
            # Recurse into subkeys
            $subKeys = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
            foreach ($subKey in $subKeys) {
                if ($count -ge $MaxResults) { return }
                Search-RegistryRecursive -Path $subKey.PSPath
            }
        }
        catch {
            # Skip inaccessible keys
        }
    }
    
    Search-RegistryRecursive -Path $RootPath
    
    Write-Host "Found $($results.Count) matches" -ForegroundColor Green
    return $results
}

function Export-RegistryReport {
    <#
    .SYNOPSIS
        Generates comprehensive registry report
    .EXAMPLE
        Export-RegistryReport -Path "HKCU:\Software\MyApp" -OutputPath .\report.html
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet('HTML', 'JSON', 'CSV')]
        [string]$Format = 'HTML'
    )
    
    $values = Get-RegistryKeyValue -Path $Path -Recurse
    
    $report = [PSCustomObject]@{
        Path = $Path
        GeneratedAt = Get-Date
        TotalValues = $values.Count
        Values = $values
    }
    
    switch ($Format) {
        'HTML' {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Registry Report - $Path</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; }
        h1 { color: #2c3e50; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #3498db; color: white; }
        .path { font-family: 'Consolas', monospace; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Registry Report</h1>
        <p><strong>Path:</strong> <span class="path">$Path</span></p>
        <p><strong>Generated:</strong> $($report.GeneratedAt)</p>
        <p><strong>Total Values:</strong> $($report.TotalValues)</p>
        
        <table>
            <tr>
                <th>Path</th>
                <th>Name</th>
                <th>Value</th>
                <th>Type</th>
            </tr>
            $(foreach ($v in $values) {
                "<tr><td class='path'>$($v.Path)</td><td>$($v.Name)</td><td>$($v.Value)</td><td>$($v.Type)</td></tr>"
            })
        </table>
    </div>
</body>
</html>
"@
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        'JSON' {
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        'CSV' {
            $values | Export-Csv -Path $OutputPath -NoTypeInformation
        }
    }
    
    Write-Host "✓ Report exported to: $OutputPath" -ForegroundColor Green
}

#endregion

# Initialize backup system on module load
Initialize-RegistryBackupSystem | Out-Null

# Export module members
Export-ModuleMember -Function @(
    'Initialize-RegistryBackupSystem',
    'Backup-RegistryKey',
    'Restore-RegistryKey',
    'Get-RegistryBackup',
    'Remove-RegistryBackup',
    'Get-RegistryKeyValue',
    'Set-RegistryKeyValue',
    'Remove-RegistryKeyValue',
    'New-RegistryKey',
    'Remove-RegistryKey',
    'Search-Registry',
    'Export-RegistryReport'
)
