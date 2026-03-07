import { describe, it, expect } from 'vitest';
import { NamingService } from './naming-service.js';

describe('NamingService', () => {
    const service = new NamingService();

    describe('split', () => {
        it('delegates to splitName', () => {
            expect(service.split('foo-bar')).toEqual(['foo', 'bar']);
        });
    });

    describe('toVariants', () => {
        it('delegates to generateNameVariants', () => {
            expect(service.toVariants('get-module')).toEqual({
                pascal: 'GetModule',
                camel: 'getModule',
                kebab: 'get-module',
                snake: 'get_module',
                display: 'Get Module',
            });
        });
    });

    describe('validatePsFunctionName', () => {
        it('validates PowerShell context', () => {
            const r = service.validatePsFunctionName('Get-Config');
            expect(r).toHaveProperty('valid');
            expect(r).toHaveProperty('variants');
        });
    });

    describe('validateCsClassName', () => {
        it('validates C# context', () => {
            const r = service.validateCsClassName('MyViewModel');
            expect(r.valid).toBe(true);
        });
    });

    describe('validateGeneral', () => {
        it('validates general context', () => {
            const r = service.validateGeneral('ValidName');
            expect(r.valid).toBe(true);
        });
    });

    describe('toPsVerbNoun', () => {
        it('formats verb-noun', () => {
            expect(service.toPsVerbNoun('Get', 'Item')).toBe('Get-Item');
        });
    });

    describe('toInterfaceName', () => {
        it('returns interface name', () => {
            expect(service.toInterfaceName('MyService')).toBe('IMyService');
        });
    });

    describe('toFieldName', () => {
        it('returns private field name', () => {
            expect(service.toFieldName('logger')).toBe('_logger');
        });
    });
});
