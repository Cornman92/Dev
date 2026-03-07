# Better11 — Application Update Mechanism

This document describes how application (Better11) updates work: version manifest, update check, download, and install.

## Overview

Better11 can check for a newer application version by fetching a **version manifest** (JSON) from a configurable URL. The manifest lists the latest version, download URL for the MSIX (or installer), and optional release notes. The in-app **About** page provides a "Check for updates" action that uses this flow.

## Version Manifest

- **URL:** Configured in the app as `AppConstants.UpdateManifestUrl` (default: `https://docs.better11.app/version-manifest.json`). This can be overridden via configuration or build if you host the manifest elsewhere.
- **Format:** JSON with the following fields:
  - **version** (required): Semantic version string (e.g. `1.1.0`). The app compares this with the current version (`AppConstants.AppVersion`).
  - **downloadUrl** (optional): Full URL to the update package (e.g. MSIX). If present, the user can download or the app can offer to open it.
  - **releaseNotes** (optional): Description or release notes for the update.
  - **publishDate** (optional): ISO 8601 date-time when the release was published.

See [version-manifest.schema.json](version-manifest.schema.json) for a JSON Schema and [version-manifest.example.json](version-manifest.example.json) for an example.

## Update Check Flow

1. User clicks **Check for updates** on the About page.
2. The app requests the manifest URL via HTTP GET.
3. The response is parsed and the **version** field is compared with the current app version (SemVer comparison).
4. If the manifest version is **newer**, the app shows a message that an update is available and may offer to open the download URL or trigger download/install.
5. If the manifest is missing, invalid, or the version is not newer, the app reports that the user is on the latest version (or reports an error if the request failed).

## Download and Install

- **Download:** The `IAppUpdateService.DownloadUpdateAsync` method downloads the file from `downloadUrl` to a temporary directory and returns the local path. The app can use this to offer an "Install" action.
- **Install:** The `InstallUpdateAsync` method launches the downloaded file (e.g. MSIX) with the shell. The user then follows the system installer. The app does not automatically close; the user can restart after installing.

## Publishing a New Version

1. **Build and sign** the new MSIX (see [RELEASE.md](../RELEASE.md) and [BUILD.md](../BUILD.md)).
2. **Upload** the MSIX to your distribution channel (e.g. GitHub Releases, website).
3. **Update the version manifest** at the URL used by `UpdateManifestUrl`:
   - Set `version` to the new semantic version (e.g. `1.1.0`).
   - Set `downloadUrl` to the direct download link for the MSIX.
   - Optionally set `releaseNotes` and `publishDate`.
4. Existing installations that run "Check for updates" will see the new version and can download/install.

## Security and Privacy

- Update check and download use standard HTTPS. No telemetry is sent as part of the update check beyond the HTTP request to your manifest URL.
- The manifest URL is fixed in the app (or config); ensure you control that endpoint and that it is served over HTTPS to avoid tampering.

## See Also

- [RELEASE.md](../RELEASE.md) — Release and signing process.
- [INSTALL.md](INSTALL.md) — End-user installation guide.
- [BUILD.md](../BUILD.md) — Build and package commands.
