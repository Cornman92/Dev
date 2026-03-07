#Requires -Module Pester

Describe 'B11.BetterPE.NetworkDeploy' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'Public' 'NetworkDeploy.ps1') -Force -ErrorAction SilentlyContinue

        # Mock external commands
        Mock wdsutil.exe { return 'Mocked WDS output' } -ErrorAction SilentlyContinue
        Mock Get-WindowsFeature { [PSCustomObject]@{ Installed = $false } } -ErrorAction SilentlyContinue
        Mock Install-WindowsFeature { [PSCustomObject]@{ Success = $true; RestartNeeded = 'No' } } -ErrorAction SilentlyContinue
        Mock Get-Service { [PSCustomObject]@{ Status = 'Stopped' } } -ErrorAction SilentlyContinue
    }

    Context 'Initialize-B11PxeServer' {
        It 'Should create TFTP directory structure' {
            $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "b11_pxe_test_$(Get-Random)"
            New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

            $result = Initialize-B11PxeServer -TftpRoot $testRoot -Architecture 'x64'
            $result | Should -Not -BeNullOrEmpty
            $result.Status | Should -Be 'Initialized'
            $result.Architecture | Should -Be 'x64'

            Test-Path (Join-Path $testRoot 'Boot') | Should -BeTrue
            Test-Path (Join-Path $testRoot 'Images') | Should -BeTrue
            Test-Path (Join-Path $testRoot 'Config') | Should -BeTrue

            Remove-Item $testRoot -Recurse -Force
        }
    }

    Context 'New-B11TftpConfig' {
        It 'Should create TFTP configuration file' {
            $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "b11_tftp_test_$(Get-Random)"
            New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

            $result = New-B11TftpConfig -TftpRoot $testRoot -Port 69
            $result.Status | Should -Be 'Created'
            $result.Port | Should -Be 69

            $configPath = Join-Path $testRoot 'tftp-config.json'
            Test-Path $configPath | Should -BeTrue

            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $config.Port | Should -Be 69

            Remove-Item $testRoot -Recurse -Force
        }
    }

    Context 'Start-B11NetworkDeployment' {
        It 'Should create deployment with correct metadata' {
            $testImage = Join-Path ([System.IO.Path]::GetTempPath()) "test.wim"
            New-Item -Path $testImage -ItemType File -Force | Out-Null

            $result = Start-B11NetworkDeployment -ImagePath $testImage -TargetMachines @('PC1', 'PC2', 'PC3')
            $result | Should -Not -BeNullOrEmpty
            $result.TargetCount | Should -Be 3
            $result.Status | Should -Be 'Running'
            $result.TransferMode | Should -Be 'Unicast'

            Remove-Item $testImage -Force
        }

        It 'Should support multicast mode' {
            $testImage = Join-Path ([System.IO.Path]::GetTempPath()) "test2.wim"
            New-Item -Path $testImage -ItemType File -Force | Out-Null

            $result = Start-B11NetworkDeployment -ImagePath $testImage -TargetMachines @('PC1') -TransferMode 'Multicast'
            $result.TransferMode | Should -Be 'Multicast'

            Remove-Item $testImage -Force
        }
    }
}
