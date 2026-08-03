#!/usr/bin/env python3
"""T-353 AC3 + AC4 — convert the 19 DIVERGENT lines and prove the conversions.

All 19 are FAILURE-PATH-CORRECT (AC2, tools/_t353-classify.py): a command that exits
non-zero BY DESIGN, with an assertion about that designed failure.  Today the gate
discards the non-zero exit; under the remedy it kills the line.  Neither is the line
saying what it means.

The conversion makes the expectation explicit — the command that is *supposed* to fail
gets `|| true`, so the line's verdict rests entirely on its assertion:

    out=$(validate BROKEN 2>&1); echo "$out" | grep -q "E-CODE"
    out=$(validate BROKEN 2>&1 || true); echo "$out" | grep -q "E-CODE"

Three legs per line, and the first is the one that carries the argument:

  1  ORIGINAL  + REMEDY  -> must FAIL   (the conversion is not a no-op)
  2  CONVERTED + REMEDY  -> must PASS   (ready for the gate change)
  3  CONVERTED + CURRENT -> must PASS   (no regression before it lands)

Leg 1 is what stops this from being a ritual.  Without it, a conversion that changed
nothing would score 2/2 and the corpus would be declared ready on the strength of lines
that were already fine.  Both gate constructs are EXTRACTED from update-task.sh, so the
readiness claim is about the real gate rather than a quote of it.
"""

import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GATE_SRC = os.environ.get(
    "GATE_SRC", os.path.join(ROOT, ".agentic-framework", "agents", "task-create", "update-task.sh")
)
REPORT = os.path.join(ROOT, "docs", "reports", "T-352-member-scan.md")


def extract_gate():
    src = open(GATE_SRC).read().splitlines()
    hits = [l for l in src if re.match(r"^\s*if .*\$cmd", l)]
    if len(hits) != 1:
        sys.stderr.write(
            "EXTRACT_ERROR: expected exactly 1 gate line matching '^\\s*if .*$cmd', found %d\n"
            % len(hits)
        )
        sys.exit(1)
    line = re.sub(r";\s*then$", "", re.sub(r"^if\s+", "", hits[0].strip()))
    remedy = line.replace(
        'eval "$cmd"', "bash -c 'set -eo pipefail; eval \"$1\"' _ \"$cmd\""
    )
    if remedy == line:
        sys.stderr.write(
            "REMEDY_ERROR: substitution produced an identical construct — every leg would "
            "measure the current gate twice and silently report readiness.\n"
        )
        sys.exit(1)
    return line, remedy


def matching_close(s, open_idx):
    """Index of the `)` matching the `(` at open_idx, quote-aware."""
    depth = 0
    sq = dq = False
    i = open_idx
    while i < len(s):
        ch = s[i]
        if sq:
            if ch == "'":
                sq = False
        elif dq:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                dq = False
        elif ch == "\\":
            i += 2
            continue
        elif ch == "'":
            sq = True
        elif ch == '"':
            dq = True
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def convert(line):
    """Append `|| true` inside every `VAR=$(...)` capture in the line.

    Only ASSIGNMENTS are touched.  A `$(...)` used as a value inside the assertion
    (`test "$(echo "$out" | grep -c X)" = "1"`) is part of the verdict and must keep
    its exit semantics — blanketing it would make the assertion unable to fail.
    """
    out = line
    pos = 0
    while True:
        m = re.search(r"(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)=\$\(", out[pos:])
        if not m:
            return out
        open_idx = pos + m.end() - 1
        close_idx = matching_close(out, open_idx)
        if close_idx < 0:
            return out
        inner = out[open_idx + 1 : close_idx]
        if "|| true" in inner:
            pos = close_idx
            continue
        out = out[:close_idx] + " || true" + out[close_idx:]
        pos = close_idx + len(" || true") + 1


def run_gate(cond, cmd):
    script = (
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n"
        '_close_locks_cmd=""\n'
        "PROJECT_ROOT=%s\n" % subprocess.list2cmdline([ROOT])
        + 'cmd="$CMD_UNDER_TEST"\n'
        + "if %s; then echo GATE_PASS; else echo GATE_FAIL; fi\n" % cond
    )
    env = dict(os.environ)
    env["CMD_UNDER_TEST"] = cmd
    try:
        p = subprocess.run(
            ["bash", "-c", script],
            capture_output=True,
            text=True,
            env=env,
            cwd=ROOT,
            timeout=120,
        )
    except subprocess.TimeoutExpired:
        return "GATE_TIMEOUT"
    tail = [l for l in p.stdout.splitlines() if l.strip()]
    last = tail[-1] if tail else ""
    return last if last in ("GATE_PASS", "GATE_FAIL") else "GATE_BROKEN(%s)" % last


def extract_members():
    text = open(REPORT).read()
    m = re.search(r"^## PROVEN members$(.*?)^## ", text, re.M | re.S)
    if not m:
        sys.stderr.write("EXTRACT_ERROR: could not locate '## PROVEN members'\n")
        sys.exit(1)
    members = []
    for line in m.group(1).splitlines():
        mm = re.match(r"^-\s+\*\*(T-\d+)\*\*\s+—\s+`(.*)`\s*$", line)
        if mm:
            members.append((mm.group(1), mm.group(2)))
    if not members:
        sys.stderr.write("EXTRACT_ERROR: section found but no members parsed\n")
        sys.exit(1)
    return members


def main():
    cur, rem = extract_gate()
    members = extract_members()
    print("== T-353 conversion probe (AC3 + AC4) ==")
    print("members: %d\n" % len(members))

    npass = nfail = 0
    unconverted = []
    for task, line in members:
        conv = convert(line)
        if conv == line:
            unconverted.append((task, line, "no capture assignment found to convert"))
            print("SKIP %s — no capture assignment to convert\n    %s\n" % (task, line))
            continue
        legs = [
            ("leg1 original+remedy   (conversion is not a no-op)", run_gate(rem, line), "GATE_FAIL"),
            ("leg2 converted+remedy  (ready for the gate change)", run_gate(rem, conv), "GATE_PASS"),
            ("leg3 converted+current (no regression today)", run_gate(cur, conv), "GATE_PASS"),
        ]
        bad = [(n, got, want) for n, got, want in legs if got != want]
        if bad:
            nfail += 1
            print("FAIL %s" % task)
            print("    orig: %s" % line)
            print("    conv: %s" % conv)
            for n, got, want in bad:
                print("      %s : expected %s, got %s" % (n, want, got))
            print()
            unconverted.append((task, line, "; ".join("%s got %s" % (n, g) for n, g, _ in bad)))
        else:
            npass += 1
            print("ok   %s  3/3" % task)

    print("\n== RESULT ==")
    print("  converted and proven : %d" % npass)
    print("  failed or skipped    : %d" % nfail)
    if unconverted:
        print("\n  MEMBERS LEFT, with the reason each was left (AC4):")
        for task, line, why in unconverted:
            print("    - %s: %s" % (task, why))
            print("        %s" % line)
    print(
        "\n  DIVERGENT remaining after conversion: %d"
        % (len(members) - npass)
    )
    return 0 if npass == len(members) else 1


if __name__ == "__main__":
    sys.exit(main())
