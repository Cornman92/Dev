@{
    RootModule        = 'PSPowerUtils.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-4a5b-8c7d-9e0f1a2b3c4d'
    Author            = 'Your Name'
    CompanyName       = 'Your Company'
    Copyright         = '(c) 2025. All rights reserved.'
    Description       = 'A comprehensive collection of PowerShell utilities'
    PowerShellVersion = '5.1'
    
    # Modules to import as nested modules
    NestedModules = @(
        'Core\ErrorHandling.psm1',
        'Core\Performance.psm1',
        'Core\Security.psm1',
        'Core\Productivity.psm1',
        'System\SystemInfo.psm1',
        'System\ProcessManager.psm1',
        'System\NetworkTools.psm1',
        'Dev\GitTools.psm1',
        'Dev\BuildTools.psm1',
        'Productivity\Clipboard.psm1',
        'Productivity\Backup.psm1',
        'Cloud\AzureTools.psm1',
        'Cloud\AwsTools.psm1'
    )
    
    # Functions to export
    FunctionsToExport = @(
        # Core
        'Write-ErrorLog',
        'Measure-CommandPerformance',
        'Test-ModuleSignature',
        'Enable-QuickEditMode',
        
        # System
        'Get-SystemInfo',
        'Get-ProcessInfo',
        'Get-NetworkInfo',
        
        # Dev
        'Invoke-GitOperation',
        'Start-Build',
        
        # Productivity
        'Copy-Enhanced',
        'Start-Backup',
        
        # Cloud
        'Connect-AzureCloud',
        'Connect-AwsCloud'
    )
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @(
        'cp',
        'ls',
        'grep'
    )
    
    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            Tags = @('Utilities', 'Productivity', 'System', 'Development', 'Cloud')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/yourusername/PSPowerUtils'
            ReleaseNotes = 'Initial release of PSPowerUtils'
        }
    }
}
