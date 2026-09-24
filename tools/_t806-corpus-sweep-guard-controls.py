#!/usr/bin/env python3
"""_t806-corpus-sweep-guard-controls.py — regression test for T-806's flag-validation
guard on tools/bake-clean-layout.py.

WHAT THIS PROVES. The incident T-806 exists to fix: a `--help` invocation of
bake-clean-layout.py silently fell through argument parsing and ran a full bake,
rewriting all 24 files under examples/aef-processes/rendered/ — the seam artefact
AEF pins against. The fix makes unrecognized `-`/`--` flags REFUSE instead of
being silently stripped, and makes `--help`/`--dry-run` genuinely no-op.

WHY THE HEAVY DEPENDENCIES ARE STUBBED. A real bake calls run_driver(), which
shells out to a headless-Chrome CDP script to run the editor's actual Clean
layout — slow, and irrelevant to what this test checks. The defect and the fix
are both in main()'s ARGUMENT GATING, before run_driver ever runs. So this test
loads bake-clean-layout.py as a module and monkeypatches resolve_corpus/sources/
run_driver/write_back/mint_store_version, then asks one question per case: did
write_back get called? That isolates the gate from the (expensive, unrelated)
pipeline it gates.

CONTROL CASE (T-806 AC5): the same harness runs against the PRE-FIX source,
pinned at PRE_FIX_REF (the parent of the commit that introduced the flag
guard — NOT `HEAD`, which is the fixed version from the moment the fix is
committed and would silently turn this into fixed-vs-fixed on every later
run) with `--help`. That version's guard does not exist, so write_back DOES
get called — proving this test would have caught the original incident, not
just that it passes against the fixed code.

Exit 0 = all pass; exit 1 = any failure (P-011 gate reads this).
"""
import hashlib
import importlib.util
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "tools", "bake-clean-layout.py")
RENDERED = os.path.join(ROOT, "examples", "aef-processes", "rendered")

# Pinned, not HEAD: HEAD is the fixed version from the moment the fix commit
# lands, which would make the "control" compare fixed-vs-fixed on every run
# after that moment and pass for the wrong reason. Pin to the parent of the
# commit that introduced the guard so the control stays a real pre-fix source
# forever, independent of how far HEAD has since moved.
PRE_FIX_REF = "93fc39cf^"

results = []


def check(name, cond, detail=""):
    results.append((name, bool(cond), detail))
    print("%s %s%s" % ("PASS" if cond else "FAIL", name, (" — " + detail) if detail else ""))


def load_module(path, unique_name):
    spec = importlib.util.spec_from_file_location(unique_name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def stub(mod):
    """Replace the expensive/irrelevant pipeline with a fixed fake result, and
    record which write-capable functions get invoked."""
    calls = []
    mod.resolve_corpus = lambda names: ["fake-map"]
    mod.sources = lambda: ["fake-map"]
    mod.run_driver = lambda maps: {
        "fake-map": {"ok": True, "xml": "<fake/>", "moved": 0,
                      "messinessBefore": 0, "messinessAfter": 0, "iters": 1},
    }
    mod.write_back = lambda base, xml: calls.append(("write_back", base))
    mod.mint_store_version = lambda base, xml, thumb=None: calls.append(("mint", base)) or None
    return calls


def run(mod, argv):
    calls = stub(mod)
    try:
        rc = mod.main(list(argv))
    except SystemExit as e:
        rc = e.code
    return rc, calls


def corpus_sha():
    h = hashlib.sha256()
    for name in sorted(os.listdir(RENDERED)):
        if name.endswith(".bpmn"):
            with open(os.path.join(RENDERED, name), "rb") as fh:
                h.update(name.encode() + b":" + fh.read())
    return h.hexdigest()


def main():
    sha_before = corpus_sha()

    fixed = load_module(TOOL, "bake_fixed")

    rc, calls = run(fixed, ["--help"])
    check("fixed: --help does not write", not calls, "calls=%r" % (calls,))
    check("fixed: --help exits 0", rc == 0, "rc=%r" % (rc,))

    rc, calls = run(fixed, ["--bogus-flag"])
    check("fixed: unknown flag does not write", not calls, "calls=%r" % (calls,))
    check("fixed: unknown flag refuses (exit 2)", rc == 2, "rc=%r" % (rc,))

    rc, calls = run(fixed, ["--dry-run"])
    check("fixed: --dry-run does not write", not calls, "calls=%r" % (calls,))
    check("fixed: --dry-run exits 0", rc == 0, "rc=%r" % (rc,))

    rc, calls = run(fixed, [])
    check("fixed: legitimate no-args bake still writes (not over-blocked)",
          ("write_back", "fake-map") in calls, "calls=%r" % (calls,))

    # --check is excluded here: its own code path reads real on-disk bytes at
    # RENDERED/<base>.bpmn to compare against, which the stub doesn't fake —
    # unrelated to what this test checks (whether write_back gets called at
    # all). --check never called write_back before or after T-806.

    # --- Control case: the PRE-FIX source, same harness, same --help case ---
    old_src = subprocess.run(
        ["git", "-C", ROOT, "show", "%s:tools/bake-clean-layout.py" % PRE_FIX_REF],
        capture_output=True, text=True)
    if old_src.returncode != 0 or not old_src.stdout.strip():
        check("control: retrieved pre-fix source from git", False,
              "git show %s failed: %s" % (PRE_FIX_REF, old_src.stderr.strip()))
    elif "FLAGS = (" in old_src.stdout:
        # The pin itself could rot (force-push, history rewrite) into pointing
        # at a commit that already has the guard — which would make this
        # control vacuous (fixed-vs-fixed again) without ever failing loudly.
        check("control: pinned ref is genuinely pre-fix (no FLAGS guard present)", False,
              "PRE_FIX_REF=%s already contains the guard — pin has rotted, update it" % PRE_FIX_REF)
    else:
        with tempfile.NamedTemporaryFile(suffix=".py", mode="w", delete=False) as fh:
            fh.write(old_src.stdout)
            old_path = fh.name
        try:
            old = load_module(old_path, "bake_old")
            rc, calls = run(old, ["--help"])
            check("control: pre-fix --help DID write (proves the guard is load-bearing)",
                  ("write_back", "fake-map") in calls, "calls=%r" % (calls,))
        finally:
            os.unlink(old_path)

    sha_after = corpus_sha()
    check("real corpus unmodified by this run", sha_before == sha_after,
          "before=%s after=%s" % (sha_before[:12], sha_after[:12]))

    passed = sum(1 for _, ok, _ in results if ok)
    failed = len(results) - passed
    print("\ncontrols: %d pass, %d fail" % (passed, failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
