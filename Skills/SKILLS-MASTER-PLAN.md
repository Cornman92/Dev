# Skills Master Plan
> **Total Skills:** 17 | **Base Path:** D:\Skills | **Created:** 2026-02-05

---

## Executive Summary

This document defines the complete architecture for 17 custom Claude skills organized into 4 categories. Each skill follows the skill-creator framework with SKILL.md, scripts/, references/, and assets/ as needed.

---

## Skill Inventory

### Category 1: Windows Infrastructure (5 skills)

| # | Skill | Folder Name | Priority | Complexity |
|---|-------|-------------|----------|------------|
| 1 | Windows Image Master | `windows-image-master` | P0 | High |
| 2 | Windows Automation | `windows-automation` | P0 | Medium |
| 3 | Windows File Organizer | `windows-file-organizer` | P2 | Low |
| 4 | Registry Operations Expert | `registry-ops-expert` | P1 | Medium |
| 5 | Windows Service Creator | `windows-service-creator` | P1 | Medium |

### Category 2: Development Workflow (6 skills)

| # | Skill | Folder Name | Priority | Complexity |
|---|-------|-------------|----------|------------|
| 6 | MCP Server Creator | `mcp-server-creator` | P0 | Medium |
| 7 | Code Base Analyzer | `codebase-analyzer` | P0 | High |
| 8 | Scope Creep Maintainer | `scope-creep-maintainer` | P1 | Medium |
| 9 | Project Scaffolder | `project-scaffolder` | P0 | Medium |
| 10 | PowerShell Module Scaffolder | `powershell-module-scaffolder` | P0 | Medium |
| 11 | WinUI 3/MVVM Generator | `winui3-mvvm-generator` | P1 | High |

### Category 3: Ideation & Implementation (3 skills)

| # | Skill | Folder Name | Priority | Complexity |
|---|-------|-------------|----------|------------|
| 12 | Idea/Feature Suggester | `idea-suggester` | P1 | Medium |
| 13 | Idea/Feature Implementer | `idea-implementer` | P1 | High |
| 14 | Idea/Feature Revisor | `idea-revisor` | P2 | Medium |

### Category 4: Quality & DevOps (3 skills)

| # | Skill | Folder Name | Priority | Complexity |
|---|-------|-------------|----------|------------|
| 15 | Documentation Generator | `documentation-generator` | P1 | Medium |
| 16 | Test Coverage Analyzer | `test-coverage-analyzer` | P1 | Medium |
| 17 | CI/CD Pipeline Builder | `cicd-pipeline-builder` | P2 | High |

---

## Recommended Build Order

### Phase 1: Foundation (P0 - Build First)
1. **Project Scaffolder** - Foundation for all other project-based skills
2. **PowerShell Module Scaffolder** - Enables PS module creation for other skills
3. **MCP Server Creator** - Standalone, high utility
4. **Code Base Analyzer** - Informs other skills' decisions
5. **Windows Automation** - Core Windows capability
6. **Windows Image Master** - Comprehensive Windows imaging

### Phase 2: Enhancement (P1 - Build Second)
7. **Registry Operations Expert** - Supports Windows skills
8. **Windows Service Creator** - Supports Windows automation
9. **WinUI 3/MVVM Generator** - Supports Better11 development
10. **Scope Creep Maintainer** - Project management
11. **Idea Suggester** - Ideation workflow start
12. **Idea Implementer** - Ideation workflow middle
13. **Documentation Generator** - Quality improvement
14. **Test Coverage Analyzer** - Quality improvement

### Phase 3: Polish (P2 - Build Last)
15. **Windows File Organizer** - Utility skill
16. **Idea Revisor** - Ideation workflow end
17. **CI/CD Pipeline Builder** - Advanced DevOps

---

## Skill Dependencies

```
project-scaffolder ──────┬──> powershell-module-scaffolder
                         ├──> winui3-mvvm-generator
                         ├──> windows-service-creator
                         └──> mcp-server-creator

codebase-analyzer ───────┬──> scope-creep-maintainer
                         ├──> idea-suggester
                         ├──> test-coverage-analyzer
                         └──> documentation-generator

windows-automation ──────┬──> windows-image-master
                         ├──> registry-ops-expert
                         └──> windows-file-organizer

idea-suggester ──────────> idea-implementer ──────────> idea-revisor
```

---

## Detailed Skill Specifications

---

### 1. Windows Image Master
**Folder:** `D:\Skills\windows-image-master`

**Description:** Comprehensive Windows image customization, creation, and deployment. Handles WIM/ESD manipulation, driver injection, feature management, answer file generation, ISO building, WinPE creation, and deployment via MDT/WDS/USB.

**Structure:**
```
windows-image-master/
├── SKILL.md
├── scripts/
│   ├── Mount-WindowsImage.ps1
│   ├── Inject-Drivers.ps1
│   ├── Add-WindowsFeatures.ps1
│   ├── Create-AnswerFile.ps1
│   ├── Build-CustomISO.ps1
│   ├── Create-WinPE.ps1
│   ├── Export-ImageInfo.ps1
│   └── Deploy-Image.ps1
├── references/
│   ├── dism-commands.md
│   ├── answer-file-schema.md
│   ├── mdt-integration.md
│   ├── wds-deployment.md
│   └── troubleshooting.md
└── assets/
    ├── templates/
    │   ├── unattend-workstation.xml
    │   ├── unattend-server.xml
    │   └── winpe-startnet.cmd
    └── samples/
        └── driver-catalog.json
```

**Key Capabilities:**
- WIM/ESD mount, modify, commit, export
- Offline driver injection (INF, CAB)
- Feature enable/disable (NetFx3, Hyper-V, WSL)
- Answer file generation (OOBE, disk config, user accounts)
- ISO creation with custom boot options
- WinPE builder with custom tools
- MDT task sequence integration
- WDS multicast deployment

---

### 2. Windows Automation
**Folder:** `D:\Skills\windows-automation`

**Description:** PowerShell-based Windows system automation including scheduled tasks, system configuration, service management, event log monitoring, and remote administration.

**Structure:**
```
windows-automation/
├── SKILL.md
├── scripts/
│   ├── New-ScheduledTask.ps1
│   ├── Set-SystemConfiguration.ps1
│   ├── Manage-WindowsServices.ps1
│   ├── Monitor-EventLogs.ps1
│   ├── Invoke-RemoteCommand.ps1
│   └── Export-SystemReport.ps1
├── references/
│   ├── task-scheduler-patterns.md
│   ├── wmi-cim-reference.md
│   ├── remoting-setup.md
│   └── common-configurations.md
└── assets/
    └── templates/
        ├── task-template.xml
        └── config-baseline.json
```

**Key Capabilities:**
- Scheduled task creation/management
- System configuration (power, network, security)
- Service lifecycle management
- Event log querying and alerting
- PowerShell remoting (WinRM, SSH)
- System inventory and reporting

---

### 3. Windows File Organizer
**Folder:** `D:\Skills\windows-file-organizer`

**Description:** Intelligent file and folder organization including cleanup scripts, archiving, duplicate detection, and structured project scaffolding.

**Structure:**
```
windows-file-organizer/
├── SKILL.md
├── scripts/
│   ├── Organize-Downloads.ps1
│   ├── Find-Duplicates.ps1
│   ├── Archive-OldFiles.ps1
│   ├── New-ProjectStructure.ps1
│   └── Clean-TempFiles.ps1
├── references/
│   ├── organization-patterns.md
│   └── archive-strategies.md
└── assets/
    └── templates/
        └── folder-structures.json
```

---

### 4. Registry Operations Expert
**Folder:** `D:\Skills\registry-ops-expert`

**Description:** Safe Windows registry manipulation with backup/rollback patterns, bulk operations, and common tweak libraries.

**Structure:**
```
registry-ops-expert/
├── SKILL.md
├── scripts/
│   ├── Backup-RegistryKey.ps1
│   ├── Restore-RegistryKey.ps1
│   ├── Set-RegistryValue.ps1
│   ├── Import-RegistryTweaks.ps1
│   ├── Export-RegistryReport.ps1
│   └── Compare-RegistrySnapshots.ps1
├── references/
│   ├── registry-hives.md
│   ├── common-tweaks.md
│   ├── security-considerations.md
│   └── value-types.md
└── assets/
    └── tweaks/
        ├── performance.reg
        ├── privacy.reg
        ├── explorer.reg
        └── context-menu.reg
```

---

### 5. Windows Service Creator
**Folder:** `D:\Skills\windows-service-creator`

**Description:** Windows service project scaffolding with proper lifecycle management, logging, configuration, and installation scripts.

**Structure:**
```
windows-service-creator/
├── SKILL.md
├── scripts/
│   ├── New-ServiceProject.ps1
│   ├── Install-Service.ps1
│   ├── Test-ServiceHealth.ps1
│   └── Generate-ServiceInstaller.ps1
├── references/
│   ├── service-lifecycle.md
│   ├── service-accounts.md
│   ├── recovery-options.md
│   └── topshelf-guide.md
└── assets/
    └── templates/
        ├── csharp-service/
        ├── powershell-service/
        └── service-installer.iss
```

---

### 6. MCP Server Creator
**Folder:** `D:\Skills\mcp-server-creator`

**Description:** Scaffold Model Context Protocol servers with tools, resources, and prompts. Supports TypeScript/Node.js and Python implementations.

**Structure:**
```
mcp-server-creator/
├── SKILL.md
├── scripts/
│   ├── New-McpServer.ps1
│   ├── Add-McpTool.ps1
│   ├── Add-McpResource.ps1
│   ├── Add-McpPrompt.ps1
│   ├── Test-McpServer.ps1
│   └── Package-McpServer.ps1
├── references/
│   ├── mcp-specification.md
│   ├── tool-patterns.md
│   ├── resource-patterns.md
│   ├── transport-options.md
│   └── claude-desktop-config.md
└── assets/
    └── templates/
        ├── typescript-mcp/
        ├── python-mcp/
        └── tool-schemas/
```

---

### 7. Code Base Analyzer
**Folder:** `D:\Skills\codebase-analyzer`

**Description:** Deep codebase analysis including architecture mapping, dependency graphing, tech debt identification, complexity metrics, and health scoring.

**Structure:**
```
codebase-analyzer/
├── SKILL.md
├── scripts/
│   ├── Analyze-Architecture.ps1
│   ├── Map-Dependencies.ps1
│   ├── Calculate-Complexity.ps1
│   ├── Find-TechDebt.ps1
│   ├── Generate-HealthReport.ps1
│   └── Export-DependencyGraph.ps1
├── references/
│   ├── metrics-definitions.md
│   ├── architecture-patterns.md
│   ├── tech-debt-categories.md
│   └── language-analyzers.md
└── assets/
    └── templates/
        ├── report-template.md
        └── graph-styles.json
```

---

### 8. Scope Creep Maintainer
**Folder:** `D:\Skills\scope-creep-maintainer`

**Description:** Feature tracking, requirement drift detection, scope validation, and project boundary enforcement.

**Structure:**
```
scope-creep-maintainer/
├── SKILL.md
├── scripts/
│   ├── Initialize-ScopeDocument.ps1
│   ├── Track-FeatureRequest.ps1
│   ├── Validate-Scope.ps1
│   ├── Generate-ScopeReport.ps1
│   └── Compare-ScopeVersions.ps1
├── references/
│   ├── scope-management.md
│   ├── change-request-process.md
│   └── prioritization-frameworks.md
└── assets/
    └── templates/
        ├── scope-document.md
        ├── change-request.md
        └── feature-matrix.xlsx
```

---

### 9. Project Scaffolder
**Folder:** `D:\Skills\project-scaffolder`

**Description:** Universal project structure generation for multiple languages/frameworks with best practices, CI/CD templates, and documentation stubs.

**Structure:**
```
project-scaffolder/
├── SKILL.md
├── scripts/
│   ├── New-Project.ps1
│   ├── Add-Component.ps1
│   ├── Initialize-Git.ps1
│   └── Generate-Documentation.ps1
├── references/
│   ├── project-types.md
│   ├── folder-conventions.md
│   └── file-templates.md
└── assets/
    └── templates/
        ├── csharp-console/
        ├── csharp-winui3/
        ├── powershell-module/
        ├── python-package/
        ├── typescript-node/
        └── common/
            ├── .gitignore
            ├── .editorconfig
            └── README.md
```

---

### 10. PowerShell Module Scaffolder
**Folder:** `D:\Skills\powershell-module-scaffolder`

**Description:** Standardized PowerShell module creation with manifest, public/private functions, Pester tests, PSScriptAnalyzer compliance, and build scripts.

**Structure:**
```
powershell-module-scaffolder/
├── SKILL.md
├── scripts/
│   ├── New-PSModule.ps1
│   ├── Add-PSFunction.ps1
│   ├── New-PesterTest.ps1
│   ├── Invoke-PSAnalyzer.ps1
│   ├── Build-Module.ps1
│   └── Publish-Module.ps1
├── references/
│   ├── module-structure.md
│   ├── manifest-fields.md
│   ├── pester-patterns.md
│   ├── psscriptanalyzer-rules.md
│   └── publishing-guide.md
└── assets/
    └── templates/
        ├── module-template/
        │   ├── ModuleName.psd1
        │   ├── ModuleName.psm1
        │   ├── Public/
        │   ├── Private/
        │   └── Tests/
        └── function-templates/
            ├── public-function.ps1
            ├── private-function.ps1
            └── pester-test.ps1
```

---

### 11. WinUI 3/MVVM Generator
**Folder:** `D:\Skills\winui3-mvvm-generator`

**Description:** WinUI 3 application scaffolding following MVVM patterns with ViewModels, Views, Services, and DI configuration aligned with Better11 architecture.

**Structure:**
```
winui3-mvvm-generator/
├── SKILL.md
├── scripts/
│   ├── New-WinUIProject.ps1
│   ├── Add-ViewModel.ps1
│   ├── Add-View.ps1
│   ├── Add-Service.ps1
│   ├── Add-Model.ps1
│   └── Configure-DependencyInjection.ps1
├── references/
│   ├── mvvm-patterns.md
│   ├── winui3-controls.md
│   ├── dependency-injection.md
│   ├── navigation-patterns.md
│   └── better11-conventions.md
└── assets/
    └── templates/
        ├── viewmodel.cs
        ├── view.xaml
        ├── view.xaml.cs
        ├── service-interface.cs
        ├── service-implementation.cs
        └── model.cs
```

---

### 12. Idea/Feature Suggester
**Folder:** `D:\Skills\idea-suggester`

**Description:** Context-aware feature recommendations based on codebase analysis, industry patterns, user needs, and gap analysis.

**Structure:**
```
idea-suggester/
├── SKILL.md
├── scripts/
│   ├── Analyze-FeatureGaps.ps1
│   ├── Generate-Suggestions.ps1
│   ├── Prioritize-Features.ps1
│   └── Export-FeatureRoadmap.ps1
├── references/
│   ├── suggestion-criteria.md
│   ├── industry-patterns.md
│   ├── prioritization-matrix.md
│   └── integration-points.md
└── assets/
    └── templates/
        ├── feature-proposal.md
        └── roadmap-template.md
```

---

### 13. Idea/Feature Implementer
**Folder:** `D:\Skills\idea-implementer`

**Description:** Structured implementation workflow from specifications to production-ready code with proper architecture, tests, and documentation.

**Structure:**
```
idea-implementer/
├── SKILL.md
├── scripts/
│   ├── Parse-FeatureSpec.ps1
│   ├── Generate-ImplementationPlan.ps1
│   ├── Create-Scaffolding.ps1
│   ├── Validate-Implementation.ps1
│   └── Generate-PullRequest.ps1
├── references/
│   ├── implementation-workflow.md
│   ├── code-standards.md
│   ├── testing-requirements.md
│   └── documentation-standards.md
└── assets/
    └── templates/
        ├── implementation-plan.md
        ├── pull-request.md
        └── test-plan.md
```

---

### 14. Idea/Feature Revisor
**Folder:** `D:\Skills\idea-revisor`

**Description:** Code quality improvement, pattern modernization, refactoring strategies, and technical debt reduction.

**Structure:**
```
idea-revisor/
├── SKILL.md
├── scripts/
│   ├── Analyze-RefactorOpportunities.ps1
│   ├── Generate-RefactorPlan.ps1
│   ├── Apply-Refactoring.ps1
│   ├── Validate-Refactoring.ps1
│   └── Measure-Improvement.ps1
├── references/
│   ├── refactoring-catalog.md
│   ├── code-smells.md
│   ├── modernization-patterns.md
│   └── safe-refactoring.md
└── assets/
    └── templates/
        ├── refactor-plan.md
        └── before-after-comparison.md
```

---

### 15. Documentation Generator
**Folder:** `D:\Skills\documentation-generator`

**Description:** Automated documentation generation including API docs, user guides, architecture diagrams, and inline code documentation.

**Structure:**
```
documentation-generator/
├── SKILL.md
├── scripts/
│   ├── Generate-ApiDocs.ps1
│   ├── Generate-UserGuide.ps1
│   ├── Generate-ArchitectureDiagram.ps1
│   ├── Extract-InlineComments.ps1
│   ├── Build-DocumentationSite.ps1
│   └── Validate-Documentation.ps1
├── references/
│   ├── documentation-types.md
│   ├── xml-comment-guide.md
│   ├── markdown-conventions.md
│   └── diagram-tools.md
└── assets/
    └── templates/
        ├── api-doc.md
        ├── user-guide.md
        ├── architecture-doc.md
        └── readme-template.md
```

---

### 16. Test Coverage Analyzer
**Folder:** `D:\Skills\test-coverage-analyzer`

**Description:** Test coverage analysis, gap identification, test generation recommendations, and coverage reporting.

**Structure:**
```
test-coverage-analyzer/
├── SKILL.md
├── scripts/
│   ├── Analyze-Coverage.ps1
│   ├── Find-UncoveredCode.ps1
│   ├── Generate-TestSuggestions.ps1
│   ├── Create-CoverageReport.ps1
│   └── Track-CoverageHistory.ps1
├── references/
│   ├── coverage-metrics.md
│   ├── testing-strategies.md
│   ├── pester-coverage.md
│   ├── dotnet-coverage.md
│   └── coverage-thresholds.md
└── assets/
    └── templates/
        ├── coverage-report.md
        ├── test-template.ps1
        └── test-template.cs
```

---

### 17. CI/CD Pipeline Builder
**Folder:** `D:\Skills\cicd-pipeline-builder`

**Description:** CI/CD pipeline generation for GitHub Actions, Azure DevOps, and GitLab with build, test, deploy stages.

**Structure:**
```
cicd-pipeline-builder/
├── SKILL.md
├── scripts/
│   ├── New-Pipeline.ps1
│   ├── Add-BuildStage.ps1
│   ├── Add-TestStage.ps1
│   ├── Add-DeployStage.ps1
│   ├── Validate-Pipeline.ps1
│   └── Migrate-Pipeline.ps1
├── references/
│   ├── github-actions-guide.md
│   ├── azure-devops-guide.md
│   ├── gitlab-ci-guide.md
│   ├── pipeline-patterns.md
│   └── secrets-management.md
└── assets/
    └── templates/
        ├── github-actions/
        │   ├── dotnet-build.yml
        │   ├── powershell-test.yml
        │   └── deploy-azure.yml
        ├── azure-devops/
        │   ├── dotnet-pipeline.yml
        │   └── release-pipeline.yml
        └── gitlab/
            └── .gitlab-ci.yml
```

---

## Next Steps

### Immediate Actions
1. Review and approve this master plan
2. Select first skill to build
3. Begin incremental implementation

### Per-Skill Build Process
1. Initialize skill structure using init_skill.py
2. Create SKILL.md with frontmatter and body
3. Implement scripts with full functionality
4. Create reference documentation
5. Add asset templates
6. Test all scripts (100% coverage, PSScriptAnalyzer clean)
7. Package skill using package_skill.py
8. Validate and iterate

### Quality Gates (Per Skill)
- [ ] SKILL.md complete with triggers
- [ ] All scripts functional
- [ ] PSScriptAnalyzer 0 errors
- [ ] 100% test coverage
- [ ] References documented
- [ ] Assets included
- [ ] Package validates

---

## Appendix: Skill Trigger Keywords

| Skill | Primary Triggers |
|-------|------------------|
| Windows Image Master | "image", "WIM", "ISO", "deploy", "WinPE", "unattend", "driver injection" |
| Windows Automation | "automate", "scheduled task", "remote", "service", "event log" |
| Windows File Organizer | "organize", "cleanup", "duplicate", "archive", "folder structure" |
| Registry Operations Expert | "registry", "regedit", "HKLM", "HKCU", "tweak" |
| Windows Service Creator | "windows service", "background service", "daemon" |
| MCP Server Creator | "MCP", "model context protocol", "claude tool", "MCP server" |
| Code Base Analyzer | "analyze codebase", "architecture", "dependencies", "tech debt", "complexity" |
| Scope Creep Maintainer | "scope", "feature creep", "requirements drift", "scope validation" |
| Project Scaffolder | "new project", "scaffold", "project structure", "boilerplate" |
| PowerShell Module Scaffolder | "PS module", "PowerShell module", "psd1", "psm1" |
| WinUI 3/MVVM Generator | "WinUI", "MVVM", "ViewModel", "WinUI3", "XAML" |
| Idea Suggester | "suggest features", "what features", "recommendations", "gaps" |
| Idea Implementer | "implement feature", "build this", "code this feature" |
| Idea Revisor | "refactor", "improve code", "modernize", "clean up" |
| Documentation Generator | "generate docs", "document this", "API docs", "user guide" |
| Test Coverage Analyzer | "test coverage", "untested code", "coverage report" |
| CI/CD Pipeline Builder | "pipeline", "CI/CD", "GitHub Actions", "Azure DevOps", "GitLab CI" |

---

*Document generated: 2026-02-05*
*Status: Planning Complete - Ready for Implementation*
