export const SERVER_NAME = 'project-scaffolder-mcp-server';
export const SERVER_VERSION = '1.0.0';
export const DEFAULT_AUTHOR = 'C-Man';
export const DEFAULT_LICENSE = 'MIT';
export const DEFAULT_VERSION = '1.0.0';
export const BETTER11_NS = 'Better11';
export const BETTER11_PREFIX = 'Better11';
export const MAX_NAME_LENGTH = 128;
export const MIN_NAME_LENGTH = 2;

export const CS_BASES = {
    viewModel: 'ObservableObject',
    service: 'object',
    navigation: 'NavigableViewModel',
} as const;

export const RESERVED_CS = new Set([
    'abstract','as','base','bool','break','byte','case','catch','char','checked',
    'class','const','continue','decimal','default','delegate','do','double',
    'else','enum','event','explicit','extern','false','finally','fixed','float',
    'for','foreach','goto','if','implicit','in','int','interface','internal',
    'is','lock','long','namespace','new','null','object','operator','out',
    'override','params','private','protected','public','readonly','ref','return',
    'sbyte','sealed','short','sizeof','stackalloc','static','string','struct',
    'switch','this','throw','true','try','typeof','uint','ulong','unchecked',
    'unsafe','ushort','using','virtual','void','volatile','while',
]);

export const RESERVED_PS = new Set([
    'begin','break','catch','class','continue','data','define','do',
    'dynamicparam','else','elseif','end','enum','exit','filter','finally',
    'for','foreach','from','function','if','in','param','process','return',
    'switch','throw','trap','try','until','using','var','while',
]);

export const TEMPLATE_CATS = ['powershell','csharp-viewmodel','csharp-service','documentation','composite'] as const;
