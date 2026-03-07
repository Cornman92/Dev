import { describe, it, expect } from 'vitest';
import { NamingService } from '../src/services/naming-service.js';

describe('NamingService', () => {
    const svc = new NamingService();

    describe('split', () => {
        it('should delegate to splitName', () => {
            expect(svc.split('driver-manager')).toEqual(['driver', 'manager']);
        });
        it('should handle empty string', () => {
            expect(svc.split('')).toEqual([]);
        });
    });

    describe('toVariants', () => {
        it('should generate all casing variants', () => {
            const v = svc.toVariants('driver-manager');
            expect(v.pascal).toBe('DriverManager');
            expect(v.camel).toBe('driverManager');
            expect(v.kebab).toBe('driver-manager');
            expect(v.snake).toBe('driver_manager');
            expect(v.display).toBe('Driver Manager');
        });
    });

    describe('validatePsFunctionName', () => {
        it('should validate valid PS name', () => {
            const r = svc.validatePsFunctionName('GetSystemInfo');
            expect(r.valid).toBe(true);
        });
        it('should reject reserved PS keyword', () => {
            const r = svc.validatePsFunctionName('break');
            expect(r.valid).toBe(false);
        });
    });

    describe('validateCsClassName', () => {
        it('should validate valid C# name', () => {
            const r = svc.validateCsClassName('DriverManager');
            expect(r.valid).toBe(true);
        });
        it('should reject reserved C# keyword', () => {
            const r = svc.validateCsClassName('class');
            expect(r.valid).toBe(false);
        });
    });

    describe('validateGeneral', () => {
        it('should validate general names', () => {
            const r = svc.validateGeneral('MyModule');
            expect(r.valid).toBe(true);
        });
        it('should reject empty', () => {
            const r = svc.validateGeneral('');
            expect(r.valid).toBe(false);
        });
    });

    describe('toPsVerbNoun', () => {
        it('should format Verb-Noun', () => {
            expect(svc.toPsVerbNoun('get', 'system-info')).toBe('Get-SystemInfo');
        });
    });

    describe('toInterfaceName', () => {
        it('should prefix with I', () => {
            expect(svc.toInterfaceName('DriverService')).toBe('IDriverService');
        });
    });

    describe('toFieldName', () => {
        it('should prefix with underscore and camelCase', () => {
            expect(svc.toFieldName('DriverService')).toBe('_driverService');
        });
    });
});
