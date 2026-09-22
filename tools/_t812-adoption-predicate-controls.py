#!/usr/bin/env python3
"""_t812-adoption-predicate-controls.py — does the adoption leg actually discriminate?

T-812, value review finding F-02.

THE DEFECT BEING GUARDED. `verdict()` in tools/_t382-release-lag.py used to escalate the
adoption leg only on `adopt_days` — the age of OUR OWN latest tag — while `adopt_behind`,
the only value carrying the distance, was interpolated into a message and never compared.
A peer eleven releases behind graded `ok` because we had cut a tag that day. Every release
reset the gauge, so the condition could be held green indefinitely by releasing.

TWO THINGS THIS ASSERTS, and the second is the one a future edit is most likely to break.

  1. DISTANCE ESCALATES ON ITS OWN. Every case below pins `adopt_days` LOW, so a leg can
     only pass if the distance is what moved it. The old predicate fails all of them, which
     is the point: these legs bind to the fix rather than passing regardless.

  2. EVERY ADOPTION REASON CARRIES THE AUDIT'S GREP ANCHOR. audit.sh builds its line with
     `grep -m1 'peer pin behind'`. The first wording of this fix — "peer pin 4 releases
     behind" — does NOT contain that substring, so a distance-only escalation would have
     reached the saved audit record as "see probe" with the reason discarded. The finding
     already names invisibility-in-the-record as half of F-02; reintroducing it while
     fixing the predicate would have been its own joke. A reworded message is one edit away
     from breaking this again, and nothing else checks it.

WHY NOT FIX audit.sh INSTEAD: it is vendored, and T-519 records that this exact file already
carries five local divergences plus a live risk that "at the next re-vendor their audit.sh
overwrites ours and the other four die". Raising that exposure for a display fix is the worse
trade; the anchor is cheaper to keep on our side. The `${_l1:-${_l2:-...}}` shadowing F-02
also names — build lag hiding adoption lag in the same run — is NOT fixed and is recorded in
T-812's decisions rather than silently left.

Exit: 0 all controls hold | 1 a control failed
"""

import importlib.util
import os
import sys

REPO = os.environ.get(
    "T812_REPO_ROOT",
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)
PROBE = os.path.join(REPO, "tools", "_t382-release-lag.py")

AUDIT_GREP_ANCHOR = "peer pin behind"

PASS = 0
FAIL = 0


def leg(name, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print(f"  ok   {name}" + (f"  {detail}" if detail else ""))
    else:
        FAIL += 1
        print(f"  FAIL {name}  {detail}")


def load():
    if not os.path.exists(PROBE):
        print(f"CANNOT MEASURE: probe not found: {PROBE}", file=sys.stderr)
        sys.exit(1)
    spec = importlib.util.spec_from_file_location("_rl", PROBE)
    if spec is None or spec.loader is None:
        print("CANNOT MEASURE: could not load the probe as a module", file=sys.stderr)
        sys.exit(1)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    m = load()

    base = {"sha_ok": True, "peer_pin_readable": True, "build_commits": 0,
            "build_days": 0, "adopt_days": 0, "adopt_behind": None,
            "adopt_versions_behind": 0}

    # Anti-vacuity first: a clean input must grade ok, else every "not ok" below is free.
    lvl, _ = m.verdict(dict(base))
    leg("clean input -> ok (so the cases below mean something)", lvl == "ok", f"-> {lvl}")

    # adopt_days is LOW in every case: only the distance can be doing the work.
    cases = [
        ("peer 4 behind, tag 0d  (the F-01 shape)", 4, 0, "fail"),
        ("peer 3 behind, tag 0d", 3, 0, "fail"),
        ("peer 11 behind, tag 0d", 11, 0, "fail"),
        ("peer 1 behind, tag 0d", 1, 0, "warn"),
    ]
    for name, behind, days, want in cases:
        lvl, reasons = m.verdict({**base, "adopt_behind": "x -> y",
                                  "adopt_versions_behind": behind, "adopt_days": days})
        leg(f"{name} -> {want}", lvl == want, f"-> {lvl}")
        leg(f"    ...and its reason is visible to audit.sh",
            any(AUDIT_GREP_ANCHOR in r for r in reasons),
            f"-> {reasons[0][:60] if reasons else '(no reason)'}")

    # An unplaceable pin must never read as healthy, and must still be reportable.
    lvl, reasons = m.verdict({**base, "adopt_behind": "9.9.9 -> y",
                              "adopt_versions_behind": None, "adopt_days": 0})
    leg("unplaceable pin -> fail, never ok", lvl == "fail", f"-> {lvl}")
    leg("    ...and its reason is visible to audit.sh",
        any(AUDIT_GREP_ANCHOR in r for r in reasons),
        f"-> {reasons[0][:60] if reasons else '(no reason)'}")

    # Age must still escalate on its own — the fix ADDS a signal, it does not replace one.
    lvl, _ = m.verdict({**base, "adopt_behind": "x -> y",
                        "adopt_versions_behind": 1, "adopt_days": 30})
    leg("peer 1 behind but stuck 30d -> fail (age still bites)", lvl == "fail", f"-> {lvl}")

    # The distance counter must place a real pair, else every case above asserts on a
    # function that returns None for everything.
    series = m.released_versions()
    d = m.versions_between(series[0], series[-1]) if len(series) >= 2 else None
    leg("distance counter places a real pair from dist/",
        d is not None and d == len(series) - 1,
        f"-> {d!r} over {len(series)} released version(s)")

    print(f"\ncontrols: {PASS} passed, {FAIL} failed")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
