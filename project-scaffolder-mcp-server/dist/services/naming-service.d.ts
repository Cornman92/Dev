/**
 * NamingService — class wrapper around name-utils for DI-friendly usage.
 */
import type { NameVariants, ValidationResult } from '../types.js';
export declare class NamingService {
    split(input: string): string[];
    toVariants(input: string): NameVariants;
    validatePsFunctionName(name: string): ValidationResult;
    validateCsClassName(name: string): ValidationResult;
    validateGeneral(name: string): ValidationResult;
    toPsVerbNoun(verb: string, noun: string): string;
    toInterfaceName(className: string): string;
    toFieldName(name: string): string;
}
//# sourceMappingURL=naming-service.d.ts.map