#!/usr/bin/env python3
"""T-342: establish the KIND of `fw fabric enrich`'s zero.

Runs enrich.py's OWN pipeline (not a reimplementation — divergence between a
probe's copy of the logic and the real logic is exactly how you measure the
wrong thing) with resolve_edges wrapped so that, per card, we see:

  raw      = edges the detectors produced (already existence-guarded against disk)
  resolved = edges that survived lookup in the registered-card index

`compute_forward_edges` returns early on `if not raw_edges: continue`, so a card
that produces zero raw edges never reaches resolve_edges at all. Those cards are
recovered by difference: cards_total - cards_that_called_resolve.

Two different zeros are possible and they mean opposite things:
  detected 0            -> CONSTRUCTION: no dependency is expressible/detectable here
  detected >0, kept 0   -> OCCUPANCY:    dependencies exist, the registry has no card
                                         for their targets, and the drop is silent
"""
import importlib.util
import os
import sys
from collections import defaultdict

PROJECT = "/opt/832-Workflow-designer"
LIB = os.path.join(PROJECT, ".agentic-framework/agents/fabric/lib/enrich.py")

spec = importlib.util.spec_from_file_location("enrich", LIB)
enrich = importlib.util.module_from_spec(spec)
spec.loader.exec_module(enrich)

components_dir = os.path.join(PROJECT, ".fabric", "components")
cards, loc_to_id, loc_to_card, id_to_loc, id_to_card = enrich.build_index(components_dir)

seen_raw = {}          # card_path -> (raw_edges, resolved_edges)
real_resolve = enrich.resolve_edges


def spy(raw_edges, loc_to_id_, source_id, *a, **kw):
    # T-343 added a `discarded` collector parameter to resolve_edges. Forward it
    # verbatim rather than swallowing it: the caller relies on that list being
    # filled, and a spy that silently dropped it would make enrich's own new
    # counter read 0 whenever this probe is loaded.
    out = real_resolve(raw_edges, loc_to_id_, source_id, *a, **kw)
    spy.last = (list(raw_edges), list(out), source_id)
    return out


enrich.resolve_edges = spy

# compute_forward_edges iterates sorted(cards.items()); re-run per card so the
# spy result can be attributed to a card without patching the loop itself.
per_card = {}
for card_path, card_data in sorted(cards.items()):
    spy.last = None
    enrich.compute_forward_edges({card_path: card_data}, loc_to_id, PROJECT)
    loc = card_data.get("location", "")
    exists = os.path.exists(os.path.join(PROJECT, loc)) if loc else False
    if spy.last is None:
        per_card[loc] = (0, 0, exists, None)
    else:
        raw, kept, _sid = spy.last
        per_card[loc] = (len(raw), len(kept), exists, raw)

tot_raw = sum(v[0] for v in per_card.values())
tot_kept = sum(v[1] for v in per_card.values())
missing = [l for l, v in per_card.items() if not v[2]]

print(f"registered cards            : {len(cards)}")
print(f"  whose source file exists  : {sum(1 for v in per_card.values() if v[2])}")
print(f"raw edges DETECTED          : {tot_raw}")
print(f"raw edges SURVIVING resolve : {tot_kept}")
print(f"dropped at resolution       : {tot_raw - tot_kept}")
print()
if tot_raw == 0:
    print("ZERO KIND: CONSTRUCTION — the detectors produced nothing to drop.")
else:
    print("ZERO KIND: OCCUPANCY — edges were detected and discarded for want of a card.")
print()
print("per card (location: detected -> kept):")
for loc in sorted(per_card):
    raw, kept, exists, rawlist = per_card[loc]
    flag = "" if exists else "  [SOURCE FILE MISSING]"
    print(f"  {raw:3d} -> {kept:3d}  {loc}{flag}")
    if rawlist:
        for t, ty in rawlist:
            has = "card" if os.path.normpath(t) in loc_to_id else "NO CARD"
            print(f"            {ty:10s} {t}   [{has}]")

# --- second question: what does the detector dispatch actually cover? ---
print()
exts = defaultdict(int)
for loc in per_card:
    exts[os.path.splitext(loc)[1] or "(none)"] += 1
print("registered cards by extension:", dict(exts))
SCANNED = {".sh", ".bats", ".py", ".html", ".ts", ".tsx", ".js", ".jsx", ".rs"}
unscanned = {e: n for e, n in exts.items() if e not in SCANNED}
print("extensions with NO type-detector branch:", unscanned)
