#!/usr/bin/env python3
"""_t495-prose-edge-probe.py — negative controls for the census's edge definition.

T-495. Subject: `strip_prose()` / `_composed_refs()` in tools/_t451-unwired-guard-census.py.

WHY THIS EXISTS
---------------
T-495 changed what the unwired-guard census means by "an edge", and a change of
DEFINITION moves the count. A moved count proves nothing on its own — it is equally
consistent with "the instrument got sharper" and "the instrument broke". The only thing
that separates those is a control that goes RED for its own reason.

So every leg below is run twice: once against the CURRENT census and once against the
PRE-CHANGE census recovered from git (`--discriminate`). A leg that passes under BOTH is
not testing this change and says so out loud. This is the check T-493's control (c) did
not survive — it passed for the wrong reason, because `set -e` aborted before the
assertion ran.

THE TWO DIRECTIONS, AND WHY BOTH ARE HERE
------------------------------------------
Stripping prose alone made the census WORSE. Ten CDP harnesses that run on every bridge
suite pass are invoked as `os.path.join(ROOT, "tools", "<name>")` and were held live only
by the docstring that happened to name them. Two errors of opposite sign were cancelling.
Legs A/B guard the direction that was fixed; legs C/D/E guard the direction that fixing it
would otherwise have broken. Half of this file without the other half would have been a
green suite over a census reporting live instruments dead.

FIXTURE NAMES ARE SYNTHETIC, AND THAT IS LOAD-BEARING
------------------------------------------------------
Every tool name below is `_t495-fixture-*`, which resolves to no file in tools/. The
first draft used REAL names — `tools/_t418-producer-attribution.py` and friends — and
that draft silently broke the thing it was written to prove.

A fixture is a string assigned to a module-level name. An assignment's value is not a
bare string STATEMENT, so `strip_prose` correctly keeps it (that is how a real
`subprocess.run(["tools/x.py"])` survives). This file is wired into the bridge suite, so
it is a live root — and a live root naming a tool makes that tool live. Wiring the probe
resurrected `_t418-producer-attribution.py`, `_t418-capture-attribution.sh` and
`_t445-partial-state-mutation.sh`, the precise instruments T-495 exists to expose, and
the census went from reporting `_t418` dark to reporting it wired again.

The control manufactured the defect it tests for, and every leg still passed while it did.
Synthetic names cannot resolve, so they cannot vouch for anything.

Exit 0 = every leg produced its expected verdict.
"""
import glob
import importlib.util
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CENSUS = os.path.join(ROOT, 'tools', '_t451-unwired-guard-census.py')


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def refuse_if_subject_missing():
    """T-496: derive-then-ASSERT. Exit 2 is an abstention, deliberately not 1.

    ROOT comes from this file's own location, which is correct in place and wrong the
    moment the file is copied — and copying it is exactly what proving a leg discriminates
    requires. Both times this happened under T-495 the copy exited 1 on an ImportError:
    the code the counterfactual WANTED, produced by the census being absent rather than by
    any assertion. 1 is the answer under test, so 1 can never mean "I could not run".
    """
    if os.path.isfile(CENSUS):
        return
    sys.stderr.write(
        'REFUSING (T-496): no census at the derived path, so nothing was measured.\n'
        '  this file : %s\n'
        '  derived   : %s\n'
        '  ROOT comes from this file\'s location. Run the probe from <project>/tools/;\n'
        '  a copy elsewhere resolves a different subject and exits 1 on the import,\n'
        '  which is indistinguishable from a leg legitimately failing.\n'
        % (os.path.abspath(__file__), CENSUS))
    raise SystemExit(2)


def refs(mod, filename, text):
    """Names the census would extract from `text` if it were saved as `filename`."""
    d = tempfile.mkdtemp()
    p = os.path.join(d, filename)
    with open(p, 'w', encoding='utf-8') as fh:
        fh.write(text)
    return mod.read_refs([p])


# ── the legs ────────────────────────────────────────────────────────────────────────
# Each: (id, description, filename, source, needle, want_present)
F_DOC = '_t495-fixture-doc.py'
F_HASH = '_t495-fixture-hash.sh'
F_ARG = '_t495-fixture-arg.py'
F_JOIN = '_t495-fixture-join.mjs'
F_PATHLIB = '_t495-fixture-pathlib.mjs'
F_NOTTOOLS = '_t495-fixture-nottools.mjs'
F_TRAIL = '_t495-fixture-trailing.sh'
F_SHCOMMENT = '_t495-fixture-shcomment.sh'
F_EXPAND = '_t495-fixture-expand.sh'
F_SLASH = '_t495-fixture-slashslash.mjs'
F_BLOCK = '_t495-fixture-blockcomment.mjs'
F_SPAWN = '_t495-fixture-spawn.mjs'
F_BROKEN = '_t495-fixture-unparseable.sh'

# Enumerated explicitly rather than re-derived from the fixture sources: F_NOTTOOLS is
# deliberately spelled WITHOUT a `tools/` prefix (leg D3), so a regex over the sources
# would miss exactly the name whose absence it is checking for.
FIXTURES = (F_DOC, F_HASH, F_ARG, F_JOIN, F_PATHLIB, F_NOTTOOLS, F_TRAIL,
            F_SHCOMMENT, F_EXPAND, F_SLASH, F_BLOCK, F_SPAWN, F_BROKEN)

PY_DOCSTRING = '"""A module that merely DISCUSSES tools/%s."""\nx = 1\n' % F_DOC

PY_COMMENT = '# see tools/%s for the teeth\nx = 1\n' % F_HASH

PY_STRING_ARG = ('import subprocess\n'
                 'subprocess.run(["python3", "tools/%s"], check=True)\n' % F_ARG)

PY_COMPOSED = ('import os\n'
               'HARNESS = os.path.join(ROOT, "tools", "%s")\n' % F_JOIN)

PY_COMPOSED_PATHLIB = ('from pathlib import Path\n'
                       'H = Path(ROOT) / "tools" / "%s"\n' % F_PATHLIB)

# The composition rule must not fire on a join that has nothing to do with tools/.
PY_COMPOSED_NEGATIVE = ('import os\n'
                        'X = os.path.join(ROOT, "docs", "%s")\n' % F_NOTTOOLS)

SH_TRAILING_COMMENT = ('#!/usr/bin/env bash\n'
                       'python3 "$ROOT/tools/%s"   # run the capture step\n' % F_TRAIL)

SH_COMMENT_ONLY = ('#!/usr/bin/env bash\n'
                   '# calls tools/%s one day\necho hi\n' % F_SHCOMMENT)

# `#` opens a comment only at the start of a WORD. A naive stripper truncates here and
# silently deletes a real call.
SH_PARAM_EXPANSION = ('#!/usr/bin/env bash\n'
                      'BASE=${SUBJECT#prefix}\n'
                      'bash tools/%s "$BASE"\n' % F_EXPAND)

MJS_LINE_COMMENT = '// Usage: node tools/%s\nconst x = 1;\n' % F_SLASH

MJS_BLOCK_COMMENT = '/* see tools/%s for the pair map */\nconst x = 1;\n' % F_BLOCK

MJS_REAL_SPAWN = ('import { spawnSync } from "node:child_process";\n'
                  'spawnSync("node", ["tools/%s"]);\n' % F_SPAWN)

LEGS = [
    ('A1', 'python DOCSTRING naming a tool is not an edge',
     'a.py', PY_DOCSTRING, F_DOC, False),
    ('A2', 'python # COMMENT naming a tool is not an edge',
     'a.py', PY_COMMENT, F_HASH, False),
    ('B1', 'shell # COMMENT naming a tool is not an edge',
     'a.sh', SH_COMMENT_ONLY, F_SHCOMMENT, False),
    ('B2', 'mjs // COMMENT naming a tool is not an edge',
     'a.mjs', MJS_LINE_COMMENT, F_SLASH, False),
    ('B3', 'mjs /* */ COMMENT naming a tool is not an edge',
     'a.mjs', MJS_BLOCK_COMMENT, F_BLOCK, False),

    ('C1', 'python STRING ARGUMENT is a real call and SURVIVES',
     'a.py', PY_STRING_ARG, F_ARG, True),
    ('C2', 'shell call with a TRAILING comment SURVIVES',
     'a.sh', SH_TRAILING_COMMENT, F_TRAIL, True),
    ('C3', 'shell ${VAR#word} does not truncate the line below it',
     'a.sh', SH_PARAM_EXPANSION, F_EXPAND, True),
    ('C4', 'mjs spawnSync array argument SURVIVES',
     'a.mjs', MJS_REAL_SPAWN, F_SPAWN, True),

    ('D1', 'os.path.join(ROOT, "tools", X) is an edge',
     'a.py', PY_COMPOSED, F_JOIN, True),
    ('D2', 'pathlib ROOT / "tools" / X is an edge',
     'a.py', PY_COMPOSED_PATHLIB, F_PATHLIB, True),
    ('D3', 'a join WITHOUT "tools" is NOT an edge (rule is not matching everything)',
     'a.py', PY_COMPOSED_NEGATIVE, F_NOTTOOLS, False),
]


def run(mod):
    """-> {leg_id: bool passed}"""
    out = {}
    for lid, _desc, fname, src, needle, want in LEGS:
        try:
            got = needle in refs(mod, fname, src)
        except Exception:                       # noqa: BLE001 - old census may lack a name
            got = None
        out[lid] = (got == want)
    return out


def main():
    refuse_if_subject_missing()
    cur = load(CENSUS, 'census_cur')

    # E: the parse fallback must be COUNTED, not silently dropped.
    cur.PARSE_FALLBACKS.clear()
    broken = refs(cur, 'a.py', 'def (:\n  # tools/%s\n' % F_BROKEN)
    e_counted = len(cur.PARSE_FALLBACKS) == 1
    e_whole = F_BROKEN in broken
    cur.PARSE_FALLBACKS.clear()

    now = run(cur)

    old = None
    if '--discriminate' in sys.argv:
        raw = subprocess.run(['git', 'show', 'HEAD:tools/_t451-unwired-guard-census.py'],
                             cwd=ROOT, capture_output=True, text=True)
        if raw.returncode != 0:
            print('REFUSING: could not recover HEAD: of the census, so no leg can be shown')
            print('  to discriminate. A control that has not been shown to go red for its')
            print('  own reason is decoration (T-493).')
            return 2
        d = tempfile.mkdtemp()
        p = os.path.join(d, 'old_census.py')
        with open(p, 'w', encoding='utf-8') as fh:
            fh.write(raw.stdout)
        old = run(load(p, 'census_old'))

    print('=== T-495 prose-edge controls ===')
    print()
    fail = 0
    inert = 0
    for lid, desc, _f, _s, _n, _w in LEGS:
        ok = now[lid]
        mark = 'ok  ' if ok else 'FAIL'
        if not ok:
            fail += 1
        note = ''
        if old is not None:
            if old[lid] and ok:
                note = '   << INERT: passes on the OLD census too, so it does not test T-495'
                inert += 1
            elif not old[lid] and ok:
                note = '   (red before, green after — discriminates)'
        print('  %-3s %-4s %s%s' % (lid, mark, desc, note))

    print()
    print('  E1  %-4s unparseable python is COUNTED as a fallback, not dropped'
          % ('ok  ' if e_counted else 'FAIL'))
    print('  E2  %-4s ...and is read WHOLE, so its refs still register'
          % ('ok  ' if e_whole else 'FAIL'))
    fail += (not e_counted) + (not e_whole)

    # F: this file is a live root (wired into the bridge suite), so any REAL tool name in
    # a fixture is a real edge and this probe silently keeps that tool alive. That is not
    # hypothetical — it happened during T-495 and resurrected the very instrument the task
    # existed to expose, with every leg still green. Asserted here rather than in a task's
    # `## Verification` because a one-shot check on a standing file is the class next door.
    pop = {os.path.basename(p) for p in glob.glob(os.path.join(ROOT, 'tools', '*'))}
    fixtures = set(FIXTURES)
    clash = sorted(fixtures & pop)
    print('  F1  %-4s no fixture name resolves to a real tool (%d fixtures checked)'
          % ('ok  ' if not clash else 'FAIL', len(fixtures)))
    if clash:
        for c in clash:
            print('        | %s EXISTS in tools/ — this probe is vouching for it' % c)
    fail += bool(clash)

    print()
    if old is not None:
        print('DISCRIMINATION: %d of %d legs pass identically on the pre-change census.'
              % (inert, len(LEGS)))
        print('  Those legs are real assertions about the definition, but they are not')
        print('  evidence FOR this change. Legs marked "discriminates" are.')
        if inert == len(LEGS):
            print()
            print('  WARNING: EVERY leg is inert, which almost certainly means HEAD already')
            print('  contains the T-495 change — `git show HEAD:` recovered the new census,')
            print('  not the old one. --discriminate is only meaningful from a working tree')
            print('  whose HEAD PREDATES the change. After the commit this mode compares the')
            print('  file to itself and reports a uniform green that asserts nothing. Said')
            print('  out loud because a control that quietly stops discriminating is the')
            print('  same failure as one that never did.')
    else:
        print('NOTE: run with --discriminate to prove these legs go red on the old census.')
        print('  Without it, a green run is consistent with the legs testing nothing.')

    print()
    print('pass=%d fail=%d' % (len(LEGS) + 3 - fail, fail))
    return 1 if fail else 0


if __name__ == '__main__':
    sys.exit(main())
