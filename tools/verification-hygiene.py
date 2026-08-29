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
# A port literal is either host-qualified (`http://192.168.10.107:3000`, `localhost:8834`,
# `127.0.0.1:8834`) or bare (`:3000`, `:8834`). The original `:(\d{2,5})\b` matched the
# colon-number in ANY context, which is fine for prose but these are EXECUTABLE lines, and
# there the same characters occur in shapes that are not ports at all:
#     [:400]            Python/shell slice        (T-461, T-462)
#     T-2553:101        a task/rail reference     (T-449)
#     update-task.sh:1018   a file:line citation
#     13:13             a timestamp
# Three of the four carriers this tool had accumulated since 2026-08-09 were of exactly
# that kind — noise, not findings. They went unnoticed because the tool has no standing
# caller (it is line 130 of tools/unwired-guard-baseline.txt), so nothing ever read its
# output. Discovered by wiring it, which is the point of wiring it.
# The discriminator: every false shape above has a WORD CHARACTER or `[` immediately before
# the colon, and every genuine bare port has whitespace, a quote or a line start. Genuine
# host-qualified ports keep their own alternative so `localhost:8834` still matches despite
# the preceding letter.
RE_PORT = re.compile(
    r"(?:localhost|\d{1,3}(?:\.\d{1,3}){3}|//[A-Za-z0-9.-]+):\d{2,5}\b"  # host-qualified
    r"|(?<![\w.\[/-]):\d{2,5}\b"                                          # bare :PORT
)

KIND_DIFF = "serve-root-diff"
KIND_PORT = "hardcoded-port"

# ── Third carrier shape (T-508, PL-200) ──────────────────────────────────────────────
# Same G-015 defect as (a) and (b): a line asserting a GLOBAL, always-moving property
# rather than a property of the task carrying it. Here the moving property is the SIZE OF
# A POPULATION — `ls examples/aef-processes/rendered/*.bpmn | wc -l` = 24 is true only
# while the corpus never grows, and a corpus is designed to grow. The literal 24 is
# replicated across seven task files, so one corpus addition falsifies all of them at once.
#
# WHY IT SURFACED ONLY NOW. A P-011 block is a ONE-SHOT gate here — it runs at
# work-completed and never again — so a stale count is unobservable by construction. AEF's
# CTL-013 re-runs verification on completed tasks DAILY. Same line, mirror-image failure
# modes: stale silently here, red spuriously there (PL-200). Adopting a CTL-013-style
# re-runner is the obvious thing to take from that exchange, and doing it against this tree
# would light these up on day one and read as "the re-runner is broken".
#
# THREE NEAR-IDENTICAL SHAPES ARE **NOT** CARRIERS, and getting this wrong would be worse
# than not detecting at all — it would push authors to weaken real invariants into `-ge`:
#   INVARIANT  `grep -c 'cleanLayout()' src/app.html` = 2
#              Occurrences of a token in a NAMED file. "Exactly two call sites" IS the
#              assertion, and it is a property of the code, not of a moving population.
#   EMPTINESS  `grep -rl 'forbidden' src/ | wc -l` = 0
#              Counts a population but pins it to ZERO. "None of these exist" does not go
#              stale as the corpus grows; it goes red only on a genuine regression.
#   HERMETIC   `d=$(mktemp -d) && … | wc -l` = 1
#              Counts a population the line CONSTRUCTED in the same breath. It cannot
#              drift. Found by inspecting a first run that flagged T-462's grep-behaviour
#              probe, not predicted — the exclusion is deliberate, not an accident of regex.
#
# Already-repaired lines are also not carriers: `-ge N` is the remedy shape (T-095, T-096
# both carry `-ge N  # was =N; call sites grew legitimately`), so matching only `=`/`-eq`
# keeps the tool from flagging its own fix.
KIND_POP = "population-pinned"

RE_COUNTER = re.compile(r"(\bwc\s+-[lcmw]|\bgrep\s+-[a-zA-Z]*c)")
RE_LITERAL = re.compile(r'(?:==?\s*"?(\d+)"?(?:\s|$|\))|-eq\s+(\d+)\b)')
RE_ENUMERATOR = re.compile(
    r"(\bls\b"
    r"|\bfind\b"
    r"|git\s+ls-files"
    r"|\bgrep\s+-[a-zA-Z]*r[a-zA-Z]*l\b"   # grep -rl: prints FILENAMES, so it enumerates
    r"|\bgrep\s+-[a-zA-Z]*l[a-zA-Z]*\b"
    r"|\bfor\s+\w+\s+in\s+\$\("
    r")"
)
RE_HERMETIC = re.compile(r"\bmktemp\b")


def is_population_pinned(line):
    """True when the line pins a NON-ZERO literal to the size of a population it did not
    construct. See the block comment above for the three shapes deliberately excluded."""
    if not RE_COUNTER.search(line) or not RE_ENUMERATOR.search(line):
        return False
    m = RE_LITERAL.search(line)
    if not m:
        return False
    if int(m.group(1) if m.group(1) is not None else m.group(2)) == 0:
        return False
    return not RE_HERMETIC.search(line)


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
    if is_population_pinned(line):
        kinds.append(KIND_POP)
    return kinds


def line_key(line):
    return hashlib.sha256(line.strip().encode("utf-8")).hexdigest()[:16]


def scan():
    """-> (findings, stats, collisions). findings: task-file BASENAME -> {key: {...}}.

    KEYED ON BASENAME, NOT RELPATH (T-409). `work-completed` MOVES a task file from
    .tasks/active/ to .tasks/completed/. A relpath key made that move look like a brand
    new carrier appearing at an unseen path, so the ratchet went red about a task nobody
    had edited — and it fired exactly when the operator finally acted on G-015, making the
    guard look like it was punishing the fix. All three remaining active carriers (T-093,
    T-102, T-105) were queued for precisely that move.

    Directory membership is LIFECYCLE STATE and moves by design; the task is the same task
    either side of it. Identity must not be carried by the moving property (PL-083, and the
    same lesson as T-399's path-vs-sha split).
    """
    paths = sorted(glob.glob(os.path.join(ROOT, ".tasks", "active", "*.md"))
                   + glob.glob(os.path.join(ROOT, ".tasks", "completed", "*.md")))
    findings = {}
    seen_at = {}
    collisions = []
    stats = {"task_files": len(paths), "with_block": 0, "exec_lines": 0,
             KIND_DIFF: 0, KIND_PORT: 0, KIND_POP: 0}
    for p in paths:
        rel = os.path.relpath(p, ROOT)
        name = os.path.basename(p)
        # A basename in BOTH active/ and completed/ would let one file's exemption cover
        # the other's carrier. Rare (work-completed moves rather than copies) but it is
        # the one way basename keying could launder a carrier, so it fails loudly.
        if name in seen_at:
            collisions.append((name, seen_at[name], rel))
        else:
            seen_at[name] = rel
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
            findings.setdefault(name, {})[line_key(ln)] = {
                "line": ln.strip(), "kinds": kinds, "where": rel}
    return findings, stats, collisions


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
            KIND_POP: stats[KIND_POP],
        },
        "carriers": {rel: {k: v["kinds"] for k, v in sorted(d.items())}
                     for rel, d in sorted(findings.items())},
    }
    with open(BASELINE, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=1, sort_keys=False)
        fh.write("\n")
    return data


def census(stats, findings):
    print("population: files=%d with-block=%d lines=%d %s=%d %s=%d %s=%d carrier-files=%d"
          % (stats["task_files"], stats["with_block"], stats["exec_lines"],
             KIND_DIFF, stats[KIND_DIFF], KIND_PORT, stats[KIND_PORT],
             KIND_POP, stats[KIND_POP], len(findings)))


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--tighten", action="store_true")
    ap.add_argument("--adopt", action="store_true")
    args = ap.parse_args()

    findings, stats, collisions = scan()

    # ANTI-VACUITY (PL-084). A scan reporting "zero violations" must state whether the
    # population it scanned was non-empty. Every exit below this point is a claim about
    # a real population, or it is an error.
    if stats["task_files"] == 0 or stats["with_block"] == 0:
        print("VACUOUS: scanned %d task file(s), %d with a ## Verification block. A clean "
              "verdict over an empty population is a bug, not a pass."
              % (stats["task_files"], stats["with_block"]), file=sys.stderr)
        return 2

    # Basename keying is only safe while basenames are unique across the two directories.
    if collisions:
        print("COLLISION: %d task-file basename(s) appear in BOTH .tasks/active/ and "
              ".tasks/completed/. Baseline entries are keyed on basename, so one file's "
              "exemption would cover the other's carrier:" % len(collisions), file=sys.stderr)
        for name, a, b in collisions:
            print("  - %s\n      %s\n      %s" % (name, a, b), file=sys.stderr)
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
    #
    # Presence is decided by whether the SCAN still finds the task file, not by testing a
    # stored path on disk. The stored-path test was the T-409 defect's other half: it called
    # a completed task "gone" purely because it had moved out of active/.
    stale = []
    for name, keys in sorted(carriers.items()):
        present = findings.get(name)
        if present is None:
            # `findings` holds only files that STILL CARRY a carrier line, so "absent from
            # findings" has two causes that a reader must not confuse: the file was deleted,
            # or the file was fully CLEANED and is sitting right there. Reporting the second
            # as "deleted?" sends whoever is ruling on this baseline hunting for a file that
            # exists. That is the T-409 defect noted above wearing a different route: the
            # stored-path test was replaced, and the conflation came back through the scan.
            # Decide it by looking, not by inferring from an absence.
            on_disk = glob.glob(os.path.join(ROOT, ".tasks", "*", name))
            if on_disk:
                stale.append((name, "all carrier lines removed, file is clean (%s)"
                                    % os.path.relpath(on_disk[0], ROOT)))
            else:
                stale.append((name, "task file no longer present under .tasks/ (deleted?)"))
            continue
        for key in sorted(keys):
            if key not in present:
                stale.append((name, "carrier line removed (%s)" % key))

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
        for name, info in new:
            print("  - %s [%s]" % (info.get("where", name), ", ".join(info["kinds"])),
                  file=sys.stderr)
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
