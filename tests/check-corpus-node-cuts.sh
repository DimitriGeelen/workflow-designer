#!/usr/bin/env bash
# Corpus node-cut regression gate (T-113) — PL-004 prevention.
#
# A "node-cut" is an edge whose rendered polyline passes through a node it does not
# connect to (a legibility defect). tools/_node-cuts-cdp.mjs measures cuts over every
# examples/aef-processes/rendered/*.bpmn by driving the REAL editor's own
# polylineCrossesNodes (PL-005 — no re-implemented geometry). This gate runs that
# census and compares it to a committed baseline so any layout change that INCREASES
# node-cuts is caught, and any IMPROVEMENT forces a baseline refresh (rot-proof, in
# the exact spirit of tests/check-corpus-geometry.sh).
#
# Contract (per map, on 'incidences'):
#   - current > baseline  → REGRESSION → FAIL (a change made routing worse).
#   - current < baseline  → IMPROVED   → FAIL (stale baseline: refresh it so wins lock in).
#   - current == baseline  → PASS.
#   - map missing from baseline → FAIL (new map must be baselined).
#   - driver error         → FAIL loudly.
#
# Refresh the baseline after a legitimate improvement:
#   node tools/_node-cuts-cdp.mjs | \
#     python3 -c "import json,sys; d=json.load(sys.stdin); \
#       json.dump({m:{'cutEdges':v['cutEdges'],'incidences':v['incidences']} \
#       for m,v in sorted(d.items()) if v.get('ok')}, \
#       open('tests/fixtures/node-cuts-baseline.json','w'), indent=2)"
#
# Exit 0 iff current census == committed baseline for every map.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER="$ROOT/tools/_node-cuts-cdp.mjs"
BASELINE="$ROOT/tests/fixtures/node-cuts-baseline.json"

[ -f "$DRIVER" ]   || { echo "ERROR: driver missing: $DRIVER"; exit 1; }
[ -f "$BASELINE" ] || { echo "ERROR: baseline missing: $BASELINE (run the refresh command in this script's header)"; exit 1; }

echo "== corpus node-cut sweep (T-113) =="

CENSUS="$(node "$DRIVER" 2>/tmp/.node-cuts-driver.err)" || {
  echo "ERROR: driver failed:"; sed 's/^/  /' /tmp/.node-cuts-driver.err | head -20; exit 1;
}

echo "$CENSUS" | BASELINE="$BASELINE" python3 -c '
import json, os, sys
cur = json.load(sys.stdin)
base = json.load(open(os.environ["BASELINE"]))

regressed = improved = missing = drv_err = ok = 0
cur_total = base_total = 0

for m in sorted(cur):
    v = cur[m]
    if not v.get("ok"):
        print("  [ERR]  " + m + " -- driver: " + str(v.get("error", "?"))[:80]); drv_err += 1; continue
    c = v["incidences"]; cur_total += c
    if m not in base:
        print("  [NEW]  " + m + " -- " + str(c) + " cuts, not in baseline (add it)"); missing += 1; continue
    b = base[m]["incidences"]; base_total += b
    if c > b:
        print("  [FAIL] " + m + " -- cuts " + str(b) + " -> " + str(c) + " (REGRESSION +" + str(c - b) + ")"); regressed += 1
    elif c < b:
        print("  [STALE] " + m + " -- cuts " + str(b) + " -> " + str(c) + " (IMPROVED; refresh baseline)"); improved += 1
    else:
        ok += 1

for m in sorted(base):
    if m not in cur:
        print("  [FAIL] " + m + " -- in baseline but not measured (deleted/renamed?)"); missing += 1

print()
print("node-cut sweep: " + str(ok) + " unchanged, " + str(regressed) + " regressed, " +
      str(improved) + " improved-stale, " + str(missing) + " missing, " + str(drv_err) +
      " driver-err  |  total cuts " + str(cur_total) + " (baseline " + str(base_total) + ")")
sys.exit(0 if (regressed == 0 and improved == 0 and missing == 0 and drv_err == 0) else 1)
'
