# Better11 — Release Process

This document describes how to cut a release: tag, build, sign, and distribute.

## Versioning

Better11 uses [Semantic Versioning](docs/VERSIONING.md) (SemVer). Set version in the app project and update `CHANGELOG.md` before releasing.

## Release steps

1. **Bump version**
   - Update `Version` / `AssemblyVersion` in `Better11.App.csproj` (or `Directory.Build.props`).
   - Add a new section in `CHANGELOG.md`: `## [X.Y.Z] - YYYY-MM-DD` and list changes.

2. **Commit and tag**
   - Commit: `chore: release vX.Y.Z`
   - Create tag: `git tag vX.Y.Z`
   - Push branch and tags: `git push && git push --tags`

3. **Build and test**
   - From `Better11\Better11`:  
     `.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package`
   - Ensure all tests pass and the MSIX is produced in `artifacts/`.

4. **Sign the MSIX (optional but recommended)**
   - Use a code-signing certificate (store or PFX).
   - Example with `SignTool` (adjust paths and cert):
     ```powershell
     signtool sign /fd SHA256 /f "path\to\cert.pfx" /p "password" /tr http://timestamp.digicert.com /td SHA256 .\artifacts\*.msix
     ```
   - Or use Azure Sign Tool / GitHub Actions for signing in CI.

5. **Distribute**
   - Upload the signed MSIX to your distribution channel (e.g. GitHub Releases, website, store).
   - Publish release notes from `CHANGELOG.md` for that version.

## Installation guide

For end-user installation steps (download, enable sideloading, trust certificate, install MSIX, uninstall), see [docs/INSTALL.md](docs/INSTALL.md).

## Sideload installation

Users can install the MSIX without the Microsoft Store by **sideloading**:

1. **Enable sideloading** (if not already):
   - Settings → Update & Security → For developers → select **Sideload apps** (or **Developer mode** for unrestricted installs).

2. **Trust the certificate** (if the app is signed with a custom cert):
   - Install the signing certificate to the machine’s Trusted Root and/or Trusted Publishers (e.g. via Group Policy or double-click the cert and install).

3. **Install the MSIX**:
   - Double-click the `.msix` file, or run:
     ```powershell
     Add-AppxPackage -Path ".\Better11_1.0.0.0_x64_Release.msix"
     ```

4. **Launch**: Start **Better11** from the Start menu.

For enterprise deployment, use Group Policy or MDM to deploy the MSIX and certificate. Document any policy requirements (e.g. allowed install scope) for your organization.

## CI/CD

For automated releases, use a pipeline (e.g. GitHub Actions or Azure DevOps) to:

- On tag `v*`: restore, build, test, package, sign (if secrets are configured), and upload artifacts or create a GitHub Release.

See `.github/workflows/` (if added) for the exact steps.
