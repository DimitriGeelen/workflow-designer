#!/usr/bin/env python3
"""
_t440-zero-population-census.py — the T-429 question, asked of .mjs and .py.

T-429 asked 35 bash suites "can you exit 0 having run no legs?" and got 35 yeses.
T-430 built teeth for one. This asks the same question of the two languages T-429
never touched: the CDP probes in `.mjs` (the instruments behind every "bridge green"
number reported across the AEF seam) and the `.py` checks (the ones cited in tasks'
`## Verification` blocks, i.e. the P-011 gate itself).

WHY A PORTED REGEX WOULD HAVE BEEN WRONG
----------------------------------------
T-429's tally detector looks for `n=$((n + 1))`. Ported to JS it finds 5 of 52 files,
because the JS idiom is `fails.push(x)` and `fails.length`. A census that under-counts
its own population is the bug it audits — the T-429 docstring says so about itself, and
this file is where that warning gets tested rather than quoted.

WHAT THIS FILE DOES AND DELIBERATELY DOES NOT DO
------------------------------------------------
It names the POPULATION and stops. It does not decide whether any instrument is blind.

The first version of this file tried to. It classified a tally as unreachable-when-empty
when every feed site was straight-line code, and reachable when a feed site sat inside a
loop over a discovered collection. On `_t293-endpoint-reach-cdp.mjs` that analysis says
UNREACHABLE, and it is wrong: the increment is `failures++` inside a helper `leg()`, and
whether `leg()` is ever called depends on call sites in another function forty lines away.
Deciding it needs interprocedural analysis, and a classifier that guesses at it produces
exactly the confident-but-unfounded verdict this census exists to find.

So reachability is settled by EXECUTION — `tools/_t440-drive-empty.sh` drives each member
to an empty population and reads what it prints. This file's job is to make sure that
harness knows who to drive, and to state the denominator it drew them from.

  IN-POPULATION   the process exit code is computed from a tally, so "how many did you
                  examine" is a question this instrument can get wrong
  NO-VERDICT      exit code is literal or absent — not an instrument in this sense
  UNREADABLE      never silently skipped

`_offpage-seam-parity-verify.py` is the reason the two layers are separate. It ends on
`sys.exit(0 if passed == total else 1)` with `total = len(results)` — read as a string,
the blind-pass shape exactly, since 0 == 0 exits 0. Read as a program, reaching that line
with an empty `results` means an exception was raised first, which is not exit 0. Only
running it tells you which.

EXIT
  0  the population is non-empty and stated
  2  cannot answer — no tools dir, or nothing examined. Never "all clean".
"""

import os
import re
import sys

ROOT = os.environ.get("T440_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(ROOT, "tools")

# ---------------------------------------------------------------- population discovery
# Collections whose size is decided at RUNTIME. A loop over one of these can iterate zero
# times. Deliberately broad: over-including a source here costs a REACHABLE classification
# that execution can then refute, while under-including it hides an instrument entirely.
DISCOVERED = re.compile(
    r"\b(glob|iglob|rglob|listdir|readdir|readdirSync|scandir|walk|"
    r"matchAll|findall|finditer|splitlines|split|"
    r"argv|\.filter\(|\.keys\(|\.values\(|\.entries\(|querySelectorAll|"
    r"json\.load|JSON\.parse|fetch|read_text|readFileSync)\b"
)

# A verdict is an exit whose code is computed, not literal — that is where a tally reaches
# the outside world.
VERDICT_PY = re.compile(r"(?:sys\.exit|return)\s*\(?\s*(.*(?:passed|fail|err|bad|ok|total|len|count|issues|problems|rows|findings|viol)[^\n]*)")
VERDICT_JS = re.compile(r"(?:process\.exit|process\.exitCode\s*=|return)\s*\(?\s*([^\n;]*(?:fail|err|bad|ok|good|issues|problems|rows|findings|viol|results)[^\n;]*)")

IDENT = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\b")
TALLY_WORDS = ("fail", "err", "bad", "ok", "good", "pass", "issue", "problem",
               "row", "finding", "viol", "result", "total", "count", "miss", "leg")


def tallies_in(expr):
    """Identifiers in an expression that are named like a tally.

    NOT a regex with a mandatory prefix. The first version of this was
    `[A-Za-z_][A-Za-z0-9_]*(?:fail|pass|...)` — which requires at least one character
    BEFORE the keyword, so `failures` and `passed` could never match and only an
    identifier like `xfailures` would. The census then reported 88 of 101 files as
    out-of-population and printed PASS. It was a census with the defect it audits:
    a clean verdict over a population its own enumeration had emptied. Caught only
    because the header prints the denominator — which is the whole argument for
    printing it.
    """
    return sorted({i for i in IDENT.findall(expr)
                   if any(w in i.lower() for w in TALLY_WORDS)})

# Something that converts "nothing was examined" into a non-success outcome.
# Two mechanisms, and a classifier that knows only the first mislabels `_t338`:
#   (1) exit-guard  — empty population reaches a non-zero exit / raise directly
#   (2) tally-guard — empty population is PUSHED ONTO the failure tally that drives
#                     the verdict, e.g. `if (applied === 0) problems.push('nothing was
#                     measured')`. Same effect, opposite direction.
EMPTY_TEST = re.compile(
    r"(?:if\s*\(?\s*!\s*\w+(?:\.length|\.size)?\s*\)?"                 # if (!files.length)
    r"|\w+(?:\.length|\.size)\s*(?:===?|<)\s*(?:0|1)\b"                # files.length === 0
    r"|\b(?:len|count)\s*\([^)]*\)\s*(?:===?|<)\s*(?:0|1)\b"           # len(rows) == 0
    r"|if\s+not\s+\w+\s*:"                                             # if not rows:
    r"|\bapplied\s*===?\s*0\b"
    r"|\b\w+\s*===?\s*0\b)"
)
GUARD_ACTION = re.compile(
    r"(?:exit\s*\(?\s*[1-9]"          # exit 1 / exit 2 / process.exit(2)
    r"|exitCode\s*=\s*[1-9]"
    r"|\braise\b|\bthrow\b"
    r"|ABSTAIN|UNKNOWN|CANNOT"
    r"|\.push\(|\.append\()"           # tally-guard: emptiness becomes a finding
)


def classify(path, src, lang):
    """-> (verdict, evidence)."""
    lines = src.splitlines()
    vre = VERDICT_PY if lang == "py" else VERDICT_JS

    # 1. Is there a computed verdict at all? Take EVERY one, not the first — an early
    # `process.exit(2)` usage guard is also a verdict-shaped line, and stopping there
    # would classify the file on a line that decides nothing about its findings.
    names, verdict_line = set(), None
    for i, ln in enumerate(lines):
        if re.match(r"\s*(#|//|\*)", ln):
            continue
        m = vre.search(ln)
        if not m:
            continue
        found = tallies_in(m.group(1))
        if found:
            names.update(found)
            verdict_line = (i + 1, ln.strip(), m.group(1))
    if verdict_line is None:
        return "NO-VERDICT", "no exit code computed from a tally"

    # 2. In population. Record the knob the drive harness can use to empty it, if any.
    #    This is a HINT for _t440-drive-empty.sh, never a verdict: a file with no knob
    #    is not thereby safe, it is un-drivable, which the harness reports as such.
    knobs = sorted({m.group(1) for m in re.finditer(
        r"\b(T\d{3}_[A-Z_]+|[A-Z][A-Z0-9_]*_(?:CORPUS|ROOT|DIR|URL|BASE))\b", src)})
    argv = bool(re.search(r"(?:process\.argv\.slice|sys\.argv\[1:\]|argparse)", src))
    corpus = bool(re.search(r"\b(CORPUS|MAPS_DIR|FIXTURES)\b", src))

    return ("IN-POPULATION",
            "verdict :%d over %s%s%s%s"
            % (verdict_line[0], "/".join(sorted(names)),
               "  env:" + ",".join(knobs) if knobs else "",
               "  argv" if argv else "",
               "  corpus-const" if corpus and not knobs else ""))


def main():
    if not os.path.isdir(TOOLS):
        print("UNKNOWN — no tools/ under %s. Nothing examined; this is not a pass." % ROOT)
        return 2

    files = sorted(f for f in os.listdir(TOOLS) if f.endswith((".mjs", ".py")))
    rows, unreadable = [], []
    for name in files:
        if name == os.path.basename(__file__):
            continue  # the census does not grade itself; _t440-drive-empty.sh does
        try:
            src = open(os.path.join(TOOLS, name), encoding="utf-8", errors="replace").read()
        except OSError as exc:
            unreadable.append((name, exc))
            continue
        lang = "py" if name.endswith(".py") else "mjs"
        verdict, evidence = classify(name, src, lang)
        rows.append((name, lang, verdict, evidence))

    if not rows:
        print("UNKNOWN — tools/ holds no .mjs or .py files. A census of nothing is not a PASS.")
        return 2

    pop = [r for r in rows if r[2] == "IN-POPULATION"]
    noverdict = [r for r in rows if r[2] == "NO-VERDICT"]

    if os.environ.get("T440_LIST"):                 # machine-readable feed for the harness
        for name, _lang, _v, _ev in pop:
            print(name)
        return 0 if pop else 2

    print("=== T-440: who can report success having examined nothing? (population only) ===")
    print()
    print("  examined         %d of %d .mjs/.py file(s) in tools/" % (len(rows), len(files)))
    print("    .mjs %d   .py %d" % (sum(1 for r in rows if r[1] == "mjs"),
                                    sum(1 for r in rows if r[1] == "py")))
    print("  unreadable       %d" % len(unreadable))
    print()
    print("  NO-VERDICT       %d  (exit code literal or absent — not an instrument in this sense)"
          % len(noverdict))
    print("  IN-POPULATION    %d  (exit code computed from a tally — CAN get its denominator wrong)"
          % len(pop))

    for name, exc in unreadable:
        print("  UNREADABLE %s: %s" % (name, exc))

    print()
    for name, lang, _v, ev in pop:
        print("  %-44s %s" % (name, ev))

    print()
    print("  This file makes NO claim about which of the %d is blind. That is decided by" % len(pop))
    print("  driving each to an empty population — tools/_t440-drive-empty.sh.")

    if not pop:
        print()
        print("UNKNOWN — a population of zero. Either every instrument computes a literal exit")
        print("  code, or this enumeration is too narrow. It has been too narrow once already")
        print("  (see tallies_in), so a zero here is a reason to check, not to relax.")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
