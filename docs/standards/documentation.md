# Documentation Standards

> Last Updated: 2025-01-20  
> Purpose: Define standards and guidelines for all documentation in the Dev workspace

## Documentation Principles

1. **Clarity**: Write clearly and concisely
2. **Completeness**: Cover all necessary information
3. **Consistency**: Follow standard formats and structures
4. **Currency**: Keep documentation up to date
5. **Accessibility**: Make documentation easy to find and navigate

## Documentation Types

### Project README Files

Every project must have a README.md with the following structure:

```markdown
# Project Name

> **Status:** [Production Ready | Active Development | Planning Phase]

## Description

Brief description of what the project does and its purpose.

## Requirements

- Requirement 1
- Requirement 2

## Installation

Installation instructions here.

## Usage

Basic usage examples.

## Features

- Feature 1
- Feature 2

## Documentation

Links to additional documentation.

## License

License information.
```

### API Documentation

API documentation should include:
- Endpoint descriptions
- Request/response examples
- Parameter descriptions
- Error codes and handling
- Authentication requirements

### Code Documentation

- **PowerShell**: Comment-based help for all public functions
- **C#**: XML documentation comments
- **JavaScript/TypeScript**: JSDoc comments
- **Python**: Docstrings

## Markdown Standards

### Headers

- Use `#` for main title (H1) - only one per document
- Use `##` for major sections (H2)
- Use `###` for subsections (H3)
- Don't skip header levels

### Code Blocks

- Always specify language: ` ```powershell `, ` ```csharp `, etc.
- Include context and comments in code examples
- Show expected output when relevant

### Links

- Use descriptive link text
- Prefer relative paths for internal links
- Use absolute URLs for external links

### Lists

- Use `-` for unordered lists
- Use `1.` for ordered lists
- Indent nested lists with 2 spaces

## File Naming

- Use `README.md` for main project documentation
- Use `CHANGELOG.md` for version history
- Use `CONTRIBUTING.md` for contribution guidelines
- Use `LICENSE` or `LICENSE.md` for license information
- Use descriptive names for other docs: `API.md`, `ARCHITECTURE.md`, etc.

## Documentation Location

- **Project-specific**: `[ProjectName]/README.md` and `docs/projects/[ProjectName]/`
- **Workspace-wide**: `docs/` directory
- **Guides**: `docs/guides/`
- **Standards**: `docs/standards/`

## Review and Maintenance

- Review documentation with code changes
- Update documentation when APIs change
- Remove outdated information
- Add examples for common use cases

## Tools

- **Markdown Linting**: Use markdownlint-cli
- **Link Checking**: Use markdown-link-check
- **Spell Checking**: Use cspell or similar
- **Formatting**: Use Prettier or similar

---

*See `docs/templates/` for documentation templates*
