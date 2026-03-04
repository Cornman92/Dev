@{
    # Module manifest for the Dev workspace Functions library

    RootModule        = ''
    ModuleVersion     = '0.2.0'
    GUID              = 'b1c2d3e4-f5a6-7890-abcd-ef1234567890'
    Author            = 'C-Man'
    CompanyName       = ''
    Copyright         = '(c) 2025-2026 C-Man. All rights reserved.'
    Description       = 'Reusable PowerShell function library for the Dev workspace.'

    # Minimum PowerShell version
    PowerShellVersion = '5.1'

    # Functions to export
    FunctionsToExport = @(
        'Write-Log',
        'Get-SystemInfo',
        'Test-AdminPrivilege',
        'ConvertTo-HashtableSplat',
        'Get-FileHashBatch'
    )

    # Nested modules (dot-sourced function files)
    NestedModules     = @(
        'Write-Log.ps1',
        'Get-SystemInfo.ps1',
        'Test-AdminPrivilege.ps1',
        'ConvertTo-HashtableSplat.ps1',
        'Get-FileHashBatch.ps1'
    )

    # Private data
    PrivateData       = @{
        PSData = @{
            Tags       = @('utilities', 'logging', 'system-info', 'admin')
            ProjectUri = ''
        }
    }
}
