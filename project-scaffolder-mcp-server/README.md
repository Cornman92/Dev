# Project Scaffolder MCP Server

MCP server for scaffolding Better11 project patterns — PowerShell modules, C# WinUI 3 ViewModels/Services, README, and CHANGELOG files.

## Tools (8)

| Tool | Description |
|------|-------------|
| `scaffold_ps_module` | Generate complete PS module (.psm1, .psd1, Public/ functions, Pester tests) |
| `scaffold_cs_viewmodel` | Generate CommunityToolkit.Mvvm ViewModel with ObservableProperties & RelayCommands |
| `scaffold_cs_service` | Generate C# service class with matching interface, DI, logging, xUnit tests |
| `scaffold_readme` | Generate professional README.md with badges, features, install, usage |
| `scaffold_changelog` | Generate Keep a Changelog format CHANGELOG.md |
| `scaffold_full_module` | Generate complete Better11 module (PS + C# ViewModel + Service + docs) |
| `scaffold_validate_name` | Validate PS/C# names and generate all casing variants |
| `scaffold_list_templates` | List available scaffolding templates with parameters |

## Setup

```json
{
  "mcpServers": {
    "project-scaffolder": {
      "command": "node",
      "args": ["/path/to/project-scaffolder-mcp-server/dist/index.js"]
    }
  }
}
```

## Build & Test

```bash
npm install
npm run build      # TypeScript → dist/
npm test           # 152 tests
npm run test:coverage  # Coverage report
npm run lint       # ESLint (0 errors)
```

## Coverage

| Metric | Threshold | Actual |
|--------|-----------|--------|
| Statements | 90% | 95.9% |
| Branches | 80% | 82.4% |
| Functions | 90% | 100% |
| Lines | 90% | 95.9% |

## Architecture

```
src/
├── index.ts                    # Entry point (stdio transport)
├── constants.ts                # Shared constants, reserved keywords
├── types.ts                    # TypeScript interfaces
├── services/
│   ├── name-utils.ts           # Name splitting, casing, validation
│   ├── naming-service.ts       # NamingService class wrapper
│   └── template-engine.ts      # Code generation for all template types
└── tools/
    └── scaffolder-tools.ts     # 8 MCP tool registrations with Zod schemas
```
