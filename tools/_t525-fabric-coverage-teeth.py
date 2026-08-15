#!/usr/bin/env python3
"""
T-525 teeth — does the fabric coverage WARN actually discriminate, or just warn?

The check being exercised warned unconditionally on `unregistered > 0` and printed raw counts.
That is why no leg here may assert merely "a fabric warning appeared": the pre-change code
satisfies that for free, on every run, for every input. The deliverable is the DISCRIMINATION —
card loss must read differently from source growth — so every leg pins which branch was taken
and, where it asserts a branch was NOT taken, also proves the check was reached at all.

That second half is L-from-T-524, learned the hard way one task ago: a negative assertion is
satisfied by silence. "The output does not say CARD LOSS" passes when there is no output, which
is precisely the broken-audit case such a leg exists to catch. So legs 3 and 5 additionally
require the coverage line to be present and well-formed.

History is controlled through FABRIC_HISTORY_DIR (a seam the audit declares) rather than by
writing fabricated audit reports into the live `.context/audits/`. Fabricating real-looking
reports in the tree to test a check that reads reports is how you end up with a fixture nobody
recognises six weeks later — and a crashed run leaves it behind.

Legs:
  1  the check is REACHED and reports a ratio, not just a difference (guards legs 3 and 5)
  2  history showing MORE cards than now → the CARD LOSS branch, with the arithmetic right
  3  history showing FEWER cards than now → the growth branch, NOT card loss, and the line exists
  4  history equal to now → the flat branch, which is the case that says "the unregistered
     movement you are looking at is tree growth, not carding"
  5  no usable history → ABSTAINS. "I have no prior value" must not render as "no change"
     (PL-205), and must not silently fall into any of the three comparison branches.
  6  severity is UNCHANGED across all branches. The operator's T-344 [REVIEW] accepted this
     warning; a reporting fix that quietly promoted it to FAIL would overturn that decision
     under cover of a cosmetic change.
  7  hermetic — the working tree is byte-identical after the run.

Exit 0 all legs pass, 1 a leg failed, 2 REFUSE (the audit did not produce a coverage line at
all — nothing was evaluated, and that is not a pass).
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FW = os.path.join(REPO, ".agentic-framework/bin/fw")

COVERAGE_RE = re.compile(r"Fabric:\s*(\d+)\s+registered,\s*(\d+)\s+unregistered\s*"
                         r"\(of\s*(\d+)\s+watched\s*[—-]\s*(\d+)%\s*covered,\s*(.*?)\)\s*$")

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


def audit(history_dir=None):
    """Run the structure audit and return (coverage_match, warn_count, fail_count, raw)."""
    env = dict(os.environ)
    if history_dir is not None:
        env["FABRIC_HISTORY_DIR"] = history_dir
    p = subprocess.run([FW, "audit", "--sections", "structure"], cwd=REPO, env=env,
                       capture_output=True, text=True, timeout=600, check=False)
    raw = p.stdout + p.stderr
    match = None
    for line in raw.splitlines():
        m = COVERAGE_RE.search(line)
        if m:
            match = m
            break
    warn = fail = None
    mw = re.search(r"^Warn:\s*(\d+)", raw, re.M)
    mf = re.search(r"^Fail:\s*(\d+)", raw, re.M)
    if mw:
        warn = int(mw.group(1))
    if mf:
        fail = int(mf.group(1))
    return match, warn, fail, raw


def history(tmp, name, registered):
    """A directory holding one daily audit report that states `registered` cards."""
    d = os.path.join(tmp, name)
    os.makedirs(d, exist_ok=True)
    if registered is not None:
        # Filename must be a plausible LATER day than any real report, because the reader
        # takes the most recent. 2099 is unmistakably synthetic to anyone who sees it.
        with open(os.path.join(d, "2099-01-01.yaml"), "w") as fh:
            fh.write('  - check: "Fabric: %d registered, 1 unregistered (of 2 watched)"\n'
                     % registered)
    return d


if not os.path.isfile(FW):
    refuse("missing .agentic-framework/bin/fw — the subject is not here")

print("T-525 teeth — does the fabric coverage WARN discriminate, or just warn?")
print("subject: .agentic-framework/agents/audit/audit.sh (fabric coverage check)")
print()

tmp = tempfile.mkdtemp(prefix="t525-teeth-")
before = subprocess.run(["git", "status", "--porcelain"], cwd=REPO,
                        capture_output=True, text=True, check=False).stdout
try:
    # ── leg 1: the real run reaches the check and reports a ratio ──────────────────────────
    base, base_warn, base_fail, base_raw = audit()
    if base is None:
        refuse("the audit produced no fabric coverage line at all, so no branch could be "
               "observed. Either the check did not run (is `unregistered` zero on this tree, "
               "which sends it down the pass() arm?) or its message shape changed and the "
               "regex in this file is stale. Nothing below was evaluated.")

    now_reg = int(base.group(1))
    watched = int(base.group(3))
    pct = int(base.group(4))
    leg("1 the check is REACHED and reports COVERAGE, not just a difference",
        watched > 0 and pct == (now_reg * 100 // watched),
        "registered=%d watched=%d printed=%d%%. The whole finding is that `unregistered` alone "
        "moves opposite to coverage; if the ratio is absent or wrong, nothing else here means "
        "anything." % (now_reg, watched, pct))

    # ── leg 2: card loss ───────────────────────────────────────────────────────────────────
    m, warn_loss, fail_loss, raw = audit(history(tmp, "loss", now_reg + 12))
    note = m.group(5) if m else ""
    leg("2 history with MORE cards than now takes the CARD LOSS branch, arithmetic right",
        m is not None and "CARD LOSS" in note and ("12 fewer cards" in note)
        and ("%d -> %d" % (now_reg + 12, now_reg)) in note,
        "note=%r. Card loss and routine growth must not print the same line — a deleted or "
        "malformed card stops participating in component resolution (T-522/T-524) and makes "
        "its own file report as unregistered." % note)

    # ── leg 3: growth — a NEGATIVE assertion, so prove the line exists first ───────────────
    m, warn_grow, fail_grow, raw = audit(history(tmp, "grow", max(now_reg - 7, 0)))
    note = m.group(5) if m else ""
    leg("3 history with FEWER cards takes the growth branch and NOT card loss",
        m is not None and note != "" and "CARD LOSS" not in note
        and note.startswith("+%d cards since" % (now_reg - max(now_reg - 7, 0))),
        "note=%r (line present=%s). This leg asserts a branch was NOT taken, so it must also "
        "prove the check produced a line — otherwise a broken audit satisfies it by silence, "
        "which is exactly the T-524 vacuous-leg failure." % (note, m is not None))

    # ── leg 4: flat ────────────────────────────────────────────────────────────────────────
    m, _, _, raw = audit(history(tmp, "flat", now_reg))
    note = m.group(5) if m else ""
    leg("4 history EQUAL to now takes the flat branch",
        m is not None and note.startswith("cards flat since"),
        "note=%r. This is the branch that tells the operator the unregistered movement they are "
        "looking at is tree growth rather than carding activity." % note)

    # ── leg 5: abstention — also a negative assertion ──────────────────────────────────────
    m, warn_abs, fail_abs, raw = audit(history(tmp, "empty", None))
    note = m.group(5) if m else ""
    leg("5 no usable history ABSTAINS rather than falling into a comparison branch",
        m is not None and note.startswith("direction not evaluated")
        and "CARD LOSS" not in note and "flat since" not in note and not note.startswith("+"),
        "note=%r (line present=%s). 'I have no prior value' rendered as 'no change' would be a "
        "claim about history the instrument cannot support (PL-205)." % (note, m is not None))

    # ── leg 6: severity untouched across branches ──────────────────────────────────────────
    leg("6 severity is UNCHANGED across every branch — still WARN, never FAIL",
        None not in (base_warn, warn_loss, warn_grow, warn_abs, base_fail, fail_loss)
        and base_warn == warn_loss == warn_grow == warn_abs
        and base_fail == fail_loss == 0,
        "warn counts base=%s loss=%s grow=%s abstain=%s; fail base=%s loss=%s. The operator's "
        "T-344 [REVIEW] accepted this standing WARN; promoting it to FAIL inside a reporting "
        "fix would overturn a ratified decision as a side effect."
        % (base_warn, warn_loss, warn_grow, warn_abs, base_fail, fail_loss))
finally:
    shutil.rmtree(tmp, ignore_errors=True)

after = subprocess.run(["git", "status", "--porcelain"], cwd=REPO,
                       capture_output=True, text=True, check=False).stdout
leg("7 hermetic — the working tree is byte-identical after the run",
    before == after,
    "git status changed across the run. The audit writes its report to .context/audits/, so a "
    "leg that let it run unconstrained would dirty the tree and make every later verdict in the "
    "session ambiguous.\nbefore:\n%s\nafter:\n%s" % (before, after))

print()
total = passes + len(failures)
if failures:
    print("%d/%d legs passed — FAILED: %s" % (passes, total, ", ".join(failures)))
    sys.exit(1)
print("%d/%d legs passed" % (passes, total))
sys.exit(0)
