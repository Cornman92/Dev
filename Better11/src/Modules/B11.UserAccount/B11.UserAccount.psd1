@{
    RootModule        = 'B11.UserAccount.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef0123456789'
    Author            = 'Better11'
    CompanyName       = 'Better11'
    Copyright         = 'Copyright (c) 2026 Better11. All rights reserved.'
    Description       = 'User account management module for Better11.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Get-B11LocalAccount','New-B11LocalAccount','Remove-B11LocalAccount','Set-B11AccountEnabled',
        'Get-B11LocalGroup','Get-B11GroupMember','Add-B11GroupMember','Remove-B11GroupMember',
        'Get-B11PasswordPolicy','Set-B11PasswordPolicy',
        'Get-B11AutoLogin','Set-B11AutoLogin','Disable-B11AutoLogin',
        'Get-B11UserProfile',
        'Get-B11SecurityAudit',
        'Get-B11UserSession','Stop-B11UserSession'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{ PSData = @{} }
}
