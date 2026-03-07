# Better11 User Guide

This guide covers how to use the Better11 System Enhancement Suite (WinUI 3 app and main features).

## Getting Started

### Installation

- **From MSIX:** Install the `.msix` package. See [SIDELOAD.md](SIDELOAD.md) if you are not installing from the Microsoft Store.
- **First launch:** The app opens to the Dashboard. You can run the **First Run Wizard** from the footer (or when prompted) to apply presets and recommended optimizations.

### First steps

1. **Dashboard** — Overview of system health, performance metrics, and quick actions (optimization, disk cleanup, privacy scan).
2. **First Run Wizard** — Guided setup: choose a preset (e.g. Gaming, Developer, Minimal), select modules to run, then apply. You can run it again later from the navigation footer.
3. **Settings** — Set theme (Dark/Light), language, and export/import settings. Use “Reset first run” to see the wizard again on next launch.

## Navigation Sections

### Management

- **Packages** — View and manage installed packages (e.g. winget); search, install, uninstall, update.
- **Drivers** — List installed drivers, scan for updates, backup and rollback drivers.
- **Startup** — Enable/disable/remove startup items (registry and folder).
- **Tasks** — View and manage scheduled tasks; enable, disable, run now.
- **Network** — View adapters, set DNS (primary/secondary), apply DNS presets, flush DNS cache, run diagnostics.

### Optimization

- **System Optimization** — Browse optimization categories (CPU, memory, disk, etc.), select tweaks, create a restore point, then apply. Changes can be reverted via restore point or undo journal.
- **Disk Cleanup** — Scan for reclaimable space (temp files, Windows Update cache, etc.), select categories, then clean.
- **Backup & Restore** — Create/system restore points, export/import registry keys, file backups, and backup schedules.
- **User Accounts** — Manage local user accounts and groups, password policy, auto-login, audit and sessions.

### Security & Privacy

- **Privacy** — Run a privacy audit, view privacy score, apply privacy profiles, toggle individual settings.
- **Security** — View security status, run security scan, apply hardening recommendations.
- **Updates** — Check for Windows updates, install updates, view update history.

### Information

- **System Info** — View OS, CPU, RAM, GPU, and performance metrics; export system information.
- **About** — App version, build info, components, links to documentation and GitHub; copy system info for support.

## Reporting

- **Reporting page** — Export system state and optimization results as **HTML**, **JSON**, **Markdown**, **CSV**, or **TXT**. Use the format selector and **Export** to save a report. Reports are saved to the location you choose (e.g. Desktop or Documents). Keep reports for records before and after major changes.
- **Where reports are saved** — The app prompts for a save path when you export; there is no default folder. Use **About** → **Open log folder** to reach `%LocalAppData%\Better11`; you can create a subfolder there for reports if you prefer.

## Certificate Manager

- **Certificate Manager** (if available in your build) — Browse certificate stores (Current User and Local Machine), import/export certificates, and create self-signed certificates. Use for code signing, TLS, or custom trust. Require administrator rights for machine stores.

## Appearance Customizer

- **Appearance Customizer** (if available) — Adjust wallpaper, accent colors, taskbar behavior, Start menu layout, and visual effects (animations, transparency). Changes apply to the current user. Create a restore point before making bulk appearance changes.

## RAM Disk

- **RAM Disk** (if available) — Create a memory-backed drive for temporary high-speed storage. Set size and optional folder redirects. Data is lost on reboot. Useful for build caches or temp files. Do not store permanent data on a RAM disk.

## First Run Wizard (presets and modules)

- **Presets** — Choose **Gaming**, **Developer**, **Minimal**, or **Custom** to apply a recommended set of optimizations and privacy settings.
- **Module selection** — In the wizard, you can select which modules (e.g. Optimization, Privacy, Cleanup) to run. Review each category and enable or disable as needed.
- **Apply** — The wizard applies your choices; you can run it again from the navigation footer (**First Run Wizard**) to change presets or re-apply.

## Settings

- **Theme** — Dark (default) or Light, or **System** to follow Windows.
- **Auto-update** — When enabled, the app can check for updates (see **About** → Check for updates).
- **Telemetry** — Opt in to send anonymous usage data; see the **Privacy policy** link next to the toggle. When disabled, no telemetry is sent.
- **Language** — App language when localization is available.
- **Export / Import settings** — Backup or restore your settings to a file.
- **Reset first run** — Mark the First Run Wizard as not completed so it can run again.

## Backup and Restore Points

Before applying system optimizations or major changes:

1. Open **Backup & Restore**.
2. Create a **restore point** with a description (e.g. “Before optimization”).
3. If something goes wrong, use Windows **System Restore** (or the restore point list in the app) to revert.

## Driver Updates and Rollback

- **Scan for updates** to see outdated drivers.
- **Backup** a driver before updating so you can **rollback** if needed.
- Use manufacturer or Windows Update sources; third-party driver tools may add risk.

## Privacy and Security Scans

- **Privacy:** The audit shows telemetry and privacy-related settings; profiles apply a set of recommended changes. Review each change before applying.
- **Security:** The scan checks common hardening items; “Apply hardening” applies the recommended set. Ensure you understand each change (e.g. firewall, UAC).

## Where to get help

- **Documentation** — [docs.better11.app](https://docs.better11.app) and this user guide ([USER-GUIDE.md](USER-GUIDE.md)). For install and sideload, see [INSTALL.md](INSTALL.md) and [SIDELOAD.md](SIDELOAD.md).
- **Log folder** — Use **About** → **Open log folder** (or go to `%LocalAppData%\Better11\Logs`) to attach logs when reporting issues.
- **GitHub** — For bugs and feature requests, open an issue and include OS version, app version (from **About**), and steps to reproduce. See [CONTRIBUTING.md](../CONTRIBUTING.md) for how to report bugs.

## Troubleshooting

- **App won’t start** — Ensure Windows 10/11 x64 and that the MSIX or dependencies are correctly installed. Reinstall the MSIX if needed.
- **A feature fails or shows an error** — Check that you run as administrator if the feature requires elevation. Copy the error message (e.g. from the page or Console Output) for support.
- **Logs** — Use **About** → **Open log folder** to open the log directory; attach relevant log files when reporting issues.
- **Reporting issues** — Include OS version, app version (from About), and steps to reproduce. See CONTRIBUTING.md for how to report bugs.

## System Requirements

- Windows 10 version 1809+ or Windows 11 (x64).
- See [README](../README.md#system-requirements) for full requirements.
