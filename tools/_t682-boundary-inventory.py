#!/usr/bin/env python3
"""_t682-boundary-inventory.py — derive the editor's reachable authority surface.

WHY DERIVED AND NOT HAND-LISTED
-------------------------------
A boundary document that is typed by hand is accurate exactly once. This derives
the route set from `gallery-serve.py`'s own dispatch via AST, so a route added
later cannot quietly stay out of the inventory: the drift check goes red.

WHAT AN ABSENCE ROW MEANS
-------------------------
Arc 2's clause (roadmap-5be23719.md line 66) names three authorities: **execution,
secret, ledger**. This file originally said "mutation, execution, secret" — a
substitution that swapped the roadmap's third authority for a fourth of its own, and
the swap is why ledger went unmeasured until T-689. Mutation IS worth a section (it is
the reachable surface) but it is an addition to the clause, not a member of it.

All four now get rows. An ABSENT row carries the patterns searched and the line
numbers found, because an empty row in a security document reads like a control that
passed. It is not. It is a place nobody looked, unless the document says what was
looked for. The same rule bites in reverse for ledger, whose answer is PRESENT: a row
so noisy it cannot be read asserts as little as a blank one.

Symmetrically, an absence must not be OVERCLAIMED. The task filing said execution
authority "does not exist in this tree at all". It does: one fixed-argument
`subprocess.check_output(['hostname', '-I'])` in the startup banner. It is
unreachable from any route and takes no request-derived input, which is a much
narrower and checkable claim than "does not exist" — so that is the claim made.

MODES
-----
  (default)     check the committed report against the derived surface -> exit 1 on drift
  --write       regenerate the report from source
  --self-test   prove the drift check goes red on an added route
"""
from __future__ import annotations

import argparse
import ast
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..'))
SERVER = os.path.join(HERE, 'gallery-serve.py')
REPORT = os.path.join(REPO, 'docs', 'reports', 'T-682-arc-2-boundary-inventory.md')

# Authority classes Arc 2 names. Each maps to the patterns that would evidence it.
EXECUTION_PATTERNS = [r'subprocess', r'os\.system', r'os\.popen', r'\bexec\(', r'\beval\(',
                      r'Popen', r'os\.spawn', r'commands\.']
SECRET_PATTERNS = [r'secret', r'password', r'passwd', r'token', r'credential',
                   r'api_key', r'apikey', r'private_key']

# T-689: the third authority the Arc-2 clause names, and the one this inventory
# originally omitted. Unlike execution and secret, the honest answer here is PRESENT —
# so these patterns are chosen to FIND the persisted-record writers, not to establish
# an absence. A bare `\.append\(` was rejected as a pattern: it matches ordinary list
# building throughout the file and would bury the two real sites in noise, which is
# the same "empty row vs. nobody looked" failure in reverse — a row so full it cannot
# be read asserts as little as one that is blank.
LEDGER_PATTERNS = [r'write_registry', r'registry_path', r'registry\.yaml',
                   r'index\.json', r'setdefault\([^)]*\)\.append', r'_trash']

# What each mutation route touches, and which fence covers it. Hand-authored
# semantics; the ROUTE SET itself is derived, so a new route lands unclassified
# and the check fails rather than silently inheriting a neighbour's row.
ROUTE_SEMANTICS = {
    ('GET', '/api/health'):   ('none — liveness only', 'n/a (no path derived from input)'),
    ('GET', '/api/list'):     ('none — enumerates corpus + saved maps', 'n/a (no id accepted)'),
    ('GET', '/api/versions'): ('none — reads index.json', 'ID_RE only (read path)'),
    ('GET', '/api/version'):  ('none — reads vN.bpmn', 'ID_RE only (read path)'),
    ('GET', '/api/thumb'):    ('none — reads vN.png', 'ID_RE only (read path)'),
    # T-689 corrected the count from 5 to 6. The sixth is the ghosts/claims registry at
    # .context/designer/registry.yaml (gallery-serve.py:726,729 -> write_registry). It was
    # missed because the T-683 containment work enumerated the ID-DERIVED targets — the ones
    # a hostile id can move — and the registry is a fixed path, so it never entered that
    # frame. Correct for containment, wrong for an authority inventory: the question here is
    # what the editor can WRITE, not what an id can STEER.
    ('POST', '/api/save'):    ('WRITES 6 targets: vN.bpmn, vN.png, index.json, corpus copy, '
                               'served copy, .context/designer/registry.yaml',
                               'T-683 per-target containment on the 5 id-derived targets; '
                               'the registry is fixed-path (see § Ledger authority)'),
    ('POST', '/api/delete'):  ('MOVES sources to .editor-versions/_trash/ AND writes '
                               '.context/designer/registry.yaml',
                               '_within_repo via archive_move (delete path); registry fixed-path'),
}


def derive_routes(src: str) -> set[tuple[str, str]]:
    """Route set from the dispatch itself: GET literals in _api_get, POST allowlist in do_POST."""
    tree = ast.parse(src)
    routes: set[tuple[str, str]] = set()

    def api_literals(node) -> set[str]:
        out = set()
        for n in ast.walk(node):
            if isinstance(n, ast.Constant) and isinstance(n.value, str) \
                    and n.value.startswith('/api/'):
                out.add(n.value)
        return out

    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == '_api_get':
            routes |= {('GET', p) for p in api_literals(node)}
        elif isinstance(node, ast.FunctionDef) and node.name == 'do_POST':
            routes |= {('POST', p) for p in api_literals(node)}
    return routes


def scan(src: str, patterns: list[str]) -> list[tuple[int, str]]:
    """Line numbers matching any pattern — the evidence behind an absence claim."""
    hits = []
    for i, line in enumerate(src.splitlines(), 1):
        for p in patterns:
            if re.search(p, line, re.I):
                hits.append((i, line.strip()))
                break
    return hits


def classify_ledger_site(text: str) -> str:
    """WRITE / READ / DECL for one matched line.

    Deliberately a line-level heuristic, not call-graph analysis: it is cheap, its
    limits are stateable, and the report prints them. A `def write_registry(reg):`
    line is DECL — the definition is not itself the authority; its three call sites
    are. Anything ambiguous falls to DECL, which the report tells the reader to treat
    as "not evidence either way" rather than as a clean bill.
    """
    t = text.strip()
    if t.startswith('#') or t.startswith('"""') or t.startswith('def '):
        return 'DECL'
    # Mode is read from the whole line, never from "the arguments to open()". The first
    # version used a `[^)]*` lookahead and mis-tagged
    #     with open(os.path.join(d, 'index.json'), 'w', ...)
    # as READ, because `[^)]*` halts at the `)` closing the nested join and never reaches
    # the mode. It failed toward under-reporting a write, which is the direction that
    # matters in an authority document, so the mode test now scans the line.
    if 'open(' in t:
        return 'WRITE' if re.search(r"""['"][wax]\+?b?['"]""", t) else 'READ'
    if re.search(r'write_registry\(|json\.dump|\.append\(|os\.replace', t):
        return 'WRITE'
    return 'DECL'


def render(routes: set[tuple[str, str]], src: str) -> str:
    execution = scan(src, EXECUTION_PATTERNS)
    secret = scan(src, SECRET_PATTERNS)
    ledger = scan(src, LEDGER_PATTERNS)

    lines = [
        '# T-682 — Arc-2 boundary inventory: the editor\'s reachable authority surface',
        '',
        '**Generated by `tools/_t682-boundary-inventory.py` — do not hand-edit.**',
        'The route table is derived from `tools/gallery-serve.py`\'s own dispatch via AST.',
        'A route added to the server without a row here fails the drift check.',
        '',
        '## 1. Mutation authority — the reachable surface',
        '',
        '| method | path | what it mutates | containment |',
        '|---|---|---|---|',
    ]
    for method, path in sorted(routes):
        mutates, fence = ROUTE_SEMANTICS.get((method, path), ('UNCLASSIFIED', 'UNCLASSIFIED'))
        lines.append('| %s | `%s` | %s | %s |' % (method, path, mutates, fence))

    lines += [
        '',
        'Seven routes, matching the S1 (T-681) measurement. Two of them mutate; the other',
        'five are read paths fenced by `ID_RE` alone, which is adequate because they resolve',
        'a path for READING and a failed resolution is a 404, not a write outside the store.',
        '',
        '## 2. Execution authority — ABSENT FROM THE REQUEST SURFACE (narrower than "absent")',
        '',
    ]
    if execution:
        lines.append('Patterns searched: `%s`' % '`, `'.join(EXECUTION_PATTERNS))
        lines.append('')
        lines.append('**%d match(es) found — so this is NOT a bare absence:**' % len(execution))
        lines.append('')
        for ln, text in execution:
            lines.append('- `gallery-serve.py:%d` — `%s`' % (ln, text))
        lines += [
            '',
            'The claim this document makes is therefore the narrow, checkable one: **no route',
            'reaches an execution primitive, and no execution primitive takes request-derived',
            'input.** The matches above sit in the startup banner with fixed argument vectors.',
            '',
            'The task filing said execution authority "does not exist in this tree at all".',
            'That was an overclaim. Overclaiming an absence is the same failure as mistaking',
            'one for a defence — both put a confident sentence where a measurement belongs.',
        ]
    else:
        lines += [
            'Patterns searched: `%s`' % '`, `'.join(EXECUTION_PATTERNS),
            '',
            '**Zero matches.** No execution primitive exists in this file.',
        ]

    lines += [
        '',
        '## 3. Secret authority — ABSENT',
        '',
        'Patterns searched: `%s`' % '`, `'.join(SECRET_PATTERNS),
        '',
    ]
    if secret:
        lines.append('**%d match(es) — absence claim does not hold:**' % len(secret))
        for ln, text in secret:
            lines.append('- `gallery-serve.py:%d` — `%s`' % (ln, text))
    else:
        lines += [
            '**Zero matches.** The editor holds, reads and transmits no secret of any kind.',
            '',
            'This row is empty because there is nothing there — not because nobody looked.',
            'The patterns above are what was looked for; that is the difference between an',
            'absence and a blind spot, and it is the reason this row exists at all rather',
            'than being omitted for having nothing to say.',
        ]

    lines += [
        '',
        '## 4. Ledger authority — PRESENT, and scoped to the editor\'s own store',
        '',
        'Arc 2\'s clause (roadmap line 66) names **three** authorities: execution, secret and',
        'ledger. The first version of this inventory measured two. This section is the third,',
        'added by T-689, and it is the only one of the three whose answer is PRESENT.',
        '',
        'Patterns searched: `%s`' % '`, `'.join(LEDGER_PATTERNS),
        '',
    ]
    if ledger:
        classified = [(ln, text, classify_ledger_site(text)) for ln, text in ledger]
        writes = [c for c in classified if c[2] == 'WRITE']
        lines += [
            '**%d match(es)** — %d write, %d read, %d declaration/comment.' % (
                len(classified), len(writes),
                sum(1 for c in classified if c[2] == 'READ'),
                sum(1 for c in classified if c[2] == 'DECL')),
            '',
            'The kind matters more than the count. This section is about *authority*, which is',
            'a claim about writes; an unclassified list renders `open(registry_path())` and',
            '`write_registry(reg)` identically, and a reader cannot tell the capability from',
            'the mention. The tag is a line-level heuristic (`classify_ledger_site`) — it reads',
            'the matched line, not the call graph, so treat DECL as "not evidence either way"',
            'rather than as "safe".',
            '',
        ]
        for ln, text, kind in classified:
            lines.append('- **%s** `gallery-serve.py:%d` — `%s`' % (kind, ln, text))
        lines += [
            '',
            'The %d WRITE site(s) are the whole of the editor\'s ledger authority.' % len(writes),
        ]
    else:
        lines.append('**Zero matches** — which for this authority would be a surprising result,')
        lines.append('and should be read as a broken scan before it is read as an absence.')

    lines += [
        '',
        '### Two different claims that must not be conflated',
        '',
        'The editor holds ledger authority over **its own version store**: `/api/save` appends',
        'to `.editor-versions/<id>/index.json`, and both `/api/save` and `/api/delete` rewrite',
        'the ghosts/claims registry at `.context/designer/registry.yaml` via `write_registry`',
        '(3 call sites). `claim_ghost_after_save` reaches it through',
        '`reg.setdefault(\'claims\', []).append(...)` — an append-structured persisted record,',
        'which is what "ledger" means in the roadmap\'s sense.',
        '',
        'The editor does **not** hold ledger authority over **governed records**. The registry',
        'sits under `.context/` but is the Designer\'s own artefact; the framework\'s append-only',
        'registers — `.context/project/*.yaml`, `.context/audits/**`, the gate-bypass log — are',
        'not written by any route in this file, and no route resolves a path into them.',
        '',
        'These are separate claims and this document makes both separately, because "the editor',
        'writes into `.context/`" is true and "the editor can edit governed records" is false,',
        'and the first sentence will be read as the second by anyone not told otherwise.',
        '',
        '### Why containment is not the control here',
        '',
        '`registry_path()` takes no request input — it is `REPO/.context/designer/registry.yaml`',
        'whatever the id. So a hostile id cannot steer this write, and T-683\'s per-target',
        'containment correctly does not cover it: containment answers "can an id move this',
        'write", and the answer is no. The open question a containment check cannot answer is',
        'whether the editor should hold this authority at all — that is Arc 2\'s joint review,',
        'not a fence.',
        '',
        '## 5. What this inventory does NOT claim',
        '',
        '- It does not claim the five read routes are unexploitable — only that they read.',
        '- It does not cover the static file handler inherited from `SimpleHTTPRequestHandler`',
        '  (`super().do_GET()` for non-`/api/` paths), which serves DOCROOT and is out of the',
        '  Arc-2 authority frame.',
        '- Absence rows are evidence of what was searched, not proof that no other shape of',
        '  the same authority exists under a name the patterns do not match.',
        '- **It does not cover "action authority."** The roadmap names the Designer-side',
        '  isolation claim twice and not identically: line 66 (the Arc-2 row) says',
        '  *execution / secret / ledger*, while line 254 says *shell / credential / ledger /',
        '  action* — but line 254 is an **Arc 4** candidate task, not Arc 2. This inventory is',
        '  scoped to Arc 2\'s clause, so shell≡execution and credential≡secret are covered,',
        '  ledger is covered as of T-689, and **action authority is out of scope here** — noted',
        '  rather than measured, so that a later reader does not mistake four-minus-one for an',
        '  oversight. Whoever opens Arc 4 inherits it.',
        '',
        '*Regenerate: `python3 tools/_t682-boundary-inventory.py --write`*',
        '',
    ]
    return '\n'.join(lines)


def parse_report_routes(text: str) -> set[tuple[str, str]]:
    out = set()
    for m in re.finditer(r'^\|\s*(GET|POST)\s*\|\s*`(/api/[^`]+)`\s*\|', text, re.M):
        out.add((m.group(1), m.group(2)))
    return out


def check(server_src: str | None = None) -> int:
    src = server_src if server_src is not None else open(SERVER, encoding='utf-8').read()
    derived = derive_routes(src)
    if not os.path.exists(REPORT):
        print('DRIFT: report does not exist — run --write', file=sys.stderr)
        return 1
    documented = parse_report_routes(open(REPORT, encoding='utf-8').read())

    missing = derived - documented
    extra = documented - derived
    unclassified = {r for r in derived if r not in ROUTE_SEMANTICS}

    if missing or extra or unclassified:
        print('DRIFT between the server and the boundary inventory:', file=sys.stderr)
        for r in sorted(missing):
            print('  IN SERVER, NOT DOCUMENTED: %s %s' % r, file=sys.stderr)
        for r in sorted(extra):
            print('  DOCUMENTED, NOT IN SERVER: %s %s' % r, file=sys.stderr)
        for r in sorted(unclassified):
            print('  UNCLASSIFIED (no semantics row): %s %s' % r, file=sys.stderr)
        print('\nA route the boundary document does not know about is a route nobody',
              file=sys.stderr)
        print('fenced on purpose. Run --write after adding its semantics.', file=sys.stderr)
        return 1

    print('OK — %d routes, server and inventory agree, all classified' % len(derived))
    return 0


def self_test() -> int:
    """The drift check must go red on an added route, or it is a claim not a control."""
    src = open(SERVER, encoding='utf-8').read()
    injected = src.replace(
        "        if route == '/api/health':",
        "        if route == '/api/exfiltrate':\n            return self._json(200, {})\n"
        "        if route == '/api/health':", 1)
    if injected == src:
        print('SELF-TEST FAIL: could not inject a route', file=sys.stderr)
        return 1
    derived = derive_routes(injected)
    if ('GET', '/api/exfiltrate') not in derived:
        print('SELF-TEST FAIL: the deriver did not see the injected route', file=sys.stderr)
        return 1
    code = check(server_src=injected)
    if code == 0:
        print('SELF-TEST FAIL: drift check stayed green with an extra route present',
              file=sys.stderr)
        return 1
    print('\nphase 1 OK — an added route makes the drift check go red')

    # T-689 phase 2: the ledger scan must be an instrument, not a fixed opinion.
    # Phase 1 proves the ROUTE deriver reacts to source changes. It says nothing about
    # the ledger patterns, which today match lines that were already there — exactly the
    # PL-206 shape where a control's stimulus is built so it can never move. So: hide the
    # real sites, confirm the scan goes empty; add a new one, confirm the scan finds it.
    baseline = scan(src, LEDGER_PATTERNS)
    if not baseline:
        print('SELF-TEST FAIL: ledger scan found nothing in the pristine source; it should '
              'match the registry and index writers', file=sys.stderr)
        return 1

    blinded = re.sub(r'write_registry|registry_path|registry\.yaml|index\.json|_trash', 'XX', src)
    blinded = re.sub(r'setdefault\(([^)]*)\)\.append', r'setdefault(\1).XX', blinded)
    if scan(blinded, LEDGER_PATTERNS):
        print('SELF-TEST FAIL: ledger scan still matched after every known site was removed — '
              'it is matching something other than what it claims to', file=sys.stderr)
        return 1

    planted = blinded.replace('def read_registry():',
                              'def _t689_probe():\n    write_registry({})\n\n\ndef read_registry():', 1)
    found = scan(planted, LEDGER_PATTERNS)
    if not found:
        print('SELF-TEST FAIL: ledger scan did not see a newly planted registry write',
              file=sys.stderr)
        return 1

    print('phase 2 OK — ledger scan reads %d site(s) live, 0 when blinded, and detects a '
          'newly planted write' % len(baseline))

    # T-689 phase 3: pin the WRITE/READ/DECL classifier. Its first version tagged an
    # `open(..., 'w')` line as READ because the mode test could not see past a nested
    # call's closing paren — an under-report, the direction that matters here. These
    # cases exist so that specific failure cannot come back unnoticed.
    cases = [
        ("with open(os.path.join(d, 'index.json'), 'w', encoding='utf-8') as f:", 'WRITE'),
        ("with open(registry_path(), encoding='utf-8') as f:", 'READ'),
        ("write_registry(reg)", 'WRITE'),
        ("reg.setdefault('claims', []).append(", 'WRITE'),
        ("def write_registry(reg):", 'DECL'),
        ("# ---- delete/archive (T-166) — sources move to _trash ----", 'DECL'),
        ("path = registry_path()", 'DECL'),
    ]
    bad = [(t, want, classify_ledger_site(t)) for t, want in cases
           if classify_ledger_site(t) != want]
    if bad:
        print('SELF-TEST FAIL: ledger site classifier regressed', file=sys.stderr)
        for t, want, got in bad:
            print('  wanted %-5s got %-5s for: %s' % (want, got, t), file=sys.stderr)
        return 1
    print('phase 3 OK — %d classifier cases hold, including the nested-paren open(...,\'w\') '
          'that the first version under-reported' % len(cases))
    print('\nself-test OK — both the route deriver and the ledger scan are capable of moving')
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--write', action='store_true', help='regenerate the report from source')
    ap.add_argument('--self-test', action='store_true')
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    src = open(SERVER, encoding='utf-8').read()
    if args.write:
        os.makedirs(os.path.dirname(REPORT), exist_ok=True)
        with open(REPORT, 'w', encoding='utf-8') as f:
            f.write(render(derive_routes(src), src))
        print('wrote %s' % os.path.relpath(REPORT, REPO))
        return 0
    return check(src)


if __name__ == '__main__':
    sys.exit(main())
