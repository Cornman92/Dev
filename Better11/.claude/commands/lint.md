Run all code quality checks on the Better11 workspace:

1. **C# Build with warnings-as-errors**: `dotnet build Better11.sln -c Release -warnaserror`
2. **StyleCop**: Already integrated via Directory.Build.props — check build output for SA* warnings
3. **PSScriptAnalyzer**: `pwsh -c "Invoke-ScriptAnalyzer -Path ./PowerShell -Recurse -Settings ./config/PSScriptAnalyzerSettings.psd1 -ReportSummary"`
4. **EditorConfig compliance**: Check that all files follow .editorconfig rules (UTF-8, LF line endings, trim trailing whitespace)

Report a summary: total issues found per tool, categorized by severity.
The target is always **0 errors AND 0 warnings** across all tools.
If any issues are found, provide the fix for each one.
