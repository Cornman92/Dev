@{
    RootModule = 'InstallEngine.psm1'
    ModuleVersion = '0.1.0'
    GUID = '8d5d9ac2-3f7c-4a9a-9a8e-4b0de6b02001'
    Author = 'Windows Automation Workspace'
    CompanyName = 'Windows Automation Workspace'
    Copyright = '(c) 2024 Windows Automation Workspace. All rights reserved.'
    Description = 'Unified app install engine for winget and offline installers.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Install-Better11Apps','Install-WingetPackage','Install-OfflinePackage','Read-Better11Json')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Better11', 'Install', 'Winget', 'PackageManager')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Unified app install engine for Better11 Suite'
        }
    }
}
