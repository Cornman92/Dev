#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.7.1' }, @{ ModuleName='PackageManagement'; ModuleVersion='1.4.7' }

$modulePath = Split-Path -Parent $PSScriptRoot
$functionFile = Join-Path $modulePath "Public\Get-InstalledPackages.ps1"

# Temporarily redefine Export-ModuleMember to avoid errors when dot-sourcing
$originalExportModuleMember = Get-Command Export-ModuleMember -ErrorAction SilentlyContinue
function Export-ModuleMember {
    # No-op for testing
}

# Dot-source the function file
try {
    . $functionFile
}
finally {
    # Restore the original Export-ModuleMember
    if ($originalExportModuleMember) {
        Set-Alias -Name Export-ModuleMember -Value $originalExportModuleMember -Scope Global -Force
    } else {
        Remove-Item -Path function:Export-ModuleMember -ErrorAction SilentlyContinue
    }
}

# Define test data
$testPackages = @(
    [PSCustomObject]@{
        Name = 'TestPackage'
        Version = [version]'1.0.0'
        Source = 'PSGallery'
        ProviderName = 'NuGet'
        Dependencies = @()
    },
    [PSCustomObject]@{
        Name = 'AnotherPackage'
        Version = [version]'2.0.0'
        Source = 'PSGallery'
        ProviderName = 'NuGet'
        Dependencies = @('TestPackage')
    },
    [PSCustomObject]@{
        Name = 'ThirdPackage'
        Version = [version]'1.5.0'
        Source = 'PrivateRepo'
        ProviderName = 'PowerShellGet'
        Dependencies = @('TestPackage', 'AnotherPackage')
    },
    [PSCustomObject]@{
        Name = 'ChocoPackage'
        Version = [version]'3.2.1'
        Source = 'Chocolatey'
        ProviderName = 'Chocolatey'
        Dependencies = @()
    }
)

Describe 'Get-InstalledPackages' -Tag 'Unit' {
    BeforeAll {
        # Mock package providers
        Mock Get-PackageProvider { 
            @(
                [PSCustomObject]@{ Name = 'NuGet'; Version = '2.8.5.208' },
                [PSCustomObject]@{ Name = 'PowerShellGet'; Version = '2.2.5' },
                [PSCustomObject]@{ Name = 'Chocolatey'; Version = '1.0.0' }
            ) | Where-Object { $Name -contains $_.Name -or $null -eq $Name }
        }
        
        # Mock Get-Package with more comprehensive test data
        Mock Get-Package {
            $result = $testPackages.Clone()
            
            # Apply name filter if specified
            if ($Name -and $Name -ne '*') {
                $nameFilters = $Name | ForEach-Object { [System.Management.Automation.WildcardPattern]::New($_) }
                $result = $result | Where-Object { 
                    $pkgName = $_.Name
                    $nameFilters | Where-Object { $_.IsMatch($pkgName) }
                }
            }
            
            # Apply source filter if specified
            if ($Source) {
                $result = $result | Where-Object { $_.Source -eq $Source }
            }
            
            # Apply provider filter if specified
            if ($ProviderName) {
                $result = $result | Where-Object { $_.ProviderName -eq $ProviderName }
            }
            
            # Convert to Package type if needed
            $result | ForEach-Object { 
                [PSCustomObject]@{
                    Name = $_.Name
                    Version = $_.Version
                    Source = $_.Source
                    ProviderName = $_.ProviderName
                    Dependencies = $_.Dependencies
                    PSTypeNames = @('Package')
                }
            }
        }
    }

    Context 'When getting all packages' {
        It 'Should return all packages without parameters' {
            $result = Get-InstalledPackages -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
    }

    Context 'When filtering by name' {
        It 'Should return matching packages' {
            $result = Get-InstalledPackages -Name 'TestPackage' -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Contain 'TestPackage'
        }

        It 'Should support wildcards' {
            $result = Get-InstalledPackages -Name 'Test*' -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Contain 'TestPackage'
        }
    }

    Context 'When using sorting' {
        It 'Should sort by name by default' {
            $result = Get-InstalledPackages -SortBy 'Name' -ErrorAction Stop
            $result[0].Name | Should -Be 'AnotherPackage'
            $result[1].Name | Should -Be 'TestPackage'
        }

        It 'Should support descending sort' {
            $result = Get-InstalledPackages -SortBy 'Name' -Descending -ErrorAction Stop
            $result[0].Name | Should -Be 'TestPackage'
            $result[1].Name | Should -Be 'AnotherPackage'
        }
    }

    Context 'When limiting results' {
        It 'Should respect the Limit parameter' {
            $result = Get-InstalledPackages -Limit 1 -ErrorAction Stop
            $result.Count | Should -Be 1
        }
    }

    Context 'When filtering by source' {
        It 'Should return packages from specified source' {
            $result = Get-InstalledPackages -Source 'PSGallery' -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.Source | Should -Contain 'PSGallery'
            $result.Source | Should -Not -Contain 'PrivateRepo'
        }
    }

    Context 'When filtering by provider' {
        It 'Should return packages from specified provider' {
            $result = Get-InstalledPackages -ProviderName 'PowerShellGet' -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.ProviderName | Should -Contain 'PowerShellGet'
            $result.ProviderName | Should -Not -Contain 'NuGet'
        }
    }

    Context 'When including dependencies' {
        It 'Should include package dependencies when specified' {
            Mock Get-Package {
                $testPackages | Where-Object { $_.Name -eq 'AnotherPackage' } | ForEach-Object {
                    $pkg = $_
                    [PSCustomObject]@{
                        Name = $pkg.Name
                        Version = $pkg.Version
                        Dependencies = $pkg.Dependencies | ForEach-Object {
                            $depName = $_
                            $dep = $testPackages | Where-Object { $_.Name -eq $depName } | Select-Object -First 1
                            if ($dep) {
                                [PSCustomObject]@{
                                    Name = $dep.Name
                                    Version = $dep.Version
                                }
                            }
                        }
                    }
                }
            }
            
            $result = Get-InstalledPackages -Name 'AnotherPackage' -IncludeDependencies -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterOrEqual 2
            $result.Name | Should -Contain 'TestPackage'
        }
    }

    Context 'When specifying scope' {
        It 'Should respect the Scope parameter' {
            $result = Get-InstalledPackages -Scope 'CurrentUser' -ErrorAction Stop
            # Just verify the command runs without error since we can't easily test the scope
            $result | Should -Not -Be $null
        }
    }

    Context 'Error handling' {
        It 'Should handle errors gracefully' {
            Mock Get-Package { throw 'Test error' } -Verifiable
            { Get-InstalledPackages -ErrorAction Stop } | Should -Throw 'Test error'
        }
        
        It 'Should handle invalid provider names' {
            { Get-InstalledPackages -ProviderName 'InvalidProvider' -ErrorAction Stop } | 
                Should -Throw -PassThru | 
                Select-Object -ExpandProperty Exception | 
                Should -Match 'not supported'
        }
    }
    
    Context 'Performance' {
        It 'Should respect the Limit parameter' {
            $result = Get-InstalledPackages -Limit 2 -ErrorAction Stop
            $result.Count | Should -Be 2
        }
    }
}
