# Better11 — Installation Guide

This guide explains how to download, install, and uninstall the Better11 System Enhancement Suite.

## Prerequisites

- **Windows 10** version 1809 or later, or **Windows 11** (x64 only).
- Administrator rights may be required for some features (e.g. system optimization, drivers); the app can be installed and run without admin for most tasks.

## Downloading the MSIX

1. Obtain the Better11 `.msix` package from one of:
   - **GitHub Releases** (if published): [Releases](https://github.com/Better11/Better11/releases)
   - **Build from source**: From the repo, run `.\scripts\Build-Better11.ps1 -Configuration Release -Package` from `Better11\Better11`; the MSIX is produced in `artifacts\`.
2. Ensure the file is not blocked (right-click → Properties → Unblock if present).

## Enabling Sideloading (required for non-Store installs)

To install an MSIX that is not from the Microsoft Store:

1. Open **Settings** → **Update & Security** → **For developers** (Windows 10) or **Privacy & security** → **For developers** (Windows 11).
2. Select **Sideload apps** (recommended) or **Developer mode** for full developer features.

## Trusting the Certificate (if the app is signed with a custom certificate)

If the MSIX is signed with a publisher certificate that Windows does not already trust:

1. Obtain the signing certificate (e.g. `.cer` or `.pfx`) from the publisher or your IT department.
2. Double-click the certificate file and complete the installation wizard.
3. Install to **Trusted Root Certification Authorities** or **Trusted Publishers** as directed.

If you built the MSIX yourself and did not sign it, you may need to use a self-signed certificate and trust it, or install in developer mode. See [SIDELOAD.md](SIDELOAD.md) for details.

## Installing the MSIX

**Option A — Double-click**

- Double-click the `.msix` file and follow the installation prompts.

**Option B — PowerShell**

```powershell
Add-AppxPackage -Path ".\Better11_1.0.0.0_x64_Release.msix"
```

Replace the path with the actual location and filename of your MSIX.

## Launching Better11

After installation, launch **Better11** from the Start menu or by searching for "Better11".

## Uninstall

- **Settings** → **Apps** → **Apps & features** → find **Better11** → **Uninstall**.
- Or in PowerShell (run as appropriate user):

  ```powershell
  Get-AppxPackage *Better11* | Remove-AppxPackage
  ```

## Logs and Support

- **Logs** are stored under `%LocalAppData%\Better11\Logs`. You can open this folder from the app via **About** → **Open log folder** (if available) or from Run: `%LocalAppData%\Better11\Logs`.
- When reporting issues, include your Windows version, app version (see **About** in the app), and attach relevant log files. See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to report bugs.

## See Also

- [SIDELOAD.md](SIDELOAD.md) — Sideload installation details.
- [RELEASE.md](../RELEASE.md) — Release and signing process.
- [USER-GUIDE.md](USER-GUIDE.md) — How to use Better11 after installation.
