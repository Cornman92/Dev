# Git Operations Skill

## Overview
Comprehensive Git repository management using the MCP Git server for version control operations.

## Capabilities

### Repository Management
- **Status checking**: View current repository status and changes
- **Commit operations**: Create, view, and manage commits
- **Branch management**: Create, switch, merge, and delete branches
- **Remote operations**: Push, pull, fetch from remote repositories

### History and Analysis
- **Log viewing**: Browse commit history with detailed information
- **Diff operations**: Compare files, commits, and branches
- **Blame tracking**: Track line-by-line file history
- **Statistics**: Repository statistics and contribution analysis

### Advanced Operations
- **Stash management**: Temporarily save and restore changes
- **Tag operations**: Create and manage version tags
- **Submodule handling**: Manage Git submodules
- **Conflict resolution**: Assist with merge conflicts

## Usage Examples

### Basic Operations
```bash
# Check repository status
git status

# View commit history
git log --oneline -10

# Create a new branch
git checkout -b feature/new-feature

# Stage and commit changes
git add .
git commit -m "Add new feature"
```

### Advanced Operations
```bash
# View file changes
git diff HEAD~1 HEAD

# Merge branches
git merge feature/branch

# Resolve conflicts
git mergetool

# Create a tag
git tag v1.0.0
```

## Best Practices
- Commit frequently with descriptive messages
- Use feature branches for development
- Pull before pushing to avoid conflicts
- Regularly check repository status
- Use .gitignore effectively

## Integration
Works with other MCP servers for:
- **Filesystem**: File staging and commit operations
- **GitHub**: Enhanced repository management
- **Memory**: Storing commit patterns and workflows

## Configuration
- **Repository**: Auto-detects Git repositories
- **Authentication**: Uses system Git credentials
- **Scope**: Full repository access within workspace

## Workflows
- **Feature development**: Branch → Develop → Test → Merge
- **Hotfix process**: Create hotfix branch → Fix → Tag → Merge
- **Release management**: Version tagging and release preparation
