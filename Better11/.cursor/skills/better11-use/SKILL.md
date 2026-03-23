---
name: better11-use
description: Guides using Better11 to optimize and customize a Windows system (presets, modules, GUI/TUI). Use when the user is running Better11 to tweak their system, choose presets (Gaming, Developer, Privacy, Balanced, Minimal), enable modules, or understand what Better11 can do.
---

# Better11 — Use (Optimizing Windows)

Use this skill when **the user is running Better11** to optimize, customize, or personalize their Windows installation (live or offline).

## Two UIs

- **WinUI 3 GUI** — Full app; Dashboard, Optimization, Privacy, Security, Updates, Settings, etc.
- **PowerShell TUI** — Terminal UI for WinPE and full Windows (primary for advanced/deployment).

## Optimization Presets

| Preset | Focus |
|--------|--------|
| **Gaming** | Max FPS, disable visual effects, optimize GPU/CPU, debloat |
| **Developer** | Dev tools, package managers, Git, WSL, no bloatware |
| **Privacy** | Maximum privacy, disable telemetry/tracking/ads |
| **Balanced** | Sensible defaults — performance + privacy + usability |
| **Minimal** | Only essential tweaks, safe for any system |

## Key Modules (What Better11 Can Do)

Optimization, Privacy, Security, Package Manager, Driver Manager, Network, Disk Cleanup, Startup Manager, Scheduled Tasks, System Info, Updates, Appearance, RAM Disk, Certificate Manager, Reporting, Testing & Validation.

## MCP Tools (Use Phase)

When the Better11 MCP server is enabled:

- **better11_use_system_info** — Get current OS/CPU/RAM (PowerShell).
- **better11_use_list_presets** — List presets and descriptions.
- **better11_use_list_modules** — List modules/capabilities.

## Guidance

- Recommend a **preset** that matches the user's goal (gaming, dev, privacy, balanced, minimal).
- Point to **modules** (e.g. Startup Manager, Scheduled Tasks, Privacy) for specific tweaks.
- For **reporting** after changes, point to the Reporting page or post-phase tools.
