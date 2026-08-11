#!/usr/bin/env python3
"""
_t429-apply-abstention-guard.py — insert the "no legs ran is not a pass" guard.

T-429.

WHY AN APPLIER AND NOT 35 HAND EDITS
------------------------------------
Thirty-five identical one-line judgements typed thirty-five times is thirty-five chances
to type it slightly differently, and the differences would be invisible — every variant
still exits 0 on a full green run. A single applier makes the edit auditable: the rule is
in one place, in the repo, and the census re-run afterwards is the check on the applier
rather than on my typing.

WHAT IT WILL NOT DO
-------------------
It refuses any file where it cannot identify the verdict block unambiguously, and it
reverts any file whose result fails `bash -n`. A blind insert into a working instrument
would be an UNVERIFIED FIX TO AN ABSTENTION BUG, which is the same family as the bug. The
skipped files are printed by name with the reason — never a silent partial pass.

THE fails-ONLY CASE
-------------------
Some suites tally only failures. `fails == 0` is then indistinguishable from `no leg ran`
using the file's own state, so a guard cannot be written from what is there — a leg counter
is injected into the assertion helper first. The helper is FOUND (first function whose body
increments a variable by one), never assumed by name.

USAGE
  python3 tools/_t429-apply-abstention-guard.py           # report only
  python3 tools/_t429-apply-abstention-guard.py --write   # edit in place
"""

import os
import re
import subprocess
import sys

ROOT = os.environ.get("T429_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(ROOT, "tools")

PASS_LIKE = re.compile(r"^(pass|passes|passed|ok|good|green)[a-z_]*$", re.I)
FAIL_LIKE = re.compile(r"^(fail|fails|failed|failures|err|errors|bad|red)[a-z_]*$", re.I)
INCREMENT = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$\(\(\s*\1\s*\+\s*1\s*\)\)")

# The verdict block: where the suite turns tallies into an exit code. Ordered by how
# unambiguous each shape is.
ANCHORS = [
    re.compile(r"^\s*if\s+\[+\s+\"?\$\{?(?:fail|fails|FAIL|FAILS)\}?\"?\s+-(?:eq|ne)\s+0\s+\]"),
    re.compile(r"^\s*\[+\s+\"?\$\{?(?:fail|fails|FAIL|FAILS)\}?\"?\s+-eq\s+0\s+\]+\s*\|\|\s*exit"),
    re.compile(r"^\s*echo\s+\"[^\"]*\$\{?(?:pass|PASS)\b[^\"]*\$\{?(?:fail|FAIL)\b"),
]

MARKER = "T-429 abstention guard"


def helper_body_span(src):
    """(start, end) of the first top-level function body containing a self-increment."""
    for m in re.finditer(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", src, re.M):
        start = m.end()
        depth, i = 1, start
        while i < len(src) and depth:
            if src[i] == "{":
                depth += 1
            elif src[i] == "}":
                depth -= 1
            i += 1
        if INCREMENT.search(src[start:i - 1]):
            return m.group(1), start, i - 1
    return None, None, None


def plan(path):
    """(guard_lines, new_src_prefix_edit, reason_if_skipped)"""
    src = open(path, encoding="utf-8", errors="replace").read()
    if MARKER in src:
        return None, None, "already guarded"

    names = {m.group(1) for m in INCREMENT.finditer(src)}
    passes = sorted(n for n in names if PASS_LIKE.match(n))
    fails = sorted(n for n in names if FAIL_LIKE.match(n))
    if not (passes or fails):
        return None, None, "no tally to guard on"

    lines = src.splitlines(keepends=True)
    anchor = None
    for rx in ANCHORS:
        for i, line in enumerate(lines):
            if rx.match(line):
                anchor = i
                break
        if anchor is not None:
            break
    if anchor is None:
        return None, None, "verdict block not identifiable — refusing a blind insert"

    if not passes:
        # FAILS-ONLY: refused deliberately, and the first draft of this applier did not
        # refuse — it injected a leg counter into the first function whose body increments
        # something, which in these files is `fail()`, the FAILURE REPORTER. A leg counter
        # driven by the failure reporter reads zero on a fully clean run, so the guard
        # would have fired on every green suite: a fix that manufactures the alarm it was
        # built to raise. bash -n caught the syntax accident (one-liner helpers) and said
        # nothing about the semantic one. Counting legs in these suites means reading how
        # each one is structured. That is a judgement per file, not a mechanical edit, and
        # this program has no business making it.
        return None, None, ("only failures are tallied — a clean run and an empty run are "
                            "identical in the file's own state; needs a per-suite leg counter")
    terms = " + ".join("${%s:-0}" % n for n in (passes[:1] + fails[:1]))
    prelude = ""

    guard = (
        '\n# %s — a suite that recorded no legs must not report success.\n'
        'if [ $(( %s )) -eq 0 ]; then\n'
        '  echo "ABSTAINED — no legs ran; this is not a pass." >&2\n'
        '  exit 2\n'
        'fi\n\n'
    ) % (MARKER, terms)

    return (lines, anchor, guard, prelude), src, None


def apply(path, built, src):
    lines, anchor, guard, prelude = built
    if prelude:
        varname, bstart = prelude
        # `${x:-0}` on the right-hand side, not a bare `$x`: these suites run under
        # `set -u`, where incrementing a never-initialised counter aborts the helper on its
        # first call. The first write pass failed on exactly that, on 9 files, and bash -n
        # did not catch it — it is a runtime error, not a syntax one. The revert-on-failure
        # path is why that cost nothing.
        src = src[:bstart] + ("\n  %s=$(( ${%s:-0} + 1 ))  # %s" % (varname, varname, MARKER)) + src[bstart:]
        # re-split after the injection so the anchor index still refers to the same line
        lines = src.splitlines(keepends=True)
        anchor = None
        for rx in ANCHORS:
            for i, line in enumerate(lines):
                if rx.match(line):
                    anchor = i
                    break
            if anchor is not None:
                break
        if anchor is None:
            return False, "anchor lost after leg-counter injection"
    out = "".join(lines[:anchor]) + guard + "".join(lines[anchor:])
    backup = open(path, encoding="utf-8", errors="replace").read()
    open(path, "w", encoding="utf-8").write(out)
    rc = subprocess.run(["bash", "-n", path], capture_output=True)
    if rc.returncode != 0:
        open(path, "w", encoding="utf-8").write(backup)
        return False, "bash -n rejected the result: %s" % rc.stderr.decode().strip()[:120]
    return True, None


def main():
    write = "--write" in sys.argv
    targets = sorted(f for f in os.listdir(TOOLS) if f.endswith(".sh"))
    done, skipped = [], []
    for name in targets:
        path = os.path.join(TOOLS, name)
        built, src, reason = plan(path)
        if reason:
            if reason != "no tally to guard on":
                skipped.append((name, reason))
            continue
        if not write:
            done.append((name, "would guard"))
            continue
        ok, err = apply(path, built, src)
        (done if ok else skipped).append((name, "guarded" if ok else err))

    print("=== T-429 abstention guard applier (%s) ===" % ("WRITE" if write else "dry run"))
    print()
    print("  candidates examined : %d .sh file(s) in tools/" % len(targets))
    print("  guarded             : %d" % len(done))
    print("  skipped             : %d" % len(skipped))
    for name, why in done:
        print("    OK   %-46s %s" % (name, why))
    for name, why in skipped:
        print("    SKIP %-46s %s" % (name, why))
    if skipped:
        print()
        print("  Skipped files are NOT fixed and are named above on purpose. A partial")
        print("  application reported as a whole one would be this task's own finding.")
    return 0 if done else 2


if __name__ == "__main__":
    sys.exit(main())
