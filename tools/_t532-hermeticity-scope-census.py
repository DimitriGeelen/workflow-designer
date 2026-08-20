#!/usr/bin/env python3
"""
T-532 — census of hermeticity assertions, classified by SCOPE.

THE QUESTION: a probe that checks "did I leave the tree as I found it" is doing the right
thing. It becomes defective when the snapshot is scoped to the WHOLE REPOSITORY instead of to
the paths its own subject writes, because then any other writer — cron, a handover commit, a
concurrent agent — reddens it. Measured under T-527: one persistent new file appearing inside
_t525's 61-second window drives its leg 7 red; the script passes 7/7 standalone.

WHY A SCRIPT AND NOT A GREP IN A TASK BODY: so the next count is a re-run rather than a
re-derivation. OBS-259 asserted the shape was "probably a population" of ~26 on the strength of
the sweep's script count. That guess was wrong in the direction that made it look bigger — the
same direction as T-527's "62 legs" (real: 23) and T-530's 15.06 MB (real: 14.96). A guess that
flatters the finding is the one that survives, so the count gets an instrument.

WHAT IT MUST NOT DO — this is the harder half. Six scripts in this corpus mention `git status`
and are CORRECT:

    _t402-budget-gate-match-probe.py   ("git status", "allowed", "legitimate read")
    _t402-gate-drive-probe.py          same shape
    _t402-gate-drive-teeth.sh          check "M1i git status stays allowed" ...
    t404-gate-e2e.sh                   check "fd duplication" 'git status --short' ALLOW
    _t392-drift-shadow-probe.sh        for c in 'fw doctor' 'git status' ...
    _t509-instrument-sweep.sh          mentions it in a header comment

In every one, `git status` is a LITERAL STRING UNDER TEST — a command-classifier fixture — not a
tree read. Flagging them would push authors to weaken real tests, which is the false-positive
risk T-508's discriminator was built to avoid. AEF found the identical class on their tree
(rail 11945): their 25 `git status` callers were all classifier fixtures too.

CLASSIFICATION
  WHOLE-TREE  a real subprocess invocation of `git status` with NO pathspec, whose result is
              compared across a before/after pair. Defective.
  SCOPED      same, but limited to a pathspec / named file / mktemp dir. Correct — reported so
              a clean run is a classification rather than an absence (PL-175).
  FIXTURE     `git status` appears only as quoted data. Correct. Never flagged.

LIMITS, stated so a clean run cannot imply coverage it does not have (PL-148):
  * Only `git status` hermeticity is classified. A probe hashing the tree by other means
    (find|md5sum, os.walk checksums) is NOT detected. Zero here today, checked by hand.
  * Python and shell invocation forms are recognised; a `git status` reached through a variable
    or a wrapper defined in another file is not.
  * Scope is judged syntactically from the argv, not by executing anything.

Exit 0 no whole-tree assertions, 1 at least one found, 2 REFUSE (corpus missing/too small —
nothing was evaluated, and that is not a pass: PL-205).
"""

import ast
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ["tools", "tests"]
EXTS = (".py", ".sh", ".mjs", ".js")

# A real invocation, not a quoted fixture.
#   python:  subprocess.run(["git", "status", ...])  /  run(["git","status",...])
PY_CALL = re.compile(r"""\[\s*["']git["']\s*,\s*["']status["']([^\]]*)\]""")
#   shell:   $(git status ...)  or  `git status ...`  or  git status at command position
SH_CALL = re.compile(r"""(?:\$\(|`|^\s*|&&\s*|\|\|\s*|;\s*)git\s+status\b([^\n)`]*)""", re.M)

# A pathspec makes it scoped: an explicit `--` separator, or a bare path argument.
PATHSPEC = re.compile(r"(--\s|[\"']?(?:\.{0,2}/|[A-Za-z_]+/)[^\s\"',\]]*)")
# argv flags that are not pathspecs
FLAGS = re.compile(r"^-{1,2}[A-Za-z-]+$")

# The comparison that turns a snapshot into an assertion.
#
# NOTE, and it is the reason this file carries a self-test: the first version of this regex
# wrapped the operator as `\b(==|!=)\b`. `\b` asserts a word/non-word boundary, and `==` is
# followed by a space — both non-word — so that alternation COULD NEVER MATCH. The census
# reported 0 whole-tree assertions against a hand-derived ground truth of 2, i.e. a FALSE
# CLEAN, in the direction that flattered the finding. Hence GROUND_TRUTH below.
COMPARE = re.compile(r"\bbefore\b[^\n]{0,40}(==|!=)[^\n]{0,40}\bafter\b"
                     r"|\bafter\b[^\n]{0,40}(==|!=)[^\n]{0,40}\bbefore\b"
                     r"|\[\s*\"?\$before\"?\s*(=|==|!=)\s*\"?\$after\"?\s*\]")

# Hand-derived by reading every `git status` site in the corpus (T-532). The census must agree
# with this or it is not measuring what it claims. Kept as a list of names, not a count: a
# count would go stale silently as the corpus grows, which is the G-015 defect this tree keeps
# finding. When one of these is legitimately fixed, delete its name here in the same commit.
GROUND_TRUTH = set()
# Emptied by T-533 in the same commit that scoped both instances — the two names below were the
# entire measured population and both are fixed:
#   tools/_t524-fabric-validate-teeth.py  -> scoped to .fabric
#   tools/_t525-fabric-coverage-teeth.py  -> scoped to .context/audits, excluding cron/
# Leaving them here after the fix would make this census REFUSE (rc 2) forever, which is the
# self-test working correctly and would have been the wrong thing to silence.

# This file quotes the patterns it searches for, so scanning itself yields self-matches. T-527
# solved the same problem by putting the checker in a different file from its subject; here the
# subject IS the directory the checker lives in, so it must exclude itself explicitly.
SELF = os.path.abspath(__file__)


COMMENT = re.compile(r"^\s*(#|//)")


def _strip_py_docstrings(src):
    """Blank bare string statements — module, class and function docstrings.

    T-558. `strip_comments` below closed the `#` half of this in T-533 and the docstring half
    stayed open for five days, until T-552 extracted `tools/_writeset_hermeticity.py`, whose
    module docstring explains at length that the FIRST form of that assertion used
    `git status --porcelain` and why the digest comparand replaced it. That module contains no
    subprocess call of any kind — it walks a subdirectory and hashes bytes — and this census
    reported it as the corpus's one WHOLE-TREE assertion, on the strength of a sentence
    describing the thing it stopped doing.

    That is precisely the failure mode `strip_comments` names: "a checker that is confused by
    comments ABOUT the pattern it detects gets steadily more wrong as authors document the
    thing." A docstring is a comment the tokenizer does not call a comment. The sibling census
    `tools/_t451-unwired-guard-census.py` reached the same conclusion under T-495 and blanks
    `ast.Expr(Constant str)` for the same reason; this is that fix arriving in the second
    census.

    Spans are BLANKED rather than deleted so line numbering and any real code sharing a line
    with a docstring's closing quotes survive. On a file that will not parse the source is
    returned unchanged: the resulting prose can only produce a FALSE WHOLE-TREE, which is the
    loud direction, and a false clean is what GROUND_TRUTH exists to prevent.
    """
    try:
        tree = ast.parse(src)
    except (SyntaxError, ValueError):
        return src
    lines = src.splitlines()
    for node in ast.walk(tree):
        if (isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant)
                and isinstance(node.value.value, str)
                and node.end_lineno is not None):
            for ln in range(node.lineno - 1, node.end_lineno):
                if 0 <= ln < len(lines):
                    start = node.col_offset if ln == node.lineno - 1 else 0
                    end = node.end_col_offset if ln == node.end_lineno - 1 else len(lines[ln])
                    lines[ln] = lines[ln][:start] + " " * (end - start) + lines[ln][end:]
    return "\n".join(lines)


def strip_comments(src, path=""):
    """Drop whole-line comments before classifying, and Python docstrings (T-558).

    T-533 found this the hard way: after both instances were scoped, the census still flagged
    them. The cause was the fix's own explanatory comments — prose containing `git status
    --porcelain` in backticks, which SH_CALL reads as a shell invocation. A checker that is
    confused by comments ABOUT the pattern it detects gets steadily more wrong as authors
    document the thing, which is the opposite of the intended incentive. Line-based only: a
    trailing comment after real code is left alone, since the code on that line is real.
    """
    if path.endswith(".py"):
        src = _strip_py_docstrings(src)
    return "\n".join("" if COMMENT.match(ln) else ln for ln in src.splitlines())


def scoped(argv_tail):
    """True when the invocation limits itself to a pathspec."""
    toks = [t for t in re.split(r"[\s,]+", argv_tail.strip()) if t]
    toks = [t.strip("\"'") for t in toks]
    for t in toks:
        if not t or FLAGS.match(t):
            continue
        if t == "--" or "/" in t or t.startswith("."):
            return True
    return False


def main():
    files = []
    for d in DIRS:
        base = os.path.join(ROOT, d)
        if not os.path.isdir(base):
            continue
        for root, _, fs in os.walk(base):
            for f in fs:
                p = os.path.join(root, f)
                if f.endswith(EXTS) and os.path.abspath(p) != SELF:
                    files.append(p)

    if len(files) < 20:
        print("REFUSE: only %d candidate files found under %s — the corpus is not what this "
              "census assumes." % (len(files), "/".join(DIRS)))
        print("This is an abstention, not a pass — nothing was evaluated.")
        return 2

    whole, scoped_hits, fixtures = [], [], []

    for path in sorted(files):
        try:
            src = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        if "git status" not in src and '"status"' not in src:
            continue

        rel = os.path.relpath(path, ROOT)
        src = strip_comments(src, path)
        calls = [m.group(1) for m in PY_CALL.finditer(src)]
        calls += [m.group(1) for m in SH_CALL.finditer(src)]

        if not calls:
            if "git status" in src:
                fixtures.append((rel, "git status appears only as quoted data"))
            continue

        has_cmp = bool(COMPARE.search(src))
        for tail in calls:
            if scoped(tail):
                scoped_hits.append((rel, tail.strip()[:40] or "(pathspec)"))
            elif has_cmp:
                whole.append(rel)
            else:
                # a real invocation with no pathspec and no before/after comparison:
                # a tree read, but not an assertion about hermeticity.
                fixtures.append((rel, "unasserted read — no before/after comparison"))

    whole = sorted(set(whole))

    print("T-532 — hermeticity assertions by scope")
    print("scanned: %d files under %s\n" % (len(files), ", ".join(DIRS)))

    print("WHOLE-TREE (defective — any other writer reddens these): %d" % len(whole))
    for r in whole:
        print("    %s" % r)
    print()
    print("SCOPED (correct — reported so green is classification, not absence): %d"
          % len(scoped_hits))
    for r, t in sorted(set(scoped_hits)):
        print("    %-52s %s" % (r, t))
    print()
    print("FIXTURE / unasserted (correct — never flagged): %d" % len(set(fixtures)))
    for r, why in sorted(set(fixtures)):
        print("    %-52s %s" % (r, why))

    print()
    print("LIMITS: only `git status` hermeticity is classified; a probe hashing the tree by")
    print("other means is not detected. Scope is judged from argv, not by execution.")

    # Self-test against hand-derived ground truth. A census that silently disagrees with the
    # reading it was built from is worse than no census — it converts an unknown into a wrong
    # known. This caught a regex that could never match (see COMPARE) reporting a false clean.
    found = set(whole)
    missed = GROUND_TRUTH - found
    if missed:
        print()
        print("REFUSE: the census disagrees with hand-derived ground truth. It did NOT flag:")
        for r in sorted(missed):
            print("    %s" % r)
        print("Either the classifier is broken or these were fixed without updating")
        print("GROUND_TRUTH. Until that is resolved nothing here was reliably evaluated.")
        return 2

    if whole:
        print()
        print("T-532 FAIL — %d whole-tree hermeticity assertion(s). Each is red whenever anything"
              % len(whole))
        print("else writes to the repo during its window, and green standalone. Scope the")
        print("snapshot to the paths the subject writes.")
        return 1

    print()
    print("T-532 OK — no whole-tree hermeticity assertions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
