#!/usr/bin/env python3
"""_t517-vendor-divergence-teeth — prove the divergence instrument can go red, and how.

The instrument went green on its first run against the real tree. That is exactly the state
PL-206 warns about: a control that CAN fail is still worthless if nothing ever fed it a
stimulus containing the thing it looks for. So every leg here BUILDS the failure and asserts
the instrument names it.

Each leg constructs a throwaway git repository under mktemp with a synthetic vendored tree,
commits it as the baseline, then mutates the working tree. Hermetic: nothing outside the temp
directory is read or written, and the real repository is never touched — which matters more
than usual here, because this tool's whole subject is the state of the real vendored tree.

Legs deliberately include the two shapes that would otherwise hide:
  * MODE-only divergence — the eight-file class in the real manifest that carries no content
    change, so a content diff calls it clean.
  * REFUSAL vs PASS — an unreachable baseline must not render as "no divergence found".

Exit 0 all passed, 1 a leg failed, 2 the subject is missing.
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
TOOL = os.path.join(HERE, "_t517-vendor-divergence.py")

results = []


def leg(name, ok, detail=""):
    results.append((name, ok))
    print("  [%s] %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))


def git(repo, *args):
    return subprocess.run(
        ["git", "-c", "user.email=t517@test", "-c", "user.name=t517"] + list(args),
        cwd=repo, capture_output=True, text=True,
    )


MANIFEST_HEAD = "baseline_commit: %s\nbaseline_note: synthetic\nentries:\n"
ENTRY = "  - path: %s\n    kind: %s\n    task: T-000\n    upstream: fix\n    reason: synthetic\n"


def make_repo(tmp, name):
    """A synthetic repo whose baseline holds >100 vendored files and diverges in 2 known ways."""
    repo = os.path.join(tmp, name)
    vend = os.path.join(repo, ".agentic-framework", "agents")
    os.makedirs(vend)
    os.makedirs(os.path.join(repo, "tools"))
    # The instrument refuses a baseline holding <100 files (anti-dead-comparator), so the
    # synthetic baseline has to be a plausible tree rather than two files.
    for i in range(120):
        with open(os.path.join(vend, "f%03d.sh" % i), "w") as f:
            f.write("#!/bin/sh\necho %d\n" % i)
    shutil.copy(TOOL, os.path.join(repo, "tools", os.path.basename(TOOL)))
    git(repo, "init", "-q")
    git(repo, "add", "-A")
    git(repo, "commit", "-qm", "baseline")
    base = git(repo, "rev-parse", "HEAD").stdout.strip()
    return repo, base, vend


def write_manifest(repo, base, entries):
    p = os.path.join(repo, ".agentic-framework", ".vendor-divergence.yaml")
    with open(p, "w") as f:
        f.write(MANIFEST_HEAD % base)
        for path, kind in entries:
            f.write(ENTRY % (path, kind))
    return p


def run_tool(repo):
    r = subprocess.run([sys.executable, os.path.join(repo, "tools", os.path.basename(TOOL))],
                       cwd=repo, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def main():
    if not os.path.exists(TOOL):
        print("REFUSE: subject %s missing — a teeth script with no subject is not green" % TOOL)
        return 2

    with tempfile.TemporaryDirectory(prefix="t517-teeth-") as tmp:

        # ── leg 1: a declared-and-matching tree is green (anti-vacuity) ────────────────
        # Without this, every red leg below could be red because the tool is simply broken.
        # Green has to be reachable for red to mean anything.
        repo, base, vend = make_repo(tmp, "clean")
        target = ".agentic-framework/agents/f001.sh"
        with open(os.path.join(repo, target), "a") as f:
            f.write("# local fix\n")
        write_manifest(repo, base, [(target, "content")])
        rc, out = run_tool(repo)
        leg("declared content divergence is green (green is reachable, so red is meaningful)",
            rc == 0, "rc=%d" % rc)

        # ── leg 2: UNRECORDED content divergence goes red and names the path ───────────
        repo, base, vend = make_repo(tmp, "unrecorded")
        with open(os.path.join(repo, ".agentic-framework/agents/f002.sh"), "a") as f:
            f.write("# undeclared local fix\n")
        write_manifest(repo, base, [])
        rc, out = run_tool(repo)
        leg("unrecorded content divergence -> rc 1, path named",
            rc == 1 and "UNRECORDED" in out and "f002.sh" in out, "rc=%d" % rc)

        # ── leg 3: UNRECORDED MODE-ONLY divergence goes red ────────────────────────────
        # The class that hides. Content is byte-identical; only the exec bit moved. Eight
        # entries in the real manifest are exactly this, and T-276 proved a re-vendor demotes
        # them. A tool that classified this as "clean" would be worse than no tool, because it
        # would certify the very files most likely to be silently lost.
        repo, base, vend = make_repo(tmp, "modeonly")
        victim = os.path.join(repo, ".agentic-framework/agents/f003.sh")
        before = open(victim).read()
        os.chmod(victim, 0o755)
        after = open(victim).read()
        # Stimulus check (PL-206): assert the mutation really is mode-only. If the content
        # changed too, this leg would pass by detecting the content change and prove nothing
        # about mode detection.
        assert before == after, "leg 3 stimulus is not mode-only — it changed content"
        write_manifest(repo, base, [])
        rc, out = run_tool(repo)
        # Asserting on "[mode" rather than "mode": the bare word appears in the summary line
        # and in prose, so a content misclassification could still satisfy it. The bracketed
        # form is the classification column and nothing else produces it.
        leg("unrecorded MODE-ONLY divergence -> rc 1, classified as mode",
            rc == 1 and "f003.sh" in out and "[mode" in out, "rc=%d" % rc)

        # ── leg 4: a STALE entry goes red (the other direction) ────────────────────────
        # A path declared as diverged that now matches the baseline means either a re-vendor
        # adopted our fix upstream, or the local fix was lost. Both need a human.
        repo, base, vend = make_repo(tmp, "stale")
        write_manifest(repo, base, [(".agentic-framework/agents/f004.sh", "content")])
        rc, out = run_tool(repo)
        leg("stale manifest entry (declared, no longer diverges) -> rc 1",
            rc == 1 and "STALE" in out, "rc=%d" % rc)

        # ── leg 5: an unreachable baseline REFUSES, it does not pass ───────────────────
        repo, base, vend = make_repo(tmp, "badbase")
        write_manifest(repo, "0" * 40, [])
        rc, out = run_tool(repo)
        leg("unreachable baseline -> rc 2 REFUSE, not rc 0",
            rc == 2 and "REFUSE" in out, "rc=%d" % rc)

        # ── leg 6: a baseline holding no vendored tree REFUSES ─────────────────────────
        # An empty diff against the wrong reference point is indistinguishable from a clean
        # tree. PL-205: the probe must be able to say "I could not look".
        repo2 = os.path.join(tmp, "emptybase")
        os.makedirs(os.path.join(repo2, "tools"))
        os.makedirs(os.path.join(repo2, ".agentic-framework"))
        with open(os.path.join(repo2, "readme"), "w") as f:
            f.write("no vendored tree here\n")
        shutil.copy(TOOL, os.path.join(repo2, "tools", os.path.basename(TOOL)))
        git(repo2, "init", "-q")
        git(repo2, "add", "-A")
        git(repo2, "commit", "-qm", "empty")
        empty_base = git(repo2, "rev-parse", "HEAD").stdout.strip()
        write_manifest(repo2, empty_base, [])
        rc, out = run_tool(repo2)
        leg("baseline with no vendored files -> rc 2 REFUSE (empty diff is not proof of clean)",
            rc == 2 and "REFUSE" in out, "rc=%d" % rc)

        # ── leg 7: a missing manifest REFUSES rather than reporting a clean tree ───────
        repo, base, vend = make_repo(tmp, "nomanifest")
        rc, out = run_tool(repo)
        leg("absent manifest -> rc 2 REFUSE", rc == 2 and "REFUSE" in out, "rc=%d" % rc)

    failed = [n for n, ok in results if not ok]
    print("\nTEETH %s — %d passed, %d failed"
          % ("PASS" if not failed else "FAIL", len(results) - len(failed), len(failed)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
