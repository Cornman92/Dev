# ProfileMega

PowerShell **profile mega module**: one module that bundles agents, advanced features, utilities, quick actions, themes, and diagnostics for your shell.

## Structure

```
ProfileMega/
├── ProfileMega.psd1          # Manifest
├── ProfileMega.psm1          # Root loader
├── Core/
│   └── AgentFramework.psm1   # Agent, EventBus, AgentOrchestrator
├── Features/
│   ├── AdvancedFeatures.psm1 # PluginManager, WorkflowEngine, SystemMonitorAgent, etc.
│   └── AdvancedUtilities.psm1
├── Actions/
│   └── QuickActions.psm1     # Git, Docker, analysis, cleanup, Show-QuickHelp
├── Agents/
│   ├── Phase2-Agents.psm1    # Registers MonitoringAgent
│   └── MonitoringAgent.psm1
└── Scripts/
    ├── Config.ps1            # Default config
    ├── Prompt.ps1            # Enhanced prompt
    ├── NavigationAndGit.ps1  # .., ..., ~, git-*
    ├── Enhancements.ps1      # Theme, diagnostics, profile-help
    └── Welcome.ps1           # Startup banner
```

## Usage

### From your profile (recommended)

In `CTTcustom.ps1` or your main profile:

```powershell
Import-Module "C:\Users\You\OneDrive\Dev\ProfileMega\ProfileMega.psd1" -Force -Global
```

Or add `ProfileMega` to `$env:PSModulePath` and run:

```powershell
Import-Module ProfileMega -Force
```

### New commands

| Command | Alias | Description |
|--------|--------|-------------|
| `Get-ProfileInfo` | `profile-info` | Version, load time, config |
| `Invoke-ProfileDiagnostics` | `profile-diagnostics` | Full diagnostics |
| `Set-ProfileTheme` | — | Dark, Light, Minimal, Ocean |
| `Get-ProfileTheme` | — | Current theme |
| `Invoke-ProfileReload` | `profile-reload` | Reload profile |
| `Show-ProfileHelp` | `profile-help` | Quick reference |
| `Get-ProfileCommand` | — | List profile commands (use `-IncludeAliases` for aliases) |
| `Export-ProfileConfig` | — | Export current config to a .ps1 file |
| `Import-ProfileConfig` | — | Load config from a .ps1 file |
| `Update-ProfileMega` | — | Check for and apply updates (Git or URL manifest; off by default) |
| `Get-AgentStatus` | — | Agent status |
| `Show-AgentDashboard` | — | Agent dashboard |

### Aliases

- **Navigation:** `..`, `...`, `~`
- **Git:** `gs`, `ga`, `gc`, `gp`, `gl`
- **Quick actions:** `qh`, `clean`, `analyze`
- **Docker/K8s:** `d`, `dc`, `k` (if installed)
- **Base utilities (define-if-missing):** `admin` / `su` (elevate), `df` (Get-Volume), `hb` (paste file to Hastebin-style URL; set `ProfileConfig.HastebinUrl`, e.g. `http://bin.christitus.com`).

## Installation

From the ProfileMega folder:

```powershell
.\Install-ProfileMega.ps1
```

This adds ProfileMega to your user `PSModulePath` and appends `Import-Module ProfileMega -Force -Global` to your profile. Use `-SkipProfileUpdate` to only update PSModulePath. Restart PowerShell, then run `profile-help`.

## Requirements

- PowerShell 7.0+
- PSReadLine (optional; base profile often configures it)

## Config

**Defaults** are in `Scripts\Config.ps1`. Prefer **user overrides** so upgrades don't overwrite your settings:

- **ProfileMegaUser.ps1** or **ProfileMega.Config.ps1** in the same folder as `ProfileMega.psd1`, or
- **`$env:APPDATA\ProfileMega\Config.ps1`**

Example user config (e.g. `ProfileMegaUser.ps1`):

```powershell
$Global:ProfileConfig.QuietMode = $true
$Global:ProfileConfig.Theme = 'Ocean'
$Global:ProfileConfig.ProfileMode = 'Lite'
```

**Options:**

| Option | Description |
|--------|-------------|
| `ProfileMode` | `'Full'` or `'Lite'` — Lite disables agents and heavy features for faster load |
| `EnableAgents` | Load AgentFramework and Phase2 agents |
| `EnableAdvancedFeatures` | Load AdvancedFeatures (PluginManager, WorkflowEngine, etc.) |
| `EnableQuickActions` | Load QuickActions (qh, clean, analyze) |
| `QuietMode` | Skip welcome banner |
| `Theme` | Dark, Light, Minimal, Ocean |
| `PromptDriver` | `'ProfileMega'`, `'OhMyPosh'`, `'Starship'`, or `'None'` — who controls the prompt |
| `LoadTimeTipThresholdMs` | Show speed-up tip in welcome when load time exceeds this (default 800) |
| `LazyLoadQuickActions` | When QuickActions is disabled, stubs load the module on first use (e.g. qh). Set to `$false` for pure stubs. |
| `HastebinUrl` | Base URL for `hb` (e.g. `http://bin.christitus.com`). Empty = hb prints instructions. |
| `UpdateSource` | `'None'` (default), `'Git'`, or `'Url'` — enables Update-ProfileMega. Git runs `git pull` at module root; Url checks UpdateManifestUrl for a newer version. |
| `UpdateManifestUrl` | When UpdateSource is `'Url'`, raw URL to a version manifest (e.g. JSON with `version` or plain text). Update-ProfileMega only reports if a newer version exists. |

**PSReadLine:** When `EnablePSReadLineConfig` is true (default), ProfileMega configures PSReadLine from `Scripts/PSReadLine.ps1` (prediction, key handlers, colors, history filter). Set to `$false` to leave PSReadLine to the base profile or your own config.

**Self-update:** `Update-ProfileMega` is optional and disabled by default. Set `UpdateSource = 'Git'` to pull updates from the module’s git repo, or `UpdateSource = 'Url'` and `UpdateManifestUrl` to check a remote manifest; with Url, only a version check is performed (you are notified if a newer version is available).

## Standalone usage (no CTT base)

To use ProfileMega as your only profile (no Chris Titus Tech base):

1. Point your profile at **UltimateProfile.ps1** in the `PowerShell` folder next to ProfileMega:
   ```powershell
   # Optional: set default profile path to UltimateProfile
   # $PROFILE = "C:\Users\You\OneDrive\Dev\PowerShell\UltimateProfile.ps1"
   ```
   Or from your existing profile, dot-source only UltimateProfile instead of loading the full CTT profile:
   ```powershell
   . "C:\Users\You\OneDrive\Dev\PowerShell\UltimateProfile.ps1"
   ```

2. **UltimateProfile.ps1** loads PSReadLine (prediction, key handlers, history filter), then imports ProfileMega, then inits zoxide. Prompt and theme are controlled by ProfileMega’s `PromptDriver` and `Theme` in config.

3. All commands (Edit-Profile, reload-profile, base utilities, profile-help, etc.) come from ProfileMega’s BaseUtilities and Enhancements. No CTT Update-Profile or WinUtil unless you add them to a user config or script.
