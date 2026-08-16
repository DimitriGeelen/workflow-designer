#!/usr/bin/env python3
"""T-550 teeth — a stale anchor does not go quiet, it rebinds onto the archive of its own past.

`tools/_t344-watch-set-denominator.sh` leg 8 compares the audit's two fabric coverage counts.
It read them out of the whole report with `sed ... | head -1`, anchored on the literal text
`unregistered (of N watched)`.

T-525 changed that finding to `(of N watched — P% covered, <direction>)`. The anchor stopped
matching the line it was written for and DID NOT STOP MATCHING, because the report's TREND
ANALYSIS section reprints recurring findings from the last 14 days verbatim, in the shape they
had when recorded. The first match became a fortnight-old aggregate:

    - Fabric: 40 registered, 185 unregistered (of 222 watched) (7 times)

which was then compared against today's drift count. Measured on 2026-08-16: the guard printed
`the two coverage checks DISAGREE (185 vs 199)` on a day both live checks said 199.

The original code guarded the case where the anchor matches NOTHING, and says so in a comment.
It could not have guarded this, because the failure was not silence — the report contains a
copy of every sentence it used to print, so there is always something for a stale anchor to
find, and what it finds looks exactly like data.

The error is not directionally safe. Here it manufactured a false RED. On any day the
historical aggregate happens to equal today's drift count it manufactures a false GREEN, which
is the same defect with nobody looking at it.

These legs drive the REAL guard through T344_AUDIT_TRANSCRIPT over recorded reports this tree
cannot produce on demand: a trend echo that disagrees with the live finding, a genuine
disagreement, a stale anchor with no live finding at all, and full coverage. Transcripts are
built from the audit's actual output shape, and leg 5 pins that shape against the live audit so
these fixtures cannot quietly stop resembling the thing they stand in for.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# T550_GUARD points the legs at a copy of the guard. It exists so the pre-T-550 parse can be
# reconstructed in a temp file and shown to turn these legs RED — without editing the real
# guard, which is a tracked file carrying an uncommitted fix. A control that has never been
# shown to fail is a control nobody has tested (PL-206).
GUARD = os.environ.get("T550_GUARD") or os.path.join(ROOT, "tools",
                                                     "_t344-watch-set-denominator.sh")

# The exact line the trend section reprints, in the PRE-T-525 shape. Kept verbatim from the
# real report rather than paraphrased — it is the stimulus, and a paraphrase of a stimulus is
# a different stimulus.
TREND_ECHO = "  - Fabric: 40 registered, 185 unregistered (of 222 watched) (7 times)"


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def transcript(coverage_line, drift_line, trend=True):
    """A report shaped like `fw audit --section structure` output."""
    parts = ["=== AUDIT REPORT ===",
             "Timestamp: 2099-01-01T00:00:00+00:00",
             "Project: /synthetic",
             "",
             "=== STRUCTURE CHECKS ===",
             "[PASS] Tasks directory exists"]
    if coverage_line:
        parts.append(coverage_line)
    if drift_line:
        parts.append(drift_line)
    parts += ["", "=== SUMMARY ===", "Pass: 20", "Warn: 3", "Fail: 0", ""]
    if trend:
        parts += ["=== TREND ANALYSIS ===",
                  "Repeated issues detected in last 14 days (candidates for practice):",
                  TREND_ECHO,
                  "  - Fabric drift: 189 source file(s) have no fabric card (8 times)",
                  ""]
    parts.append("=== END AUDIT ===")
    return "\n".join(parts) + "\n"


def run_guard(text):
    """Run the real guard over a recorded report. Returns its leg-8 line."""
    fd, path = tempfile.mkstemp(prefix="t550-transcript-", suffix=".txt")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(text)
        env = dict(os.environ, T344_AUDIT_TRANSCRIPT=path)
        p = subprocess.run(["bash", GUARD], cwd=ROOT, env=env,
                           capture_output=True, text=True, timeout=600, check=False)
        out = p.stdout + p.stderr
        # Leg 8's own verdicts, matched exactly. An earlier version of this probe searched for
        # the substring "coverage checks" and bound to leg 1's "the coverage checks have a
        # population" — the same wrong-line-that-looks-right error this file exists to catch,
        # committed inside the probe for it. Anchoring on the verdict phrases, not the topic.
        for line in out.splitlines():
            if ("coverage checks agree:" in line
                    or "coverage checks DISAGREE" in line
                    or "full coverage over" in line
                    or "could not read both coverage counts" in line):
                return line.strip(), out
        return "", out
    finally:
        os.unlink(path)


def main():
    if not os.path.isfile(GUARD):
        refuse("%s not found — there is no guard to drive" % GUARD)
    src = open(GUARD, encoding="utf-8").read()
    if "T344_AUDIT_TRANSCRIPT" not in src:
        refuse("the guard no longer reads T344_AUDIT_TRANSCRIPT, so every leg below would "
               "silently run a LIVE audit instead of the recorded report it is meant to be "
               "examining, and would agree with itself for the wrong reason. Nothing was "
               "evaluated.")

    failures = []
    passes = 0

    def leg(name, ok, detail=""):
        nonlocal passes
        if ok:
            passes += 1
            print("  PASS  %s" % name)
        else:
            failures.append(name)
            print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))

    LIVE = "[WARN] Fabric: 59 registered, 199 unregistered (of 255 watched — 23% covered, cards flat since earlier today (59))"
    DRIFT199 = "[WARN] Fabric drift: 199 source file(s) have no fabric card"
    DRIFT150 = "[WARN] Fabric drift: 150 source file(s) have no fabric card"

    # ── leg 1: the reported defect ─────────────────────────────────────────────────────────
    # Live finding says 199/255. A trend echo in the old shape says 185/222. The guard must
    # read the live one and conclude agreement.
    line, out = leg1 = run_guard(transcript(LIVE, DRIFT199))
    leg("1 a trend echo of the OLD message shape does not become today's number",
        "agree" in line and "199" in line and "255" in line and "185" not in line,
        "leg 8 said: %r. This is the T-550 defect verbatim: the live finding is 199 of 255 and "
        "the only other candidate in the report is a 14-day aggregate of 185 of 222. Reading "
        "the aggregate produces a disagreement that does not exist." % line)

    # ── leg 2: the guard still catches a REAL disagreement ─────────────────────────────────
    # Without this, leg 1 is satisfied by a guard that has stopped comparing anything.
    line, _ = run_guard(transcript(LIVE, DRIFT150))
    leg("2 a genuine disagreement between the two live findings is still reported",
        "DISAGREE" in line and "199" in line and "150" in line,
        "leg 8 said: %r. A repair that made the guard agreeable rather than accurate would "
        "pass leg 1 and be worse than the defect." % line)

    # ── leg 3: a stale anchor must abstain, not fall through ───────────────────────────────
    # No live coverage finding at all, trend echo present. The old code would have matched the
    # echo; the requirement is that the guard says its anchor is stale.
    line, out = run_guard(transcript(None, DRIFT199))
    leg("3 no live coverage finding ABSTAINS loudly instead of matching the trend echo",
        "anchor has gone stale" in out and "185" not in line,
        "leg 8 said: %r. With no current finding the only text resembling one is the "
        "historical echo. Falling through to it is the defect; falling silent is the T-524 "
        "vacuous pass. The guard has to say the anchor is stale." % line)

    # ── leg 4: full coverage is read from a finding, not from anywhere ─────────────────────
    line, _ = run_guard(transcript(
        "[PASS] Fabric: 59 registered, 0 unregistered (of 255 watched)", None))
    leg("4 full coverage is recognised, and from a severity-marked finding",
        "full coverage" in line,
        "leg 8 said: %r. Zero unregistered is the one legitimate reason the drift count is "
        "absent, and it must still be read off the audit's own verdict." % line)

    # ── leg 5: the fixtures still resemble the real report ─────────────────────────────────
    # Legs 1-4 are only worth their green while the transcripts look like what the audit
    # actually emits. This runs the LIVE audit once and requires its coverage finding to match
    # the shape used above — otherwise these fixtures have drifted into testing a format
    # nothing produces, which is the same class of decay as the defect under repair.
    fw = os.path.join(ROOT, ".agentic-framework/bin/fw")
    p = subprocess.run([fw, "audit", "--section", "structure"], cwd=ROOT,
                       capture_output=True, text=True, timeout=600, check=False)
    real = p.stdout + p.stderr
    shape = re.compile(r"^\[[A-Z]+\] Fabric: \d+ registered, \d+ unregistered \(of \d+ watched")
    live_found = [l for l in real.splitlines() if shape.match(l)]
    leg("5 the live audit still emits the finding shape these fixtures imitate",
        len(live_found) == 1,
        "found %d line(s) matching the shape leg 1-4's transcripts use. If 0, the message "
        "changed again and these fixtures now test a format nothing emits — re-derive them "
        "rather than trust their green. If more than 1, the anchor is ambiguous on the real "
        "report and `head -1` is choosing.\n        live: %s"
        % (len(live_found), live_found or "none"))

    print()
    if failures:
        print("T-550 TEETH: %d/%d legs passed — FAILED: %s"
              % (passes, passes + len(failures), ", ".join(failures)))
        return 1
    print("T-550 TEETH: %d/%d legs passed — the guard reads today's finding rather than the "
          "report's summary of its own past, still catches a real disagreement, abstains when "
          "its anchor goes stale, and its fixtures still resemble the live report" % (passes, passes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
