#!/usr/bin/env python3
"""T-549 teeth — a cheaper stimulus that can no longer fail is not a cheaper test.

T-549 moved _t525's four branch legs off this repository and onto a 20-file fixture, taking
the probe from 86.04s to ~24.6s. The saving is real and so is the risk it creates: a fixture
is a stimulus somebody built, and a stimulus somebody built can be built — by accident — so
that the legs it drives cannot go red. PL-206 names that class, and T-543's `_t523` showed
what it looks like from outside: an arm certifying on nothing while reporting green.

So this probe breaks the subject on purpose and requires _t525 to notice.

Method: copy the vendored framework, edit ONE branch of the fabric coverage check in the copy,
and run _t525 against it via the T525_FW seam. The real .agentic-framework is never written —
the copy is a full copytree, not a hardlink farm, precisely so that truncating a file in the
copy cannot reach the original through a shared inode.

_t525 is driven in T525_SCOPE=branches mode (~8s rather than ~25s), because the legs under
examination here are exactly the ones that moved to the fixture. Legs 1, 6b and 7 still audit
this repository, were not made cheaper, and are out of scope for this probe. That mode exits 2
by construction, so this file reads the LEG LINES rather than the exit code — which is also
the only way to assert that the RIGHT leg went red rather than merely that something did.

The control matters as much as the mutations: an unmutated copy must come back all-green. If
it does not, then every red below is the copy mechanism failing and not a leg with teeth, and
the whole probe would be measuring itself.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VENDORED = os.path.join(ROOT, ".agentic-framework")
T525 = os.path.join(ROOT, "tools", "_t525-fabric-coverage-teeth.py")
AUDIT_REL = os.path.join("agents", "audit", "audit.sh")

# Each mutation is (label, needle, replacement, leg that must go red, why it must).
# The needles are read out of the real file and verified present before anything runs, so a
# rewritten audit.sh makes this probe REFUSE rather than quietly stop mutating anything.
MUTATIONS = [
    (
        "card-loss-renders-as-flat",
        'fabric_dir_note="CARD LOSS: $(( fabric_prev_reg - fabric_registered )) fewer cards',
        'fabric_dir_note="cards flat since $fabric_prev_day (ignored: $(( fabric_prev_reg - fabric_registered )) fewer cards',
        "2",
        "card loss printed as flat is the exact blind spot T-525 was raised to close: a "
        "deleted card and twenty new files produce one line and one reading",
    ),
    (
        "growth-renders-as-card-loss",
        'fabric_dir_note="+$(( fabric_registered - fabric_prev_reg )) cards since',
        'fabric_dir_note="CARD LOSS: $(( fabric_registered - fabric_prev_reg )) cards since',
        "3",
        "growth reported as loss sends the operator hunting deleted cards during a period "
        "when carding was working",
    ),
    (
        "abstention-renders-as-flat",
        'fabric_dir_note="direction not evaluated — no prior audit report carries a Fabric line"',
        'fabric_dir_note="cards flat since the beginning of time (0)"',
        "5",
        "PL-205 exactly: 'I have no prior value' rendered as 'no change' is a claim about "
        "history the instrument cannot support",
    ),
]

FAIL_RE = re.compile(r"^\s*FAIL\s+(\S+)", re.M)


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no mutation was evaluated.")
    sys.exit(2)


# Every variable that can route `fw` at a framework other than the one its own path implies.
# `fw` EXPORTS both of these (bin/fw:639-640), so anything that runs this probe from inside a
# framework command — the P-011 verification gate, most obviously — hands the child a pointer
# straight back to the real vendored tree.
#
# This is not hypothetical and it is not a tidy-up. The first version of this file stripped
# PROJECT_ROOT and not FRAMEWORK_ROOT. Run by hand it was 4/4 green; run under
# `fw task update --status work-completed` all three mutations came back green and the probe
# accused three sound legs of having no teeth. A probe that reports "your test cannot fail" is
# doing more damage when it is wrong than when it is silent, and it was wrong in precisely the
# environment that matters. Hence the resolution precondition below rather than just the fix.
FRAMEWORK_ROUTING_VARS = ("FRAMEWORK_ROOT", "PROJECT_ROOT")


def child_env(fw_path, **extra):
    env = dict(os.environ, **extra)
    for var in FRAMEWORK_ROUTING_VARS:
        env.pop(var, None)
    return env


def resolved_framework(fw_path, where):
    """Which framework tree `fw_path` resolves to, ASKED UNDER THE CONDITIONS THE AUDIT RUNS.

    `where` must stand in for _t525's fixture: outside this repository and with no vendored
    framework of its own. That matters, and getting it wrong was the first version of this
    check. Asked from inside this repo, `fw` resolves to the real vendored tree and is right
    to (bin/fw:128, T-498 prefers a project's own framework) — so a precondition asked there
    reports a mismatch that does not exist for the calls it is meant to be about, and refuses
    a probe whose mutations were in fact landing correctly.

    The lesson is the same one this file exists to enforce, one level up: a control has to be
    run against the thing it certifies, not against something nearby.
    """
    p = subprocess.run([fw_path, "version"], cwd=where,
                       env=child_env(fw_path, PROJECT_ROOT=where),
                       capture_output=True, text=True, timeout=120, check=False)
    m = re.search(r"^Framework:\s*(\S+)", p.stdout + p.stderr, re.M)
    return m.group(1) if m else None


def run_t525(fw_path):
    """Drive _t525 in branch scope against `fw_path`. Returns (rc, output, failed legs)."""
    env = child_env(fw_path, T525_FW=fw_path, T525_SCOPE="branches")
    p = subprocess.run([sys.executable, T525], cwd=ROOT, env=env,
                       capture_output=True, text=True, timeout=600, check=False)
    out = p.stdout + p.stderr
    return p.returncode, out, FAIL_RE.findall(out)


def main():
    if not os.path.isdir(VENDORED):
        refuse("%s is not here — there is no framework to copy or mutate" % VENDORED)
    if not os.path.isfile(T525):
        refuse("%s is missing — the probe under examination is not here" % T525)

    real_audit = os.path.join(VENDORED, AUDIT_REL)
    if not os.path.isfile(real_audit):
        refuse("%s not found; the coverage check does not live where this probe expects"
               % real_audit)
    src = open(real_audit, encoding="utf-8").read()
    for label, needle, _repl, _leg, _why in MUTATIONS:
        if src.count(needle) != 1:
            refuse("mutation %r expects exactly one occurrence of its needle in audit.sh and "
                   "found %d. The check has been rewritten since this probe was built. "
                   "Re-derive the mutations against the current source rather than trust a "
                   "green from a probe that would now mutate nothing.\n  needle: %s"
                   % (label, src.count(needle), needle))

    failures = []
    passes = 0
    tmp = tempfile.mkdtemp(prefix="t549-mutation-")
    try:
        copy = os.path.join(tmp, "framework")
        # copytree, not a hardlink farm: writing to a hardlinked copy would reach the real
        # vendored file through the shared inode. 29M is cheap; corrupting AEF's tooling is not.
        shutil.copytree(VENDORED, copy, symlinks=True)
        copy_fw = os.path.join(copy, "bin", "fw")
        copy_audit = os.path.join(copy, AUDIT_REL)
        if not os.path.isfile(copy_fw):
            refuse("the copied framework has no bin/fw at %s" % copy_fw)

        # ── precondition: the copy is the framework that will actually run ─────────────────
        # Asked of `fw` itself rather than assumed from the path it was invoked by. Without
        # this, an inherited routing variable sends every run back to the real tree, all three
        # mutations come back green, and the probe reports the LEGS as toothless — a false
        # accusation against sound code, which is a worse failure than staying quiet.
        elsewhere = os.path.join(tmp, "elsewhere")
        os.makedirs(elsewhere, exist_ok=True)
        resolved = resolved_framework(copy_fw, elsewhere)
        if resolved is None or os.path.realpath(resolved) != os.path.realpath(copy):
            refuse("the copied fw resolves its framework to %r, not to the copy at %r, when "
                   "asked from a directory standing in for _t525's fixture. Every mutation "
                   "below would edit a file the subject never reads, and each leg would then "
                   "be reported as having no teeth when the real fault is here. The usual "
                   "cause is a framework-routing variable inherited from a caller: %s. "
                   "Nothing was evaluated."
                   % (resolved, copy,
                      ", ".join("%s=%s" % (v, os.environ[v])
                                for v in FRAMEWORK_ROUTING_VARS if v in os.environ) or "none set"))
        print("  PASS  the copied fw resolves to the copy, so a mutation below reaches the "
              "subject")
        passes += 1

        # ── control ────────────────────────────────────────────────────────────────────────
        rc, out, failed = run_t525(copy_fw)
        if failed or rc != 2:
            refuse("the UNMUTATED copy did not come back clean (rc=%d, failed legs=%s). Every "
                   "verdict below would then be measuring the copy mechanism rather than the "
                   "legs. Nothing was evaluated.\n%s" % (rc, failed or "none", out[-1200:]))
        print("  PASS  control — the unmutated copy runs green, so a red below is the mutation")
        passes += 1

        # ── one run per mutation ───────────────────────────────────────────────────────────
        for label, needle, repl, want_leg, why in MUTATIONS:
            with open(copy_audit, "w", encoding="utf-8") as fh:
                fh.write(src.replace(needle, repl))
            rc, out, failed = run_t525(copy_fw)
            if want_leg in failed:
                print("  PASS  %s — leg %s went red" % (label, want_leg))
                passes += 1
            elif failed:
                failures.append(
                    "%s: the subject was broken and _t525 DID go red, but on leg(s) %s rather "
                    "than leg %s. A probe that reds on the wrong leg sends the reader to the "
                    "wrong branch. %s" % (label, ", ".join(failed), want_leg, why))
            else:
                failures.append(
                    "%s: leg %s stayed GREEN against a subject whose branch was deliberately "
                    "broken. That leg cannot fail as currently written, so its green says "
                    "nothing. %s\n      output: %s"
                    % (label, want_leg, why, out.strip()[-500:]))
        # Leave the copy pristine on the way out so a crash mid-loop cannot leave a mutated
        # audit.sh anywhere a later reader might mistake for the real one.
        with open(copy_audit, "w", encoding="utf-8") as fh:
            fh.write(src)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print()
    if failures:
        print("T-549 MUTATION TEETH: %d finding(s)" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("T-549 MUTATION TEETH: %d/%d green — _t525's fixture legs still detect a broken "
          "coverage check. The cost reduction removed work, not discrimination."
          % (passes, passes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
