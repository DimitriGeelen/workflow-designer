#!/usr/bin/env python3
"""_t517-vendor-divergence — hold the vendored framework tree against its vendor baseline.

G-008 lets us fix `.agentic-framework/` in-tree AND upstream the fix. The tree records that a
fix happened (a commit); nothing records that the fix is LOCAL — present here, absent upstream.
That invisibility runs both ways and has already cost:

  * email-archive re-pinged G-AUDIT-EXCLUDE-NOT-HONORED three times over four months while our
    T-374 sat here as a tested implementation of the exact remedy they proposed.
  * T-276's own follow-up commit reads "post-vendor repair — restore exec bits demoted by old
    do_vendor copy (5 files) + chmod secret-scan". The last re-vendor DID clobber local state
    and it was caught by hand.

So this compares the live vendored tree against the recorded baseline commit and asserts the
diverged SET equals the manifest's declared set.

WHY A SET AND NOT A COUNT. A count of diverged files is a global always-moving property: it
rises with every legitimate G-008 fix, so a count ratchet would fire on correct work and teach
its reader to re-baseline reflexively. That is the G-015 class tools/verification-hygiene.py
already catalogues (832 T-508). Set equality fires only on divergence nobody DECLARED, in either
direction — an unrecorded patch, or a manifest entry that no longer diverges because a re-vendor
adopted it upstream. Both are things a human should see.

MODE-ONLY DIVERGENCE IS THE HALF THAT HIDES. Eight of the files that diverge here carry no
content change at all — only 100644 => 100755. A reviewer diffing content reports them clean,
and a re-vendor silently demotes them. They are classified and reported explicitly.

Exit codes are three-valued on purpose:
  0  actual divergence == manifest
  1  divergence differs from the manifest (unrecorded, or stale entry)
  2  REFUSE — the comparison could not be made (missing/unparseable manifest, unreachable
     baseline commit, or a baseline that holds no vendored files at all)

2 exists because rc 0 must never be reachable by a broken comparator. "No divergence found"
and "I could not look" are different facts and an instrument that renders both as green is the
PL-205 failure this repo keeps re-finding.
"""
import os
import subprocess
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
VENDOR_PATH = ".agentic-framework"
MANIFEST = os.path.join(ROOT, VENDOR_PATH, ".vendor-divergence.yaml")

# Paths that are runtime state written INTO the vendored tree by the framework itself rather
# than edits we made. Declared here rather than in the manifest because they are not fixes to
# upstream and there is nothing to upstream: excluding them in the manifest would put a
# non-fix in a register whose whole purpose is "what should travel upstream".
RUNTIME_STATE = (
    VENDOR_PATH + "/.context/",
)


def git(*args, cwd=ROOT):
    return subprocess.run(["git"] + list(args), cwd=cwd, capture_output=True, text=True)


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("        rc 2 — the comparison was not made. This is not a pass.")
    return 2


def load_manifest():
    if not os.path.exists(MANIFEST):
        return None, "manifest absent at %s" % MANIFEST
    try:
        with open(MANIFEST, encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except Exception as e:  # noqa: BLE001 - any parse failure is a refusal, not a verdict
        return None, "manifest unparseable: %s" % e
    if not isinstance(data, dict) or not data.get("baseline_commit"):
        return None, "manifest has no baseline_commit"
    return data, None


def actual_divergence(baseline):
    """{path: kind} for the working tree vs the baseline commit.

    Working tree, not HEAD: an uncommitted patch to vendored code is exactly the state this
    instrument should surface, and it is also the state a re-vendor would destroy first.

    `git diff --raw` carries both modes and both blob shas, which is what makes the mode-only
    class separable. --name-status would collapse it into 'M' and the eight exec-bit files
    would be indistinguishable from content edits.
    """
    r = git("diff", "--raw", "--abbrev=40", baseline, "--", VENDOR_PATH)
    if r.returncode != 0:
        return None, r.stderr.strip()
    out = {}
    for line in r.stdout.splitlines():
        if not line.startswith(":"):
            continue
        meta, _, path = line.partition("\t")
        path = path.strip()
        if not path or any(path.startswith(p) for p in RUNTIME_STATE):
            continue
        fields = meta[1:].split()
        if len(fields) < 5:
            continue
        src_mode, dst_mode, src_sha, dst_sha, status = fields[:5]

        # An UNSTAGED working-tree file has no hashed blob, so --raw reports its dst sha as all
        # zeros. Left as-is that makes src_sha != dst_sha unconditionally and every mode-only
        # change downstream is misclassified as content — which is the whole class this tool
        # exists to make visible, silently mislabelled in exactly the state it matters most:
        # someone has just patched vendored code and has not committed yet. Hash it ourselves.
        # (Caught by the teeth leg asserting on the classification column rather than on red/
        # green. Red for the wrong reason still counts as wrong.)
        if dst_sha.strip("0") == "" and not status.startswith("D"):
            full = os.path.join(ROOT, path)
            if os.path.exists(full):
                h = git("hash-object", full)
                if h.returncode == 0 and h.stdout.strip():
                    dst_sha = h.stdout.strip()

        if status.startswith("A") or src_sha.strip("0") == "":
            kind = "added"
        elif status.startswith("D"):
            kind = "deleted"
        elif src_sha == dst_sha and src_mode != dst_mode:
            kind = "mode"
        else:
            kind = "content"
        out[path] = kind
    return out, None


def main():
    manifest, err = load_manifest()
    if err:
        return refuse(err)

    baseline = manifest["baseline_commit"]

    # Is the baseline reachable at all? An unreachable ref makes `git diff` fail, and a
    # comparator that cannot resolve its own reference point must not report a clean tree.
    if git("cat-file", "-e", baseline + "^{commit}").returncode != 0:
        return refuse("baseline commit %s is unreachable in this repository" % baseline[:12])

    # Anti-dead-comparator: a baseline that holds no vendored files would yield an empty diff
    # that reads exactly like a clean tree. Check the reference point is populated BEFORE
    # believing anything the diff says about it.
    ls = git("ls-tree", "-r", "--name-only", baseline, "--", VENDOR_PATH)
    baseline_files = [l for l in ls.stdout.splitlines() if l.strip()]
    if len(baseline_files) < 100:
        return refuse(
            "baseline %s holds only %d files under %s — that is not a vendored framework tree, "
            "so an empty diff would mean 'wrong reference point', not 'no divergence'"
            % (baseline[:12], len(baseline_files), VENDOR_PATH)
        )

    actual, err = actual_divergence(baseline)
    if actual is None:
        return refuse("git diff against %s failed: %s" % (baseline[:12], err))

    declared = {}
    for e in manifest.get("entries") or []:
        if isinstance(e, dict) and e.get("path"):
            declared[e["path"]] = e.get("kind", "content")

    unrecorded = {p: k for p, k in actual.items() if p not in declared}
    stale = {p: k for p, k in declared.items() if p not in actual}
    reclassified = {
        p: (declared[p], actual[p]) for p in actual if p in declared and declared[p] != actual[p]
    }

    by_kind = {}
    for k in actual.values():
        by_kind[k] = by_kind.get(k, 0) + 1

    print("vendor baseline : %s (%d files)" % (baseline[:12], len(baseline_files)))
    print("diverged now    : %d  (%s)" % (
        len(actual), ", ".join("%s=%d" % (k, v) for k, v in sorted(by_kind.items())) or "none"))
    print("declared        : %d" % len(declared))

    if not unrecorded and not stale and not reclassified:
        print("\nOK — every diverged path is declared, and every declared path still diverges.")
        return 0

    print("")
    for p, k in sorted(unrecorded.items()):
        print("  UNRECORDED  [%-7s] %s" % (k, p))
        print("              a local change to vendored code that no manifest entry claims.")
    for p, k in sorted(stale.items()):
        print("  STALE       [%-7s] %s" % (k, p))
        print("              declared as diverged but matches the baseline now — adopted "
              "upstream, or the local fix was lost.")
    for p, (was, now) in sorted(reclassified.items()):
        print("  RECLASSIFIED %s: declared %s, actually %s" % (p, was, now))

    print("\nFAIL — %d unrecorded, %d stale, %d reclassified. Update %s."
          % (len(unrecorded), len(stale), len(reclassified), MANIFEST))
    return 1


if __name__ == "__main__":
    sys.exit(main())
