#!/usr/bin/env python3
"""T-392 — does the focus-drift gate survive the safe-command fast path?

THE DEFECT. `check-active-task.sh` exited 0 for any command on the safe-list roughly 240
lines above the focus-drift gate. `fw context add-learning --task T-OTHER` is on that
list, so drift pattern 2 never executed. T-607 widened the gate's path anchor and reported
this as still-open, because no anchor can rescue a block that is never reached.

TWO DEFECTS, ONE SYMPTOM. Both presented identically: a drifting command exited 0 in
silence. Only a control separated them — the bare form `fw task update T-OTHER` reached
the gate while `.agentic-framework/bin/fw task update T-OTHER` did not (T-607, anchor),
and NO form of `fw context add-* --task T-OTHER` reached it (T-392, shadow). A fix
credited to one cause would have left the other live and looked complete.

WHAT THIS ADDS OVER T-607's MATRIX. Pattern-2 legs across every invocation form, plus the
regression controls the deferral itself could break: the safe-list must still allow safe
commands when focus is stale, when no focus file exists, and when no task is active. The
fix converts an early `exit 0` into a late one, so the risk is not that drift stops
working — it is that `ls` acquires a task precondition. Those controls are the point.

The hook is driven over stdin against throwaway roots. Bypass legs assert the override's
own note, never merely the absence of a block.
"""
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
HOOK = REPO / ".agentic-framework" / "agents" / "context" / "check-active-task.sh"

FOCUS = "T-392"
OTHER = "T-999"
DRIFT = "FOCUS-DRIFT"

FORMS = {"bare": "fw", "bin": "bin/fw", "mandated": ".agentic-framework/bin/fw",
         "absolute": "/opt/832-Workflow-designer/.agentic-framework/bin/fw"}


def make_root(tmp, focus=FOCUS, session=None, focus_file=True, framework=True):
    root = Path(tmp)
    (root / ".context" / "working").mkdir(parents=True, exist_ok=True)
    if focus_file:
        txt = f"current_task: {focus}\npriorities: []\n"
        if session:
            txt += f"focus_session: {session}\n"
        (root / ".context" / "working" / "focus.yaml").write_text(txt)
    if session:
        (root / ".context" / "working" / "session.yaml").write_text(
            "session_id: S-CURRENT-0001\n")
    if framework:
        (root / ".framework.yaml").write_text("name: probe\n")
    return root


def run(root, command):
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command},
                          "cwd": str(root)})
    r = subprocess.run(["bash", str(HOOK)], input=payload, capture_output=True, text=True,
                       timeout=60,
                       env={"CLAUDECODE": "1", "PATH": "/usr/bin:/bin", "HOME": str(root)})
    return r.returncode, (r.stdout or "") + (r.stderr or "")


def evaluate(root):
    """(label, kind, expect_drift, saw_drift, good, rc)"""
    cases = []
    for name, form in FORMS.items():
        # THE FIX: pattern 2 is on the safe-list, so before T-392 none of these reached
        # the gate for any form.
        cases.append((f"P2 {name:8s} drift", "fix", True,
                      f'{form} context add-learning "x" --task {OTHER}'))
        cases.append((f"P2 {name:8s} control", "control", False,
                      f'{form} context add-learning "x" --task {FOCUS}'))
    # T-607's pattern 1 must not regress.
    cases.append(("P1 mandated drift", "control", True,
                  f".agentic-framework/bin/fw task update {OTHER} --status issues"))
    cases.append(("P1 mandated control", "control", False,
                  f".agentic-framework/bin/fw task update {FOCUS} --status issues"))
    # Over-match guard: a token merely ending in fw is not the framework CLI.
    cases.append(("over-match myfw", "guard", False,
                  f'myfw context add-learning "x" --task {OTHER}'))
    # Bypasses must survive the deferral, and must prove the override FIRED.
    cases.append(("bypass --switch-focus", "bypass", False,
                  f'.agentic-framework/bin/fw context add-learning "x" --task {OTHER} --switch-focus'))
    cases.append(("bypass FW_SWITCH_FOCUS=1", "bypass", False,
                  f'FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw context add-learning "x" --task {OTHER}'))

    rows = []
    for label, kind, expect, cmd in cases:
        rc, out = run(root, cmd)
        saw = DRIFT in out
        good = saw == expect
        if kind == "bypass":
            good = good and ("focus-drift override" in out)
        rows.append((label, kind, expect, saw, good, rc))
    return rows


def regression_rows():
    """The deferral's real risk: a safe command acquiring a task precondition.

    Each of these exited 0 BEFORE the fix by never reaching the gates below. They must
    still exit 0 after it, for a different reason (an explicitly guarded late exit)."""
    rows = []
    with tempfile.TemporaryDirectory() as tmp:
        # stale focus: focus_session != current session -> T-560 blocks WORK, not `ls`
        root = make_root(Path(tmp) / "stale", session="S-OLD-0001")
        rc, out = run(root, "ls -la")
        rows.append(("safe cmd under STALE focus", "regress", rc == 0, out))
    with tempfile.TemporaryDirectory() as tmp:
        # initialized project, no focus.yaml -> T-002 blocks WORK, not `ls`
        root = make_root(Path(tmp) / "nofocus", focus_file=False)
        rc, out = run(root, "ls -la")
        rows.append(("safe cmd with NO focus file", "regress", rc == 0, out))
    with tempfile.TemporaryDirectory() as tmp:
        # focus set, safe command, no drift target -> plain allow
        root = make_root(Path(tmp) / "plain")
        rc, out = run(root, "git status --short")
        rows.append(("safe cmd with focus, no target", "regress", rc == 0, out))
    return rows


def deadlock_rows():
    """T-390's deadlock must stay fixed. This fix sits directly on top of it.

    With focus NULL, the capture verbs are how an agent RECORDS anything — gating them on
    an active task is the deadlock T-390 removed. The deferral moves their exit later, so
    each one has to be re-proven, not assumed: `fw note`, `fw context add-*`, `fw handover`.
    Plus `fw doctor` as an over-correction control — a safe verb carrying no task id at all
    must never consult focus."""
    rows = []
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "nullfocus"
        (root / ".context" / "working").mkdir(parents=True)
        (root / ".context" / "working" / "focus.yaml").write_text(
            "current_task: null\npriorities: []\n")
        (root / ".framework.yaml").write_text("name: probe\n")
        for cmd in ('fw note "captured under null focus"',
                    'fw context add-learning "x"',
                    "fw handover",
                    "fw doctor",
                    "git status --short"):
            rc, out = run(root, cmd)
            rows.append((cmd, rc == 0, out))
    return rows


def report(rows):
    ok = True
    for label, kind, expect, saw, good, rc in rows:
        ok = ok and good
        print(f"  [{'PASS' if good else 'FAIL'}] {label:26s} ({kind:7s}) "
              f"expected {'drift' if expect else 'no drift':8s} "
              f"got {'drift' if saw else 'no drift':8s} exit={rc}")
    return ok


def main():
    print("T-392 — drift gate reachability past the safe-command fast path\n" + "=" * 76)
    with tempfile.TemporaryDirectory() as tmp:
        root = make_root(Path(tmp) / "proj")
        rows = evaluate(root)
        ok = report(rows)

        print("\nregression controls (the deferral must not add a task precondition)")
        reg_ok = True
        for label, kind, good, out in regression_rows():
            reg_ok = reg_ok and good
            print(f"  [{'PASS' if good else 'FAIL'}] {label:34s} exit 0 expected"
                  + ("" if good else f" — GOT BLOCK: {out.strip().splitlines()[:1]}"))

        print("\nT-390 deadlock controls (focus NULL — capture verbs must stay allowed)")
        dead_ok = True
        for cmd, good, out in deadlock_rows():
            dead_ok = dead_ok and good
            print(f"  [{'PASS' if good else 'FAIL'}] {cmd:44s} allowed under null focus"
                  + ("" if good else f" — BLOCKED: {out.strip().splitlines()[:1]}"))

        print("\npoison arm (restores the file, sha256-verified)")
        before = hashlib.sha256(HOOK.read_bytes()).hexdigest()
        src = HOOK.read_text()
        needle = "        _deferred_safe_exit=1"
        if needle not in src:
            print("  [SKIP] deferral absent — arm would probe UNPOISONED code")
            arm_ok = False
        else:
            # Restore the original immediate exit: pattern 2 must go dark again.
            HOOK.write_text(src.replace(needle, "        exit 0", 1))
            try:
                poisoned = evaluate(root)
            finally:
                HOOK.write_text(src)
            restored = hashlib.sha256(HOOK.read_bytes()).hexdigest() == before
            red = {l.split()[1] for l, k, e, s, good, rc in poisoned if not good and k == "fix"}
            arm_ok = ({"bare", "bin", "mandated", "absolute"} <= red) and restored
            print(f"  [{'PROVEN' if arm_ok else 'NOT PROVEN'}] restore the immediate exit 0: "
                  f"reddened {sorted(red) or 'NOTHING'}; "
                  f"restored={'yes' if restored else 'NO — TREE LEFT DIRTY'}")

    print("=" * 76)
    verdict = "PASS" if ok and reg_ok and dead_ok and arm_ok else "FAIL"
    print(f"{verdict} — {sum(1 for r in rows if r[4])}/{len(rows)} matrix legs; "
          f"regression controls {'ok' if reg_ok else 'FAILED'}; "
          f"T-390 deadlock {'ok' if dead_ok else 'FAILED'}; "
          f"arm {'proven failable' if arm_ok else 'NOT proven'}")
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
