import { randomUUID } from 'node:crypto';
import type {
    PsModuleConfig, PsFunctionConfig, PsParamConfig,
    CsViewModelConfig, CsServiceConfig,
    ReadmeConfig, ChangelogConfig, FullModuleConfig,
    GeneratedFile, ScaffoldResult,
} from '../types.js';
import { DEFAULT_AUTHOR, DEFAULT_VERSION, DEFAULT_LICENSE, BETTER11_NS, BETTER11_PREFIX, CS_BASES } from '../constants.js';
import { generateNameVariants, toFieldName, toInterfaceName } from './name-utils.js';

function renderParam(p: PsParamConfig): string {
    const parts: string[] = [];
    const pAttrs: string[] = [];
    if (p.mandatory) pAttrs.push('Mandatory = $true');
    if (p.position >= 0) pAttrs.push(`Position = ${p.position}`);
    if (p.helpMessage) pAttrs.push(`HelpMessage = '${p.helpMessage.replace(/'/g, "''")}'`);
    parts.push(`        [Parameter(${pAttrs.join(', ')})]`);
    if (p.validateSet && p.validateSet.length > 0) {
        parts.push(`        [ValidateSet(${p.validateSet.map((v) => `'${v}'`).join(', ')})]`);
    }
    const def = p.defaultValue ? ` = ${p.defaultValue}` : '';
    parts.push(`        [${p.type}]$${p.name}${def}`);
    return parts.join('\n');
}

function renderFn(fn: PsFunctionConfig): string {
    const params = fn.parameters.map(renderParam).join(',\n\n');
    const sp = fn.supportsShouldProcess ? 'SupportsShouldProcess' : '';
    return `function ${fn.name} {
    <#
    .SYNOPSIS
        ${fn.description}
    .DESCRIPTION
        ${fn.description}
    #>
    [CmdletBinding(${sp})]
    [OutputType([${fn.returnType}])]
    param(
${params}
    )
    begin { Write-Verbose "Starting ${fn.name}" }
    process {
        try {
            throw [System.NotImplementedException]::new('${fn.name} not yet implemented')
        } catch {
            Write-Error "Error in ${fn.name}: \$(\$_.Exception.Message)"
            throw
        }
    }
    end { Write-Verbose "Completed ${fn.name}" }
}`;
}

function renderManifest(config: PsModuleConfig, modName: string): string {
    const fns = config.functions.map((f) => `'${f.name}'`).join(',\n        ');
    const deps = config.dependencies.map((d) => `'${d}'`).join(', ');
    const tags = config.tags.map((t) => `'${t}'`).join(', ');
    return `@{
    RootModule        = '${modName}.psm1'
    ModuleVersion     = '${config.version}'
    GUID              = '${randomUUID()}'
    Author            = '${config.author}'
    Description       = '${config.description}'
    PowerShellVersion = '5.1'
    RequiredModules   = @(${deps})
    FunctionsToExport = @(
        ${fns}
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{ Tags = @(${tags}); ProjectUri = '' }
    }
}\n`;
}

function renderPester(config: PsModuleConfig, modName: string): string {
    const fnTests = config.functions.map((fn) => {
        const paramTests = fn.parameters.filter((p) => p.mandatory).map((p) =>
            `\n            It 'Should have mandatory parameter ${p.name}' {\n                $cmd = Get-Command ${fn.name}\n                $cmd.Parameters['${p.name}'].Attributes.Mandatory | Should -BeTrue\n            }`
        ).join('');
        return `\n    Describe '${fn.name}' {\n        It 'Should exist' { Get-Command ${fn.name} -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty }${paramTests}\n    }`;
    }).join('\n');
    return `BeforeAll { Import-Module (Join-Path $PSScriptRoot '..' '${modName}.psm1') -Force }
Describe '${modName} Module' {
    It 'Should import' { Get-Module ${modName} | Should -Not -BeNullOrEmpty }${fnTests}
}
AfterAll { Remove-Module ${modName} -Force -ErrorAction SilentlyContinue }\n`;
}

export function generatePsModule(config: PsModuleConfig): ScaffoldResult {
    try {
        const files: GeneratedFile[] = [];
        const modName = config.moduleName.startsWith(BETTER11_PREFIX) ? config.moduleName : `${BETTER11_PREFIX}.${config.moduleName}`;
        const fnsCode = config.functions.map(renderFn).join('\n\n');
        const exports = config.functions.map((f) => `'${f.name}'`).join(',\n    ');
        files.push({ relativePath: `${modName}/${modName}.psm1`, language: 'powershell', content:
`#Requires -Version 5.1\nSet-StrictMode -Version Latest\n$ErrorActionPreference = 'Stop'\n\n${fnsCode}\n\nExport-ModuleMember -Function @(\n    ${exports}\n)\n` });
        if (config.includeManifest) files.push({ relativePath: `${modName}/${modName}.psd1`, language: 'powershell', content: renderManifest(config, modName) });
        if (config.includeTests) files.push({ relativePath: `${modName}/Tests/${modName}.Tests.ps1`, language: 'powershell', content: renderPester(config, modName) });
        return { success: true, files, summary: `Generated PS module "${modName}" with ${config.functions.length} functions`, errors: [] };
    } catch (err: unknown) {
        return { success: false, files: [], summary: '', errors: [err instanceof Error ? err.message : String(err)] };
    }
}

export function generateCsViewModel(config: CsViewModelConfig): ScaffoldResult {
    try {
        const files: GeneratedFile[] = [];
        const ns = config.namespace || `${BETTER11_NS}.ViewModels`;
        const v = generateNameVariants(config.className);
        const cn = v.pascal.endsWith('ViewModel') ? v.pascal : `${v.pascal}ViewModel`;
        const base = config.baseClass || CS_BASES.viewModel;
        const usings = ['using System;', 'using System.Threading.Tasks;', 'using CommunityToolkit.Mvvm.ComponentModel;', 'using CommunityToolkit.Mvvm.Input;'];
        if (config.includeNavigation) usings.push(`using ${BETTER11_NS}.Navigation;`);
        if (config.includeValidation) usings.push('using System.ComponentModel.DataAnnotations;');
        const fields = config.injectedServices.map((s) => `    private readonly ${s.interfaceName} ${s.fieldName};`).join('\n');
        const ctorP = config.injectedServices.map((s) => `${s.interfaceName} ${s.fieldName.replace(/^_/, '')}`).join(', ');
        const ctorA = config.injectedServices.map((s) => `        ${s.fieldName} = ${s.fieldName.replace(/^_/, '')} ?? throw new ArgumentNullException(nameof(${s.fieldName.replace(/^_/, '')}));`).join('\n');
        const props = config.properties.map((p) => {
            if (!p.isObservable) {
                const d = p.defaultValue ? ` = ${p.defaultValue};` : '';
                return `    /// <summary>${p.description}</summary>\n    public ${p.type} ${p.name} { get; set; }${d}`;
            }
            const fn = toFieldName(p.name);
            const d = p.defaultValue ? ` = ${p.defaultValue}` : '';
            return `    /// <summary>${p.description}</summary>\n    [ObservableProperty]\n    private ${p.type} ${fn}${d};`;
        }).join('\n\n');
        const cmds = config.commands.map((c) => {
            const am = c.isAsync ? 'async ' : '';
            const rt = c.isAsync ? 'Task' : 'void';
            const pt = c.parameterType ? `${c.parameterType} parameter` : '';
            const ce = c.canExecuteProperty ? `\n    private bool CanExecute${c.name.replace('Command', '')}() => ${c.canExecuteProperty};` : '';
            return `    /// <summary>${c.description}</summary>\n    [RelayCommand]${ce}\n    private ${am}${rt} ${c.name.replace('Command', '')}(${pt})\n    {\n        throw new NotImplementedException("${c.name} not yet implemented");\n    }`;
        }).join('\n\n');
        files.push({ relativePath: `ViewModels/${cn}.cs`, language: 'csharp', content:
`${usings.join('\n')}\n\nnamespace ${ns};\n\n/// <summary>${config.description}</summary>\npublic partial class ${cn} : ${base}\n{\n${fields}\n\n    public ${cn}(${ctorP})\n    {\n${ctorA}\n    }\n\n    #region Properties\n\n${props}\n\n    #endregion\n\n    #region Commands\n\n${cmds}\n\n    #endregion\n}\n` });
        return { success: true, files, summary: `Generated ViewModel "${cn}" with ${config.properties.length} props, ${config.commands.length} commands`, errors: [] };
    } catch (err: unknown) {
        return { success: false, files: [], summary: '', errors: [err instanceof Error ? err.message : String(err)] };
    }
}

export function generateCsService(config: CsServiceConfig): ScaffoldResult {
    try {
        const files: GeneratedFile[] = [];
        const ns = config.namespace || `${BETTER11_NS}.Services`;
        const v = generateNameVariants(config.className);
        const cn = v.pascal.endsWith('Service') ? v.pascal : `${v.pascal}Service`;
        const iName = config.interfaceName || toInterfaceName(cn);
        // Interface
        const iMethods = config.methods.map((m) => {
            const rt = m.isAsync ? `Task<${m.returnType}>` : m.returnType;
            const ps = m.parameters.map((p) => { const d = p.defaultValue ? ` = ${p.defaultValue}` : ''; return `${p.type} ${p.name}${d}`; }).join(', ');
            return `    /// <summary>${m.description}</summary>\n    ${rt} ${m.name}(${ps});`;
        }).join('\n\n');
        files.push({ relativePath: `Services/${iName}.cs`, language: 'csharp', content: `using System;\nusing System.Threading.Tasks;\n\nnamespace ${ns};\n\npublic interface ${iName}\n{\n${iMethods}\n}\n` });
        // Implementation
        const usings = ['using System;', 'using System.Threading.Tasks;'];
        if (config.includeLogging) usings.push('using Microsoft.Extensions.Logging;');
        const flds = config.injectedServices.map((s) => `    private readonly ${s.interfaceName} ${s.fieldName};`);
        if (config.includeLogging) flds.push(`    private readonly ILogger<${cn}> _logger;`);
        const cps = config.injectedServices.map((s) => `${s.interfaceName} ${s.fieldName.replace(/^_/, '')}`);
        if (config.includeLogging) cps.push(`ILogger<${cn}> logger`);
        const cas = config.injectedServices.map((s) => `        ${s.fieldName} = ${s.fieldName.replace(/^_/, '')} ?? throw new ArgumentNullException(nameof(${s.fieldName.replace(/^_/, '')}));`);
        if (config.includeLogging) cas.push('        _logger = logger ?? throw new ArgumentNullException(nameof(logger));');
        const iMthds = config.methods.map((m) => {
            const am = m.isAsync ? 'async ' : '';
            const rt = m.isAsync ? `Task<${m.returnType}>` : m.returnType;
            const ps = m.parameters.map((p) => { const d = p.defaultValue ? ` = ${p.defaultValue}` : ''; return `${p.type} ${p.name}${d}`; }).join(', ');
            return `    /// <inheritdoc />\n    public ${am}${rt} ${m.name}(${ps})\n    {\n        throw new NotImplementedException("${m.name} not yet implemented");\n    }`;
        }).join('\n\n');
        files.push({ relativePath: `Services/${cn}.cs`, language: 'csharp', content:
`${usings.join('\n')}\n\nnamespace ${ns};\n\n/// <summary>${config.description}\n/// Lifetime: ${config.lifetime}</summary>\npublic class ${cn} : ${iName}\n{\n${flds.join('\n')}\n\n    public ${cn}(${cps.join(', ')})\n    {\n${cas.join('\n')}\n    }\n\n${iMthds}\n}\n` });
        // DI snippet
        files.push({ relativePath: `Services/${cn}.DI.txt`, language: 'text', content: `// services.Add${config.lifetime}<${iName}, ${cn}>();\n` });
        // Tests
        if (config.includeTests) {
            const tMethods = config.methods.map((m) => {
                const ar = m.isAsync ? 'async Task' : 'void';
                const sfx = m.isAsync ? 'Async' : '';
                const prms = m.parameters.map((p) => `default(${p.type})!`).join(', ');
                const body = m.isAsync
                    ? `await Assert.ThrowsAsync<NotImplementedException>(() => sut.${m.name}(${prms}));`
                    : `Assert.Throws<NotImplementedException>(() => sut.${m.name}(${prms}));`;
                return `    [Fact]\n    public ${ar} ${m.name}${sfx}_Should_ThrowNotImplemented()\n    {\n        var sut = CreateSut();\n        ${body}\n    }`;
            }).join('\n\n');
            files.push({ relativePath: `Tests/${cn}Tests.cs`, language: 'csharp', content:
`using System;\nusing System.Threading.Tasks;\nusing Xunit;\n\nnamespace ${ns}.Tests;\n\npublic class ${cn}Tests\n{\n    private static ${cn} CreateSut() => null!;\n\n${tMethods}\n}\n` });
        }
        return { success: true, files, summary: `Generated service "${cn}" implementing ${iName} with ${config.methods.length} methods`, errors: [] };
    } catch (err: unknown) {
        return { success: false, files: [], summary: '', errors: [err instanceof Error ? err.message : String(err)] };
    }
}

export function generateReadme(config: ReadmeConfig): ScaffoldResult {
    try {
        const badges = config.badges.map((b) => `![${b.label}](https://img.shields.io/badge/${encodeURIComponent(b.label)}-${encodeURIComponent(b.value)}-${b.color})`).join(' ');
        const features = config.features.map((f) => `- ${f}`).join('\n');
        const prereqs = config.prerequisites.map((p) => `- ${p}`).join('\n');
        const install = config.installSteps.map((s, i) => `${i + 1}. ${s}`).join('\n');
        const usage = config.usageExamples.map((u) => '```\n' + u + '\n```').join('\n\n');
        const content = `# ${config.projectName}\n\n${badges}\n\n${config.description}\n\n## Features\n\n${features}\n\n## Prerequisites\n\n${prereqs}\n\n## Installation\n\n${install}\n\n## Usage\n\n${usage}\n\n## License\n\n${config.license} — see [LICENSE](LICENSE) for details.\n\n## Author\n\n${config.author || DEFAULT_AUTHOR}\n`;
        return { success: true, files: [{ relativePath: 'README.md', content, language: 'markdown' }], summary: `Generated README.md for "${config.projectName}"`, errors: [] };
    } catch (err: unknown) {
        return { success: false, files: [], summary: '', errors: [err instanceof Error ? err.message : String(err)] };
    }
}

export function generateChangelog(config: ChangelogConfig): ScaffoldResult {
    try {
        const sections: string[] = [];
        if (config.added.length > 0) sections.push(`### Added\n${config.added.map((a) => `- ${a}`).join('\n')}`);
        if (config.changed.length > 0) sections.push(`### Changed\n${config.changed.map((c) => `- ${c}`).join('\n')}`);
        if (config.fixed.length > 0) sections.push(`### Fixed\n${config.fixed.map((f) => `- ${f}`).join('\n')}`);
        if (config.deprecated.length > 0) sections.push(`### Deprecated\n${config.deprecated.map((d) => `- ${d}`).join('\n')}`);
        if (config.removed.length > 0) sections.push(`### Removed\n${config.removed.map((r) => `- ${r}`).join('\n')}`);
        const content = `# Changelog\n\nAll notable changes to ${config.projectName} will be documented in this file.\n\nThe format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),\nand this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).\n\n## [${config.version}] - ${config.date}\n\n${sections.join('\n\n')}\n`;
        return { success: true, files: [{ relativePath: 'CHANGELOG.md', content, language: 'markdown' }], summary: `Generated CHANGELOG.md for "${config.projectName}" v${config.version}`, errors: [] };
    } catch (err: unknown) {
        return { success: false, files: [], summary: '', errors: [err instanceof Error ? err.message : String(err)] };
    }
}

export function generateFullModule(config: FullModuleConfig): ScaffoldResult {
    const allFiles: GeneratedFile[] = [];
    const allErrors: string[] = [];
    const summaries: string[] = [];
    const psResult = generatePsModule({
        moduleName: config.moduleName, description: config.description,
        author: config.author || DEFAULT_AUTHOR, version: config.version || DEFAULT_VERSION,
        functions: config.psModule.functions ?? [], dependencies: config.psModule.dependencies ?? [],
        tags: config.psModule.tags ?? [], includeManifest: config.psModule.includeManifest ?? true,
        includeTests: config.psModule.includeTests ?? true,
    });
    if (psResult.success) { allFiles.push(...psResult.files); summaries.push(psResult.summary); } else allErrors.push(...psResult.errors);
    if (config.csViewModel.className) {
        const vmResult = generateCsViewModel({
            className: config.csViewModel.className, namespace: config.csViewModel.namespace ?? `${BETTER11_NS}.ViewModels`,
            description: config.csViewModel.description ?? config.description, baseClass: config.csViewModel.baseClass ?? CS_BASES.viewModel,
            properties: config.csViewModel.properties ?? [], commands: config.csViewModel.commands ?? [],
            injectedServices: config.csViewModel.injectedServices ?? [], includeNavigation: config.csViewModel.includeNavigation ?? false,
            includeValidation: config.csViewModel.includeValidation ?? false,
        });
        if (vmResult.success) { allFiles.push(...vmResult.files); summaries.push(vmResult.summary); } else allErrors.push(...vmResult.errors);
    }
    if (config.csService.className) {
        const svcResult = generateCsService({
            className: config.csService.className, interfaceName: config.csService.interfaceName ?? '',
            namespace: config.csService.namespace ?? `${BETTER11_NS}.Services`, description: config.csService.description ?? config.description,
            methods: config.csService.methods ?? [], injectedServices: config.csService.injectedServices ?? [],
            lifetime: config.csService.lifetime ?? 'Singleton', includeLogging: config.csService.includeLogging ?? true,
            includeTests: config.csService.includeTests ?? true,
        });
        if (svcResult.success) { allFiles.push(...svcResult.files); summaries.push(svcResult.summary); } else allErrors.push(...svcResult.errors);
    }
    if (config.includeReadme) {
        const rr = generateReadme({ projectName: `${BETTER11_PREFIX}.${config.moduleName}`, description: config.description, features: [], prerequisites: ['Windows 10/11', 'PowerShell 5.1+'], installSteps: [`Import-Module ${BETTER11_PREFIX}.${config.moduleName}`], usageExamples: [], author: config.author || DEFAULT_AUTHOR, license: DEFAULT_LICENSE, badges: [{ label: 'version', value: config.version || DEFAULT_VERSION, color: 'blue' }] });
        if (rr.success) { allFiles.push(...rr.files); summaries.push(rr.summary); }
    }
    if (config.includeChangelog) {
        const cr = generateChangelog({ projectName: `${BETTER11_PREFIX}.${config.moduleName}`, version: config.version || DEFAULT_VERSION, date: new Date().toISOString().split('T')[0], added: [`Initial implementation of ${config.moduleName}`], changed: [], fixed: [], removed: [], deprecated: [] });
        if (cr.success) { allFiles.push(...cr.files); summaries.push(cr.summary); }
    }
    return { success: allErrors.length === 0, files: allFiles, summary: summaries.join('; '), errors: allErrors };
}
