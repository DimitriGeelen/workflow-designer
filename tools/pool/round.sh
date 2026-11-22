#!/usr/bin/env bash
# round.sh — T-1482 (T-1478 GO, O4): a designer round's two gates AT THE SAME TIME instead of one after the other:
#   the browser gate  tools/pool/tier-gate.sh browser   (what CLAUDE.md asks before pushing a src/ or validator change)
#   the push gate     tools/_t1288-prepush-gate.sh       (core; a green run is cached by tree, so the push then passes at once)
# Their pool slots do not compete (ring20: separate per-entry caps for 832 core and browser). Each gate keeps its own
# rules, logs and verdict lines (build/tiergate/tier-browser.runs.log, .context/working/prepush-core.runs.log).
# A red gate stops the other at once (its local shards and waits; pool jobs already sent run out on ring20): a red
# round needs a fix whatever the other says, and the cache can only ever record a green core run.
#   bash tools/pool/round.sh          exit 0 both green · 1 a gate red (or stopped by the other's red) · 2 setup broken
# Output: build/tiergate/round/{browser,core}.out; one summary line per gate with its time.
# T1482_BROWSER_CMD / T1482_CORE_CMD replace the two gates (tests only).
set -u
ROOT=$(git rev-parse --show-toplevel) || exit 2
OUT="$ROOT/build/tiergate/round"; mkdir -p "$OUT" || exit 2
BCMD=${T1482_BROWSER_CMD:-bash "$ROOT/tools/pool/tier-gate.sh" browser}
CCMD=${T1482_CORE_CMD:-bash "$ROOT/tools/_t1288-prepush-gate.sh"}
T0=$(date +%s)
# each gate in its own process group (setsid), so stopping one stops all it started here and nothing else.
# env --default-signal: bash starts a background job with SIGINT and SIGQUIT IGNORED (no job control), and an ignored
# signal is inherited by everything under it; the first real round failed _t1286 case 7 (a SIGINT mid-step was never
# delivered) for exactly that reason. The gates must see the signals a terminal run would.
setsid env --default-signal=INT,QUIT bash -c "cd '$ROOT' && exec $BCMD" > "$OUT/browser.out" 2>&1 < /dev/null & bpid=$!
setsid env --default-signal=INT,QUIT bash -c "cd '$ROOT' && exec $CCMD" > "$OUT/core.out" 2>&1 < /dev/null & cpid=$!
echo "round: browser and core gates started together at $(git -C "$ROOT" rev-parse --short HEAD) (logs: ${OUT#"$ROOT"/}/)" >&2
stop() { kill -TERM -- "-$1" 2>/dev/null; sleep 2; kill -KILL -- "-$1" 2>/dev/null; }
trap 'stop $bpid; stop $cpid; exit 130' INT TERM HUP
brc="" crc="" bt="" ct=""
while [ -z "$brc" ] || [ -z "$crc" ]; do
    wait -n "$bpid" "$cpid" 2>/dev/null
    if [ -z "$brc" ] && ! kill -0 "$bpid" 2>/dev/null; then wait "$bpid"; brc=$?; bt=$(( $(date +%s) - T0 )); fi
    if [ -z "$crc" ] && ! kill -0 "$cpid" 2>/dev/null; then wait "$cpid"; crc=$?; ct=$(( $(date +%s) - T0 )); fi
    if [ -n "$brc" ] && [ "$brc" != 0 ] && [ "$brc" != stopped ] && [ -z "$crc" ]; then
        stop "$cpid"; wait "$cpid" 2>/dev/null; crc=stopped; ct=$(( $(date +%s) - T0 )); fi
    if [ -n "$crc" ] && [ "$crc" != 0 ] && [ "$crc" != stopped ] && [ -z "$brc" ]; then
        stop "$bpid"; wait "$bpid" 2>/dev/null; brc=stopped; bt=$(( $(date +%s) - T0 )); fi
done
verdict() { case "$1" in 0) echo green ;; stopped) echo "STOPPED (the other gate was red)" ;; *) echo "RED (exit $1)" ;; esac; }
echo "round: browser $(verdict "$brc") after ${bt}s"
echo "round: core    $(verdict "$crc") after ${ct}s"
echo "round: total $(( $(date +%s) - T0 ))s (logs: ${OUT#"$ROOT"/}/browser.out, core.out)"
[ "$brc" = 0 ] && [ "$crc" = 0 ] && exit 0
exit 1
