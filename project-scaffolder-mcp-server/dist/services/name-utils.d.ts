import type { NameVariants, ValidationResult } from '../types.js';
export declare function splitName(input: string): string[];
export declare function generateNameVariants(input: string): NameVariants;
export declare function validateName(name: string, context: 'csharp' | 'powershell' | 'general'): ValidationResult;
export declare function toPsVerbNoun(verb: string, noun: string): string;
export declare function toInterfaceName(className: string): string;
export declare function toFieldName(name: string): string;
//# sourceMappingURL=name-utils.d.ts.map