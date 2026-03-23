@{
    RootModule = 'Better11.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'b3773e11-0000-0000-0000-b3773e110000'
    Author = 'Better11 Team'
    Description = 'Better11 System Enhancement Suite'
    PowerShellVersion = '7.4'
    NestedModules = @(
        'Submodules\Better11.Core\Better11.Core.psd1',
        'Submodules\Better11.SystemOptimizer\Better11.SystemOptimizer.psd1',
        'Submodules\Better11.PackageManager\Better11.PackageManager.psd1',
        'Submodules\Better11.DriverManager\Better11.DriverManager.psd1',
        'Submodules\Better11.RegistryManager\Better11.RegistryManager.psd1',
        'Submodules\Better11.PrivacyDashboard\Better11.PrivacyDashboard.psd1',
        'Submodules\Better11.StartupManager\Better11.StartupManager.psd1',
        'Submodules\Better11.NetworkManager\Better11.NetworkManager.psd1',
        'Submodules\Better11.DiskCleanup\Better11.DiskCleanup.psd1',
        'Submodules\Better11.SystemInfo\Better11.SystemInfo.psd1'
    )
    FunctionsToExport = '*'
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
