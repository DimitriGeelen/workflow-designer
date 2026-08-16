#!/usr/bin/env python3
"""T-551 teeth — a sweep that keeps only the exit code cannot describe the failure it found.

`tools/_t509-instrument-sweep.sh` ran every probe as

    timeout "$TIMEOUT" "$runner" "tools/$f" > /dev/null 2>&1

so the only thing that survived a run was an integer. T-548 taught the sweep to classify those
integers honestly — regressed / did-not-finish / abstained / passed — and that is as far as an
integer can be taught. It could name WHICH probe failed and never WHY, because the sentence
naming the leg was discarded microseconds after it was written.

That became the binding constraint on a real, recurring problem. Three instruments have now
failed only inside a full run and passed every standalone attempt afterwards: `_t523` (rc=1,
9/9 green after), `_t366` (rc=2, rc=0 on three attempts after) and `_t344`'s leg 2. Three
failures, zero bytes retained from any of them, while `_t523` alone prints nine named legs when
run by hand. For that class of failure, "run it directly for its own output" is advice that
cannot be taken: running it directly is precisely what does not reproduce it.

These legs drive the REAL sweep over synthetic probes in a mktemp tree. The probes exit with
known codes and print known sentinels, and each leg asserts the sentinel reaches the sweep's
own report — not that some capture machinery exists. A probe checking only exit codes would
have stayed green across the entire defect, because the exit codes were never wrong.

The exclusion stubs are derived from the sweep's own EXCLUDE list rather than copied into a
literal here. A fixture carrying its own copy of a list that lives somewhere else is the exact
decay T-550 repaired one file over.

Seam: T551_SWEEP points the legs at a copy of the sweep, so the pre-T-551 redirect can be
reconstructed and shown to turn these legs red without editing the tracked file (PL-206 — a
control that has never been shown to fail is a control nobody has tested).

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWEEP = os.environ.get("T551_SWEEP") or os.path.join(
    ROOT, "tools", "_t509-instrument-sweep.sh")

FAIL_SENTINEL = "WIDGET_SENTINEL_9931"
ABSTAIN_SENTINEL = "ABSTAIN_SENTINEL_4417"
SLOW_SENTINEL = "SLOWPOKE_SENTINEL_7712"
PASS_SENTINEL = "QUIET_SENTINEL_5508"


def refuse(msg):
    print("REFUSE: %s" % msg)
    print("This is an abstention, not a pass — no leg was evaluated.")
    sys.exit(2)


def excluded_names(src):
    """The names the sweep exempts, read out of the sweep itself.

    The sweep exits 1 on a STALE EXCLUSION — an exemption whose file no longer exists — and it
    does so BEFORE the run loop. A fixture tree without these files never reaches the code
    under test, so every leg below would be judged on a run that never happened.
    """
    body = src.split("EXCLUDE=(", 1)[1].split("\n)", 1)[0]
    return [m.group(1) for m in re.finditer(r'^"([^|"]+)\|', body, re.M)]


def build_tree(where, probes, stubs):
    root = tempfile.mkdtemp(prefix="t551-tree-", dir=where)
    tools = os.path.join(root, "tools")
    os.makedirs(tools)
    shutil.copy2(SWEEP, os.path.join(tools, os.path.basename(SWEEP)))
    for name in stubs:
        # Excluded by name, so never run — it only has to exist.
        with open(os.path.join(tools, name), "w", encoding="utf-8") as fh:
            fh.write("# T-551 fixture stub: excluded by name, never executed\n")
    for name, body in probes.items():
        with open(os.path.join(tools, name), "w", encoding="utf-8") as fh:
            fh.write(body)
    return root


def run_sweep(root, tmpdir, **env_extra):
    env = dict(os.environ, TMPDIR=tmpdir, **env_extra)
    sweep = os.path.join(root, "tools", os.path.basename(SWEEP))
    p = subprocess.run(["bash", sweep], cwd=root, env=env,
                       capture_output=True, text=True, timeout=600, check=False)
    out = p.stdout + p.stderr
    if "STALE EXCLUSION" in out:
        refuse("the fixture tree is missing a file the sweep exempts by name, so the sweep "
               "exited before its run loop and no probe was executed. The exclusion list has "
               "changed shape and excluded_names() no longer parses it.")
    if "RAN " not in out:
        refuse("the sweep never reported a population in the fixture tree, so nothing below "
               "was measured. Output was:\n%s" % out)
    return p.returncode, out


def sh(body):
    return "#!/usr/bin/env bash\n" + body


def main():
    if not os.path.isfile(SWEEP):
        refuse("%s not found — there is no sweep to drive" % SWEEP)
    src = open(SWEEP, encoding="utf-8").read()
    stubs = excluded_names(src)
    if not stubs:
        refuse("could not parse the sweep's EXCLUDE list, so the fixture tree cannot be built "
               "without tripping the stale-exclusion exit. Nothing was evaluated.")

    failures = []
    passes = 0

    def leg(name, ok, detail=""):
        nonlocal passes
        if ok:
            passes += 1
            print("  PASS  %s" % name)
        else:
            failures.append(name)
            print("  FAIL  %s%s" % (name, ("\n        " + detail) if detail else ""))

    work = tempfile.mkdtemp(prefix="t551-work-")
    tmpdir = os.path.join(work, "tmp")
    os.makedirs(tmpdir)
    try:
        # ── leg 1: a regression carries its own account ────────────────────────────────────
        root = build_tree(work, {
            "_t551f-fail-teeth.sh": sh('echo "%s"\nexit 1\n' % FAIL_SENTINEL),
        }, stubs)
        rc, out = run_sweep(root, tmpdir)
        leg("1 a regressed probe's own output reaches the sweep's report",
            rc == 1 and "SWEEP FAIL" in out and FAIL_SENTINEL in out,
            "rc=%d, sentinel present=%s. This is the T-551 defect verbatim: the sweep knows a "
            "probe failed and cannot say what it said. For the intermittent class the probe "
            "will pass on every re-run, so this report is the only account that will exist."
            % (rc, FAIL_SENTINEL in out))

        # ── leg 2: an abstention IS its output ─────────────────────────────────────────────
        root = build_tree(work, {
            "_t551a-abstain-teeth.sh": sh('echo "%s"\nexit 2\n' % ABSTAIN_SENTINEL),
        }, stubs)
        rc, out = run_sweep(root, tmpdir)
        leg("2 an abstaining probe's reasoning reaches the report, still classified rc=3",
            rc == 3 and "ABSTAINED" in out and ABSTAIN_SENTINEL in out,
            "rc=%d, sentinel present=%s. A refusal to certify whose reasoning is discarded is "
            "indistinguishable from a probe that said nothing at all — and T-548's whole "
            "argument for the rc=2 class is that the reasoning is the finding."
            % (rc, ABSTAIN_SENTINEL in out))

        # ── leg 3: what it managed to say before the kill ──────────────────────────────────
        root = build_tree(work, {
            "_t551s-slow-teeth.sh": sh('echo "%s"\nsleep 30\n' % SLOW_SENTINEL),
        }, stubs)
        rc, out = run_sweep(root, tmpdir, T509_TIMEOUT="3")
        leg("3 a killed probe's pre-kill output reaches the report, still classified rc=3",
            rc == 3 and "DID NOT FINISH" in out and SLOW_SENTINEL in out,
            "rc=%d, sentinel present=%s. Where a probe was when the clock ran out is the first "
            "thing anyone measuring its cost needs, and a bare rc=124 withholds exactly that."
            % (rc, SLOW_SENTINEL in out))

        # ── leg 4: a green run stays quiet ─────────────────────────────────────────────────
        # Capture happens for passing probes too (so a probe that passes while printing
        # something alarming is not invisible by construction) but is dropped once the verdict
        # is known. A sweep that printed every green probe's chatter would be unreadable, and
        # unreadable is how the capture stops being read.
        root = build_tree(work, {
            "_t551p-pass-teeth.sh": sh('echo "%s"\nexit 0\n' % PASS_SENTINEL),
        }, stubs)
        rc, out = run_sweep(root, tmpdir)
        leg("4 a passing probe's output is captured and then dropped, not printed",
            rc == 0 and "SWEEP PASS" in out and PASS_SENTINEL not in out,
            "rc=%d, sentinel leaked=%s. Diagnosis was bought at the price of a report nobody "
            "reads if every green probe's output lands in it." % (rc, PASS_SENTINEL in out))

        # ── leg 5: bounded, and the bound is stated ────────────────────────────────────────
        noisy = 'for i in $(seq 1 500); do printf "LINE-%03d\\n" "$i"; done\nexit 1\n'
        root = build_tree(work, {"_t551t-trunc-teeth.sh": sh(noisy)}, stubs)
        rc, out = run_sweep(root, tmpdir, T509_CAPTURE_LINES="10")
        kept = re.findall(r"^\s+\| (LINE-\d+)$", out, re.M)
        leg("5 a pathological probe is truncated to the tail, and the truncation is stated",
            (rc == 1 and len(kept) == 10 and kept[-1] == "LINE-500"
             and "LINE-001" not in kept and "last 10 of 500 lines" in out),
            "rc=%d, kept %d line(s) ending %r, bound stated=%s. A silently clipped report is "
            "how a reader ends up confident about the wrong evidence; and the tail is the end "
            "to keep, because these probes print their verdict last."
            % (rc, len(kept), kept[-1] if kept else None,
               "last 10 of 500 lines" in out))

        # ── leg 6: absence is reported as absence ──────────────────────────────────────────
        root = build_tree(work, {
            "_t551q-quiet-fail-teeth.sh": sh("exit 1\n"),
        }, stubs)
        rc, out = run_sweep(root, tmpdir)
        leg("6 a probe that fails printing nothing says so, rather than showing an empty block",
            rc == 1 and "no output captured" in out,
            "rc=%d. An empty gap under a failure reads as 'the capture is broken'. Saying the "
            "probe printed nothing is a different and useful finding — it is the signature "
            "OBS-264 records for an arm that certifies on nothing." % rc)

        # ── leg 7: the capture leaves nothing behind ───────────────────────────────────────
        # Six sweep runs have now happened with TMPDIR pointed here. Every one of them created
        # a capture directory, and the trap is the only thing that removes them.
        leftover = [n for n in os.listdir(tmpdir) if n.startswith("t509-capture-")]
        leg("7 every capture directory is removed on exit",
            not leftover,
            "%d capture director(y/ies) survived %s. A diagnostic that accumulates temp files "
            "on every run is a diagnostic somebody disables." % (len(leftover), leftover))
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print()
    if failures:
        print("T-551 TEETH: %d/%d legs passed — FAILED: %s"
              % (passes, passes + len(failures), ", ".join(failures)))
        return 1
    print("T-551 TEETH: %d/%d legs passed — the sweep reports what each failing, abstaining "
          "and killed probe actually said, bounded and with the bound stated, stays quiet on "
          "green, and leaves no capture files behind" % (passes, passes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
