#!/usr/bin/env python3
"""_t1273-mutation-signal-guard.py — an in-place mutation script must not survive INT/TERM with its mutant.

WHY (T-1273). On 2026-10-22 the T-509 sweep's time cap TERMed _t910-lanemeta-teeth.sh. Its
`trap cleanup EXIT INT TERM` handler restored src and RETURNED; bash resumed the script, which planted the
next mutant and could no longer restore it. src stayed mutated and four later legs tested the mutant. In
Python the twin is `try/finally`: an unhandled SIGTERM ends the process without running `finally`.

WHAT IT CHECKS, on scripts under tools/ that write a real file in place and restore it:
  bash   every `trap` covering INT or TERM must exit in its own action (`exit N`, or `kill -SIG $$` after
         `trap - SIG`). A handler that only restores lets bash resume. An EXIT-only trap is safe: bash runs
         it when TERM kills the shell.
  python the script must install a SIGTERM handler (`signal.signal(signal.SIGTERM, ...)`), so the restore in
         `finally` runs.

WHICH SCRIPTS. The census in T-1273 (explicit lists below) PLUS a heuristic for new ones:
  bash   a trap on INT/TERM whose action names a shell FUNCTION that copies (`cp`) a file. Inline
         `rm -rf "$TMP"` traps only delete scratch, so they are not in-place restorers.
  python a `finally:` block that writes a file (write_text, write_bytes, copyfile, copy, open(..., "w")).
         A write in `finally` is a restore.
LIMITS. The heuristic reads text, not data flow: it does not know whether the restored path is tracked
(a script that restores a temp file is flagged too; add the T-1273 handler, it costs nothing), it misses a
restore done by sed/mv/redirect or inside a sourced helper, it ignores Node scripts (the census found no
JS in-place restorer; _t423-carrier-agreement-cdp.mjs's witness write is covered by the suite's src check),
it cannot see the window between the mutating write and the `try:` in Python, and it reads heredocs as code
(so the T-1273 teeth, whose dummies carry the old pattern on purpose, are excluded by name). The explicit lists keep
the known scripts covered whatever the heuristic misses; a listed script that is gone is a FAIL (blind).

  python3 tools/_t1273-mutation-signal-guard.py            # the working tree
  python3 tools/_t1273-mutation-signal-guard.py --at HEAD  # read every script as of a git revision
Exit 0 = every in-place script is signal-safe; 1 = at least one is not, or a listed script is missing.
"""
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# T-1273 census: scripts that write a real file in place and restore it. Bare names under tools/, NOT
# `tools/<name>` literals: the unwired-guard census (T-451) reads that literal as a caller and would count
# a listed-but-unwired script as wired.
BASH_IN_PLACE = [
    "_t910-lanemeta-teeth.sh",   # src/aef-workflow-designer.html + tools/_roundtrip-serialization-cdp.mjs
    "t404-gate-e2e.sh",          # .context/working/focus.yaml (live, untracked)
    "_t371-audit-partition-teeth.sh",  # framework hook, EXIT-only trap
    "_t890-lanemeta-guard-teeth.sh",   # src, EXIT-only trap
]
PY_IN_PLACE = [
    "_t886-writer-mutation.py",        # src/aef-workflow-designer.html
    "_t392-safelist-shadow-gate.py",   # .agentic-framework/agents/context/check-active-task.sh
    "_t607-drift-gate-reach.py",       # same hook
    "_t606-render-escaping.py",        # .agentic-framework/web/blueprints/tasks.py
]

# Scripts whose text CARRIES the unsafe pattern as a dummy (a heredoc), not as their own trap.
SELF_FIXTURES = {"tools/_t1273-" + "signal-restore-teeth.sh"}

TRAP_RE = re.compile(r"""^\s*(?:[^#\n]*;\s*)?trap\s+(?:'([^']*)'|"([^"]*)"|(\S+))\s+([A-Z0-9 ]+?)\s*(?:;|$|#)""", re.M)
SIGTERM_RE = re.compile(r"signal\.signal\(\s*signal\.SIGTERM\s*,")
FINALLY_WRITE_RE = re.compile(r"write_text\(|write_bytes\(|copyfile\(|shutil\.copy2?\(|open\([^)]*,\s*['\"][wa]")


def read(rel, at):
    if at:
        r = subprocess.run(["git", "-C", ROOT, "show", f"{at}:{rel}"], capture_output=True, text=True)
        return r.stdout if r.returncode == 0 else None
    p = os.path.join(ROOT, rel)
    return open(p, encoding="utf-8", errors="replace").read() if os.path.isfile(p) else None


def candidates(pattern, at):
    if at:
        r = subprocess.run(["git", "-C", ROOT, "ls-tree", "--name-only", at, "tools/"], capture_output=True, text=True)
        names = r.stdout.split()
        return sorted(n for n in names if re.fullmatch(pattern.replace(".", r"\.").replace("*", r"[^/]*"), n))
    return sorted(os.path.relpath(p, ROOT) for p in glob.glob(os.path.join(ROOT, pattern)))


def func_body(text, name):
    m = re.search(r"^\s*%s\s*\(\)\s*\{(.*?)^\}|^\s*%s\s*\(\)\s*\{(.*?)\}\s*$" % (re.escape(name), re.escape(name)),
                  text, re.M | re.S)
    return (m.group(1) or m.group(2) or "") if m else None


def bash_traps(text):
    """[(action, [signals])] for every trap line."""
    out = []
    for m in TRAP_RE.finditer(text):
        action = m.group(1) if m.group(1) is not None else (m.group(2) if m.group(2) is not None else m.group(3))
        out.append((action, m.group(4).split()))
    return out


def action_exits(action):
    return bool(re.search(r"\bexit\b", action) or re.search(r"\bkill\s+-(INT|TERM|HUP|s\s+\w+)\s+\$\$", action))


def bash_in_place(text):
    for action, sigs in bash_traps(text):
        if not ({"INT", "TERM"} & set(sigs)):
            continue
        first = action.strip().split()[0] if action.strip() else ""
        body = func_body(text, first) if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", first) else None
        if body is not None:
            # the handler function, or a function it calls first (cleanup -> restore), copies a file
            called = [body] + [func_body(text, w) or "" for w in re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)\b", body)]
            if any(re.search(r"(^|[;&|\s])cp\s", b) for b in called):
                return True
    return False


def bash_unsafe(text):
    return [f"trap '{a}' {' '.join(s)}" for a, s in bash_traps(text)
            if ({"INT", "TERM"} & set(s)) and not action_exits(a)]


def py_in_place(text):
    for m in re.finditer(r"^([ \t]*)finally:[ \t]*\n((?:\1[ \t]+.*\n|[ \t]*\n)+)", text, re.M):
        if FINALLY_WRITE_RE.search(m.group(2)):
            return True
    return False


def main():
    at = sys.argv[sys.argv.index("--at") + 1] if "--at" in sys.argv else None
    print(f"T-1273 mutation signal guard — {'revision ' + at if at else 'working tree'}")
    fails, checked = [], []

    bash_set = {"tools/" + r: "listed" for r in BASH_IN_PLACE}
    for rel in candidates("tools/*.sh", at):
        if rel not in bash_set and rel not in SELF_FIXTURES and bash_in_place(read(rel, at) or ""):
            bash_set[rel] = "heuristic"
    for rel, why in sorted(bash_set.items()):
        text = read(rel, at)
        if text is None:
            fails.append(f"{rel}: listed in the T-1273 census but not found — the guard is blind to it")
            continue
        bad = bash_unsafe(text)
        checked.append(rel)
        print(f"  [{'FAIL' if bad else 'ok  '}] bash   {rel} ({why})" + (f": {'; '.join(bad)} can return" if bad else ""))
        if bad:
            fails.append(f"{rel}: INT/TERM handler returns without exit -> bash resumes and can re-mutate")

    py_set = {"tools/" + r: "listed" for r in PY_IN_PLACE}
    for rel in candidates("tools/*.py", at):
        if rel not in py_set and rel != "tools/_t1273-mutation-signal-guard.py" and py_in_place(read(rel, at) or ""):
            py_set[rel] = "heuristic"
    for rel, why in sorted(py_set.items()):
        text = read(rel, at)
        if text is None:
            fails.append(f"{rel}: listed in the T-1273 census but not found — the guard is blind to it")
            continue
        ok = bool(SIGTERM_RE.search(text))
        checked.append(rel)
        print(f"  [{'ok  ' if ok else 'FAIL'}] python {rel} ({why})" + ("" if ok else ": restores in finally, no SIGTERM handler"))
        if not ok:
            fails.append(f"{rel}: restore in `finally` without a SIGTERM handler -> TERM leaves the mutant")

    print(f"checked {len(checked)} in-place scripts ({len(bash_set)} bash, {len(py_set)} python); {len(fails)} unsafe")
    for f in fails:
        print("  FAIL " + f)
    print("RESULT: " + ("FAIL" if fails else "PASS"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
