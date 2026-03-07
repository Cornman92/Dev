/**
 * Scaffolder MCP Tools — tool registrations for all scaffolding operations.
 */
import { z } from 'zod';
import { NamingService } from '../services/naming-service.js';
import { generatePsModule, generateCsViewModel, generateCsService, generateReadme, generateChangelog, generateFullModule, } from '../services/template-engine.js';
import { DEFAULT_AUTHOR, DEFAULT_VERSION, DEFAULT_LICENSE, BETTER11_NS, BETTER11_PREFIX, } from '../constants.js';
const CHARACTER_LIMIT = 40_000;
const naming = new NamingService();
function formatResult(result) {
    if (!result.success) {
        return `❌ Scaffolding failed:\n${result.errors.join('\n')}`;
    }
    const fileList = result.files.map(f => `  📄 ${f.relativePath} (${f.language}, ${f.content.split('\n').length} lines)`).join('\n');
    let output = `✅ ${result.summary}\n\nGenerated ${result.files.length} file(s):\n${fileList}`;
    for (const file of result.files) {
        const fileContent = `\n\n─── ${file.relativePath} ───\n\`\`\`${file.language}\n${file.content}\n\`\`\``;
        if (output.length + fileContent.length > CHARACTER_LIMIT) {
            output += `\n\n⚠️ Output truncated at ${CHARACTER_LIMIT} characters.`;
            break;
        }
        output += fileContent;
    }
    return output;
}
// ─── Zod Schemas ────────────────────────────────────────────────
const PsParamSchema = z.object({
    name: z.string().min(1).describe('Parameter name'),
    type: z.string().default('string').describe('PowerShell type'),
    mandatory: z.boolean().default(false),
    position: z.number().int().min(0).default(0),
    helpMessage: z.string().default(''),
    validateSet: z.array(z.string()).optional(),
    defaultValue: z.string().optional(),
}).strict();
const PsFunctionSchema = z.object({
    name: z.string().min(1).describe('Function name in Verb-Noun format'),
    description: z.string().min(1),
    parameters: z.array(PsParamSchema).default([]),
    returnType: z.string().default('PSObject'),
    supportsShouldProcess: z.boolean().default(false),
}).strict();
const CsPropertySchema = z.object({
    name: z.string().min(1),
    type: z.string().default('string'),
    defaultValue: z.string().optional(),
    isObservable: z.boolean().default(true),
    description: z.string().default(''),
}).strict();
const CsCommandSchema = z.object({
    name: z.string().min(1),
    description: z.string().default(''),
    isAsync: z.boolean().default(true),
    canExecuteProperty: z.string().optional(),
    parameterType: z.string().optional(),
}).strict();
const CsServiceRefSchema = z.object({
    interfaceName: z.string().min(1),
    fieldName: z.string().min(1),
}).strict();
const CsMethodSchema = z.object({
    name: z.string().min(1),
    returnType: z.string().default('void'),
    isAsync: z.boolean().default(true),
    parameters: z.array(z.object({
        name: z.string().min(1),
        type: z.string().min(1),
        defaultValue: z.string().optional(),
    }).strict()).default([]),
    description: z.string().default(''),
}).strict();
const BadgeSchema = z.object({
    label: z.string().min(1),
    value: z.string().min(1),
    color: z.string().min(1),
}).strict();
// ─── Tool Registration ──────────────────────────────────────────
export function registerScaffolderTools(server) {
    // ── 1. scaffold_ps_module ────────────────────────────────────
    server.registerTool('scaffold_ps_module', {
        title: 'Scaffold PowerShell Module',
        description: `Generate a complete PowerShell module with .psm1, .psd1 manifest, individual function files in Public/, and Pester tests.

Uses Better11 conventions: strict mode, error handling, comment-based help, approved verbs.

Args:
  - moduleName: Module name (e.g., Better11.Drivers)
  - description: Module description
  - functions: Array of function definitions with Verb-Noun names
  - author, version, dependencies, tags: Module metadata
  - includeManifest/includeTests: What to generate

Returns: Generated file contents with paths.`,
        inputSchema: {
            moduleName: z.string().min(1).describe('Module name (e.g., Better11.Drivers)'),
            description: z.string().min(1).describe('Module description'),
            author: z.string().default(DEFAULT_AUTHOR),
            version: z.string().default(DEFAULT_VERSION),
            functions: z.array(PsFunctionSchema).min(1),
            dependencies: z.array(z.string()).default([]),
            tags: z.array(z.string()).default([]),
            includeManifest: z.boolean().default(true),
            includeTests: z.boolean().default(true),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        try {
            const result = generatePsModule(params);
            return { content: [{ type: 'text', text: formatResult(result) }] };
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { content: [{ type: 'text', text: `❌ Error: ${msg}` }], isError: true };
        }
    });
    // ── 2. scaffold_cs_viewmodel ─────────────────────────────────
    server.registerTool('scaffold_cs_viewmodel', {
        title: 'Scaffold C# WinUI 3 ViewModel',
        description: `Generate a CommunityToolkit.Mvvm ViewModel class with ObservableProperties, RelayCommands, DI constructor, logging, and xUnit tests.

Args:
  - className: ViewModel class name
  - namespace, properties, commands, injectedServices: Config
  - includeNavigation/includeValidation: Feature flags

Returns: ViewModel .cs file and test file.`,
        inputSchema: {
            className: z.string().min(1),
            namespace: z.string().default(BETTER11_NS),
            description: z.string().default(''),
            baseClass: z.string().default('ObservableObject'),
            properties: z.array(CsPropertySchema).default([]),
            commands: z.array(CsCommandSchema).default([]),
            injectedServices: z.array(CsServiceRefSchema).default([]),
            includeNavigation: z.boolean().default(false),
            includeValidation: z.boolean().default(false),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        try {
            const config = {
                ...params,
                description: params.description || `${params.className} ViewModel`,
            };
            const result = generateCsViewModel(config);
            return { content: [{ type: 'text', text: formatResult(result) }] };
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { content: [{ type: 'text', text: `❌ Error: ${msg}` }], isError: true };
        }
    });
    // ── 3. scaffold_cs_service ───────────────────────────────────
    server.registerTool('scaffold_cs_service', {
        title: 'Scaffold C# Service + Interface',
        description: `Generate a C# service class with matching interface, DI support, logging, and xUnit tests.

Args:
  - className/interfaceName: Service class and interface names
  - methods: Method definitions with signatures
  - lifetime: DI lifetime (Singleton, Scoped, Transient)

Returns: Interface, implementation, and test files.`,
        inputSchema: {
            className: z.string().min(1),
            interfaceName: z.string().min(1),
            namespace: z.string().default(BETTER11_NS),
            description: z.string().default(''),
            methods: z.array(CsMethodSchema).min(1),
            injectedServices: z.array(CsServiceRefSchema).default([]),
            lifetime: z.enum(['Singleton', 'Scoped', 'Transient']).default('Singleton'),
            includeLogging: z.boolean().default(true),
            includeTests: z.boolean().default(true),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        try {
            const config = {
                ...params,
                description: params.description || `${params.className} service`,
            };
            const result = generateCsService(config);
            return { content: [{ type: 'text', text: formatResult(result) }] };
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { content: [{ type: 'text', text: `❌ Error: ${msg}` }], isError: true };
        }
    });
    // ── 4. scaffold_readme ───────────────────────────────────────
    server.registerTool('scaffold_readme', {
        title: 'Scaffold README.md',
        description: `Generate a professional README.md with badges, features, prerequisites, installation, and usage sections.`,
        inputSchema: {
            projectName: z.string().min(1),
            description: z.string().min(1),
            features: z.array(z.string()).min(1),
            prerequisites: z.array(z.string()).default([]),
            installSteps: z.array(z.string()).default([]),
            usageExamples: z.array(z.string()).default([]),
            author: z.string().default(DEFAULT_AUTHOR),
            license: z.string().default(DEFAULT_LICENSE),
            badges: z.array(BadgeSchema).default([]),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        try {
            const result = generateReadme(params);
            return { content: [{ type: 'text', text: formatResult(result) }] };
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { content: [{ type: 'text', text: `❌ Error: ${msg}` }], isError: true };
        }
    });
    // ── 5. scaffold_changelog ────────────────────────────────────
    server.registerTool('scaffold_changelog', {
        title: 'Scaffold CHANGELOG.md',
        description: `Generate a Keep a Changelog format CHANGELOG.md with Added, Changed, Fixed, Deprecated, Removed sections.`,
        inputSchema: {
            projectName: z.string().min(1),
            version: z.string().default(DEFAULT_VERSION),
            date: z.string().default(new Date().toISOString().split('T')[0] ?? ''),
            added: z.array(z.string()).default([]),
            changed: z.array(z.string()).default([]),
            fixed: z.array(z.string()).default([]),
            deprecated: z.array(z.string()).default([]),
            removed: z.array(z.string()).default([]),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        try {
            const result = generateChangelog(params);
            return { content: [{ type: 'text', text: formatResult(result) }] };
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { content: [{ type: 'text', text: `❌ Error: ${msg}` }], isError: true };
        }
    });
    // ── 6. scaffold_full_module ──────────────────────────────────
    server.registerTool('scaffold_full_module', {
        title: 'Scaffold Full Module (PS + C# + Docs)',
        description: `Generate a complete Better11 module with PowerShell backend, C# ViewModel, C# Service, README, and CHANGELOG — all wired together.

Args:
  - moduleName: Module name used across all layers
  - description: Module description
  - psFunctions, vmProperties, vmCommands, svcMethods: Layer configs

Returns: All generated files across all layers.`,
        inputSchema: {
            moduleName: z.string().min(1),
            description: z.string().min(1),
            author: z.string().default(DEFAULT_AUTHOR),
            version: z.string().default(DEFAULT_VERSION),
            psFunctions: z.array(PsFunctionSchema).default([]),
            psDependencies: z.array(z.string()).default([]),
            vmProperties: z.array(CsPropertySchema).default([]),
            vmCommands: z.array(CsCommandSchema).default([]),
            svcMethods: z.array(CsMethodSchema).default([]),
            svcDependencies: z.array(CsServiceRefSchema).default([]),
            includeReadme: z.boolean().default(true),
            includeChangelog: z.boolean().default(true),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        try {
            const names = naming.toVariants(params.moduleName);
            const config = {
                moduleName: params.moduleName,
                description: params.description,
                author: params.author,
                version: params.version,
                psModule: {
                    moduleName: `${BETTER11_PREFIX}.${names.pascal}`,
                    description: params.description,
                    author: params.author,
                    version: params.version,
                    functions: params.psFunctions,
                    dependencies: params.psDependencies,
                    tags: [names.pascal, 'Better11', 'Windows'],
                    includeManifest: true,
                    includeTests: true,
                },
                csViewModel: {
                    className: `${names.pascal}ViewModel`,
                    namespace: BETTER11_NS,
                    description: `${names.display} ViewModel`,
                    baseClass: 'ObservableObject',
                    properties: params.vmProperties,
                    commands: params.vmCommands,
                    injectedServices: [
                        { interfaceName: `I${names.pascal}Service`, fieldName: `_${names.camel}Service` },
                        ...params.svcDependencies,
                    ],
                    includeNavigation: true,
                    includeValidation: true,
                },
                csService: {
                    className: `${names.pascal}Service`,
                    interfaceName: `I${names.pascal}Service`,
                    namespace: BETTER11_NS,
                    description: `${names.display} service`,
                    methods: params.svcMethods,
                    injectedServices: params.svcDependencies,
                    lifetime: 'Singleton',
                    includeLogging: true,
                    includeTests: true,
                },
                includeReadme: params.includeReadme,
                includeChangelog: params.includeChangelog,
            };
            const result = generateFullModule(config);
            return { content: [{ type: 'text', text: formatResult(result) }] };
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            return { content: [{ type: 'text', text: `❌ Error: ${msg}` }], isError: true };
        }
    });
    // ── 7. scaffold_validate_name ────────────────────────────────
    server.registerTool('scaffold_validate_name', {
        title: 'Validate & Convert Name',
        description: `Validate a PowerShell function name or C# class name and generate all casing variants.`,
        inputSchema: {
            name: z.string().min(1),
            nameType: z.enum(['ps-function', 'cs-class']),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        const result = params.nameType === 'ps-function'
            ? naming.validatePsFunctionName(params.name)
            : naming.validateCsClassName(params.name);
        const output = [
            result.valid ? `✅ "${params.name}" is valid` : `❌ "${params.name}" has issues`,
            '',
            ...result.errors.map(e => `  Error: ${e}`),
            ...result.suggestions.map(s => `  Suggestion: ${s}`),
        ];
        if (result.variants) {
            output.push('', '  Name variants:', `    PascalCase:  ${result.variants.pascal}`, `    camelCase:   ${result.variants.camel}`, `    kebab-case:  ${result.variants.kebab}`, `    snake_case:  ${result.variants.snake}`, `    Display:     ${result.variants.display}`);
        }
        return { content: [{ type: 'text', text: output.join('\n') }] };
    });
    // ── 8. scaffold_list_templates ───────────────────────────────
    server.registerTool('scaffold_list_templates', {
        title: 'List Available Templates',
        description: `List all available scaffolding templates with categories, required/optional params, and generated file patterns.`,
        inputSchema: {
            category: z.enum(['powershell', 'csharp-viewmodel', 'csharp-service', 'documentation', 'composite', 'all'])
                .default('all'),
        },
        annotations: {
            readOnlyHint: true,
            destructiveHint: false,
            idempotentHint: true,
            openWorldHint: false,
        },
    }, async (params) => {
        const templates = [
            {
                id: 'scaffold_ps_module', name: 'PowerShell Module',
                description: 'Complete PS module with .psm1, .psd1, Public/ functions, and Pester tests',
                category: 'powershell',
                files: ['<Module>/<Module>.psm1', '<Module>/<Module>.psd1', '<Module>/Public/*.ps1', '<Module>/Tests/*.Tests.ps1'],
                requiredParams: ['moduleName', 'description', 'functions'],
                optionalParams: ['author', 'version', 'dependencies', 'tags', 'includeManifest', 'includeTests'],
            },
            {
                id: 'scaffold_cs_viewmodel', name: 'C# WinUI 3 ViewModel',
                description: 'CommunityToolkit.Mvvm ViewModel with ObservableProperties, RelayCommands, DI, and xUnit tests',
                category: 'csharp-viewmodel',
                files: ['ViewModels/<Class>.cs', 'Tests/ViewModels/<Class>Tests.cs'],
                requiredParams: ['className'],
                optionalParams: ['namespace', 'properties', 'commands', 'injectedServices', 'includeNavigation', 'includeValidation'],
            },
            {
                id: 'scaffold_cs_service', name: 'C# Service + Interface',
                description: 'Service class with interface, DI support, logging, and xUnit tests',
                category: 'csharp-service',
                files: ['Services/I<Class>.cs', 'Services/<Class>.cs', 'Tests/Services/<Class>Tests.cs'],
                requiredParams: ['className', 'interfaceName', 'methods'],
                optionalParams: ['namespace', 'injectedServices', 'lifetime', 'includeLogging', 'includeTests'],
            },
            {
                id: 'scaffold_readme', name: 'README.md',
                description: 'Professional README with badges, features, install, and usage',
                category: 'documentation',
                files: ['README.md'],
                requiredParams: ['projectName', 'description', 'features'],
                optionalParams: ['prerequisites', 'installSteps', 'usageExamples', 'author', 'license', 'badges'],
            },
            {
                id: 'scaffold_changelog', name: 'CHANGELOG.md',
                description: 'Keep a Changelog format with Added/Changed/Fixed/Deprecated/Removed',
                category: 'documentation',
                files: ['CHANGELOG.md'],
                requiredParams: ['projectName'],
                optionalParams: ['version', 'date', 'added', 'changed', 'fixed', 'deprecated', 'removed'],
            },
            {
                id: 'scaffold_full_module', name: 'Full Module (PS + C# + Docs)',
                description: 'Complete Better11 module: PS backend, C# ViewModel + Service, README, CHANGELOG',
                category: 'composite',
                files: ['*.psm1', '*.psd1', 'Public/*.ps1', 'Tests/*.ps1', 'ViewModels/*.cs', 'Services/*.cs', 'Tests/**/*Tests.cs', 'README.md', 'CHANGELOG.md'],
                requiredParams: ['moduleName', 'description'],
                optionalParams: ['psFunctions', 'vmProperties', 'vmCommands', 'svcMethods', 'includeReadme', 'includeChangelog'],
            },
        ];
        const filtered = params.category === 'all'
            ? templates
            : templates.filter(t => t.category === params.category);
        const catLabels = {
            'powershell': '⚡ PowerShell',
            'csharp-viewmodel': '🖥️ C# ViewModel',
            'csharp-service': '⚙️ C# Service',
            'documentation': '📝 Documentation',
            'composite': '📦 Composite',
        };
        const output = filtered.map(t => [
            `📋 ${t.name} [${catLabels[t.category] ?? t.category}]`,
            `   Tool: ${t.id}`,
            `   ${t.description}`,
            `   Files: ${t.files.join(', ')}`,
            `   Required: ${t.requiredParams.join(', ')}`,
            `   Optional: ${t.optionalParams.join(', ')}`,
        ].join('\n')).join('\n\n');
        return {
            content: [{
                    type: 'text',
                    text: `Available Templates (${filtered.length}):\n\n${output}`,
                }],
        };
    });
}
//# sourceMappingURL=scaffolder-tools.js.map