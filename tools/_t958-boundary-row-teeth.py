#!/usr/bin/env python3
"""T-958: prove the new ROUTE_SEMANTICS row is what cleared the boundary drift check.

WHY THIS EXISTS. `_t682-boundary-inventory.py` now prints OK. An OK is worth exactly as much
as the check's ability to say otherwise, and this check has two independent arms — a route the
server has that the REPORT lacks, and a route with no SEMANTICS row. Adding the row plus
regenerating the report clears both at once, so a green run cannot tell you WHICH arm was
holding, or whether either still works. This prober removes one input at a time and demands
red for the right reason.

WHY IT DOES NOT COPY THE SCRIPT TO A TEMP DIRECTORY. `REPO` and `REPORT` are derived from
`__file__`, so a copy anywhere else computes a different repo root and reads a different (or
missing) report — the prober would then be measuring its own relocation. It imports the real
module from its real path and mutates the table in memory instead, which leaves REPO/REPORT
pointing where they do in production.

Exit 0 iff every leg passes. Run: python3 tools/_t958-boundary-row-teeth.py
"""
import contextlib
import importlib.util
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TARGET = os.path.join(HERE, '_t682-boundary-inventory.py')
ROUTE = ('POST', '/api/validate')

results = []


def check_leg(name, cond, detail=''):
    results.append((name, bool(cond)))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def fresh_module():
    """A new module object each time, so one leg's mutation cannot leak into the next."""
    spec = importlib.util.spec_from_file_location('_t958_inv', TARGET)
    if spec is None or spec.loader is None:
        # Refuse rather than proceed: a prober that cannot load its subject must not
        # report on it, and an AttributeError here would read as a failing leg.
        raise RuntimeError('cannot build an import spec for %s' % TARGET)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def run_check(mod):
    """-> (rc, combined stdout+stderr). check() writes its complaints to stderr."""
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        rc = mod.check()
    return rc, out.getvalue() + err.getvalue()


def main():
    if not os.path.isfile(TARGET):
        print('COULD-NOT-MEASURE: %s missing' % TARGET, file=sys.stderr)
        return 3

    # --- leg 1: the control. Untouched, the check must be green. ------------------
    # Without this, a red in legs 2/3 could just mean the tree is broken.
    mod = fresh_module()
    rc, text = run_check(mod)
    check_leg('control: untouched check is green',
              rc == 0 and 'all classified' in text,
              'rc=%d %s' % (rc, text.strip().splitlines()[-1] if text.strip() else '(silent)'))

    # --- leg 2: the row is present in the table at all ---------------------------
    mod = fresh_module()
    check_leg('the row under test exists in ROUTE_SEMANTICS',
              ROUTE in mod.ROUTE_SEMANTICS,
              '%s %s' % ROUTE)

    # --- leg 3: pop the row -> UNCLASSIFIED arm must fire ------------------------
    mod = fresh_module()
    mod.ROUTE_SEMANTICS.pop(ROUTE, None)
    rc, text = run_check(mod)
    check_leg('row removed -> check goes red naming UNCLASSIFIED for this route',
              rc != 0 and 'UNCLASSIFIED' in text and '/api/validate' in text,
              'rc=%d unclassified=%s named=%s'
              % (rc, 'UNCLASSIFIED' in text, '/api/validate' in text))

    # --- leg 4: the mutation is specific, not a blanket break --------------------
    # A prober that breaks the check by breaking everything proves nothing about this
    # row. Popping ONE row must leave the other eight routes classified: the complaint
    # names /api/validate and no other route.
    mod = fresh_module()
    n_before = len(mod.ROUTE_SEMANTICS)
    mod.ROUTE_SEMANTICS.pop(ROUTE, None)
    rc, text = run_check(mod)
    others = [r for (_, r) in mod.derive_routes(open(
        os.path.join(mod.REPO, 'tools', 'gallery-serve.py'), encoding='utf-8').read())
        if r != '/api/validate']
    leaked = sorted({r for r in others if ('UNCLASSIFIED (no semantics row): POST %s' % r) in text
                     or ('UNCLASSIFIED (no semantics row): GET %s' % r) in text})
    check_leg('removal is specific: no other route is reported unclassified',
              not leaked and n_before == 9,
              'table_size=%d leaked=%s' % (n_before, leaked))

    # --- leg 5: the report arm is independent and also bites --------------------
    # Feed check() a server source with the route's dispatch literal removed. The route
    # then vanishes from derive_routes while the REPORT still lists it, so the OTHER arm
    # -- DOCUMENTED, NOT IN SERVER -- must fire. This proves the report was really
    # regenerated, not that the check stopped comparing.
    mod = fresh_module()
    src = open(os.path.join(mod.REPO, 'tools', 'gallery-serve.py'), encoding='utf-8').read()
    stripped = src.replace("'/api/validate'", "'/api/__gone__'")
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        rc = mod.check(server_src=stripped)
    text = out.getvalue() + err.getvalue()
    check_leg('report arm bites: route gone from server -> DOCUMENTED, NOT IN SERVER',
              rc != 0 and 'DOCUMENTED, NOT IN SERVER' in text and '/api/validate' in text,
              'rc=%d %s' % (rc, 'named' if '/api/validate' in text else 'NOT named'))

    passed = sum(1 for _, ok in results if ok)
    failed = len(results) - passed
    print()
    print('boundary-row teeth: %d passed, %d failed' % (passed, failed))
    if failed:
        print('boundary-row teeth: FAILED')
        return 1
    print('OK: the /api/validate row is load-bearing, and both drift arms still bite')
    return 0


if __name__ == '__main__':
    sys.exit(main())
