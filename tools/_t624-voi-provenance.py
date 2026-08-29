#!/usr/bin/env python3
"""T-624 — separate a DELIBERATE voi_score from the one the template planted.

WHY THIS EXISTS

For inception tasks the BVP estimator does not run its nine per-driver scorers.
`_score_inception_voi` (estimator.py:2429) makes `voi_score:` the entire composite,
which is the right design: for an exploration, the value IS the information it buys.

But `.tasks/templates/inception.md:22` ships `voi_score: 0.5`, so every inception is
born at the midpoint. 38 of 39 still carry it. The estimator has a branch for the
unscored case (`voi is None` -> "voi-absent-grandfathered") and it is UNREACHABLE for
any template-created task, because the template guarantees the field is never None.
Both branches return 2 and the ranking table prints neither evidence string, so
"deliberately scored 0.5" and "never scored at all" are the same row.

THE DISCRIMINATOR, AND WHY IT IS NOT THE VALUE

The value alone cannot answer this — 0.5 is a legitimate score. The file's own history
can (PL-149: a population contains its own provenance). Two independent marks of
deliberation, either sufficient:

  * the `voi_score:` line was touched by a commit AFTER the one that created the file
    (someone went back and changed it), or
  * the value differs from what the template ships (someone typed a number at creation).

The second clause is not decoration. Without it, an author who scores 0.8 correctly at
creation time is reported as "never scored" — one commit, no later edit. That case does
not occur in our corpus today, which is exactly why it is in the fixture set: the fixture
set is a claim about which failures the author imagined, and a corpus of two real
instances cannot test the class (010-termlink @764, 577-CashWeb @766, 2026-08-29).

WHAT THIS DOES NOT DO

It does not write `voi_score:`. That field IS the composite, which makes it the
sovereignty equivalent of confirmed `bvp_scores:`, and unlike bvp_scores/cost_estimate
it has no `_proposed:` lane for an agent to write into. The absence of that lane is part
of the finding; it is not a licence.
"""
import argparse
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, ".tasks", "templates", "inception.md")
RE_VOI = re.compile(r"^voi_score:\s*([0-9.]+)", re.M)


def template_default():
    """The value the template plants. Read, never assumed — if the template changes,
    every verdict below changes with it, and silently hard-coding 0.5 would freeze
    this instrument at today's shape."""
    try:
        with open(TEMPLATE, encoding="utf-8") as fh:
            m = RE_VOI.search(fh.read())
        return m.group(1) if m else None
    except OSError:
        return None


def voi_line_commits(path):
    """Commits that touched the file's `voi_score:` line, newest first."""
    rel = os.path.relpath(path, ROOT)
    try:
        out = subprocess.run(
            ["git", "-C", ROOT, "log", "--format=%h|%ad|%s", "--date=short",
             "-L", "/^voi_score:/,+1:" + rel],
            capture_output=True, text=True, timeout=60,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    return [l for l in out.splitlines() if re.match(r"^[0-9a-f]{7,12}\|", l)]


def decide(value, n_commits, default):
    """The whole rule, in one place.

    `classify` and `self_test` both call THIS. An earlier draft had the self-test
    re-implement the condition inline, which would have proved only that the fixtures
    agree with a copy of the rule — green while the shipped path was anything at all.
    That is the defect this task is filing, one layer up.
    """
    if value is None:
        return "absent"
    edited_after_creation = n_commits > 1
    differs_from_template = default is not None and value != default
    return "scored" if (edited_after_creation or differs_from_template) else "template-default"


def classify(path, default):
    """-> (state, value, n_commits, newest_subject)

    States: `scored` (deliberate), `template-default` (never scored),
    `absent` (no field at all — the estimator's grandfathered path).
    """
    with open(path, encoding="utf-8") as fh:
        m = RE_VOI.search(fh.read())
    if not m:
        return "absent", None, 0, ""
    value = m.group(1)
    commits = voi_line_commits(path)
    subject = commits[0].split("|", 2)[2] if commits else ""
    return decide(value, len(commits), default), value, len(commits), subject


def collect():
    default = template_default()
    rows = []
    for path in sorted(glob.glob(os.path.join(ROOT, ".tasks", "*", "*.md"))):
        # `.tasks/*/` includes templates/, and the templates carry
        # `workflow_type: inception` in order to BE inception templates. Counting them
        # inflates the population with the very artefact that plants the default —
        # 010-termlink @764: "a corpus census of a defective idiom counts the remedy's
        # own documentation, and the overcount grows as remediation improves". Measured
        # here: 3 template files were in the first run's 43.
        if os.sep + "templates" + os.sep in path:
            continue
        try:
            with open(path, encoding="utf-8") as fh:
                head = fh.read(4096)
        except OSError:
            continue
        if "workflow_type: inception" not in head:
            continue
        state, value, n, subject = classify(path, default)
        rows.append((os.path.basename(path), state, value, n, subject))
    return default, rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--assert-scored", type=int, default=None,
                    help="fail unless exactly N inceptions are deliberately scored; "
                         "pins the count so an agent silently writing voi_score is caught")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    default, rows = collect()
    scored = [r for r in rows if r[1] == "scored"]
    planted = [r for r in rows if r[1] == "template-default"]
    absent = [r for r in rows if r[1] == "absent"]

    print("T-624 — voi_score provenance across %d inception task(s)" % len(rows))
    print("  template plants: voi_score: %s" % default)
    print()
    print("  deliberately scored ....... %d" % len(scored))
    print("  still at template default . %d   <- the estimator reports these as a" % len(planted))
    print("                                     computed 'voi:0.50', never as unscored")
    print("  field absent (grandfathered) %d" % len(absent))
    print()
    for name, state, value, n, subject in scored:
        print("  SCORED  %-52s voi=%-5s %s" % (name[:52], value, subject[:40]))
    if planted:
        print()
        print("  The %d below share one BVP score and cannot be ranked against each" % len(planted))
        print("  other. Scoring them is the operator's act: voi_score IS the composite,")
        print("  and it has no _proposed: lane an agent may write.")

    if args.assert_scored is not None and len(scored) != args.assert_scored:
        print()
        print("FAIL: expected %d deliberately-scored inception(s), found %d"
              % (args.assert_scored, len(scored)))
        return 1
    return 0


def self_test():
    """Fixtures for the classes the corpus cannot supply.

    Our real corpus holds exactly two shapes: 38 untouched template defaults and one
    task edited later. Red-then-green against that corpus would prove only that the
    discriminator separates those two — not that it covers the class. Cases 3 and 4
    exist for precisely that reason and neither occurs in the tree today.
    """
    cases = [
        # (label, value, n_commits, template_default, expected_state)
        ("untouched template default",        "0.5", 1, "0.5", "template-default"),
        ("edited after creation",             "0.9", 2, "0.5", "scored"),
        ("deliberate value AT creation",      "0.8", 1, "0.5", "scored"),
        ("template default, edited to itself","0.5", 2, "0.5", "scored"),
        ("template itself changed to 0.3",    "0.3", 1, "0.3", "template-default"),
    ]
    failures = 0
    for label, value, n, default, expected in cases:
        got = decide(value, n, default)
        ok = got == expected
        failures += 0 if ok else 1
        print("  %-4s %-38s -> %s" % ("ok" if ok else "FAIL", label, got))
    print()
    if failures:
        print("self-test FAILED: %d of %d" % (failures, len(cases)))
        return 1
    print("self-test passed: %d of %d" % (len(cases), len(cases)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
