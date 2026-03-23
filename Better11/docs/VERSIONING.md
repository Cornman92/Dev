# Better11 Versioning

Better11 uses **Semantic Versioning (SemVer)** 2.0: `MAJOR.MINOR.PATCH`.

- **MAJOR**: Incompatible API or behavior changes (e.g. dropping a platform or breaking settings format).
- **MINOR**: New features, backward-compatible (e.g. new pages, new optimization categories).
- **PATCH**: Bug fixes and backward-compatible improvements (e.g. fixes, performance, docs).

## Where version is set

- **C# / MSIX**: `Version` and `AssemblyVersion` in `Better11.App.csproj` (or `Directory.Build.props`). MSIX package version is derived from the app project.
- **PowerShell modules**: Module manifest (`.psd1`) `ModuleVersion` can be aligned with app version for releases; during development it may differ.

## Pre-release labels

Optional pre-release identifiers use the format `MAJOR.MINOR.PATCH-label.N` (e.g. `1.0.0-beta.1`, `1.0.0-rc.2`). These are not used in the store; use for internal or beta builds.

## Release notes

- Update `CHANGELOG.md` for each release with date and version heading.
- Tag releases in git as `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`).
- Release notes can be generated from CHANGELOG sections or git tag messages.

## Bumping version

1. Update version in the app project (and any shared props).
2. Update `CHANGELOG.md` under a new `## [X.Y.Z] - YYYY-MM-DD` section.
3. Commit with message like `chore: release vX.Y.Z`.
4. Create git tag `vX.Y.Z` and push.
