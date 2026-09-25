#!/usr/bin/env python3
"""T-857 — repair the ONE hook entry whose path Claude Code cannot resolve.

WHY THIS SCRIPT EXISTS RATHER THAN A ONE-LINE sed. B-005 structurally blocks the
agent from writing .claude/settings.json and there is no settings.local.json side
door, so the edit is the operator's to run. Same shape as T-847's registrar, which
the operator ran. A sed would also happily corrupt JSON; this fails closed.

WHAT IS WRONG. T-847's registrar wrote the advisory's command as
    $CLAUDE_PROJECT_DIR/tools/hooks/warn-uncontrolled-absence.sh
while 19 of the other 20 hook entries use a plain absolute path. Measured 2026-09-25:
CLAUDE_PROJECT_DIR is UNSET in this environment, so that command resolves to
    /tools/hooks/warn-uncontrolled-absence.sh   ->  No such file or directory
The advisory has therefore never fired. The script itself is fine — invoked directly
with a real payload it correctly flags an uncontrolled absence leg — and the tool
counter keeps incrementing, so PostToolUse hooks in general do run. It is this one
entry's path, and nothing else.

WHAT THIS CHANGES. Exactly one string in one hook entry. Every other entry, the
group structure, the matchers and the ordering are left byte-identical.

AFTER RUNNING IT you MUST refresh the enforcement baseline, or fw doctor trades one
FAIL for another (L-398, T-1886):
    cd /opt/832-Workflow-designer && .agentic-framework/bin/fw enforcement baseline
"""

import json
import os
import shutil
import sys
from pathlib import Path

NEEDLE = "$CLAUDE_PROJECT_DIR/tools/hooks/warn-uncontrolled-absence.sh"
SCRIPT_REL = "tools/hooks/warn-uncontrolled-absence.sh"


def main(argv):
    root = Path(argv[1]).resolve() if len(argv) > 1 else Path("/opt/832-Workflow-designer")
    settings = root / ".claude" / "settings.json"
    target = str(root / SCRIPT_REL)

    if not settings.is_file():
        print(f"REFUSING: no settings file at {settings}", file=sys.stderr)
        return 2

    raw = settings.read_text()
    try:
        data = json.loads(raw)
    except Exception as exc:
        # Fails closed: a settings file we cannot parse is one we must not rewrite.
        print(f"REFUSING: {settings} is not valid JSON ({exc}). Nothing written.", file=sys.stderr)
        return 2

    if not (root / SCRIPT_REL).is_file():
        print(f"REFUSING: {target} does not exist — fix the path to nothing is not a fix.",
              file=sys.stderr)
        return 2

    hits = 0
    already = 0
    for groups in (data.get("hooks") or {}).values():
        for group in groups or []:
            for hook in group.get("hooks") or []:
                cmd = hook.get("command", "")
                if NEEDLE in cmd:
                    hook["command"] = cmd.replace(NEEDLE, target)
                    hits += 1
                elif cmd.strip() == target:
                    already += 1

    if hits == 0:
        # Idempotent: a second run is a no-op that says so, not an error.
        if already:
            print(f"OK: already absolute ({already} entry/entries). Nothing to do.")
            return 0
        print(f"NOT EVALUATED: no entry contains {NEEDLE}.", file=sys.stderr)
        print("  Either it was already repaired by other means, or the advisory is not "
              "registered at all. Check with: fw doctor", file=sys.stderr)
        return 2
    if hits > 1:
        print(f"REFUSING: {hits} entries match; expected exactly 1. Inspect by hand.",
              file=sys.stderr)
        return 2

    backup = settings.with_suffix(".json.pre-t857")
    shutil.copy2(settings, backup)
    tmp = settings.with_suffix(".json.t857-tmp")
    # Two spaces, trailing newline: matches how the file is already formatted, so the
    # diff is the one line that changed rather than a whole-file reformat.
    tmp.write_text(json.dumps(data, indent=2) + "\n")
    os.replace(tmp, settings)

    print(f"OK: 1 hook command rewritten to an absolute path.")
    print(f"  was: {NEEDLE}")
    print(f"  now: {target}")
    print(f"  backup: {backup}")
    print()
    print("REQUIRED NEXT STEP — the canonical hook hash changed, so fw doctor will")
    print("report 'Enforcement baseline CHANGED' until you refresh it (L-398):")
    print()
    print("  cd /opt/832-Workflow-designer && .agentic-framework/bin/fw enforcement baseline")
    print()
    print("Then confirm both original failures are gone:")
    print()
    print("  cd /opt/832-Workflow-designer && .agentic-framework/bin/fw doctor")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
