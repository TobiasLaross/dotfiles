# Global Claude Instructions

## Story Tracking

For any significant change, create and maintain a story file at `~/.claude/stories/<kebab-name>/story.md` before starting work. Update checkpoints as each stage completes. Use story files to resume context across sessions.

Use `/story <description>` to kick off the story creation flow — Claude will draft a user story for approval before creating any files.

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

### When to create a story

- Any change spanning multiple sessions
- Refactors or architectural changes
- New features or tools being added

### Story lifecycle

- Active stories live in `~/.claude/stories/<name>/`
- Completed stories move to `~/.claude/stories/done/<name>/`
- All related md files for a story go in its folder

---

## Auto-Review Markers

After presenting a complete implementation plan, end your response with `<!-- review:plan -->`.

After finishing a complete implementation, end your response with `<!-- review:code -->`.

These markers are detected by a Stop hook that automatically triggers the appropriate review skill.
