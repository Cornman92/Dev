@{
    RootModule            = 'Utilities.psm1'
    ModuleVersion         = '0.10.6'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '23564e03-315e-4ad7-a5f2-011c751025f4'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module with a collection of functions that should have been in PowerShell to start with.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName      = 'Admin'
            RequiredVersion = '1.1.3'
        }
        @{
            ModuleName      = 'Ast'
            RequiredVersion = '0.4.0'
        }
        @{
            ModuleName    = 'Hashtable'
            ModuleVersion = '1.1.1'
        }
    )
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Add-ModuleManifestData'
        'Add-PSModulePath'
        'Clear-GitRepo'
        'ConvertTo-Boolean'
        'Copy-Object'
        'Export-PowerShellDataFile'
        'Format-ModuleManifest'
        'Get-FileInfo'
        'Get-ModuleManifest'
        'Invoke-GitSquash'
        'Invoke-PruneModule'
        'Invoke-ReinstallModule'
        'Invoke-SquashBranch'
        'Remove-EmptyFolder'
        'Reset-GitRepo'
        'Restore-GitRepo'
        'Set-ModuleManifest'
        'Set-ScriptFileRequirement'
        'Set-WindowsSetting'
        'Show-FileContent'
        'Sync-GitRepo'
        'Sync-Repo'
        'Test-IsNotNullOrEmpty'
        'Test-IsNullOrEmpty'
        'Uninstall-Pester'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'IsNotNullOrEmpty'
        'IsNullOrEmpty'
        'Prune-Module'
        'Reinstall-Module'
        'Squash-Branch'
        'Squash-Main'
        'Sync-Git'
    )
    ModuleList            = @()
    FileList              = @(
        'Utilities.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'tools'
                'utility'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Utilities/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Utilities'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Utilities/main/icon/icon.png'
        }
    }
}
