@{
    RootModule = 'Integrity.psm1'
    ModuleVersion = '0.1.0'
    GUID = '2c1e6b9a-33f3-4f39-8f6d-7e5d4ef62001'
    Author = 'Aurora'
    Description = 'Integrity manifest creation and verification.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-AuroraFileHash','New-AuroraIntegrityManifest','Test-AuroraIntegrityManifest')
}
