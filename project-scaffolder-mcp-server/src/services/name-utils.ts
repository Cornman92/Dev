import type { NameVariants, ValidationResult } from '../types.js';
import { RESERVED_CS, RESERVED_PS, MAX_NAME_LENGTH, MIN_NAME_LENGTH } from '../constants.js';

export function splitName(input: string): string[] {
    const trimmed = input.trim();
    if (trimmed.length === 0) return [];
    if (trimmed.includes('-') || trimmed.includes('_')) {
        return trimmed.split(/[-_]+/).filter((w) => w.length > 0).map((w) => w.toLowerCase());
    }
    if (trimmed.includes(' ')) {
        return trimmed.split(/\s+/).filter((w) => w.length > 0).map((w) => w.toLowerCase());
    }
    return trimmed.replace(/([a-z])([A-Z])/g, '$1 $2')
        .replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
        .split(/\s+/).filter((w) => w.length > 0).map((w) => w.toLowerCase());
}

function cap(word: string): string {
    return word.length === 0 ? '' : word.charAt(0).toUpperCase() + word.slice(1);
}

export function generateNameVariants(input: string): NameVariants {
    const words = splitName(input);
    if (words.length === 0) return { pascal: '', camel: '', kebab: '', snake: '', display: '' };
    return {
        pascal: words.map(cap).join(''),
        camel: words[0] + words.slice(1).map(cap).join(''),
        kebab: words.join('-'),
        snake: words.join('_'),
        display: words.map(cap).join(' '),
    };
}

export function validateName(name: string, context: 'csharp' | 'powershell' | 'general'): ValidationResult {
    const errors: string[] = [];
    const suggestions: string[] = [];
    if (!name || name.trim().length === 0) {
        return { valid: false, errors: ['Name cannot be empty'], suggestions: [], variants: null };
    }
    const trimmed = name.trim();
    if (trimmed.length < MIN_NAME_LENGTH) errors.push(`Name must be at least ${MIN_NAME_LENGTH} characters`);
    if (trimmed.length > MAX_NAME_LENGTH) errors.push(`Name must be at most ${MAX_NAME_LENGTH} characters`);
    const variants = generateNameVariants(trimmed);
    if (context === 'csharp') {
        if (RESERVED_CS.has(variants.camel)) {
            errors.push(`"${variants.camel}" is a reserved C# keyword`);
            suggestions.push(`Prefix with underscore: _${variants.camel}`);
        }
        if (/^[0-9]/.test(variants.pascal)) {
            errors.push('C# identifiers cannot start with a digit');
            suggestions.push(`Prefix with a letter: A${variants.pascal}`);
        }
        if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(variants.pascal)) {
            errors.push('C# identifiers may only contain letters, digits, and underscores');
        }
    }
    if (context === 'powershell') {
        if (RESERVED_PS.has(variants.camel.toLowerCase())) {
            errors.push(`"${variants.camel}" is a reserved PowerShell keyword`);
        }
        if (!variants.pascal.includes('-') && !/^[A-Z][a-z]+[A-Z]/.test(variants.pascal)) {
            suggestions.push('PowerShell functions should use Verb-Noun naming (e.g., Get-ModuleConfig)');
        }
    }
    return { valid: errors.length === 0, errors, suggestions, variants };
}

export function toPsVerbNoun(verb: string, noun: string): string {
    return `${generateNameVariants(verb).pascal}-${generateNameVariants(noun).pascal}`;
}

export function toInterfaceName(className: string): string {
    return `I${generateNameVariants(className).pascal}`;
}

export function toFieldName(name: string): string {
    return `_${generateNameVariants(name).camel}`;
}
