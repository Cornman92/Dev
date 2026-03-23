import { describe, it, expect } from 'vitest';
import {
    splitName,
    generateNameVariants,
    validateName,
    toPsVerbNoun,
    toInterfaceName,
    toFieldName,
} from './name-utils.js';

describe('splitName', () => {
    it('returns empty array for empty or whitespace-only input', () => {
        expect(splitName('')).toEqual([]);
        expect(splitName('   ')).toEqual([]);
    });

    it('splits on hyphens and normalizes to lowercase', () => {
        expect(splitName('foo-bar')).toEqual(['foo', 'bar']);
        expect(splitName('Get-ModuleConfig')).toEqual(['get', 'moduleconfig']);
    });

    it('splits on underscores', () => {
        expect(splitName('foo_bar_baz')).toEqual(['foo', 'bar', 'baz']);
    });

    it('splits on spaces', () => {
        expect(splitName('foo bar')).toEqual(['foo', 'bar']);
    });

    it('splits PascalCase into words', () => {
        expect(splitName('ModuleConfig')).toEqual(['module', 'config']);
        expect(splitName('GetModuleConfig')).toEqual(['get', 'module', 'config']);
    });

    it('trims input before processing', () => {
        expect(splitName('  foo-bar  ')).toEqual(['foo', 'bar']);
    });
});

describe('generateNameVariants', () => {
    it('returns empty variants for empty input', () => {
        expect(generateNameVariants('')).toEqual({
            pascal: '',
            camel: '',
            kebab: '',
            snake: '',
            display: '',
        });
    });

    it('generates correct variants for single word', () => {
        expect(generateNameVariants('foo')).toEqual({
            pascal: 'Foo',
            camel: 'foo',
            kebab: 'foo',
            snake: 'foo',
            display: 'Foo',
        });
    });

    it('generates correct variants for multiple words', () => {
        expect(generateNameVariants('get-module-config')).toEqual({
            pascal: 'GetModuleConfig',
            camel: 'getModuleConfig',
            kebab: 'get-module-config',
            snake: 'get_module_config',
            display: 'Get Module Config',
        });
    });

    it('handles PascalCase input', () => {
        expect(generateNameVariants('ModuleConfig').pascal).toBe('ModuleConfig');
        expect(generateNameVariants('ModuleConfig').camel).toBe('moduleConfig');
    });
});

describe('validateName', () => {
    it('rejects empty name', () => {
        const r = validateName('', 'general');
        expect(r.valid).toBe(false);
        expect(r.errors).toContain('Name cannot be empty');
    });

    it('rejects name shorter than MIN_NAME_LENGTH', () => {
        const r = validateName('a', 'general');
        expect(r.valid).toBe(false);
        expect(r.errors.some((e) => e.includes('at least'))).toBe(true);
    });

    it('accepts valid general name', () => {
        const r = validateName('MyModule', 'general');
        expect(r.valid).toBe(true);
        expect(r.variants).not.toBeNull();
    });

    it('rejects C# reserved keyword', () => {
        const r = validateName('class', 'csharp');
        expect(r.valid).toBe(false);
        expect(r.errors.some((e) => e.includes('reserved'))).toBe(true);
    });

    it('rejects C# identifier starting with digit', () => {
        const r = validateName('2foo', 'csharp');
        expect(r.valid).toBe(false);
        expect(r.errors.some((e) => e.includes('digit'))).toBe(true);
    });

    it('rejects PowerShell reserved keyword', () => {
        const r = validateName('function', 'powershell');
        expect(r.valid).toBe(false);
        expect(r.errors.some((e) => e.includes('reserved'))).toBe(true);
    });
});

describe('toPsVerbNoun', () => {
    it('formats Verb-Noun correctly', () => {
        expect(toPsVerbNoun('get', 'module')).toBe('Get-Module');
        expect(toPsVerbNoun('Set', 'Item')).toBe('Set-Item');
    });
});

describe('toInterfaceName', () => {
    it('prepends I and uses PascalCase', () => {
        expect(toInterfaceName('moduleConfig')).toBe('IModuleConfig');
        expect(toInterfaceName('service')).toBe('IService');
    });
});

describe('toFieldName', () => {
    it('prepends underscore and uses camelCase', () => {
        expect(toFieldName('logger')).toBe('_logger');
        expect(toFieldName('ModuleConfig')).toBe('_moduleConfig');
    });
});
