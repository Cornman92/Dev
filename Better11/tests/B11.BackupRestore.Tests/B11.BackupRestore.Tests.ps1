#Requires -Modules Pester
BeforeAll{Import-Module (Join-Path $PSScriptRoot '..\..\src\Modules\B11.BackupRestore\B11.BackupRestore.psd1') -Force}
Describe 'Module'{It 'Imports'{Get-Module 'B11.BackupRestore'|Should -Not -BeNullOrEmpty};It 'Exports 12'{(Get-Command -Module 'B11.BackupRestore').Count|Should -Be 12}}
Describe 'Get-B11RestorePoint'{It 'Returns'{{Get-B11RestorePoint}|Should -Not -Throw}}
Describe 'Get-B11RegistryBackup'{It 'Returns'{{Get-B11RegistryBackup}|Should -Not -Throw}}
Describe 'Get-B11FileBackup'{It 'Returns'{{Get-B11FileBackup}|Should -Not -Throw}}
Describe 'Get-B11BackupSchedule'{It 'Returns'{{Get-B11BackupSchedule}|Should -Not -Throw}}
