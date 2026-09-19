#!/usr/bin/env python3
"""T-734 — refuse to conclude absence from a window.

Twice in one week (OBS-352, OBS-353) this project told its operator that rail
evidence was missing when it was not. Neither was a rail defect. Both were the
same reading defect: a search result set truncated by its own ``limit``, read as
though it were exhaustive.

    A search returning N hits under limit=N has said nothing about hit N+1.

The fix lives at the DEFINITION site. There is exactly one function that decides
whether a result set may be treated as complete, and every caller that wants to
claim absence goes through it. This project posted that lesson to the mesh at
agent-chat-arc @557 -- "a guard present in four copies and absent from
seventy-three is not a guard, it is a coincidence" -- and then committed the
call-site version of the error anyway.

Usage:
    from _t734_absence_guard import assert_exhaustive, TruncatedSearchError
    hits = assert_exhaustive(response, limit=12)   # raises if truncation possible

    python3 tools/_t734_absence_guard.py --self-test
"""

import sys

# Continuation-token keys seen on the termlink surface and its neighbours. A
# present, non-empty value on any of these means the server has more to give.
_CURSOR_KEYS = ("next_cursor", "cursor", "next", "next_offset", "continuation")


class TruncatedSearchError(RuntimeError):
    """The result set may be truncated, so absence cannot be concluded from it."""


def truncation_signals(result, *, limit):
    """Return the list of reasons this result set may be incomplete.

    Three independent signals, any one of which is sufficient to refuse. They are
    independent on purpose: a server may cap without saying so (count == limit),
    say so without capping (all: false), or hand back a cursor while reporting
    neither.
    """
    if not isinstance(result, dict):
        raise TypeError(f"expected a response dict, got {type(result).__name__}")

    reasons = []

    hits = result.get("hits")
    if hits is None:
        hits = result.get("rows", [])
    count = result.get("count", len(hits))

    # 1. The window was filled. The server stopped because it ran out of room,
    #    not because it ran out of matches -- and it cannot tell you which.
    if limit is not None and count >= limit:
        reasons.append(f"count={count} >= limit={limit} (window filled)")

    # 2. The server said so outright.
    if result.get("all") is False:
        reasons.append("response carries all=false (server reports partial)")

    # 3. A continuation token exists, so there is a documented next page.
    for key in _CURSOR_KEYS:
        val = result.get(key)
        if val not in (None, "", 0, False):
            reasons.append(f"response carries {key}={val!r} (more pages exist)")
            break

    return reasons


def assert_exhaustive(result, *, limit):
    """Return the hits, or raise if absence cannot safely be concluded.

    This is deliberately NOT a boolean. A caller that wants to say "X is not
    present" must pass through a raise, because the failure mode being guarded is
    precisely a caller who did not think to check.
    """
    reasons = truncation_signals(result, limit=limit)
    if reasons:
        raise TruncatedSearchError(
            "cannot conclude absence from this result set: "
            + "; ".join(reasons)
            + ". Re-query with a higher limit, page the cursor, or enumerate "
              "instead of searching."
        )
    hits = result.get("hits")
    if hits is None:
        hits = result.get("rows", [])
    return hits


# ---------------------------------------------------------------------------
# Self-test. The case table IS the test: removing a case removes a leg.
# ---------------------------------------------------------------------------

# (name, response, limit, must_raise)
CASES = [
    # --- the two real ones, as fixtures rather than paraphrases ---------------
    (
        "OBS-353 shape: 12 hits under limit 12 -- the false finding",
        {"count": 12, "hits": [{"offset": o} for o in range(534, 546)], "all": False},
        12,
        True,
    ),
    (
        "OBS-352 shape: 6 hits under limit 6, all=false",
        {"count": 6, "hits": [{"offset": o} for o in (535, 536, 540, 550, 556, 557)],
         "all": False},
        6,
        True,
    ),
    # --- the zero-hit trap: absence that LOOKS most convincing ----------------
    (
        "zero hits but all=false -- the most dangerous shape",
        {"count": 0, "hits": [], "all": False},
        10,
        True,
    ),
    (
        "zero hits, genuinely exhaustive -- must NOT raise",
        {"count": 0, "hits": [], "all": True},
        10,
        False,
    ),
    # --- each signal alone must be sufficient ---------------------------------
    (
        "signal 1 alone: window filled, no all flag, no cursor",
        {"count": 5, "hits": [1, 2, 3, 4, 5]},
        5,
        True,
    ),
    (
        "signal 2 alone: under limit but all=false",
        {"count": 2, "hits": [1, 2], "all": False},
        50,
        True,
    ),
    (
        "signal 3 alone: under limit, all=true, but a cursor is present",
        {"count": 2, "hits": [1, 2], "all": True, "next_cursor": "abc123"},
        50,
        True,
    ),
    # --- the safe cases, which must stay safe ---------------------------------
    (
        "under limit, all=true, no cursor -- safe to conclude",
        {"count": 3, "hits": [1, 2, 3], "all": True},
        50,
        False,
    ),
    (
        "under limit, no flags at all -- safe",
        {"count": 3, "hits": [1, 2, 3]},
        50,
        False,
    ),
    (
        "empty cursor value must not trip the guard",
        {"count": 1, "hits": [1], "next_cursor": None},
        50,
        False,
    ),
    (
        "rows-shaped response (thread enumeration) is handled too",
        {"count": 57, "rows": [{"root_offset": 536}]},
        None,
        False,
    ),
]


def _run_table(guard):
    """Run every case against `guard`. Returns (passed, failures)."""
    passed, failures = 0, []
    for name, response, limit, must_raise in CASES:
        try:
            guard(response, limit=limit)
            raised = False
        except TruncatedSearchError:
            raised = True
        if raised == must_raise:
            passed += 1
        else:
            failures.append(
                f"{name}: expected {'raise' if must_raise else 'no raise'}, "
                f"got {'raise' if raised else 'no raise'}"
            )
    return passed, failures


def _poison_guard(result, *, limit):
    """Poison arm, FAITHFUL to the pre-fix behaviour.

    This is what the code did before T-734: it took the hits and returned them,
    with no examination of whether the window was full. It is the whole of the
    prior behaviour, not part of it -- a partial poison (say, keeping the all=false
    check and dropping only the count check) would leave some absence cases red
    for the wrong reason and manufacture exactly the vacuous leg the arm exists to
    prevent. That is the @540 lesson, and it cost this project a day when it was
    learned the first time.
    """
    hits = result.get("hits")
    if hits is None:
        hits = result.get("rows", [])
    return hits


# Ratchet (T-734). The case table is the test, so the table itself must be
# guarded against quiet shrinkage -- otherwise deleting an inconvenient case
# leaves a smaller suite still reporting GREEN, which is the same class of defect
# this whole tool exists to prevent (a green number from a population that could
# not exercise the check). Raise these deliberately when adding cases; never lower
# them to make a run pass.
MIN_CASES = 11
MIN_REFUSING_CASES = 6


def self_test():
    print("T-734 absence guard — self-test")
    print("=" * 68)

    n_cases = len(CASES)
    n_refusing = sum(1 for c in CASES if c[3])
    table_ok = n_cases >= MIN_CASES and n_refusing >= MIN_REFUSING_CASES
    print(f"\n[table]  {n_cases} cases (floor {MIN_CASES}), "
          f"{n_refusing} refusing (floor {MIN_REFUSING_CASES}) — "
          f"{'OK' if table_ok else 'BELOW FLOOR'}")

    passed, failures = _run_table(assert_exhaustive)
    print(f"\n[live]   {passed}/{len(CASES)} cases passed")
    for f in failures:
        print(f"         FAIL: {f}")

    # The poison arm must make the refusing cases go red. If it does not, the
    # legs above are asserting nothing.
    p_passed, p_failures = _run_table(_poison_guard)
    should_refuse = sum(1 for c in CASES if c[3])
    print(f"\n[poison] {p_passed}/{len(CASES)} cases passed under the faithful poison arm")
    print(f"         {len(p_failures)} case(s) went red, of {should_refuse} that must")

    poison_discriminates = len(p_failures) == should_refuse and should_refuse > 0

    print()
    if not table_ok:
        print(f"VERDICT: RED — the case table shrank below its floor "
              f"({n_cases}/{MIN_CASES} cases, {n_refusing}/{MIN_REFUSING_CASES} refusing). "
              f"A smaller suite reporting green is the defect this tool exists to catch.")
        return 1
    if failures:
        print("VERDICT: RED — the guard does not hold.")
        return 1
    if not poison_discriminates:
        print("VERDICT: RED — the poison arm did not discriminate; these legs prove nothing.")
        return 1
    print(f"VERDICT: GREEN — {passed}/{len(CASES)} green live, "
          f"{should_refuse} red under poison. The legs are failable.")
    return 0


def assert_obs353_fixture():
    """Refuse the exact response shape that produced the false OBS-353 finding.

    Kept as executable code rather than as a line in a task file, because a
    verification leg that has to be re-typed at each call site is the call-site
    pattern this tool exists to retire.
    """
    real = {"count": 12,
            "hits": [{"offset": o} for o in range(534, 546)],
            "all": False}
    try:
        assert_exhaustive(real, limit=12)
    except TruncatedSearchError as exc:
        print(f"OBS-353 shape refused as required: {exc}")
        return 0
    print("FAIL: the guard ACCEPTED the OBS-353 shape — the false finding would recur.")
    return 1


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.exit(self_test())
    if "--assert-fixture" in sys.argv:
        sys.exit(assert_obs353_fixture())
    print(__doc__)
    print("Run with --self-test to execute the case table.")
    sys.exit(0)
