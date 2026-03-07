#Requires -Version 7.2

<#
.SYNOPSIS
    Migrates C:\Users\C-Man\OneDrive\Dev to D:\Dev with intelligent routing,
    diff-merge for Better11, and module consolidation.

.DESCRIPTION
    Performs a structured, logged migration of the OneDrive Dev workspace to the
    local D:\Dev tree. Key behaviours:

    - Better11: diff-merge (source wins on newer/missing only)
    - Standalone projects: routed into D:\Dev\Better11 sub-paths
    - Loose root .psm1 files: staged into the appropriate B11 module Source\Legacy dirs
    - GitHub sub-dirs: unique repos copied to D:\Dev\GitHub
    - Sensitive files, binaries, and third-party tools are never touched

    Run with -WhatIf first, then again without it to execute.
    WhatIf mode shows every file that WOULD be copied without writing anything.

.PARAMETER Source
    Root of the OneDrive Dev folder.

.PARAMETER Destination
    Root of the local Dev folder.

.PARAMETER LogPath
    Full path for the migration log file.

.PARAMETER WhatIf
    Preview all operations without writing any files.

.EXAMPLE
    .\Invoke-DevMigration.ps1 -WhatIf
    .\Invoke-DevMigration.ps1

.NOTES
    PSScriptAnalyzer: 0 errors  |  Author: C-Man  |  Project: Better11
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
[OutputType([void])]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Source = 'C:\Users\C-Man\OneDrive\Dev',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Destination = 'D:\Dev',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $LogPath = "D:\Dev\migration-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Capture WhatIf state for use in non-cmdlet contexts
[bool] $script:IsWhatIf = $WhatIfPreference.IsPresent

#region ── Constants ────────────────────────────────────────────────────────────

[string] $script:B11Root = Join-Path $Destination 'Better11'
[string] $script:OdB11   = Join-Path $Source 'Better11'

[string[]] $script:SensitiveFiles = @(
    '2FA-AccessToken.txt',
    'github-recovery-codes.txt',
    '2FA-AccessToken*',
    '*recovery-code*',
    '*password*',
    '*.token',
    '*.secret'
)

[string[]] $script:SkipTopDirs = @(
    '.git', '.dotnet', 'mnt',
    'archive1', 'consolidated-zip-files', 'Complete-Artifacts-Archive',
    'images',
    'installers',
    'Broker',
    'Autoruns',
    'LGPO',
    'PolicyAnalyzer',
    'tbosdts_en',
    'ventoy-1.1.07-windows',
    'VG278Q_WHQL_Driver',
    'windick-main',
    'third-party',
    'Visual Studio',
    'Windows Kits',
    'LanguagesV10',
    'Idb',
    'Journal',
    'OwnershipToolkit',
    'logs',
    'boot',
    'DISMGUI',
    'DeploymentPipeline_USB',
    'GoldenImage',
    'individual-files',
    'Individual-files',
    'ISOBuilder',
    'CMan-Projects-Consolidated',
    'Manifests',
    'manifest',
    'EnvConfig',
    'FunctionCatalog',
    'PluginRegistry',
    'subagent-system',
    'Libraries',
    'project-scaffolder-mcp-server',
    'code-analysis-mcp-server',
    'dism-mcp-server',
    'dotnet-cli-mcp-server',
    'nuget-mcp-server',
    'powershell-mcp-server',
    'system-info-mcp-server',
    'winget-mcp-server',
    'Batlez.Folder'
)

[string[]] $script:SkipExtensions = @(
    '.wim', '.img', '.iso', '.esd', '.swm',
    '.exe', '.msi', '.msp', '.msu', '.cab',
    '.dll', '.pdb', '.so', '.dylib',
    '.zip', '.7z', '.tar', '.gz', '.rar', '.xz',
    '.vhd', '.vhdx', '.vmdk', '.ova', '.ovf',
    '.mp4', '.mkv', '.avi', '.mov',
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico',
    '.war', '.jar', '.class',
    '.pyc', '.pyo',
    '.binlog', '.bin',
    '.log'
)

[hashtable] $script:LoosePsm1Map = @{
    'AdvancedFeatures.psm1'        = 'B11.BetterShell\Source\Legacy'
    'AdvancedUtilities.psm1'       = 'B11.BetterShell\Source\Legacy'
    'AdvancedVariables.psm1'       = 'B11.BetterShell\Source\Legacy'
    'AgentFramework.psm1'          = 'B11.Automation\Source\Legacy'
    'AIIntegration.psm1'           = 'B11.Automation\Source\Legacy'
    'BackupSyncAgent.psm1'         = 'B11.Recovery\Source\Legacy'
    'BuildAutomation.psm1'         = 'B11.Automation\Source\Legacy'
    'CustomObjects.psm1'           = 'B11.System\Source\Legacy'
    'DatabaseAPIAgent.psm1'        = 'B11.Automation\Source\Legacy'
    'DevOpsIntegration.psm1'       = 'B11.Automation\Source\Legacy'
    'ExtendedAliases.psm1'         = 'B11.BetterShell\Source\Legacy'
    'MassiveExtensions.psm1'       = 'B11.BetterShell\Source\Legacy'
    'MegaUtilities.psm1'           = 'B11.System\Source\Legacy'
    'MonitoringAgent.psm1'         = 'B11.Automation\Source\Legacy'
    'Ok_Part1_Core.psm1'           = 'B11.System\Source\Legacy'
    'PackageEnvironmentAgent.psm1' = 'B11.PackageManager\Source\Legacy'
    'Phase2-Agents.psm1'           = 'B11.Automation\Source\Legacy'
    'QuickActions.psm1'            = 'B11.QuickMode\Source\Legacy'
}

[string[]] $script:ProfileMegaPatches = @(
    'UltraProfile_Phase3_patch',
    'UltraProfile_Phase3_patch_1',
    'UltraProfile_Phase3_RTX_Games_patch',
    'UltraProfile_Phase3_RTX_Games_patch_2'
)

[string[]] $script:AutomationSources = @('ConnorOS', 'PostInstall', 'Onboarding')

[string[]] $script:ShellExtras = @('PSColor', 'PSModules')

[string[]] $script:GitHubUniqueRepos = @(
    'DevEnv', 'GayMrPC', 'PowerShellProfile', 'PSP', 'Smrt-Fylz', 'WindowsPowerSuite'
)

[string[]] $script:SecurityBaselineDirs = @(
    'Microsoft Edge v139 Security Baseline',
    'Microsoft Edge v139 Security Baseline_1',
    'Windows 11 v24H2 Security Baseline',
    'Windows 11 v24H2 Security Baseline_1'
)

[string[]] $script:WinPELegacyMods = @(
    'Deploy-Automation.psm1', 'Deploy-WinPEImage.psm1',
    'Image-Customization.psm1', 'Test-WinPEImage.psm1',
    'WinPE-Console.psm1', 'Network-Configuration.psm1',
    'Storage-Management.psm1'
)

#endregion

#region ── Counters & Logging ────────────────────────────────────────────────────

[int] $script:CopiedCount  = 0
[int] $script:SkippedCount = 0
[int] $script:ErrorCount   = 0

function Write-MigLog {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string] $Message,

        [Parameter()]
        [ValidateSet('INFO', 'COPY', 'SKIP', 'WARN', 'ERROR', 'SECTION')]
        [string] $Level = 'INFO'
    )

    $ts = Get-Date -Format 'HH:mm:ss'
    $colours = @{
        INFO    = 'Cyan'; COPY = 'Green'; SKIP = 'DarkGray'
        WARN    = 'Yellow'; ERROR = 'Red'; SECTION = 'Magenta'
    }

    $prefix = if ($script:IsWhatIf) { '[WHATIF] ' } else { '' }
    $line   = "[$ts] [$Level] $prefix$Message"

    Write-Host $line -ForegroundColor $colours[$Level]

    # Use .NET directly to bypass WhatIf preference on Add-Content
    [System.IO.File]::AppendAllText($script:LogPath, "$line`r`n", [System.Text.Encoding]::UTF8)
}

#endregion

#region ── Helpers ───────────────────────────────────────────────────────────────

function Test-IsSensitive {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string] $Name
    )

    foreach ($pattern in $script:SensitiveFiles) {
        if ($Name -like $pattern) { return $true }
    }
    return $false
}

function Test-ShouldSkipExtension {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Extension
    )

    if ([string]::IsNullOrEmpty($Extension)) { return $false }
    return $script:SkipExtensions -contains $Extension.ToLower()
}

function Invoke-SafeCopy {
    <#
    .SYNOPSIS
        Copies one file — only if destination is missing or source is strictly newer.
        Fully respects -WhatIf.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string] $SourcePath,

        [Parameter(Mandatory)]
        [string] $DestPath,

        [Parameter()]
        [string] $Reason = ''
    )

    # Guard: sensitive
    if (Test-IsSensitive -Name (Split-Path $SourcePath -Leaf)) {
        Write-MigLog "SENSITIVE – skipped: $SourcePath" -Level WARN
        $script:SkippedCount++
        return
    }

    # Guard: binary extension
    $ext = [System.IO.Path]::GetExtension($SourcePath)
    if (Test-ShouldSkipExtension -Extension $ext) {
        $script:SkippedCount++
        return
    }

    # Guard: .git internals anywhere in path
    if ($SourcePath -match [regex]::Escape([System.IO.Path]::DirectorySeparatorChar + '.git')) {
        $script:SkippedCount++
        return
    }

    # Diff guard: skip if destination is same age or newer
    if (Test-Path $DestPath) {
        $srcAge = (Get-Item $SourcePath).LastWriteTimeUtc
        $dstAge = (Get-Item $DestPath).LastWriteTimeUtc
        if ($srcAge -le $dstAge) {
            $script:SkippedCount++
            return
        }
    }

    $label      = if ($Reason) { "[$Reason] " } else { '' }
    $displaySrc = $SourcePath.Replace($Source, 'OneDrive\Dev')
    $displayDst = $DestPath.Replace($Destination, 'D:\Dev')

    if ($PSCmdlet.ShouldProcess("$displaySrc → $displayDst", "$($label)Copy file")) {
        try {
            $destDir = Split-Path $DestPath -Parent
            if (-not (Test-Path $destDir)) {
                [void](New-Item -ItemType Directory -Path $destDir -Force)
            }
            Copy-Item -Path $SourcePath -Destination $DestPath -Force
            Write-MigLog "${label}$displaySrc → $displayDst" -Level COPY
            $script:CopiedCount++
        }
        catch {
            Write-MigLog "ERROR ${label}$displaySrc → ${displayDst}: $_" -Level ERROR
            $script:ErrorCount++
        }
    } else {
        # WhatIf mode — count it as a "would-copy" for reporting
        Write-MigLog "${label}WOULD COPY: $displaySrc → $displayDst" -Level COPY
        $script:CopiedCount++
    }
}

function Invoke-CopyTree {
    <#
    .SYNOPSIS
        Recursively copies all eligible files from SourceDir to DestDir.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string] $SourceDir,

        [Parameter(Mandatory)]
        [string] $DestDir,

        [Parameter()]
        [string] $Reason = '',

        [Parameter()]
        [string[]] $ExcludeSubDirs = @()
    )

    if (-not (Test-Path $SourceDir)) {
        Write-MigLog "Source not found, skipping: $SourceDir" -Level WARN
        return
    }

    $sepEsc = [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

    Get-ChildItem -Path $SourceDir -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            $file    = $_
            $relPath = $file.FullName.Substring($SourceDir.TrimEnd('\').Length).TrimStart('\')

            # Skip .git directories
            if ($relPath -match "${sepEsc}?\.git(${sepEsc}|$)") { return }

            # Skip excluded sub-directories
            foreach ($excl in $ExcludeSubDirs) {
                if ($relPath -like "$excl\*" -or $relPath -eq $excl) { return }
            }

            $destFile = Join-Path $DestDir $relPath
            Invoke-SafeCopy -SourcePath $file.FullName -DestPath $destFile -Reason $Reason
        }
}

#endregion

#region ── Migration Steps ───────────────────────────────────────────────────────

function Invoke-MigrateB11 {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 1 — Diff-merge OneDrive\Dev\Better11 → D:\Dev\Better11' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    if (-not (Test-Path $script:OdB11)) {
        Write-MigLog 'OneDrive\Dev\Better11 not found — skipping.' -Level WARN
        return
    }

    Invoke-CopyTree -SourceDir $script:OdB11 `
                    -DestDir   $script:B11Root `
                    -Reason    'B11-Merge' `
                    -ExcludeSubDirs @(
                        'dism-mcp-server', 'Custom-Skills-Bundle',
                        '1-FoundationMigration', '2-QualityGate', '3-Packaging'
                    )
}

function Invoke-MigrateLoosePsm1 {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 2 — Loose .psm1 files → appropriate B11 module Source\Legacy' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    foreach ($entry in $script:LoosePsm1Map.GetEnumerator()) {
        $fileName = $entry.Key
        $relDest  = $entry.Value

        $candidates = @(
            (Join-Path $Source $fileName),
            (Join-Path $script:OdB11 $fileName),
            (Join-Path $Source "modules\$fileName")
        )

        $found = $false
        foreach ($candidate in $candidates) {
            if (Test-Path $candidate) {
                $destPath = Join-Path $script:B11Root "PowerShell\Modules\$relDest\$fileName"
                Invoke-SafeCopy -SourcePath $candidate -DestPath $destPath -Reason 'LegacyPsm1'
                $found = $true
                break
            }
        }

        if (-not $found) {
            Write-MigLog "  Not found (skipped): $fileName" -Level SKIP
            $script:SkippedCount++
        }
    }

    # Catch remaining root-level .psm1 files not in the map
    Get-ChildItem -Path $Source -Filter '*.psm1' -File -ErrorAction SilentlyContinue |
        Where-Object { -not $script:LoosePsm1Map.ContainsKey($_.Name) } |
        ForEach-Object {
            $destPath = Join-Path $script:B11Root "PowerShell\Modules\B11.System\Source\Legacy\$($_.Name)"
            Invoke-SafeCopy -SourcePath $_.FullName -DestPath $destPath -Reason 'LegacyPsm1-Extra'
        }
}

function Invoke-MigrateProfileMega {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 3 — ProfileMega + UltraProfile patches → B11.BetterShell\Source\ProfileMega' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    $destBase = Join-Path $script:B11Root 'PowerShell\Modules\B11.BetterShell\Source\ProfileMega'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'ProfileMega') `
                    -DestDir   $destBase `
                    -Reason    'ProfileMega'

    foreach ($patchDir in $script:ProfileMegaPatches) {
        Invoke-CopyTree -SourceDir (Join-Path $Source $patchDir) `
                        -DestDir   (Join-Path $destBase "Patches\$patchDir") `
                        -Reason    'UltraProfile-Patch'
    }

    Invoke-CopyTree -SourceDir (Join-Path $Source 'PowerShellProfile-files') `
                    -DestDir   (Join-Path $destBase 'PowerShellProfile-files') `
                    -Reason    'PSProfile-Files'
}

function Invoke-MigrateAutomation {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 4 — ConnorOS / PostInstall / Onboarding → B11.Automation\Source' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    foreach ($dirName in $script:AutomationSources) {
        Invoke-CopyTree -SourceDir (Join-Path $Source $dirName) `
                        -DestDir   (Join-Path $script:B11Root "PowerShell\Modules\B11.Automation\Source\$dirName") `
                        -Reason    "Automation-$dirName"
    }
}

function Invoke-MigrateBetterPE {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 5 — My-WinPE-RE + deployment → B11.BetterPE\Source' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    $peSourceBase = Join-Path $script:B11Root 'PowerShell\Modules\B11.BetterPE\Source'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'My-WinPE-RE') `
                    -DestDir   (Join-Path $peSourceBase 'WinPE-RE') `
                    -Reason    'BetterPE-WinPE-RE'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'deployment') `
                    -DestDir   (Join-Path $peSourceBase 'DeploymentScripts') `
                    -Reason    'BetterPE-Deployment'

    # Specific WinPE .psm1s from the flat modules/ directory
    $moduleSrc = Join-Path $Source 'modules'
    foreach ($modFile in $script:WinPELegacyMods) {
        $candidate = Join-Path $moduleSrc $modFile
        if (Test-Path $candidate) {
            Invoke-SafeCopy -SourcePath $candidate `
                            -DestPath   (Join-Path $peSourceBase "Legacy\$modFile") `
                            -Reason     'BetterPE-LegacyMod'
        }
    }
}

function Invoke-MigrateTools {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 6 — Standalone tools → D:\Dev\Better11\tools\' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    # DeployForge — prefer GitHub version (more history / docs)
    $dfSrc = Join-Path $Source 'GitHub\DeployForge'
    if (-not (Test-Path $dfSrc)) { $dfSrc = Join-Path $Source 'DeployForge' }
    Invoke-CopyTree -SourceDir $dfSrc `
                    -DestDir   (Join-Path $script:B11Root 'tools\DeployForge') `
                    -Reason    'Tool-DeployForge' `
                    -ExcludeSubDirs @('.git')

    Invoke-CopyTree -SourceDir (Join-Path $Source 'deployment-toolkit') `
                    -DestDir   (Join-Path $script:B11Root 'tools\deployment-toolkit') `
                    -Reason    'Tool-DeployToolkit' `
                    -ExcludeSubDirs @('.git')

    Invoke-CopyTree -SourceDir (Join-Path $Source 'dev-dashboard') `
                    -DestDir   (Join-Path $script:B11Root 'tools\dev-dashboard') `
                    -Reason    'Tool-DevDashboard' `
                    -ExcludeSubDirs @('.git')

    Invoke-CopyTree -SourceDir (Join-Path $Source 'ntlite-configs-main') `
                    -DestDir   (Join-Path $script:B11Root 'tools\NTLite') `
                    -Reason    'Tool-NTLite' `
                    -ExcludeSubDirs @('.git', 'images')

    # Claude tooling
    Invoke-CopyTree -SourceDir (Join-Path $Source 'claude-agents') `
                    -DestDir   (Join-Path $script:B11Root '.claude\agents') `
                    -Reason    'Claude-Agents'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'Skills') `
                    -DestDir   (Join-Path $script:B11Root '.claude\skills') `
                    -Reason    'Claude-Skills'

    # Shell extras → BetterShell\Source
    foreach ($extra in $script:ShellExtras) {
        Invoke-CopyTree -SourceDir (Join-Path $Source $extra) `
                        -DestDir   (Join-Path $script:B11Root "PowerShell\Modules\B11.BetterShell\Source\$extra") `
                        -Reason    "ShellExtra-$extra"
    }

    # Security baselines
    foreach ($baseline in $script:SecurityBaselineDirs) {
        $safeName = ($baseline -replace '[^\w\-\. ]', '' -replace '\s+', '-').Trim('-')
        Invoke-CopyTree -SourceDir (Join-Path $Source $baseline) `
                        -DestDir   (Join-Path $script:B11Root "tools\SecurityBaselines\$safeName") `
                        -Reason    'SecurityBaseline'
    }
}

function Invoke-MigratePlatform {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 7 — platform\ → D:\Dev\Better11\platform\' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    Invoke-CopyTree -SourceDir (Join-Path $Source 'platform') `
                    -DestDir   (Join-Path $script:B11Root 'platform') `
                    -Reason    'Platform'
}

function Invoke-MigrateGitHubRepos {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 8 — GitHub unique repos → D:\Dev\GitHub\' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    $githubSrc  = Join-Path $Source 'GitHub'
    $githubDest = Join-Path $Destination 'GitHub'

    foreach ($repo in $script:GitHubUniqueRepos) {
        Invoke-CopyTree -SourceDir (Join-Path $githubSrc $repo) `
                        -DestDir   (Join-Path $githubDest $repo) `
                        -Reason    "GitHub-$repo" `
                        -ExcludeSubDirs @('.git')
    }
}

function Invoke-MigrateDotFiles {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 9 — DotFiles → D:\Dev\DotFiles\' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    Invoke-CopyTree -SourceDir (Join-Path $Source 'DotFiles') `
                    -DestDir   (Join-Path $Destination 'DotFiles') `
                    -Reason    'DotFiles' `
                    -ExcludeSubDirs @(
                        '.git', '.venv',
                        '.quarantine_20251120-191327',
                        '.quarantine_20251120-191327(1)'
                    )
}

function Invoke-MigrateSharedAssets {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    Write-MigLog ('━' * 62) -Level SECTION
    Write-MigLog 'STEP 10 — docs / configs / data / scripts / PowerShell profiles' -Level SECTION
    Write-MigLog ('━' * 62) -Level SECTION

    Invoke-CopyTree -SourceDir (Join-Path $Source 'docs') `
                    -DestDir   (Join-Path $script:B11Root 'docs') `
                    -Reason    'Docs-Merge'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'Documentation') `
                    -DestDir   (Join-Path $script:B11Root 'docs\Archive') `
                    -Reason    'Documentation-Archive'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'configs') `
                    -DestDir   (Join-Path $script:B11Root 'config\BaseConfigs') `
                    -Reason    'Configs-Merge'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'data') `
                    -DestDir   (Join-Path $script:B11Root 'config\data') `
                    -Reason    'Data-Merge'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'apps') `
                    -DestDir   (Join-Path $script:B11Root 'config\apps') `
                    -Reason    'Apps-Catalog'

    # Only .ps1 files from root scripts/ directory
    $rootScriptsDst = Join-Path $script:B11Root 'scripts'
    Get-ChildItem -Path (Join-Path $Source 'scripts') -File -Filter '*.ps1' -ErrorAction SilentlyContinue |
        ForEach-Object {
            Invoke-SafeCopy -SourcePath $_.FullName `
                            -DestPath   (Join-Path $rootScriptsDst $_.Name) `
                            -Reason     'Scripts-Root'
        }

    # PowerShell profiles (skip Modules — handled per B11 module)
    Invoke-CopyTree -SourceDir (Join-Path $Source 'PowerShell') `
                    -DestDir   (Join-Path $script:B11Root 'PowerShell') `
                    -Reason    'PSProfile' `
                    -ExcludeSubDirs @('Modules')

    # OEM setup
    Invoke-CopyTree -SourceDir (Join-Path $Source '$OEM$') `
                    -DestDir   (Join-Path $script:B11Root 'tools\OEM') `
                    -Reason    'OEM'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'bootstrap') `
                    -DestDir   (Join-Path $script:B11Root 'tools\bootstrap') `
                    -Reason    'Bootstrap'

    Invoke-CopyTree -SourceDir (Join-Path $Source 'Shared') `
                    -DestDir   (Join-Path $script:B11Root 'tools\Shared') `
                    -Reason    'Shared'

    # Root-level .ps1 scripts (misc ones not in scripts/)
    [string[]] $rootPs1Skip = @(
        'MEGA-PROFILE.ps1', 'Enhanced-Profile.ps1',
        'Microsoft.PowerShell_profile_v2_ENHANCED.ps1'
    )

    Get-ChildItem -Path $Source -File -Filter '*.ps1' -ErrorAction SilentlyContinue |
        Where-Object { $rootPs1Skip -notcontains $_.Name } |
        ForEach-Object {
            Invoke-SafeCopy -SourcePath $_.FullName `
                            -DestPath   (Join-Path $script:B11Root "scripts\Root\$($_.Name)") `
                            -Reason     'Root-PS1'
        }

    # External modules from flat modules/ (folder-based, not individual .psm1s)
    $moduleSrc = Join-Path $Source 'modules'
    [string[]] $skipModDirs = @(
        'powershell', 'WinPE-Toolkit', 'Pester',
        'Microsoft.PowerShell.PSResourceGet', 'Carbon',
        '7Zip4Powershell', 'VcRedist', 'WinGet-Essentials'
    )

    if (Test-Path $moduleSrc) {
        Get-ChildItem -Path $moduleSrc -Directory -ErrorAction SilentlyContinue |
            Where-Object { $skipModDirs -notcontains $_.Name } |
            ForEach-Object {
                Invoke-CopyTree -SourceDir $_.FullName `
                                -DestDir   (Join-Path $script:B11Root "PowerShell\Modules\External\$($_.Name)") `
                                -Reason    "ExtModule-$($_.Name)"
            }
    }
}

#endregion

#region ── Report ────────────────────────────────────────────────────────────────

function Write-MigrationReport {
    [CmdletBinding()]
    [OutputType([void])]
    param()

    $whatIfLabel = if ($script:IsWhatIf) { ' [DRY RUN — no files were written]' } else { '' }

    $report = @"

$('═' * 62)
  MIGRATION REPORT$whatIfLabel
  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$('═' * 62)
  Source      : $Source
  Destination : $Destination
  Log         : $script:LogPath
$('─' * 62)
  Files Copied  : $($script:CopiedCount)
  Files Skipped : $($script:SkippedCount)
  Errors        : $($script:ErrorCount)
$('─' * 62)
  NEXT STEPS (after verifying migration):
  1. Review D:\Dev\Better11\PowerShell\Modules\*\Source\Legacy\
     Consolidate useful functions into live B11 module Public\ dirs.
  2. Review D:\Dev\Better11\tools\DeployForge\
     Decide if it should be its own repo under D:\Dev\GitHub\.
  3. Re-add git remotes for repos in D:\Dev\GitHub\ as needed.
  4. Update IDE/editor workspace paths from OneDrive\Dev to D:\Dev.
  5. Once fully verified, delete the OneDrive source:
     Remove-Item -Path '$Source' -Recurse -Force
$('═' * 62)
"@

    Write-Host $report -ForegroundColor Cyan
    [System.IO.File]::AppendAllText($script:LogPath, $report, [System.Text.Encoding]::UTF8)
}

#endregion

#region ── Entry Point ───────────────────────────────────────────────────────────

function Invoke-DevMigration {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([void])]
    param()

    # Use .NET to create log file — bypasses WhatIf on New-Item
    [System.IO.Directory]::CreateDirectory((Split-Path $script:LogPath -Parent)) | Out-Null
    [System.IO.File]::WriteAllText($script:LogPath, '', [System.Text.Encoding]::UTF8)

    Write-MigLog "Migration started. WhatIf=$($script:IsWhatIf)" -Level INFO
    Write-MigLog "Source      : $Source" -Level INFO
    Write-MigLog "Destination : $Destination" -Level INFO

    if (-not (Test-Path $Source)) {
        Write-MigLog "Source path not found: $Source" -Level ERROR
        return
    }

    if (-not (Test-Path $Destination) -and -not $script:IsWhatIf) {
        [void](New-Item -ItemType Directory -Path $Destination -Force)
    }

    # Steps are called unconditionally — WhatIf is handled at the leaf (Invoke-SafeCopy)
    Invoke-MigrateB11
    Invoke-MigrateLoosePsm1
    Invoke-MigrateProfileMega
    Invoke-MigrateAutomation
    Invoke-MigrateBetterPE
    Invoke-MigrateTools
    Invoke-MigratePlatform
    Invoke-MigrateGitHubRepos
    Invoke-MigrateDotFiles
    Invoke-MigrateSharedAssets

    Write-MigrationReport
}

# ── Run ──────────────────────────────────────────────────────────────────────────
Invoke-DevMigration

#endregion
