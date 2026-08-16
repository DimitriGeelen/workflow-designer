#!/usr/bin/env python3
"""T-536 teeth — CTL-028 must still detect a task whose location and status disagree.

Drives the REAL audit binary (vendored .agentic-framework/agents/audit/audit.sh) through the
TASKS_DIR seam against a synthetic task tree. The real .tasks/ is neither read nor written.

WHY THIS IS DRIVEN AGAINST A SYNTHETIC TREE, NOT THE REAL ONE
    T-536 cleaned the four real offenders, so a guard asserting "the real tree is clean" is a
    global always-moving property (G-015): it goes red for someone else's unrelated mistake and
    green for reasons that have nothing to do with CTL-028 still working. It would also go
    permanently green the moment the control is deleted. This plants the disagreement instead, so
    what is asserted is the CONTROL'S ABILITY TO SEE, not the tree's current cleanliness.

THE FAILURE MODE THIS EXISTS FOR
    CTL-028 was not broken. It fired correctly 263 times over 14 days and nobody saw one of them,
    because `audit.sh:3721` gates it on `compliance || oe-daily` while the pre-push hook
    (`agents/git/lib/hooks.sh:839`) runs `--section structure` only. A control that runs nowhere a
    reader looks is indistinguishable from a control that does not exist. Leg 3 therefore asserts
    the SECTION the control answers on, so a future re-gating that strands it again goes red here.

Exit codes:  0 = all legs green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = os.path.join(ROOT, ".agentic-framework", "bin", "fw")

CLEAN_ID = "T-9001"      # in completed/, status work-completed  -> must NOT be named
DESYNC_ID = "T-9002"     # in completed/, status started-work    -> MUST be named
ACTIVE_ID = "T-9003"     # in active/,    status started-work    -> must NOT be named (not drift)

CTL_LINE = re.compile(r'CTL-028:\s*(?P<rest>.*)$')


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def task_md(task_id, status, name):
    return """---
id: {tid}
name: "{name}"
description: >
  Synthetic fixture for the T-536 status-desync teeth. Never shipped, never real.

status: {status}
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-01-01T00:00:00Z
last_update: 2026-01-01T00:00:00Z
date_finished: {finished}
---

# {tid}: {name}

## Acceptance Criteria

### Agent
- [x] Fixture only.

## Verification

# none
""".format(tid=task_id, name=name, status=status,
           finished=("2026-01-01T00:00:00Z" if status == "work-completed" else "null"))


def build_tree(base):
    for sub in ("active", "completed", "templates"):
        os.makedirs(os.path.join(base, sub), exist_ok=True)
    # The template is required by the structure checks; copy the real one so the fixture tree is
    # not subtly different from a real project in a way that changes what the audit does.
    real_tpl = os.path.join(ROOT, ".tasks", "templates", "default.md")
    if os.path.isfile(real_tpl):
        shutil.copy(real_tpl, os.path.join(base, "templates", "default.md"))
    else:
        open(os.path.join(base, "templates", "default.md"), "w").write("---\nid: T-000\n---\n")

    open(os.path.join(base, "completed", "%s-clean.md" % CLEAN_ID), "w").write(
        task_md(CLEAN_ID, "work-completed", "Closed through the state machine"))
    open(os.path.join(base, "completed", "%s-desync.md" % DESYNC_ID), "w").write(
        task_md(DESYNC_ID, "started-work", "Moved by git mv, frontmatter never rewritten"))
    open(os.path.join(base, "active", "%s-inflight.md" % ACTIVE_ID), "w").write(
        task_md(ACTIVE_ID, "started-work", "Genuinely in flight, must not be flagged"))


def run_audit(tasks_dir):
    env = dict(os.environ, TASKS_DIR=tasks_dir)
    proc = subprocess.run([FW, "audit", "--section", "compliance"],
                          cwd=ROOT, env=env, capture_output=True, text=True, timeout=900)
    return proc.stdout + proc.stderr


def main():
    if not os.path.isfile(FW):
        refuse("fw not found at %s" % FW)

    sandbox = tempfile.mkdtemp(prefix="t536-desync-")
    try:
        build_tree(sandbox)
        out = run_audit(sandbox)
    finally:
        shutil.rmtree(sandbox, ignore_errors=True)

    ctl_lines = [m.group("rest").strip() for m in
                 (CTL_LINE.search(l) for l in out.splitlines()) if m]

    # Leg 0 — REFUSE rather than pass when the control did not speak at all. A deleted or
    # re-gated CTL-028 emits nothing, and "nothing" is indistinguishable from "all clear".
    if not ctl_lines:
        refuse("audit --section compliance emitted no CTL-028 line at all — the control is "
               "absent or no longer answers on this section, so nothing was evaluated")

    failures = []
    joined = "\n".join(ctl_lines)

    # Leg 1 — the planted disagreement is named.
    named = [l for l in ctl_lines if DESYNC_ID in l]
    if not named:
        failures.append("leg1: %s sits in completed/ with status='started-work' and CTL-028 did "
                        "not name it; the drift class is no longer detected" % DESYNC_ID)
    elif "started-work" not in named[0]:
        failures.append("leg1: %s named but the observed status is not reported: %r"
                        % (DESYNC_ID, named[0]))

    # Leg 2 — anti-vacuity in BOTH directions. A control that names everything is as useless as
    # one that names nothing, and only these two legs together make green a classification.
    if any(CLEAN_ID in l for l in ctl_lines):
        failures.append("leg2: %s is correctly closed and was flagged anyway — CTL-028 is not "
                        "discriminating on status" % CLEAN_ID)
    if any(ACTIVE_ID in l for l in ctl_lines):
        failures.append("leg2: %s is in active/ and in flight; flagging it would make every "
                        "open task a finding" % ACTIVE_ID)

    # Leg 3 — the control answers on the section this probe asks for. Guards the re-gating
    # failure that made 263 real firings invisible.
    if not any(DESYNC_ID in l or "All completed/ tasks" in l for l in ctl_lines):
        failures.append("leg3: CTL-028 produced output but neither a finding nor its clean line; "
                        "the section gate may have moved (audit.sh:3721)")

    # Leg 4 — the remedy it prints does not lead with a gate bypass. CTL-028's mitigation offers
    # `--force`; an agent reading it under an autonomous directive must not be steered there when
    # the clean path (fw task update through the gates) works.
    if re.search(r'--force[^\n]*\bor\b', joined) and "hand-edit" not in joined:
        failures.append("leg4: the printed remedy offers --force without naming a non-bypass "
                        "alternative")

    print("T-536 status-desync teeth — CTL-028 emitted %d line(s)" % len(ctl_lines))
    for l in ctl_lines:
        print("    %s" % l[:150])
    legs = 5
    if failures:
        print("\n%d/%d legs FAILED:" % (len(failures), legs))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\n%d/%d legs green" % (legs, legs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
