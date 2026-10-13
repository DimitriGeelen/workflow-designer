#!/usr/bin/env python3
"""T-1145 — register the decision-handover guard (a Stop hook) in .claude/settings.json.

THE OPERATOR RUNS THIS (runme job), NOT THE AGENT: B-005 blocks the agent from writing
.claude/settings.json. Same shape as install-absence-hook.py (T-847): merges into the existing
Stop group (matcher "") instead of appending a duplicate group, refuses a settings file that does
not parse, and is idempotent ("already registered" writes nothing).

Afterwards refresh the enforcement baseline, or fw doctor reports "Enforcement baseline CHANGED"
(L-398): .agentic-framework/bin/fw enforcement baseline

Usage:  python3 tools/hooks/install-decision-handover-guard.py [path-to-settings.json] [--dry-run]
"""
import json
import os
import sys

CMD = "${CLAUDE_PROJECT_DIR}/tools/hooks/guard-decision-handover.py"
EVENT = "Stop"
MATCHER = ""


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in argv
    path = args[0] if args else os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        ".claude", "settings.json")

    if not os.path.isfile(path):
        print("REFUSE: no settings file at %s" % path)
        return 2
    try:
        data = json.load(open(path, encoding="utf-8"))
    except ValueError as exc:
        print("REFUSE: %s is not valid JSON (%s) — not touching it" % (path, exc))
        return 2

    groups = data.setdefault("hooks", {}).setdefault(EVENT, [])
    target = next((g for g in groups if g.get("matcher", "") == MATCHER), None)
    created_group = target is None
    if created_group:
        target = {"matcher": MATCHER, "hooks": []}
        groups.append(target)
    hooks = target.setdefault("hooks", [])

    if any(h.get("command") == CMD for h in hooks):
        print("already registered — no change made to %s" % path)
        return 0

    hooks.append({"type": "command", "command": CMD, "timeout": 60})
    if dry:
        print("DRY RUN: would %s the %s group and add the guard (%d hook(s) after)"
              % ("create" if created_group else "append to", EVENT, len(hooks)))
        return 0

    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    print("registered %s in %s (%d %s hook(s) now)" % (CMD, path, len(hooks), EVENT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
