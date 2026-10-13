#!/usr/bin/env python3
"""T-1145 — the decision-handover guard blocks an unready decision link, and only that.

Drives tools/hooks/guard-decision-handover.py as Claude Code does (JSON on stdin) against a SANDBOX
task tree with two fixture inceptions — one with an undisposed open question (unready), one fully
disposed (ready) — and the live framework library. Never the live .tasks/: their readiness moves.

Legs: unready link blocks naming task + blocker; ready link passes; no link passes; a link from an
EARLIER turn is not this reply's; unreadable transcript fails open, audibly; stop_hook_active lets a
second attempt through, audibly; last_assistant_message is preferred when present.
Teeth: a copy of the hook whose readiness call is replaced by `true` must let the unready link
through — so the block in leg 1 comes from the predicate, not from the link match alone.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK = os.path.join(ROOT, "tools", "hooks", "guard-decision-handover.py")
FRAMEWORK = os.path.join(ROOT, ".agentic-framework")

FIXTURE = """---
id: {tid}
name: "t1145 fixture"
description: >
  fixture
status: started-work
workflow_type: inception
owner: agent
horizon: now
created: 2026-10-13T00:00:00Z
last_update: 2026-10-13T00:00:00Z
---

## Problem Statement

Fixture.

## Open Questions

- **IW-1: Is this fixture ready?**
  confidence: 2
{disposition}  rationale: fixture rationale

## Recommendation

**Recommendation:** DEFER
**Rationale:** fixture, evidence gap by construction
**Evidence:**
- none

## Updates
"""

PASS = FAIL = 0


def check(ok, what):
    global PASS, FAIL
    if ok:
        PASS += 1
        print("  PASS  " + what)
    else:
        FAIL += 1
        print("  FAIL  " + what)


def transcript(tmp, name, turns):
    """turns: list of (role, text). A 'user' turn is a typed prompt."""
    path = os.path.join(tmp, name)
    with open(path, "w", encoding="utf-8") as fh:
        for role, text in turns:
            if role == "user":
                fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": text}}) + "\n")
            elif role == "tool":
                fh.write(json.dumps({"type": "user", "message": {"role": "user", "content": [
                    {"type": "tool_result", "tool_use_id": "x", "content": text}]}}) + "\n")
            else:
                fh.write(json.dumps({"type": "assistant", "message": {"role": "assistant", "content": [
                    {"type": "text", "text": text}]}}) + "\n")
    return path


def run(hook, sandbox, payload):
    env = dict(os.environ, PROJECT_ROOT=sandbox, CLAUDE_PROJECT_DIR=sandbox, FRAMEWORK_ROOT=FRAMEWORK)
    res = subprocess.run([sys.executable, hook], input=json.dumps(payload), env=env,
                         capture_output=True, text=True, timeout=60)
    block = None
    if res.stdout.strip():
        try:
            block = json.loads(res.stdout)
        except ValueError:
            block = {"unparsable": res.stdout}
    return res.returncode, block, res.stderr


def main():
    tmp = tempfile.mkdtemp(prefix="t1145-")
    try:
        sandbox = os.path.join(tmp, "proj")
        os.makedirs(os.path.join(sandbox, ".tasks", "active"))
        with open(os.path.join(sandbox, ".tasks", "active", "T-9101-unready.md"), "w") as fh:
            fh.write(FIXTURE.format(tid="T-9101", disposition=""))
        with open(os.path.join(sandbox, ".tasks", "active", "T-9102-ready.md"), "w") as fh:
            fh.write(FIXTURE.format(tid="T-9102", disposition="  disposition: deferred\n"))
        url = "http://192.0.2.1:3013"

        print("=== T-1145 decision-handover guard ===")
        t = transcript(tmp, "unready.jsonl", [("user", "status?"), ("tool", "ok"),
                                              ("assistant", "Decide here: %s/inception/T-9101" % url)])
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t, "stop_hook_active": False})
        check(rc == 0 and block and block.get("decision") == "block"
              and "T-9101" in block.get("reason", "") and "IW-1" in block.get("reason", ""),
              "unready inception link: stop blocked, reason names T-9101 and IW-1")

        t = transcript(tmp, "ready.jsonl", [("user", "go"), ("assistant", "Decide: %s/inception/T-9102" % url)])
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t})
        check(rc == 0 and block is None, "ready inception link: passes")

        t = transcript(tmp, "review.jsonl", [("user", "go"), ("assistant", "Review: %s/review/T-9101" % url)])
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t})
        check(block is not None and block.get("decision") == "block", "/review/ link to an unready inception: blocked too")

        t = transcript(tmp, "none.jsonl", [("user", "go"), ("assistant", "All committed, nothing to decide.")])
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t})
        check(rc == 0 and block is None, "no decision link: passes")

        t = transcript(tmp, "earlier.jsonl", [("user", "a"), ("assistant", "%s/inception/T-9101" % url),
                                              ("user", "b"), ("assistant", "Done, nothing to decide.")])
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t})
        check(block is None, "a link in an EARLIER turn is not this reply's: passes")

        t = transcript(tmp, "unknown.jsonl", [("user", "a"), ("assistant", "%s/inception/T-9999" % url)])
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t})
        check(block is None, "link to a task not in .tasks/active: passes")

        rc, block, err = run(HOOK, sandbox, {"transcript_path": os.path.join(tmp, "missing.jsonl")})
        check(rc == 0 and block is None and "NOT CHECKED" in err, "unreadable transcript: fails open, says NOT CHECKED")

        t = os.path.join(tmp, "unready.jsonl")
        rc, block, err = run(HOOK, sandbox, {"transcript_path": t, "stop_hook_active": True})
        check(rc == 0 and block is None and "T-9101" in err,
              "stop_hook_active: second attempt let through, warning names T-9101 (no loop)")

        rc, block, err = run(HOOK, sandbox, {"transcript_path": os.path.join(tmp, "none.jsonl"),
                                             "last_assistant_message": "%s/inception/T-9101" % url})
        check(block is not None and block.get("decision") == "block",
              "last_assistant_message is read when the payload carries it")

        print("--- teeth: the readiness call replaced by `true` must let the unready link through")
        src = open(HOOK, encoding="utf-8").read()
        anchor = 'inception_handoff_blockers "$1"'
        if src.count(anchor) != 1:
            check(False, "teeth: anchor found %d times, expected 1 — no teeth demonstrated" % src.count(anchor))
        else:
            mutant = os.path.join(tmp, "mutant.py")
            open(mutant, "w", encoding="utf-8").write(src.replace(anchor, "true", 1))
            rc, block, err = run(mutant, sandbox, {"transcript_path": os.path.join(tmp, "unready.jsonl")})
            check(block is None, "teeth: without the predicate the unready link passes — leg 1 is load-bearing on it")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print("=== %d passed, %d failed ===" % (PASS, FAIL))
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
