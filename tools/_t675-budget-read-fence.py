#!/usr/bin/env python3
"""T-675: drive every arm of the budget safe-read, and the gate's fail-open, against
throwaway roots.

PL-308: a guard that has only ever been green is a hand-maintained claim. Every case
below is a state that USED TO READ AS `level: ok` — the whole defect is that a reader
could not tell these apart from a measured healthy session, so a fence that only
checked the happy path would restate the bug rather than catch it.

Two subjects:

  checkpoint.sh budget    must REFUSE (exit 3) an unmeasured, stale, foreign-session,
                          scan-failed, or absent cache, and ACCEPT (exit 0) a genuine
                          fresh measured one. The accept arm matters as much as the
                          refusals: a reader that refuses everything is ignored, and
                          an ignored check is worse than no check.

  budget-gate.sh          must still EXIT 0 when its scan fails (fail open — a broken
                          scan must never block every tool call) AND must write
                          `measured: false` while doing so. Those two properties are
                          in tension by design; asserting the exit code without the
                          stamp would pass on the original bug.

Nothing here touches the real .context/ — every case runs under CONTEXT_DIR pointed at
a fresh temp dir. Append-only ledgers are not test fixtures.

Exit 0 all arms behaved, 1 any arm did not.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECKPOINT = os.path.join(REPO, ".agentic-framework", "agents", "context", "checkpoint.sh")
GATE = os.path.join(REPO, ".agentic-framework", "agents", "context", "budget-gate.sh")
SESSION = "S-2026-0903-TEST"

NOW = int(time.time())

# (label, cache dict or None, expect_refused)
CASES = [
    ("unmeasured seed (post-compact-resume)",
     {"level": "ok", "tokens": 0, "timestamp": NOW,
      "source": "post-compact-resume", "measured": False, "session_id": SESSION},
     True),
    ("unmeasured fail-open (budget-gate scan failure)",
     {"level": "unknown", "tokens": 0, "timestamp": NOW,
      "source": "budget-gate", "measured": False, "session_id": SESSION},
     True),
    # A pre-T-675 file has no `measured` key at all. Absence must degrade safely
    # rather than trust every legacy cache: tokens==0 is exactly what both
    # unmeasured writers emit, so it is inferred unmeasured.
    ("legacy shape, no measured key, tokens 0",
     {"level": "ok", "tokens": 0, "timestamp": NOW, "source": "budget-gate"},
     True),
    ("stale — a previous session left it behind",
     {"level": "ok", "tokens": 91000, "timestamp": NOW - 7200,
      "source": "budget-gate", "measured": True, "session_id": SESSION},
     True),
    ("foreign session",
     {"level": "ok", "tokens": 91000, "timestamp": NOW,
      "source": "budget-gate", "measured": True, "session_id": "S-2000-0101-0000"},
     True),
    ("absent cache", None, True),
    # GREEN. Everything the refusals lack.
    ("fresh, measured, this session",
     {"level": "warn", "tokens": 231000, "timestamp": NOW,
      "source": "budget-gate", "measured": True, "session_id": SESSION},
     False),
]


def make_root(tmp, cache):
    """A throwaway CONTEXT_DIR with just the two files the reader consults."""
    ctx = os.path.join(tmp, ".context")
    os.makedirs(os.path.join(ctx, "working"), exist_ok=True)
    with open(os.path.join(ctx, "working", "session.yaml"), "w") as fh:
        fh.write("session_id: %s\n" % SESSION)
    p = os.path.join(ctx, "working", ".budget-status")
    if cache is None:
        if os.path.exists(p):
            os.remove(p)
    else:
        with open(p, "w") as fh:
            json.dump(cache, fh)
    return ctx


def run(argv, ctx, stdin=""):
    env = dict(os.environ, CONTEXT_DIR=ctx)
    env.pop("_FW_PATHS_DERIVED_BY", None)
    return subprocess.run(argv, env=env, input=stdin,
                          capture_output=True, text=True)


def check_reader():
    failures = []
    for label, cache, expect_refused in CASES:
        tmp = tempfile.mkdtemp(prefix="t675-")
        try:
            ctx = make_root(tmp, cache)
            r = run(["bash", CHECKPOINT, "budget"], ctx)
            refused = r.returncode == 3
            ok = refused == expect_refused
            # A refusal must SAY WHY. "unknown" with no reason is just a different
            # way to be unhelpful, and would leave the reader guessing.
            if refused and "reason:" not in r.stdout:
                ok, label = False, label + " [refused without a reason]"
            # The accept arm must carry the real level through, not flatten it to ok.
            if not expect_refused and "level: warn" not in r.stdout:
                ok, label = False, label + " [did not report the cached level]"
            want = "REFUSE" if expect_refused else "ACCEPT"
            print("%-6s %-52s want=%s rc=%d" %
                  ("PASS" if ok else "FAIL", label, want, r.returncode))
            if not ok:
                failures.append(label)
                sys.stdout.write("".join("        | %s\n" % ln
                                         for ln in r.stdout.splitlines()[:4]))
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    return failures


def check_gate_fail_open():
    """A failed scan must exit 0 AND record that nobody measured it.

    The exit code alone is not enough: exit 0 with `{level: ok, tokens: 0}` IS the
    original defect. Both halves, or this arm is decorative.
    """
    failures = []
    tmp = tempfile.mkdtemp(prefix="t675-gate-")
    try:
        ctx = make_root(tmp, None)
        # An EMPTY transcript: present (so the path resolves and no reconstruction
        # fallback reaches the real session log) but carrying no usage entries, which
        # is exactly the scan failure this fences.
        empty = os.path.join(tmp, "empty.jsonl")
        open(empty, "w").close()
        stdin = json.dumps({"tool_name": "Bash",
                            "tool_input": {"command": "ls"},
                            "transcript_path": empty})
        r = run(["bash", GATE], ctx, stdin=stdin)

        if r.returncode != 0:
            failures.append("gate did not fail open (rc=%d)" % r.returncode)
        print("%-6s gate fails OPEN on a failed scan (rc=%d)" %
              ("PASS" if r.returncode == 0 else "FAIL", r.returncode))

        p = os.path.join(ctx, "working", ".budget-status")
        written = {}
        if os.path.exists(p):
            try:
                written = json.load(open(p))
            except Exception:
                pass
        stamped = written.get("measured") is False and written.get("level") == "unknown"
        print("%-6s ... and records it as UNMEASURED (%s)" %
              ("PASS" if stamped else "FAIL",
               json.dumps({k: written.get(k) for k in ("level", "tokens", "measured")})))
        if not stamped:
            failures.append("failed scan was not stamped unmeasured")

        # And the safe reader must then refuse what the gate just wrote.
        r2 = run(["bash", CHECKPOINT, "budget"], ctx)
        print("%-6s ... and the safe read refuses it (rc=%d)" %
              ("PASS" if r2.returncode == 3 else "FAIL", r2.returncode))
        if r2.returncode != 3:
            failures.append("safe read accepted the gate's unmeasured write")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return failures


def main():
    print("T-675 budget safe-read fence\n")
    print("-- checkpoint.sh budget " + "-" * 44)
    failures = check_reader()
    print("\n-- budget-gate.sh fail-open " + "-" * 40)
    failures += check_gate_fail_open()

    if failures:
        print("\nFENCE FAILED — %d arm(s) did not behave: %s"
              % (len(failures), "; ".join(failures)))
        return 1
    print("\nFENCE PASSED — every unmeasured/stale/foreign cache is refused with a"
          "\nreason, a genuine one is accepted with its real level, and the gate still"
          "\nfails open while recording that nobody measured it.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
