#!/usr/bin/env python3
"""Check profile writes against the profile template.

`replica:Set({path}, value)` walks every segment of the path EXCEPT the last and
then assigns — so a missing intermediate table throws at runtime. The template
in src/server/Data/Default.luau is the only thing that guarantees those
intermediates exist, because Global.FillTable can only backfill what it knows
about.

This walks every literal `:Set` / `:SetValues` / `:TableInsert` / `:TableRemove`
path in src/server and reports any whose intermediates the template does not
declare. It is deliberately lexical: it does not run Luau, so a dynamic segment
(a variable, an index) simply ends the check for that path — everything before
it is still verified.

    python3 tools/check_schema.py          # exits 1 if anything is unbacked

See DATA.md §4, invariant 1.
"""
from __future__ import annotations

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(REPO, "src", "server", "Data", "Default.luau")
SERVER = os.path.join(REPO, "src", "server")

# `replica:Set({ "A", "B" }, …)` and friends. The path argument only; the value
# may contain anything, including braces, so we stop at the first `}`.
CALL = re.compile(
    r':(Set|SetValues|TableInsert|TableRemove)\(\s*\{([^{}]*)\}',
)
SEGMENT = re.compile(r'^"([A-Za-z_][A-Za-z0-9_]*)"$')


def strip_comments(src: str) -> str:
    out, i, n = [], 0, len(src)
    while i < n:
        if src.startswith("--[[", i):
            j = src.find("]]", i)
            if j == -1:
                break
            out.append("\n" * src.count("\n", i, j))
            i = j + 2
            continue
        if src.startswith("--", i):
            j = src.find("\n", i)
            if j == -1:
                break
            i = j
            continue
        out.append(src[i])
        i += 1
    return "".join(out)


SETTINGS = os.path.join(
    REPO, "src", "shared", "Modules", "Global", "Libraries", "Game_Settings.luau"
)


def resolve_dynamic_key(line: str) -> str:
    """`[Game_Settings.A.B.Field] = …` -> the literal string Field holds."""
    m = re.search(r'\[\s*[A-Za-z_][\w.]*\.([A-Za-z_]\w*)\s*\]', line)
    if m is None:
        return "?"
    field = m.group(1)
    settings = open(SETTINGS, encoding="utf-8").read()
    hit = re.search(rf'\b{re.escape(field)}\s*=\s*"([^"]+)"', settings)
    return hit.group(1) if hit else "?"


def template_tree() -> dict:
    """Top-level and one nested level of Default.luau, as a dict of dicts."""
    src = strip_comments(open(TEMPLATE, encoding="utf-8").read())
    tree: dict = {}
    depth = 0
    stack: list[dict] = []
    pending: str | None = None
    for line in src.split("\n"):
        m = re.match(r'\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', line)
        key = m.group(1) if m else None
        rest = m.group(2) if m else ""
        # A dynamic key (`[Game_Settings.Zones.Workout.SecondsField] = 0`) is
        # declared but not spelled here. RESOLVE it rather than wildcarding: a
        # wildcard at the root suppresses every root check and turns this whole
        # script into a no-op, which is exactly what the first version did.
        if re.match(r'\s*\[', line):
            key = resolve_dynamic_key(line)
            rest = line.split("=", 1)[1] if "=" in line else ""
            if key == "?":
                print(f"warning: unresolved dynamic template key: {line.strip()}")
        if key and depth >= 1:
            target = stack[-1] if stack else tree
            target[key] = {}
            if rest.strip().startswith("{"):
                pending = key
        for ch in line:
            if ch == "{":
                depth += 1
                if depth == 1:
                    stack = [tree]
                elif pending is not None:
                    parent = stack[-1]
                    stack.append(parent[pending])
                    pending = None
                else:
                    stack.append({})
            elif ch == "}":
                depth -= 1
                if stack:
                    stack.pop()
    return tree


def main() -> int:
    tree = template_tree()
    problems: list[str] = []
    checked = 0

    for dirpath, _, names in os.walk(SERVER):
        for name in sorted(names):
            if not name.endswith(".luau"):
                continue
            path = os.path.join(dirpath, name)
            src = strip_comments(open(path, encoding="utf-8").read())
            for lineno, line in enumerate(src.split("\n"), 1):
                for call in CALL.finditer(line):
                    raw = [p.strip() for p in call.group(2).split(",") if p.strip()]
                    segments: list[str] = []
                    for piece in raw:
                        seg = SEGMENT.match(piece)
                        if seg is None:
                            break  # dynamic from here on; stop verifying
                        segments.append(seg.group(1))
                    if not segments:
                        continue
                    checked += 1
                    # Only the intermediates have to exist; the leaf may be new.
                    node = tree
                    walked: list[str] = []
                    for seg in segments[:-1]:
                        walked.append(seg)
                        if seg in node:
                            node = node[seg]
                        else:
                            rel = os.path.relpath(path, REPO)
                            problems.append(
                                f"{rel}:{lineno}  {{{', '.join(segments)}}}"
                                f"  — '{'.'.join(walked)}' is not in Default.luau"
                            )
                            break
                    # A single-segment path writes at the root, which always exists,
                    # but flag it if the template does not declare it: FillTable can
                    # never backfill a field it has not been told about.
                    if len(segments) == 1 and segments[0] not in tree:
                        rel = os.path.relpath(path, REPO)
                        problems.append(
                            f"{rel}:{lineno}  {{{segments[0]}}}"
                            f"  — root field '{segments[0]}' is not in Default.luau"
                        )

    for problem in problems:
        print(problem)
    print(f"-- {checked} literal profile paths checked, {len(problems)} unbacked")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
