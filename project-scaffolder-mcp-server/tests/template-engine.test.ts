import { describe, it, expect } from 'vitest';
import {
    generatePsModule, generateCsViewModel, generateCsService,
    generateReadme, generateChangelog,
} from '../src/services/template-engine.js';
import type {
    PsModuleConfig, CsViewModelConfig, CsServiceConfig,
    ReadmeConfig, ChangelogConfig,
} from '../src/types.js';

// ─── Test Fixtures ──────────────────────────────────────────────

const basePsConfig: PsModuleConfig = {
    moduleName: 'Better11.Drivers',
    description: 'Driver management module',
    author: 'C-Man',
    version: '1.0.0',
    functions: [
        {
            name: 'Get-DriverInfo',
            description: 'Gets driver information',
            parameters: [
                { name: 'Name', type: 'string', mandatory: true, position: 0, helpMessage: 'Driver name' },
                { name: 'All', type: 'switch', mandatory: false, position: 1, helpMessage: 'Get all drivers' },
            ],
            returnType: 'PSObject',
            supportsShouldProcess: false,
        },
        {
            name: 'Install-Driver',
            description: 'Installs a driver',
            parameters: [
                { name: 'Path', type: 'string', mandatory: true, position: 0, helpMessage: 'Driver path' },
            ],
            returnType: 'bool',
            supportsShouldProcess: true,
        },
    ],
    dependencies: ['Better11.Core'],
    tags: ['Drivers', 'Better11', 'Windows'],
    includeManifest: true,
    includeTests: true,
};

const baseVmConfig: CsViewModelConfig = {
    className: 'DriverManagerViewModel',
    namespace: 'Better11',
    description: 'Driver manager ViewModel',
    baseClass: 'ObservableObject',
    properties: [
        { name: 'DriverCount', type: 'int', isObservable: true, description: 'Number of drivers', defaultValue: '0' },
        { name: 'IsLoading', type: 'bool', isObservable: true, description: 'Loading state' },
        { name: 'StatusText', type: 'string', isObservable: true, description: 'Status message' },
    ],
    commands: [
        { name: 'RefreshDrivers', description: 'Refresh driver list', isAsync: true },
        { name: 'InstallDriver', description: 'Install a driver', isAsync: true, canExecuteProperty: 'IsNotLoading' },
    ],
    injectedServices: [
        { interfaceName: 'IDriverService', fieldName: '_driverService' },
    ],
    includeNavigation: true,
    includeValidation: true,
};

const baseSvcConfig: CsServiceConfig = {
    className: 'DriverService',
    interfaceName: 'IDriverService',
    namespace: 'Better11',
    description: 'Driver management service',
    methods: [
        {
            name: 'GetAllDrivers',
            returnType: 'IReadOnlyList<DriverInfo>',
            isAsync: true,
            parameters: [],
            description: 'Gets all installed drivers',
        },
        {
            name: 'InstallDriver',
            returnType: 'bool',
            isAsync: true,
            parameters: [
                { name: 'path', type: 'string' },
                { name: 'force', type: 'bool', defaultValue: 'false' },
            ],
            description: 'Installs a driver from path',
        },
    ],
    injectedServices: [
        { interfaceName: 'IPowerShellService', fieldName: '_psService' },
    ],
    lifetime: 'Singleton',
    includeLogging: true,
    includeTests: true,
};

const baseReadmeConfig: ReadmeConfig = {
    projectName: 'Better11.Drivers',
    description: 'Driver management for Better11',
    features: ['Auto-detect drivers', 'Bulk install', 'Backup/restore'],
    prerequisites: ['PowerShell 5.1+', '.NET 8.0'],
    installSteps: ['Clone repo', 'Import-Module Better11.Drivers'],
    usageExamples: ['Get-DriverInfo -Name "Realtek"'],
    author: 'C-Man',
    license: 'MIT',
    badges: [{ label: 'version', value: '1.0.0', color: 'blue' }],
};

const baseClConfig: ChangelogConfig = {
    projectName: 'Better11.Drivers',
    version: '1.0.0',
    date: '2026-02-08',
    added: ['Initial release', 'Get-DriverInfo function'],
    changed: ['Updated error handling'],
    fixed: ['Fixed path resolution'],
    deprecated: [],
    removed: [],
};

// ─── PowerShell Module Tests ────────────────────────────────────

describe('generatePsModule', () => {
    it('should return success result', () => {
        const result = generatePsModule(basePsConfig);
        expect(result.success).toBe(true);
        expect(result.errors).toHaveLength(0);
        expect(result.files.length).toBeGreaterThan(0);
        expect(result.summary).toContain('Better11.Drivers');
    });

    it('should generate .psm1 file', () => {
        const { files } = generatePsModule(basePsConfig);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'));
        expect(psm1).toBeDefined();
        expect(psm1!.language).toBe('powershell');
        expect(psm1!.content).toContain('#Requires -Version 5.1');
        expect(psm1!.content).toContain('$ErrorActionPreference');
        expect(psm1!.content).toContain('Export-ModuleMember');
    });

    it('should include all functions in .psm1', () => {
        const { files } = generatePsModule(basePsConfig);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.content).toContain('function Get-DriverInfo');
        expect(psm1.content).toContain('function Install-Driver');
    });

    it('should generate .psd1 manifest when includeManifest is true', () => {
        const { files } = generatePsModule(basePsConfig);
        const psd1 = files.find(f => f.relativePath.endsWith('.psd1'));
        expect(psd1).toBeDefined();
        expect(psd1!.content).toContain('RootModule');
        expect(psd1!.content).toContain("'Get-DriverInfo'");
        expect(psd1!.content).toContain("'Install-Driver'");
        expect(psd1!.content).toContain('RequiredModules');
        expect(psd1!.content).toContain("'Better11.Core'");
    });

    it('should skip .psd1 when includeManifest is false', () => {
        const config = { ...basePsConfig, includeManifest: false };
        const { files } = generatePsModule(config);
        const psd1 = files.find(f => f.relativePath.endsWith('.psd1'));
        expect(psd1).toBeUndefined();
    });

    it('should include SupportsShouldProcess for functions that need it', () => {
        const { files } = generatePsModule(basePsConfig);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.content).toContain('SupportsShouldProcess');
    });

    it('should render parameter attributes correctly', () => {
        const { files } = generatePsModule(basePsConfig);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.content).toContain('Mandatory = $true');
        expect(psm1.content).toContain('Position = 0');
        expect(psm1.content).toContain('[string]$Name');
        expect(psm1.content).toContain('[switch]$All');
    });

    it('should render ValidateSet when provided', () => {
        const config: PsModuleConfig = {
            ...basePsConfig,
            functions: [{
                name: 'Set-Mode',
                description: 'Sets mode',
                parameters: [{
                    name: 'Mode', type: 'string', mandatory: true, position: 0,
                    helpMessage: 'Mode', validateSet: ['Fast', 'Safe', 'Full'],
                }],
                returnType: 'void',
                supportsShouldProcess: false,
            }],
        };
        const { files } = generatePsModule(config);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.content).toContain("ValidateSet('Fast', 'Safe', 'Full')");
    });

    it('should generate Pester tests when includeTests is true', () => {
        const { files } = generatePsModule(basePsConfig);
        const tests = files.find(f => f.relativePath.includes('.Tests.ps1'));
        expect(tests).toBeDefined();
        expect(tests!.content).toContain("Describe");
        expect(tests!.content).toContain('Get-DriverInfo');
        expect(tests!.content).toContain('Should -Not -BeNullOrEmpty');
    });

    it('should skip Pester tests when includeTests is false', () => {
        const config = { ...basePsConfig, includeTests: false };
        const { files } = generatePsModule(config);
        const tests = files.find(f => f.relativePath.includes('.Tests.ps1'));
        expect(tests).toBeUndefined();
    });

    it('should generate correct file count with all options enabled', () => {
        const { files } = generatePsModule(basePsConfig);
        // .psm1 + .psd1 + 1 test file = 3
        expect(files).toHaveLength(3);
    });

    it('should render parameter default values', () => {
        const config: PsModuleConfig = {
            ...basePsConfig,
            functions: [{
                name: 'Get-Data',
                description: 'Gets data',
                parameters: [{
                    name: 'Count', type: 'int', mandatory: false, position: 0,
                    helpMessage: 'Item count', defaultValue: '10',
                }],
                returnType: 'PSObject',
                supportsShouldProcess: false,
            }],
        };
        const { files } = generatePsModule(config);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.content).toContain('$Count = 10');
    });

    it('should auto-prefix module name with Better11', () => {
        const config = { ...basePsConfig, moduleName: 'Drivers' };
        const { files } = generatePsModule(config);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.relativePath).toContain('Better11.Drivers');
    });
});

// ─── C# ViewModel Tests ────────────────────────────────────────

describe('generateCsViewModel', () => {
    it('should return success result', () => {
        const result = generateCsViewModel(baseVmConfig);
        expect(result.success).toBe(true);
        expect(result.errors).toHaveLength(0);
        expect(result.files.length).toBeGreaterThan(0);
    });

    it('should generate ViewModel .cs file', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files.find(f => f.relativePath.includes('DriverManagerViewModel.cs'));
        expect(vmFile).toBeDefined();
        expect(vmFile!.language).toBe('csharp');
    });

    it('should include CommunityToolkit.Mvvm usings', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('CommunityToolkit.Mvvm.ComponentModel');
        expect(vmFile.content).toContain('CommunityToolkit.Mvvm.Input');
    });

    it('should generate ObservableProperty attributes', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('[ObservableProperty]');
        expect(vmFile.content).toContain('_driverCount');
        expect(vmFile.content).toContain('_isLoading');
    });

    it('should generate RelayCommand attributes', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('[RelayCommand]');
        expect(vmFile.content).toContain('RefreshDrivers');
        expect(vmFile.content).toContain('InstallDriver');
    });

    it('should include CanExecute when specified', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('CanExecute');
        expect(vmFile.content).toContain('IsNotLoading');
    });

    it('should inject services via constructor', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('IDriverService driverService');
        expect(vmFile.content).toContain('_driverService = driverService');
        expect(vmFile.content).toContain('ArgumentNullException');
    });

    it('should include validation attributes when requested', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('System.ComponentModel.DataAnnotations');
    });

    it('should include navigation when requested', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('Navigation');
    });

    it('should exclude navigation when not requested', () => {
        const config = { ...baseVmConfig, includeNavigation: false };
        const { files } = generateCsViewModel(config);
        const vmFile = files[0]!;
        expect(vmFile.content).not.toContain('Navigation');
    });

    it('should include proper namespace', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain('namespace Better11');
    });

    it('should extend base class', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        const vmFile = files[0]!;
        expect(vmFile.content).toContain(': ObservableObject');
    });

    it('should generate exactly 1 file', () => {
        const { files } = generateCsViewModel(baseVmConfig);
        expect(files).toHaveLength(1);
    });
});

// ─── C# Service Tests ──────────────────────────────────────────

describe('generateCsService', () => {
    it('should return success result', () => {
        const result = generateCsService(baseSvcConfig);
        expect(result.success).toBe(true);
        expect(result.errors).toHaveLength(0);
    });

    it('should generate interface file', () => {
        const { files } = generateCsService(baseSvcConfig);
        const iface = files.find(f => f.relativePath.includes('IDriverService.cs'));
        expect(iface).toBeDefined();
        expect(iface!.content).toContain('public interface IDriverService');
        expect(iface!.content).toContain('GetAllDrivers');
        expect(iface!.content).toContain('InstallDriver');
    });

    it('should generate implementation file', () => {
        const { files } = generateCsService(baseSvcConfig);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'));
        expect(impl).toBeDefined();
        expect(impl!.content).toContain('public class DriverService : IDriverService');
        expect(impl!.content).toContain('Singleton');
    });

    it('should inject services via constructor', () => {
        const { files } = generateCsService(baseSvcConfig);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'))!;
        expect(impl.content).toContain('IPowerShellService psService');
        expect(impl.content).toContain('_psService = psService');
    });

    it('should include logging when enabled', () => {
        const { files } = generateCsService(baseSvcConfig);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'))!;
        expect(impl.content).toContain('ILogger<DriverService> logger');
        expect(impl.content).toContain('_logger = logger');
    });

    it('should generate method stubs with NotImplementedException', () => {
        const { files } = generateCsService(baseSvcConfig);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'))!;
        expect(impl.content).toContain('NotImplementedException');
    });

    it('should generate async methods correctly', () => {
        const { files } = generateCsService(baseSvcConfig);
        const iface = files.find(f => f.relativePath.includes('IDriverService.cs'))!;
        expect(iface.content).toContain('Task<IReadOnlyList<DriverInfo>>');
    });

    it('should include default parameter values in interface', () => {
        const { files } = generateCsService(baseSvcConfig);
        const iface = files.find(f => f.relativePath.includes('IDriverService.cs'))!;
        expect(iface.content).toContain('bool force = false');
    });

    it('should generate DI registration snippet', () => {
        const { files } = generateCsService(baseSvcConfig);
        const diFile = files.find(f => f.relativePath.includes('.DI.txt'));
        expect(diFile).toBeDefined();
        expect(diFile!.content).toContain('AddSingleton');
    });

    it('should generate xUnit tests when includeTests is true', () => {
        const { files } = generateCsService(baseSvcConfig);
        const testFile = files.find(f => f.relativePath.includes('Tests'));
        expect(testFile).toBeDefined();
        expect(testFile!.content).toContain('[Fact]');
        expect(testFile!.content).toContain('ThrowNotImplemented');
    });

    it('should skip tests when includeTests is false', () => {
        const config = { ...baseSvcConfig, includeTests: false };
        const { files } = generateCsService(config);
        const testFile = files.find(f => f.relativePath.includes('Tests'));
        expect(testFile).toBeUndefined();
    });

    it('should generate 4 files with tests enabled', () => {
        const { files } = generateCsService(baseSvcConfig);
        // interface + impl + DI.txt + tests = 4
        expect(files).toHaveLength(4);
    });

    it('should generate 3 files without tests', () => {
        const config = { ...baseSvcConfig, includeTests: false };
        const { files } = generateCsService(config);
        expect(files).toHaveLength(3);
    });

    it('should handle service with no injected dependencies', () => {
        const config = { ...baseSvcConfig, injectedServices: [] };
        const { files } = generateCsService(config);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'))!;
        expect(impl.content).toContain('ILogger<DriverService> logger');
        expect(impl.content).not.toContain('IPowerShellService');
    });
});

// ─── Documentation Tests ────────────────────────────────────────

describe('generateReadme', () => {
    it('should return success result', () => {
        const result = generateReadme(baseReadmeConfig);
        expect(result.success).toBe(true);
        expect(result.files).toHaveLength(1);
    });

    it('should generate README.md', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.relativePath).toBe('README.md');
        expect(files[0]!.language).toBe('markdown');
    });

    it('should include project name as heading', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('# Better11.Drivers');
    });

    it('should include features', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('- Auto-detect drivers');
        expect(files[0]!.content).toContain('- Bulk install');
    });

    it('should include badges', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('img.shields.io/badge');
    });

    it('should include prerequisites', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('PowerShell 5.1+');
    });

    it('should include numbered install steps', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('1. Clone repo');
        expect(files[0]!.content).toContain('2. Import-Module');
    });

    it('should include author', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('C-Man');
    });

    it('should include license', () => {
        const { files } = generateReadme(baseReadmeConfig);
        expect(files[0]!.content).toContain('MIT');
    });
});

describe('generateChangelog', () => {
    it('should return success result', () => {
        const result = generateChangelog(baseClConfig);
        expect(result.success).toBe(true);
        expect(result.files).toHaveLength(1);
    });

    it('should generate CHANGELOG.md', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.relativePath).toBe('CHANGELOG.md');
    });

    it('should include Keep a Changelog header', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).toContain('Keep a Changelog');
    });

    it('should include version and date', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).toContain('[1.0.0] - 2026-02-08');
    });

    it('should include Added section', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).toContain('### Added');
        expect(files[0]!.content).toContain('- Initial release');
    });

    it('should include Changed section', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).toContain('### Changed');
    });

    it('should include Fixed section', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).toContain('### Fixed');
        expect(files[0]!.content).toContain('- Fixed path resolution');
    });

    it('should skip empty sections', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).not.toContain('### Deprecated');
        expect(files[0]!.content).not.toContain('### Removed');
    });

    it('should include Semantic Versioning reference', () => {
        const { files } = generateChangelog(baseClConfig);
        expect(files[0]!.content).toContain('Semantic Versioning');
    });
});

// ─── Full Module Tests ──────────────────────────────────────────

import { generateFullModule } from '../src/services/template-engine.js';
import type { FullModuleConfig } from '../src/types.js';

describe('generateFullModule', () => {
    const baseFullConfig: FullModuleConfig = {
        moduleName: 'Drivers',
        description: 'Driver management module',
        author: 'C-Man',
        version: '1.0.0',
        psModule: {
            functions: [{
                name: 'Get-DriverInfo',
                description: 'Gets driver info',
                parameters: [],
                returnType: 'PSObject',
                supportsShouldProcess: false,
            }],
            dependencies: [],
            tags: ['Drivers'],
            includeManifest: true,
            includeTests: true,
        },
        csViewModel: {
            className: 'DriverManagerViewModel',
            properties: [],
            commands: [],
            injectedServices: [],
        },
        csService: {
            className: 'DriverService',
            methods: [],
            injectedServices: [],
        },
        includeReadme: true,
        includeChangelog: true,
    };

    it('should return success result', () => {
        const result = generateFullModule(baseFullConfig);
        expect(result.success).toBe(true);
        expect(result.errors).toHaveLength(0);
    });

    it('should generate PS module files', () => {
        const { files } = generateFullModule(baseFullConfig);
        expect(files.some(f => f.relativePath.endsWith('.psm1'))).toBe(true);
        expect(files.some(f => f.relativePath.endsWith('.psd1'))).toBe(true);
    });

    it('should generate ViewModel file', () => {
        const { files } = generateFullModule(baseFullConfig);
        expect(files.some(f => f.relativePath.includes('ViewModel.cs'))).toBe(true);
    });

    it('should generate service files', () => {
        const { files } = generateFullModule(baseFullConfig);
        expect(files.some(f => f.relativePath.includes('Service.cs'))).toBe(true);
        expect(files.some(f => f.relativePath.includes('IDriverService.cs'))).toBe(true);
    });

    it('should generate README when requested', () => {
        const { files } = generateFullModule(baseFullConfig);
        expect(files.some(f => f.relativePath === 'README.md')).toBe(true);
    });

    it('should generate CHANGELOG when requested', () => {
        const { files } = generateFullModule(baseFullConfig);
        expect(files.some(f => f.relativePath === 'CHANGELOG.md')).toBe(true);
    });

    it('should skip README when not requested', () => {
        const config = { ...baseFullConfig, includeReadme: false };
        const { files } = generateFullModule(config);
        expect(files.some(f => f.relativePath === 'README.md')).toBe(false);
    });

    it('should skip CHANGELOG when not requested', () => {
        const config = { ...baseFullConfig, includeChangelog: false };
        const { files } = generateFullModule(config);
        expect(files.some(f => f.relativePath === 'CHANGELOG.md')).toBe(false);
    });

    it('should skip ViewModel when className is empty', () => {
        const config = { ...baseFullConfig, csViewModel: {} };
        const { files } = generateFullModule(config);
        expect(files.some(f => f.relativePath.includes('ViewModel.cs'))).toBe(false);
    });

    it('should skip Service when className is empty', () => {
        const config = { ...baseFullConfig, csService: {} };
        const { files } = generateFullModule(config);
        expect(files.some(f => f.relativePath.includes('Service.cs'))).toBe(false);
    });

    it('should combine summaries from all generators', () => {
        const result = generateFullModule(baseFullConfig);
        expect(result.summary.length).toBeGreaterThan(0);
    });
});

// ─── Additional template engine coverage ────────────────────────

describe('generateCsViewModel - additional coverage', () => {
    it('should handle sync commands', () => {
        const config: CsViewModelConfig = {
            className: 'TestViewModel',
            namespace: 'Test',
            description: 'Test VM',
            baseClass: 'ObservableObject',
            properties: [],
            commands: [{ name: 'DoWork', description: 'Do work', isAsync: false }],
            injectedServices: [],
            includeNavigation: false,
            includeValidation: false,
        };
        const { files } = generateCsViewModel(config);
        expect(files[0]!.content).toContain('void DoWork');
    });

    it('should handle commands with parameter types', () => {
        const config: CsViewModelConfig = {
            className: 'TestViewModel',
            namespace: 'Test',
            description: 'Test VM',
            baseClass: 'ObservableObject',
            properties: [],
            commands: [{ name: 'SelectItem', description: 'Select', isAsync: true, parameterType: 'ItemModel' }],
            injectedServices: [],
            includeNavigation: false,
            includeValidation: false,
        };
        const { files } = generateCsViewModel(config);
        expect(files[0]!.content).toContain('ItemModel parameter');
    });

    it('should handle non-observable properties', () => {
        const config: CsViewModelConfig = {
            className: 'TestViewModel',
            namespace: 'Test',
            description: 'Test VM',
            baseClass: 'ObservableObject',
            properties: [
                { name: 'Title', type: 'string', isObservable: false, description: 'Title', defaultValue: '"Drivers"' },
            ],
            commands: [],
            injectedServices: [],
            includeNavigation: false,
            includeValidation: false,
        };
        const { files } = generateCsViewModel(config);
        expect(files[0]!.content).toContain('string Title');
    });
});

describe('generateCsService - additional coverage', () => {
    it('should handle sync methods', () => {
        const config: CsServiceConfig = {
            className: 'SyncService',
            interfaceName: 'ISyncService',
            namespace: 'Test',
            description: 'Sync service',
            methods: [{
                name: 'GetCount',
                returnType: 'int',
                isAsync: false,
                parameters: [],
                description: 'Gets count',
            }],
            injectedServices: [],
            lifetime: 'Transient',
            includeLogging: false,
            includeTests: true,
        };
        const { files } = generateCsService(config);
        const iface = files.find(f => f.relativePath.includes('ISyncService'))!;
        expect(iface.content).toContain('int GetCount()');
    });
});

// ─── Branch coverage boosts ─────────────────────────────────────

describe('generateChangelog - additional branches', () => {
    it('should include deprecated when present', () => {
        const config: ChangelogConfig = {
            ...baseClConfig,
            deprecated: ['Old API removed in next version'],
        };
        const { files } = generateChangelog(config);
        expect(files[0]!.content).toContain('### Deprecated');
        expect(files[0]!.content).toContain('Old API removed');
    });

    it('should include removed when present', () => {
        const config: ChangelogConfig = {
            ...baseClConfig,
            removed: ['Legacy endpoint'],
        };
        const { files } = generateChangelog(config);
        expect(files[0]!.content).toContain('### Removed');
        expect(files[0]!.content).toContain('Legacy endpoint');
    });

    it('should handle all sections empty except added', () => {
        const config: ChangelogConfig = {
            ...baseClConfig,
            changed: [],
            fixed: [],
        };
        const { files } = generateChangelog(config);
        expect(files[0]!.content).toContain('### Added');
        expect(files[0]!.content).not.toContain('### Changed');
        expect(files[0]!.content).not.toContain('### Fixed');
    });
});

describe('generatePsModule - additional branches', () => {
    it('should handle function with no parameters', () => {
        const config: PsModuleConfig = {
            ...basePsConfig,
            functions: [{
                name: 'Get-AllDrivers',
                description: 'Gets all drivers',
                parameters: [],
                returnType: 'PSObject[]',
                supportsShouldProcess: false,
            }],
        };
        const { files } = generatePsModule(config);
        const psm1 = files.find(f => f.relativePath.endsWith('.psm1'))!;
        expect(psm1.content).toContain('function Get-AllDrivers');
    });

    it('should handle parameter without helpMessage', () => {
        const config: PsModuleConfig = {
            ...basePsConfig,
            functions: [{
                name: 'Get-Item',
                description: 'Gets item',
                parameters: [{
                    name: 'Id', type: 'int', mandatory: true, position: 0,
                    helpMessage: '',
                }],
                returnType: 'PSObject',
                supportsShouldProcess: false,
            }],
        };
        const result = generatePsModule(config);
        expect(result.success).toBe(true);
    });
});

describe('generateCsService - additional branches', () => {
    it('should handle service with no logging', () => {
        const config: CsServiceConfig = {
            ...baseSvcConfig,
            includeLogging: false,
        };
        const { files } = generateCsService(config);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'))!;
        expect(impl.content).not.toContain('ILogger');
    });

    it('should use Transient lifetime', () => {
        const config: CsServiceConfig = {
            ...baseSvcConfig,
            lifetime: 'Transient',
        };
        const { files } = generateCsService(config);
        const impl = files.find(f => f.relativePath.endsWith('DriverService.cs') && !f.relativePath.includes('IDriver'))!;
        expect(impl.content).toContain('Transient');
    });

    it('should auto-generate interface name when not provided', () => {
        const config: CsServiceConfig = {
            ...baseSvcConfig,
            interfaceName: '',
        };
        const { files } = generateCsService(config);
        expect(files.some(f => f.relativePath.includes('IDriverService.cs'))).toBe(true);
    });
});
