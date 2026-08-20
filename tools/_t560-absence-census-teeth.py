#!/usr/bin/env python3
"""T-560 teeth — the absence-assertion census must discriminate, not merely count.

WHY THIS EXISTS. A census that reports "81 uncontrolled" is indistinguishable, from
the outside, from one that reports 81 because it flags EVERY absence leg, or because
its control detector always returns NONE. Both would produce a plausible number and a
green ratchet. These legs pin the two edges the number sits between:

  * a genuinely uncontrolled absence leg must be FLAGGED (leg 1) and must make the
    ratchet FAIL rather than merely print (leg 4)
  * an absence leg WITH a positive control must NOT be flagged (leg 2)
  * a presence assertion must not be swept in at all (leg 3)

Leg 2 is the one that matters most and is the easiest to lose. Without it, "flag
everything" passes leg 1, leg 3 and leg 4, and the tool becomes noise that readers
learn to ignore — which is how a gate dies without anyone deleting it (OBS-293).

Leg 5 is the anti-override leg. The census honours `T560_TASK_ROOT` so these teeth can
plant mutants outside the live `.tasks/` tree; leg 5 runs it with no override and
requires the real corpus back, so the door cannot be left open unnoticed.

THE OVER-CREDITING THIS ALREADY CAUGHT, recorded because it is the reason leg 2 is
written the way it is: the first control detector accepted any sibling leg whose TEXT
CONTAINED the pattern. It scored 13 legs PATTERN-controlled. Requiring the pattern to
BE the sibling's grep pattern dropped that to 4 — so the loose rule was hiding nine
real findings while reporting them as covered. Mention is not invocation.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENSUS = os.path.join(ROOT, "tools", "_t560-absence-assertion-census.py")

TASK_HEAD = """---
id: %s
name: "teeth fixture"
status: started-work
workflow_type: build
owner: agent
---

# %s

## Verification

%s
"""

# Leg text is assembled rather than written out flat: this file lives in tools/ and
# other censuses in this repo scan tools/. Nothing here should read as a live
# assertion about the real tree.
_Q = "'"
UNCONTROLLED = "! grep -q %sTEETH_SENTINEL_ALPHA%s src/aef-workflow-designer.html" % (_Q, _Q)
CONTROLLED_A = "! grep -q %sTEETH_SENTINEL_BETA%s src/aef-workflow-designer.html" % (_Q, _Q)
CONTROLLED_B = "grep -q %sTEETH_SENTINEL_BETA%s tests/fixtures/teeth-beta.txt" % (_Q, _Q)
PRESENCE = "grep -q %sTEETH_SENTINEL_GAMMA%s src/aef-workflow-designer.html" % (_Q, _Q)

NONE_RX = re.compile(r"NONE\s+\(nothing proves the search could succeed\)\s*:\s*(\d+)")
TOTAL_RX = re.compile(r"executable legs examined\s*:\s*(\d+)")


def run_census(task_root=None):
    env = dict(os.environ)
    if task_root:
        env["T560_TASK_ROOT"] = task_root
    else:
        env.pop("T560_TASK_ROOT", None)
    p = subprocess.run([sys.executable, CENSUS], cwd=ROOT, capture_output=True,
                       text=True, env=env)
    return p.returncode, p.stdout + p.stderr


def plant(tmp, task_id, legs):
    d = os.path.join(tmp, "active")
    os.makedirs(d, exist_ok=True)
    os.makedirs(os.path.join(tmp, "completed"), exist_ok=True)
    with open(os.path.join(d, "%s-teeth.md" % task_id), "w") as fh:
        fh.write(TASK_HEAD % (task_id, task_id, legs))


def uncontrolled_count(out):
    m = NONE_RX.search(out)
    return int(m.group(1)) if m else None


def main():
    if not os.path.isfile(CENSUS):
        print("REFUSE: %s is missing, so nothing was evaluated." % CENSUS)
        return 2

    failures = []
    tmp = tempfile.mkdtemp(prefix="t560-teeth-")
    try:
        # ── Leg 1: an uncontrolled absence leg IS flagged ────────────────────────
        plant(tmp, "T-901", UNCONTROLLED)
        rc, out = run_census(tmp)
        n1 = uncontrolled_count(out)
        if n1 == 1:
            print("  PASS  1 an uncontrolled absence assertion is flagged")
        else:
            failures.append("leg 1: expected exactly 1 uncontrolled finding, census "
                            "reported %r — the detector does not detect" % n1)

        # ── Leg 2: the SAME leg with a positive control is NOT flagged ───────────
        # This is the discrimination arm. If it goes green while leg 1 also goes
        # green, the tool is classifying rather than counting.
        shutil.rmtree(tmp)
        tmp = tempfile.mkdtemp(prefix="t560-teeth-")
        plant(tmp, "T-902", CONTROLLED_A + "\n" + CONTROLLED_B)
        rc, out = run_census(tmp)
        n2 = uncontrolled_count(out)
        if n2 == 0:
            print("  PASS  2 an absence assertion with a positive control is NOT flagged")
        else:
            failures.append("leg 2: a controlled absence assertion was flagged (%r "
                            "uncontrolled) — the tool flags everything, which is noise "
                            "rather than a gate" % n2)

        # ── Leg 3: a presence assertion is not swept in ──────────────────────────
        shutil.rmtree(tmp)
        tmp = tempfile.mkdtemp(prefix="t560-teeth-")
        plant(tmp, "T-903", PRESENCE)
        rc, out = run_census(tmp)
        n3 = uncontrolled_count(out)
        if n3 == 0:
            print("  PASS  3 a presence assertion is not classified as absence")
        else:
            failures.append("leg 3: a plain `grep -q` presence leg was counted as an "
                            "absence assertion (%r)" % n3)

        # ── Leg 4: exceeding the baseline must FAIL, not print ───────────────────
        # A finding that does not change the verdict is a log line. The live baseline
        # is 78; a synthetic tree of 82 uncontrolled legs must exit 1.
        shutil.rmtree(tmp)
        tmp = tempfile.mkdtemp(prefix="t560-teeth-")
        many = "\n".join(
            "! grep -q 'TEETH_SENTINEL_%03d' src/aef-workflow-designer.html" % i
            for i in range(82)
        )
        plant(tmp, "T-904", many)
        rc, out = run_census(tmp)
        n4 = uncontrolled_count(out)
        if rc == 1 and n4 == 82:
            print("  PASS  4 exceeding the ratchet baseline exits 1, not 0")
        else:
            failures.append("leg 4: 82 uncontrolled legs against a baseline of 81 gave "
                            "rc=%d, count=%r — the ratchet does not bite" % (rc, n4))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    # ── Leg 5: with NO override the census reports the REAL corpus ───────────────
    rc, out = run_census(None)
    m = TOTAL_RX.search(out)
    total = int(m.group(1)) if m else -1
    if rc == 0 and total > 1000:
        print("  PASS  5 with no override the census reads the live corpus (%d legs) "
              "and is green" % total)
    else:
        failures.append("leg 5: unoverridden run gave rc=%d over %d legs — either the "
                        "live corpus regressed or T560_TASK_ROOT leaked" % (rc, total))

    if failures:
        print()
        for f in failures:
            print("FAIL: %s" % f)
        return 1

    print()
    print("T-560 TEETH: 5/5 legs passed — the census flags an uncontrolled absence "
          "assertion, does NOT flag one carrying a positive control, does not sweep in "
          "presence assertions, fails rather than notes when the baseline is exceeded, "
          "and reads the live corpus when not overridden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
