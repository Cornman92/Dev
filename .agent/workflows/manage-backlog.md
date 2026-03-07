---
description: Manage and prioritize the feature backlog
---

# Manage Feature Backlog

This workflow helps you organize, prioritize, and maintain your feature backlog.

## Steps

### 1. Review Current Backlog
Open and review `docs/FEATURE-BACKLOG.md` to see all planned features.

### 2. Prioritize Features
Consider these factors when prioritizing:
- **Business Value**: How much impact will this have?
- **User Need**: How urgently do users need this?
- **Technical Debt**: Does this reduce or increase technical debt?
- **Dependencies**: What needs to be done first?
- **Effort**: How much time will this take?
- **Risk**: What's the risk of building (or not building) this?

Use the MoSCoW method:
- **Must Have**: Critical for success
- **Should Have**: Important but not critical
- **Could Have**: Nice to have if time permits
- **Won't Have**: Not planned for this sprint

### 3. Update Feature Status
Update the status emoji in the backlog:
- 🔵 Planned
- 🟡 In Progress
- 🟢 Completed
- 🔴 Blocked
- ⚪ On Hold

### 4. Sprint Planning
Select features for the next sprint:
- Review team capacity
- Choose features that fit within sprint timeline
- Ensure dependencies are met
- Balance quick wins with larger initiatives
- Move selected features to "Current Sprint" section

### 5. Groom New Feature Ideas
For features in the "Icebox":
- Refine the idea into a proper feature document
- Create feature document using `/create-feature` workflow
- Add to appropriate priority section in backlog
- Remove from icebox

### 6. Archive Completed Work
Periodically (monthly or quarterly):
- Move old completed features to an archive document
- Keep backlog focused on current and upcoming work
- Document lessons learned

### 7. Stakeholder Communication
Share backlog updates with stakeholders:
- What's completed
- What's in progress
- What's coming next
- Any blockers or risks

## Best Practices

- **Review Weekly**: Keep backlog fresh and relevant
- **Limit WIP**: Don't start too many features at once (recommend 2-3 max)
- **Be Ruthless**: Remove features that no longer make sense
- **Get Feedback**: Involve team in prioritization
- **Stay Flexible**: Priorities change, and that's okay
- **Celebrate Wins**: Acknowledge completed features

## Quick Commands

View the backlog:
```bash
cat docs/FEATURE-BACKLOG.md
```

List all feature documents:
```bash
ls docs/features/
```

Search for a specific feature:
```bash
grep -r "feature-name" docs/features/
```
