#!/bin/bash
# _t1183-tmp-containment.sh — T-1183 (P-015): 832's test runs must not leave folders in the host's shared /tmp.
#
# The suite (tests/run-bridge-tests.sh) and the instrument sweep (tools/_t509-instrument-sweep.sh) each export
# TMPDIR into a private run directory that their traps remove on exit. node tmpdir(), python tempfile, bash
# mktemp and headless Chromium's own org.chromium.Chromium.* folder all follow TMPDIR, so a test that never
# cleans up (or a Chromium that is SIGKILLed) leaves its folders there instead of in /tmp.
#   1-2  each runner exports TMPDIR into its trapped run directory, before the first test it runs
#   3    a child that leaks (node mkdtemp, python mkdtemp, bash mktemp, never removed) lands INSIDE the private dir
#   4    and the shared /tmp gains none of the leaked names
# Exit 0 = pass, 1 = a leg failed.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
ok()   { echo "PASS  $*"; }
bad()  { echo "FAIL  $*"; fails=$((fails + 1)); }

# 1. the suite: TMP is made, exported as TMPDIR, and the EXIT trap removes it — all before the first test runs
S="$ROOT/tests/run-bridge-tests.sh"
l_tmp=$(grep -n '^TMP="$(mktemp -d)"' "$S" | head -1 | cut -d: -f1)
l_exp=$(grep -n '^export TMPDIR="$TMP"' "$S" | head -1 | cut -d: -f1)
l_trap=$(grep -n "^trap '.*rm -rf \"\$TMP\"' EXIT" "$S" | head -1 | cut -d: -f1)
l_first=$(grep -n '^for f in "\${files\[@\]}"' "$S" | head -1 | cut -d: -f1)
if [ -n "$l_tmp" ] && [ -n "$l_exp" ] && [ -n "$l_trap" ] && [ -n "$l_first" ] && [ "$l_tmp" -lt "$l_exp" ] && [ "$l_exp" -lt "$l_first" ] && [ "$l_trap" -lt "$l_first" ]; then
  ok "1 the bridge suite exports TMPDIR into its trapped \$TMP (lines $l_tmp/$l_exp/$l_trap) before its first test (line $l_first)"
else
  bad "1 the bridge suite does not export TMPDIR into a trapped run dir before its tests (tmp=$l_tmp export=$l_exp trap=$l_trap first=$l_first)"
fi

# 2. the sweep: RUNTMP made, trapped, exported, before the probe loop
W="$ROOT/tools/_t509-instrument-sweep.sh"
w_run=$(grep -n '^RUNTMP="$(mktemp -d' "$W" | head -1 | cut -d: -f1)
w_trap=$(grep -n "^trap 'rm -rf \"\$RUNTMP\"' EXIT" "$W" | head -1 | cut -d: -f1)
w_exp=$(grep -n '^export TMPDIR="$RUNTMP"' "$W" | head -1 | cut -d: -f1)
w_loop=$(grep -n 'timeout "$limit" "$runner"' "$W" | head -1 | cut -d: -f1)
if [ -n "$w_run" ] && [ -n "$w_trap" ] && [ -n "$w_exp" ] && [ -n "$w_loop" ] && [ "$w_exp" -lt "$w_loop" ] && [ "$w_trap" -lt "$w_loop" ]; then
  ok "2 the instrument sweep exports TMPDIR into its trapped \$RUNTMP (lines $w_run/$w_trap/$w_exp) before running probes (line $w_loop)"
else
  bad "2 the instrument sweep does not export TMPDIR into a trapped run dir before its probes (run=$w_run trap=$w_trap export=$w_exp loop=$w_loop)"
fi

# 3-4. the mechanism: leak on purpose under a private TMPDIR, the way the runners do
PRIV="$(mktemp -d "${TMPDIR:-/tmp}/t1183-priv-XXXXXX")"
trap 'rm -rf "$PRIV"' EXIT
TAG="t1183leak$$"
TMPDIR="$PRIV" node -e "require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), '$TAG-node-'))"
TMPDIR="$PRIV" python3 -c "import tempfile; tempfile.mkdtemp(prefix='$TAG-py-')"
TMPDIR="$PRIV" bash -c "mktemp -d -t '$TAG-sh-XXXXXX' >/dev/null"
inside=$(ls -A "$PRIV" | grep -c "^$TAG-")
outside=$(ls -A /tmp | grep -c "^$TAG-")
[ "$inside" -eq 3 ] && ok "3 all three deliberate leaks (node, python, bash) landed inside the private dir" \
                    || bad "3 expected 3 leaked folders inside the private dir, found $inside"
[ "$outside" -eq 0 ] && ok "4 the shared /tmp gained none of them" || bad "4 $outside leaked folder(s) reached the shared /tmp"

[ "$fails" -eq 0 ] && { echo "tmp containment: 4/4"; exit 0; }
echo "tmp containment: $fails leg(s) failed"; exit 1
