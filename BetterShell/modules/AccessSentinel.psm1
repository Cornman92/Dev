# AccessSentinel.psm1
# v2.0.0
# ACL audit, journaling, rollback, UX explorer, export, simulation, sync, versioning.

Set-StrictMode -Version Latest

# -------------------------
# Module-level metadata
# -------------------------
$script:ModuleName    = 'AccessSentinel'
$script:ModuleVersion = [version]'2.0.0'
$script:ModuleRoot    = Split-Path -Parent $PSCommandPath

# -------------------------
# Internal helpers
# -------------------------

function Get-AccessSentinelPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativePath
    )
    Join-Path -Path $script:ModuleRoot -ChildPath $RelativePath
}

function Ensure-AccessSentinelDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RelativePath
    )
    $path = Get-AccessSentinelPath -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    $path
}

function Get-AccessJournalDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    Ensure-AccessSentinelDirectory -RelativePath 'Journal'
}

function Get-AccessJournalPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [datetime]$Date = (Get-Date)
    )
    $dir  = Get-AccessJournalDirectory
    $name = 'snapshot-{0}.json' -f $Date.ToString('yyyy-MM-dd')
    Join-Path -Path $dir -ChildPath $name
}

function Get-AccessJournalHashPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [datetime]$Date = (Get-Date)
    )
    $dir  = Get-AccessJournalDirectory
    $name = 'snapshot-{0}.json.sha256' -f $Date.ToString('yyyy-MM-dd')
    Join-Path -Path $dir -ChildPath $name
}

function Invoke-AccessSentinelGlobalJournal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EventType,
        [Parameter(Mandatory)][object]$Payload
    )
    $globalWriter = Get-Command -Name 'Write-GlobalJournalEvent' -ErrorAction SilentlyContinue
    if ($null -ne $globalWriter) {
        & $globalWriter -Source $script:ModuleName -EventType $EventType -Payload $Payload
    }
}

function ConvertTo-AccessAclSnapshot {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [System.Security.AccessControl.FileSystemSecurity]$Acl
    )

    $aceSnapshots = foreach ($ace in $Acl.Access) {
        [pscustomobject]@{
            IdentityReference = $ace.IdentityReference.Value
            FileSystemRights  = $ace.FileSystemRights.ToString()
            AccessControlType = $ace.AccessControlType.ToString()
            InheritanceFlags  = $ace.InheritanceFlags.ToString()
            PropagationFlags  = $ace.PropagationFlags.ToString()
            IsInherited       = [bool]$ace.IsInherited
        }
    }

    [pscustomobject]@{
        Owner = $Acl.Owner.Value
        Access = $aceSnapshots
    }
}

function Update-AccessJournalHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$JournalPath
    )

    if (-not (Test-Path -LiteralPath $JournalPath)) {
        return
    }

    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $JournalPath
    $hashPath = [System.IO.Path]::ChangeExtension($JournalPath, '.sha256')
    "{0}  {1}" -f $hash.Hash, (Split-Path -Leaf $JournalPath) | Set-Content -LiteralPath $hashPath -Encoding UTF8
}

function Test-AccessJournalIntegrity {
    <#
    .SYNOPSIS
        Verifies SHA256 hash for a journal snapshot file.

    .PARAMETER Date
        Date of the snapshot (defaults to today).

    .OUTPUTS
        PSCustomObject with Path, IsValid, ExpectedHash, ActualHash.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [datetime]$Date = (Get-Date)
    )

    $journalPath = Get-AccessJournalPath -Date $Date
    $hashPath    = Get-AccessJournalHashPath -Date $Date

    if (-not (Test-Path -LiteralPath $journalPath)) {
        throw "No journal snapshot found for $($Date.ToShortDateString()) at '$journalPath'."
    }

    if (-not (Test-Path -LiteralPath $hashPath)) {
        return [pscustomobject]@{
            Path         = $journalPath
            IsValid      = $false
            ExpectedHash = $null
            ActualHash   = (Get-FileHash -Algorithm SHA256 -LiteralPath $journalPath).Hash
        }
    }

    $hashLine = Get-Content -LiteralPath $hashPath -Raw
    $expected = ($hashLine -split '\s+')[0]
    $actual   = (Get-FileHash -Algorithm SHA256 -LiteralPath $journalPath).Hash

    [pscustomobject]@{
        Path         = $journalPath
        IsValid      = ($expected -eq $actual)
        ExpectedHash = $expected
        ActualHash   = $actual
    }
}

function Get-AccessJournalEntries {
    <#
    .SYNOPSIS
        Retrieves journal entries for a given date.

    .PARAMETER Date
        Date of the journal snapshot (defaults to today).

    .PARAMETER VerifyIntegrity
        If specified, verifies SHA256 integrity and throws on mismatch.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [datetime]$Date = (Get-Date),
        [switch]$VerifyIntegrity
    )

    $journalPath = Get-AccessJournalPath -Date $Date

    if (-not (Test-Path -LiteralPath $journalPath)) {
        Write-Verbose "No journal snapshot found for $($Date.ToShortDateString()) at '$journalPath'."
        return @()
    }

    if ($VerifyIntegrity) {
        $result = Test-AccessJournalIntegrity -Date $Date
        if (-not $result.IsValid) {
            throw "Journal integrity check failed for '$($result.Path)'. Expected $($result.ExpectedHash), got $($result.ActualHash)."
        }
    }

    $raw = Get-Content -LiteralPath $journalPath -Raw
    if (-not $raw.Trim()) {
        return @()
    }

    $entries = $raw | ConvertFrom-Json -ErrorAction Stop

    if ($entries -isnot [System.Collections.IEnumerable]) {
        ,$entries
    } else {
        $entries
    }
}

# -------------------------
# Public: Write-JournalSnapshot
# -------------------------
function Write-JournalSnapshot {
    <#
    .SYNOPSIS
        Writes a single ACL snapshot entry into today's journal file.

    .DESCRIPTION
        Stores ACL state (including SDDL and expanded ACEs) for rollback, export, and exploration.

    .PARAMETER Path
        Path being audited / mutated.

    .PARAMETER Owner
        Owner of the path.

    .PARAMETER AclObject
        File system security descriptor obtained via Get-Acl.

    .PARAMETER Action
        Logical action: Audit, Fix, Skip, Simulate, Backup, Sync, Rollback.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Owner,

        [Parameter(Mandatory)]
        [System.Security.AccessControl.FileSystemSecurity]$AclObject,

        [Parameter(Mandatory)]
        [ValidateSet('Audit','Fix','Skip','Simulate','Backup','Sync','Rollback')]
        [string]$Action
    )

    process {
        $journalPath = Get-AccessJournalPath

        $aclSnapshot = ConvertTo-AccessAclSnapshot -Acl $AclObject

        $entry = [pscustomobject]@{
            Timestamp = (Get-Date).ToString('o')
            Path      = $Path
            Owner     = $Owner
            Action    = $Action
            Sddl      = $AclObject.GetSecurityDescriptorSddlForm('All')
            Acl       = $aclSnapshot
        }

        $existing = @()
        if (Test-Path -LiteralPath $journalPath) {
            try {
                $raw = Get-Content -LiteralPath $journalPath -Raw
                if ($raw.Trim()) {
                    $existing = $raw | ConvertFrom-Json -ErrorAction Stop
                }
            } catch {
                throw "Failed to read existing journal '$journalPath' as JSON. $($_.Exception.Message)"
            }
        }

        if ($existing -isnot [System.Collections.IEnumerable]) {
            $existing = @($existing)
        }

        $allEntries = @($existing + $entry)

        $json = $allEntries | ConvertTo-Json -Depth 8
        $json | Set-Content -LiteralPath $journalPath -Encoding UTF8

        Update-AccessJournalHash -JournalPath $journalPath
        Invoke-AccessSentinelGlobalJournal -EventType 'SnapshotWritten' -Payload $entry

        $entry
    }
}

# -------------------------
# Public: Invoke-Rollback
# -------------------------
function Invoke-Rollback {
    <#
    .SYNOPSIS
        Restores ACLs from a journal snapshot file.

    .DESCRIPTION
        Recreates FileSecurity objects from stored SDDL and applies them with Set-Acl.
        Default is today's snapshot; can target specific date.

    .PARAMETER Date
        Date whose snapshot should be used (defaults to today).

    .PARAMETER Force
        Skip confirmation prompts by leveraging SupportsShouldProcess and -Confirm:$false.

    .PARAMETER IgnoreIntegrity
        Skip integrity validation (not recommended).
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [datetime]$Date = (Get-Date),
        [switch]$Force,
        [switch]$IgnoreIntegrity
    )

    $entries = Get-AccessJournalEntries -Date $Date -VerifyIntegrity:(-not $IgnoreIntegrity)

    if (-not $entries -or $entries.Count -eq 0) {
        Write-Warning "No journal entries found for $($Date.ToShortDateString()). Nothing to rollback."
        return
    }

    foreach ($entry in $entries) {
        $targetPath = [string]$entry.Path
        if (-not (Test-Path -LiteralPath $targetPath)) {
            Write-Warning "Path not found, skipping rollback: $targetPath"
            continue
        }

        if ($PSCmdlet.ShouldProcess($targetPath, "Restore ACL from journal snapshot dated $($Date.ToShortDateString())")) {
            try {
                $fs = New-Object System.Security.AccessControl.FileSecurity
                $fs.SetSecurityDescriptorSddlForm([string]$entry.Sddl)
                Set-Acl -LiteralPath $targetPath -AclObject $fs
                Write-Verbose "Rolled back ACL for '$targetPath'."
                Invoke-AccessSentinelGlobalJournal -EventType 'RollbackApplied' -Payload $entry
            } catch {
                Write-Warning "Failed to rollback ACL for '$targetPath': $($_.Exception.Message)"
            }
        }
    }
}

# -------------------------
# Public: Launch UX Explorer
# -------------------------
function Launch-AccessExplorer {
    <#
    .SYNOPSIS
        Launches an interactive explorer over journal entries.

    .DESCRIPTION
        Uses Out-GridView when available; falls back to Format-Table for console-only environments.

    .PARAMETER Date
        Date of the snapshot to explore (defaults to today).
    #>
    [CmdletBinding()]
    param(
        [datetime]$Date = (Get-Date)
    )

    $entries = Get-AccessJournalEntries -Date $Date

    if (-not $entries -or $entries.Count -eq 0) {
        Write-Warning "No entries found for $($Date.ToShortDateString())."
        return
    }

    $view = $entries | Select-Object `
        Timestamp,
        Path,
        Owner,
        Action,
        @{ Name='AceCount'; Expression = { $_.Acl.Access.Count } }

    $ogv = Get-Command -Name 'Out-GridView' -ErrorAction SilentlyContinue
    if ($null -ne $ogv) {
        $view | Out-GridView -Title "Access Sentinel Explorer - $($Date.ToShortDateString())"
    } else {
        $view | Format-Table -AutoSize
        Write-Host "Out-GridView not available. Displayed table instead." -ForegroundColor Yellow
    }
}

# -------------------------
# Public: Export Snapshot
# -------------------------
function Export-Snapshot {
    <#
    .SYNOPSIS
        Exports snapshot entries to CSV.

    .DESCRIPTION
        Flattens ACL entries so each ACE is a row with path and context.

    .PARAMETER Date
        Date of snapshot to export (defaults to today).

    .PARAMETER OutputPath
        Destination CSV path. Defaults to Export/snapshot-YYYY-MM-DD.csv.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [datetime]$Date = (Get-Date),

        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    $entries = Get-AccessJournalEntries -Date $Date

    if (-not $entries -or $entries.Count -eq 0) {
        Write-Warning "No entries found for $($Date.ToShortDateString()). Nothing to export."
        return $null
    }

    if (-not $OutputPath) {
        $exportDir = Ensure-AccessSentinelDirectory -RelativePath 'Export'
        $OutputPath = Join-Path -Path $exportDir -ChildPath ('snapshot-{0}.csv' -f $Date.ToString('yyyy-MM-dd'))
    }

    $rows = foreach ($entry in $entries) {
        foreach ($ace in $entry.Acl.Access) {
            [pscustomobject]@{
                Timestamp   = $entry.Timestamp
                Path        = $entry.Path
                Owner       = $entry.Owner
                Action      = $entry.Action
                Identity    = $ace.IdentityReference
                Rights      = $ace.FileSystemRights
                Type        = $ace.AccessControlType
                Inheritance = $ace.InheritanceFlags
                Propagation = $ace.PropagationFlags
                IsInherited = $ace.IsInherited
            }
        }
    }

    $rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Verbose "Snapshot exported to: $OutputPath"

    Invoke-AccessSentinelGlobalJournal -EventType 'SnapshotExported' -Payload @{ Path = $OutputPath; Date = $Date }

    $OutputPath
}

# -------------------------
# Public: Onboarding Guide
# -------------------------
function Show-OnboardingGuide {
    [CmdletBinding()]
    param()

@"
👋 Welcome to Access Sentinel v2

This module helps you:
  • Audit ACLs across paths
  • Capture journaled snapshots per day
  • Explore snapshots interactively
  • Export ACL state for reviews and compliance
  • Roll back ACL changes safely
  • Simulate changes and sync ACLs between paths
  • Register itself into a plugin registry for discovery

Core commands:
  • Invoke-AccessSentinel     – main CLI entrypoint (audit, simulate, sync, export, explorer)
  • Write-JournalSnapshot     – write a single snapshot entry
  • Invoke-Rollback           – restore ACLs from a snapshot
  • Launch-AccessExplorer     – interactive explorer
  • Export-Snapshot           – export snapshots to CSV
  • Simulate-Mutation         – dry-run ACL inspection for a path
  • Sync-AccessAclState       – copy ACL between paths
  • Backup-AccessAclState     – export ACL to .acl backup file
  • Register-AccessSentinelPlugin – register in a plugin registry
  • Get-AccessSentinelVersion – display module version

Common patterns:
  • Invoke-AccessSentinel -Path "C:\Data" -Recurse -Interactive -Export
  • Invoke-AccessSentinel -Path "C:\Data" -Simulate -Verbose
  • Invoke-Rollback -Date (Get-Date).AddDays(-1) -Confirm:$false

Use Start-OnboardingWalkthrough for a guided first run.
"@ | Write-Host
}

function Start-OnboardingWalkthrough {
    [CmdletBinding()]
    param()

@"
🚀 Access Sentinel v2 – Walkthrough

Step 1:
  Choose a test folder:
    `$testPath = "$env:TEMP\AccessSentinel-Test"`
    New-Item -ItemType Directory -Path $testPath -Force | Out-Null

Step 2:
  Run a simulated audit:
    Invoke-AccessSentinel -Path $testPath -Simulate -Verbose

Step 3:
  Explore today's snapshot:
    Launch-AccessExplorer

Step 4:
  Export snapshot to CSV:
    Export-Snapshot

Step 5:
  (Optional) Perform a real audit with journaling:
    Invoke-AccessSentinel -Path $testPath -Verbose

Step 6:
  (Optional) Rollback:
    Invoke-Rollback -Confirm:$false

Step 7:
  Register plugin for discovery:
    Register-AccessSentinelPlugin

✅ You now have a full ACL journaling and rollback workflow.
"@ | Write-Host
}

# -------------------------
# Public: Plugin Registry
# -------------------------
function Register-AccessSentinelPlugin {
    <#
    .SYNOPSIS
        Registers Access Sentinel into a JSON plugin registry file.

    .PARAMETER RegistryPath
        Optional explicit registry path. Defaults to PluginRegistry\registry.json under module root.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$RegistryPath
    )

    if (-not $RegistryPath) {
        $regDir = Ensure-AccessSentinelDirectory -RelativePath 'PluginRegistry'
        $RegistryPath = Join-Path -Path $regDir -ChildPath 'registry.json'
    }

    $plugin = [pscustomobject]@{
        Name        = $script:ModuleName
        Version     = $script:ModuleVersion.ToString()
        Description = 'ACL audit, journaling, rollback, UX explorer, export, simulation, sync, versioning'
        EntryPoint  = (Get-AccessSentinelPath -RelativePath 'AccessSentinel.psm1')
        RegisteredOn = (Get-Date).ToString('o')
    }

    $all = @()
    if (Test-Path -LiteralPath $RegistryPath) {
        try {
            $raw = Get-Content -LiteralPath $RegistryPath -Raw
            if ($raw.Trim()) {
                $all = $raw | ConvertFrom-Json -ErrorAction Stop
            }
        } catch {
            throw "Failed to read existing registry '$RegistryPath'. $($_.Exception.Message)"
        }
    }

    if ($all -isnot [System.Collections.IEnumerable]) {
        $all = @($all)
    }

    $all = $all | Where-Object { $_.Name -ne $plugin.Name }
    $all += $plugin

    if ($PSCmdlet.ShouldProcess($RegistryPath, "Write Access Sentinel plugin metadata")) {
        $all | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $RegistryPath -Encoding UTF8
    }

    Invoke-AccessSentinelGlobalJournal -EventType 'PluginRegistered' -Payload $plugin

    $plugin
}

function Find-AccessSentinelPlugin {
    <#
    .SYNOPSIS
        Searches the plugin registry for matching entries.

    .PARAMETER Name
        Wildcard name filter (defaults to *Access*).
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [string]$Name = '*Access*',

        [ValidateNotNullOrEmpty()]
        [string]$RegistryPath
    )

    if (-not $RegistryPath) {
        $regDir = Ensure-AccessSentinelDirectory -RelativePath 'PluginRegistry'
        $RegistryPath = Join-Path -Path $regDir -ChildPath 'registry.json'
    }

    if (-not (Test-Path -LiteralPath $RegistryPath)) {
        Write-Verbose "Plugin registry not found at '$RegistryPath'."
        return @()
    }

    $raw = Get-Content -LiteralPath $RegistryPath -Raw
    if (-not $raw.Trim()) {
        return @()
    }

    $all = $raw | ConvertFrom-Json -ErrorAction Stop
    if ($all -isnot [System.Collections.IEnumerable]) {
        $all = @($all)
    }

    $all | Where-Object { $_.Name -like $Name }
}

# -------------------------
# Public: Mutation Simulator
# -------------------------
function Simulate-Mutation {
    <#
    .SYNOPSIS
        Simulates an ACL mutation by inspecting and returning ACL state.

    .DESCRIPTION
        No changes are applied. Intended for "what if" analysis and teaching.

    .PARAMETER Path
        Path whose ACL should be simulated.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    process {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw "Path not found: $Path"
        }

        $acl = Get-Acl -LiteralPath $Path
        $snapshot = ConvertTo-AccessAclSnapshot -Acl $acl

        [pscustomobject]@{
            Path      = $Path
            Owner     = $snapshot.Owner
            Acl       = $snapshot.Access
            Sddl      = $acl.GetSecurityDescriptorSddlForm('All')
            Timestamp = (Get-Date).ToString('o')
        }
    }
}

# -------------------------
# Public: Sync & Backup
# -------------------------
function Sync-AccessAclState {
    <#
    .SYNOPSIS
        Copies ACL from a source path to a target path.

    .PARAMETER SourcePath
        Source path whose ACL will be copied.

    .PARAMETER TargetPath
        Target path that will receive the ACL.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TargetPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        throw "Target path not found: $TargetPath"
    }

    $acl = Get-Acl -LiteralPath $SourcePath

    if ($PSCmdlet.ShouldProcess($TargetPath, "Apply ACL from '$SourcePath'")) {
        Set-Acl -LiteralPath $TargetPath -AclObject $acl
        Write-Verbose "ACL synced from '$SourcePath' to '$TargetPath'."

        # journal sync
        Write-JournalSnapshot -Path $TargetPath -Owner $acl.Owner.Value -AclObject $acl -Action 'Sync' | Out-Null
    }
}

function Backup-AccessAclState {
    <#
    .SYNOPSIS
        Exports ACL of a path to a .acl backup file.

    .PARAMETER Path
        Path whose ACL is being backed up.

    .PARAMETER OutputPath
        Optional explicit backup path; defaults to SyncBackup\backup-YYYYMMDD-HHmmss.acl.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    process {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw "Path not found: $Path"
        }

        $acl = Get-Acl -LiteralPath $Path

        if (-not $OutputPath) {
            $backupDir  = Ensure-AccessSentinelDirectory -RelativePath 'SyncBackup'
            $backupName = 'backup-{0}.acl' -f (Get-Date).ToString('yyyyMMdd-HHmmss')
            $OutputPath = Join-Path -Path $backupDir -ChildPath $backupName
        }

        $acl | Export-Clixml -LiteralPath $OutputPath
        Write-Verbose "Backup saved to: $OutputPath"

        Write-JournalSnapshot -Path $Path -Owner $acl.Owner.Value -AclObject $acl -Action 'Backup' | Out-Null
        Invoke-AccessSentinelGlobalJournal -EventType 'BackupCreated' -Payload @{ Path = $Path; BackupPath = $OutputPath }

        $OutputPath
    }
}

# -------------------------
# Public: Versioning
# -------------------------
function Get-ModuleVersion {
    <#
    .SYNOPSIS
        Returns the semantic version for Access Sentinel (from module metadata).

    .OUTPUTS
        [version]
    #>
    [CmdletBinding()]
    [OutputType([version])]
    param()
    $script:ModuleVersion
}

function Get-AccessSentinelVersion {
    <#
    .SYNOPSIS
        Returns rich version info including optional changelog metadata.

    .OUTPUTS
        PSCustomObject with Version, Source, LatestChangelogEntry.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $result = [pscustomobject]@{
        Name                 = $script:ModuleName
        Version              = $script:ModuleVersion.ToString()
        Source               = 'ModuleMetadata'
        LatestChangelogEntry = $null
    }

    $changelogPath = Get-AccessSentinelPath -RelativePath 'Versioning\changelog.md'
    if (Test-Path -LiteralPath $changelogPath) {
        $line = Get-Content -LiteralPath $changelogPath |
            Select-String -Pattern '^##\s+\[v' |
            Select-Object -First 1

        if ($line) {
            $result.LatestChangelogEntry = $line.Line.Trim()
            $result.Source = 'ModuleMetadata+Changelog'
        }
    }

    $result
}

# -------------------------
# Public: Main CLI Entry
# -------------------------
function Invoke-AccessSentinel {
    <#
    .SYNOPSIS
        Main CLI entrypoint for auditing and journaling ACLs.

    .DESCRIPTION
        Scans one or more paths, captures ACL snapshots, optionally simulates only,
        supports post-run explorer and export, and can trigger rollback.

    .PARAMETER Path
        One or more filesystem paths to audit.

    .PARAMETER Recurse
        Recursively process child items.

    .PARAMETER Simulate
        Perform simulation (no ACL changes; journal Action='Simulate').

    .PARAMETER Interactive
        Launch UX Explorer after run.

    .PARAMETER Export
        Export snapshot to CSV after run.

    .PARAMETER Rollback
        Trigger rollback at the end of the run, using today's snapshot (or JournalDate).

    .PARAMETER JournalDate
        Override snapshot date when exporting / explorer / rollback.

    .PARAMETER SyncTarget
        If specified, sync ACLs of each matched item to this target path (dangerous; obeys -WhatIf).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [switch]$Recurse,
        [switch]$Simulate,
        [switch]$Interactive,
        [switch]$Export,
        [switch]$Rollback,

        [datetime]$JournalDate = (Get-Date),

        [ValidateNotNullOrEmpty()]
        [string]$SyncTarget
    )

    begin {
        if ($SyncTarget -and -not (Test-Path -LiteralPath $SyncTarget)) {
            throw "Sync target path not found: $SyncTarget"
        }
    }

    process {
        foreach ($p in $Path) {
            if (-not (Test-Path -LiteralPath $p)) {
                Write-Warning "Path not found, skipping: $p"
                continue
            }

            $items = if ($Recurse) {
                Get-ChildItem -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue |
                    ForEach-Object { $_ } + (Get-Item -LiteralPath $p -Force)
            } else {
                Get-Item -LiteralPath $p -Force
            }

            foreach ($item in $items) {
                $targetPath = $item.FullName

                if (-not (Test-Path -LiteralPath $targetPath)) { continue }

                $acl = Get-Acl -LiteralPath $targetPath

                if ($Simulate) {
                    # Simulation only — no mutations.
                    Write-JournalSnapshot -Path $targetPath -Owner $acl.Owner.Value -AclObject $acl -Action 'Simulate' | Out-Null
                    Write-Verbose "Simulated ACL capture for '$targetPath'."
                } else {
                    # For now, this is an audit-only journal (no fix-up logic yet).
                    Write-JournalSnapshot -Path $targetPath -Owner $acl.Owner.Value -AclObject $acl -Action 'Audit' | Out-Null
                    Write-Verbose "Audited ACL for '$targetPath'."
                }

                if ($SyncTarget) {
                    Sync-AccessAclState -SourcePath $targetPath -TargetPath $SyncTarget -WhatIf:$WhatIfPreference
                }
            }
        }
    }

    end {
        if ($Rollback) {
            Invoke-Rollback -Date $JournalDate -Confirm:$false
        }

        if ($Export) {
            $exportPath = Export-Snapshot -Date $JournalDate
            if ($exportPath) {
                Write-Verbose "Exported snapshot to '$exportPath'."
            }
        }

        if ($Interactive) {
            Launch-AccessExplorer -Date $JournalDate
        }
    }
}

# -------------------------
# Exported members
# -------------------------
Export-ModuleMember -Function @(
    'Invoke-AccessSentinel',
    'Write-JournalSnapshot',
    'Get-AccessJournalEntries',
    'Test-AccessJournalIntegrity',
    'Invoke-Rollback',
    'Launch-AccessExplorer',
    'Export-Snapshot',
    'Show-OnboardingGuide',
    'Start-OnboardingWalkthrough',
    'Register-AccessSentinelPlugin',
    'Find-AccessSentinelPlugin',
    'Simulate-Mutation',
    'Sync-AccessAclState',
    'Backup-AccessAclState',
    'Get-ModuleVersion',
    'Get-AccessSentinelVersion'
)
