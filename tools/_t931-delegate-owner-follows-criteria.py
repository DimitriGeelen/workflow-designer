#!/usr/bin/env python3
"""T-931 regression: `fw task delegate` must make ownership follow the open Human criteria.

Operator ruling 2026-09-29: `owner: human` is a sovereignty claim only while a Human criterion
is open. delegation_cli used to flip the owner only `if converted and remaining_human == 0`, so a
task with NO open Human criterion (nothing to convert) kept `owner: human` forever — measured on
832: 45 of 112 human-owned tasks. The fix was lost silently in the 1.7.740 re-vendor because no
test held it (found 2026-10-04 under T-1009); this file is that test.

Runs the real CLI (`python3 -m lib.delegation_cli delegate T-N --dry-run --json`) against fixture
tasks in a temp PROJECT_ROOT. Works in both layouts: a vendoring project (.agentic-framework/lib)
and the framework repo itself (lib/). Exit 0 = all cases pass, 1 = a case failed, 2 = cannot run.
"""
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
# The framework repo itself (FRAMEWORK.md at its root) tests its OWN lib/ -- it also carries a
# self-vendored .agentic-framework/ that must not be picked up instead (caught 2026-10-04: the
# test ran AEF's stale self-vendored copy and failed against a correct fix). A vendoring project
# tests .agentic-framework/.
_order = ((REPO, os.path.join(REPO, ".agentic-framework"))
          if os.path.isfile(os.path.join(REPO, "FRAMEWORK.md"))
          else (os.path.join(REPO, ".agentic-framework"), REPO))
FW = next((c for c in _order
           if os.path.isfile(os.path.join(c, "lib", "delegation_cli.py"))), None)
if FW is None:
    print("CANNOT RUN: lib/delegation_cli.py not found under .agentic-framework/ or the repo root")
    sys.exit(2)

FM = """---
id: {tid}
name: "fixture"
description: fixture
status: started-work
workflow_type: build
owner: {owner}
horizon: now
created: 2026-10-04T00:00:00Z
last_update: 2026-10-04T00:00:00Z
---

# {tid}: fixture

## Acceptance Criteria

### Agent
- [x] done
{human}
## Verification
"""

OPEN_JUDGEMENT = """
### Human
- [ ] [REVIEW] Decide whether the new colour palette feels right for the product
  **Steps:**
  1. Open the editor and look at the palette
  **Expected:** you are happy with how it feels
  **If not:** say what feels wrong
"""

CASES = [
    # (name, owner, human-section, expected owner_after)
    ("no Human criteria at all -> owner follows (the lost fix)", "human", "", "agent"),
    ("every Human criterion ticked -> owner follows", "human",
     "\n### Human\n- [x] [REVIEW] Signed off already\n", "agent"),
    ("CONTROL an open judgement criterion keeps owner: human", "human", OPEN_JUDGEMENT, "human"),
    ("owner: agent with nothing open is unchanged", "agent", "", "agent"),
]


def run(root, tid):
    fw = str(FW)
    env = dict(os.environ, PROJECT_ROOT=root, PYTHONPATH=fw)
    p = subprocess.run([sys.executable, "-m", "lib.delegation_cli", "delegate", tid,
                        "--dry-run", "--json"], cwd=fw, env=env, capture_output=True, text=True)
    try:
        return json.loads(p.stdout), p
    except ValueError:
        return None, p


def main():
    failures = 0
    with tempfile.TemporaryDirectory(prefix="t931-delegate-") as root:
        os.makedirs(os.path.join(root, ".tasks", "active"))
        os.makedirs(os.path.join(root, ".tasks", "completed"))
        for i, (name, owner, human, want) in enumerate(CASES):
            tid = "T-%d" % (9101 + i)
            with open(os.path.join(root, ".tasks", "active", tid + "-fixture.md"), "w") as fh:
                fh.write(FM.format(tid=tid, owner=owner, human=human))
            rec, p = run(root, tid)
            if rec is None:
                print("  CANNOT RUN  %s: no JSON (rc=%d) %s" % (name, p.returncode,
                                                               (p.stderr or p.stdout)[-300:]))
                return 2
            got = rec.get("owner_after")
            ok = got == want
            failures += 0 if ok else 1
            print("  %s  %s (owner_after=%s, want %s)" % ("PASS" if ok else "FAIL", name, got, want))
    print("%d/%d passed" % (len(CASES) - failures, len(CASES)))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
