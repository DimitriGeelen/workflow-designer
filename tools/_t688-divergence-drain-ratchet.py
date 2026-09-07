#!/usr/bin/env python3
"""T-688 — drain metric for the vendor-divergence register.

WHY THIS EXISTS
---------------
`.agentic-framework/.vendor-divergence.yaml` declares every path where our
vendored framework diverges from upstream. Measured 2026-09-07: 62 entries, of
which **46 carry `upstream: fix`** — a repair that belongs upstream.

The schema's complete field list was: kind, path, reason, task, upstream,
superseded_by, superseded_changes. **There is no terminal state.** Forty-six
fixes were marked as belonging upstream and the register could not express
whether a single one ever got there. It is not an empty queue; it is an
unmeasurable one, and it passes `[PASS] Vendor divergence: all N diverged
path(s) declared` every single day.

    PL-321: a queue with no terminal state is a landfill with an audit line.

This is the third register in one session with that defect, after `fw promote`
(319 learnings, 41 ready, 0 promoted) and the loop detector (G-050). The other
two at least *report* their zero. This one could not.

WHAT IT ASSERTS
---------------
A ratchet, in the T-560 bare-number idiom: the count of `upstream: fix` entries
with no terminal state may not RISE above the baseline. Divergences may not be
added faster than they are drained. It does not demand the queue empty — it
demands it stop growing, which is the weakest claim that is still a claim.

TERMINAL STATES
---------------
An entry is drained when it carries `delivered:` with one of:

  reported   — patch/report sent upstream. Transport evidence only.
  accepted   — upstream took it. `upstream_ref:` should name their commit/PR.
  rejected   — upstream declined. Closed, and the divergence is now deliberate.
  superseded — upstream changed underneath us; our fix is moot.

`reported` is deliberately NOT `accepted`. Per the collaboration rule: a
TermLink post or file transfer alone is transport evidence, not collaboration
completion. A register that treats "I sent it" as "it landed" is how you get a
second landfill inside the first one.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parent.parent
REGISTER = REPO / ".agentic-framework" / ".vendor-divergence.yaml"
BASELINE = Path(__file__).resolve().parent / "_t688-divergence-drain-baseline.txt"

TERMINAL = {"reported", "accepted", "rejected", "superseded"}
RED, GREEN = 1, 0


def undrained(entries: list[dict]) -> list[dict]:
    """Entries marked as belonging upstream that carry no terminal state."""
    out = []
    for e in entries:
        if e.get("upstream") != "fix":
            continue
        if str(e.get("delivered", "")).strip() in TERMINAL:
            continue
        out.append(e)
    return out


def load_entries(path: Path) -> list[dict]:
    data = yaml.safe_load(path.read_text()) or {}
    return [e for e in (data.get("entries") or []) if isinstance(e, dict)]


def verdict(count: int, baseline: int) -> tuple[int, str]:
    if count > baseline:
        return RED, (
            f"DRAIN RATCHET BROKEN: {count} undrained upstream fixes, baseline {baseline}. "
            f"{count - baseline} divergence(s) were added without any being delivered. "
            f"Mark deliveries with `delivered: reported|accepted|rejected|superseded`, "
            f"or lower the baseline when the queue genuinely drains."
        )
    if count < baseline:
        return GREEN, (
            f"{count} undrained upstream fixes, below baseline {baseline} — the queue drained. "
            f"Lower the baseline to {count} to lock the gain in."
        )
    return GREEN, f"{count} undrained upstream fixes, holding at baseline {baseline}"


def self_test() -> int:
    """Both verdicts must be reachable, and `delivered:` must actually drop an entry."""
    failures = []

    base = [
        {"path": "a", "upstream": "fix"},
        {"path": "b", "upstream": "fix"},
        {"path": "c", "upstream": "local-config"},   # never upstream — must not count
        {"path": "d", "upstream": "vendoring-repair"},
    ]

    if len(undrained(base)) != 2:
        failures.append(f"non-fix entries counted (got {len(undrained(base))}, want 2)")

    drained = base + [{"path": "e", "upstream": "fix", "delivered": "accepted"}]
    if len(undrained(drained)) != 2:
        failures.append("a `delivered: accepted` entry was still counted as undrained")

    for state in sorted(TERMINAL):
        one = [{"path": "x", "upstream": "fix", "delivered": state}]
        if undrained(one):
            failures.append(f"terminal state {state!r} did not drain the entry")

    bogus = [{"path": "x", "upstream": "fix", "delivered": "soon"}]
    if not undrained(bogus):
        failures.append("an unrecognised `delivered:` value was accepted as terminal")

    if verdict(3, 2)[0] != RED:
        failures.append("growth above baseline did not go RED")
    if verdict(2, 2)[0] != GREEN:
        failures.append("holding at baseline did not go GREEN")
    if verdict(1, 2)[0] != GREEN:
        failures.append("draining below baseline did not go GREEN")

    if failures:
        for f in failures:
            print(f"SELF-TEST FAIL: {f}", file=sys.stderr)
        return 1
    print("self-test OK — RED and GREEN reachable; terminal states drain, bogus ones do not")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--seed", action="store_true",
                    help="write the baseline from the measured value (refuses to overwrite)")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    count = len(undrained(load_entries(REGISTER)))

    if args.seed:
        if BASELINE.exists():
            print(f"REFUSED: baseline already exists ({BASELINE.read_text().strip()}). "
                  f"A ratchet that can be re-seeded is not a ratchet.", file=sys.stderr)
            return 1
        BASELINE.write_text(f"{count}\n")
        print(f"baseline seeded at measured value {count}")
        return 0

    if not BASELINE.exists():
        print(f"no baseline — run with --seed (measured: {count})", file=sys.stderr)
        return 1

    baseline = int(BASELINE.read_text().strip())
    code, msg = verdict(count, baseline)
    print(f"[{'RED' if code else 'OK'}] {msg}")
    return code


if __name__ == "__main__":
    sys.exit(main())
