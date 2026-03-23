# Contributing to Dev Workspace

Thank you for your interest in contributing! This guide will help you get started.

## Getting Started

1. **Set up your environment**
   - Run `.\Scripts\Setup-DevEnvironment.ps1` to install required tools
   - Run `.\Scripts\Test-DevEnvironment.ps1` to validate setup
   - See [Setup Guide](guides/setup.md) for detailed instructions

2. **Fork and clone**
   - Fork the repository
   - Clone your fork locally
   - Set up the upstream remote

3. **Create a branch**
   ```powershell
   git checkout -b feature/your-feature-name
   ```

## Development Guidelines

### Code Style

- **PowerShell**: Follow PSScriptAnalyzer rules, use approved verbs
- **C#**: Follow .NET coding conventions
- **JavaScript**: Follow ESLint rules (if configured)
- **Python**: Follow PEP 8

### Testing

- Write tests for new functionality
- Ensure all tests pass before submitting
- Aim for 80%+ code coverage
- Run `.\Scripts\Test-AllProjects.ps1` to test everything

### Documentation

- Update README files when adding features
- Add code comments for complex logic
- Follow [Documentation Standards](standards/documentation.md)
- Update API documentation for API changes

## Submitting Changes

1. **Commit your changes**
   - Use clear, descriptive commit messages
   - Follow conventional commit format when possible
   - Make atomic commits (one logical change per commit)

2. **Push to your fork**
   ```powershell
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Provide a clear description
   - Reference related issues
   - Include screenshots for UI changes
   - Ensure CI checks pass

## Pull Request Process

1. **Review checklist**
   - [ ] Code follows style guidelines
   - [ ] Tests pass locally
   - [ ] Documentation updated
   - [ ] No breaking changes (or documented)

2. **Review process**
   - Maintainers will review your PR
   - Address feedback promptly
   - Keep PRs focused and reasonably sized

3. **Merge**
   - PRs are merged after approval
   - Squash and merge is preferred
   - Your contribution will be credited

## Project-Specific Guidelines

### PowerShell Modules
- Include comment-based help for all public functions
- Add examples in help comments
- Follow module structure standards

### .NET Projects
- Include XML documentation comments
- Follow MVVM pattern for UI projects
- Write unit tests for services

### Node.js Projects
- Include JSDoc comments
- Follow async/await patterns
- Write integration tests

## Reporting Issues

- Use GitHub Issues
- Provide clear description
- Include steps to reproduce
- Add relevant logs or screenshots

## Getting Help

- Check existing documentation
- Search closed issues
- Ask in discussions
- Contact maintainers

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

*Thank you for contributing!*
