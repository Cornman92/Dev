---
description: Quick workflow to create a new feature from scratch
---

# Create New Feature

This workflow helps you quickly scaffold a new feature with all necessary documentation and structure.

## Steps

### 1. Define Feature Name
Choose a clear, descriptive name for your feature using kebab-case (e.g., `user-authentication`, `dark-mode-toggle`)

// turbo
### 2. Create Feature Branch
```bash
git checkout -b feature/[feature-name]
```

### 3. Create Feature Document
Create a planning document at `docs/features/[feature-name].md` with the following template:

```markdown
# Feature: [Feature Name]

## Overview
Brief description of what this feature does and why it's needed.

## User Stories
- As a [user type], I want to [action] so that [benefit]
- As a [user type], I want to [action] so that [benefit]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Approach
Describe the technical implementation approach, including:
- Architecture changes
- New components/modules needed
- Database changes (if applicable)
- API changes (if applicable)

## Dependencies
List any dependencies on other features, libraries, or systems.

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Timeline
Estimated: [X days/hours]
Actual: [To be filled upon completion]

## Testing Plan
- Unit tests for [components]
- Integration tests for [workflows]
- Manual testing steps

## Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High/Medium/Low | How to mitigate |

## Notes
Additional notes, decisions, or context.
```

### 4. Start Development
Follow the feature sprint workflow for implementation.

## Quick Start Command
To create everything at once, you can ask the AI assistant to:
1. Create the feature branch
2. Generate the feature document with your specific requirements
3. Set up any necessary file structure
