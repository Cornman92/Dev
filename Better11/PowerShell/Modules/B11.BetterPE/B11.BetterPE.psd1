@{
    RootModule        = 'B11.BetterPE.psm1'
    ModuleVersion     = '4.0.0'
    GUID              = 'b2c3d4e5-f6a7-8901-bcde-f12345678901'
    Author            = 'C-Man'
    CompanyName       = 'Better11'
    Copyright         = '(c) 2025-2026 C-Man. All rights reserved.'
    Description       = 'BetterPE v4.0 — Windows Imaging & Deployment Toolkit with PXE/WDS network deployment.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Initialize-B11PxeServer','Add-B11WdsBootImage','Add-B11WdsInstallImage',
        'New-B11MulticastSession','Get-B11WdsStatus','Install-B11WdsRole',
        'New-B11TftpConfig','Start-B11NetworkDeployment'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('BetterPE','WinPE','Imaging','Deployment','PXE','WDS','Better11')
            ProjectUri = 'https://github.com/better11/better11'
        }
    }
}
