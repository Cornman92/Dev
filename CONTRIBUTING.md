# Contributing Guidelines

Guidelines for contributing to this development workspace.

## Directory Usage

### Where to Put Code

| Type of Code | Directory |
|--------------|-----------|
| New experiments | `Scratch/` |
| Tested scripts | `Scripts/` |
| Reusable functions | `Functions/` |
| Complete modules | `Modules/` |
| System optimizations | `Optimizations/` |
| Registry modifications | `Registry/` |
| Completed projects | `Archive/` |
| Build outputs | `Artifacts/` |
| Media/resources | `Assets/` |
| Active projects | `CurrentProjects/` |

## Code Style

### PowerShell

```powershell
# Use approved verbs
function Get-SomeThing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Implementation
}
```

**Conventions:**
- Use PascalCase for function names
- Use camelCase for local variables
- Include comment-based help for public functions
- Use approved verbs: `Get-Verb` to see the list

### General Guidelines

1. **Single Purpose** - Each script/function should do one thing well
2. **Documentation** - Include header comments explaining purpose
3. **Error Handling** - Handle errors gracefully
4. **No Hardcoding** - Use parameters instead of hardcoded values

## Git Workflow

### Branching

```bash
# Create feature branch
git checkout -b feature/description

# Create bugfix branch
git checkout -b fix/description
```

### Commits

- Keep commits atomic (one logical change)
- Write clear commit messages
- Reference issues if applicable

**Commit Message Format:**
```
type: brief description

Optional longer description if needed.
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

### Pull Requests

1. Create a branch for your changes
2. Make your changes and test
3. Commit with clear messages
4. Push and create PR
5. Wait for review

## Testing

1. **Always test in `Scratch/` first**
2. Test edge cases
3. Verify on clean environment if possible
4. Document any dependencies

## Security

**Never commit:**
- Passwords or secrets
- API keys or tokens
- Personal information
- Credentials of any kind

Use environment variables or secure vaults for sensitive data.

## Questions?

Open an issue or reach out directly.
