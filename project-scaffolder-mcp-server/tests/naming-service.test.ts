import { describe, it, expect } from 'vitest';
import {
    splitName, generateNameVariants, validateName,
    toPsVerbNoun, toInterfaceName, toFieldName,
} from '../src/services/name-utils.js';

// ─── splitName ──────────────────────────────────────────────────

describe('splitName', () => {
    it('should split kebab-case', () => {
        expect(splitName('driver-manager')).toEqual(['driver', 'manager']);
    });
    it('should split snake_case', () => {
        expect(splitName('driver_manager')).toEqual(['driver', 'manager']);
    });
    it('should split space-separated', () => {
        expect(splitName('driver manager')).toEqual(['driver', 'manager']);
    });
    it('should split PascalCase', () => {
        expect(splitName('DriverManager')).toEqual(['driver', 'manager']);
    });
    it('should split camelCase', () => {
        expect(splitName('driverManager')).toEqual(['driver', 'manager']);
    });
    it('should handle consecutive uppercase', () => {
        const result = splitName('WMIQuery');
        expect(result.length).toBeGreaterThanOrEqual(2);
    });
    it('should handle single word', () => {
        expect(splitName('driver')).toEqual(['driver']);
    });
    it('should return empty array for empty string', () => {
        expect(splitName('')).toEqual([]);
    });
    it('should return empty array for whitespace-only', () => {
        expect(splitName('   ')).toEqual([]);
    });
    it('should handle mixed separators', () => {
        expect(splitName('my-cool_name')).toEqual(['my', 'cool', 'name']);
    });
    it('should filter empty segments', () => {
        expect(splitName('--foo--bar--')).toEqual(['foo', 'bar']);
    });
});

// ─── generateNameVariants ───────────────────────────────────────

describe('generateNameVariants', () => {
    it('should generate all variants from PascalCase', () => {
        const v = generateNameVariants('DriverManager');
        expect(v.pascal).toBe('DriverManager');
        expect(v.camel).toBe('driverManager');
        expect(v.kebab).toBe('driver-manager');
        expect(v.snake).toBe('driver_manager');
        expect(v.display).toBe('Driver Manager');
    });
    it('should generate variants from kebab-case', () => {
        const v = generateNameVariants('driver-manager');
        expect(v.pascal).toBe('DriverManager');
        expect(v.camel).toBe('driverManager');
        expect(v.kebab).toBe('driver-manager');
        expect(v.snake).toBe('driver_manager');
    });
    it('should generate variants from snake_case', () => {
        const v = generateNameVariants('driver_manager');
        expect(v.pascal).toBe('DriverManager');
        expect(v.kebab).toBe('driver-manager');
    });
    it('should generate variants from space-separated', () => {
        const v = generateNameVariants('driver manager');
        expect(v.pascal).toBe('DriverManager');
    });
    it('should handle single word', () => {
        const v = generateNameVariants('driver');
        expect(v.pascal).toBe('Driver');
        expect(v.camel).toBe('driver');
        expect(v.kebab).toBe('driver');
        expect(v.snake).toBe('driver');
        expect(v.display).toBe('Driver');
    });
    it('should return all empty strings for empty input', () => {
        const v = generateNameVariants('');
        expect(v.pascal).toBe('');
        expect(v.camel).toBe('');
        expect(v.kebab).toBe('');
        expect(v.snake).toBe('');
        expect(v.display).toBe('');
    });
    it('should return all empty strings for whitespace-only', () => {
        const v = generateNameVariants('   ');
        expect(v.pascal).toBe('');
    });
});

// ─── validateName ───────────────────────────────────────────────

describe('validateName', () => {
    describe('general context', () => {
        it('should accept valid names', () => {
            const r = validateName('DriverManager', 'general');
            expect(r.valid).toBe(true);
            expect(r.errors).toHaveLength(0);
            expect(r.variants).not.toBeNull();
        });
        it('should reject empty names', () => {
            const r = validateName('', 'general');
            expect(r.valid).toBe(false);
            expect(r.errors.length).toBeGreaterThan(0);
            expect(r.variants).toBeNull();
        });
        it('should reject whitespace-only names', () => {
            const r = validateName('   ', 'general');
            expect(r.valid).toBe(false);
        });
    });

    describe('csharp context', () => {
        it('should accept valid C# class name', () => {
            const r = validateName('DriverManagerViewModel', 'csharp');
            expect(r.valid).toBe(true);
            expect(r.variants).not.toBeNull();
        });
        it('should reject names starting with digit', () => {
            const r = validateName('1Driver', 'csharp');
            expect(r.valid).toBe(false);
            expect(r.suggestions.length).toBeGreaterThan(0);
        });
    });

    describe('powershell context', () => {
        it('should accept valid PS names', () => {
            const r = validateName('SystemInfo', 'powershell');
            expect(r.valid).toBe(true);
        });
        it('should suggest Verb-Noun format when missing', () => {
            const r = validateName('systeminfo', 'powershell');
            expect(r.suggestions.length).toBeGreaterThan(0);
        });
    });
});

// ─── toPsVerbNoun ───────────────────────────────────────────────

describe('toPsVerbNoun', () => {
    it('should combine verb and noun in PascalCase', () => {
        expect(toPsVerbNoun('get', 'system-info')).toBe('Get-SystemInfo');
    });
    it('should handle already PascalCase inputs', () => {
        expect(toPsVerbNoun('Set', 'Config')).toBe('Set-Config');
    });
    it('should handle multi-word noun', () => {
        expect(toPsVerbNoun('get', 'driver info')).toBe('Get-DriverInfo');
    });
});

// ─── toInterfaceName ────────────────────────────────────────────

describe('toInterfaceName', () => {
    it('should prefix with I', () => {
        expect(toInterfaceName('DriverService')).toBe('IDriverService');
    });
    it('should handle kebab-case input', () => {
        expect(toInterfaceName('driver-service')).toBe('IDriverService');
    });
});

// ─── toFieldName ────────────────────────────────────────────────

describe('toFieldName', () => {
    it('should prefix with underscore and camelCase', () => {
        expect(toFieldName('DriverService')).toBe('_driverService');
    });
    it('should handle kebab-case input', () => {
        expect(toFieldName('driver-service')).toBe('_driverService');
    });
    it('should handle single word', () => {
        expect(toFieldName('logger')).toBe('_logger');
    });
});

// ─── Additional coverage tests ──────────────────────────────────

describe('validateName - additional coverage', () => {
    it('should reject C# reserved keyword "class"', () => {
        const r = validateName('class', 'csharp');
        expect(r.valid).toBe(false);
        expect(r.errors.some(e => e.includes('reserved C# keyword'))).toBe(true);
        expect(r.suggestions.some(s => s.includes('underscore'))).toBe(true);
    });

    it('should reject C# identifier with special characters', () => {
        const r = validateName('my-class!', 'csharp');
        expect(r.valid).toBe(false);
        expect(r.errors.some(e => e.includes('letters, digits, and underscores'))).toBe(true);
    });

    it('should reject PowerShell reserved keyword "break"', () => {
        const r = validateName('break', 'powershell');
        expect(r.valid).toBe(false);
        expect(r.errors.some(e => e.includes('reserved PowerShell keyword'))).toBe(true);
    });

    it('should reject too-short names', () => {
        const r = validateName('a', 'general');
        expect(r.valid).toBe(false);
        expect(r.errors.some(e => e.includes('at least'))).toBe(true);
    });

    it('should reject too-long names', () => {
        const r = validateName('A'.repeat(300), 'general');
        expect(r.valid).toBe(false);
        expect(r.errors.some(e => e.includes('at most'))).toBe(true);
    });
});
