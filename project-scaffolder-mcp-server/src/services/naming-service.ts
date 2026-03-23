/**
 * NamingService — class wrapper around name-utils for DI-friendly usage.
 */

import type { NameVariants, ValidationResult } from '../types.js';
import {
    splitName, generateNameVariants, validateName,
    toPsVerbNoun, toInterfaceName, toFieldName,
} from './name-utils.js';

export class NamingService {

    split(input: string): string[] {
        return splitName(input);
    }

    toVariants(input: string): NameVariants {
        return generateNameVariants(input);
    }

    validatePsFunctionName(name: string): ValidationResult {
        return validateName(name, 'powershell');
    }

    validateCsClassName(name: string): ValidationResult {
        return validateName(name, 'csharp');
    }

    validateGeneral(name: string): ValidationResult {
        return validateName(name, 'general');
    }

    toPsVerbNoun(verb: string, noun: string): string {
        return toPsVerbNoun(verb, noun);
    }

    toInterfaceName(className: string): string {
        return toInterfaceName(className);
    }

    toFieldName(name: string): string {
        return toFieldName(name);
    }
}
