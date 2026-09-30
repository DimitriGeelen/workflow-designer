#!/usr/bin/env python3
"""
T-941: both-directions proof for the arc-2 boundary inventory's unclassified-route check.

Why this exists
---------------
`tools/_t682-boundary-inventory.py` derives the route set from `gallery-serve.py`'s own
dispatch by AST, then requires every derived route to carry a hand-authored
`ROUTE_SEMANTICS` row. A route with no row is reported UNCLASSIFIED and the check exits
non-zero — deliberately, so a new route cannot silently inherit a neighbour's fence.

That design worked: it flagged `GET /api/instances` from the day T-884 shipped it. It also
went unread for three weeks, and the fix for it was *adding a row to the table*. Adding rows
is precisely the edit that could quietly turn this detector into a rubber stamp — widen a
default, wrap the lookup in a `.get()` that invents a benign row, relax the comparison — and
every such change leaves the check exiting 0 while asserting nothing. A green check and a
blind check are indistinguishable from the outside, which is the whole failure class here.

So the negative leg comes FIRST and is the point of the file: prove the check still BITES.
The positive leg alone would pass just as happily against a predicate that always says yes.

Run (exits 0 on pass, non-zero on failure):
    python3 tests/test_boundary_inventory_unclassified.py
"""
import importlib.util
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOL = ROOT / "tools" / "_t682-boundary-inventory.py"

# A route name no dispatch would ever contain, so a future real route cannot collide with the
# fixture and turn the negative leg green by accident.
FAKE = "/api/t941-deliberately-unclassified"


def _load():
    """Import the tool by path — its filename has hyphens, so it is not a normal module name.

    Safe to import: the tool guards its entry point with `if __name__ == '__main__'`, so
    exec_module defines the table and helpers without running the check or writing the report.
    """
    if not TOOL.exists():
        raise SystemExit(f"FAIL: tool not found at {TOOL}")
    spec = importlib.util.spec_from_file_location("t682_boundary_inventory", TOOL)
    if spec is None or spec.loader is None:
        raise SystemExit(f"FAIL: could not build an import spec for {TOOL}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    mod = _load()
    failures = []

    # ---- NEGATIVE LEG (first): an unclassified route must still be detected -------------
    # Feed the deriver a synthetic dispatch carrying one route that has no semantics row.
    # This exercises the real derive_routes() and the real ROUTE_SEMANTICS membership test,
    # not a reimplementation of either.
    synthetic = (
        "def _api_get(self):\n"
        f"    if route == '{FAKE}':\n"
        "        return self._json(200, {})\n"
    )
    derived = mod.derive_routes(synthetic)
    if ("GET", FAKE) not in derived:
        failures.append(
            f"derive_routes() did not find the synthetic route {FAKE} — the AST deriver no "
            f"longer sees GET literals in _api_get, so the whole check is blind upstream of "
            f"the semantics table (got: {sorted(derived)})"
        )
    else:
        unclassified = {r for r in derived if r not in mod.ROUTE_SEMANTICS}
        if ("GET", FAKE) not in unclassified:
            failures.append(
                f"({'GET'!r}, {FAKE!r}) is in ROUTE_SEMANTICS or the membership test stopped "
                f"discriminating — an unrowed route now passes as classified, which is the "
                f"rubber-stamp failure this test exists to catch"
            )

    # ---- POSITIVE LEG: the real route set must be fully classified ----------------------
    # Guards against the opposite error: a check so strict it fires on the committed state.
    src = (ROOT / "tools" / "gallery-serve.py").read_text(encoding="utf-8")
    real = mod.derive_routes(src)
    if not real:
        failures.append(
            "derive_routes() returned NOTHING for the real server — an empty denominator "
            "reads as 'all classified' while asserting nothing (T-3105)"
        )
    missing = sorted(r for r in real if r not in mod.ROUTE_SEMANTICS)
    if missing:
        failures.append(
            "routes in the server with no ROUTE_SEMANTICS row: "
            + ", ".join(f"{m} {p}" for m, p in missing)
        )

    if failures:
        print(f"FAIL: boundary-inventory unclassified check — {len(failures)} issue(s):",
              file=sys.stderr)
        for f in failures:
            print("  - " + f, file=sys.stderr)
        return 1

    print(f"PASS: unclassified-route check bites (synthetic {FAKE} detected) "
          f"and the real {len(real)} route(s) are all classified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
