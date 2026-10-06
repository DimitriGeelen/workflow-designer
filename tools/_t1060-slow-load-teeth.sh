#!/usr/bin/env bash
# _t1060-slow-load-teeth.sh — the CDP probes wait for the ?load= map, not a lucky 400 ms (832 T-1060).
#
# On a busy host the editor's deep-link fetch landed after the probes' fixed sleep, and two standing
# guards reported "CANNOT RUN: fixture node absent" — read by the bridge suite as regressions.
# Stimulus, deterministic instead of "load the machine": an editor copy whose ?load= fetch waits
# 1.5 s before starting.
#   leg 1  _t573 against the slow editor passes            (the fix holds)
#   leg 2  _t570's probe against the slow editor passes    (the fix holds)
#   leg 3  CONTROL: _t573 with the OLD ready-condition against the slow editor reports CANNOT RUN
#          (the stimulus reaches the race; legs 1-2 are not vacuous)
# exit 0 = all legs pass; 1 = a leg failed; 2 = could not set up
set -uo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$ROOT/src/aef-workflow-designer.html"
T573="$ROOT/tools/_t573-emits-panel-shape-cdp.mjs"
T570="$ROOT/tools/_t570-meta-carriage-cdp.mjs"
W=$(mktemp -d -t t1060-teeth.XXXXXX); trap 'rm -rf "$W"' EXIT
fails=0
leg() { if [ "$1" = 0 ]; then echo "PASS  $2"; else echo "FAIL  $2${3:+ — $3}"; fails=$((fails + 1)); fi; }

python3 - "$SRC" "$W/slow.html" <<'PY' || { echo "CANNOT RUN: could not build the slow editor (fetch line moved?)"; exit 2; }
import sys
s = open(sys.argv[1]).read()
old = "    const res = await fetch(src);\n    if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${src}`);"
if s.count(old) != 1:
    sys.exit(1)
open(sys.argv[2], "w").write(s.replace(old, "    await new Promise(r => setTimeout(r, 1500));\n" + old))
PY

out=$(cd "$ROOT" && timeout 300 node "$T573" --src "$W/slow.html" 2>&1); rc=$?
leg $([ "$rc" = 0 ] && grep -q 'legs passed' <<<"$out"; echo $?) "1 _t573 passes against a slow-loading editor" "rc=$rc $(tail -1 <<<"$out" | cut -c1-120)"

out=$(cd "$ROOT" && timeout 300 node "$T570" --src "$W/slow.html" 2>&1); rc=$?
leg $([ "$rc" = 0 ] && grep -q 'legs passed' <<<"$out"; echo $?) "2 _t570 probe passes against a slow-loading editor" "rc=$rc $(tail -1 <<<"$out" | cut -c1-120)"

# Control: the probe with the pre-T-1060 ready-condition (copied next to the original so its
# relative imports and paths still resolve).
OLDP="$ROOT/tools/.t1060-control-$$.mjs"
python3 - "$T573" "$OLDP" <<'PY' || { echo "CANNOT RUN: could not build the control probe"; exit 2; }
import sys
s = open(sys.argv[1]).read()
new = "&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))"
if s.count(new) != 1:
    sys.exit(1)
open(sys.argv[2], "w").write(s.replace(new, ")"))
PY
out=$(cd "$ROOT" && timeout 300 node "$OLDP" --src "$W/slow.html" 2>&1); rc=$?
rm -f "$OLDP"
leg $([ "$rc" != 0 ] && grep -q 'CANNOT RUN: fixture node absent' <<<"$out"; echo $?) \
    "3 CONTROL: the old fixed-sleep wait loses the race against the same editor" "rc=$rc $(tail -1 <<<"$out" | cut -c1-120)"

echo
[ "$fails" = 0 ] && { echo "3/3 T-1060 legs passed"; exit 0; }
echo "$fails leg(s) failed"; exit 1
