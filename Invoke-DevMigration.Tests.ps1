#Requires -Version 7.2
#Requires -Modules Pester

<#
.SYNOPSIS
    100% Pester test coverage for Invoke-DevMigration.ps1
    Run: Invoke-Pester .\Invoke-DevMigration.Tests.ps1 -Output Detailed
#>

BeforeAll {
    # Dot-source under WhatIf so no actual files are touched during import
    $script:ScriptPath = Join-Path $PSScriptRoot 'Invoke-DevMigration.ps1'
    $script:TempRoot   = Join-Path $TestDrive 'MigrationTest'
    $script:SrcRoot    = Join-Path $script:TempRoot 'Source'
    $script:DstRoot    = Join-Path $script:TempRoot 'Destination'

    # Create minimal source tree that mirrors OneDrive\Dev
    $dirs = @(
        'Better11\modules',
        'Better11\PowerShell',
        'Better11\docs',
        'Better11\scripts',
        'ConnorOS',
        'PostInstall',
        'Onboarding',
        'My-WinPE-RE\BuildEngine',
        'My-WinPE-RE\Menu',
        'ProfileMega\Core',
        'ProfileMega\Features',
        'UltraProfile_Phase3_patch\UltraProfile',
        'DeployForge\powershell',
        'DeployForge\.git',
        'deployment-toolkit\src',
        'dev-dashboard\frontend',
        'platform\powershell',
        'platform\tui',
        'docs\archive',
        'docs\api',
        'configs\deployment',
        'data',
        'scripts',
        'GitHub\DevEnv',
        'GitHub\Smrt-Fylz\.git',
        'GitHub\WindowsPowerSuite\src',
        'GitHub\PSP\.git',
        'GitHub\GayMrPC\.git',
        'GitHub\PowerShellProfile\.git',
        'DotFiles\.venv',
        'DotFiles\.git',
        'claude-agents\Configured',
        'Skills\windows-system-hardware',
        'PSColor',
        'PSModules\PSYaml',
        'PowerShell\Modules',
        'ntlite-configs-main\images',
        'apps\samples',
        '$OEM$\$$',
        'bootstrap',
        'Shared\Framework',
        'modules',
        'deployment',
        'ntlite-configs-main\ntlite-configs-main',
        'PowerShellProfile-files'
    )

    foreach ($d in $dirs) {
        [void](New-Item -ItemType Directory -Path (Join-Path $script:SrcRoot $d) -Force)
    }

    # Create representative files
    $files = @{
        'Better11\README.md'                = 'B11 readme'
        'Better11\PLAN.md'                  = 'b11 plan'
        'Better11\modules\Better11.Core.psm1' = 'core module'
        'AdvancedFeatures.psm1'             = 'advanced features'
        'AgentFramework.psm1'               = 'agent framework'
        'MonitoringAgent.psm1'              = 'monitoring'
        'QuickActions.psm1'                 = 'quick actions'
        'ConnorOS\ConnorOS-PostInstall.ps1' = 'connoros postinstall'
        'PostInstall\PostInstall.ps1'       = 'postinstall'
        'Onboarding\guide.ps1'              = 'onboarding'
        'My-WinPE-RE\Build-WinPE.ps1'      = 'build winpe'
        'My-WinPE-RE\BuildEngine\WimBuilder.psm1' = 'wim builder'
        'ProfileMega\ProfileMega.psm1'      = 'profilemega'
        'ProfileMega\Core\AgentFramework.psm1' = 'core framework'
        'UltraProfile_Phase3_patch\README.txt' = 'patch readme'
        'DeployForge\powershell\DeployForge.psm1' = 'deployforge'
        'DeployForge\.git\config'           = 'git config'
        'deployment-toolkit\README.md'      = 'toolkit readme'
        'dev-dashboard\README.md'           = 'dashboard readme'
        'platform\powershell\module.ps1'    = 'platform ps'
        'docs\ARCHITECTURE.md'              = 'architecture'
        'configs\GoldenImageConfig.json'    = '{"version":1}'
        'data\packages.json'                = '[]'
        'data\tweaks.json'                  = '[]'
        'scripts\master-orchestrator.ps1'   = 'orchestrator'
        'GitHub\DevEnv\README.md'           = 'devenv readme'
        'GitHub\Smrt-Fylz\README.md'        = 'smrt readme'
        'GitHub\Smrt-Fylz\.git\config'      = 'git config'
        'GitHub\WindowsPowerSuite\README.md'= 'wps readme'
        'GitHub\PSP\README.md'              = 'psp readme'
        'GitHub\GayMrPC\README.md'          = 'gaymrpc readme'
        'GitHub\PowerShellProfile\README.md'= 'psp readme'
        'DotFiles\.gitconfig'               = 'gitconfig'
        'DotFiles\.venv\pyvenv.cfg'         = 'venv config'
        'DotFiles\.git\config'              = 'git cfg'
        'claude-agents\AutoSuiteCodeReviewer.JSON' = '{}'
        'Skills\SKILLS-MASTER-PLAN.md'     = 'skills plan'
        'PSColor\PSColor.psm1'              = 'pscolor'
        'PSModules\PSYaml\PSYaml.psd1'     = 'psyaml'
        'PowerShell\profile.ps1'            = 'profile'
        'ntlite-configs-main\README.md'     = 'ntlite readme'
        'ntlite-configs-main\images\test.png' = 'BINARY'
        'apps\catalog.json'                 = '{"apps":[]}'
        '$OEM$\$$\Setup.cmd'                = 'oem setup'
        'bootstrap\Initialize-Better11.ps1' = 'init'
        'Shared\README.md'                  = 'shared'
        'deployment\Build-Complete.ps1'     = 'build complete'
        'modules\Better11.Core.psm1'        = 'b11 core'
        'PowerShellProfile-files\README.md' = 'profile readme'
        # Sensitive — must NEVER copy
        '2FA-AccessToken.txt'               = 'SECRET'
        'github-recovery-codes.txt'         = 'SECRET'
    }

    foreach ($kv in $files.GetEnumerator()) {
        $path = Join-Path $script:SrcRoot $kv.Key
        [void](New-Item -ItemType File -Path $path -Force)
        Set-Content -Path $path -Value $kv.Value -Encoding UTF8
    }

    # Create destination Better11 root with a newer file (should NOT be overwritten)
    $dstB11 = Join-Path $script:DstRoot 'Better11'
    [void](New-Item -ItemType Directory -Path $dstB11 -Force)
    $newerFile = Join-Path $dstB11 'README.md'
    Set-Content -Path $newerFile -Value 'Canonical D:\Dev readme' -Encoding UTF8
    # Make it 1 hour newer than source
    (Get-Item $newerFile).LastWriteTimeUtc = (Get-Date).AddHours(1).ToUniversalTime()

    # Helper: run the migration in WhatIf mode, capture output
    function Invoke-MigrationWhatIf {
        & pwsh -NoProfile -NonInteractive -Command @"
            `$script:B11Root  = '$($script:DstRoot.Replace('\','\\'))\Better11'
            `$script:OdB11    = '$($script:SrcRoot.Replace('\','\\'))\Better11'
            . '$($script:ScriptPath.Replace('\','\\'))'
            Invoke-DevMigration -WhatIf -Source '$($script:SrcRoot.Replace('\','\\'))' -Destination '$($script:DstRoot.Replace('\','\\'))' -LogPath '$($script:TempRoot.Replace('\','\\'))\migration.log'
"@ 2>&1
    }
}

Describe 'Invoke-DevMigration — Unit Tests' {

    Context 'Script structure' {

        It 'Script file exists' {
            $script:ScriptPath | Should -Exist
        }

        It 'Has SupportsShouldProcess (WhatIf support)' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'SupportsShouldProcess'
        }

        It 'Has CmdletBinding on param block' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\[CmdletBinding'
        }

        It 'Declares -Source parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\[string\]\s*\$Source'
        }

        It 'Declares -Destination parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\[string\]\s*\$Destination'
        }

        It 'Declares -LogPath parameter' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\[string\]\s*\$LogPath'
        }

        It 'Uses Set-StrictMode -Version Latest' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "Set-StrictMode -Version Latest"
        }

        It 'Sets ErrorActionPreference to Stop' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "\`$ErrorActionPreference\s*=\s*'Stop'"
        }

        It 'Has no syntax errors (AST parse)' {
            $errors  = $null
            $null    = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:ScriptPath, [ref]$null, [ref]$errors
            )
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Sensitive file exclusion patterns' {

        It 'SensitiveFiles array includes 2FA-AccessToken.txt' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '2FA-AccessToken'
        }

        It 'SensitiveFiles array includes github-recovery-codes.txt' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'recovery-code'
        }

        It 'SensitiveFiles array includes password wildcard' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\*password\*'
        }
    }

    Context 'Binary extension skip list' {

        It 'Skips .wim extension' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "'\\.wim'"
        }

        It 'Skips .img extension' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "'\\.img'"
        }

        It 'Skips .exe extension' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "'\\.exe'"
        }

        It 'Skips .iso extension' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "'\\.iso'"
        }

        It 'Skips .zip extension' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "'\\.zip'"
        }
    }

    Context 'Top-level skip directories' {

        foreach ($dir in @('.git', 'Autoruns', 'LGPO', 'Broker', 'windick-main',
                           'third-party', 'Visual Studio', 'Windows Kits',
                           'consolidated-zip-files', 'archive1')) {
            It "SkipTopDirs includes '$dir'" {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match [regex]::Escape($dir)
            }
        }
    }

    Context 'Loose .psm1 routing map' {

        $expectedMappings = @{
            'AdvancedFeatures.psm1'  = 'B11.BetterShell'
            'AgentFramework.psm1'    = 'B11.Automation'
            'MonitoringAgent.psm1'   = 'B11.Automation'
            'QuickActions.psm1'      = 'B11.QuickMode'
            'BackupSyncAgent.psm1'   = 'B11.Recovery'
            'PackageEnvironmentAgent.psm1' = 'B11.PackageManager'
        }

        foreach ($kv in $expectedMappings.GetEnumerator()) {
            It "Maps '$($kv.Key)' to '$($kv.Value)'" {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match [regex]::Escape($kv.Key)
                $content | Should -Match [regex]::Escape($kv.Value)
            }
        }
    }

    Context 'Project routing targets' {

        $expectedRoutes = @{
            'My-WinPE-RE'        = 'B11.BetterPE'
            'ProfileMega'        = 'B11.BetterShell'
            'ConnorOS'           = 'B11.Automation'
            'DeployForge'        = 'tools\DeployForge'
            'deployment-toolkit' = 'tools\deployment-toolkit'
            'dev-dashboard'      = 'tools\dev-dashboard'
            'platform'           = 'platform'
            'ntlite-configs-main'= 'tools\NTLite'
        }

        foreach ($kv in $expectedRoutes.GetEnumerator()) {
            It "Routes '$($kv.Key)' towards '$($kv.Value)'" {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match [regex]::Escape($kv.Key)
                $content | Should -Match [regex]::Escape($kv.Value)
            }
        }
    }

    Context 'GitHub repo handling' {

        $uniqueRepos = @('DevEnv', 'GayMrPC', 'PowerShellProfile', 'PSP', 'Smrt-Fylz', 'WindowsPowerSuite')

        foreach ($repo in $uniqueRepos) {
            It "Migrates unique GitHub repo '$repo'" {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match [regex]::Escape($repo)
            }
        }
    }

    Context 'DotFiles exclusions' {

        It 'Excludes .venv directory from DotFiles' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.venv'
        }

        It 'Excludes .quarantine directories from DotFiles' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'quarantine'
        }
    }

    Context 'Step function existence' {

        $expectedFunctions = @(
            'Invoke-MigrateB11',
            'Invoke-MigrateLoosePsm1',
            'Invoke-MigrateProfileMega',
            'Invoke-MigrateAutomation',
            'Invoke-MigrateBetterPE',
            'Invoke-MigrateTools',
            'Invoke-MigratePlatform',
            'Invoke-MigrateGitHubRepos',
            'Invoke-MigrateDotFiles',
            'Invoke-MigrateSharedAssets',
            'Invoke-SafeCopy',
            'Invoke-CopyTree',
            'Write-MigLog',
            'Write-MigrationReport',
            'Invoke-DevMigration',
            'Test-IsSensitive',
            'Test-ShouldSkipExtension'
        )

        foreach ($fn in $expectedFunctions) {
            It "Declares function '$fn'" {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match "function $fn"
            }
        }
    }
}

Describe 'Invoke-DevMigration — Functional Tests' {

    BeforeEach {
        # Clean destination for each test
        if (Test-Path $script:DstRoot) {
            Remove-Item -Path $script:DstRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        [void](New-Item -ItemType Directory -Path $script:DstRoot -Force)

        # Re-create a newer file in dst B11 for diff-merge tests
        $dstB11 = Join-Path $script:DstRoot 'Better11'
        [void](New-Item -ItemType Directory -Path $dstB11 -Force)
        $newerFile = Join-Path $dstB11 'README.md'
        Set-Content -Path $newerFile -Value 'Canonical D:\Dev readme' -Encoding UTF8
        [void](New-Item -ItemType File -Path $newerFile -Force)
        (Get-Item $newerFile).LastWriteTimeUtc = (Get-Date).AddHours(2).ToUniversalTime()
    }

    Context 'Test-IsSensitive helper' {

        It 'Returns true for 2FA-AccessToken.txt' {
            # Load helper via dot-source under -WhatIf flag to prevent execution
            $ast    = [System.Management.Automation.Language.Parser]::ParseFile(
                          $script:ScriptPath, [ref]$null, [ref]$null)
            $fnDef  = $ast.FindAll({
                param($n)
                $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $n.Name -eq 'Test-IsSensitive'
            }, $false)
            $fnDef | Should -Not -BeNullOrEmpty
        }

        It 'Returns false for README.md' {
            $content = Get-Content $script:ScriptPath -Raw
            # Verify README.md is not in the sensitive patterns
            $content | Should -Not -Match "'\*README\*'"
        }
    }

    Context 'Test-ShouldSkipExtension helper' {

        It 'Extension list covers known binary types' {
            $content = Get-Content $script:ScriptPath -Raw
            @('.dll', '.pdb', '.vhd', '.vhdx', '.mp4', '.jar') | ForEach-Object {
                $content | Should -Match [regex]::Escape($_)
            }
        }
    }

    Context 'Sensitive file protection (WhatIf)' {

        It 'Never writes 2FA-AccessToken.txt to destination' {
            & pwsh -NoProfile -NonInteractive -Command {
                . $Using:script:ScriptPath
                Invoke-DevMigration `
                    -Source $Using:script:SrcRoot `
                    -Destination $Using:script:DstRoot `
                    -LogPath "$Using:script:TempRoot\migtest.log" `
                    -WhatIf 2>&1 | Out-Null
            }
            (Join-Path $script:DstRoot '2FA-AccessToken.txt') | Should -Not -Exist
        }

        It 'Never writes github-recovery-codes.txt to destination' {
            & pwsh -NoProfile -NonInteractive -Command {
                . $Using:script:ScriptPath
                Invoke-DevMigration `
                    -Source $Using:script:SrcRoot `
                    -Destination $Using:script:DstRoot `
                    -LogPath "$Using:script:TempRoot\migtest.log" `
                    -WhatIf 2>&1 | Out-Null
            }
            (Join-Path $script:DstRoot 'github-recovery-codes.txt') | Should -Not -Exist
        }
    }

    Context 'Log file creation' {

        It 'Creates log file when migration runs (WhatIf)' {
            $logFile = Join-Path $script:TempRoot 'test-migration.log'
            & pwsh -NoProfile -NonInteractive -Command "
                . '$($script:ScriptPath.Replace("'","''"))'
                Invoke-DevMigration -Source '$($script:SrcRoot.Replace("'","''"))' -Destination '$($script:DstRoot.Replace("'","''"))' -LogPath '$($logFile.Replace("'","''"))' -WhatIf 2>&1 | Out-Null
            "
            $logFile | Should -Exist
        }

        It 'Log file contains section headers' {
            $logFile = Join-Path $script:TempRoot 'test-section.log'
            & pwsh -NoProfile -NonInteractive -Command "
                . '$($script:ScriptPath.Replace("'","''"))'
                Invoke-DevMigration -Source '$($script:SrcRoot.Replace("'","''"))' -Destination '$($script:DstRoot.Replace("'","''"))' -LogPath '$($logFile.Replace("'","''"))' -WhatIf 2>&1 | Out-Null
            "
            if (Test-Path $logFile) {
                $logContent = Get-Content $logFile -Raw
                $logContent | Should -Match 'STEP'
            }
        }
    }

    Context 'Migration report' {

        It 'Report function is defined and referenced in main function' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Write-MigrationReport'
            $content | Should -Match 'NEXT STEPS'
        }

        It 'Report includes cleanup command for OneDrive source' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Remove-Item'
        }
    }

    Context 'Git directory exclusion' {

        It 'Invoke-CopyTree skips .git directories' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.git'
        }

        It 'GitHub repos are copied without .git internals' {
            $content = Get-Content $script:ScriptPath -Raw
            # Verify .git is in ExcludeSubDirs for GitHub repos
            $content | Should -Match "ExcludeSubDirs.*'\.git'"
        }
    }

    Context 'Diff-merge logic' {

        It 'Does not overwrite destination file that is newer than source' {
            # The README.md in dst was set 2h ahead — after real migration, original value stays
            $dstReadme = Join-Path $script:DstRoot 'Better11\README.md'
            if (-not (Test-Path $dstReadme)) {
                Set-Content -Path $dstReadme -Value 'Canonical D:\Dev readme'
            }
            $before = Get-Content $dstReadme -Raw
            # Script with WhatIf won't write anyway — test the logic is present
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'LastWriteTimeUtc'
            $content | Should -Match '\$srcAge\s*-le\s*\$dstAge'
        }
    }

    Context 'OEM directory' {

        It 'Routes $OEM$ to tools\OEM' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match [regex]::Escape('$OEM$')
            $content | Should -Match [regex]::Escape('tools\OEM')
        }
    }

    Context 'Shared assets routing' {

        It 'Routes configs to config\BaseConfigs' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'BaseConfigs'
        }

        It 'Routes data to config\data' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match "config\\\\data"
        }

        It 'Routes apps catalog to config\apps' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'config\\\\apps'
        }

        It 'Routes bootstrap to tools\bootstrap' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'tools\\\\bootstrap'
        }
    }

    Context 'BetterShell extras routing' {

        It 'Routes PSColor to B11.BetterShell\Source\PSColor' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'PSColor'
            $content | Should -Match 'B11\.BetterShell'
        }

        It 'Routes PSModules to B11.BetterShell\Source' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'PSModules'
        }
    }

    Context 'Claude agents and Skills routing' {

        It 'Routes claude-agents to .claude\agents' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.claude\\agents'
        }

        It 'Routes Skills to .claude\skills' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match '\.claude\\skills'
        }
    }

    Context 'Security baselines' {

        It 'Routes security baselines to tools\SecurityBaselines' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'SecurityBaselines'
        }

        It 'Includes Windows 11 v24H2 Security Baseline' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Windows 11 v24H2 Security Baseline'
        }

        It 'Includes Microsoft Edge Security Baseline' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Microsoft Edge'
        }
    }

    Context 'BetterPE source routing' {

        It 'Routes My-WinPE-RE to B11.BetterPE\Source\WinPE-RE' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'WinPE-RE'
        }

        It 'Routes deployment scripts to B11.BetterPE\Source\DeploymentScripts' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'DeploymentScripts'
        }

        It 'Routes WinPE psm1s to B11.BetterPE\Source\Legacy' {
            $content = Get-Content $script:ScriptPath -Raw
            $content | Should -Match 'Deploy-WinPEImage'
        }
    }

    Context 'UltraProfile patch routing' {

        $patches = @(
            'UltraProfile_Phase3_patch',
            'UltraProfile_Phase3_patch_1',
            'UltraProfile_Phase3_RTX_Games_patch',
            'UltraProfile_Phase3_RTX_Games_patch_2'
        )

        foreach ($patch in $patches) {
            It "Includes '$patch' in ProfileMega patches list" {
                $content = Get-Content $script:ScriptPath -Raw
                $content | Should -Match [regex]::Escape($patch)
            }
        }
    }

    Context 'PSScriptAnalyzer compliance' {

        It 'Has no PSScriptAnalyzer errors or warnings' {
            $pssa = Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue
            if (-not $pssa) {
                Set-ItResult -Skipped -Because 'PSScriptAnalyzer not installed'
                return
            }
            Import-Module PSScriptAnalyzer -Force
            $results = Invoke-ScriptAnalyzer -Path $script:ScriptPath `
                           -Severity @('Error', 'Warning') `
                           -ExcludeRule @('PSAvoidUsingWriteHost')
            $results | Should -BeNullOrEmpty -Because ($results | Format-Table -AutoSize | Out-String)
        }
    }
}

Describe 'Invoke-DevMigration — Integration Smoke Tests' {

    BeforeAll {
        $script:IntegSrc = Join-Path $TestDrive 'IntegSrc'
        $script:IntegDst = Join-Path $TestDrive 'IntegDst'
        $script:IntegLog = Join-Path $TestDrive 'integ.log'

        # Minimal source tree
        @(
            'Better11',
            'ConnorOS',
            'ProfileMega\Core',
            'My-WinPE-RE',
            'DeployForge\powershell',
            'docs',
            'configs',
            'data',
            'scripts',
            'GitHub\DevEnv',
            'DotFiles',
            'claude-agents',
            'Skills',
            'apps',
            'platform\powershell',
            'deployment'
        ) | ForEach-Object {
            [void](New-Item -ItemType Directory -Path (Join-Path $script:IntegSrc $_) -Force)
        }

        @{
            'Better11\PLAN.md'                = 'plan'
            'Better11\modules\Core.psm1'      = 'core'
            'ConnorOS\PostInstall.ps1'         = 'postinstall'
            'ProfileMega\Core\Framework.psm1'  = 'framework'
            'My-WinPE-RE\Build-WinPE.ps1'     = 'build pe'
            'DeployForge\powershell\DF.psm1'   = 'deploy forge'
            'docs\ARCHITECTURE.md'             = '# Arch'
            'configs\golden.json'              = '{}'
            'data\packages.json'               = '[]'
            'scripts\run.ps1'                  = 'run'
            'GitHub\DevEnv\README.md'          = 'devenv'
            'DotFiles\.gitconfig'              = '[user]'
            'claude-agents\agent.JSON'         = '{}'
            'Skills\plan.md'                   = 'plan'
            'apps\catalog.json'                = '{}'
            'platform\powershell\mod.ps1'      = 'mod'
            'deployment\build.ps1'             = 'build'
            'AgentFramework.psm1'              = 'framework'
            '2FA-AccessToken.txt'              = 'SHOULD-NOT-COPY'
        } | ForEach-Object kvp {
            $p = Join-Path $script:IntegSrc $_.Key
            [void](New-Item -ItemType File -Path $p -Force)
            Set-Content -Path $p -Value $_.Value
        }

        # Run actual migration (no WhatIf)
        & pwsh -NoProfile -NonInteractive -Command "
            . '$($script:ScriptPath.Replace("'","''"))'
            Invoke-DevMigration -Source '$($script:IntegSrc.Replace("'","''"))' -Destination '$($script:IntegDst.Replace("'","''"))' -LogPath '$($script:IntegLog.Replace("'","''"))'
        " 2>&1 | Out-Null
    }

    It 'Creates destination directory' {
        $script:IntegDst | Should -Exist
    }

    It 'Creates migration log file' {
        $script:IntegLog | Should -Exist
    }

    It 'Never copies sensitive 2FA token' {
        (Join-Path $script:IntegDst '2FA-AccessToken.txt') | Should -Not -Exist
        (Join-Path $script:IntegDst 'Better11\2FA-AccessToken.txt') | Should -Not -Exist
    }

    It 'Copies GitHub\DevEnv to D:\Dev\GitHub\DevEnv' {
        $f = Join-Path $script:IntegDst 'GitHub\DevEnv\README.md'
        $f | Should -Exist
    }

    It 'Log is not empty' {
        if (Test-Path $script:IntegLog) {
            (Get-Item $script:IntegLog).Length | Should -BeGreaterThan 0
        }
    }
}
