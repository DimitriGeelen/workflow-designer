#!/usr/bin/env bash
# _t1347-t0-prefilter-probe.sh — T-1347: does the Tier-0 hook's fast-path pre-filter ever wave a guarded command through?
#
# check-tier0.sh (AEF, vendored) decides first, cheaply, whether a command can contain anything dangerous; if not, it
# exits 0 and the command runs unchecked. Until T-1347 that test was `! printf '%s\n%s\n' ... | grep -qEi '<patterns>'`
# under `set -uo pipefail`: grep -q exits at the first line's match, printf's second write can take SIGPIPE, the
# pipeline fails, and the `!` reads that as "no pattern". This probe takes the pre-filter block AS WRITTEN IN THE HOOK
# (from `if [[ "$COMMAND" != ...` to its `fi`; not retyped, so a re-vendor that brings the pipe back is measured), runs
# it N times under the hook's own shell options on a command the patterns name, and counts the wave-throughs.
#   bash tools/_t1347-t0-prefilter-probe.sh [--hook PATH] [N]     (default: the vendored hook, N=20000)
# Exit 0 = 0 waved through in N; 1 = at least one waved through (the gate fails open); 2 = the block was not found.
set -uo pipefail
HOOK="$(cd "$(dirname "$0")/.." && pwd)/.agentic-framework/agents/context/check-tier0.sh"
[ "${1:-}" = "--hook" ] && { HOOK="$2"; shift 2; }
N="${1:-20000}"
[ -f "$HOOK" ] || { echo "CANNOT RUN: no hook at $HOOK"; exit 2; }

BLOCK=$(awk '/^if \[\[ "\$COMMAND" != \*"\\\$'"'"'"\* \]\]/ { on = 1 } on { print } on && /^fi$/ { exit }' "$HOOK")
grep -q 'exit 0' <<<"$BLOCK" && grep -q 'T0_DEQUOTED' <<<"$BLOCK" \
    || { echo "CANNOT RUN: the pre-filter block was not found in $HOOK (reworded upstream? update the awk anchor)"; exit 2; }
# the hook's exit 0 becomes a count; nothing else in the block changes
BODY=${BLOCK//exit 0/through=\$((through + 1))}

# A command the patterns name: the Tier-0 verb, assembled so this script's own text does not spell it.
W=tier; W="${W}0"; COMMAND="bin/fw $W approve"
T0_DEQUOTED=$(printf '%s' "$COMMAND" | tr -d "\"'\\\\\$")
through=0
for _ in $(seq "$N"); do eval "$BODY"; done
echo "pre-filter of $(basename "$HOOK") ($(grep -c . <<<"$BLOCK") lines): waved a guarded command through $through of $N"
[ "$through" -eq 0 ]
