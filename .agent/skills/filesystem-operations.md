# Filesystem Operations Skill

## Overview
Advanced file and directory management capabilities using the MCP filesystem server.

## Capabilities

### File Operations
- **Read files**: Access any file content within the configured workspace
- **Write files**: Create and modify files with proper permissions
- **Delete files**: Remove files safely with confirmation
- **File metadata**: Access file size, modification time, permissions

### Directory Operations
- **List directories**: Browse directory contents with detailed information
- **Create directories**: Make new directory structures
- **Delete directories**: Remove empty or non-empty directories
- **Directory traversal**: Navigate through complex folder hierarchies

### Search Operations
- **File search**: Find files by name, pattern, or content
- **Recursive search**: Search through entire directory trees
- **Filter search**: Filter by file type, size, or date

## Usage Examples

### Basic File Operations
```bash
# Read a configuration file
read_file /path/to/config.json

# Write a new script
write_to_file /path/to/script.py "print('Hello World')"

# List directory contents
list_dir /path/to/directory
```

### Search Operations
```bash
# Find all Python files
find_by_name /path/to/project "*.py"

# Search for specific content
grep_search /path/to/project "function.*debug"
```

## Best Practices
- Always verify file paths before operations
- Use absolute paths for reliability
- Check file permissions before attempting writes
- Implement proper error handling for file operations

## Configuration
- **Workspace path**: `c:\Users\saymo\OneDrive\Dev`
- **Access level**: Full read/write within workspace
- **Security**: Restricted to configured directory only

## Integration
Works seamlessly with other MCP servers for:
- Code analysis with Git server
- Documentation generation
- Project automation
- Build system integration
