#!/usr/bin/env python3
"""T-671: the Arc-0 Component Fabric fence, evidenced one word at a time.

Roadmap section 6 fence: "Component Fabric non-empty, enriched, validated",
required before implementation decomposition. Three words, three separate checks.

WHY NOT ONE NUMBER. "22% covered" cannot tell you which of the three is unmet, and
the arc's exit gate names all three. Worse, the aggregate MOVES THE WRONG WAY under
the obvious fix: registering 278 stub cards raises `registered` while every one of
them lands in the "cards have no edges" warning. A single figure would have shown
that as progress. These three do not.

  NON-EMPTY   every member of the Arc-0 set has a component card.
  ENRICHED    every member's card carries at least one real edge, in either
              direction, and no card carries a placeholder purpose. A card with a
              TODO purpose and no edges is a registration, not topology.
  VALIDATED   every member is inside the watch set (so an absent card would be
              REPORTED, not silently out of scope), and every edge target on a
              member's card resolves to a path that exists.

SCOPE IS THE ARC-0 SET, NOT THE TREE. This is a scoped pass and says so: the repo's
whole-tree fabric warning is expected to persist and is not what this fence ranges
over. Reporting a scoped pass as a cleared warning would be the false green.

Exit 0 all three PASS, 1 any FAIL, 2 refuse (set or config unreadable).
"""
import os
import subprocess
import sys

import yaml

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Overridable so the RED arm of every check can be driven against a throwaway
# fixture (PL-308: a guard that has only ever been green is a hand-maintained claim
# until something has made it fail). Defaults are the real paths; the overrides
# exist for the self-test and are never set in normal use.
SET_FILE = os.environ.get("T671_SET_FILE") or os.path.join(
    REPO, "docs", "research", "executable-workflow", "arc-0-component-set.txt")
CARD_DIR = os.environ.get("T671_CARD_DIR") or os.path.join(
    REPO, ".fabric", "components")
WATCH = os.path.join(REPO, ".fabric", "watch-patterns.yaml")
EXPAND = os.path.join(REPO, ".agentic-framework", "agents", "fabric", "lib",
                      "expand_patterns.py")


def card_path(p):
    d, b = os.path.split(p)
    return os.path.join(CARD_DIR, f"{d.replace('/', '-')}-{os.path.splitext(b)[0]}.yaml")


def self_test():
    """Drive every red arm against a throwaway fixture. Exit 0 only if ALL of them fail.

    PL-308: a guard that has only ever been green is a hand-maintained claim. This is
    the arm that makes the claim checkable from a single command, so a P-011
    Verification leg can assert the fence still has teeth rather than only that it is
    currently happy. Driving it is how the ENRICHED false green (a missing card
    reported PASS, because an empty population satisfies "all of them are enriched")
    was found in the first place.
    """
    import shutil
    import tempfile

    member = "tools/validate-workflow.py"  # real, tracked, inside the watch set
    stub = 'id: %s\nlocation: %s\npurpose: "TODO: describe what this component does"\ndepends_on: []\ndepended_by: []\n' % (member, member)
    dangling = ('id: %s\nlocation: %s\npurpose: "A real sourced purpose."\n'
                'depends_on:\n  - target: tools/does-not-exist-%d.py\n    type: calls\n'
                'depended_by: []\n') % (member, member, os.getpid())

    cases = [("NON-EMPTY+ENRICHED (no card)", None),
             ("ENRICHED (stub card)", stub),
             ("VALIDATED (dangling target)", dangling)]

    tmp = tempfile.mkdtemp(prefix="t671-selftest-")
    failures = []
    try:
        set_file = os.path.join(tmp, "set.txt")
        with open(set_file, "w") as fh:
            fh.write(member + "\n")
        cards = os.path.join(tmp, "cards")
        for label, card in cases:
            shutil.rmtree(cards, ignore_errors=True)
            os.makedirs(cards)
            if card:
                d, b = os.path.split(member)
                name = f"{d.replace('/', '-')}-{os.path.splitext(b)[0]}.yaml"
                with open(os.path.join(cards, name), "w") as fh:
                    fh.write(card)
            env = dict(os.environ, T671_SET_FILE=set_file, T671_CARD_DIR=cards)
            r = subprocess.run([sys.executable, os.path.abspath(__file__)],
                               env=env, capture_output=True, text=True)
            ok = r.returncode == 1
            print(f"{'PASS' if ok else 'FAIL'}  red arm fires: {label} (rc={r.returncode})")
            if not ok:
                failures.append(label)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if failures:
        print("\nSELF-TEST FAILED — the fence did NOT refuse: %s" % ", ".join(failures))
        return 1
    print("\nSELF-TEST PASSED — all three red arms refuse independently.")
    return 0


def main():
    if "--self-test" in sys.argv:
        return self_test()
    if not os.path.exists(SET_FILE):
        sys.stderr.write("REFUSE: Arc-0 component set not found: %s\n" % SET_FILE)
        return 2
    members = [ln.strip() for ln in open(SET_FILE)
               if ln.strip() and not ln.lstrip().startswith("#")]
    if not members:
        sys.stderr.write("REFUSE: Arc-0 component set is empty — an empty set would\n"
                         "pass all three checks vacuously.\n")
        return 2

    # ---- NON-EMPTY -------------------------------------------------------------
    no_card = [m for m in members if not os.path.exists(card_path(m))]

    # ---- ENRICHED --------------------------------------------------------------
    edgeless, placeholder, cards = [], [], {}
    for m in members:
        cp = card_path(m)
        if not os.path.exists(cp):
            continue
        with open(cp) as fh:
            c = yaml.safe_load(fh) or {}
        cards[m] = c
        if not (c.get("depends_on") or []) and not (c.get("depended_by") or []):
            edgeless.append(m)
        if "TODO" in str(c.get("purpose") or ""):
            placeholder.append(m)

    # ---- VALIDATED -------------------------------------------------------------
    watched = set()
    try:
        out = subprocess.run([sys.executable, EXPAND, WATCH, REPO],
                             capture_output=True, text=True, check=True).stdout
        watched = set(out.split())
    except Exception as exc:  # noqa: BLE001 - report, never silently pass
        sys.stderr.write("REFUSE: could not expand watch patterns: %s\n" % exc)
        return 2
    unwatched = [m for m in members if m not in watched]

    dangling = []
    for m, c in cards.items():
        for key in ("depends_on", "depended_by"):
            for e in (c.get(key) or []):
                t = e.get("target") if isinstance(e, dict) else None
                if t and not os.path.exists(os.path.join(REPO, t)):
                    dangling.append(f"{m} -> {t}")

    # ---- report ----------------------------------------------------------------
    def verdict(name, failures, detail):
        uniq = sorted(set(failures))
        ok = not uniq
        print(f"{'PASS' if ok else 'FAIL'}  {name:<10} {detail}")
        for f in uniq[:8]:
            print(f"        - {f}")
        if len(uniq) > 8:
            print(f"        ... and {len(uniq) - 8} more")
        return ok

    print(f"Arc-0 Component Fabric fence — scoped to {len(members)} member(s)")
    print(f"set: {os.path.relpath(SET_FILE, REPO)}\n")

    a = verdict("NON-EMPTY", no_card,
                f"{len(members) - len(no_card)}/{len(members)} member(s) carded")

    # A MISSING CARD CANNOT BE ENRICHED. Counting only the cards that exist made
    # ENRICHED report PASS on a set whose sole member had no card at all — the
    # check silently ranged over an empty population and called that success.
    # Absent cards are ENRICHED failures too, and the two checks fail together
    # rather than one covering for the other.
    not_enriched = set(edgeless) | set(placeholder) | set(no_card)
    b = verdict("ENRICHED", sorted(not_enriched),
                f"{len(members) - len(not_enriched)}/{len(members)} "
                f"card(s) carry edges and a sourced purpose")

    c = verdict("VALIDATED", unwatched + dangling,
                f"{len(members) - len(unwatched)}/{len(members)} in watch set, "
                f"{len(dangling)} dangling edge target(s)")

    if a and b and c:
        print("\nSCOPED PASS — this fence ranges over the Arc-0 set only, and a pass here"
              "\nis not a statement about the tree. The repo-wide fabric coverage warning"
              "\nwas cleared separately by T-673 (whole watch set carded with sourced"
              "\npurposes and derived edges) — NOT by this fence, which never ranged over"
              "\nit. Crediting this pass with that clear would be the false green.")
        return 0
    print("\nFENCE NOT MET — the Arc-0 set above does not satisfy every word of the"
          "\nroadmap section 6 fence. Implementation decomposition is gated on it.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
