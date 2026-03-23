<#
.SYNOPSIS
    Installs git hooks for the Dev workspace.

.DESCRIPTION
    Creates pre-commit (secret scanning) and commit-msg (conventional
    commit validation) hooks in .git/hooks/. Backs up any existing
    hooks before overwriting.

.EXAMPLE
    .\Scripts\Install-GitHooks.ps1
    Installs all git hooks.

.EXAMPLE
    .\Scripts\Install-GitHooks.ps1 -Force
    Overwrites existing hooks without prompting.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ---- Locate workspace root ----
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$hooksDir = Join-Path $workspaceRoot '.git' 'hooks'

if (-not (Test-Path $hooksDir)) {
    Write-Error "Git hooks directory not found at $hooksDir. Is this a git repository?"
}

# ---- Pre-Commit Hook: Secret Scanner ----
$preCommitPath = Join-Path $hooksDir 'pre-commit'
$preCommitContent = @'
#!/bin/sh
# ===========================================
# Pre-Commit Hook: Secret & Sensitive Data Scanner
# ===========================================
# Scans staged files for potential secrets, credentials,
# API keys, and other sensitive data before allowing commit.

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Running pre-commit secret scan..."

STAGED_FILES=$(git diff --cached --name-only --diff-filter=d)

if [ -z "$STAGED_FILES" ]; then
    echo "${GREEN}No staged files to scan.${NC}"
    exit 0
fi

PATTERNS="
(?i)(password|passwd|pwd)\s*[=:]\s*['\"][^'\"]{4,}['\"]|Hardcoded password
(?i)(api[_-]?key|apikey)\s*[=:]\s*['\"][^'\"]{8,}['\"]|Hardcoded API key
(?i)(secret|token)\s*[=:]\s*['\"][^'\"]{8,}['\"]|Hardcoded secret or token
(?i)(access[_-]?key|secret[_-]?key)\s*[=:]\s*['\"][^'\"]{8,}['\"]|Hardcoded access/secret key
AKIA[0-9A-Z]{16}|AWS Access Key ID
(?i)private[_-]?key|Private key reference
-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|Private key file content
(?i)(connection[_-]?string|conn[_-]?str)\s*[=:]\s*['\"][^'\"]{10,}['\"]|Hardcoded connection string
"

echo "$STAGED_FILES" | while IFS= read -r file; do
    if file "$file" 2>/dev/null | grep -q "binary"; then
        continue
    fi
    [ "$file" = ".git/hooks/pre-commit" ] && continue

    CONTENT=$(git show ":$file" 2>/dev/null)
    [ -z "$CONTENT" ] && continue

    echo "$PATTERNS" | while IFS='|' read -r pattern description; do
        [ -z "$pattern" ] && continue
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$pattern" ] && continue

        MATCHES=$(echo "$CONTENT" | grep -nP "$pattern" 2>/dev/null)
        if [ -n "$MATCHES" ]; then
            echo "${RED}BLOCKED:${NC} ${YELLOW}$description${NC}"
            echo "  File: $file"
            echo "$MATCHES" | head -3 | while IFS= read -r line; do
                echo "  Line: $line"
            done
            echo ""
            echo "ISSUE_FOUND" >> /tmp/pre-commit-issues-$$
        fi
    done
done

if [ -f /tmp/pre-commit-issues-$$ ]; then
    ISSUE_COUNT=$(wc -l < /tmp/pre-commit-issues-$$)
    rm -f /tmp/pre-commit-issues-$$
    echo "${RED}========================================${NC}"
    echo "${RED}Commit blocked: $ISSUE_COUNT potential secret(s) found.${NC}"
    echo "${RED}========================================${NC}"
    echo ""
    echo "To fix: Remove sensitive data from staged files."
    echo "To bypass (use with caution): git commit --no-verify"
    exit 1
fi

rm -f /tmp/pre-commit-issues-$$
echo "${GREEN}Secret scan passed. No issues found.${NC}"
exit 0
'@

# ---- Commit-Msg Hook: Conventional Commit Validator ----
$commitMsgPath = Join-Path $hooksDir 'commit-msg'
$commitMsgContent = @'
#!/bin/sh
# ===========================================
# Commit-Msg Hook: Conventional Commit Validator
# ===========================================
# Validates commit messages follow the conventional commit format:
#   type: brief description
# Valid types: feat, fix, docs, refactor, test, chore

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")
FIRST_LINE=$(echo "$COMMIT_MSG" | head -1)

echo "$FIRST_LINE" | grep -qE "^Merge " && exit 0
echo "$FIRST_LINE" | grep -qE "^Revert " && exit 0

VALID_TYPES="feat|fix|docs|refactor|test|chore"
PATTERN="^($VALID_TYPES)(\([a-zA-Z0-9_-]+\))?: .{1,}"

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
    echo ""
    echo "${RED}========================================${NC}"
    echo "${RED}Invalid commit message format${NC}"
    echo "${RED}========================================${NC}"
    echo ""
    echo "Your message:  ${YELLOW}$FIRST_LINE${NC}"
    echo ""
    echo "Expected format:"
    echo "  ${GREEN}type: brief description${NC}"
    echo "  ${GREEN}type(scope): brief description${NC}"
    echo ""
    echo "Valid types: ${GREEN}feat, fix, docs, refactor, test, chore${NC}"
    echo ""
    echo "To bypass (use with caution): git commit --no-verify"
    exit 1
fi

SUBJECT_LENGTH=$(echo "$FIRST_LINE" | wc -c)
if [ "$SUBJECT_LENGTH" -gt 73 ]; then
    echo "${YELLOW}Warning: Subject line is $((SUBJECT_LENGTH - 1)) characters. Consider keeping it under 72.${NC}"
fi

echo "${GREEN}Commit message format validated.${NC}"
exit 0
'@

# ---- Install hooks ----
$hooks = @(
    @{ Name = 'pre-commit'; Path = $preCommitPath; Content = $preCommitContent },
    @{ Name = 'commit-msg'; Path = $commitMsgPath; Content = $commitMsgContent }
)

foreach ($hook in $hooks) {
    if ((Test-Path $hook.Path) -and -not $Force) {
        $existing = Get-Content $hook.Path -Raw -ErrorAction SilentlyContinue
        if ($existing -and -not $existing.Contains('.sample')) {
            $backupPath = "$($hook.Path).backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $hook.Path $backupPath
            Write-Host "[*] Backed up existing $($hook.Name) to $(Split-Path $backupPath -Leaf)" -ForegroundColor Yellow
        }
    }

    Set-Content -Path $hook.Path -Value $hook.Content -NoNewline -Encoding UTF8
    Write-Host "[+] Installed $($hook.Name) hook" -ForegroundColor Green

    # Make executable (git for Windows handles this, but set for WSL/Linux)
    if ($IsLinux -or $IsMacOS) {
        chmod +x $hook.Path
    }
}

Write-Host ""
Write-Host "[+] All git hooks installed successfully." -ForegroundColor Green
