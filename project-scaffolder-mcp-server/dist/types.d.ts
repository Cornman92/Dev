export interface NameVariants {
    readonly pascal: string;
    readonly camel: string;
    readonly kebab: string;
    readonly snake: string;
    readonly display: string;
}
export interface TemplateInfo {
    readonly id: string;
    readonly name: string;
    readonly description: string;
    readonly category: string;
    readonly files: readonly string[];
    readonly requiredParams: readonly string[];
    readonly optionalParams: readonly string[];
}
export interface PsFunctionConfig {
    readonly name: string;
    readonly description: string;
    readonly parameters: readonly PsParamConfig[];
    readonly returnType: string;
    readonly supportsShouldProcess: boolean;
}
export interface PsParamConfig {
    readonly name: string;
    readonly type: string;
    readonly mandatory: boolean;
    readonly position: number;
    readonly helpMessage: string;
    readonly validateSet?: readonly string[];
    readonly defaultValue?: string;
}
export interface PsModuleConfig {
    readonly moduleName: string;
    readonly description: string;
    readonly author: string;
    readonly version: string;
    readonly functions: readonly PsFunctionConfig[];
    readonly dependencies: readonly string[];
    readonly tags: readonly string[];
    readonly includeManifest: boolean;
    readonly includeTests: boolean;
}
export interface CsPropertyConfig {
    readonly name: string;
    readonly type: string;
    readonly defaultValue?: string;
    readonly isObservable: boolean;
    readonly description: string;
}
export interface CsCommandConfig {
    readonly name: string;
    readonly description: string;
    readonly isAsync: boolean;
    readonly canExecuteProperty?: string;
    readonly parameterType?: string;
}
export interface CsServiceRef {
    readonly interfaceName: string;
    readonly fieldName: string;
}
export interface CsViewModelConfig {
    readonly className: string;
    readonly namespace: string;
    readonly description: string;
    readonly baseClass: string;
    readonly properties: readonly CsPropertyConfig[];
    readonly commands: readonly CsCommandConfig[];
    readonly injectedServices: readonly CsServiceRef[];
    readonly includeNavigation: boolean;
    readonly includeValidation: boolean;
}
export interface CsMethodParam {
    readonly name: string;
    readonly type: string;
    readonly defaultValue?: string;
}
export interface CsMethodConfig {
    readonly name: string;
    readonly returnType: string;
    readonly isAsync: boolean;
    readonly parameters: readonly CsMethodParam[];
    readonly description: string;
}
export interface CsServiceConfig {
    readonly className: string;
    readonly interfaceName: string;
    readonly namespace: string;
    readonly description: string;
    readonly methods: readonly CsMethodConfig[];
    readonly injectedServices: readonly CsServiceRef[];
    readonly lifetime: 'Singleton' | 'Scoped' | 'Transient';
    readonly includeLogging: boolean;
    readonly includeTests: boolean;
}
export interface ReadmeConfig {
    readonly projectName: string;
    readonly description: string;
    readonly features: readonly string[];
    readonly prerequisites: readonly string[];
    readonly installSteps: readonly string[];
    readonly usageExamples: readonly string[];
    readonly author: string;
    readonly license: string;
    readonly badges: readonly BadgeConfig[];
}
export interface BadgeConfig {
    readonly label: string;
    readonly value: string;
    readonly color: string;
}
export interface ChangelogConfig {
    readonly projectName: string;
    readonly version: string;
    readonly date: string;
    readonly added: readonly string[];
    readonly changed: readonly string[];
    readonly fixed: readonly string[];
    readonly removed: readonly string[];
    readonly deprecated: readonly string[];
}
export interface FullModuleConfig {
    readonly moduleName: string;
    readonly description: string;
    readonly author: string;
    readonly version: string;
    readonly psModule: Partial<PsModuleConfig>;
    readonly csViewModel: Partial<CsViewModelConfig>;
    readonly csService: Partial<CsServiceConfig>;
    readonly includeReadme: boolean;
    readonly includeChangelog: boolean;
}
export interface GeneratedFile {
    readonly relativePath: string;
    readonly content: string;
    readonly language: string;
}
export interface ScaffoldResult {
    readonly success: boolean;
    readonly files: readonly GeneratedFile[];
    readonly summary: string;
    readonly errors: readonly string[];
}
export interface ValidationResult {
    readonly valid: boolean;
    readonly suggestions: readonly string[];
    readonly errors: readonly string[];
    readonly variants: NameVariants | null;
}
//# sourceMappingURL=types.d.ts.map