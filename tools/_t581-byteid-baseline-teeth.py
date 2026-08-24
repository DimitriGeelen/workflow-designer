#!/usr/bin/env python3
"""
_t581-byteid-baseline-teeth.py — teeth for the recorded-golden byte-identity gate.

WHAT THIS EXISTS TO PREVENT. T-581 moved tools/_t358-byteid-thirdparty.mjs off a
hand-picked git ref (`3bf37909~1`) and onto 11 recorded goldens. That repair is only
worth its weight if the new gate can still go RED — and the specific failure this
task is repairing is a gate that reports health it never checked. Shipping a green
gate and asserting from the code's shape that it "would" catch drift would repeat the
defect inside the repair.

So each leg BREAKS SOMETHING SPECIFIC and requires the gate to notice, for the
predicted reason and with the predicted exit code:

  CONTROL  unmutated build vs the real goldens        -> rc 0, "11 identical"
  (a)      one golden byte changed                    -> rc 1, DRIFTED naming THAT fixture
  (b)      the emitter changed                        -> rc 1, DRIFTED
  (c)      uid derivation made nondeterministic       -> rc 2, REFUSING
  (d)      the suite's own invocation carries no      -> asserted POSITIVELY: every
           --record                                      invocation is enumerated and
                                                         its argv checked, never by
                                                         grepping for an absence

WHY THE CONTROL IS A LEG AND NOT A COURTESY. Legs (a)-(c) all assert a NON-zero exit.
Every one of them is satisfied by a gate that is simply broken — a typo in the tool
exits non-zero on all four runs and reads as four passes. The control is the only leg
that can tell "the teeth bite" from "the tool is dead", so it runs first and its
failure aborts the rest.

WHY (d) IS NOT A GREP. `grep -c -- --record tests/run-bridge-tests.sh` returning 0 is
satisfied identically by "the suite does not pass --record" and by "my pattern was
wrong" (T-560, and the absence-assertion census that now ratchets on it). This leg
instead enumerates the invocations of the gate in the runner, REQUIRES at least one to
exist, and checks the argv of each. Absence is then a property of a population that was
proven non-empty.

WHAT THIS INHERITED (T-579 AC5). `tools/_t364-byteid-precondition-teeth.py` was retired in
the same commit that added this file, and leg (c) is why. Those teeth proved the CROSS-BUILD
precondition could fire: a crafted same-x uid-less document made the two builds' uid vectors
disagree, so the gate refused. T-581 deleted the second build, which deletes that term — not
weakens it, deletes it — so there was no longer a proposition for them to test. They were
already failing for exactly that reason: they parse for the literal strings `PRECONDITION
HOLDS` / `PRECONDITION VIOLATED`, and the gate stopped printing both, the first because it
was a false claim on this corpus (2 fixtures carry 16 tie groups over 64 uid-less nodes)
and the second because its cause cannot arise. Repointing them at new strings would have
restored a green reading for a check that no longer exists — the precise failure this whole
line of work keeps finding. Leg (c) covers what SURVIVED: within-build uid determinism, the
half that can still be false.

Exit 0 = every leg behaved as predicted. Exit 1 = a leg did not. Exit 2 = harness
failure (missing tool, missing corpus, control red) — the teeth could not be run at all,
which is not the same as the gate being fine.
"""

import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GATE = ROOT / "tools" / "_t358-byteid-thirdparty.mjs"
SRC = ROOT / "src" / "aef-workflow-designer.html"
GOLDENS = ROOT / "tests" / "goldens" / "third-party"
RUNNER = ROOT / "tests" / "run-bridge-tests.sh"
TIMEOUT = int(os.environ.get("T581_TIMEOUT", "300"))

results = []


def leg(name, ok, detail):
    results.append((name, ok, detail))
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}")
    for line in detail.splitlines():
        print(f"         {line}")


def run_gate(src=None, goldendir=None):
    """Run the gate under overrides. Returns (rc, combined output)."""
    env = dict(os.environ)
    if src:
        env["T358_SRC"] = str(src)
    if goldendir:
        env["T358_GOLDENDIR"] = str(goldendir)
    p = subprocess.run(
        ["node", str(GATE)],
        cwd=str(ROOT), env=env, capture_output=True, text=True, timeout=TIMEOUT,
    )
    return p.returncode, p.stdout + p.stderr


def invocations_of(script_text, tool_basename):
    """Lines of a shell script that actually RUN `tool_basename` under node.

    CORRECTED DURING THIS TASK, and the correction is the point. The first draft
    matched any non-comment line containing the tool name. That found THREE hits in
    a runner that invokes the gate ONCE: the invocation, the `report FAIL "..."`
    message which quotes the command for the reader, and the `show_output` label.
    Two of the three were prose. A leg that exists to replace a wrong-pattern
    absence check had itself produced a wrong-pattern presence count.

    The discriminator is shell semantics, not text: an invocation is a TOKEN whose
    basename is the tool, immediately preceded by the token `node`. Under shlex a
    quoted message is a single token however much command-looking text it contains,
    so `report FAIL "... run 'node tools/x.mjs' ..."` yields no `node` token at all,
    and `show_output "$TMP/a.out" "x.mjs"` yields the tool as a token preceded by a
    path rather than by `node`.

    Limitation, stated rather than papered over: this reads line by line, so an
    invocation split across a line continuation would be missed. The caller requires
    a non-empty result, so that failure mode surfaces as "no invocation found" —
    a red leg — and not as a vacuous pass.
    """
    found = []
    for ln, line in enumerate(script_text.splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue
        if tool_basename not in line:
            continue
        try:
            toks = shlex.split(line, comments=True)
        except ValueError:
            # Unbalanced quotes on this line alone (e.g. a continuation). Cannot
            # decide it; report it as an invocation so it gets looked at rather
            # than silently dropped from a population we are about to quantify over.
            found.append((ln, line.strip()))
            continue
        for i, t in enumerate(toks):
            if os.path.basename(t) == tool_basename and i > 0 and os.path.basename(toks[i - 1]) == "node":
                found.append((ln, line.strip()))
                break
    return found


def copy_goldens(dest):
    shutil.copytree(GOLDENS, dest)
    return dest


def main():
    if not GATE.exists():
        print(f"ERROR: gate not found at {GATE}")
        return 2
    if not GOLDENS.is_dir() or not list(GOLDENS.glob("*.golden")):
        print(f"ERROR: no recorded goldens under {GOLDENS} — nothing to have teeth about.")
        print("       Record them deliberately: node tools/_t358-byteid-thirdparty.mjs --record")
        return 2

    golden_files = sorted(p.name for p in GOLDENS.glob("*.golden"))
    print(f"\nTeeth for the recorded-golden byte-identity gate ({len(golden_files)} golden(s))\n")

    tmp = Path(tempfile.mkdtemp(prefix="t581-teeth-"))
    try:
        # ── CONTROL ───────────────────────────────────────────────────────────────
        # Runs FIRST and aborts the rest on failure: legs (a)-(c) each assert a
        # non-zero exit, so a gate that is merely broken satisfies all three.
        rc, out = run_gate()
        ctl_ok = rc == 0 and "PASS —" in out
        m = re.search(r"(\d+) identical, (\d+) drifted", out)
        leg(
            "CONTROL: the unmutated build matches its recorded goldens",
            ctl_ok,
            f"rc={rc}; {'counts: ' + m.group(0) if m else 'no count line found'}",
        )
        if not ctl_ok:
            print("\n  Control is RED. Every remaining leg asserts a non-zero exit and would")
            print("  therefore 'pass' against a gate that is simply broken. Refusing to run them.")
            print("\n  --- gate output ---")
            print("\n".join("  " + l for l in out.splitlines()[-40:]))
            return 2

        # ── (a) a changed golden byte ─────────────────────────────────────────────
        gdir = copy_goldens(tmp / "goldens-a")
        victim = gdir / golden_files[0]
        text = victim.read_text()
        # Change ONE byte inside emitted content, not the framing: append a character to
        # the first name= attribute value. Chosen over truncation because a truncated
        # golden could plausibly be caught by a length check rather than a comparison.
        mutated, n = re.subn(r'(name=")([^"]*)(")', r'\1\2X\3', text, count=1)
        if n != 1:
            leg("(a) a changed golden byte is caught", False,
                f"harness: no name= attribute to mutate in {victim.name}")
        else:
            victim.write_text(mutated)
            rc, out = run_gate(goldendir=gdir)
            fixture = golden_files[0][: -len(".golden")]
            named = bool(re.search(re.escape(fixture) + r"\s+DRIFTED", out))
            ok = rc == 1 and named
            leg("(a) a changed golden byte goes red, naming that fixture", ok,
                f"rc={rc} (want 1); output names '{fixture} DRIFTED': {named}\n"
                f"mutated one name= value in {victim.name}")

        # ── (b) a changed emitter ─────────────────────────────────────────────────
        gdir_b = copy_goldens(tmp / "goldens-b")
        src_b = tmp / "src-b.html"
        s = SRC.read_text()
        # BPMN_EXPORTER reaches <definitions exporter="..."> on every emission (T-399),
        # so this is one edit that must move every fixture's bytes.
        s_b, n = re.subn(
            r"const BPMN_EXPORTER = 'aef-workflow-designer';",
            "const BPMN_EXPORTER = 'aef-workflow-designer-MUTANT';",
            s, count=1,
        )
        if n != 1:
            leg("(b) a changed emitter is caught", False,
                "harness: BPMN_EXPORTER declaration not found in src — update this leg")
        else:
            src_b.write_text(s_b)
            rc, out = run_gate(src=src_b, goldendir=gdir_b)
            nd = re.search(r"(\d+) identical, (\d+) drifted", out)
            drifted = int(nd.group(2)) if nd else -1
            ok = rc == 1 and drifted == len(golden_files)
            leg("(b) a changed emitter goes red", ok,
                f"rc={rc} (want 1); drifted={drifted} (want {len(golden_files)} — "
                f"exporter= is on every emission)")

        # ── (c) nondeterministic uid derivation ───────────────────────────────────
        gdir_c = copy_goldens(tmp / "goldens-c")
        src_c = tmp / "src-c.html"
        # deriveUid is T-364's repair: uid derives from the element id via hash32, so a
        # second parse of the same bytes yields the same uid vector. Replacing the seed
        # hash with randomness restores the pre-T-364 behaviour the gate must refuse.
        s_c, n = re.subn(
            r"let uid = `\$\{prefix\}_\$\{hash32\(seed\)\}`;",
            "let uid = `${prefix}_${Math.random().toString(36).slice(2, 10)}`;",
            s, count=1,
        )
        if n != 1:
            leg("(c) nondeterministic uid minting is refused", False,
                "harness: deriveUid's hash32 seed line not found in src — update this leg")
        else:
            src_c.write_text(s_c)
            rc, out = run_gate(src=src_c, goldendir=gdir_c)
            refused = "REFUSING" in out and "deterministically" in out
            ok = rc == 2 and refused
            leg("(c) a build with nondeterministic uid minting is REFUSED, not compared", ok,
                f"rc={rc} (want 2 — a refusal, not a drift); refusal text present: {refused}\n"
                "made deriveUid return Math.random() instead of hash32(seed)")

        # ── (d) the suite does not pass --record ──────────────────────────────────
        # Positive form: enumerate the invocations, prove the population is non-empty,
        # then state a fact about each member.
        if not RUNNER.exists():
            leg("(d) the suite's invocation carries no --record", False,
                f"harness: runner not found at {RUNNER}")
        else:
            runner_text = RUNNER.read_text()
            invocations = invocations_of(runner_text, "_t358-byteid-thirdparty.mjs")
            if not invocations:
                leg("(d) the suite's invocation carries no --record", False,
                    "the runner contains NO executable invocation of the gate. This leg "
                    "asserts a property of every invocation; with none, that assertion is "
                    "vacuously true and therefore worthless. Wire the gate (AC5) first.")
            else:
                offenders = [(ln, t) for ln, t in invocations if "--record" in t]
                ok = not offenders
                detail = (f"{len(invocations)} executable invocation(s) found, "
                          f"line(s) {', '.join(str(ln) for ln, _ in invocations)}; "
                          f"{len(offenders)} carry --record (want 0)")
                if offenders:
                    detail += "\n" + "\n".join(f"line {ln}: {t}" for ln, t in offenders)
                leg("(d) every executable invocation of the gate in the suite omits --record",
                    ok, detail)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    npass = sum(1 for _, ok, _ in results if ok)
    print(f"\n  {npass}/{len(results)} leg(s) passed\n")
    return 0 if npass == len(results) else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.TimeoutExpired as e:
        print(f"ERROR: a gate run exceeded {TIMEOUT}s ({e}). Harness failure, not a verdict.")
        sys.exit(2)
