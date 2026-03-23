#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.7.1' }

# Get the module path
$modulePath = Join-Path $PSScriptRoot "PackageManager.psd1"

# Import the module
Remove-Module -Name PackageManager -Force -ErrorAction SilentlyContinue
Import-Module $modulePath -Force -ErrorAction Stop

# Run the tests
$testResults = Invoke-Pester -Path "$PSScriptRoot\Tests" -OutputFile TestResults.xml -OutputFormat NUnitXml -PassThru

# Output test results
$testResults | Format-List

# Exit with non-zero code if any tests failed
if ($testResults.FailedCount -gt 0) {
    exit 1
}
