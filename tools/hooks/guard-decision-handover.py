#!/usr/bin/env python3
"""T-1145 — Stop hook: a decision link in the agent's reply must pass the inception readiness check.

WHY. 2026-10-12 the agent handed the operator http://<watchtower>/inception/T-1094 as "ready for your
decision" while Watchtower's own page said "Not ready for your decision" (no Hypothesis, IW-1 open).
The check exists and works — `inception_handoff_blockers` (.agentic-framework/lib/inception-readiness.sh)
and `fw task review T-XXX`, which refused T-1094 — but a bare URL typed into the reply goes around it.
Same class as T-1118/T-1123. This hook closes that route: when the reply about to end the turn names
`/inception/T-XXX` or `/review/T-XXX`, each such task is run through the same predicate, and an unready
one blocks the stop so the reply is corrected before the operator acts on it.

FAILS OPEN. A guard on the agent's own reply must never wedge a session: an unreadable payload,
transcript, task or library lets the stop through and says why on stderr. It blocks only on a positive
finding, and only once per stop chain (`stop_hook_active`), so a reply that must mention the link (e.g.
explaining why a task is not ready) cannot loop.

INSTALLATION IS THE OPERATOR'S (B-005: the agent cannot write .claude/settings.json); see
tools/hooks/install-decision-handover-guard.py and runme job for T-1145. Upstream: AEF T-4135.

Seams for the test (tests/test_t1145_decision_handover_guard.py): PROJECT_ROOT / CLAUDE_PROJECT_DIR
pick the task tree, FRAMEWORK_ROOT picks the library.
"""
import json
import os
import re
import subprocess
import sys

LINK = re.compile(r"/(?:inception|review)/(T-\d+)\b")

# The one call the teeth mutate: if it stops being made, an unready inception must pass.
BLOCKERS_SH = r'''
source "$FRAMEWORK_ROOT/lib/task-audit.sh" 2>/dev/null || true
source "$FRAMEWORK_ROOT/lib/inception-readiness.sh" || exit 3
inception_handoff_blockers "$1"
'''


def warn(msg):
    sys.stderr.write("decision-handover-guard: %s\n" % msg)


def turn_text(payload):
    """All assistant text since the operator's last prompt (what the operator will read)."""
    msg = payload.get("last_assistant_message")
    if isinstance(msg, str) and msg.strip():
        return msg
    path = payload.get("transcript_path")
    if not path:
        raise ValueError("no transcript_path in the hook payload")
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().splitlines()
    texts = []
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        kind = entry.get("type")
        content = (entry.get("message") or {}).get("content")
        if kind == "user":
            # A tool result is part of the turn; a typed prompt starts it.
            if isinstance(content, str) or (isinstance(content, list) and any(
                    isinstance(b, dict) and b.get("type") == "text" for b in content)):
                break
            continue
        if kind == "assistant" and isinstance(content, list):
            for block in reversed(content):
                if isinstance(block, dict) and block.get("type") == "text":
                    texts.append(block.get("text") or "")
    return "\n".join(reversed(texts))


def task_file(root, tid):
    active = os.path.join(root, ".tasks", "active")
    try:
        names = os.listdir(active)
    except OSError:
        return None
    hit = [n for n in names if n.startswith(tid + "-") and n.endswith(".md")]
    return os.path.join(active, sorted(hit)[0]) if hit else None


def blockers(framework_root, path):
    env = dict(os.environ, FRAMEWORK_ROOT=framework_root)
    res = subprocess.run(["bash", "-c", BLOCKERS_SH, "_", path], env=env,
                         capture_output=True, text=True, timeout=30)
    if res.returncode != 0:
        raise RuntimeError("readiness check exited %d: %s" % (res.returncode, res.stderr.strip()[:200]))
    return [line.split("\t")[1] if "\t" in line else line
            for line in res.stdout.splitlines() if line.strip()]


def main():
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except ValueError as exc:
        warn("NOT CHECKED: unreadable hook payload (%s)" % exc)
        return 0
    root = os.environ.get("CLAUDE_PROJECT_DIR") or os.environ.get("PROJECT_ROOT") or \
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    framework_root = os.environ.get("FRAMEWORK_ROOT") or os.path.join(root, ".agentic-framework")

    try:
        text = turn_text(payload)
    except Exception as exc:  # fail open, audibly
        warn("NOT CHECKED: cannot read the reply (%s)" % exc)
        return 0

    found = []
    for tid in sorted(set(LINK.findall(text))):
        path = task_file(root, tid)
        if not path:
            continue  # not active (closed, or not a task here): nothing to decide
        try:
            bl = blockers(framework_root, path)
        except Exception as exc:
            warn("NOT CHECKED: %s (%s)" % (tid, exc))
            continue
        if bl:
            found.append((tid, bl))

    if not found:
        return 0
    detail = "; ".join("%s: %s" % (tid, " | ".join(bl)) for tid, bl in found)
    if payload.get("stop_hook_active"):
        warn("still names an unready decision link after one correction, letting it through: " + detail)
        return 0
    reason = ("Your reply gives the operator a decision link, but the task is NOT decision-ready — %s. "
              "Do not offer it as ready: fix the task, or tell the operator plainly that it is not ready "
              "and why. A ready link comes from `fw task review T-XXX`, which runs this same check (T-1145)."
              % detail)
    print(json.dumps({"decision": "block", "reason": reason}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
