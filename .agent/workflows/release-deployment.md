---
description: Release and deploy projects with proper versioning, changelog, and publishing
---

# Release & Deployment Workflow

Complete workflow for versioning, creating releases, and deploying projects.

## Prerequisites
- Git installed and configured
- GitHub CLI (`gh`) installed (optional but recommended)
- PowerShell Gallery API key (for module publishing)

## Steps

### 1. Prepare Release
// turbo
```powershell
# Check current status
git status
git log --oneline -10
```

### 2. Update Version
**For PowerShell modules** (update .psd1):
```powershell
$manifestPath = ".\modules\[ModuleName]\[ModuleName].psd1"
$manifest = Import-PowerShellDataFile $manifestPath
$currentVersion = [version]$manifest.ModuleVersion

# Bump version (patch, minor, or major)
$newVersion = [version]::new($currentVersion.Major, $currentVersion.Minor, $currentVersion.Build + 1)
Update-ModuleManifest -Path $manifestPath -ModuleVersion $newVersion
```

**For .NET projects** (update .csproj):
```xml
<PropertyGroup>
    <Version>1.0.0</Version>
    <AssemblyVersion>1.0.0.0</AssemblyVersion>
    <FileVersion>1.0.0.0</FileVersion>
</PropertyGroup>
```

### 3. Generate Changelog
```powershell
# Get commits since last tag
$lastTag = git describe --tags --abbrev=0 2>$null
if ($lastTag) {
    $commits = git log "$lastTag..HEAD" --pretty=format:"- %s (%h)" --no-merges
} else {
    $commits = git log --pretty=format:"- %s (%h)" --no-merges -20
}

# Categorize commits (if using conventional commits)
$features = $commits | Where-Object { $_ -match '^- feat' }
$fixes = $commits | Where-Object { $_ -match '^- fix' }
$docs = $commits | Where-Object { $_ -match '^- docs' }

# Create changelog entry
$changelogEntry = @"
## [$newVersion] - $(Get-Date -Format 'yyyy-MM-dd')

### Added
$($features -join "`n")

### Fixed
$($fixes -join "`n")

### Documentation
$($docs -join "`n")
"@

Write-Host $changelogEntry
```

### 4. Commit Version Bump
```powershell
git add .
git commit -m "chore: bump version to $newVersion"
```

### 5. Create Git Tag
```powershell
$tagName = "v$newVersion"
git tag -a $tagName -m "Release $tagName"
```

### 6. Push to Remote
```powershell
git push origin main
git push origin $tagName
```

### 7. Create GitHub Release
**Using GitHub CLI:**
```powershell
gh release create $tagName --title "Release $tagName" --notes "$changelogEntry"
```

**Or create release notes file:**
```powershell
$releaseNotes = @"
# Release $tagName

## What's New
$changelogEntry

## Installation

### PowerShell Module
``powershell
Install-Module [ModuleName] -Force
``

### .NET Application
Download the release artifacts below.

## Contributors
Thanks to all contributors!
"@

$releaseNotes | Set-Content ".\RELEASE_NOTES.md"
```

### 8. Publish PowerShell Module
```powershell
# Test publish (dry run)
Publish-Module -Path ".\modules\[ModuleName]" -NuGetApiKey $env:NUGET_API_KEY -WhatIf

# Actual publish
Publish-Module -Path ".\modules\[ModuleName]" -NuGetApiKey $env:NUGET_API_KEY
```

### 9. Publish .NET Application
```powershell
# Build release
dotnet publish -c Release -r win-x64 --self-contained true -o .\publish

# Create zip for release
Compress-Archive -Path .\publish\* -DestinationPath ".\[ProjectName]-$tagName-win-x64.zip"

# Upload to GitHub release
gh release upload $tagName ".\[ProjectName]-$tagName-win-x64.zip"
```

## Automated Release (CI/CD)

The workspace already has `.github/workflows/ci-cd.yml` configured with:
- Automatic testing on push
- PSScriptAnalyzer linting
- PowerShell Gallery publishing on main branch
- GitHub release creation

**Trigger a release:**
1. Merge PR to main branch
2. CI/CD automatically:
   - Runs tests
   - Publishes to PowerShell Gallery
   - Creates GitHub release

## Version Numbering (SemVer)

| Change Type | Version Part | Example |
|------------|--------------|---------|
| Breaking changes | Major | 1.0.0 → 2.0.0 |
| New features | Minor | 1.0.0 → 1.1.0 |
| Bug fixes | Patch | 1.0.0 → 1.0.1 |

## Commit Message Format

Use conventional commits for automatic changelog generation:
```
feat: add new feature
fix: resolve bug in component
docs: update README
chore: update dependencies
refactor: reorganize code structure
test: add unit tests
```

## Quick Reference

```powershell
# Full release workflow
$version = "1.2.0"
git add . && git commit -m "chore: release v$version"
git tag -a "v$version" -m "Release v$version"
git push origin main --tags
gh release create "v$version" --generate-notes
```

## Rollback Procedure

If a release has issues:
```powershell
# Delete remote tag
git push --delete origin $tagName

# Delete local tag
git tag -d $tagName

# Revert commit
git revert HEAD

# Force update PowerShell Gallery (publish new patch version)
```
