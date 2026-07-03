#!/usr/bin/env bash
# Corpus geometry sweep (T-052) — G-019 prevention for the blindness found in T-050.
#
# tools/check-lane-bands.py asserts every node's y-box sits inside its lane band
# (no straddle, no same-lane overlap). It existed but was never run against the
# corpus, so pre-convention maps straddled bands undetected. This sweep runs the
# gate on EVERY examples/aef-processes/*.workflow.yaml and fails on any straddle
# — EXCEPT an explicit legacy allowlist (the maps authored before the lane-band
# convention was tightened, tracked for re-layout under T-051).
#
# Contract:
#   - A straddle in a NON-allowlisted map  → FAIL (exit non-zero). New work is gated.
#   - A straddle in an allowlisted map      → KNOWN-LEGACY (T-051), not a failure.
#   - An allowlisted map that now PASSES     → STALE ALLOWLIST entry → FAIL (so the
#                                              list can't rot: fixed maps must be
#                                              removed from the allowlist).
#   - check-lane-bands.py tool error (exit 2)→ FAIL loudly.
#
# Exit 0 iff the corpus is geometry-clean modulo an exact legacy allowlist.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$ROOT/tools/check-lane-bands.py"
CORPUS="$ROOT/examples/aef-processes"

# Legacy maps that predate the tightened lane-band convention (T-051 re-layout).
# Keep this list EXACT — a fixed map must be removed, or the sweep flags it stale.
LEGACY="
arc-lifecycle
assumption-validation
audit-process
inception-lifecycle
session-handover
task-lifecycle
tier0-escalation
upgrade-process
"

is_legacy() { echo "$LEGACY" | grep -qx "$1"; }

report() { printf '  [%s] %s\n' "$1" "$2"; }

clean=0; legacy_known=0; new_fail=0; stale=0; tool_err=0

shopt -s nullglob
files=("$CORPUS"/*.workflow.yaml)
if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no corpus files found in $CORPUS"
  exit 1
fi

echo "== corpus geometry sweep (T-052) =="
for f in "${files[@]}"; do
  base="$(basename "$f" .workflow.yaml)"
  python3 "$GATE" "$f" >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 2 ]; then
    report ERR "$base — check-lane-bands.py tool error (exit 2)"
    tool_err=$((tool_err + 1))
    continue
  fi
  if [ "$rc" -eq 0 ]; then
    if is_legacy "$base"; then
      report STALE "$base — passes now; remove from LEGACY allowlist (T-051)"
      stale=$((stale + 1))
    else
      report PASS "$base"
      clean=$((clean + 1))
    fi
  else
    if is_legacy "$base"; then
      report KNOWN-LEGACY "$base — straddles bands; tracked for re-layout (T-051)"
      legacy_known=$((legacy_known + 1))
    else
      report FAIL "$base — node straddles its lane band (run: python3 tools/check-lane-bands.py $f)"
      new_fail=$((new_fail + 1))
    fi
  fi
done

echo
echo "geometry sweep: $clean clean, $legacy_known known-legacy, $new_fail new-fail, $stale stale, $tool_err tool-err"
[ "$new_fail" -eq 0 ] && [ "$stale" -eq 0 ] && [ "$tool_err" -eq 0 ]
