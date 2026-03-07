@{
    RootModule        = 'ProfileMega.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'ProfileMega'
    Description       = 'PowerShell profile mega module: agents, utilities, quick actions, themes, and diagnostics.'
    PowerShellVersion = '7.0'
    RequiredModules   = @()
    NestedModules     = @()
    FunctionsToExport = @(
        'Initialize-AgentFramework', 'Stop-AgentFramework', 'Get-AgentStatus', 'Show-AgentDashboard',
        'Get-ProfileInfo', 'Invoke-ProfileDiagnostics', 'Set-ProfileTheme', 'Get-ProfileTheme',
        'Invoke-ProfileReload', 'Show-ProfileHelp', 'Get-ProfileCommand',
        'Export-ProfileConfig', 'Import-ProfileConfig',
        'Update-ProfileMega',
        'Set-LocationParent', 'Set-LocationGrandParent', 'Set-LocationHome',
        'git-status', 'git-add-all', 'git-commit', 'git-push', 'git-pull'
    )
    AliasesToExport   = @('..', '...', '~', 'gs', 'ga', 'gc', 'gp', 'gl', 'qh', 'clean', 'analyze', 'd', 'dc', 'k', 'profile-reload', 'profile-help', 'profile-info', 'profile-diagnostics')
    VariablesToExport = @('ProfileConfig', 'ProfileMegaRoot', 'ProfileLoaded', 'ProfileLoadTime', 'ProfileVersion')
    PrivateData       = @{
        PSData = @{
            Tags       = @('Profile', 'Productivity', 'Agents', 'DevOps')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}
