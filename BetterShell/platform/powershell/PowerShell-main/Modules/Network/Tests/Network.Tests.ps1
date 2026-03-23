#Requires -Version 5.1
#Requires -Modules Pester
#Requires -RunAsAdministrator

$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = Split-Path -Leaf $modulePath

# Import the module for testing
Import-Module $modulePath -Force

# Test configuration
$testHost = 'example.com'  # Using example.com as it's guaranteed to resolve
$testPort = 80             # HTTP port for testing

Describe "Network Module Tests" -Tag 'Network' {
    Context "Test-NetworkConnectivity" {
        It "Should successfully ping a known host" {
            $Get=Get-Module -Name Network -ListAvailable
            $result = Test-NetworkConnectivity -ComputerName $testHost -ErrorAction Stop
            $result.PingSuccess | Should -Be $true
            $result.ComputerName | Should -Be $testHost
        }

        It "Should test TCP port connectivity" {
            $result = Test-NetworkConnectivity -ComputerName $testHost -Port $testPort -ErrorAction Stop
            $result.PortOpen | Should -Be $true
        }

        It "Should handle invalid hosts gracefully" {
            $result = Test-NetworkConnectivity -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue
            $result.PingSuccess | Should -Be $false
        }
    }

    Context "Start-PortScan" {
        It "Should scan a single port" {
            $result = Start-PortScan -ComputerName 'localhost' -Port $testPort -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result.Port | Should -Be $testPort
            $result.Status | Should -Be 'Open'
        }

        It "Should scan multiple ports" {
            $ports = @(80, 443, 8080)
            $result = Start-PortScan -ComputerName $testHost -Port $ports -ErrorAction Stop
            $result.Count | Should -Be $ports.Count
            $result.Port | Should -Contain $testPort
        }
    }

    Context "Get-NetworkAdapter" {
        It "Should return network adapter information" {
            $Get=Get-Module -Name Network -Listavailable
            $result = Get-NetworkAdapter -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
            $result[0] | Should -HaveMember 'Name'
            $result[0] | Should -HaveMember 'Status'
            $result[0] | Should -HaveMember 'MacAddress'
        }
    }

    Context "Clear-DnsClientCache" {
        It "Should clear DNS client cache when running as admin" {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if ($isAdmin) {
                { Clear-DnsClientCache -ErrorAction Stop } | Should -Not -Throw
                $result = Clear-DnsClientCache -PassThru -ErrorAction Stop
                $result | Should -Be $true
            } else {
                Set-ItResult -Skipped -Because "Test requires administrator privileges"
            }
        }
    }
}

# Clean up the module after tests
AfterAll {
    Remove-Module $moduleName -ErrorAction SilentlyContinue
}

