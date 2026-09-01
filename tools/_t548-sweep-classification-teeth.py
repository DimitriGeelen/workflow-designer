#!/usr/bin/env python3
"""T-548 teeth — "it broke" and "I never found out" are different claims.

`_t509-instrument-sweep.sh` counted every non-zero exit as a regression and
announced each one as

    SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:
      - _t525-fabric-coverage-teeth.py (rc=124)
    ...a red here is a real regression in the thing it guards.

124 is GNU timeout's exit code. T-543 measured the case: _t525 costs 86.04s
against a 90s cap and passes 7/7 standalone, so it crosses whenever the machine
is busy. Nothing regressed in fabric coverage; the sweep was killed before it
could find out, and then asserted a finding about what it had not measured.

rc=2 is the same error with a longer history. The sweep's own exclusion list
argues that _t364 "exits 2 BY DESIGN, refusing to certify … converting that to
a suite failure would punish the honesty" — reasoning about a PROPERTY, written
into an exemption keyed on a FILENAME, so every other abstaining probe was still
called a regression.

This probe drives THE REAL SWEEP over synthetic instruments with known exit
codes and asserts, for each class, both the exit code and the words. Wording is
pinned deliberately: the defect was never in the arithmetic, it was in the
sentence, and a probe that checked only `rc` would have been green throughout
the entire period the tool was misreporting.

HERMETIC: the sweep is copied into a mktemp tree whose `tools/` holds only
synthetic probes, so ROOT resolves there ($0/..) and the real repository is
never scanned, written, or left with stray files.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SWEEP = ROOT / "tools" / "_t509-instrument-sweep.sh"

# The phrases that must never appear over a timeout or an abstention. Read out of
# the sweep itself rather than re-typed, so this cannot keep passing after the
# real sentence changes.
REGRESSION_PHRASES = [
    "an instrument that passed on",
    "a real regression in the thing it guards",
]


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def excluded_names(src: str) -> list[str]:
    """The sweep exits 1 on a stale exclusion BEFORE running anything, so the
    synthetic tree must contain a file for each excluded name or every scenario
    would return the same 1 for the same wrong reason."""
    block = src.split("EXCLUDE=(", 1)
    if len(block) != 2:
        refuse("could not find the EXCLUDE=( list in the sweep — the synthetic "
               "tree cannot be built without knowing which names it demands")
    names = re.findall(r'^"([^|"]+)\|', block[1].split(")\n", 1)[0], re.M)
    if not names:
        refuse("EXCLUDE=( parsed to zero names; a synthetic tree missing them "
               "would trip the stale-exclusion exit and every leg would read "
               "the same failure regardless of what it was testing")
    return names


PROBES = {
    "pass":    "#!/bin/bash\nexit 0\n",
    "abstain": "#!/bin/bash\nexit 2\n",
    "regress": "#!/bin/bash\nexit 1\n",
    "hang":    "#!/bin/bash\nsleep 30\n",
    "slow":    "#!/bin/bash\nsleep 3\nexit 0\n",
    # T-666. rc 4 is a DEAD CONTROL: the probe's own unmutated control leg ran and
    # failed, so nothing below it proves anything. It used to be spelled `exit 2`,
    # which put it in the same bucket as a parameterised probe honestly declining —
    # and the sweep's abstention text then told the reader, correctly for the one
    # case and backwards for the other, not to treat it as a regression.
    "dead":    "#!/bin/bash\necho 'TEETH BROKEN — the UNMUTATED copy fails, so no "
               "mutation below proves anything.'\nexit 4\n",
}


def run_scenario(kinds, timeout, src, names):
    """Build a mktemp tree containing only `kinds`, run the REAL sweep in it."""
    tmp = Path(tempfile.mkdtemp(prefix="t548-"))
    try:
        tools = tmp / "tools"
        tools.mkdir()
        shutil.copy2(SWEEP, tools / SWEEP.name)
        for n in names:                      # satisfy the stale-exclusion check
            (tools / n).write_text("#!/bin/bash\nexit 0\n")
        for k in kinds:
            p = tools / ("_t548-fake-%s-teeth.sh" % k)
            p.write_text(PROBES[k])
            p.chmod(0o755)
        env = dict(os.environ, T509_TIMEOUT=str(timeout))
        r = subprocess.run(["bash", str(tools / SWEEP.name)],
                           capture_output=True, text=True, timeout=180, env=env)
        return r.returncode, r.stdout + r.stderr
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    if not SWEEP.is_file():
        refuse("%s not found — nothing to drive" % SWEEP)
    src = SWEEP.read_text(encoding="utf-8")
    for phrase in REGRESSION_PHRASES:
        if phrase not in src:
            refuse("the sweep no longer contains the phrase %r that this probe "
                   "asserts is withheld from timeouts and abstentions. Either "
                   "the wording moved or the branch went — re-derive rather "
                   "than trust a green." % phrase)
    names = excluded_names(src)

    failures = []

    def check(label, kinds, timeout, want_rc, must, must_not):
        rc, out = run_scenario(kinds, timeout, src, names)
        if rc != want_rc:
            meaning = {0: "everything ran and passed", 1: "a genuine regression",
                       2: "a refusal to establish a population",
                       3: "no regression, but not everything was covered"}
            failures.append(
                "%s: sweep exited %d (%s), expected %d (%s). The exit code is "
                "the only signal a caller gets without parsing prose.\n"
                "      output: %s"
                % (label, rc, meaning.get(rc, "undefined"), want_rc,
                   meaning.get(want_rc, "undefined"), out.strip()[-400:]))
        for m in must:
            if m not in out:
                failures.append("%s: output never says %r — the reader is not "
                                "told which class this is." % (label, m))
        for m in must_not:
            if m in out:
                failures.append(
                    "%s: output asserts %r. That sentence is FALSE here — "
                    "nothing regressed, and it sends the reader hunting a bug "
                    "that does not exist." % (label, m))
        return out

    # ── Leg 1 — the control. All green must stay green, or every other leg is
    #    just measuring a broken sweep.
    check("all-pass", ["pass"], 10, 0,
          ["SWEEP PASS"], ["SWEEP FAIL", "SWEEP INCOMPLETE"])

    # ── Leg 2 — the reported defect: a probe killed by timeout.
    check("did-not-finish", ["pass", "hang"], 2, 3,
          ["DID NOT FINISH", "SWEEP INCOMPLETE"], REGRESSION_PHRASES)

    # ── Leg 3 — abstention. The sweep's exclusion list already argues this for
    #    one file by name; the classifier must hold it for the class.
    check("abstained", ["pass", "abstain"], 10, 3,
          ["ABSTAINED", "SWEEP INCOMPLETE"], REGRESSION_PHRASES)

    # ── Leg 4 — a genuine regression must still be called one, loudly. A repair
    #    that softened everything into "incomplete" would be worse than the bug.
    check("regressed", ["pass", "regress"], 10, 1,
          ["SWEEP FAIL"] + REGRESSION_PHRASES, ["SWEEP PASS"])

    # ── Leg 5 — precedence. With both present, the regression is the verdict
    #    (rc 1, not 3), and the timeout is STILL reported rather than swallowed
    #    by the louder finding.
    out = check("regression-and-timeout", ["regress", "hang"], 2, 1,
                ["SWEEP FAIL"], [])
    if "DID NOT FINISH" not in out:
        failures.append(
            "leg5: a regression and a timeout occurred together and only the "
            "regression was reported. The timeout is not noise to be swallowed "
            "by the louder finding — it is an instrument nobody heard from.")

    # ── Leg 6 — the leading indicator. _t525 sat at 95.6% of budget for weeks
    #    and the first thing anyone heard was a false regression report. A
    #    nearly-spent budget has to be visible while the run is still GREEN.
    out = check("headroom", ["slow"], 4, 0, ["HEADROOM WARNING"], ["SWEEP FAIL"])
    if "_t548-fake-slow-teeth.sh" not in out.split("HEADROOM WARNING", 1)[-1]:
        failures.append(
            "leg6: HEADROOM WARNING fired but does not name the instrument that "
            "is running out of budget, which is the only actionable part.")
    out = check("headroom-quiet", ["pass"], 10, 0, ["SWEEP PASS"], [])
    if "HEADROOM WARNING" in out:
        failures.append(
            "leg6b: HEADROOM WARNING fired for an instrument that used none of "
            "its budget. A warning that is always on is not a warning.")

    # ── Leg 7 (T-666) — a DEAD CONTROL is not an abstention. This is the leg the
    #    six above could not have caught: `exit 2` was a legal, documented, green-
    #    looking way to say "my control is broken", and _t358-teeth.py said it on
    #    every sweep run for six days while the sweep printed "ABSTAINED … rather
    #    than treating this as a regression in what it guards" (T-665).
    #
    #    must_not carries BOTH mislabels, because there are two ways to get this
    #    wrong and only one of them is the old bug: filing it as an abstention
    #    (too quiet — a state that needs no action) or filing it as a regression
    #    in the guarded thing (too loud, and a claim this run cannot make, since a
    #    dead control measured nothing about the subject either way).
    out = check("dead-control", ["pass", "dead"], 10, 1,
                ["DEAD CONTROL", "SWEEP FAIL"], ["ABSTAINED"] + REGRESSION_PHRASES)
    if "_t548-fake-dead-teeth.sh" not in out.split("DEAD CONTROL", 1)[-1]:
        failures.append(
            "leg7: DEAD CONTROL fired but does not name the broken instrument. "
            "A sweep that says an unnamed guard is dead has moved the search "
            "problem, not solved it.")

    # ── Leg 8 (T-666) — precedence and coexistence, the same argument as leg 5.
    #    A dead control and an honest abstention in one run must BOTH be reported
    #    and must not be merged: the exit code follows the dead control (1, a
    #    finding), and the abstention still appears by name.
    out = check("dead-and-abstain", ["dead", "abstain"], 10, 1,
                ["DEAD CONTROL", "ABSTAINED"], REGRESSION_PHRASES)
    if out.count("_t548-fake-dead-teeth.sh") == 0 or "_t548-fake-abstain-teeth.sh" not in out:
        failures.append(
            "leg8: a dead control and an abstention occurred together and one of "
            "them was not named. These are the two states this task exists to "
            "keep apart; collapsing them under load is the defect returning.")

    if failures:
        print("T-548 TEETH: %d finding(s)" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("T-548/T-666 TEETH: 8 legs green — the sweep distinguishes regressed (1) "
          "and dead-control (1, its own bucket) from did-not-finish and abstained "
          "(3) from passed (0), says which in words, withholds the regression "
          "claim from all three, never files a dead control as an abstention, "
          "keeps a real regression loud, and names an instrument running out of "
          "budget while it is still passing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
