---
name: better11-post
description: Guides post-optimization steps after the user is mostly done optimizing their Windows image with Better11 (reports, backup, imaging, deployment). Use when the user has finished tweaking and wants to export a report, create a backup, capture an image, or run health checks.
---

# Better11 — Post (After Optimization)

Use this skill when **the user is done (or mostly done) optimizing** their Windows system with Better11 and wants to document, backup, or deploy.

## Suggested Next Steps

1. **Export a report** — Use Better11 Reporting (GUI or module) to save HTML/JSON/MD of changes and system state for records.
2. **Create a backup/image** — System image (DISM, Macrium, Windows Backup) or full backup before further changes.
3. **Deployment (optional)** — If capturing for deployment: generalize (Sysprep) then capture; use BetterBoot pipeline for full flow.
4. **Bootable USB / post-boot** — Optional: create bootable USB or run post-boot scripts via BetterBoot.

## MCP Tools (Post Phase)

When the Better11 MCP server is enabled:

- **better11_post_export_report** — Suggest how to export a report (format: html, json, md).
- **better11_post_health_check** — Run a quick build/health check (e.g. solution build).
- **better11_post_suggest_next_steps** — Return the suggested next steps (report, backup, imaging, deployment).

## Better11 Sub-Components (Post Context)

- **Better.Wim** — Edit/capture boot.wim, install.wim, custom WinPE/WinRE.
- **BetterBoot** — Full pipeline: WinPE → Apply → Generalize → Capture → Export → USB → Install → Post-OOBE → Post-Boot.

Use these when the user asks about **imaging**, **capturing**, or **deploying** the optimized system.
