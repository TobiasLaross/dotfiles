# Task: Convert auto-review skills to hooks

## Status: in-progress

## Goal
Replace auto-review-plan and auto-review-code skills with a marker-based Stop hook.

## Checkpoints
- [x] Plan drafted
- [ ] Plan reviewed
- [x] CLAUDE.md created
- [x] settings.json created
- [x] hooks/auto-review.sh created
- [x] tasks/ directory created
- [x] symlinks.sh updated
- [x] Symlinks created
- [x] auto-review-plan and auto-review-code skills removed
- [ ] Hook tested end-to-end
- [ ] Done

## Notes
Markers: `<!-- review:plan -->` and `<!-- review:code -->` appended to Claude responses.
Hook reads transcript_path from Stop event stdin payload, detects markers, injects review prompt.
