import { describe, it, expect } from 'vitest';
import {
    generatePsModule,
    generateCsViewModel,
    generateCsService,
    generateReadme,
    generateChangelog,
    generateFullModule,
} from './template-engine.js';
import type { PsModuleConfig, CsViewModelConfig, CsServiceConfig, ReadmeConfig, ChangelogConfig, FullModuleConfig } from '../types.js';

describe('generatePsModule', () => {
    it('generates PS module with psm1 and optional manifest/tests', () => {
        const config: PsModuleConfig = {
            moduleName: 'TestModule',
            description: 'Test',
            author: 'Test',
            version: '1.0.0',
            functions: [
                {
                    name: 'Get-Test',
                    description: 'Gets test',
                    parameters: [],
                    returnType: 'PSObject',
                    supportsShouldProcess: false,
                },
            ],
            dependencies: [],
            tags: [],
            includeManifest: true,
            includeTests: true,
        };
        const result = generatePsModule(config);
        expect(result.success).toBe(true);
        expect(result.files.length).toBeGreaterThanOrEqual(1);
        expect(result.files.some((f) => f.relativePath.endsWith('.psm1'))).toBe(true);
        expect(result.summary).toContain('TestModule');
    });

    it('prepends Better11 prefix when module name does not have it', () => {
        const config: PsModuleConfig = {
            moduleName: 'MyMod',
            description: 'D',
            author: 'A',
            version: '1.0.0',
            functions: [],
            dependencies: [],
            tags: [],
            includeManifest: false,
            includeTests: false,
        };
        const result = generatePsModule(config);
        expect(result.success).toBe(true);
        expect(result.files[0].relativePath).toContain('Better11.MyMod');
    });
});

describe('generateCsViewModel', () => {
    it('generates ViewModel class file', () => {
        const config: CsViewModelConfig = {
            className: 'Settings',
            namespace: 'Better11.ViewModels',
            description: 'Settings VM',
            baseClass: 'ObservableObject',
            properties: [{ name: 'Title', type: 'string', isObservable: true, description: 'Title' }],
            commands: [],
            injectedServices: [],
            includeNavigation: false,
            includeValidation: false,
        };
        const result = generateCsViewModel(config);
        expect(result.success).toBe(true);
        expect(result.files.length).toBe(1);
        expect(result.files[0].content).toContain('SettingsViewModel');
        expect(result.files[0].content).toContain('ObservableProperty');
    });
});

describe('generateCsService', () => {
    it('generates interface and implementation', () => {
        const config: CsServiceConfig = {
            className: 'Test',
            interfaceName: 'ITestService',
            namespace: 'Better11.Services',
            description: 'Test service',
            methods: [{ name: 'DoWork', returnType: 'void', isAsync: false, parameters: [], description: 'Does work' }],
            injectedServices: [],
            lifetime: 'Singleton',
            includeLogging: false,
            includeTests: false,
        };
        const result = generateCsService(config);
        expect(result.success).toBe(true);
        expect(result.files.some((f) => f.relativePath.includes('ITestService'))).toBe(true);
        expect(result.files.some((f) => f.relativePath.endsWith('TestService.cs'))).toBe(true);
    });
});

describe('generateReadme', () => {
    it('generates README content', () => {
        const config: ReadmeConfig = {
            projectName: 'MyProject',
            description: 'Desc',
            features: ['F1'],
            prerequisites: ['P1'],
            installSteps: ['Step 1'],
            usageExamples: ['example'],
            author: 'Author',
            license: 'MIT',
            badges: [{ label: 'v', value: '1.0', color: 'blue' }],
        };
        const result = generateReadme(config);
        expect(result.success).toBe(true);
        expect(result.files[0].relativePath).toBe('README.md');
        expect(result.files[0].content).toContain('MyProject');
        expect(result.files[0].content).toContain('Desc');
    });
});

describe('generateChangelog', () => {
    it('generates CHANGELOG with sections', () => {
        const config: ChangelogConfig = {
            projectName: 'Proj',
            version: '1.0.0',
            date: '2025-01-01',
            added: ['Feature A'],
            changed: [],
            fixed: [],
            removed: [],
            deprecated: [],
        };
        const result = generateChangelog(config);
        expect(result.success).toBe(true);
        expect(result.files[0].content).toContain('### Added');
        expect(result.files[0].content).toContain('Feature A');
    });
});

describe('generateFullModule', () => {
    it('combines PS module, ViewModel, Service, README, CHANGELOG when configured', () => {
        const config: FullModuleConfig = {
            moduleName: 'FullMod',
            description: 'Full module',
            author: 'Author',
            version: '1.0.0',
            psModule: {
                functions: [{ name: 'Get-Full', description: 'Get', parameters: [], returnType: 'PSObject', supportsShouldProcess: false }],
                includeManifest: true,
                includeTests: false,
            },
            csViewModel: { className: 'FullVm', namespace: 'Better11.ViewModels', description: 'VM', baseClass: 'ObservableObject', properties: [], commands: [], injectedServices: [], includeNavigation: false, includeValidation: false },
            csService: { className: 'FullSvc', namespace: 'Better11.Services', description: 'Svc', methods: [], injectedServices: [], includeTests: false },
            includeReadme: true,
            includeChangelog: true,
        };
        const result = generateFullModule(config);
        expect(result.success).toBe(true);
        expect(result.files.length).toBeGreaterThan(1);
        expect(result.summary).toContain('FullMod');
    });
});
