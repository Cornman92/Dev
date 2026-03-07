# Windows Automation Station (WAS) Overview

- Root layout: `platform/powershell` (WAS modules, scripts), `platform/python-api`, `platform/workflows`, `platform/tui`, `deploy`, `tests`, `tools`, `third_party`, `archive`, `provenance`, `docs`.
- WAS modules: `platform/powershell/WAS/WAS.Core.psd1` implements WAS-prefixed functions (metrics, backup, config/optimize/security profiles). `WAS.Shim.psd1` maps legacy AutoSuite/Aurora names to WAS.
- Example run: `platform/powershell/AutoSuite_EndToEnd.ps1` imports WAS shim/core and exercises backup + profile flows.
- Safety: backups skip root-drive copies unless `-AllowRootCopy` is provided; profile actions are applied in-memory/state (no destructive system changes).
- Function list: see `docs/WAS-Modules-And-Functions.md`; mappings in `docs/WAS-Function-Mapping.md`.
