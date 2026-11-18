#!/usr/bin/env python3
"""check-vacuous-verification.py — find `## Verification` legs that cannot fail.

Two defect shapes, both of which report health regardless of whether the thing they
guard actually worked:

  LOUD   grep -qv PATTERN
         `-v` selects NON-matching lines and `-q` exits 0 if ANY line is selected, so the
         leg asserts "at least one line lacks PATTERN" — true of nearly every multi-line
         file, and true whether or not the banned thing is present. (T-590 AC5: a fixture
         with the exact construct it forbids still passed.)

  QUIET  out=$(cmd 2>&1); echo "$out" | grep -q PATTERN
         The pipe discards cmd's own exit status and substitutes a text heuristic on its
         output. P-011 runs each line as the CONDITION of an `if`, which neutralises
         errexit, so `a; b` is judged on `b` alone (T-352) — a command that fails outright
         leaves the line green. Proven: a command exiting 1 while printing "3 passed, 2
         FAILED" passes `grep -q "passed"`. Credit: 010-termlink, rail 479, who generalised
         this past the `-v` case.

  The honest forms: the bare command (where it already exits non-zero on failure), or
  CLAUDE.md's file form `cmd > /tmp/.out 2>&1 && grep -q PAT /tmp/.out`, where `&&`
  preserves the exit status. The PIPE is what is reported, not the presence of `&&` — a
  line can carry both, and `out=$(cmd); echo "$out" | grep -q X && ...` is still defective.

LIVE RISK vs HISTORICAL RESIDUE. Completed tasks' Verification blocks are never re-run —
they are the copy-paste source, not a live defect. Reporting them as failures buries the
handful that can actually fire under hundreds that cannot. Active tasks fail (exit 1);
completed tasks are advisory only.

Parsing anchors on the LAST `## Verification` heading. A first-wins extractor is the very
defect T-588 documents, and reintroducing it in the tool that checks for defects would be
funny exactly once.

Usage:
  check-vacuous-verification.py              scan the repo; exit 1 if any LIVE occurrence
  check-vacuous-verification.py --self-test  plant a defect, require the scanner to find it
"""
import os
import re
import sys
import glob
import tempfile

RE_LOUD = re.compile(r'grep\s+-[a-zA-Z]*q[a-zA-Z]*v|grep\s+-[a-zA-Z]*v[a-zA-Z]*q')
RE_QUIET = re.compile(r'\|\s*grep\s+-[a-zA-Z]*q')
RE_VERIF = re.compile(r'^## Verification[ \t]*$', re.M)
RE_NEXTH = re.compile(r'^## ', re.M)


def verification_block(text):
    """Return the text of the LAST ## Verification section, or '' if absent."""
    matches = list(RE_VERIF.finditer(text))
    if not matches:
        return ''
    start = matches[-1].end()
    nxt = RE_NEXTH.search(text[start:])
    return text[start:start + nxt.start()] if nxt else text[start:]


def top_level_statements(line):
    """Split a shell line on `;` outside quotes, $(...) and (...): the statements P-011 runs in sequence.

    T-1434: P-011 judges `a; b` on `b` alone (T-352) but keeps a pipeline's failure (pipefail is live), so the
    exit status a leg discards is that of a statement BEFORE a `;`. `cmd | grep -q P` and
    `cmd > F 2>&1 && head F | grep -q P` keep cmd's status and are not vacuous.
    """
    parts, cur, depth, quote, i = [], [], 0, None, 0
    while i < len(line):
        ch = line[i]
        if quote:
            if ch == '\\' and quote == '"' and i + 1 < len(line):
                cur.append(line[i:i + 2]); i += 2; continue
            if ch == quote:
                quote = None
        elif ch in '\'"':
            quote = ch
        elif ch == '(':
            depth += 1
        elif ch == ')':
            depth = max(0, depth - 1)
        elif ch == ';' and depth == 0:
            parts.append(''.join(cur)); cur = []; i += 1; continue
        cur.append(ch); i += 1
    parts.append(''.join(cur))
    return [x for x in (p.strip() for p in parts) if x]


def last_statement(line):
    st = top_level_statements(line)
    return st[-1] if st else ''


def scan_text(text):
    """Yield (kind, line) for each vacuous leg in this file's Verification block."""
    for raw in verification_block(text).split('\n'):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        if RE_LOUD.search(line):
            yield ('loud', line)
        elif RE_QUIET.search(last_statement(line)) and len(top_level_statements(line)) > 1:
            # The PIPE is the discriminator, not the presence of `&&`. CLAUDE.md's honest file
            # form (`cmd > /tmp/.o 2>&1 && grep -q PAT /tmp/.o`) has no pipe into grep and is
            # therefore already outside RE_QUIET. An earlier draft ALSO excluded any line
            # containing `&&`, which spared nothing extra and silently created false negatives:
            # `out=$(cmd); echo "$out" | grep -q X && ...` is the defective idiom with a
            # conjunction bolted on. Found by the over-eager control in --self-test, which
            # passed unchanged when that guard was deleted — proving the guard did nothing.
            yield ('quiet', line)


def scan_dir(d):
    out = []
    for path in sorted(glob.glob(os.path.join(d, '*.md'))):
        try:
            text = open(path, encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        for kind, line in scan_text(text):
            out.append((os.path.basename(path), kind, line))
    return out


def self_test():
    """Plant one poisoned leg and one clean leg; require exactly the poisoned one to be found.

    An instrument that reports clean has to prove it can see dirt first — otherwise a clean
    run is indistinguishable from a blind one. (999-AEF, rail 473.)
    """
    ok = True
    with tempfile.TemporaryDirectory() as d:
        poisoned = (
            "# T\n\n## Verification\n\n"
            'out=$(bash tests/run.sh 2>&1); echo "$out" | grep -q "passed"\n'
        )
        clean = (
            "# T\n\n## Verification\n\n"
            "bash tests/run.sh\n"
            'bash tests/run.sh > /tmp/.o 2>&1 && grep -q "passed" /tmp/.o\n'
            '! grep -qE "forbidden" some/file\n'
            # T-1434: these keep the producing command's exit status (pipefail; `&&`), so they are not vacuous.
            'node tools/x.mjs > /tmp/.o 2>&1 && head -2 /tmp/.o | grep -q \'"ok": true\'\n'
            'python3 tools/y.py | grep -q "ok; fine"\n'
        )
        open(os.path.join(d, 'poisoned.md'), 'w', encoding='utf-8').write(poisoned)
        open(os.path.join(d, 'clean.md'), 'w', encoding='utf-8').write(clean)

        hits = scan_dir(d)
        names = sorted({h[0] for h in hits})
        if names == ['poisoned.md'] and len(hits) == 1:
            print("PASS  self-test: exactly the planted defect was found (1 hit, poisoned.md)")
        else:
            print(f"FAIL  self-test: expected 1 hit in poisoned.md only, got {len(hits)}: {names}")
            for h in hits:
                print(f"        {h[0]}  [{h[1]}]  {h[2][:70]}")
            ok = False

        # The clean file's `&&` form and `! grep -qE` form must NOT be flagged — a detector
        # that flags the remedy would push authors back onto the defect.
        clean_hits = [h for h in hits if h[0] == 'clean.md']
        if clean_hits:
            print(f"FAIL  self-test: the honest forms were flagged ({len(clean_hits)} false positives)")
            ok = False
        else:
            print("PASS  self-test: honest forms (bare, && file form, ! grep -qE, pipefail pipe, && then head|grep) not flagged")

        # Anchoring: a SECOND ## Verification block must supersede the first. If this fails,
        # the scanner has the T-588 first-wins defect.
        two = (
            "# T\n\n## Verification\n\n"
            'out=$(bash x 2>&1); echo "$out" | grep -q "ok"\n'
            "\n## Notes\n\ntext\n\n## Verification\n\nbash x\n"
        )
        if list(scan_text(two)):
            print("FAIL  self-test: read the FIRST ## Verification block (T-588 first-wins defect)")
            ok = False
        else:
            print("PASS  self-test: anchors on the LAST ## Verification block")

    # T-1434: the ratchet must fail on a NEW leg and on a STALE baseline entry, or it gates nothing.
    import contextlib, io
    with tempfile.TemporaryDirectory() as r:
        os.makedirs(os.path.join(r, '.tasks', 'active'))
        os.makedirs(os.path.join(r, 'tests'))
        leg = os.path.join(r, '.tasks', 'active', 'T-9-x.md')
        open(leg, 'w').write(poisoned)
        quiet = io.StringIO()
        with contextlib.redirect_stdout(quiet):
            gate(r, write=True)
            open(os.path.join(r, BASELINE), 'w').write("# empty\n")
            rc_new = gate(r)
            gate(r, write=True)
            rc_same = gate(r)
            open(leg, 'w').write(poisoned.replace('passed', 'PASSED'))   # rewritten, task still open
            gate(r, write=False)
            open(os.path.join(r, BASELINE), 'a').write("T-9  000000000000  (old form)\n")
            open(leg, 'w').write("# T\n\n## Verification\n\nbash x\n")   # fixed, task still open
            rc_stale = gate(r)
            os.remove(leg)                                                   # task closed: drain, not a failure
            rc_gone = gate(r)
        if (rc_new, rc_same, rc_stale, rc_gone) == (1, 0, 1, 0):
            print("PASS  self-test: the gate fails on a new leg and on a stale entry of an open task; "
                  "passes when they match and when a listed task closes")
        else:
            print(f"FAIL  self-test: gate rc new/same/stale/gone = {rc_new}/{rc_same}/{rc_stale}/{rc_gone}, "
                  f"expected 1/0/1/0")
            ok = False
    return ok


BASELINE = os.path.join('tests', 'vacuous-verification-baseline.txt')


def _key(name, line):
    """Task id + a hash of the leg: stable while the line is unchanged, gone once it is rewritten or the task closes."""
    import hashlib
    tid = re.match(r'(T-\d+)', name)
    return '%s  %s' % (tid.group(1) if tid else name, hashlib.sha256(line.encode()).hexdigest()[:12])


def gate(repo, write=False):
    """T-1434 (T-592 ruling b): a ratchet. Fails on a live leg not in the baseline (a NEW vacuous leg) and on a
    baseline entry no longer found (stale: rewritten, or its task closed). The baseline lists only legs in tasks that
    wait on the operator, which are not edited on their behalf (operator, 2026-11-18: no rubber stamping)."""
    live = scan_dir(os.path.join(repo, '.tasks', 'active'))
    keys = {_key(n, l): (n, l) for n, _, l in live}
    path = os.path.join(repo, BASELINE)
    if write:
        with open(path, 'w', encoding='utf-8') as f:
            f.write("# vacuous-verification-baseline.txt (T-1434) -- DERIVED by\n"
                    "#   python3 tools/check-vacuous-verification.py --write-baseline\n"
                    "# Known vacuous Verification legs in active tasks that wait on the operator. Not edited for them\n"
                    "# (operator, 2026-11-18: that would be a rubber stamp); each runs once more when its task closes,\n"
                    "# then leaves. The core leg fails on a leg NOT listed here (new) and on a listed one no longer\n"
                    "# found (stale): regenerate then, never to admit a new leg.\n")
            for k in sorted(keys):
                f.write("%s  %s\n" % (k, keys[k][1][:90]))
        print("wrote %s: %d entr%s" % (BASELINE, len(keys), "y" if len(keys) == 1 else "ies"))
        return 0
    try:
        base = set()
        for raw in open(path, encoding='utf-8'):
            if raw.strip() and not raw.startswith('#'):
                tid, h = raw.split()[:2]
                base.add('%s  %s' % (tid, h))
    except OSError:
        print("NOT CHECKED: no baseline at %s" % BASELINE)
        return 2
    new = sorted(set(keys) - base)
    missing = sorted(base - set(keys))
    # A task that closed takes its legs with it: that is the drain, reported but not a failure (closing an
    # operator-held task must not turn the push gate red). A leg missing while its task is still active was
    # rewritten without regenerating the baseline: stale, a failure.
    active_ids = {m.group(1) for m in (re.match(r'(T-\d+)-', f) for f in
                                       os.listdir(os.path.join(repo, '.tasks', 'active'))) if m}
    stale = [k for k in missing if k.split()[0] in active_ids]
    for k in new:
        print("NEW    %s  %s  %s" % (k, keys[k][0][:40], keys[k][1][:80]))
    for k in missing:
        if k in stale:
            print("STALE  %s  (rewritten while its task is still open; regenerate the baseline)" % k)
        else:
            print("GONE   %s  (its task closed; drop it at the next --write-baseline)" % k)
    print("%s: %d live, %d in baseline, %d new, %d stale" % ("PASS" if not (new or stale) else "FAIL",
                                                              len(keys), len(base), len(new), len(stale)))
    if new:
        print("Remedy for a NEW leg: the bare command, or cmd > /tmp/.out 2>&1 && grep -q PATTERN /tmp/.out")
    return 1 if (new or stale) else 0


def main():
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if '--self-test' in sys.argv:
        return 0 if self_test() else 1
    if '--write-baseline' in sys.argv:
        return gate(repo, write=True)
    if '--gate' in sys.argv:
        return gate(repo)

    live = scan_dir(os.path.join(repo, '.tasks', 'active'))
    residue = scan_dir(os.path.join(repo, '.tasks', 'completed'))

    print(f"LIVE RISK      {len(live):>4}  (active tasks — these blocks re-run)")
    for name, kind, line in live:
        print(f"  [{kind:5}] {name[:44]:46} {line[:64]}")
    print(f"ADVISORY       {len(residue):>4}  (completed tasks — never re-run; copy-paste source)")

    if live:
        print("\nRemedy: use the bare command where it already exits non-zero on failure, or")
        print("        cmd > /tmp/.out 2>&1 && grep -q PATTERN /tmp/.out   (&& keeps the exit status)")
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
