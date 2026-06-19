#!/usr/bin/env python3
"""PreToolUse(Bash) guard: block test/build runners piped into a pager.

The pitfall: `pytest | tail` (or `| head` / `| grep`) returns the *pager's*
exit code, not the runner's, so a failing test suite looks like it passed. This
hook denies that shape unless the command guards the exit code itself
($PIPESTATUS / $pipestatus / `set -o pipefail`) or there is no pipe at all
(e.g. redirect the runner to a file, then grep the file separately).

Reads the PreToolUse JSON event on stdin; on a match it exits 2 with an
explanation on stderr (Claude Code feeds stderr back to the model and blocks
the call). Anything it doesn't recognize passes through (exit 0, silent).
"""

from __future__ import annotations

import json
import re
import sys

# A command boundary: the runner has to start a command, not sit inside a path
# (`cat pytest.log | tail` must not trip). Start-of-string or after a
# separator/opener.
_BOUNDARY = r"(?:^|[\n;&|(]|&&|\|\|)\s*"

# Optional leading `VAR=value` assignments — the real invocations are
# `PYTHONPATH="$WT/src" pytest …`, so the runner is rarely the literal first
# token. Values may be bare, single-, or double-quoted (the quoted form lets a
# value contain spaces without ending the prefix).
_ENV_PREFIX = r"(?:[A-Za-z_]\w*=(?:\"[^\"]*\"|'[^']*'|\S*)\s+)*"

# An interpreter in front of `-m pytest`: a literal python, a `$VAR` / `${VAR}`
# indirection (we run pytest as `$VPY -m pytest`), an absolute/relative path to
# one, or a `uv run` / `poetry run` / `pdm run` wrapper. The `-m pytest` flag
# form is interpreter-agnostic and never appears in a filename, so it's a strong
# signal on its own — the interpreter prefix is optional.
_INTERP = r"(?:[\w./-]*python[0-9.]*|\$\{?\w+\}?|uv\s+run|poetry\s+run|pdm\s+run)\s+"

# A runner whose exit code actually matters. Two shapes, both anchored to a
# command boundary after any env-assignment prefix:
#   1. `[<interp>] -m pytest`  — covers `$VPY -m pytest`, `python3 -m pytest`,
#      `/path/to/python -m pytest`, and a bare `-m pytest`.
#   2. a named runner token — pytest/ruff/jest/etc. as the command itself.
_RUNNER = re.compile(
    _BOUNDARY + _ENV_PREFIX + r"(?:" + _INTERP + r")?-m\s+pytest\b"
    r"|"
    + _BOUNDARY
    + _ENV_PREFIX
    + r"(?:pytest|py\.test|uv\s+run\s+pytest"
    r"|mocha|jest|vitest|ruff|tsc|eslint"
    r"|npm\s+(?:run|test)|pnpm\s+(?:run|test)|yarn\s+(?:run|test)|npx"
    r"|cargo\s+(?:test|build)|go\s+test|make)\b"
)
# The masking final stage: a pipe into a pager/filter that swallows the status.
_MASKER = re.compile(r"\|\s*(?:tail|head|grep|sed|awk|less|wc)\b")
# Either of these means the author already accounted for the pipeline status.
_GUARD = re.compile(r"pipestatus|pipefail", re.IGNORECASE)

_MESSAGE = (
    "Blocked: this pipes a test/build runner into tail/head/grep/sed/awk/less/wc, "
    "so the pipeline reports the filter's exit code (usually 0), masking a real "
    "failure. Either redirect the runner to a file and grep the file "
    "separately:\n"
    "    <runner> > /tmp/out.log 2>&1; echo \"EXIT=$?\"; grep -E 'passed|failed' /tmp/out.log\n"
    "or guard the pipeline status explicitly with $pipestatus / "
    "$PIPESTATUS, or `set -o pipefail` before the pipe."
)


def should_block(command: object) -> bool:
    """True when ``command`` is a runner-piped-into-a-pager with no status guard.

    Split out from ``main`` so the regex behaviour is unit-testable without
    spawning the process. A heredoc-bearing command is exempt: its body is
    data (we author test fixtures and `python3 - <<PY … | tail …` examples),
    not a pipeline whose own exit code we're checking — matching there is a
    false positive, not a masked failure.
    """
    if not isinstance(command, str) or not command:
        return False
    if "<<" in command:
        return False
    return bool(_RUNNER.search(command) and _MASKER.search(command) and not _GUARD.search(command))


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # Not parseable — don't get in the way.
    command = (event.get("tool_input") or {}).get("command")
    if should_block(command):
        print(_MESSAGE, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
