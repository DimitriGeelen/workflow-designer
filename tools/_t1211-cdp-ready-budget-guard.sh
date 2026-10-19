#!/bin/bash
# _t1211-cdp-ready-budget-guard.sh — every CDP probe's editor-readiness budget reads CDP_READY_MS (832 T-1211).
#
# WHY. 95 probes each carried their own fixed budget for the editor to become ready (87 at 20 s, 4 at 25 s, one as
# 200 turns of 150 ms). On a loaded host a full bridge run made a DIFFERENT one miss it each time (_t1060 on one run,
# _t1194 on the next), while each passed alone. Patching the one that failed only moves the flake. Now each budget
# is `(+process.env.CDP_READY_MS || <its old default>)`: standalone runs behave as before, and the suite raises it
# once. This guard keeps a new or copied probe from hard-coding the budget again.
#
# WHAT IT CHECKS. Every line in tools/*.mjs that throws 'editor not ready' must read CDP_READY_MS on that line, or,
# for a loop-shaped wait, within the 3 lines above it. A probe whose budget lives elsewhere names itself in the output.
# Teeth: a scratch copy of one probe with its budget reverted must turn the scan red.
#
# Usage: bash tools/_t1211-cdp-ready-budget-guard.sh [DIR]   (DIR defaults to tools/; the teeth leg passes its own)
# Exit 0 = every budget reads it; 1 = a hard-coded budget; 2 = cannot measure (nothing found, or teeth inert).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

scan() {   # scan DIR -> prints offenders; returns 0 clean, 1 offenders, 2 nothing found
    local dir="$1" n=0 bad=0 f ln
    for f in "$dir"/*.mjs; do
        [ -f "$f" ] || continue
        while IFS=: read -r ln _; do
            n=$((n + 1))
            if ! sed -n "$((ln > 3 ? ln - 3 : 1)),${ln}p" "$f" | grep -q 'CDP_READY_MS'; then
                echo "  HARD-CODED  $(basename "$f"):$ln — the 'editor not ready' budget does not read CDP_READY_MS"
                bad=$((bad + 1))
            fi
        done < <(grep -n "throw new Error('editor not ready" "$f")
    done
    [ "$n" -eq 0 ] && { echo "  found no 'editor not ready' budget at all in $dir"; return 2; }
    echo "  $n budget(s) scanned in $dir, $bad hard-coded"
    [ "$bad" -eq 0 ]
}

if [ $# -ge 1 ]; then scan "$1"; exit $?; fi

echo "=== T-1211: every CDP probe's readiness budget reads CDP_READY_MS ==="
scan "$ROOT/tools"; rc=$?
[ "$rc" -eq 2 ] && { echo "CANNOT MEASURE: no probe found — a moved tools/ dir would make this pass vacuously"; exit 2; }

# Teeth: revert one probe's budget in a scratch copy; the scan must go red on exactly that copy.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
probe="$ROOT/tools/_t1194-slug-task-id-cdp.mjs"
sed -E 's/\(\+process\.env\.CDP_READY_MS \|\| ([0-9]+)\)/\1/' "$probe" > "$tmp/$(basename "$probe")"
if cmp -s "$probe" "$tmp/$(basename "$probe")"; then
    echo "CANNOT MEASURE: the teeth revert did not apply to $(basename "$probe") — its budget shape changed"; exit 2
fi
if scan "$tmp" >/dev/null; then
    echo "  TEETH FAIL  a probe with a hard-coded budget passed the scan — this guard cannot fail"; exit 2
fi
echo "  teeth ok    a reverted copy of $(basename "$probe") is reported HARD-CODED"
exit "$rc"
