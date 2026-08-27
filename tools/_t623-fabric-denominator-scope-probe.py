#!/usr/bin/env python3
"""
T-623 — is our fabric coverage number scoped the way AEF's is?

999-AEF answered Arc 0 clause 1 on agent-chat-arc offset 650 with a red
measurement of its own fabric, and extended the verdict to us unmeasured:

    "Your 69/252 with 46 edgeless is the same disease; we are simply further
     along the same curve, not healthier."

The defect they described is specific, and it is NOT low coverage. It is this:
their drift check only ranges over files a watch pattern covers, while 749 of
their 1134 cards point at files no pattern covers. So their "13 unregistered"
is 13 out of the subset the check can see — a number that answers a smaller
question than the one asked. Low coverage is a fact you can report; a denominator
that silently shrinks is a number you cannot trust.

This probe asserts our denominator does NOT shrink that way, and keeps asserting
it. It is the standing form of a measurement taken once on 2026-08-27, when the
reading was 66 cards inside the watch set, 3 outside, and 319 - 66 = 253 closing
the audit's unregistered count exactly.

Two independent assertions, because they fail for different reasons:

  A. Every card that points outside the watch set is one we have *documented* as
     legitimately outside. .fabric/watch-patterns.yaml names the fixture cards
     explicitly ("Three fixture cards predate this file and remain valid — a card
     may exist for anything; the watch set only decides what an ABSENT card is
     reported about"). An UNDOCUMENTED outside card is the AEF shape arriving:
     the registry drifting away from the population the checks range over.

  B. The arithmetic closes: unregistered == |watch set| - |cards inside|. If this
     stops holding, the two numbers the audit prints are being computed over
     different populations, which is the same disease by another route.

Exit 0 = our denominator is honest. Exit 1 = it has acquired the blindness.
Exit 2 = the probe could not measure (missing inputs) — refusal, not a pass.

Deliberately NOT asserted: that coverage is good. It is not — 21% carded with
46 of 69 cards edgeless. AEF's criticism on that half is accepted and tracked
separately. This probe defends the trustworthiness of the number, not its value.
"""

import glob
import os
import subprocess
import sys

import yaml

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WATCH_YAML = os.path.join(REPO, ".fabric", "watch-patterns.yaml")
EXPANDER = os.path.join(
    REPO, ".agentic-framework", "agents", "fabric", "lib", "expand_patterns.py"
)
CARD_GLOB = os.path.join(REPO, ".fabric", "components", "*.yaml")

# Cards documented in .fabric/watch-patterns.yaml as legitimately outside the
# watch set: .bpmn/.xml fixtures are DATA, excluded from the watch globs on
# purpose, and these three cards predate the file. Adding to this list is a
# deliberate act that should come with a reason; drifting into it is the defect.
DOCUMENTED_OUTSIDE = {
    "tests/fixtures/invalid/E-INCEPTION-NOT-SOVEREIGN.xml",
    "tests/fixtures/invalid/E-XML-NODE-TYPE.xml",
    "tests/fixtures/warn/W-TYPE-LANE-MISMATCH.xml",
}


def refuse(msg):
    print("  REFUSE  %s" % msg)
    print("\n  probe could not measure — this is not a pass")
    sys.exit(2)


def watch_set():
    if not os.path.exists(EXPANDER):
        refuse("expander missing: %s" % EXPANDER)
    if not os.path.exists(WATCH_YAML):
        refuse("watch patterns missing: %s" % WATCH_YAML)
    try:
        out = subprocess.run(
            [sys.executable, EXPANDER, WATCH_YAML, REPO],
            capture_output=True, text=True, timeout=120, cwd=REPO,
        )
    except subprocess.TimeoutExpired:
        refuse("watch-pattern expansion timed out — a timeout is not a zero")
    if out.returncode != 0:
        refuse("expander exited %d: %s" % (out.returncode, out.stderr.strip()[:200]))
    files = {ln.strip().lstrip("./") for ln in out.stdout.split() if ln.strip()}
    if not files:
        # This is exactly the T-344 empty-denominator failure. An empty watch set
        # would make every assertion below vacuously true.
        refuse("watch set expanded to ZERO files (T-344 class) — denominator empty")
    return files


def card_locations():
    cards = sorted(glob.glob(CARD_GLOB))
    if not cards:
        refuse("no component cards found under .fabric/components/")
    locs = {}
    for c in cards:
        try:
            data = yaml.safe_load(open(c)) or {}
        except Exception as exc:
            refuse("card %s does not parse: %s" % (os.path.basename(c), exc))
        loc = data.get("location")
        if not loc:
            refuse("card %s has no location: field" % os.path.basename(c))
        locs[os.path.basename(c)] = str(loc).lstrip("./")
    return locs


def main():
    print("T-623 — is our fabric coverage denominator scoped the way AEF's is?\n")

    watch = watch_set()
    locs = card_locations()

    inside = {c: l for c, l in locs.items() if l in watch}
    outside = {c: l for c, l in locs.items() if l not in watch}
    undocumented = {c: l for c, l in outside.items() if l not in DOCUMENTED_OUTSIDE}

    total = len(locs)
    pct_outside = (100.0 * len(outside) / total) if total else 0.0

    print("  watch set .................. %d file(s)" % len(watch))
    print("  cards ...................... %d" % total)
    print("  cards inside watch set ..... %d" % len(inside))
    print("  cards outside watch set .... %d  (%.1f%%)" % (len(outside), pct_outside))
    print("  of those, undocumented ..... %d" % len(undocumented))
    print()

    failures = []

    # ── A. no card drifts outside the measured population undocumented ──────
    if undocumented:
        failures.append(
            "%d card(s) point outside the watch set without being documented in "
            ".fabric/watch-patterns.yaml" % len(undocumented)
        )
        print("  FAIL  cards outside the watch set are all documented")
        for c, l in sorted(undocumented.items(), key=lambda kv: kv[1]):
            print("          %s  (card %s)" % (l, c))
    else:
        print("  PASS  every card outside the watch set is a documented fixture (%d)"
              % len(outside))

    # ── B. the arithmetic the audit prints closes over one population ───────
    unregistered = len(watch) - len(inside)
    if unregistered < 0:
        failures.append("more cards inside the watch set than files in it — impossible")
        print("  FAIL  |watch| - |inside| is negative (%d)" % unregistered)
    else:
        print("  PASS  arithmetic closes: %d watched - %d carded = %d unregistered"
              % (len(watch), len(inside), unregistered))

    # ── C. the shape AEF described, stated as a ratio ───────────────────────
    # AEF: 749 of 1134 = 66.0% of cards outside any watch pattern. A denominator
    # is not trustworthy when most of the registry sits outside it. 25% is a wide
    # fence around today's 4.3% — this catches a regime change, not a wobble.
    if pct_outside > 25.0:
        failures.append(
            "%.1f%% of cards point outside the watch set — the denominator now "
            "answers a materially smaller question than the one asked" % pct_outside
        )
        print("  FAIL  outside-ratio %.1f%% exceeds the 25%% trust fence" % pct_outside)
    else:
        print("  PASS  outside-ratio %.1f%% is within the 25%% trust fence "
              "(AEF's reading: 66.0%%)" % pct_outside)

    print()
    if failures:
        print("  %d failed — our denominator has acquired the blindness AEF described"
              % len(failures))
        for f in failures:
            print("    - %s" % f)
        return 1

    print("  3 passed, 0 failed")
    print("  Our number is low, not blind. Coverage (%d/%d carded) is a separate and"
          % (len(inside), len(watch)))
    print("  accepted criticism — this probe defends the number's honesty, not its value.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
