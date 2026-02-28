# cursor.md - Editor & IDE Configuration

Rules and settings for Cursor, VS Code, and other editors working in this workspace.

---

## General Editor Settings

- **Default EOL:** CRLF (Windows workspace)
- **Indent Style:** Spaces
- **Indent Size:** 4 (PowerShell, Python, C#) / 2 (JSON, YAML, HTML, CSS)
- **Trim Trailing Whitespace:** Yes
- **Insert Final Newline:** Yes
- **Encoding:** UTF-8 (with BOM for PowerShell `.ps1` files)

## Language-Specific Rules

### PowerShell (.ps1, .psm1, .psd1)
- Indent: 4 spaces
- Use PascalCase for functions: `Get-UserInfo`, `Set-Configuration`
- Use camelCase for variables: `$userName`, `$filePath`
- Use approved verbs only (run `Get-Verb` for the list)
- Include `[CmdletBinding()]` on all advanced functions
- Prefer splatting for commands with 3+ parameters
- Use `Write-Verbose` / `Write-Debug` instead of `Write-Host` for non-output messages

### Python (.py)
- Indent: 4 spaces
- Follow PEP 8 naming: `snake_case` for functions/variables, `PascalCase` for classes
- Use type hints on function signatures
- Max line length: 120 characters
- Use f-strings for string formatting

### JavaScript / TypeScript (.js, .ts)
- Indent: 2 spaces
- Use `const` by default, `let` when reassignment needed, never `var`
- Use arrow functions for callbacks
- Prefer template literals over string concatenation

### JSON (.json)
- Indent: 2 spaces
- Always use double quotes
- No trailing commas

### YAML (.yaml, .yml)
- Indent: 2 spaces
- Use lowercase keys with hyphens: `my-setting-name`
- Quote strings that could be misinterpreted (e.g., `"yes"`, `"no"`, `"true"`)

### Markdown (.md)
- Indent: 2 spaces for nested lists
- Use ATX-style headers (`#`, `##`, `###`)
- One blank line before and after headers
- Use fenced code blocks with language identifiers

## File Organization Rules

- New files go in `Scratch/` until tested and validated
- Production scripts go in `Scripts/`
- Reusable functions go in `Functions/`
- Follow the directory structure defined in `CLAUDE.md`

## Git Integration

- **Pre-commit hook active:** Scans for secrets (passwords, API keys, private keys)
- **Commit-msg hook active:** Enforces conventional commit format
- Commit types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- Format: `type: description` or `type(scope): description`

## Cursor AI / Copilot Rules

When generating code in this workspace:

1. **Follow the coding conventions** defined in CLAUDE.md and CONTRIBUTING.md
2. **Check `Functions/` first** before creating new utility functions
3. **PowerShell is the primary language** for system scripts and automation
4. **Never generate hardcoded secrets** - use environment variables or parameter inputs
5. **Include comment-based help** for any new PowerShell function
6. **Target PowerShell 5.1+ compatibility** unless explicitly using 7+ features
7. **Use `$ErrorActionPreference = 'Stop'`** at the top of scripts that should fail fast
8. **Prefer native cmdlets** over calling external executables when possible

## Recommended Extensions

| Extension | Purpose |
|-----------|---------|
| PowerShell (ms-vscode.powershell) | PowerShell language support and debugging |
| Python (ms-python.python) | Python language support |
| EditorConfig (editorconfig.editorconfig) | Cross-editor settings from `.editorconfig` |
| GitLens (eamodio.gitlens) | Enhanced git integration |
| Markdown All in One (yzhang.markdown-all-in-one) | Markdown editing support |
| Code Spell Checker (streetsidesoftware.code-spell-checker) | Catch typos in code and docs |

## Excluded Files / Folders

These should be hidden from the editor file explorer:

- `$RECYCLE.BIN/`
- `System Volume Information/`
- `.git/`
- `node_modules/`
- `__pycache__/`
- `.venv/` / `venv/`
- `*.pyc`
