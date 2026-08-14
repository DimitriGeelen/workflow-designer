#!/usr/bin/env python3
"""_t497-derived-root-census.py — count harnesses that derive a root from their own
location and resolve a subject beneath it, and say how many verify the subject first.

T-497. Supersedes the ad-hoc measurement in T-496, which produced "70 python / 42
verify / 28 do not" by hand and left no instrument, so the number could not be
re-derived the next day. The shell half was stated as UNMEASURED rather than implied
zero (AEF rail 617 §2, exclusion-vs-hole); this file measures it.

WHAT IS BEING COUNTED, IN TERMS A READER CAN CHECK BY HAND
---------------------------------------------------------
A file is a MEMBER when both hold:

  (1) it DERIVES A ROOT — it computes a directory from its own file location:
        python : dirname(__file__), Path(__file__).parent, abspath(__file__)
        shell  : dirname "$0", dirname "${BASH_SOURCE[0]}"
  (2) it RESOLVES A SUBJECT beneath that root — it composes a path from the derived
      root plus a literal component, and that composed path is later read/executed:
        python : os.path.join(ROOT, "tools", "x"), ROOT / "x", f"{ROOT}/x"
        shell  : "$ROOT/tools/x", or — the implicit form — `cd "$(dirname "$0")/.."`
                 followed by RELATIVE literal paths, where the root is the cwd

A member VERIFIES when, before using the subject, it tests that the subject exists:
        python : os.path.isfile / os.path.exists / os.path.isdir / Path.exists()
                 applied to the composed path (or to a variable holding it)
        shell  : [ -f "$X" ] / [ -e ] / [ -x ] / [ -d ] / test -f, on the subject

THE SHELL-SPECIFIC TRAP, AND WHY `|| exit` DOES NOT COUNT AS VERIFICATION
------------------------------------------------------------------------
The dominant shell idiom here is

    cd "$(dirname "$0")/.." || exit 2

which LOOKS guarded and is not guarded against this class at all. Copy the file to
/tmp and `cd /tmp/..` succeeds — cd to a parent directory essentially cannot fail.
The guard tests the one step that does not go wrong. What then goes wrong is every
RELATIVE subject path afterwards, unguarded, and the failure code the interpreter
returns is drawn from the same small set a real verdict uses.

So `|| exit` on the cd is scored as ROOT-guarded, NOT as subject-verified. They are
different claims and this file keeps them apart, because conflating them is what
makes 12 files read as safe.

TWO READINGS, AND WHY BOTH ARE PRINTED
--------------------------------------
This file reports STRICT and LOOSE unverified counts and the gap between them. That is
not indecision — the two readings are wrong in OPPOSITE directions, and each was found
by hand-reading files the other had classified:

  LOOSE  over-credits (mention-vs-instance, T-429 defects 1-2, rail 530). Its rule is
         "an existence test appears in the file". tests/run-bridge-tests.sh matched on
         `[ -s "$file" ]` — a check on a CAPTURED OUTPUT — while the ~74 harnesses it
         launches from "$ROOT/tools/" are never checked. _t408-hygiene-teeth.sh matched
         `test -f README.md` sitting INSIDE A QUOTED FIXTURE STRING: data, not code.

  STRICT under-credits (indirection). Its rule is "the tested operand is the derived
         subject". concerns-schema.py and tracked-secret-artifacts.py both compose the
         subject into a module constant, pass it as an ARGPARSE DEFAULT, and check it
         inside the function under the parameter's name. Verified, and invisible here.
         This file is itself a third shape: it guards the POPULATION (refuse_if_empty)
         rather than any single path, so its own rule scores it unverified.

The true count is inside the interval, not at either end. Reporting one number would
have picked a side by accident. Same opposite-sign structure as T-495, where stripping
prose alone made the census worse because a false positive was standing in for a false
negative — met again here, one layer up, in the classifier instead of the subject.

LIMIT — WHAT THIS CENSUS CANNOT SEE
-----------------------------------
Stated so the number is not read as full coverage:
  - subject reached through a default parameter value or a helper's argument (above)
  - subjects composed at runtime from a variable this file cannot constant-fold
    (a name read from argv, a loop over a list built elsewhere)
  - verification performed by a CALLEE (a helper function that checks, invoked with
    the subject) — only checks lexically in the same file are seen
  - `set -e` plus a bare `source "$ROOT/lib.sh"`, which does abort, but on an error
    message about the wrong subject rather than on a named refusal
  - non-python, non-shell harnesses (.mjs) — out of scope, not zero
  - files outside the globs below
  - DOT-NAMED files. `glob.glob` does not match them, so anything at `tools/.x.sh` is
    invisible here. Proven, not assumed: _t497-census-controls.sh planted its fixtures
    under dot-names on its first run (copying _t429's convention) and the census
    reported them CLEAR — absent read as clean. Transient dot-names are the local
    convention for scratch copies (_t429 writes tools/.t429-neutered-$$.sh), so this
    blind spot lines up exactly with the files most likely to be a wrong subject.

EXIT
  0  census ran; findings printed (this is a MEASUREMENT, not a gate — it does not
     fail on the backlog it reports)
  2  cannot answer (no population found at the derived root — see refuse_if_empty)
"""

import ast
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# Population globs. The denominator is DERIVED from these, never typed.
GLOBS = [
    'tools/**/*.py', 'tools/**/*.sh',
    'tests/**/*.py', 'tests/**/*.sh',
    'lib/**/*.py', 'lib/**/*.sh',
    'bin/**/*.sh',
    'web/**/*.py',
    'scripts/**/*.sh', 'scripts/**/*.py',
]
# Never measure vendored or third-party trees — they are someone else's population.
EXCLUDE_PREFIXES = ('.agentic-framework/', '.git/', 'node_modules/', 'venv/')

# ---------------------------------------------------------------- shell patterns

SH_DERIVE = re.compile(r'dirname\s+"?\$\{?(?:BASH_SOURCE\[0\]|0)\}?"?')
# the implicit form: cd into the derived dir, making the root the cwd
SH_CD_ROOT = re.compile(r'\bcd\s+"?\$\(\s*dirname\s+"?\$\{?(?:BASH_SOURCE\[0\]|0)\}?"?')
SH_CD_GUARDED = re.compile(
    r'\bcd\s+"?\$\(\s*dirname[^\n]*?\)\s*[^\n]*?(\|\|\s*(?:exit|return|die))')
# a subject test: [ -f "$X" ], [[ -e ... ]], test -x ...
SH_VERIFY = re.compile(r'(\[\[?\s*-(?:f|e|x|d|s)\s|(?<![\w-])test\s+-(?:f|e|x|d|s)\s)')
# a composed subject: "$ROOT/lit", "$REPO_ROOT/lit", "${SCRIPT_DIR}/lit"
SH_SUBJECT = re.compile(r'\$\{?(?:ROOT|REPO_ROOT|REPO|SCRIPT_DIR|BASE|HERE|DIR)\}?/[A-Za-z0-9_.\-]')
# relative literal subjects used after a cd-to-root
SH_REL_SUBJECT = re.compile(
    r'(?<![\w/$."-])(?:tools|tests|lib|bin|web|src|docs|examples|\.context|\.tasks)/'
    r'[A-Za-z0-9_.\-/]+\.(?:py|sh|mjs|js|json|yaml|yml|md|bpmn)')

# ---------------------------------------------------------------- python patterns

PY_DERIVE_NAMES = ('__file__',)
PY_VERIFY = re.compile(
    r'\bos\.path\.(?:isfile|exists|isdir)\s*\(|\.exists\s*\(\)|\.is_file\s*\(\)|\.is_dir\s*\(\)')


def rel(p):
    return os.path.relpath(p, ROOT)


def population():
    """Derived, never typed. Returns sorted relative paths."""
    seen = set()
    for g in GLOBS:
        for p in glob.glob(os.path.join(ROOT, g), recursive=True):
            if not os.path.isfile(p):
                continue
            r = rel(p)
            if r.startswith(EXCLUDE_PREFIXES):
                continue
            seen.add(r)
    return sorted(seen)


SQ_STRING = re.compile(r"'[^']*'")
# X="$ROOT/lit"  |  X="$(cd "$(dirname "$0")/.." && pwd)/lit"  |  X=tools/lit
ASSIGN = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)=(.+)$', re.M)


def _subject_vars(text, implicit):
    """Names whose assignment RHS composes the derived root with a literal component."""
    names = set()
    for m in ASSIGN.finditer(text):
        name, rhs = m.group(1), m.group(2)
        if SH_SUBJECT.search(rhs) or SH_DERIVE.search(rhs):
            names.add(name)
        elif implicit and SH_REL_SUBJECT.search(rhs):
            # after a cd-to-root a bare `tools/x.sh` IS a composed subject
            names.add(name)
    return names


def _verifies_a_subject(text, subject_vars, implicit):
    """A test whose OPERAND is a derived subject — not merely a test somewhere in the file.

    This is the distinction T-429 defects (1) and (2) got wrong, and rail 530 named as
    mention-vs-instance: `is the thing named here` answered when the question was
    `is THIS the thing`. Single-quoted regions are removed first, so a `test -f X`
    sitting inside a fixture heredoc is data and does not count as code.
    """
    code = SQ_STRING.sub("''", text)
    for name in subject_vars:
        if re.search(r'\[\[?\s*-(?:f|e|x|d|s)\s+"?\$\{?%s\b' % re.escape(name), code):
            return True
        if re.search(r'(?<![\w-])test\s+-(?:f|e|x|d|s)\s+"?\$\{?%s\b' % re.escape(name), code):
            return True
    if implicit:
        for m in re.finditer(r'\[\[?\s*-(?:f|e|x|d|s)\s+"?([A-Za-z0-9_.\-/]+)', code):
            if SH_REL_SUBJECT.match(m.group(1)):
                return True
    return False


def classify_shell(text):
    """-> None if not a member, else dict(kind, root_guarded, subject_verified, ...)."""
    if not SH_DERIVE.search(text):
        return None
    implicit = bool(SH_CD_ROOT.search(text))
    explicit_subject = bool(SH_SUBJECT.search(text))
    rel_subject = implicit and bool(SH_REL_SUBJECT.search(text))
    if not (explicit_subject or rel_subject):
        return None            # derives a root but never resolves anything under it
    svars = _subject_vars(text, implicit)
    return {
        'lang': 'sh',
        'kind': 'explicit-var' if explicit_subject else 'implicit-cd',
        # cd-guard is recorded but deliberately NOT counted as subject verification
        'root_guarded': bool(SH_CD_GUARDED.search(text)),
        # STRICT: the tested operand is a derived subject
        'subject_verified': _verifies_a_subject(text, svars, implicit),
        # LOOSE: any existence test anywhere in the file (the first draft's rule, kept
        # so the gap between the two readings is reportable instead of invisible)
        'loose_verified': bool(SH_VERIFY.search(SQ_STRING.sub("''", text))),
    }


def _is_composition(node):
    """join(a, b) / a / 'b' / f'{a}/b' — a path built from parts."""
    if isinstance(node, ast.Call):
        name = getattr(node.func, 'attr', None) or getattr(node.func, 'id', None)
        return name == 'join' and len(node.args) >= 2
    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Div):
        return True
    if isinstance(node, ast.JoinedStr):
        return any(isinstance(v, ast.Constant) and isinstance(v.value, str) and '/' in v.value
                   for v in node.values)
    return False


def classify_python(text):
    try:
        tree = ast.parse(text)
    except (SyntaxError, ValueError):
        return None
    if not any(isinstance(n, ast.Name) and n.id in PY_DERIVE_NAMES for n in ast.walk(tree)):
        return None

    composed_names, composed = set(), False
    for node in ast.walk(tree):
        if _is_composition(node):
            composed = True
        if isinstance(node, ast.Assign) and _is_composition(node.value):
            for t in node.targets:
                if isinstance(t, ast.Name):
                    composed_names.add(t.id)
    if not composed:
        return None

    # STRICT: an existence check whose ARGUMENT is a composed path, or a name holding one.
    strict = False
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        fn = getattr(node.func, 'attr', None)
        if fn not in ('isfile', 'exists', 'isdir', 'is_file', 'is_dir'):
            continue
        # Path(x).exists() — the receiver carries the subject; os.path.isfile(x) — arg 0
        cand = list(node.args[:1])
        if isinstance(node.func, ast.Attribute):
            cand.append(node.func.value)
        for a in cand:
            if _is_composition(a) or (isinstance(a, ast.Name) and a.id in composed_names):
                strict = True
            if isinstance(a, ast.Call) and a.args and _is_composition(a.args[0]):
                strict = True

    return {
        'lang': 'py',
        'kind': 'derive-join',
        'root_guarded': False,          # python has no cd-idiom equivalent
        'subject_verified': strict,
        'loose_verified': bool(PY_VERIFY.search(text)),
    }


def refuse_if_empty(pop):
    """T-496/PL-193: derive-then-ASSERT. Exit 2 — never 1, and never 0."""
    if pop:
        return
    sys.stderr.write(
        'REFUSING (T-497): no population at the derived root, so nothing was measured.\n'
        '  this file : %s\n'
        '  derived   : %s\n'
        'A copy run outside the project derives the wrong root and would otherwise\n'
        'report a clean population of zero, which is the answer under test.\n'
        % (os.path.abspath(__file__), ROOT))
    raise SystemExit(2)


def main():
    as_json = '--json' in sys.argv
    pop = population()
    refuse_if_empty(pop)

    members = []
    for r in pop:
        try:
            text = open(os.path.join(ROOT, r), encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        ext = os.path.splitext(r)[1].lower()
        if ext == '.sh':
            c = classify_shell(text)
        elif ext == '.py':
            c = classify_python(text)
        else:
            c = None
        if c:
            c['path'] = r
            members.append(c)

    by = lambda lang: [m for m in members if m['lang'] == lang]
    unver = lambda ms: [m for m in ms if not m['subject_verified']]
    unloose = lambda ms: [m for m in ms if not m['loose_verified']]

    def half(lang):
        ms = by(lang)
        return {
            'members': len(ms),
            'verify_strict': len(ms) - len(unver(ms)),
            'do_not_verify_strict': len(unver(ms)),
            # LOOSE is the first-draft rule: any existence test anywhere in the file.
            # Reported because the GAP between the two readings is the size of the
            # mention-vs-instance error, and hiding it would make one reading look
            # like the answer.
            'do_not_verify_loose': len(unloose(ms)),
        }

    result = {
        'scanned': len(pop),
        'members_total': len(members),
        'python': half('py'),
        'shell': half('sh'),
        'shell_root_guarded_only': len([m for m in by('sh')
                                        if m['root_guarded'] and not m['subject_verified']]),
        'unverified_paths': sorted(m['path'] for m in unver(members)),
        'disputed_paths': sorted(m['path'] for m in members
                                 if m['loose_verified'] and not m['subject_verified']),
    }

    if as_json:
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0

    print('T-497 derived-root census — scanned %d files (denominator derived from globs)'
          % result['scanned'])
    print()
    for label, d in (('python', result['python']), ('shell', result['shell'])):
        print('  %-7s members %3d | verify the subject %3d | DO NOT %3d'
              % (label, d['members'], d['verify_strict'], d['do_not_verify_strict']))
    print()
    print('  Two readings, deliberately both shown:')
    print('    STRICT (tested operand IS the derived subject) unverified: py %d  sh %d'
          % (result['python']['do_not_verify_strict'], result['shell']['do_not_verify_strict']))
    print('    LOOSE  (any existence test anywhere in file)   unverified: py %d  sh %d'
          % (result['python']['do_not_verify_loose'], result['shell']['do_not_verify_loose']))
    print('    %d file(s) differ between the readings — that gap IS the mention-vs-instance'
          % len(result['disputed_paths']))
    print('    error, sized rather than resolved. The truth is inside it, not at an end.')
    print()
    print('  shell files whose ONLY guard is `cd ... || exit` (guards the step that')
    print('  cannot fail; a copy elsewhere cd\'s fine and then misses every subject): %d'
          % result['shell_root_guarded_only'])
    print()
    print('  LIMIT: runtime-composed subjects, callee-side checks, and .mjs harnesses')
    print('  are NOT counted. See this file\'s docstring.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
