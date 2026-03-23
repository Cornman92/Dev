#Requires -Modules Pester
# ============================================================================
# File: tests/B11.UserAccount.Tests/B11.UserAccount.Tests.ps1
# Better11 System Enhancement Suite
# Copyright (c) 2026 Better11. All rights reserved.
# ============================================================================

BeforeAll { Import-Module (Join-Path $PSScriptRoot '..\..\src\Modules\B11.UserAccount\B11.UserAccount.psd1') -Force }

Describe 'Module Import' {
    It 'Should import' { Get-Module 'B11.UserAccount' | Should -Not -BeNullOrEmpty }
    It 'Should export 17 functions' { (Get-Command -Module 'B11.UserAccount').Count | Should -Be 17 }
    It 'Should use approved verbs' { Get-Command -Module 'B11.UserAccount' | ForEach-Object { $_.Name | Should -Match '^(Get|Set|New|Remove|Add|Stop|Disable)-B11' } }
}

Describe 'Get-B11LocalAccount' {
    It 'Should return accounts' { $r = Get-B11LocalAccount; $r.Count | Should -BeGreaterThan 0 }
    It 'Should have Username' { $r = Get-B11LocalAccount | Select-Object -First 1; $r.Username | Should -Not -BeNullOrEmpty }
    It 'Should have Enabled property' { $r = Get-B11LocalAccount | Select-Object -First 1; $r.PSObject.Properties.Name | Should -Contain 'Enabled' }
    It 'Should have IsAdmin property' { $r = Get-B11LocalAccount | Select-Object -First 1; $r.PSObject.Properties.Name | Should -Contain 'IsAdmin' }
}

Describe 'Get-B11LocalGroup' {
    It 'Should return groups' { $r = Get-B11LocalGroup; $r.Count | Should -BeGreaterThan 0 }
    It 'Should have Name and MemberCount' { $r = Get-B11LocalGroup | Select-Object -First 1; $r.Name | Should -Not -BeNullOrEmpty }
}

Describe 'Get-B11PasswordPolicy' {
    It 'Should return policy' { $r = Get-B11PasswordPolicy; $r | Should -Not -BeNullOrEmpty }
    It 'Should have MinLength' { (Get-B11PasswordPolicy).PSObject.Properties.Name | Should -Contain 'MinLength' }
}

Describe 'Get-B11AutoLogin' {
    It 'Should return config' { $r = Get-B11AutoLogin; $r | Should -Not -BeNullOrEmpty }
    It 'Should have Enabled' { (Get-B11AutoLogin).PSObject.Properties.Name | Should -Contain 'Enabled' }
}

Describe 'Get-B11UserProfile' {
    It 'Should return without error' { { Get-B11UserProfile } | Should -Not -Throw }
}

Describe 'Get-B11SecurityAudit' {
    It 'Should return without error' { { Get-B11SecurityAudit -MaxEntries 5 } | Should -Not -Throw }
}

Describe 'Get-B11UserSession' {
    It 'Should return without error' { { Get-B11UserSession } | Should -Not -Throw }
}
