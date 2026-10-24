#!/usr/bin/env python3
"""_t1288-tier-guard.py — every leg of a tiered runner has exactly one declared tier (832 T-1288).

tests/run-bridge-tests.sh registers each leg with one line, `leg <tier> <name> <fn> [args]` (tools/_t1288-tiers.sh).
A leg added the old way, as a bare `if ...; then pass=$((pass + 1)) ...` block at column 0, would run in EVERY tier
(core included, browser or not) and no tier would own it. This guard fails that, statically:

  1. no counted check (`pass=$((` / `fail=$((`) at top level outside a function, unless its first line carries the
     marker `# T-1288: every tier` (the guard's own call in the runner);
  2. every function that counts is registered by a `leg` line, or called from one that is;
  3. every `leg` line names a tier: a literal core|browser|sweep, or a variable taken from the first field of the
     entries of the array its `for` loop walks, each of which must then be core|, browser| or sweep|.

Without --static it also runs the runner with --list-legs (nothing executes) and checks the names are unique, no
leg reports NO-TIER, and every tests/quarantine.yaml entry names a real leg; it prints the count per tier.

    python3 tools/_t1288-tier-guard.py [--static] [RUNNER]     (default RUNNER: tests/run-bridge-tests.sh)

Exit 0 clean, 1 a finding, 2 cannot evaluate (no runner, or no `leg` line at all: a guard over zero legs is vacuous).
"""
import os
import re
import subprocess
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TIERS = ("core", "browser", "sweep")
COUNT = re.compile(r'\b(?:pass|fail)=\$\(\(')
OPEN = re.compile(r'^(if|for|while|until|case)\b')
CLOSE = re.compile(r'^(fi|done|esac)\b')
SAME_LINE_CLOSE = re.compile(r';\s*(fi|done|esac)\s*(#.*)?$')
FUNC = re.compile(r'^([A-Za-z_]\w*)\(\)\s*\{')
ARRAY = re.compile(r'^([A-Za-z_]\w*)=\(\s*$')
LEG = re.compile(r'^\s*leg\s+("[^"]*"|\S+)\s+("[^"]*"|\S+)\s+([A-Za-z_]\w*)\b')
MARK = "# T-1288: every tier"


def code(line):
    return "" if line.lstrip().startswith("#") else line


def parse(lines):
    """-> functions {name: (start, end)}, arrays {name: [entries]}, top-level statements [(start, end)]"""
    funcs, arrays, stmts = {}, {}, []
    i = 0
    while i < len(lines):
        l = lines[i]
        if not l.strip() or l.lstrip().startswith("#"):
            i += 1
            continue
        m = FUNC.match(l)
        if m:
            if l.rstrip().endswith("}"):
                funcs[m.group(1)] = (i, i)
                i += 1
                continue
            j = i + 1
            while j < len(lines) and not lines[j].startswith("}"):
                j += 1
            funcs[m.group(1)] = (i, j)
            i = j + 1
            continue
        m = ARRAY.match(l)
        if m:
            j = i + 1
            entries = []
            while j < len(lines) and not lines[j].startswith(")"):
                e = lines[j].strip()
                if e and not e.startswith("#"):
                    entries.append(e.strip("'\""))
                j += 1
            arrays[m.group(1)] = entries
            i = j + 1
            continue
        if OPEN.match(l) and not SAME_LINE_CLOSE.search(l):
            depth, j = 1, i + 1
            while j < len(lines) and depth:
                if OPEN.match(lines[j]) and not SAME_LINE_CLOSE.search(lines[j]):
                    depth += 1
                elif CLOSE.match(lines[j]):
                    depth -= 1
                j += 1
            stmts.append((i, j - 1))
            i = j
            continue
        j = i
        while lines[j].rstrip().endswith("\\") and j + 1 < len(lines):
            j += 1
        stmts.append((i, j))
        i = j + 1
    return funcs, arrays, stmts


def static_check(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    funcs, arrays, stmts = parse(lines)
    findings = []
    legs = []   # (line, tier-token, name-token, fn)
    for a, b in stmts:
        body = [code(x) for x in lines[a:b + 1]]
        for k, x in enumerate(body):
            m = LEG.match(x)
            if m:
                legs.append((a + k + 1, m.group(1), m.group(2), m.group(3), (a, b)))
        if any(COUNT.search(x) for x in body) and MARK not in lines[a]:
            findings.append(f"line {a + 1}: a counted check runs at top level, outside any registered leg — wrap it in "
                            f"a function and register it with `leg <tier> <name> <fn>`: {lines[a].strip()[:90]}")
    if not legs:
        return None, ["no `leg <tier> <name> <fn>` line found: nothing to evaluate"]
    registered = {fn for _, _, _, fn, _ in legs}
    counting = {n for n, (a, b) in funcs.items() if any(COUNT.search(code(x)) for x in lines[a:b + 1])}
    for fn in sorted(counting - registered):
        callers = [r for r in registered if r in funcs and re.search(r'(^|[\s;(])' + re.escape(fn) + r'\b',
                   "\n".join(code(x) for x in lines[funcs[r][0] + 1:funcs[r][1] + 1]))]
        if not callers:
            a, _ = funcs[fn]
            findings.append(f"line {a + 1}: function {fn} counts checks but no `leg` line registers it (nor calls it "
                            f"from a registered leg), so no tier owns it")
    for ln, tier, name, fn, (a, b) in legs:
        if fn not in funcs:
            findings.append(f"line {ln}: leg {name} registers {fn}, which is not defined in this file")
        t = tier.strip('"')
        if t in TIERS:
            continue
        mv = re.fullmatch(r'\$\{?(\w+)\}?', t)
        loop = re.match(r'^for\s+(\w+)\s+in\s+"\$\{(\w+)\[@\]\}"', lines[a])
        if not mv or not loop or loop.group(2) not in arrays:
            findings.append(f"line {ln}: leg {name} has no tier: '{tier}' is not core|browser|sweep, nor the first "
                            f"field of the entries of the array its loop walks")
            continue
        for e in arrays[loop.group(2)]:
            if e.split("|", 1)[0] not in TIERS:
                findings.append(f"array {loop.group(2)}: entry has no tier (want 'core|…', 'browser|…' or "
                                f"'sweep|…'): {e[:80]}")
    return legs, findings


def list_check(path):
    """-> (Counter of tiers, findings) from running the runner with --list-legs"""
    findings = []
    p = subprocess.run(["bash", path, "--list-legs"], capture_output=True, text=True, timeout=120,
                       stdin=subprocess.DEVNULL)
    rows = [l.split(" ", 1) for l in p.stdout.splitlines() if re.match(r'^(core|browser|sweep|NO-TIER) ', l)]
    if p.returncode != 0 and not any(r[0] == "NO-TIER" for r in rows):
        findings.append(f"--list-legs exited {p.returncode}: {(p.stderr or p.stdout).strip()[-300:]}")
    names = Counter(r[1] for r in rows)
    for r in rows:
        if r[0] == "NO-TIER":
            findings.append(f"leg has no tier at run time: {r[1]}")
    for n, c in names.items():
        if c > 1:
            findings.append(f"leg name declared {c} times: {n} (names key the quarantine)")
    qf = os.environ.get("T1288_QUARANTINE", os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(path))),
                                                         "tests", "quarantine.yaml"))
    if os.path.isfile(qf):
        import yaml
        doc = yaml.safe_load(open(qf, encoding="utf-8")) or {}
        for e in doc.get("quarantine") or []:
            if e.get("leg") not in names:
                findings.append(f"{os.path.relpath(qf)}: entry names no leg: {e.get('leg')!r}")
    return Counter(r[0] for r in rows), findings


def main(argv):
    static_only = "--static" in argv
    args = [a for a in argv if a != "--static"]
    path = args[0] if args else os.path.join(ROOT, "tests", "run-bridge-tests.sh")
    if not os.path.isfile(path):
        print(f"CANNOT EVALUATE: no runner at {path}")
        return 2
    legs, findings = static_check(path)
    if legs is None:
        print("CANNOT EVALUATE: " + findings[0])
        return 2
    summary = f"{len(legs)} leg line(s)"
    if not static_only:
        tiers, more = list_check(path)
        findings += more
        summary += ", run-time legs: " + ", ".join(f"{t} {tiers.get(t, 0)}" for t in TIERS)
    if findings:
        print(f"T-1288 tier guard FAIL — {len(findings)} finding(s) ({summary}):")
        for f in findings:
            print("  " + f)
        return 1
    print(f"T-1288 tier guard OK — {summary}, every one with a tier")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
