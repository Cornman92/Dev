# Project Structure Standards

> Last Updated: 2025-01-20  
> Purpose: Define standard project structure for all projects in the Dev workspace

## Standard Project Structure

All new projects should follow this structure. Existing projects should be gradually migrated where feasible.

```
[ProjectName]/
├── src/                    # Source code
│   ├── [language-specific structure]
│   └── ...
├── tests/                  # Test files
│   ├── Unit/              # Unit tests
│   ├── Integration/       # Integration tests
│   └── ...
├── docs/                   # Project-specific documentation
│   ├── README.md          # Project overview
│   ├── API.md             # API documentation (if applicable)
│   └── ...
├── config/                 # Configuration files
│   ├── [config files]
│   └── ...
├── scripts/                # Build/deployment scripts
│   ├── build.ps1          # Build script
│   ├── test.ps1           # Test script
│   └── ...
├── .gitignore             # Project-specific gitignore
├── README.md              # Main project README
├── LICENSE                # License file (if applicable)
└── [project-specific files]
```

## Language-Specific Structures

### PowerShell Projects

```
[ProjectName]/
├── src/
│   ├── [ProjectName].psd1  # Module manifest
│   ├── [ProjectName].psm1  # Module file
│   ├── Public/             # Public functions
│   │   └── *.ps1
│   ├── Private/            # Private/internal functions
│   │   └── *.ps1
│   └── Classes/            # PowerShell classes (if any)
│       └── *.ps1
├── tests/
│   ├── Unit/
│   │   └── *.Tests.ps1
│   └── Integration/
│       └── *.Tests.ps1
└── ...
```

### C#/.NET Projects

```
[ProjectName]/
├── src/
│   ├── [ProjectName].sln   # Solution file
│   ├── [ProjectName].Core/ # Core project
│   │   ├── *.cs
│   │   └── [ProjectName].Core.csproj
│   ├── [ProjectName].Infrastructure/ # Infrastructure project
│   │   └── ...
│   └── ...
├── tests/
│   ├── [ProjectName].Tests.Unit/
│   │   └── *.cs
│   └── [ProjectName].Tests.Integration/
│       └── *.cs
└── ...
```

### Node.js Projects

```
[ProjectName]/
├── src/
│   ├── index.js           # Entry point
│   ├── routes/            # API routes
│   ├── services/          # Business logic
│   ├── models/            # Data models
│   └── ...
├── tests/
│   ├── unit/
│   └── integration/
├── config/
│   └── ...
├── package.json
└── ...
```

### Python Projects

```
[ProjectName]/
├── src/
│   ├── [project_name]/    # Main package
│   │   ├── __init__.py
│   │   └── ...
│   └── ...
├── tests/
│   ├── unit/
│   └── integration/
├── requirements.txt
├── setup.py
└── ...
```

## Required Files

### README.md

Every project must have a README.md with the following sections:

1. **Project Name** - Clear title
2. **Description** - What the project does
3. **Status** - Current status (Production Ready, Active Development, Planning Phase)
4. **Requirements** - Prerequisites and dependencies
5. **Installation** - How to install/setup
6. **Usage** - Basic usage examples
7. **Documentation** - Links to additional docs
8. **Contributing** - How to contribute (link to main CONTRIBUTING.md if applicable)
9. **License** - License information

### .gitignore

Every project should have a `.gitignore` file appropriate for its language/framework.

### LICENSE

Projects should include a LICENSE file. Use the workspace default license unless specified otherwise.

## Documentation Standards

### Project Documentation Location

- Project-specific docs: `docs/projects/[ProjectName]/`
- Main README: `[ProjectName]/README.md`
- API docs: `docs/projects/[ProjectName]/API.md` or `[ProjectName]/docs/API.md`

### Documentation Requirements

- All public APIs must be documented
- Code examples should be provided
- Architecture diagrams for complex projects
- Setup/installation instructions
- Troubleshooting guide (for user-facing projects)

## Naming Conventions

### Project Names
- Use PascalCase for project names: `ProjectName`
- Use descriptive names that indicate purpose
- Avoid abbreviations unless widely understood

### Directory Names
- Use PascalCase for C# projects: `ProjectName.Core`
- Use lowercase with hyphens for other projects: `project-name`
- Use descriptive names: `Public`, `Private`, `Services`, `Models`

### File Names
- Follow language conventions:
  - PowerShell: `Verb-Noun.ps1` (functions), `Noun.ps1` (scripts)
  - C#: `PascalCase.cs`
  - JavaScript: `camelCase.js` or `PascalCase.js` (classes)
  - Python: `snake_case.py`

## Testing Standards

### Test Structure
- Unit tests: Test individual functions/methods in isolation
- Integration tests: Test component interactions
- Test files should mirror source structure

### Test Naming
- PowerShell: `*.Tests.ps1`
- C#: `*Tests.cs`
- JavaScript: `*.test.js` or `*.spec.js`
- Python: `test_*.py`

### Coverage Goals
- Minimum: 60% code coverage
- Target: 80%+ code coverage
- Critical paths: 100% coverage

## Build and Deployment

### Build Scripts
- PowerShell projects: `scripts/build.ps1`
- .NET projects: Use MSBuild/DotNet CLI
- Node.js projects: Use npm scripts
- Python projects: Use setup.py or pyproject.toml

### Versioning
- Follow Semantic Versioning (SemVer): `MAJOR.MINOR.PATCH`
- Update version in appropriate files (manifest, package.json, etc.)
- Tag releases in Git

## Exceptions

Large legacy projects (GaymerPC, Windows-Automation-Station) may not follow this structure exactly due to their size and history. However, new components should follow these standards.

## Migration Guide

For existing projects:

1. **Assess current structure** - Document current layout
2. **Plan migration** - Identify what can be moved/renamed
3. **Create new structure** - Set up new directories
4. **Move files gradually** - Migrate in phases
5. **Update references** - Fix imports, paths, etc.
6. **Test thoroughly** - Ensure everything still works
7. **Update documentation** - Reflect new structure

## References

- [PowerShell Module Guidelines](https://docs.microsoft.com/powershell/scripting/developer/module/strongly-encouraged-development-guidelines)
- [.NET Project Structure](https://docs.microsoft.com/dotnet/core/project-structure)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Python Project Structure](https://docs.python-guide.org/writing/structure/)

---

*Last Updated: 2025-01-20*
