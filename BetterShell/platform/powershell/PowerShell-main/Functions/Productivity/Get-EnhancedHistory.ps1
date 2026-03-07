<#
.SYNOPSIS
    Enhanced command history with search, tags, and export capabilities.

.DESCRIPTION
    Provides advanced history management features:
    - Fuzzy search through command history
    - Tag commands for quick retrieval
    - Export/import history
    - Command frequency analytics
    - Smart deduplication

.PARAMETER Search
    Search term to filter history (supports fuzzy matching).

.PARAMETER Tag
    Filter by tag name.

.PARAMETER Count
    Number of results to return (default: 50).

.PARAMETER Export
    Export history to JSON file.

.PARAMETER Import
    Import history from JSON file.

.PARAMETER AddTag
    Add a tag to a specific history entry (by ID).

.PARAMETER ShowStats
    Show command frequency statistics.

.EXAMPLE
    Get-EnhancedHistory -Search "git"
    Search for git-related commands in history.

.EXAMPLE
    Get-EnhancedHistory -Tag "deployment" -Count 10
    Show last 10 commands tagged with "deployment".

.EXAMPLE
    Get-EnhancedHistory -Export "C:\history.json"
    Export history to JSON file.

.EXAMPLE
    Get-EnhancedHistory -ShowStats
    Display command frequency statistics.
#>
function Get-EnhancedHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Search = '',
        
        [Parameter(Mandatory = $false)]
        [string]$Tag = '',
        
        [Parameter(Mandatory = $false)]
        [int]$Count = 50,
        
        [Parameter(Mandatory = $false)]
        [string]$Export = '',
        
        [Parameter(Mandatory = $false)]
        [string]$Import = '',
        
        [Parameter(Mandatory = $false)]
        [int]$AddTag = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$TagName = '',
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowStats
    )

    # History storage file
    $historyFile = Join-Path $env:USERPROFILE '.pshistory-enhanced.json'
    
    # Load enhanced history
    if (Test-Path $historyFile) {
        $enhancedHistory = Get-Content $historyFile | ConvertFrom-Json
    } else {
        $enhancedHistory = @()
    }
    
    # Import history
    if ($Import) {
        if (Test-Path $Import) {
            $imported = Get-Content $Import | ConvertFrom-Json
            $enhancedHistory = $imported
            $enhancedHistory | ConvertTo-Json -Depth 10 | Set-Content $historyFile
            Write-Host "History imported from $Import" -ForegroundColor Green
            return
        } else {
            Write-Error "File not found: $Import"
            return
        }
    }
    
    # Export history
    if ($Export) {
        $enhancedHistory | ConvertTo-Json -Depth 10 | Set-Content $Export
        Write-Host "History exported to $Export" -ForegroundColor Green
        return
    }
    
    # Add tag to history entry
    if ($AddTag -gt 0 -and $TagName) {
        $entry = $enhancedHistory | Where-Object { $_.Id -eq $AddTag }
        if ($entry) {
            if (-not $entry.Tags) {
                $entry.Tags = @()
            }
            if ($TagName -notin $entry.Tags) {
                $entry.Tags += $TagName
                $enhancedHistory | ConvertTo-Json -Depth 10 | Set-Content $historyFile
                Write-Host "Tag '$TagName' added to history entry $AddTag" -ForegroundColor Green
            }
        }
        return
    }
    
    # Show statistics
    if ($ShowStats) {
        $commandFreq = @{}
        foreach ($entry in $enhancedHistory) {
            $cmd = ($entry.Command -split '\s+')[0]
            if (-not $commandFreq[$cmd]) {
                $commandFreq[$cmd] = 0
            }
            $commandFreq[$cmd]++
        }
        
        Write-Host "`nCommand Frequency Statistics:" -ForegroundColor Cyan
        Write-Host "=" * 50
        $commandFreq.GetEnumerator() | 
            Sort-Object -Property Value -Descending | 
            Select-Object -First 20 |
            ForEach-Object {
                Write-Host ("{0,-20} {1,5} times" -f $_.Key, $_.Value) -ForegroundColor Yellow
            }
        return
    }
    
    # Sync with PowerShell history
    $psHistory = Get-History -Count 1000
    foreach ($psEntry in $psHistory) {
        $existing = $enhancedHistory | Where-Object { 
            $_.Command -eq $psEntry.CommandLine -and 
            $_.ExecutionDate -eq $psEntry.StartExecutionTime.ToString('o')
        }
        
        if (-not $existing) {
            $newEntry = @{
                Id = [int](Get-Date -UFormat %s)
                Command = $psEntry.CommandLine
                ExecutionDate = $psEntry.StartExecutionTime.ToString('o')
                Duration = ($psEntry.EndExecutionTime - $psEntry.StartExecutionTime).TotalSeconds
                Tags = @()
            }
            $enhancedHistory += $newEntry
        }
    }
    
    # Remove duplicates (keep most recent)
    $deduplicated = $enhancedHistory | 
        Sort-Object -Property ExecutionDate -Descending |
        Group-Object -Property Command |
        ForEach-Object { $_.Group[0] }
    
    $enhancedHistory = $deduplicated | Sort-Object -Property ExecutionDate -Descending
    
    # Save enhanced history
    $enhancedHistory | ConvertTo-Json -Depth 10 | Set-Content $historyFile
    
    # Filter by search
    $filtered = $enhancedHistory
    if ($Search) {
        $filtered = $filtered | Where-Object { 
            $_.Command -like "*$Search*" -or 
            $_.Command -match $Search 
        }
    }
    
    # Filter by tag
    if ($Tag) {
        $filtered = $filtered | Where-Object { 
            $_.Tags -and $Tag -in $_.Tags 
        }
    }
    
    # Limit results
    $results = $filtered | Select-Object -First $Count
    
    # Display results
    foreach ($entry in $results) {
        $tags = if ($entry.Tags) { " [$($entry.Tags -join ', ')]" } else { "" }
        $duration = if ($entry.Duration) { " ({0:N2}s)" -f $entry.Duration } else { "" }
        $date = [DateTime]::Parse($entry.ExecutionDate).ToString('yyyy-MM-dd HH:mm:ss')
        
        Write-Host ("[{0}] {1}{2}{3}" -f $entry.Id, $entry.Command, $tags, $duration) -ForegroundColor Cyan
        Write-Host ("    {0}" -f $date) -ForegroundColor Gray
    }
    
    Write-Host "`nTotal: $($results.Count) entries" -ForegroundColor Green
    Write-Host "Use 'Get-EnhancedHistory -AddTag <ID> -TagName <tag>' to tag commands" -ForegroundColor Yellow
    
    return $results
}

# Alias for quick access
Set-Alias -Name 'hh' -Value 'Get-EnhancedHistory' -Scope Global -Force
Set-Alias -Name 'history-enhanced' -Value 'Get-EnhancedHistory' -Scope Global -Force

# Function to quickly tag last command
function Add-HistoryTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TagName
    )
    
    $history = Get-History -Count 1
    if ($history) {
        $enhancedHistory = Get-EnhancedHistory -Count 1
        if ($enhancedHistory) {
            Get-EnhancedHistory -AddTag $enhancedHistory[0].Id -TagName $TagName
        }
    }
}

Set-Alias -Name 'tag' -Value 'Add-HistoryTag' -Scope Global -Force

