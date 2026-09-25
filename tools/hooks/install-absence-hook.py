#!/usr/bin/env python3
"""T-847 — register the T-843 write-time absence advisory in .claude/settings.json.

THE OPERATOR RUNS THIS, NOT THE AGENT. B-005 blocks the agent from writing
.claude/settings.json and there is no settings.local.json side door, so the Route 3 hook can
only be installed by a human. This script exists so that is one short paste rather than a
hand-edit of a 7-group JSON structure.

WHY NOT JUST PASTE THE JSON. `.claude/settings.json` already carries a `Write|Edit` PostToolUse
group holding `fw hook commit-cadence`. Appending a NEW group with the same matcher is valid
JSON and quietly duplicated semantics, so the fragment has to merge into the existing group —
which is fiddly by hand and is exactly the kind of step that gets done wrong once and then
avoided.

IDEMPOTENT: re-running reports "already registered" and writes nothing.

AFTER RUNNING IT, refresh the enforcement baseline or `fw doctor` reports a standing
"Enforcement baseline CHANGED" FAIL that accumulates silently (L-398 — it bit T-1849, T-1730
and T-1731 in turn):

    cd /opt/832-Workflow-designer && .agentic-framework/bin/fw enforcement baseline

Usage:  python3 tools/hooks/install-absence-hook.py [path-to-settings.json] [--dry-run]
"""
import json
import os
import sys

CMD = "$CLAUDE_PROJECT_DIR/tools/hooks/warn-uncontrolled-absence.sh"
MATCHER = "Write|Edit"


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
        # Fail closed and loudly: a half-parsed settings file must never be rewritten.
        print("REFUSE: %s is not valid JSON (%s) — not touching it" % (path, exc))
        return 2

    groups = data.setdefault("hooks", {}).setdefault("PostToolUse", [])
    target = next((g for g in groups if g.get("matcher") == MATCHER), None)
    created_group = target is None
    if created_group:
        target = {"matcher": MATCHER, "hooks": []}
        groups.append(target)
    hooks = target.setdefault("hooks", [])

    if any(h.get("command") == CMD for h in hooks):
        print("already registered — no change made to %s" % path)
        return 0

    hooks.append({"type": "command", "command": CMD})
    if dry:
        print("DRY RUN: would %s the '%s' group and add the advisory (%d hook(s) after)"
              % ("create" if created_group else "append to", MATCHER, len(hooks)))
        return 0

    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    print("registered in %s (%s '%s' group, %d hook(s) in it)"
          % (path, "created" if created_group else "appended to", MATCHER, len(hooks)))
    print("NEXT, or fw doctor will report a standing baseline FAIL (L-398):")
    print("  cd /opt/832-Workflow-designer && .agentic-framework/bin/fw enforcement baseline")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
