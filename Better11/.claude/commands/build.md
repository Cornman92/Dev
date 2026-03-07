Build and test the Better11 project. Run the following steps in order:

1. `dotnet restore Better11.sln`
2. `dotnet build Better11.sln -c Debug --verbosity minimal`
3. `dotnet test Better11.sln --verbosity normal`
4. `pwsh -c "Invoke-ScriptAnalyzer -Path ./PowerShell -Recurse -Settings ./config/PSScriptAnalyzerSettings.psd1"` (if PSScriptAnalyzer is installed)
5. `pwsh -c "Invoke-Pester -Path ./PowerShell/Modules -Output Detailed"` (if Pester is installed)

Report results as: build status, test count/pass/fail, analyzer warnings.
All must be 0 errors and 0 warnings to pass.
