#!/usr/bin/env python3
"""
T-522 teeth — does a completed task still get its episodic memory, and does anyone NOTICE
when it does not?

WHAT BROKE. `update-task.sh` runs under `set -euo pipefail`. Its component auto-populate
block (T-224) reads every card in .fabric/components/ with

    c_loc=$(grep "^location:" "$card" 2>/dev/null | sed ... | head -1)

A card that lacks `location:` makes grep exit 1; pipefail carries that through the pipe, and
the *assignment* then terminates the entire script. By that point the task file has already
been moved to completed/ and rewritten, so completion LOOKS fine. Everything below the abort
never runs — decision capture, outcome back-prop, and the Episodic Generation block ~110
lines further down. Measured on the real corpus: two hand-written cards without `location:`
landed at 12:13:39Z on 2026-08-15, and the next two completions (T-520 at 12:13:59Z, T-521 at
13:34:03Z) both lost their episodics, while T-519 at 11:53:42Z — before those cards existed —
was fine.

WHY IT STAYED INVISIBLE, WHICH IS THE PART WORTH TESTING. Two controls already existed and
neither could see it. T-1169 warns when the generator produces no file; T-1860 logs every
generator invocation. Both live INSIDE the block that never executed. A control downstream of
the branch that fails cannot report the failure — the same shape T-509 and PL-206 keep
turning up. So T-522 fixed the abort AND put a watchdog on the EXIT trap, outside the block
it guards.

WHAT THIS SCRIPT ASSERTS, AND WHY IN THIS ORDER.
  leg 1  MUTATION / anti-vacuity. Copy the framework, put the unguarded grep BACK, and run a
         real completion. Must lose the episodic — otherwise leg 2's green means nothing,
         because a harness that cannot reproduce the bug cannot certify the fix.
  leg 2  MUTATION, second half. That same broken run must be REPORTED by the watchdog: named
         message on stderr and a NOT REACHED record in episodic-gen/. This is the T-1860
         promise ("log EVERY invocation") honoured on the path where the logging code itself
         never ran. PL-206: red is not enough, it has to be red for the named reason.
  leg 3  The real tree, same hostile card: episodic present, invocation log written.
  leg 4  No false positive. A partial-complete task (unchecked Human AC) SKIPS episodic
         generation by design (T-1160/T-1103) and stays in active/ — the watchdog must stay
         silent. A watchdog that cries on the designed skip gets muted, and then it is gone.
  leg 5  Exactly one `trap ... EXIT` in update-task.sh. bash silently REPLACES an EXIT trap
         when a second one is installed, so the next person adding cleanup would delete the
         watchdog with no error anywhere. This is the only leg that guards the guard.

Hermetic: every run happens under mktemp. Touches nothing in this repository.
Exit 0 all legs pass, 1 a leg failed, 2 REFUSE (preconditions absent — distinguishable from
a pass, PL-205).
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAMEWORK = os.path.join(REPO, ".agentic-framework")
UPDATE_TASK = os.path.join(FRAMEWORK, "agents", "task-create", "update-task.sh")

# The guarded form T-522 installed. The mutation puts the unguarded form back.
GUARDED = '''c_loc=$({ grep "^location:" "$card" 2>/dev/null || true; } | sed 's/^location:[[:space:]]*//' | head -1)'''
UNGUARDED = '''c_loc=$(grep "^location:" "$card" 2>/dev/null | sed 's/^location:[[:space:]]*//' | head -1)'''

TASK = """---
id: T-999
name: "t522 reachability probe"
description: hermetic probe task
status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
created: 2026-08-15T00:00:00Z
last_update: 2026-08-15T00:00:00Z
date_finished: null
---

# T-999: t522 reachability probe

## Acceptance Criteria

### Agent
- [x] the probe ran
%(human)s
## Updates
"""

HUMAN_BLOCK = """
### Human
- [ ] [REVIEW] someone looked at it
  **Steps:**
  1. look
  **Expected:** it looks fine
  **If not:** say so
"""

failures = []
passes = 0


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def leg(name, ok, detail=""):
    global passes
    if ok:
        passes += 1
        print("  PASS  %s" % name)
    else:
        failures.append(name)
        print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))


def make_project(root, human=False):
    """A minimal project whose ONLY hostile feature is a card without `location:`."""
    for d in (
        ".tasks/active",
        ".tasks/completed",
        ".tasks/templates",
        ".context/working",
        ".context/episodic",
        ".context/project",
        ".fabric/components",
    ):
        os.makedirs(os.path.join(root, d), exist_ok=True)
    with open(os.path.join(root, ".tasks/active/T-999-probe.md"), "w") as f:
        f.write(TASK % {"human": HUMAN_BLOCK if human else ""})
    # The trigger: a well-formed YAML card that simply has no `location:` key.
    with open(os.path.join(root, ".fabric/components/no-location.yaml"), "w") as f:
        f.write("id: x/y.sh\nname: y\ntype: script\nsubsystem: unknown\ntags: []\n")
    subprocess.run(
        ["git", "-C", root, "init", "-q"], capture_output=True, text=True, check=False
    )


def run_completion(framework_root, project_root):
    script = os.path.join(framework_root, "agents", "task-create", "update-task.sh")
    p = subprocess.run(
        [script, "T-999", "--status", "work-completed"],
        cwd=REPO,
        env=dict(os.environ, PROJECT_ROOT=project_root),
        capture_output=True,
        text=True,
        check=False,
    )
    return p.returncode, p.stdout + p.stderr


def episodic_exists(project_root):
    return os.path.isfile(os.path.join(project_root, ".context/episodic/T-999.yaml"))


def gen_log(project_root):
    path = os.path.join(project_root, ".context/working/episodic-gen/T-999.log")
    if not os.path.isfile(path):
        return None
    with open(path) as f:
        return f.read()


# ---------------------------------------------------------------------------
# Preconditions — refuse rather than pass when the subject is not what we think
# ---------------------------------------------------------------------------
if not os.path.isfile(UPDATE_TASK):
    refuse("update-task.sh not found at %s" % UPDATE_TASK)

with open(UPDATE_TASK) as f:
    SRC = f.read()

if GUARDED not in SRC:
    refuse(
        "the T-522 guarded idiom is not present in update-task.sh, so the mutation in leg 1 "
        "would be a no-op and legs 1-2 would report a green that means nothing. Either the "
        "fix was reverted (that is a real regression — look at the components auto-populate "
        "block) or the line was reformatted and this script needs its literal updated."
    )

print("T-522 teeth — episodic reachability on task completion")
print("subject: %s" % os.path.relpath(UPDATE_TASK, REPO))
print()

# ---------------------------------------------------------------------------
# legs 1 + 2 — mutation: put the defect back, prove it bites AND is reported
# ---------------------------------------------------------------------------
mut_fw = tempfile.mkdtemp(prefix="t522-fw-")
mut_proj = tempfile.mkdtemp(prefix="t522-proj-")
try:
    shutil.copytree(FRAMEWORK, os.path.join(mut_fw, "fw"), symlinks=True)
    mut_root = os.path.join(mut_fw, "fw")
    mut_script = os.path.join(mut_root, "agents", "task-create", "update-task.sh")
    with open(mut_script) as f:
        body = f.read()
    body = body.replace(GUARDED, UNGUARDED, 1)
    with open(mut_script, "w") as f:
        f.write(body)

    make_project(mut_proj)
    rc, out = run_completion(mut_root, mut_proj)

    leg(
        "1 mutation reproduces the defect — unguarded grep loses the episodic",
        not episodic_exists(mut_proj),
        "episodic WAS generated on the mutated tree (rc=%d). The harness no longer "
        "reproduces the bug, so leg 3 proves nothing." % rc,
    )

    log = gen_log(mut_proj)
    watchdog_logged = bool(log and "NOT REACHED" in log)
    watchdog_spoke = "episodic generation was never reached" in out
    leg(
        "2 watchdog reports the abort by name (stderr + episodic-gen log)",
        watchdog_logged and watchdog_spoke,
        "stderr message %s, NOT REACHED log record %s. A silent abort is exactly the "
        "failure mode T-522 exists to end."
        % ("present" if watchdog_spoke else "MISSING",
           "present" if watchdog_logged else "MISSING"),
    )
finally:
    shutil.rmtree(mut_fw, ignore_errors=True)
    shutil.rmtree(mut_proj, ignore_errors=True)

# ---------------------------------------------------------------------------
# leg 3 — the real tree survives the same hostile card
# ---------------------------------------------------------------------------
proj = tempfile.mkdtemp(prefix="t522-proj-")
try:
    make_project(proj)
    rc, out = run_completion(FRAMEWORK, proj)
    log = gen_log(proj)
    leg(
        "3 real tree: card without `location:` no longer aborts completion",
        rc == 0 and episodic_exists(proj) and bool(log) and "NOT REACHED" not in log,
        "rc=%d episodic=%s log=%s" % (rc, episodic_exists(proj), bool(log)),
    )
finally:
    shutil.rmtree(proj, ignore_errors=True)

# ---------------------------------------------------------------------------
# leg 4 — the designed skip must not trip the watchdog
# ---------------------------------------------------------------------------
proj = tempfile.mkdtemp(prefix="t522-proj-")
try:
    make_project(proj, human=True)
    rc, out = run_completion(FRAMEWORK, proj)
    still_active = os.path.isfile(os.path.join(proj, ".tasks/active/T-999-probe.md"))
    leg(
        "4 partial-complete (unchecked Human AC) skips episodic WITHOUT a watchdog alarm",
        still_active and "episodic generation was never reached" not in out,
        "task_in_active=%s, watchdog fired=%s. Partial-complete deliberately defers "
        "episodic generation (T-1160/T-1103); alarming on it trains people to ignore the "
        "alarm." % (still_active, "episodic generation was never reached" in out),
    )
finally:
    shutil.rmtree(proj, ignore_errors=True)

# ---------------------------------------------------------------------------
# leg 5 — guard the guard
# ---------------------------------------------------------------------------
exit_traps = re.findall(r"^\s*trap\s+.*\bEXIT\b", SRC, re.M)
leg(
    "5 exactly one EXIT trap in update-task.sh (a second one silently replaces it)",
    len(exit_traps) == 1,
    "found %d EXIT traps. bash keeps only the last; whichever one is installed later wins "
    "and the others vanish with no error. If cleanup was genuinely needed, compose it into "
    "the existing trap rather than installing another.\n        %s"
    % (len(exit_traps), "\n        ".join(t.strip() for t in exit_traps)),
)

print()
total = passes + len(failures)
if failures:
    print("%d/%d legs passed — FAILED: %s" % (passes, total, ", ".join(failures)))
    sys.exit(1)
print("%d/%d legs passed" % (passes, total))
sys.exit(0)
