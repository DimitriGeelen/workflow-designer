#!/usr/bin/env bash
# test_t1108_sidecar_mail_watch.sh — tools/sidecar-mail-watch.sh wakes a non-injectable session on mail (T-1108).
#
# Uses the REAL receiver: sends one consult from this agent to itself, so it is stored and waits exactly as
# dimitri-mint-dev's did. Isolated seen-file per run, so the live watcher's memory is untouched.
#   1  negative control: with every currently-waiting id marked seen, the watcher stays armed (rc 3 at MAX)
#   2  positive: a fresh self-sent consult wakes it (rc 0) and names the msg id
#   3  report-once: re-armed, it does NOT fire again on the same consult (rc 3 at MAX)
#   4  --once on that state reports nothing new (rc 1)
# Exit 0 = all legs pass.
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
W="$ROOT/tools/sidecar-mail-watch.sh"
FW="$ROOT/.agentic-framework/bin/fw"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
export SIDECAR_WATCH_SEEN="$TMP/seen" SIDECAR_WATCH_POLL=1
pass=0; fail=0
leg() { if [ "$1" = 0 ]; then pass=$((pass+1)); echo "PASS $2"; else fail=$((fail+1)); echo "FAIL $2 — $3"; fi; }

# seed: everything already waiting counts as seen (so leg 1 measures only NEW mail)
(cd "$ROOT" && python3 -c "
import sys; sys.path.insert(0,'.agentic-framework/lib')
from sidecar import receiver
print('\n'.join(receiver.awaiting_handover()))") > "$TMP/seen"

SIDECAR_WATCH_MAX=3 bash "$W" > "$TMP/o1" 2>&1; rc=$?
leg $([ $rc = 3 ] && echo 0 || echo 1) "1 no new mail -> stays armed until MAX (rc 3)" "rc=$rc $(head -c 200 "$TMP/o1")"

tag="t1108-selftest-$(date +%s)"
(cd "$ROOT" && "$FW" sidecar send --to 832-Workflow-designer --conversation "$tag" \
   --body "T-1108 watcher self-test ($tag): ignore; the test marks it seen.") > "$TMP/send" 2>&1
SIDECAR_WATCH_MAX=60 bash "$W" > "$TMP/o2" 2>&1; rc=$?
leg $([ $rc = 0 ] && grep -q "conversation $tag" "$TMP/o2" && echo 0 || echo 1) "2 a fresh consult wakes it and names it" "rc=$rc $(head -c 300 "$TMP/o2") send: $(head -c 200 "$TMP/send")"

SIDECAR_WATCH_MAX=3 bash "$W" > "$TMP/o3" 2>&1; rc=$?
leg $([ $rc = 3 ] && echo 0 || echo 1) "3 re-armed, the same consult does not fire again" "rc=$rc $(head -c 200 "$TMP/o3")"

bash "$W" --once > "$TMP/o4" 2>&1; rc=$?
leg $([ $rc = 1 ] && echo 0 || echo 1) "4 --once: nothing new (rc 1)" "rc=$rc"

# the self-test consult must not wake the LIVE watcher either: mark it seen there too
grep -oE '[0-9a-f-]{36}' "$TMP/o2" | head -1 >> "$ROOT/.context/working/sidecar-mail-watch.seen"
echo "T-1108 sidecar mail watch: $pass passed, $fail failed"
[ "$fail" = 0 ]
