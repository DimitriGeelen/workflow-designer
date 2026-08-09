#!/usr/bin/env python3
"""verification-hygiene.py — a RATCHET on the G-015 carrier population.

G-015 records that `## Verification` blocks carry lines asserting a GLOBAL,
always-moving property instead of a property of the task that carries them. Two
shapes are on record:

  (a) `diff src/aef-workflow-designer.html build/gallery/designer.html`
      — "is the serve root built and current right now", which decays the instant
        anyone else edits src, and converts "the human has not reviewed this yet"
        into "permanently red" (T-093, red for 35 days for reasons unrelated to T-093).
  (b) a hard-coded `:PORT` literal — a gate pinned to a host-level fact. Ports live
      in .context/working/watchtower.{port,url} or are discovered free at runtime.

WHAT THIS TOOL IS NOT
---------------------
It does NOT narrow, rewrite, or green a single existing line. G-015's leg 1 —
changing the convention across 75 lines — is a convention change the register
reserves for the operator ("NOT APPLIED... Reported with the measurement so the
operator can rule"). Nor does it rebuild build/gallery/: the register pre-rejects
that as manufacturing a green that asserts less than it says.

WHAT IT IS
----------
The register also named a third thing, which is neither leg:

    "nothing in the tree stops the next author writing :3001, and CLAUDE.md's ban
     on hard-coded ports is prose, read by nothing."

Measured against the register's own 2026-08-02 figures, that is what happened:
serve-root-diff lines held at 75, while hard-coded-port lines went 11 -> 17 in
seven days. The prose ban held zero of the six.

So: baseline the carriers that exist today, and fail on a carrier in any file NOT
in the baseline. The grandfathered population stays exactly as it is, awaiting the
operator's ruling; the population cannot grow without someone being told. Same
shape as T-399's ledger — a population grandfathered by PATH, with the live rule
applying to everything else.

Baseline is keyed on (task file, sha256 of the normalised carrier line), not on
counts. A count-keyed baseline would let a file that was cleaned 1->0 silently go
0->1 again and still satisfy "<= 1". Hash keying means a DIFFERENT carrier line in
a grandfathered file is still caught, and `--tighten` drops entries whose line is
gone so the ratchet only ever turns one way.

Removing a carrier never fails the scan (cleaning up must never be punished), but
a stale baseline entry is reported loudly on every run, so a cleaned file cannot
SILENTLY re-acquire one — the notice is standing until someone runs --tighten.

Usage:
  verification-hygiene.py              ratchet check (exit 1 on a new carrier)
  verification-hygiene.py --census     print the population, exit 0
  verification-hygiene.py --tighten    drop baseline entries whose line is gone
  verification-hygiene.py --adopt      (re)generate the baseline from the tree

Exit 0 = no carrier outside the baseline. 1 = a new carrier. 2 = harness/vacuity error.
"""
import argparse
import glob
import hashlib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASELINE = os.path.join(ROOT, "tools", "verification-hygiene-baseline.json")

# The two carrier shapes. Kept character-identical to _t350-verification-hygiene.py so a
# line one tool calls a carrier is a carrier to the other; the teeth assert they agree.
RE_SERVE_DIFF_A = re.compile(r"\b(diff|cmp)\b.*build/gallery")
RE_SERVE_DIFF_B = re.compile(r"build/gallery.*\b(diff|cmp)\b")
RE_PORT = re.compile(r":(\d{2,5})\b")

KIND_DIFF = "serve-root-diff"
KIND_PORT = "hardcoded-port"


def exec_lines(text):
    """The executable lines of a task's ## Verification block, or [] if it has none.

    Anchored on the HEADING, not the string: an AC that talks about "## Verification"
    puts the same characters in the body, and splitting on the raw string captures that
    prose instead of the block (the bug _t350 fixed by anchoring — same fix here).
    """
    m = re.search(r"^## Verification[ \t]*$", text, re.M)
    if not m:
        return None
    block = re.split(r"^## ", text[m.end():], maxsplit=1, flags=re.M)[0]
    return [ln for ln in block.splitlines()
            if ln.strip() and not ln.strip().startswith("#")]


def carriers_in(line):
    """Which carrier kinds this one line is. A line can be both."""
    kinds = []
    if RE_SERVE_DIFF_A.search(line) or RE_SERVE_DIFF_B.search(line):
        kinds.append(KIND_DIFF)
    if RE_PORT.search(line):
        kinds.append(KIND_PORT)
    return kinds


def line_key(line):
    return hashlib.sha256(line.strip().encode("utf-8")).hexdigest()[:16]


def scan():
    """-> (findings, stats). findings: relpath -> {key: {line, kinds}}."""
    paths = sorted(glob.glob(os.path.join(ROOT, ".tasks", "active", "*.md"))
                   + glob.glob(os.path.join(ROOT, ".tasks", "completed", "*.md")))
    findings = {}
    stats = {"task_files": len(paths), "with_block": 0, "exec_lines": 0,
             KIND_DIFF: 0, KIND_PORT: 0}
    for p in paths:
        rel = os.path.relpath(p, ROOT)
        try:
            text = open(p, encoding="utf-8").read()
        except OSError as e:
            print("ERROR: unreadable task file %s: %s" % (rel, e), file=sys.stderr)
            continue
        lines = exec_lines(text)
        if lines is None:
            continue
        stats["with_block"] += 1
        stats["exec_lines"] += len(lines)
        for ln in lines:
            kinds = carriers_in(ln)
            if not kinds:
                continue
            for k in kinds:
                stats[k] += 1
            findings.setdefault(rel, {})[line_key(ln)] = {
                "line": ln.strip(), "kinds": kinds}
    return findings, stats


def load_baseline():
    if not os.path.exists(BASELINE):
        return None
    with open(BASELINE, encoding="utf-8") as fh:
        return json.load(fh)


def write_baseline(findings, stats, note):
    data = {
        "_note": note,
        "_generated_against": {
            "task_files": stats["task_files"],
            "files_with_verification_block": stats["with_block"],
            "executable_lines": stats["exec_lines"],
            KIND_DIFF: stats[KIND_DIFF],
            KIND_PORT: stats[KIND_PORT],
        },
        "carriers": {rel: {k: v["kinds"] for k, v in sorted(d.items())}
                     for rel, d in sorted(findings.items())},
    }
    with open(BASELINE, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=1, sort_keys=False)
        fh.write("\n")
    return data


def census(stats, findings):
    print("population: files=%d with-block=%d lines=%d %s=%d %s=%d carrier-files=%d"
          % (stats["task_files"], stats["with_block"], stats["exec_lines"],
             KIND_DIFF, stats[KIND_DIFF], KIND_PORT, stats[KIND_PORT],
             len(findings)))


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--tighten", action="store_true")
    ap.add_argument("--adopt", action="store_true")
    args = ap.parse_args()

    findings, stats = scan()

    # ANTI-VACUITY (PL-084). A scan reporting "zero violations" must state whether the
    # population it scanned was non-empty. Every exit below this point is a claim about
    # a real population, or it is an error.
    if stats["task_files"] == 0 or stats["with_block"] == 0:
        print("VACUOUS: scanned %d task file(s), %d with a ## Verification block. A clean "
              "verdict over an empty population is a bug, not a pass."
              % (stats["task_files"], stats["with_block"]), file=sys.stderr)
        return 2

    if args.census:
        census(stats, findings)
        return 0

    if args.adopt:
        data = write_baseline(findings, stats,
                              "G-015 carrier baseline (T-408). Grandfathered population "
                              "awaiting the operator's leg-1 ruling. A carrier NOT listed "
                              "here fails the ratchet. Never hand-edit to add entries.")
        census(stats, findings)
        print("adopted baseline: %d file(s), %d carrier line(s) -> %s"
              % (len(data["carriers"]),
                 sum(len(v) for v in data["carriers"].values()),
                 os.path.relpath(BASELINE, ROOT)))
        return 0

    base = load_baseline()
    if base is None:
        print("ERROR: no baseline at %s. Generate it once with --adopt."
              % os.path.relpath(BASELINE, ROOT), file=sys.stderr)
        return 2
    carriers = base.get("carriers") or {}
    if not carriers:
        print("VACUOUS: the baseline records no carriers, so every carrier in the tree "
              "would read as new and every clean tree as a pass over nothing.",
              file=sys.stderr)
        return 2

    # THE RATCHET. A carrier line is allowed only if this exact line is recorded against
    # this exact task file. New file with a carrier, or a new carrier line in a
    # grandfathered file, both fail.
    new = []
    for rel, d in sorted(findings.items()):
        allowed = carriers.get(rel, {})
        for key, info in sorted(d.items()):
            if key not in allowed:
                new.append((rel, info))

    # Stale = baseline entry whose line is gone. Never a failure — cleaning up must not be
    # punished — but reported on every run so a cleaned file cannot SILENTLY re-acquire one.
    stale = []
    for rel, keys in sorted(carriers.items()):
        present = findings.get(rel, {})
        if not os.path.exists(os.path.join(ROOT, rel)):
            stale.append((rel, "task file no longer at this path (moved by work-completed?)"))
            continue
        for key in sorted(keys):
            if key not in present:
                stale.append((rel, "carrier line removed (%s)" % key))

    if args.tighten:
        kept = {}
        for rel, keys in carriers.items():
            present = findings.get(rel, {})
            keep = {k: v for k, v in keys.items() if k in present}
            if keep:
                kept[rel] = keep
        dropped = sum(len(v) for v in carriers.values()) - sum(len(v) for v in kept.values())
        write_baseline({rel: {k: {"line": "", "kinds": v} for k, v in d.items()}
                        for rel, d in kept.items()}, stats,
                       base.get("_note", "G-015 carrier baseline (T-408)."))
        print("tightened: dropped %d stale entry/entries; baseline now %d file(s)."
              % (dropped, len(kept)))
        return 0

    census(stats, findings)
    print("baseline: %d grandfathered file(s), %d carrier line(s)"
          % (len(carriers), sum(len(v) for v in carriers.values())))

    if stale:
        print("\nRATCHET AVAILABLE — %d baseline entry/entries no longer present:" % len(stale))
        for rel, why in stale[:10]:
            print("  - %s: %s" % (rel, why))
        if len(stale) > 10:
            print("  ... and %d more" % (len(stale) - 10))
        print("  Run --tighten to drop them. Until then these slots stay open, which is "
              "why this notice is not silent.")

    if new:
        print("\nHYGIENE FAIL — %d carrier line(s) outside the baseline:" % len(new),
              file=sys.stderr)
        for rel, info in new:
            print("  - %s [%s]" % (rel, ", ".join(info["kinds"])), file=sys.stderr)
            print("      %s" % info["line"], file=sys.stderr)
        print("\nG-015: a ## Verification line must assert what ITS OWN TASK delivered, not "
              "a global that decays when anyone else edits the tree.", file=sys.stderr)
        print("  serve-root diff -> assert the feature instead, e.g. "
              "grep -q \"<the-thing-this-task-added>\" <artifact>", file=sys.stderr)
        print("  port literal     -> resolve it: "
              "PORT=$(cat .context/working/watchtower.port)", file=sys.stderr)
        return 1

    print("\nhygiene ok: no carrier outside the %d-file baseline." % len(carriers))
    return 0


if __name__ == "__main__":
    sys.exit(main())
