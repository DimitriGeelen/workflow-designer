#!/usr/bin/env python3
"""T-607 — can the focus-drift gate SEE the command form this project mandates?

WHAT THIS GUARDS. The drift gate anchored its fw patterns on `(^|[[:space:]])(bin/)?fw`.
CLAUDE.md mandates `cd /opt/... && .agentic-framework/bin/fw ...`, where the character
before `bin/fw` is `/` — a branch the alternation did not have. So the gate was blind to
the only invocation form the project tells people to use, while still firing on pattern 3
(which anchors on the commit message, not on fw). A gate that is live for one pattern and
dead for another looks alive. PL-182: reachability is not binary.

HOW IT TESTS. It drives the REAL hook over stdin. It does not re-implement the regex —
a test that re-states the pattern it is checking agrees with itself by construction and
would have passed on the broken code.

Every probe runs against a THROWAWAY project root with a pinned focus, so the matrix is
deterministic regardless of the session's actual focus, and so the bypass cases cannot
append fabricated entries to the real .gate-bypass-log.yaml — an audit ledger is not a
test fixture.
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
HOOK = REPO / ".agentic-framework" / "agents" / "context" / "check-active-task.sh"

FOCUS = "T-607"          # pinned focus inside the throwaway root
OTHER = "T-999"          # a different task -> drift
DRIFT = "FOCUS-DRIFT"

FORMS = {
    "bare":     "fw",
    "bin":      "bin/fw",
    "mandated": ".agentic-framework/bin/fw",
    "absolute": "/opt/832-Workflow-designer/.agentic-framework/bin/fw",
}


def make_root(tmp):
    root = Path(tmp) / "proj"
    (root / ".context" / "working").mkdir(parents=True)
    (root / ".context" / "working" / "focus.yaml").write_text(
        f"current_task: {FOCUS}\npriorities: []\n")
    (root / ".framework.yaml").write_text("name: probe\n")
    return root


def run(root, command):
    payload = json.dumps({"tool_name": "Bash",
                          "tool_input": {"command": command},
                          "cwd": str(root)})
    r = subprocess.run(["bash", str(HOOK)], input=payload, capture_output=True,
                       text=True, timeout=60, env={"CLAUDECODE": "1", "PATH": "/usr/bin:/bin",
                                                   "HOME": str(root)})
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def cases():
    """(label, command, expect_drift, kind) — kind drives reporting, not pass/fail."""
    out = []
    for name, form in FORMS.items():
        # Pattern 1 — the defect. Every form must reach the gate.
        out.append((f"P1 {name:8s} drift", f"{form} task update {OTHER} --status issues",
                    True, "fix"))
        # Control per form: same verb, target IS the focus. A change that simply blocks
        # everything would pass the drift legs and fail here — which is the point.
        out.append((f"P1 {name:8s} no-drift control", f"{form} task update {FOCUS} --status issues",
                    False, "control"))
    # Pattern 3 anchors on the commit message, so it was never form-sensitive. Included as
    # a second control: it must be unchanged by this fix.
    out.append(("P3 git commit drift", f'git commit -m "{OTHER}: something"', True, "control"))
    out.append(("P3 git commit no-drift", f'git commit -m "{FOCUS}: something"', False, "control"))
    # Over-match guard: a token merely ENDING in fw is not the framework CLI.
    out.append(("over-match myfw", f"myfw task update {OTHER} --status issues", False, "guard"))
    out.append(("over-match xfw/", f"x/myfw task update {OTHER} --status issues", False, "guard"))
    # Bypasses must still work after the anchor widened.
    out.append(("bypass --switch-focus",
                f".agentic-framework/bin/fw task update {OTHER} --status issues --switch-focus",
                False, "bypass"))
    out.append(("bypass FW_SWITCH_FOCUS=1",
                f"FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw task update {OTHER} --status issues",
                False, "bypass"))
    return out


def evaluate(root):
    rows = []
    for label, cmd, expect_drift, kind in cases():
        rc, out = run(root, cmd)
        saw = DRIFT in out
        good = saw == expect_drift
        # A bypass leg that only checks "no block" passes for the WRONG reason if the
        # pattern stopped matching altogether — absence of a block is not evidence the
        # override fired. Require the override's own note.
        if kind == "bypass":
            good = good and ("focus-drift override" in out)
        rows.append((label, kind, expect_drift, saw, good, rc))
    return rows


def report(rows):
    ok = True
    for label, kind, expect, saw, good, rc in rows:
        if not good:
            ok = False
        want = "drift" if expect else "no drift"
        got = "drift" if saw else "no drift"
        print(f"  [{'PASS' if good else 'FAIL'}] {label:28s} ({kind:7s}) expected {want:8s} got {got:8s} exit={rc}")
    return ok


# ------------------------------------------------------------------ known-open condition

def pattern2_status(root):
    """Pattern 2 stays unreachable until T-392. REPORT it rather than omit it: a matrix
    that quietly drops the case it cannot satisfy is how a partial fix comes to look
    total. This is informational and does NOT gate the verdict — asserting the broken
    state would turn a defect into a requirement."""
    rc, out = run(root, f'.agentic-framework/bin/fw context add-learning "x" --task {OTHER}')
    reachable = DRIFT in out
    print(f"\n  [{'CHANGED' if reachable else 'KNOWN-OPEN'}] P2 fw context add-* --task <other>: "
          f"{'now reaches the gate' if reachable else 'still shadowed by the safe-command early-return'}")
    if not reachable:
        print("             This is T-392, a SEPARATE cause with an identical symptom: the")
        print("             early-return at check-active-task.sh:97 exits 0 before the gate")
        print("             at :305, so no anchor fix can reach it. Not fixed by T-607.")
    else:
        print("             T-392 appears to have landed — fold this case into the matrix above.")
    return reachable


def main():
    print("T-607 — drift-gate reachability across invocation forms\n" + "=" * 74)
    with tempfile.TemporaryDirectory() as tmp:
        root = make_root(tmp)
        rows = evaluate(root)
        ok = report(rows)
        pattern2_status(root)

        print("\npoison arm (restores the file, sha256-verified)")
        before = hashlib.sha256(HOOK.read_bytes()).hexdigest()
        src = HOOK.read_text()
        needle = "(^|[[:space:]])([^[:space:]]*/)?fw"
        if needle not in src:
            print("  [SKIP] widened anchor absent — arm would probe UNPOISONED code")
            arm_ok = False
        else:
            HOOK.write_text(src.replace(needle, "(^|[[:space:]])(bin/)?fw"))
            try:
                poisoned = evaluate(root)
            finally:
                HOOK.write_text(src)
            restored = hashlib.sha256(HOOK.read_bytes()).hexdigest() == before
            # The arm must redden the MANDATED/ABSOLUTE path forms and leave bare/bin green.
            red = {lbl.split()[1] for lbl, k, e, s, good, rc in poisoned
                   if not good and k == "fix"}
            green = {lbl.split()[1] for lbl, k, e, s, good, rc in poisoned
                     if good and k == "fix"}
            arm_ok = ({"mandated", "absolute"} <= red) and ({"bare", "bin"} <= green) and restored
            print(f"  [{'PROVEN' if arm_ok else 'NOT PROVEN'}] revert to (bin/)? anchor: "
                  f"reddened {sorted(red) or 'NOTHING'}, still green {sorted(green)}; "
                  f"restored={'yes' if restored else 'NO — TREE LEFT DIRTY'}")

    print("=" * 74)
    verdict = "PASS" if ok and arm_ok else "FAIL"
    print(f"{verdict} — {sum(1 for r in rows if r[4])}/{len(rows)} matrix legs; "
          f"arm {'proven failable' if arm_ok else 'NOT proven'}")
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
