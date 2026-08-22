#!/usr/bin/env python3
"""_t574-p011-block-locator-teeth — the P-011 gate must never pass silently on
a block it could not read.

WHAT THIS GUARDS
----------------
`run_verification_commands` in the vendored `update-task.sh` located its block
with `sed -n '/^## Verification/,/^## /p'` and then did:

    [ -z "$verify_cmds" ] && return 0

A silent pass. Its output was byte-identical to a run that executed every leg
and found no fault. T-572 completed that way with ALL TEN of its legs unrun.

`^## Verification` is a PREFIX match and it fails in two OPPOSITE ways, both
observed in this repo one day apart:

  T-572  a backticked mention of the heading inside an acceptance criterion
         glued the real heading to the end of that line. `^## Verification`
         never matched, sed returned zero lines, the gate PASSED SILENTLY.

  T-542  `## Verification of the probe itself` sat ABOVE `## Verification`.
         The prefix match opened the range on the wrong heading and fed the
         shell a markdown table. It REFUSED — loudly.

Only one of those announces itself. This probe holds both, plus the states
either side of them.

WHY A CONTROL RUN COMES FIRST (T-560)
-------------------------------------
"Every mutant died" is equally satisfied by a harness that fails on everything.
Leg 0 runs the gate against UNMUTATED source and requires the well-formed case
to PASS. Without it, a probe that reddens unconditionally would report perfect
discrimination.

WHY THE MUTANT ASSERTS ITS LEG SET, NOT JUST "SOMETHING WENT RED"
-----------------------------------------------------------------
Reverting the fix must redden the malformed legs and ONLY those. A mutant that
reddens more than it owns is not discriminating — it is just breaking things.

Run:  python3 tools/_t574-p011-block-locator-teeth.py
Exit: 0 all legs pass, 1 otherwise. CANNOT RUN is not a pass.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GATE = os.path.join(ROOT, ".agentic-framework", "agents", "task-create", "update-task.sh")

# The anchors the mutant reverts. Kept as exact source text so a refactor that
# moves this logic breaks the probe LOUDLY rather than letting it silently stop
# testing anything (PL-148: an instrument's registration must be asserted by
# something other than the instrument).
NEW_ANCHOR = "    _v_exact=$(grep -c '^## Verification[[:space:]]*$' \"$TASK_FILE\" 2>/dev/null || true)"
NEW_EXTRACT = (
    "    verify_section=$(awk -v start=\"$_v_exact_ln\" "
    "'NR>start { if ($0 ~ /^## /) exit; print }' \"$TASK_FILE\" 2>/dev/null)"
)
OLD_EXTRACT = (
    "    verify_section=$(sed -n '/^## Verification/,/^## /p' \"$TASK_FILE\" 2>/dev/null | sed '$d')\n"
    "    verify_section=$(echo \"$verify_section\" | tail -n +2)"
)

FAILS = []
TOTAL_LEGS = 0


def die(msg):
    print("ABORT: " + msg, file=sys.stderr)
    sys.exit(1)


def leg(name, ok, detail):
    global TOTAL_LEGS
    TOTAL_LEGS += 1
    tag = "PASS" if ok else "FAIL"
    print("%-4s  %-24s %s" % (tag, name, detail))
    if not ok:
        FAILS.append(name)


# --------------------------------------------------------------------------
# Fixtures. Four task files, differing ONLY in the shape of their Verification
# heading, so any behavioural difference is attributable to that and nothing
# else.
# --------------------------------------------------------------------------
HEAD = """---
id: {tid}
name: "fixture {tid}"
description: fixture
status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-08-22T00:00:00Z
last_update: 2026-08-22T00:00:00Z
date_finished: null
---

# {tid}: fixture

## Acceptance Criteria

### Agent
- [x] the only criterion, already met
"""

# 1. WELL-FORMED — one exact heading, two runnable legs.
WELLFORMED = HEAD + """
## Verification

true
true

## RCA
"""

# 2. ABSENT — no such section anywhere. Documented pass-through.
ABSENT = HEAD + """
## Decisions

nothing here
"""

# 3. T-572 SHAPE — the heading exists in the file but is GLUED to the end of an
#    AC line by a backticked mention of itself. This is the real defect, copied
#    in shape from the task that shipped with ten unrun legs. A fix that passes
#    only on a synthetic case has not been shown to catch this one.
T572 = HEAD + """- [x] the commands live in the `## Verification` section ## Verification

true
true

## RCA
"""

# 4. T-542 SHAPE — a heading that PREFIXES the real one, sitting above it.
T542 = HEAD + """
## Verification of the probe itself

| mutant | killed by |
|---|---|
| existence check removed | leg 3 |

## Verification

true
true

## RCA
"""

# 5. VERIFICATION IS THE FINAL SECTION. Not a heading-shape case — this pins an
#    INCIDENTAL defect the T-574 rewrite also removed, found by this probe's own
#    first red run. The old extraction ended `| sed '$d'`, which trims the range
#    terminator; when `## Verification` is the LAST section there IS no
#    terminator, so `$d` ate a real command instead. The old gate therefore ran
#    N-1 legs and reported N-1 as though that were the whole block — a
#    miscount that renders as health, which is the exact class T-574 exists for.
#    The new awk extraction has no terminator to trim and counts 2 here.
TRAILING = HEAD + """
## Verification

true
true
"""

FIXTURES = {
    "wellformed": WELLFORMED,
    "absent": ABSENT,
    "t572-inline": T572,
    "t542-prefix": T542,
    "trailing": TRAILING,
}


def run_gate(gate_src, fixture_text, tid):
    """Drive run_verification_commands against one fixture in a tmpdir.

    Sources the real gate file and calls the real function — the instrument
    must run the thing it describes (T-402/PL-204), not a reimplementation of
    it. Never touches the live tree.
    """
    with tempfile.TemporaryDirectory() as td:
        gate_path = os.path.join(td, "update-task.sh")
        with open(gate_path, "w", encoding="utf-8") as f:
            f.write(gate_src)
        task_path = os.path.join(td, "%s.md" % tid)
        with open(task_path, "w", encoding="utf-8") as f:
            f.write(fixture_text)

        # Extract just the function under test plus the colour vars it uses.
        # Sourcing the whole script would execute its argument parsing and exit.
        src = gate_src
        m = re.search(r"^run_verification_commands\(\) \{$", src, re.M)
        if not m:
            die("cannot find run_verification_commands() in the gate source")
        start = m.start()
        # Walk to the matching closing brace at column 0.
        rest = src[start:]
        end_m = re.search(r"^\}$", rest, re.M)
        if not end_m:
            die("cannot find the end of run_verification_commands()")
        func = rest[: end_m.end()]

        harness = (
            "set -uo pipefail\n"
            "RED=''; GREEN=''; YELLOW=''; CYAN=''; NC=''\n"
            "SKIP_VERIFICATION=false\n"
            'PROJECT_ROOT="%s"\n'
            'TASK_FILE="%s"\n'
            "log_gate_bypass() { :; }\n"
            "%s\n"
            "run_verification_commands\n"
            'echo "GATE_RC=$?"\n' % (td, task_path, func)
        )
        harness_path = os.path.join(td, "harness.sh")
        with open(harness_path, "w", encoding="utf-8") as f:
            f.write(harness)
        p = subprocess.run(
            ["bash", harness_path], capture_output=True, text=True, timeout=120
        )
        out = p.stdout + p.stderr
        rc_m = re.search(r"GATE_RC=(\d+)", out)
        rc = int(rc_m.group(1)) if rc_m else None
        return rc, out


def evaluate(gate_src, label):
    """Return {fixture: (rc, out)} for all four fixtures."""
    res = {}
    for name, text in FIXTURES.items():
        rc, out = run_gate(gate_src, text, "T-999")
        res[name] = (rc, out)
    return res


def main():
    if not os.path.exists(GATE):
        die("gate not found: %s" % GATE)
    with open(GATE, encoding="utf-8") as f:
        clean = f.read()

    if NEW_ANCHOR not in clean:
        die(
            "the T-574 exact-heading locator is GONE from update-task.sh.\n"
            "  This probe can no longer test what it claims to test, and that is a\n"
            "  failure, not a skip. Expected to find:\n    %s" % NEW_ANCHOR
        )
    if NEW_EXTRACT not in clean:
        die("the T-574 anchored awk extraction is GONE from update-task.sh")

    print("== control: unmutated gate (T-560 — a harness that fails on everything")
    print("   would satisfy 'every mutant died' equally well) ==")
    base = evaluate(clean, "control")

    rc, out = base["wellformed"]
    leg(
        "control-wellformed",
        rc == 0 and "Running 2 verification command(s)" in out,
        "well-formed block runs and REPORTS ITS COUNT (rc=%s)" % rc,
    )

    rc, out = base["absent"]
    leg(
        "control-absent",
        rc == 0 and "Running 0 verification command(s)" in out,
        "no section → pass-through, and SAYS zero (rc=%s)" % rc,
    )

    rc, out = base["t572-inline"]
    leg(
        "t572-refused",
        rc == 1 and "COULD NOT READ THE BLOCK" in out,
        "mid-line heading (the real T-572 shape) is REFUSED, not silently passed (rc=%s)" % rc,
    )

    rc, out = base["t542-prefix"]
    leg(
        "t542-refused",
        rc == 1 and "COULD NOT READ THE BLOCK" in out,
        "prefix heading (the real T-542 shape) is REFUSED (rc=%s)" % rc,
    )

    rc, out = base["trailing"]
    leg(
        "trailing-counts-all",
        rc == 0 and "Running 2 verification command(s)" in out,
        "## Verification as the FINAL section runs BOTH legs (old `sed '$d'` ate one)",
    )

    # The distinguishing assertion: absent and malformed must NOT render alike.
    _, absent_out = base["absent"]
    _, t572_out = base["t572-inline"]
    leg(
        "absent-vs-malformed",
        ("COULD NOT READ" not in absent_out) and ("COULD NOT READ" in t572_out),
        "'no section' and 'unreadable section' produce DIFFERENT output — the whole defect",
    )

    # ----------------------------------------------------------------------
    # Mutant: revert to the pre-T-574 prefix-sed locator. Must redden the two
    # malformed legs and ONLY those.
    # ----------------------------------------------------------------------
    print()
    print("== mutant: revert to the pre-T-574 `sed -n '/^## Verification/,/^## /p'` locator ==")
    mutant = clean.replace(NEW_EXTRACT, OLD_EXTRACT, 1)
    if mutant == clean:
        die("mutant patch was a no-op — the anchored extraction did not match")
    # Also restore the silent early return, which is the half that hides.
    mutant = mutant.replace(
        '    if [ -z "$verify_cmds" ]; then',
        '    [ -z "$verify_cmds" ] && return 0\n    if [ -z "$verify_cmds" ]; then',
        1,
    )
    # And disable the refusal, so the mutant behaves as the old gate did.
    mutant = mutant.replace('    if [ -n "$_v_why" ]; then', '    if false; then', 1)

    mres = evaluate(mutant, "mutant")

    m_t572_rc, m_t572_out = mres["t572-inline"]
    leg(
        "mutant-kills-t572",
        m_t572_rc == 0 and "COULD NOT READ" not in m_t572_out,
        "reverted gate passes the T-572 fixture SILENTLY (rc=%s) — the defect reproduces" % m_t572_rc,
    )

    m_wf_rc, m_wf_out = mres["wellformed"]
    leg(
        "mutant-spares-wellformed",
        m_wf_rc == 0 and "Running 2 verification command(s)" in m_wf_out,
        "reverted gate still passes the well-formed case — the mutant is TARGETED, not broad",
    )

    m_tr_rc, m_tr_out = mres["trailing"]
    leg(
        "mutant-undercounts-trailing",
        m_tr_rc == 0 and "Running 1 verification command(s)" in m_tr_out,
        "reverted gate runs only 1 of 2 legs when Verification is last — the `sed '$d'` bug reproduces",
    )

    m_ab_rc, _ = mres["absent"]
    leg(
        "mutant-spares-absent",
        m_ab_rc == 0,
        "reverted gate still passes the absent case — mutant reddens only what it owns",
    )

    print()
    print("%d passed, %d failed" % (TOTAL_LEGS - len(FAILS), len(FAILS)))
    if FAILS:
        print("FAILED: %s" % ", ".join(FAILS))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
