#!/usr/bin/env python3
"""T-316: no collectable test file may sit outside the gating runner.

A suite nobody runs cannot report a failure, so its silence is indistinguishable
from health. Nine files in tests/ were named by no runner at all; all nine passed
when finally run by hand, which is precisely why the condition survived.

PREDICATE (adopted from AEF rail 349, their wording): MATCH WHAT A RUNNER WOULD
COLLECT, NOT WHAT LOOKS LIKE A TEST. bats runs *.bats; pytest collects test_*.py
and *_test.py. Anything else under tests/ is a helper, and flagging it is a false
positive. Per their L-527 a guard with false positives is not a stricter guard —
it is one that gets ignored, and the honest response to it is to stop running it.

REACHABILITY IS NOT COMPLETENESS. AEF wired a directory into one runner, turned
their guard green, and the suite that actually gates still named a single file.
One mention anywhere satisfies a mention-anywhere guard. Our tree is worse on
this axis: four runners live in tests/, and a file named only by
check-corpus-node-cuts.sh (9 task-Verification references) would read as wired
while run-bridge-tests.sh — the suite 78 tasks actually call — never touches it.
So this guard checks membership in the GATING runner specifically, not in the
union of runners.

ANCHORING. Matching a bare basename is the prose-in-the-haystack class (third
instance this arc): a token in a comment or an echo string satisfies the check.
Comments are stripped first, and the match requires the invocation path form
`tests/<name>`, which is how the runner actually calls a leg — a structural
literal rather than a loose token.

NOT-VACUOUS. A check that cannot find its subject must go RED, not pass quietly.
If the gating runner is missing, renamed, or empty, that is a failure here — the
T-312 span-vacuity class, where a scan bounded on something that moved kept
returning green over an empty span.
"""
import os
import re
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TESTS = os.path.join(ROOT, "tests")
GATING_RUNNER = os.path.join(TESTS, "run-bridge-tests.sh")
SELF = os.path.basename(__file__)

# Directories under tests/ that hold no runnable legs.
SKIP_DIRS = {"fixtures", "__pycache__", ".pytest_cache"}

# Deliberate exclusions: collectable files knowingly kept out of the gating
# runner, each with a stated reason. COUNTED, not suppressed — every entry
# prints a NOTE on every run and the count is asserted, so a silent new entry
# fails the build. A tolerance kept past its cause is a suppression list with
# better manners; when the reason dies, delete the entry.
DELIBERATE = {}


def _collectable(name):
    """True iff a runner would actually collect this file.

    bats: *.bats. pytest: test_*.py and *_test.py. Everything else under tests/
    is a helper (shared fixtures builders, drivers invoked from Verification
    blocks) and must NOT be flagged.
    """
    return (name.endswith(".bats")
            or (name.startswith("test_") and name.endswith(".py"))
            or name.endswith("_test.py"))


def _strip_comments(text):
    """Drop whole-line comments. A comment naming a path is prose about the
    wiring, not the wiring."""
    return "\n".join(ln for ln in text.splitlines()
                     if not re.match(r"^\s*#", ln))


def collectable_files(tests_dir):
    """Every collectable file under tests_dir, as paths relative to tests_dir."""
    found = []
    for dirpath, dirnames, filenames in os.walk(tests_dir):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fn in filenames:
            if _collectable(fn):
                rel = os.path.relpath(os.path.join(dirpath, fn), tests_dir)
                found.append(rel)
    return sorted(found)


def find_orphans(tests_dir, runner_path):
    """Collectable files under tests_dir that runner_path does not invoke.

    Raises RuntimeError when the runner cannot be read or carries no code —
    an unevaluable check must fail, not pass.
    """
    if not os.path.isfile(runner_path):
        raise RuntimeError(
            "gating runner not found at %s — renamed or deleted; this guard "
            "cannot evaluate and must not pass" % runner_path)
    code = _strip_comments(open(runner_path, encoding="utf-8").read())
    if not code.strip():
        raise RuntimeError(
            "gating runner %s has no non-comment content — every file would "
            "look orphaned and the guard would be reporting noise, not a "
            "finding" % runner_path)
    orphans = []
    for rel in collectable_files(tests_dir):
        # Structural literal: the invocation path form, not the bare basename.
        if ("tests/" + rel.replace(os.sep, "/")) not in code:
            orphans.append(rel)
    return orphans


# ---------------------------------------------------------------------------
# Negative controls. The predicate is exercised against synthetic trees, because
# a guard proven only by reading is not proven. Three controls, and the third is
# the one that decides whether this survives contact with people.
# ---------------------------------------------------------------------------

def _synthetic(tmp, files, runner_lines):
    tdir = os.path.join(tmp, "tests")
    os.makedirs(tdir, exist_ok=True)
    for rel in files:
        path = os.path.join(tdir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, "w").write("# synthetic\n")
    runner = os.path.join(tdir, "run-bridge-tests.sh")
    open(runner, "w").write("\n".join(runner_lines) + "\n")
    return tdir, runner


def negative_controls():
    failures = []
    tmp = tempfile.mkdtemp(prefix="t316-controls-")
    try:
        # (a) RED on a synthetic collectable orphan.
        tdir, runner = _synthetic(
            tmp + "/a", ["test_wired.py", "test_zzz_orphan.py"],
            ['python3 "$ROOT/tests/test_wired.py"'])
        got = find_orphans(tdir, runner)
        if got != ["test_zzz_orphan.py"]:
            failures.append("control (a) synthetic orphan: expected "
                            "['test_zzz_orphan.py'], got %r" % (got,))

        # (b) RED on call-site drift — the runner exists and is non-empty, but
        #     no longer names a file that is still on disk. This is the mode the
        #     nine arrived in: nobody deleted a test, the call site moved away.
        tdir, runner = _synthetic(
            tmp + "/b", ["test_wired.py"],
            ['python3 "$ROOT/tests/some-other-thing.py"'])
        got = find_orphans(tdir, runner)
        if got != ["test_wired.py"]:
            failures.append("control (b) call-site drift: expected "
                            "['test_wired.py'], got %r" % (got,))

        # (c) GREEN on a directory holding only a non-collectable helper. The
        #     false-positive control. A guard that flags helpers gets switched
        #     off, and a guard that is switched off is worth less than none,
        #     because its absence is at least honest.
        tdir, runner = _synthetic(
            tmp + "/c", ["test_wired.py", "scripts/yaml_parse_helper.py",
                         "scripts/conftest_stub.py"],
            ['python3 "$ROOT/tests/test_wired.py"'])
        got = find_orphans(tdir, runner)
        if got != []:
            failures.append("control (c) helper false-positive: expected [], "
                            "got %r" % (got,))

        # (d) RED when the runner is unreadable or empty — must raise, not pass.
        for label, lines in (("missing", None), ("empty", ["# only a comment"])):
            tdir, runner = _synthetic(tmp + "/d" + label, ["test_wired.py"],
                                      lines or ["placeholder"])
            if lines is None:
                os.remove(runner)
            else:
                open(runner, "w").write("\n".join(lines) + "\n")
            try:
                find_orphans(tdir, runner)
                failures.append("control (d/%s): expected RuntimeError, got a "
                                "clean pass — the guard would be vacuous" % label)
            except RuntimeError:
                pass

        # (e) A comment naming the path must NOT count as wiring. The runner
        #     needs a LIVE leg as well, or the empty-runner rule in (d) fires
        #     first and this control tests nothing — the first cut of this
        #     control had only the commented line and died on (d)'s check.
        tdir, runner = _synthetic(
            tmp + "/e", ["test_live.py", "test_wired.py"],
            ['python3 "$ROOT/tests/test_live.py"',
             '# python3 "$ROOT/tests/test_wired.py"   <- disabled last week'])
        got = find_orphans(tdir, runner)
        if got != ["test_wired.py"]:
            failures.append("control (e) commented-out call site: expected "
                            "['test_wired.py'], got %r" % (got,))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return failures


def main():
    failures = []

    print("== T-316: runner-orphan guard ==")

    # 1. Negative controls first. If the predicate is wrong, the real-tree
    #    result below is meaningless whichever way it comes out.
    ctrl = negative_controls()
    if ctrl:
        failures.extend(ctrl)
        for c in ctrl:
            print("  FAIL control: %s" % c)
    else:
        print("  OK   negative controls: orphan RED, drift RED, helper GREEN, "
              "unevaluable RED, commented-call RED (5)")

    # 2. Fixed point: this guard must itself be invoked by the runner it checks.
    #    Otherwise removing its leg retires it silently — the exact condition it
    #    exists to detect, applied to itself.
    try:
        code = _strip_comments(open(GATING_RUNNER, encoding="utf-8").read())
    except OSError as e:
        failures.append("cannot read gating runner: %s" % e)
        code = ""
    if ("tests/" + SELF) not in code:
        failures.append(
            "fixed point: %s is not invoked by %s — this guard would be silently "
            "retired by deleting its own leg" % (SELF, os.path.basename(GATING_RUNNER)))
    else:
        print("  OK   fixed point: guard is wired into %s"
              % os.path.basename(GATING_RUNNER))

    # 3. The real tree.
    try:
        orphans = find_orphans(TESTS, GATING_RUNNER)
    except RuntimeError as e:
        failures.append(str(e))
        orphans = []
    else:
        blocking = [o for o in orphans if o not in DELIBERATE]
        for o in orphans:
            if o in DELIBERATE:
                print("  NOTE (deliberate) %s — %s" % (o, DELIBERATE[o]))
        total = len(collectable_files(TESTS))
        if blocking:
            failures.append(
                "%d collectable file(s) are not invoked by %s: %s"
                % (len(blocking), os.path.basename(GATING_RUNNER),
                   ", ".join(blocking)))
            for b in blocking:
                print("  FAIL orphan: tests/%s" % b)
        else:
            print("  OK   %d collectable file(s), all invoked by %s"
                  % (total, os.path.basename(GATING_RUNNER)))

        # The deliberate list is COUNTED. A silent new entry is the actual
        # failure mode, so the count is asserted rather than the list merely
        # being consulted.
        if len(DELIBERATE) != 0:
            failures.append("deliberate-exclusion list is %d, expected 0 — an "
                            "exclusion was added without updating this "
                            "assertion" % len(DELIBERATE))

    if failures:
        print("\nFAIL: %d" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\nPASS: no collectable test file sits outside the gating runner")
    return 0


if __name__ == "__main__":
    sys.exit(main())
