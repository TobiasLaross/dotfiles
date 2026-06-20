#!/usr/bin/env python3
"""
a11y_scan.py — candidate finder for SwiftUI accessibility audits.

This is a HEURISTIC pre-filter, NOT an authoritative linter. Regex cannot see
Swift types, view composition, or whether a label is supplied by a child view,
so every hit it prints is a *candidate to inspect* — the auditing model must
open the file and confirm before reporting it as a finding. Its job is to make
sure no interactive element is overlooked and to give the audit a starting map;
it is deliberately conservative about claiming a violation.

Usage:
    python3 a11y_scan.py <path> [<path> ...]      # files or directories
    python3 a11y_scan.py --diff                   # only files changed vs origin/main
    python3 a11y_scan.py <path> --json            # machine-readable output

Rules (each is a candidate, verify by reading the code):
    A11Y001  icon-only Button (Image label, no Text, no .accessibilityLabel)
    A11Y002  .onTapGesture without .accessibilityAddTraits(.isButton)
    A11Y003  hardcoded .font(.system(size:)) — Dynamic Type breaker
    A11Y004  small fixed frame on/near an interactive element (< 44pt touch target)
    A11Y005  ToolbarItem/Group(placement: .keyboard) — buttons don't reach AX tree
    A11Y006  interactive element with no .accessibilityIdentifier in its chain
    A11Y007  duplicate .accessibilityIdentifier literal across the scanned files
             (ambiguous for the bots — they match the first / wrong element)
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

WINDOW = 14  # lines of modifier-chain lookahead; SwiftUI chains span many lines

INTERACTIVE = re.compile(
    r"\b(Button|TextField|SecureField|Toggle|Picker|Stepper|Slider|"
    r"NavigationLink|Link|Menu)\s*[({<]"
)
HAS_ID = re.compile(r"\.accessibilityIdentifier\(")
HAS_LABEL = re.compile(r"\.accessibilityLabel\(")
HAS_HIDDEN = re.compile(r"\.accessibilityHidden\(true\)")
TEXT_IN_CHAIN = re.compile(r"\bText\(|\bLabel\(|systemImage:|\",\s*systemImage")
IMAGE_LABEL = re.compile(r"\bImage\(")
ON_TAP = re.compile(r"\.onTapGesture")
IS_BUTTON_TRAIT = re.compile(r"\.accessibilityAddTraits\(\.is(Button|Header|Link)")
FONT_SIZE = re.compile(r"\.font\((?:Font)?\.system\(size:")
FRAME_SMALL = re.compile(r"\.frame\([^)]*(?:width|height):\s*(\d+(?:\.\d+)?)")
KEYBOARD_TOOLBAR = re.compile(r"placement:\s*\.keyboard")
# A static identifier literal — skip interpolated ids (per-instance, e.g. "row.\(id)").
STATIC_ID = re.compile(r'\.accessibilityIdentifier\("([^"\\]+)"\)')

RULE_DESC = {
    "A11Y001": "icon-only Button — no Text label, no .accessibilityLabel (invisible to VoiceOver)",
    "A11Y002": ".onTapGesture without .accessibilityAddTraits(.isButton)",
    "A11Y003": "hardcoded .font(.system(size:)) — breaks Dynamic Type",
    "A11Y004": "fixed frame < 44pt on/near interactive element — below HIG touch target",
    "A11Y005": "placement: .keyboard — buttons collapse to one empty group in the AX tree",
    "A11Y006": "interactive element with no .accessibilityIdentifier in its modifier chain",
    "A11Y007": "duplicate .accessibilityIdentifier literal — ambiguous for the test bots",
}


def chain_window(lines, idx):
    """Return the text of the modifier chain following line idx (best-effort)."""
    return "\n".join(lines[idx : idx + WINDOW])


def scan_file(path):
    findings = []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return findings

    for idx, line in enumerate(lines):
        lineno = idx + 1
        window = chain_window(lines, idx)

        if KEYBOARD_TOOLBAR.search(line):
            findings.append((lineno, "A11Y005", line.strip()))

        if FONT_SIZE.search(line):
            findings.append((lineno, "A11Y003", line.strip()))

        if ON_TAP.search(line) and not IS_BUTTON_TRAIT.search(window):
            findings.append((lineno, "A11Y002", line.strip()))

        match_small = FRAME_SMALL.search(line)
        if match_small and float(match_small.group(1)) < 44:
            # Only flag when an interactive element is nearby (look back a little).
            back = "\n".join(lines[max(0, idx - WINDOW) : idx + 2])
            if INTERACTIVE.search(back) or "Image(" in back:
                findings.append((lineno, "A11Y004", line.strip()))

        if INTERACTIVE.search(line):
            if not HAS_ID.search(window):
                findings.append((lineno, "A11Y006", line.strip()))
            # Icon-only button: Image label, no Text/systemImage convenience, no label.
            is_button = line.lstrip().startswith("Button") or "Button(" in line
            if (
                is_button
                and IMAGE_LABEL.search(window)
                and not TEXT_IN_CHAIN.search(window)
                and not HAS_LABEL.search(window)
                and not HAS_HIDDEN.search(window)
            ):
                findings.append((lineno, "A11Y001", line.strip()))

    return findings


def collect_ids(path):
    """Return [(identifier, lineno)] for static (non-interpolated) identifiers."""
    found = []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        return found
    for idx, line in enumerate(lines):
        match = STATIC_ID.search(line)
        if match:
            found.append((match.group(1), idx + 1))
    return found


def find_duplicate_ids(paths):
    """Map each identifier used in 2+ places to its [(file, line)] sites."""
    sites = {}
    for path in paths:
        for identifier, lineno in collect_ids(path):
            sites.setdefault(identifier, []).append((str(path), lineno))
    return {ident: locs for ident, locs in sites.items() if len(locs) > 1}


def gather_paths(args):
    if args.diff:
        try:
            out = subprocess.run(
                ["git", "diff", "--name-only", "--diff-filter=d", "origin/main...HEAD"],
                capture_output=True, text=True, check=True,
            ).stdout
            extra = subprocess.run(
                ["git", "diff", "--name-only", "--diff-filter=d"],
                capture_output=True, text=True, check=True,
            ).stdout
            names = set((out + extra).split())
            return [Path(name) for name in names if name.endswith(".swift")]
        except subprocess.CalledProcessError:
            print("git diff failed — are you in a repo with origin/main?", file=sys.stderr)
            return []
    paths = []
    for raw in args.paths:
        path = Path(raw)
        if path.is_dir():
            paths.extend(path.rglob("*.swift"))
        elif path.suffix == ".swift":
            paths.append(path)
    return paths


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*", help="Swift files or directories")
    parser.add_argument("--diff", action="store_true", help="scan only files changed vs origin/main")
    parser.add_argument("--json", action="store_true", help="emit JSON")
    args = parser.parse_args()

    paths = gather_paths(args)
    if not paths:
        print("No Swift files to scan.", file=sys.stderr)
        return 0

    unique_paths = sorted(set(paths))
    results = {}
    for path in unique_paths:
        hits = scan_file(path)
        if hits:
            results[str(path)] = hits

    duplicate_ids = find_duplicate_ids(unique_paths)

    if args.json:
        payload = {
            "findings": {
                file: [{"line": ln, "rule": rule, "code": code} for ln, rule, code in hits]
                for file, hits in results.items()
            },
            "duplicate_identifiers": {
                ident: [{"file": file, "line": line} for file, line in locs]
                for ident, locs in duplicate_ids.items()
            },
        }
        print(json.dumps(payload, indent=2))
        return 0

    if not results and not duplicate_ids:
        print("No accessibility candidates found. (Still verify interactive elements by reading the code.)")
        return 0

    total = sum(len(hits) for hits in results.values())
    print(f"{total} candidate(s) across {len(results)} file(s) — VERIFY each by reading the code:\n")
    for file, hits in results.items():
        print(f"  {file}")
        for lineno, rule, code in sorted(hits):
            print(f"    {rule}  L{lineno}: {RULE_DESC[rule]}")
            print(f"            {code[:100]}")
        print()
    if duplicate_ids:
        print(f"A11Y007 — {len(duplicate_ids)} duplicate identifier(s) across the scanned files:")
        for ident, locs in sorted(duplicate_ids.items()):
            where = ", ".join(f"{file}:{line}" for file, line in locs)
            print(f"    \"{ident}\"  →  {where}")
        print()

    print("Reminder: these are heuristic candidates. A child view may supply the label,")
    print("a frame may not be the tap target, etc. Confirm before reporting as a finding.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
