# Global Claude Instructions

## Feature Tracking

For any significant change, create and maintain a feature file at `~/.claude/features/<kebab-name>/story.md` before starting work. Update checkpoints as each stage completes. Use feature files to resume context across sessions.

Use `/feature-plan <description>` to kick off the feature creation flow — Claude will draft a user story for approval before creating any files.

### Format

```md
# Story: <Name>

**As a** [user type], **I want** [goal] **so that** [reason]

## Status: todo | in-progress | done

## Checkpoints
- [ ] Plan drafted
- [ ] Plan reviewed
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Code reviewed
- [ ] Committed

## Notes
```

### When to create a feature

- Any change spanning multiple sessions
- Refactors or architectural changes
- New features or tools being added

### Feature lifecycle

- Active features live in `~/.claude/features/<name>/`
- Completed features move to `~/.claude/features/done/<name>/`
- All related md files for a feature go in its folder

### Work repos

When working inside a `/work/` directory, related repositories live in `~/Developer/work/`. Scan that directory to identify which repos are relevant to a given task or feature.

---

## Auto-Review Markers

After presenting a complete implementation plan, end your response with `<!-- review:plan -->`.

After finishing a complete implementation, end your response with `<!-- review:code -->`.

These markers are detected by a Stop hook that automatically triggers the appropriate review skill.
