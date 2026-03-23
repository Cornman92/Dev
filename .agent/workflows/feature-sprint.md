---
description: How to run a feature sprint - plan, develop, and deploy new features
---

# Feature Sprint Workflow

This workflow guides you through planning, developing, testing, and deploying new features in a structured sprint cycle.

## Prerequisites
- Clear feature requirements and acceptance criteria
- Development environment set up
- Access to version control (git)

## Steps

### 1. Sprint Planning & Setup
Create a feature branch for your work:
```bash
git checkout -b feature/[feature-name]
```

Create a feature planning document:
```bash
mkdir -p docs/features
```

Document your feature requirements in `docs/features/[feature-name].md` including:
- Feature description and goals
- User stories
- Acceptance criteria
- Technical approach
- Dependencies
- Timeline estimates

### 2. Design Phase
Review and create necessary design assets:
- UI/UX mockups (if applicable)
- Architecture diagrams
- Database schema changes
- API contracts

### 3. Development
Break down the feature into smaller tasks:
- Create task list in your feature document
- Implement core functionality
- Write unit tests for new code
- Update integration tests as needed

// turbo
### 4. Code Quality Checks
Run linting and formatting:
```bash
git add .
git status
```

### 5. Testing
Run your test suite:
- Unit tests
- Integration tests
- Manual testing of the feature
- Cross-browser/platform testing (if applicable)

### 6. Documentation
Update relevant documentation:
- README.md (if feature affects setup/usage)
- API documentation
- User guides
- Changelog

### 7. Code Review
Prepare for code review:
```bash
git add .
git commit -m "feat: [feature-name] - [brief description]"
git push origin feature/[feature-name]
```

Create a pull request with:
- Feature description
- Testing instructions
- Screenshots/demos (if applicable)
- Breaking changes (if any)

### 8. Deployment
After approval:
- Merge to main branch
- Deploy to staging environment
- Verify in staging
- Deploy to production
- Monitor for issues

### 9. Sprint Retrospective
Document learnings:
- What went well
- What could be improved
- Action items for next sprint
- Update estimates based on actual time spent

## Notes
- Use conventional commit messages (feat:, fix:, docs:, etc.)
- Keep features small and focused
- Deploy frequently to get feedback quickly
- Don't forget to celebrate completed features! 🎉
