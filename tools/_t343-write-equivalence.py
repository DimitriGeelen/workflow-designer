#!/usr/bin/env python3
"""T-343: prove the discarded-edge collector is REPORTING-ONLY.

The obvious form of this check — diff the card tree against the pre-change build
from git — goes vacuous the moment the change is committed, because `HEAD` then
IS the changed build and the tool compares a thing to itself. It is also vacuous
in the stock registry, where enrich writes nothing at all: the trees match
because both are empty, and they would match just as well if edge-writing were
broken outright. Both failures look exactly like a pass.

So this asserts the property directly and permanently instead:

    compute_forward_edges(..., discarded=None)   # the pre-T-343 call, verbatim
    compute_forward_edges(..., discarded=[])     # the T-343 call

must return IDENTICAL forward-edge structures. `apply_edges` writes purely from
that structure, so identical structures mean identical writes.

Two conditions make it discriminating rather than decorative:
  1. the compared structure must be NON-EMPTY (otherwise it is the empty-tree
     trap above) — enforced, and the run fails loudly if it cannot be filled;
  2. the collector must actually have collected something on the same run —
     otherwise "no side effect" is being asserted about a code path that did
     not execute.

Exit 0 on equivalence, non-zero with a named reason otherwise.
"""
import importlib.util
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENRICH = os.path.join(REPO, ".agentic-framework", "agents", "fabric", "lib", "enrich.py")
COMPONENTS = os.path.join(REPO, ".fabric", "components")
TEMP_CARD = os.path.join(COMPONENTS, "_t343-write-equivalence-temp.yaml")

# A target that IS referenced by existing cards but has no card of its own, so
# registering it makes forward edges appear. Chosen by name, verified non-empty
# below rather than assumed.
VICTIM = "tools/validate-workflow.py"

CARD = f"""id: {VICTIM}
name: t343-write-equivalence-temp
type: script
subsystem: unknown
location: {VICTIM}
tags: []

purpose: "T-343 write-equivalence probe — transient, removed by this script"

depends_on:
  []

depended_by:
  []

last_verified: 2026-08-02
created_by: t343-write-equivalence
"""


def load_enrich():
    os.environ["PROJECT_ROOT"] = REPO
    spec = importlib.util.spec_from_file_location("enrich_t343", ENRICH)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def normalise(forward):
    """Order-insensitive, comparable form of the forward-edge structure."""
    return {
        path: sorted((e.get("target", ""), e.get("type", "")) for e in edges)
        for path, edges in forward.items()
    }


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def main():
    enrich = load_enrich()

    created = False
    try:
        if not os.path.exists(TEMP_CARD):
            with open(TEMP_CARD, "w") as f:
                f.write(CARD)
            created = True

        cards, loc_to_id, _l2c, _i2l, _i2c = enrich.build_index(COMPONENTS)

        # pre-T-343 call shape: no collector argument at all
        before = enrich.compute_forward_edges(cards, loc_to_id, REPO)

        # T-343 call shape: collector supplied
        collected = []
        after = enrich.compute_forward_edges(cards, loc_to_id, REPO, collected)

        n_edges = sum(len(v) for v in after.values())
        if n_edges == 0:
            fail("forward-edge structure is EMPTY — this comparison would pass "
                 "over nothing and prove nothing. The victim target "
                 f"'{VICTIM}' produced no resolvable edges; pick another.")

        if not collected:
            fail("the collector gathered nothing on this run — 'the collector has "
                 "no side effect' would be asserted about a path that never ran.")

        if normalise(before) != normalise(after):
            fail("forward edges DIFFER with the collector enabled — the change is "
                 "not reporting-only.")

        print(f"PASS: forward-edge structure identical with and without the "
              f"discarded-edge collector")
        print(f"      compared over {n_edges} edge(s) across "
              f"{sum(1 for v in after.values() if v)} card(s) — non-empty, so the "
              f"comparison could have failed")
        print(f"      collector gathered {len(collected)} discarded edge(s) on the "
              f"same run — the reporting path did execute")
        return 0
    finally:
        if created and os.path.exists(TEMP_CARD):
            os.unlink(TEMP_CARD)


if __name__ == "__main__":
    sys.exit(main())
