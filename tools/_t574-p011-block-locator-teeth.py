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
# T-943: extraction moved OUT of update-task.sh and into this shared helper under T-3232.
LIB = os.path.join(ROOT, ".agentic-framework", "lib", "verification-port.sh")

# ---------------------------------------------------------------------------
# T-943 RESTRUCTURE — why the behavioural legs now run FIRST and unconditionally
# ---------------------------------------------------------------------------
# This probe used to `die()` when it could not find an exact source line in
# update-task.sh, on the reasoning that a refactor should break it LOUDLY rather
# than let it silently stop testing. The reasoning was right and the
# implementation still cost us the finding:
#
#   2026-08-22  b17e49fa  T-575 lands the exact-heading refusal in the VENDORED gate
#   2026-09-25  7b5e227e  "upgraded to AEF bleeding-edge 1.7.68" overwrites the file
#   2026-09-25  ...       this probe starts printing ABORT: "the locator is GONE"
#   2026-09-30  T-943     someone runs the suite and reads it
#
# ABORT was loud about the WRONG THING. It said "I cannot test this" and said
# nothing about whether the protection still worked — so for five days the only
# available reading was a red line in a twenty-failure suite that gates no
# release. A probe that cannot answer its own question when an anchor moves is a
# probe whose value depends on its anchors never moving.
#
# So the split is now explicit:
#   BEHAVIOURAL legs  — fixtures in, exit codes and output out. No source anchors.
#                       These answer "does the protection work?" and they survive
#                       any refactor, any re-vendor, any reimplementation.
#   MUTATION legs     — require a source anchor, and prove the FIXTURES
#                       DISCRIMINATE (that they would go red if the fix were
#                       removed). If the anchor has moved, that proof is
#                       unavailable, and the probe reports a FAILED leg saying
#                       exactly that — while still reporting everything the
#                       behavioural legs learned.
# Both must pass. A missing anchor is still red, because CANNOT RUN is not a
# pass — but it is now red WITH an answer attached instead of instead of one.

# Mutation anchors, in the LIB where the logic actually lives.
LIB_EXACT_AWK = "/^## Verification[[:space:]]*$/ { if (!seen) { seen=1; inblk=1 }; next }"
LIB_RC3_RETURN = "            return 3"

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


def run_gate(gate_src, fixture_text, tid, lib_src=None):
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

        # T-943: extraction lives in lib/verification-port.sh since T-3232, and
        # run_verification_commands hard-refuses if extract_verification_block is
        # not defined. Source the lib (a possibly-MUTATED copy) so the harness
        # exercises the real two-layer path rather than a stub of either half.
        lib_path = os.path.join(td, "verification-port.sh")
        with open(lib_path, "w", encoding="utf-8") as f:
            f.write(lib_src if lib_src is not None else open(LIB, encoding="utf-8").read())

        harness = (
            "set -uo pipefail\n"
            "RED=''; GREEN=''; YELLOW=''; CYAN=''; NC=''\n"
            "SKIP_VERIFICATION=false\n"
            'PROJECT_ROOT="%s"\n'
            'TASK_FILE="%s"\n'
            'FRAMEWORK_ROOT="%s"\n'
            "log_gate_bypass() { :; }\n"
            'source "%s"\n'
            "%s\n"
            "run_verification_commands\n"
            'echo "GATE_RC=$?"\n'
            % (td, task_path, os.path.join(ROOT, ".agentic-framework"), lib_path, func)
        )
        harness_path = os.path.join(td, "harness.sh")
        with open(harness_path, "w", encoding="utf-8") as f:
            f.write(harness)
        p = subprocess.run(
            ["bash", harness_path], capture_output=True, text=True, timeout=120
        )
        out = p.stdout + p.stderr
        rc_m = re.search(r"GATE_RC=(\d+)", out)
        # T-943: the refusal paths call `exit 1`, which ends the harness shell
        # before it can echo GATE_RC. Falling back to the process status is not a
        # convenience — without it every REFUSING fixture reported rc=None, which
        # is unequal to 1 and so read as "did not refuse". The probe would have
        # gone red on a working gate and blamed the gate.
        rc = int(rc_m.group(1)) if rc_m else p.returncode
        return rc, out


def evaluate(gate_src, lib_src=None):
    """Return {fixture: (rc, out)} for every fixture."""
    res = {}
    for name, text in FIXTURES.items():
        rc, out = run_gate(gate_src, text, "T-999", lib_src=lib_src)
        res[name] = (rc, out)
    return res


def main():
    if not os.path.exists(GATE):
        die("gate not found: %s" % GATE)
    with open(GATE, encoding="utf-8") as f:
        clean = f.read()

    if not os.path.exists(LIB):
        die("extraction lib not found: %s" % LIB)
    with open(LIB, encoding="utf-8") as f:
        lib_clean = f.read()

    print("== control: unmutated gate (T-560 — a harness that fails on everything")
    print("   would satisfy 'every mutant died' equally well) ==")
    base = evaluate(clean)

    rc, out = base["wellformed"]
    leg(
        "control-wellformed",
        rc == 0 and "Running 2 verification command(s)" in out,
        "well-formed block runs and REPORTS ITS COUNT (rc=%s)" % rc,
    )

    rc, out = base["absent"]
    leg(
        "control-absent",
        # T-1005: 1.7.740 says the zero in its own words (T-3546: "Verification: skipped — no
        # '## Verification' section"); our T-943 wording went out with the re-vendor. The
        # property is that the zero is SAID, not which sentence says it — accept either.
        rc == 0 and ("Running 0 verification command(s)" in out
                     or "Verification: skipped" in out or "Verification: 0 commands" in out),
        "no section → pass-through, and SAYS zero (rc=%s)" % rc,
    )

    rc, out = base["t572-inline"]
    leg(
        "t572-refused",
        rc == 1 and "COULD NOT READ THE BLOCK" in out,
        "mid-line heading (the real T-572 shape) is REFUSED, not silently passed (rc=%s)" % rc,
    )

    # T-943 CHANGED THIS EXPECTATION, deliberately. It previously required the
    # T-542 shape to be REFUSED, which is what the pre-T-3232 gate did: its prefix
    # anchor opened the range on `## Verification of the probe itself`, fed the
    # shell a markdown table, and refused loudly. Refusing was the best available
    # outcome for a locator that had picked the wrong heading — it was never the
    # right outcome for the DOCUMENT, which is perfectly well-formed and contains
    # an exact heading further down.
    #
    # The exact-match anchor resolves it correctly, so the correct assertion is now
    # that the real block RUNS. Encoding "refuses" would pin the old defect's
    # symptom as a requirement and block the fix that removed it — a guard
    # asserting the bug (PL-159 class). The mutant below still proves the exact
    # anchor is load-bearing.
    rc, out = base["t542-prefix"]
    leg(
        "t542-resolves",
        rc == 0 and "Running 2 verification command(s)" in out,
        "prefix-heading-above-real-heading (T-542 shape) resolves to the CORRECT "
        "block and runs both legs (rc=%s)" % rc,
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
    # MUTATION legs (T-943). These prove the fixtures DISCRIMINATE — that they
    # would go red if the protection were removed. Unlike the behavioural legs
    # above, they need a source anchor, so a moved anchor costs us this proof and
    # nothing else. That is reported as a failing leg rather than an ABORT: the
    # old ABORT threw away the behavioural answer too, which is how five days
    # passed with the gate open and the only signal being "I cannot test this".
    # ----------------------------------------------------------------------
    print()
    print("== mutant: remove the rc=3 malformed-heading refusal (reproduces the")
    print("   state the 1.7.68 re-vendor left us in on 2026-09-25) ==")

    if LIB_RC3_RETURN not in lib_clean:
        leg(
            "mutation-anchor-rc3",
            False,
            "ANCHOR MOVED: %r is no longer in %s, so the discrimination proof is "
            "unavailable — this leg says nothing about whether the protection works. "
            "READ THE BEHAVIOURAL LEGS ABOVE for that: if they are green the fix was "
            "refactored and this anchor needs updating; if t572-refused is red the "
            "protection itself is gone. Do not infer either from this line."
            % (LIB_RC3_RETURN, os.path.relpath(LIB, ROOT)),
        )
    else:
        mutant_lib = lib_clean.replace(LIB_RC3_RETURN, "            return 0", 1)
        # A mutation that changed nothing would make every mutant leg below fail
        # for a reason that has nothing to do with the gate. Assert the patch bit,
        # so the red line names the harness rather than the subject (T-849/PL-339:
        # a mutation harness without this cannot tell 'fix removed' from 'script
        # broken'). The old version of this probe had the guard; T-943's first
        # draft dropped it, and that is how this one was found.
        leg(
            "mutation-applied-rc3",
            mutant_lib != lib_clean,
            "the rc=3 patch actually changed the lib source",
        )
        mres = evaluate(clean, lib_src=mutant_lib)

        m_t572_rc, m_t572_out = mres["t572-inline"]
        leg(
            "mutant-kills-t572",
            m_t572_rc == 0 and "COULD NOT READ" not in m_t572_out,
            "without rc=3 the T-572 fixture passes SILENTLY (rc=%s) — the defect reproduces"
            % m_t572_rc,
        )

        m_wf_rc, m_wf_out = mres["wellformed"]
        leg(
            "mutant-spares-wellformed",
            m_wf_rc == 0 and "Running 2 verification command(s)" in m_wf_out,
            "the well-formed case still passes — the mutant is TARGETED, not broad",
        )

        m_ab_rc, _ = mres["absent"]
        leg(
            "mutant-spares-absent",
            m_ab_rc == 0,
            "the absent case still passes — the mutant reddens only what it owns",
        )

    # Second mutant: the EXACT-match anchor itself, which is T-574's original
    # fix rather than T-943's. Reverting it to a prefix match is what let T-542's
    # `## Verification of the probe itself` open the range on the wrong heading.
    print()
    print("== mutant: relax the exact-heading anchor to a prefix match (reverts T-574) ==")
    if LIB_EXACT_AWK not in lib_clean:
        leg(
            "mutation-anchor-exact",
            False,
            "ANCHOR MOVED: the exact-heading awk line is no longer in %s. Behavioural "
            "legs above are unaffected; re-anchor this one."
            % os.path.relpath(LIB, ROOT),
        )
    else:
        relaxed = lib_clean.replace(
            LIB_EXACT_AWK,
            "/^## Verification/ { if (!seen) { seen=1; inblk=1 }; next }",
            1,
        )
        leg(
            "mutation-applied-exact",
            relaxed != lib_clean,
            "the prefix-anchor patch actually changed the lib source",
        )
        rres = evaluate(clean, lib_src=relaxed)
        r_t542_rc, r_t542_out = rres["t542-prefix"]
        leg(
            "mutant-breaks-t542",
            not (r_t542_rc == 1 and "COULD NOT READ" in r_t542_out),
            "a prefix anchor stops refusing the T-542 shape correctly (rc=%s) — "
            "T-574's exact match is load-bearing" % r_t542_rc,
        )
        r_wf_rc, r_wf_out = rres["wellformed"]
        leg(
            "relaxed-spares-wellformed",
            r_wf_rc == 0 and "Running 2 verification command(s)" in r_wf_out,
            "the well-formed case is unaffected by the relaxation — targeted mutant",
        )

    print()
    print("%d passed, %d failed" % (TOTAL_LEGS - len(FAILS), len(FAILS)))
    if FAILS:
        print("FAILED: %s" % ", ".join(FAILS))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
