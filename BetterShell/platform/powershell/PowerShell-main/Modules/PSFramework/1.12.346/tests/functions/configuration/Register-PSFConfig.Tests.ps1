Describe "Register-PSFConfig Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Register-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module Register-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Register-PSFConfig).ParameterSets.Name | Should -Be 'Default', 'Name'
		$properties = 'Config', 'FullName', 'Module', 'Name', 'Scope', 'EnableException', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		Compare-Object $properties ((Get-Command Register-PSFConfig).Parameters.Keys | Remove-PSFNull -Enumerate) | Should -BeNullOrEmpty
	}
	
	Context "Validating registry persistence" {
		BeforeAll {
			$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
			$script:pathRegistryUserDefault = & $module { $path_RegistryUserDefault }
			$script:pathRegistryUserEnforced = & $module { $path_RegistryUserEnforced }
			$script:pathRegistryMachineDefault = & $module { $path_RegistryMachineDefault }
			$script:pathRegistryMachineEnforced = & $module { $path_RegistryMachineEnforced }
			
			Set-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Value 24
		}
		
		# Test Persistence for Registry > User > Default
		It "Should correctly persist to the user-default registry location" {
			{ Get-ItemPropertyValue -Path $script:pathRegistryUserDefault -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw
			Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope UserDefault
			Get-ItemPropertyValue -Path $script:pathRegistryUserDefault -Name 'Register-PSFConfig.Phase1.Setting1' | Should -Be 'int:24'
			Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope UserDefault
			{ Get-ItemPropertyValue -Path $script:pathRegistryUserDefault -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw

			{ Get-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' | Register-PSFConfig -Scope UserDefault -ErrorAction Stop } | Should -Not -Throw
			Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope UserDefault
		}
		
		# Test Persistence for Registry > User > Enforced
		It "Should correctly persist to the user-mandatory registry location" {
			{ Get-ItemPropertyValue -Path $script:pathRegistryUserEnforced -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw
			Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope UserMandatory
			Get-ItemPropertyValue -Path $script:pathRegistryUserEnforced -Name 'Register-PSFConfig.Phase1.Setting1' | Should -Be 'int:24'
			Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope UserMandatory
			{ Get-ItemPropertyValue -Path $script:pathRegistryUserEnforced -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw
		}
		
		# Only valid with elevation
		if (Test-PSFPowerShell -Elevated)
		{
			# Test Persistence for Registry > Machine > Default
			It "Should correctly persist to the system-default registry location" {
				{ Get-ItemPropertyValue -Path $script:pathRegistryMachineDefault -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop} | Should -Throw
				Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope SystemDefault
				Get-ItemPropertyValue -Path $script:pathRegistryMachineDefault -Name 'Register-PSFConfig.Phase1.Setting1' | Should -Be 'int:24'
				Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope SystemDefault
				{ Get-ItemPropertyValue -Path $script:pathRegistryMachineDefault -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw
			}
			# Test Persistence for Registry > Machine > Enforced
			It "Should correctly persist to the system-mandatory registry location" {
				{ Get-ItemPropertyValue -Path $script:pathRegistryMachineEnforced -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw
				Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope SystemMandatory
				Get-ItemPropertyValue -Path $script:pathRegistryMachineEnforced -Name 'Register-PSFConfig.Phase1.Setting1' | Should -Be 'int:24'
				Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting1' -Scope SystemMandatory
				{ Get-ItemPropertyValue -Path $script:pathRegistryMachineEnforced -Name 'Register-PSFConfig.Phase1.Setting1' -ErrorAction Stop } | Should -Throw
			}
		}
	}
	Context "Validating file persistence" {
		BeforeAll {
			$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
			$pathFileUserLocal = & $module { $path_FileUserLocal }
			$pathFileUserShared = & $module { $path_FileUserShared }
			$pathFileSystem = & $module { $path_FileSystem }
			
			Set-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Value 32
		}
		# Test Persistence for File > User > Local
		It "Should correctly persist to the user-local specific file" {
			$tempPathRoot = $pathFileUserLocal
			$tempPath = Join-Path $tempPathRoot "psf_config.json"
			if (Test-Path $tempPath)
			{
				Rename-Item -Path $tempPath -NewName 'psf_config.json.old'
			}
			Test-Path $tempPath | Should -Be $false
			Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Scope FileUserLocal
			Get-Content $tempPath | Select-String 'Register-PSFConfig.Phase1.Setting2' | Should -Not -BeNullOrEmpty
			Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Scope FileUserLocal
			Test-Path $tempPath | Should -Be $false
			if (Test-Path (Join-Path $tempPathRoot "psf_config.json.old"))
			{
				Rename-Item -Path (Join-Path $tempPathRoot "psf_config.json.old") -NewName 'psf_config.json' -Force
			}
		}
		
		# Test Persistence for File > User > Shared
		It "Should correctly persist to the user-shared specific file" {
			$tempPathRoot = $pathFileUserShared
			$tempPath = Join-Path $tempPathRoot "psf_config.json"
			if (Test-Path $tempPath)
			{
				Rename-Item -Path $tempPath -NewName 'psf_config.json.old'
			}
			Test-Path $tempPath | Should -Be $false
			Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Scope FileUserShared
			Get-Content $tempPath | Select-String 'Register-PSFConfig.Phase1.Setting2' | Should -Not -BeNullOrEmpty
			Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Scope FileUserShared
			Test-Path $tempPath | Should -Be $false
			if (Test-Path (Join-Path $tempPathRoot "psf_config.json.old"))
			{
				Rename-Item -Path (Join-Path $tempPathRoot "psf_config.json.old") -NewName 'psf_config.json' -Force
			}
		}
		
		if (Test-PSFPowerShell -Elevated)
		{
			# Test Persistence for File > Machine
			It "Should correctly persist to the system-wide file" {
				$tempPathRoot = $pathFileSystem
				$tempPath = Join-Path $tempPathRoot "psf_config.json"
				if (Test-Path $tempPath)
				{
					Rename-Item -Path $tempPath -NewName 'psf_config.json.old'
				}
				Test-Path $tempPath | Should -Be $false
				Register-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Scope FileSystem
				Get-Content $tempPath | Select-String 'Register-PSFConfig.Phase1.Setting2' | Should -Not -BeNullOrEmpty
				Unregister-PSFConfig -FullName 'Register-PSFConfig.Phase1.Setting2' -Scope FileSystem
				Test-Path $tempPath | Should -Be $false
				if (Test-Path (Join-Path $tempPathRoot "psf_config.json.old"))
				{
					Rename-Item -Path (Join-Path $tempPathRoot "psf_config.json.old") -NewName 'psf_config.json' -Force
				}
			}
		}
	}
	
	Context "Ensuring Content based Data Integrity" {
		BeforeAll {
			$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
			$script:pathRegistryUserDefault = & $module { $path_RegistryUserDefault }
			$script:pathFileUserLocal = & $module { $path_FileUserLocal }
			
			# Set test values
			Set-PSFConfig -FullName 'Register-PSFConfig.Phase2.Setting1' -Value 42
			Set-PSFConfig -FullName 'Register-PSFConfig.Phase2.Setting2' -Value 'TestValue'
		}
		
		It "should export single and multiple items to registry without issues" {
			{ Register-PSFConfig -FullName 'Register-PSFConfig.Phase2.Setting1' } | Should -Not -Throw
			{ Register-PSFConfig -FullName 'Register-PSFConfig.Phase2.Setting2' } | Should -Not -Throw
			$hive = Get-ItemProperty -Path $script:pathRegistryUserDefault
			$hive.'Register-PSFConfig.Phase2.Setting1' | Should -Be 'Int:42'
			$hive.'Register-PSFConfig.Phase2.Setting2' | Should -Be 'String:TestValue'
			Unregister-PSFConfig -Module Register-PSFConfig
			$hive = Get-ItemProperty -Path $script:pathRegistryUserDefault
			$hive.'Register-PSFConfig.Phase2.Setting1' | Should -BeNullOrEmpty
			$hive.'Register-PSFConfig.Phase2.Setting2' | Should -BeNullOrEmpty
		}
		It "should export single and multiple items to file without issues" {
			{ Register-PSFConfig -FullName 'Register-PSFConfig.Phase2.Setting1' -Scope FileUserLocal } | Should -Not -Throw
			{ Register-PSFConfig -FullName 'Register-PSFConfig.Phase2.Setting2' -Scope FileUserLocal } | Should -Not -Throw
			$localFile = Join-Path $script:pathFileUserLocal 'psf_config.json'
			Get-Content -Path $localFile | Select-String 'Register-PSFConfig.Phase2.Setting1' | Should -Not -BeNullOrEmpty
			Get-Content -Path $localFile | Select-String 'Register-PSFConfig.Phase2.Setting2' | Should -Not -BeNullOrEmpty
			Unregister-PSFConfig -Module Register-PSFConfig -Scope FileUserLocal
			if (Test-Path $localFile)
			{
				Get-Content -Path $localFile | Select-String 'Register-PSFConfig.Phase2.Setting1' | Should -BeNullOrEmpty
				Get-Content -Path $localFile | Select-String 'Register-PSFConfig.Phase2.Setting2' | Should -BeNullOrEmpty
			}
		}
	}
}