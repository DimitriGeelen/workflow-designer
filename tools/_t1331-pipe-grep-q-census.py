#!/usr/bin/env python3
"""_t1331-pipe-grep-q-census.py — `producer | grep -q` under `set -o pipefail` (T-1331, after T-1330).

THE DEFECT. `grep -q` exits at its first match and closes the pipe. A producer still writing then dies of SIGPIPE
(exit 141 for a shell command, BrokenPipeError for Python), and under pipefail the pipeline's status is that failure:
the condition reads FALSE although the match was found. T-1330: `_t344` piped a 660-line expander into `grep -qx`
with the matched path on line 1, failed 6 of 40 runs, and reddened the core tier while passing standalone (L-387).

WHAT IS SAFE. A builtin `echo`/`printf` of a string writes once into the pipe buffer before grep can read it, so it
cannot be cut off below the buffer size (64 KiB); a `head`/`sed -n` with a small bound writes little and stops. Every
other producer (python3, fw, git, curl, cat, sed over a file, a script) can still be writing when grep exits: RISKY.

THE FIX for a risky site: capture once, then grep the capture (`out=$(cmd); grep -q PAT <<<"$out"`, or redirect to a
file and grep the file).

Usage:
  _t1331-pipe-grep-q-census.py              list risky sites; exit 1 if the count exceeds the baseline
  _t1331-pipe-grep-q-census.py --all        also list the safe sites, with their class
  _t1331-pipe-grep-q-census.py --selftest   teeth: a planted risky line is flagged; captured and echo forms are not
Baseline: tools/_t1331-pipe-grep-q-baseline.txt (one integer; lower it when sites are fixed, never raise it to pass).
Exit 0 = at or below baseline (or selftest passed); 1 = above baseline (or selftest failed); 2 = misconfig.
"""
import os
import re
import sys
import tempfile

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
BASELINE = os.path.join(REPO, 'tools', '_t1331-pipe-grep-q-baseline.txt')
SCAN_DIRS = ('tools', 'tests', 'scripts')

PIPEFAIL = re.compile(r'^\s*set\s+(-[A-Za-z]*o\s+pipefail|-o\s+pipefail|.*\bpipefail\b)')
# `| grep` with -q among its short options (-q, -qE, -Eq, -qx …) or --quiet / --silent
GREP_Q = re.compile(r'\|\s*grep\s+((?:-[A-Za-z]*q[A-Za-z]*|--quiet|--silent)\b|(?:-[A-Za-z]+\s+)+-[A-Za-z]*q)')
# Command boundaries before the producer. `$(` opens a command substitution, but `$((` is arithmetic and is not one.
SPLIT = re.compile(r'\|\||&&|;|\$\((?!\()|`|(?<![$(])\((?!\()|\b(?:el)?if\b|\bthen\b|\bwhile\b|\buntil\b|\bdo\b|!\s')
# a line address: a number, ${VAR}, or $((expr)) — `sed -n "<addr>[,<addr>]p"` prints a few lines and stops
_ADDR = r'(?:\d+|\$\{?\w+\}?|\$\(\([^)]*\)\))'
SMALL_BOUND = re.compile(r'^(head|tail)\s+(-n\s*)?-?\d{1,3}\b|^sed\s+-n\s+[\'"]?' + _ADDR + r'(?:,' + _ADDR + r')?p[\'"]?\s')


def classify(producer):
    p = producer.strip()
    first = p.split()[0] if p.split() else ''
    if first in ('echo', 'printf'):
        return 'safe:builtin-string'
    if SMALL_BOUND.match(p):
        return 'safe:small-bound'
    return 'RISKY:command'


def producer_of(line, at):
    """The command feeding the pipe that ends at index `at` (the `|` before grep)."""
    left = line[:at]
    # the last pipe segment of the pipeline: text after the previous unrelated `|`
    seg = re.split(r'(?<!\|)\|(?!\|)', left)[-1]
    parts = SPLIT.split(seg)
    return parts[-1].strip() if parts else seg.strip()


def scan_file(path):
    try:
        text = open(path, encoding='utf-8', errors='replace').read()
    except OSError:
        return None
    lines = text.split('\n')
    if not any(PIPEFAIL.match(l) for l in lines):
        return None
    out = []
    for i, raw in enumerate(lines, 1):
        s = raw.lstrip()
        if s.startswith('#'):
            continue
        for m in GREP_Q.finditer(raw):
            prod = producer_of(raw, m.start())
            if not prod:
                continue
            out.append((i, classify(prod), prod[:90]))
    return out


def census(root):
    rows = []
    for d in SCAN_DIRS:
        base = os.path.join(root, d)
        for dp, dn, fn in os.walk(base):
            dn[:] = [x for x in dn if x not in ('node_modules', '.git', 'goldens', 'fixtures')]
            for f in sorted(fn):
                if not f.endswith('.sh'):
                    continue
                p = os.path.join(dp, f)
                for (ln, cls, prod) in scan_file(p) or []:
                    rows.append((os.path.relpath(p, root), ln, cls, prod))
    return sorted(rows)


def selftest():
    bad = 0
    with tempfile.TemporaryDirectory() as t:
        os.makedirs(os.path.join(t, 'tools'))
        body = '\n'.join([
            '#!/usr/bin/env bash', 'set -uo pipefail',
            'python3 expand.py w r | grep -qx "src/x.html" && echo ok',          # 3 risky
            'echo "$out" | grep -q PAT',                                            # 4 safe builtin
            'out=$(python3 expand.py w r); grep -qx "src/x.html" <<<"$out"',       # 5 not a pipe
            'if git log --oneline | grep -qE "^abc"; then :; fi',                   # 6 risky
            '# python3 x | grep -q y',                                              # 7 comment
            'head -2 "$f" | grep -q ok',                                            # 8 safe small bound
            'printf "%s\\n" "$x" | grep -Eq y',                                     # 9 safe builtin
            'elif echo "$out" | grep -q z; then :',                                 # 10 safe builtin after elif
            'sed -n "${W_LINE}p" "$f" | grep -q w',                                 # 11 safe one-line sed
            'sed -n "$((a-3)),${b}p" "$f" | grep -q w',                             # 12 safe few-line sed
            'sed -n "/x/,/y/p" "$f" | grep -q w',                                   # 13 risky: a pattern range
        ])
        open(os.path.join(t, 'tools', 'a.sh'), 'w').write(body)
        open(os.path.join(t, 'tools', 'nopf.sh'), 'w').write('#!/bin/bash\npython3 x | grep -q y\n')  # no pipefail
        rows = census(t)
        got = {(r[1], r[2].split(':')[0]) for r in rows}
        want = {(3, 'RISKY'), (4, 'safe'), (6, 'RISKY'), (8, 'safe'), (9, 'safe'), (10, 'safe'), (11, 'safe'),
                (12, 'safe'), (13, 'RISKY')}
        for w in sorted(want):
            ok = w in got
            bad += not ok
            print(f'  {"PASS" if ok else "FAIL"}  line {w[0]} classified {w[1]}')
        extra = {(r[1], r[2].split(':')[0]) for r in rows} - want
        if extra:
            bad += 1
            print(f'  FAIL  unexpected rows {sorted(extra)} (a capture, a comment or a non-pipefail file was flagged)')
        else:
            print('  PASS  the captured form, the comment and the non-pipefail file are not flagged')
    print('selftest: OK' if not bad else f'selftest: {bad} FAILED')
    return 0 if not bad else 1


def main():
    if '--selftest' in sys.argv:
        return selftest()
    rows = census(REPO)
    risky = [r for r in rows if r[2].startswith('RISKY')]
    for r in (rows if '--all' in sys.argv else risky):
        print(f'{r[2]:20} {r[0]}:{r[1]}  {r[3]}')
    try:
        base = int(open(BASELINE).read().strip())
    except (OSError, ValueError):
        print(f'misconfig: no readable baseline at {BASELINE}')
        return 2
    print(f'\nRATCHET  baseline {base}, risky now {len(risky)} (of {len(rows)} pipe-into-grep -q sites in pipefail scripts)')
    if len(risky) > base:
        print('FAIL: a new `command | grep -q` under pipefail. Capture the output, then grep the capture (T-1330).')
        return 1
    print('PASS: no increase.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
