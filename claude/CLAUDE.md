# Global Claude Instructions

## Task Tracking

For any significant change, create and maintain a task file at `~/.claude/tasks/<kebab-name>.md` before starting work. Update checkpoints as each stage completes. Use task files to resume context across sessions.

### Format

```md
# Task: <Name>

## Status: todo | in-progress | done

## Goal
One-line description.

## Checkpoints
- [ ] Plan drafted
- [ ] Plan reviewed
- [ ] Implementation started
- [ ] Implementation complete
- [ ] Code reviewed
- [ ] Committed

## Notes
```

### When to create a task file

- Any change spanning multiple sessions
- Refactors or architectural changes
- New features or tools being added

---

## Auto-Review Markers

After presenting a complete implementation plan, end your response with `<!-- review:plan -->`.

After finishing a complete implementation, end your response with `<!-- review:code -->`.

These markers are detected by a Stop hook that automatically triggers the appropriate review skill.
