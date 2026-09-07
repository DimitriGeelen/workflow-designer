#!/usr/bin/env python3
"""T-687 — function check for stdin-consuming PostToolUse hooks.

WHY THIS EXISTS
---------------
loop-detect was registered on every PostToolUse call and fired 400 times in one
session while recording nothing. Every health surface reported it healthy,
because the only signal was `.hook-counter`, and a fire counter measures
INVOCATION, NOT FUNCTION (PL-320). The hook was starved of its stdin payload by
checkpoint.sh:278 (`HOOK_INPUT=$(cat ...)`) running ahead of it on the same
event — see G-050.

The failure class is PL-306 ("being wired is not being watched") and PL-317
("a control that cannot go red for its own reasons"). This check closes it by
asserting the thing the counter cannot: that the hook's STATE MOVED.

WHAT IT ASSERTS
---------------
Between two runs, if the fire counter advanced by at least THRESHOLD and the
newest entry in the state file did NOT advance, the hook is firing without
functioning -> RED.

Entry COUNT is deliberately not the signal: loop-detect trims history to 30, so
a healthy long-running session sits at 30 forever and a count-based check would
read saturation as starvation. The newest entry's TIMESTAMP is monotonic and
does not saturate.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
WORKING = REPO / ".context" / "working"
COUNTER = WORKING / ".hook-counter"
STATE = WORKING / ".loop-detect.json"
BASELINE = WORKING / ".t687-function-baseline.json"

HOOK = "loop-detect"
THRESHOLD = 20  # fires that must elapse before absence of movement is meaningful

RED, GREEN, GREY = 2, 0, 0  # GREY (no baseline yet) is not a failure


def read_fires(counter_path: Path, hook: str = HOOK) -> int:
    """Last occurrence wins — .hook-counter is append-ish and repeats keys."""
    try:
        text = counter_path.read_text()
    except OSError:
        return -1
    hits = re.findall(rf"^{re.escape(hook)}=(\d+)$", text, re.M)
    return int(hits[-1]) if hits else -1


def read_newest_ts(state_path: Path) -> int:
    """Newest entry timestamp, or -1 if unreadable/empty. Does not saturate."""
    try:
        history = json.loads(state_path.read_text()).get("history", [])
    except (OSError, ValueError, AttributeError):
        return -1
    stamps = [e.get("timestamp", 0) for e in history if isinstance(e, dict)]
    return max(stamps) if stamps else -1


def verdict(prev: dict | None, fires: int, newest_ts: int,
            threshold: int = THRESHOLD) -> tuple[int, str]:
    """Pure decision function — the part the self-test exercises."""
    if fires < 0:
        return GREY, f"no fire counter for {HOOK}: nothing to check yet"
    if prev is None:
        return GREY, f"baseline recorded (fires={fires}) — re-run to compare"

    elapsed = fires - int(prev.get("fires", 0))
    moved = newest_ts > int(prev.get("newest_ts", -1))

    if elapsed < threshold:
        return GREEN, f"only {elapsed} fires since baseline (< {threshold}) — inconclusive, holding"
    if moved:
        return GREEN, f"{elapsed} fires and the state advanced — hook is functioning"
    return RED, (
        f"STARVED: {HOOK} fired {elapsed} times since baseline and its state file "
        f"did NOT advance (newest entry still {newest_ts}). The hook is being "
        f"invoked and is doing nothing. See G-050."
    )


def self_test() -> int:
    """Both verdicts must be reachable. A control with one reachable outcome is not a control."""
    failures = []
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)

        # --- RED must be reachable: fires advance, state frozen ---
        (tmp / "counter").write_text("error-watchdog=5\nloop-detect=400\n")
        (tmp / "state").write_text(json.dumps(
            {"history": [{"toolName": "unknown", "timestamp": 1000}]}))
        code, msg = verdict({"fires": 300, "newest_ts": 1000},
                            read_fires(tmp / "counter"), read_newest_ts(tmp / "state"))
        if code != RED:
            failures.append(f"starvation did not go RED (got {code}: {msg})")

        # --- GREEN must be reachable: fires advance, state advances too ---
        (tmp / "state2").write_text(json.dumps(
            {"history": [{"toolName": "Bash", "timestamp": 9999}]}))
        code, msg = verdict({"fires": 300, "newest_ts": 1000},
                            read_fires(tmp / "counter"), read_newest_ts(tmp / "state2"))
        if code != GREEN:
            failures.append(f"healthy state did not go GREEN (got {code}: {msg})")

        # --- Saturation must NOT read as starvation: 30 entries, newest moved ---
        (tmp / "state3").write_text(json.dumps(
            {"history": [{"toolName": "Bash", "timestamp": 1000 + i} for i in range(30)]}))
        code, _ = verdict({"fires": 300, "newest_ts": 1005},
                          read_fires(tmp / "counter"), read_newest_ts(tmp / "state3"))
        if code != GREEN:
            failures.append("trimmed-but-live history misread as starvation")

        # --- A missing counter must be GREY, never a false green or false red ---
        code, _ = verdict(None, -1, -1)
        if code != GREY:
            failures.append("absent counter did not degrade to GREY")

    if failures:
        for f in failures:
            print(f"SELF-TEST FAIL: {f}", file=sys.stderr)
        return 1
    print("self-test OK — RED, GREEN and GREY are all reachable")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test", action="store_true",
                    help="prove both verdicts are reachable, then exit")
    ap.add_argument("--no-update", action="store_true",
                    help="do not rewrite the baseline (for repeatable demonstration)")
    ap.add_argument("--threshold", type=int, default=THRESHOLD)
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    fires = read_fires(COUNTER)
    newest_ts = read_newest_ts(STATE)
    try:
        prev = json.loads(BASELINE.read_text())
    except (OSError, ValueError):
        prev = None

    code, msg = verdict(prev, fires, newest_ts, args.threshold)
    label = {RED: "RED", GREEN: "OK"}.get(code, "OK")
    print(f"[{label}] {msg}")

    if not args.no_update and fires >= 0:
        BASELINE.parent.mkdir(parents=True, exist_ok=True)
        BASELINE.write_text(json.dumps({"fires": fires, "newest_ts": newest_ts}))
    return code


if __name__ == "__main__":
    sys.exit(main())
