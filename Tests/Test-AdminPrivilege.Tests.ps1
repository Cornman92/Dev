<#
.SYNOPSIS
    Pester tests for the Test-AdminPrivilege function.

.NOTES
    Run with: Invoke-Pester -Path .\Tests\Test-AdminPrivilege.Tests.ps1
#>

BeforeAll {
    . "$PSScriptRoot\..\Functions\Test-AdminPrivilege.ps1"
}

Describe 'Test-AdminPrivilege' {

    Context 'Return Value' {
        It 'Should return a boolean' {
            $result = Test-AdminPrivilege
            $result | Should -BeOfType [bool]
        }
    }

    Context 'Require Switch' {
        It 'Should throw when not admin and -Require is specified' {
            # This test is environment-dependent
            # In non-admin context, it should throw
            $isAdmin = Test-AdminPrivilege
            if (-not $isAdmin) {
                { Test-AdminPrivilege -Require } | Should -Throw
            }
            else {
                { Test-AdminPrivilege -Require } | Should -Not -Throw
            }
        }
    }

    Context 'Warn Switch' {
        It 'Should not throw when -Warn is specified' {
            { Test-AdminPrivilege -Warn } | Should -Not -Throw
        }
    }
}
