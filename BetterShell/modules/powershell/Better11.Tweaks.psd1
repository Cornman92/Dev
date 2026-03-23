@{
    RootModule = 'Better11.Tweaks.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567895'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Better11.Tweaks - System tweaks and optimizations for Better11 Suite'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Set-Better11RegistryValue',
        'Get-Better11RegistryValue',
        'Apply-Better11GamingTweaks',
        'Apply-Better11PerformanceTweaks',
        'Apply-Better11PrivacyTweaks',
        'New-Better11Tweak',
        'Apply-Better11Tweaks'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Tweaks', 'Registry', 'Performance', 'Gaming', 'Privacy')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of Better11.Tweaks module'
        }
    }
}
