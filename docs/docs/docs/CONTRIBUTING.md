# Contributing to PowerShell Modules

Thank you for your interest in contributing! Here's how you can help
improve these PowerShell modules.

## Getting Started

1. Fork the repository

2. Clone your fork locally

3. Create a feature branch: `git checkout -b feature/your-feature-name `4.
Make your changes

4. Test your changes thoroughly

5. Commit your changes:`git commit -m 'Add some feature'`7. Push to the
  branch:`git push origin feature/your-feature-name`8. Open a Pull Request

## Coding Standards

- Follow the [PowerShell Best Practices and Style
- Guide](<https://poshcode.gitbooks.io/powershell-practice-and-style>/)

- Use [PSScriptAnalyzer](<https://github.com/PowerShell/PSScriptAnalyzer>)
- to check your code

- Write clear, concise commit messages

- Include comment-based help for all functions

- Add Pester tests for new functionality

## Testing

1. Run PSScriptAnalyzer:

  ```powershell
   Invoke-ScriptAnalyzer -Path .\Modules\ -Recurse -Severity @('Error', 'Warning')
   ```text

1. Run Pester tests:

   ```powershell
   Invoke-Pester -Path .\Tests\
   ```text

## Pull Request Process

1. Ensure your code passes all tests

2. Update the README.md with details of changes if needed

3. Update the CHANGELOG.md with your changes

4. The PR will be reviewed and merged once approved

## Reporting Issues

When reporting issues, please include:

- PowerShell version

- Module version

- Steps to reproduce

- Expected behavior

- Actual behavior

- Any error messages
