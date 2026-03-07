# Sideload Installation (Better11 MSIX)

This document describes how to install the Better11 MSIX package without using the Microsoft Store (sideloading).

## Prerequisites

- Windows 10 version 1809+ or Windows 11 (x64).
- The Better11 `.msix` package (e.g. from a GitHub Release or build output).

## Enable sideloading

1. Open **Settings** → **Update & Security** → **For developers** (or **Privacy & security** → **For developers** on Windows 11).
2. Under **Developer Mode**, choose one of:
   - **Sideload apps** — Install apps that are not from the Store, with a trusted certificate.
   - **Developer mode** — Enables sideloading and other developer features (less restrictive).

## Trust the certificate (if the app is signed with a custom certificate)

If the MSIX is signed with a certificate that is not already trusted by your organization:

1. Obtain the signing certificate (e.g. `.cer` or `.pfx` from the publisher).
2. Double-click the certificate and complete the installation wizard.
3. Place it in **Trusted Root Certification Authorities** or **Trusted Publishers** as instructed by your IT or the publisher.

Enterprise deployment often uses Group Policy or MDM to deploy both the certificate and the MSIX.

## Install the MSIX

**Option A — Double-click**

- Double-click the `.msix` file and follow the prompts.

**Option B — PowerShell**

```powershell
Add-AppxPackage -Path ".\Better11_1.0.0.0_x64_Release.msix"
```

Replace the filename with your actual MSIX path.

## Launch the app

After installation, launch **Better11** from the Start menu or by searching for "Better11".

## Uninstall

- **Settings** → **Apps** → **Apps & features** → find **Better11** → **Uninstall**
- Or in PowerShell: `Get-AppxPackage *Better11* | Remove-AppxPackage`

## Troubleshooting

- **"App installation failed"** — Ensure sideloading or developer mode is enabled and the certificate is trusted.
- **Dependencies** — The package is self-contained; no separate .NET or SDK install is required for the app to run.
- **Updates** — Install a newer MSIX over the existing one, or uninstall and then install the new version.

For the full release process (including signing), see [RELEASE.md](../RELEASE.md).
