/**
 * NamingService — class wrapper around name-utils for DI-friendly usage.
 */
import { splitName, generateNameVariants, validateName, toPsVerbNoun, toInterfaceName, toFieldName, } from './name-utils.js';
export class NamingService {
    split(input) {
        return splitName(input);
    }
    toVariants(input) {
        return generateNameVariants(input);
    }
    validatePsFunctionName(name) {
        return validateName(name, 'powershell');
    }
    validateCsClassName(name) {
        return validateName(name, 'csharp');
    }
    validateGeneral(name) {
        return validateName(name, 'general');
    }
    toPsVerbNoun(verb, noun) {
        return toPsVerbNoun(verb, noun);
    }
    toInterfaceName(className) {
        return toInterfaceName(className);
    }
    toFieldName(name) {
        return toFieldName(name);
    }
}
//# sourceMappingURL=naming-service.js.map