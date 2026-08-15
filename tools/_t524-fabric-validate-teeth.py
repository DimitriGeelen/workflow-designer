#!/usr/bin/env python3
"""
T-524 teeth — does `fw fabric validate` actually detect anything, and does it say what?

The command this exercises used to `return 0` unconditionally while printing "Deep validation
not yet implemented". That is the failure being fixed, so a teeth script that only asserts
"validate exits 0 on the real tree" would have passed against the stub it replaces — the whole
point is that a green from this command now MEANS something. Every leg below is therefore built
around a stimulus that CONTAINS the fault (PL-206), and asserts red for the NAMED reason rather
than merely non-zero (the OBS-255 failure mode: a bare rc check passes on a red caused by
anything at all, including the validator crashing).

Legs:
  1  a card missing `location:` → rc 1, and the card is named
  2  red for the NAMED reason — the finding is on the `location` field specifically, not on
     some other field that happened to trip
  3  green is a CLASSIFICATION, not absence — a valid card sitting in the same run is not
     flagged. Without this, a validator that flags every card would pass legs 1 and 2.
  4  an unparseable card is a FINDING, not a silent skip. Every python pass in drift.sh wraps
     safe_load in a bare try/except, so a broken card is present on disk, counted by ls, and
     invisible to the graph. That silence is one level below the one this task is about.
  5  two cards claiming one id → detected. Which one wins is glob order, i.e. the filename,
     which nobody thinks of as semantic.
  6  an empty register REFUSES (rc 2) rather than reporting "all valid". A run over zero cards
     is the stub's exact behaviour wearing better prose (PL-205).
  7  an unknown component argument REFUSES (rc 2) rather than silently validating nothing.
  8  the real tree is green (rc 0). A red here would mean the validator is wrong, not the tree.
  9  THE DOWNSTREAM HARM IS REAL, MEASURED NOT ASSERTED. The same malformed card makes
     `fw fabric drift` report its file as UNREGISTERED even though a card exists — so the
     operator is advised to run `fw fabric scan`, which mints a SECOND card for one file. This
     leg is what justifies `location` being required at all; without it the required-field set
     would be my taste rather than a consequence.

Hermetic: every fixture is built under mktemp and the register under test is selected with
PROJECT_ROOT. Leaves this repository byte-identical.

Exit 0 all legs pass, 1 a leg failed, 2 REFUSE (the subject is absent — nothing was evaluated).
"""

import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FABRIC = os.path.join(REPO, ".agentic-framework/agents/fabric/fabric.sh")

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


def run(cmd, root=None):
    env = dict(os.environ)
    if root:
        env["PROJECT_ROOT"] = root
    p = subprocess.run(cmd, cwd=REPO, env=env, capture_output=True, text=True,
                       timeout=120, check=False)
    return p.returncode, (p.stdout + p.stderr)


def validate(root=None, arg=None):
    cmd = ["bash", FABRIC, "validate"] + ([arg] if arg else [])
    return run(cmd, root)


def register(tmp, name, cards, sources=(), patterns=None):
    """Build a throwaway project with a .fabric register and return its root."""
    root = os.path.join(tmp, name)
    os.makedirs(os.path.join(root, ".fabric", "components"), exist_ok=True)
    for rel in sources:
        path = os.path.join(root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as fh:
            fh.write("placeholder\n")
    for fname, body in cards.items():
        with open(os.path.join(root, ".fabric", "components", fname), "w") as fh:
            fh.write(body)
    if patterns:
        with open(os.path.join(root, ".fabric", "watch-patterns.yaml"), "w") as fh:
            fh.write(patterns)
    return root


GOOD = "id: C-900\nname: a good card\nlocation: tools/carded.py\ntype: tool\n"
NO_LOCATION = "id: C-901\nname: a card with no location\ntype: tool\n"
UNPARSEABLE = "id: C-902\nname: [unclosed\n  location: nope\n"
DUP_A = "id: C-903\nname: first claimant\nlocation: tools/dup.py\n"
DUP_B = "id: C-903\nname: second claimant\nlocation: tools/dup2.py\n"

if not os.path.isfile(FABRIC):
    refuse("missing .agentic-framework/agents/fabric/fabric.sh — the subject is not here")

print("T-524 teeth — does `fw fabric validate` detect anything, and does it name it")
print("subject: .agentic-framework/agents/fabric/lib/drift.sh do_validate()")
print()

tmp = tempfile.mkdtemp(prefix="t524-teeth-")
before = run(["git", "status", "--porcelain"])[1]
try:
    # ── legs 1-3: the T-522 card, alongside a valid one ────────────────────────────────────
    root = register(tmp, "missing-location",
                    {"good.yaml": GOOD, "bad.yaml": NO_LOCATION})
    rc, out = validate(root)

    leg("1 a card missing `location:` makes validate go red (rc 1) and names the card",
        rc == 1 and "bad.yaml" in out,
        "rc=%d out=%r. This is the exact card shape that aborted update-task.sh in T-522 and "
        "lost two episodics; if it does not surface here, nothing surfaces it." % (rc, out[-400:]))

    bad_block = out.split("! bad.yaml", 1)[-1] if "! bad.yaml" in out else ""
    leg("2 red for the NAMED reason — the finding is on `location`, not merely non-zero",
        "location:" in bad_block and "missing" in bad_block,
        "the block reported under bad.yaml was %r. Asserting only rc!=0 would pass on a "
        "validator that crashed, which is the OBS-255 shape." % bad_block[:300])

    # The obvious form of this leg — `"good.yaml" not in out` — is VACUOUSLY TRUE whenever the
    # validator prints nothing at all, which is exactly what the stub being replaced did. It
    # passed against the regression while every other content leg failed. So the leg has to
    # assert that a discrimination actually happened: findings were reported, AND the valid card
    # is not among them, AND exactly one card was faulted out of the two checked.
    leg("3 green is a CLASSIFICATION, not absence — findings were reported and the valid card "
        "is not among them",
        "! bad.yaml" in out and "! good.yaml" not in out and "across 1 card(s) of 2 checked" in out,
        "out=%r. A detector that fires on every input has no discriminating power — and one that "
        "fires on nothing passes a naive 'the good card was not flagged' check for free."
        % out[-400:])

    # ── leg 4: unparseable card is a finding, not a silent skip ────────────────────────────
    root = register(tmp, "unparseable", {"good.yaml": GOOD, "broken.yaml": UNPARSEABLE})
    rc, out = validate(root)
    leg("4 an unparseable card is a FINDING, not a silent skip",
        rc == 1 and "broken.yaml" in out and "yaml:" in out,
        "rc=%d out=%r. drift.sh's python passes swallow parse errors in bare try/except, so "
        "such a card is on disk, counted by ls, and absent from the graph." % (rc, out[-400:]))

    # ── leg 5: duplicate ids ───────────────────────────────────────────────────────────────
    root = register(tmp, "dup-ids", {"a.yaml": DUP_A, "b.yaml": DUP_B})
    rc, out = validate(root)
    leg("5 two cards claiming one id are detected",
        rc == 1 and "duplicate id" in out and "C-903" in out,
        "rc=%d out=%r. Edges name ids; with two holders, which one an edge resolves to is glob "
        "order — the filename, which is not supposed to carry meaning." % (rc, out[-400:]))

    # ── leg 6: empty register refuses ──────────────────────────────────────────────────────
    root = register(tmp, "empty", {})
    rc, out = validate(root)
    leg("6 an EMPTY register refuses (rc 2) rather than reporting success",
        rc == 2 and "REFUSE" in out,
        "rc=%d out=%r. 'I validated zero cards' reported as green IS the stub this task "
        "replaces — it printed prose and returned 0 too." % (rc, out[-400:]))

    # ── leg 7: unknown component refuses ───────────────────────────────────────────────────
    root = register(tmp, "known", {"good.yaml": GOOD})
    rc, out = validate(root, arg="C-nope")
    leg("7 an unknown component argument refuses (rc 2), distinguishable from a pass",
        rc == 2 and "REFUSE" in out,
        "rc=%d out=%r. A typo'd component id must not be reportable as validated." % (rc, out[-400:]))

    # ── leg 8: the real tree ───────────────────────────────────────────────────────────────
    rc, out = validate()
    leg("8 the real register is green (rc 0)",
        rc == 0 and "OK:" in out,
        "rc=%d out=%r. Every current card carries id/name/location, so a red here means this "
        "validator is wrong rather than the tree." % (rc, out[-400:]))

    # ── leg 9: the downstream harm, measured ───────────────────────────────────────────────
    root = register(
        tmp, "drift-harm",
        {"carded.yaml": "id: C-900\nname: carded\nlocation: tools/carded.py\n",
         "nolocation.yaml": NO_LOCATION},
        sources=("tools/carded.py", "tools/nolocation.py"),
        patterns='patterns:\n  - glob: "tools/**/*.py"\n',
    )
    subprocess.run(["git", "-C", root, "init", "-q"], capture_output=True, check=False)
    drc, dout = run(["bash", FABRIC, "drift"], root)
    unreg = "! tools/nolocation.py" in dout
    carded_quiet = "! tools/carded.py" not in dout
    leg("9 the harm is REAL — a location-less card makes its own file report UNREGISTERED",
        unreg and carded_quiet,
        "nolocation flagged=%s carded quiet=%s. drift builds its `registered` set by grepping "
        "`^location:` (lib/drift.sh:25), so a card without one contributes nothing and its file "
        "looks uncarded — and the printed remedy is `fw fabric scan`, which would mint a SECOND "
        "card for that one file. This leg is why `location` is required rather than merely "
        "conventional.\ndrift said:\n%s" % (unreg, carded_quiet, dout[:600]))
finally:
    shutil.rmtree(tmp, ignore_errors=True)

after = run(["git", "status", "--porcelain"])[1]
leg("10 hermetic — the working tree is byte-identical after the run",
    before == after,
    "git status changed across the run. Fixtures must live under mktemp; a teeth script that "
    "dirties the tree makes every later verdict in the session ambiguous.")

print()
total = passes + len(failures)
if failures:
    print("%d/%d legs passed — FAILED: %s" % (passes, total, ", ".join(failures)))
    sys.exit(1)
print("%d/%d legs passed" % (passes, total))
sys.exit(0)
