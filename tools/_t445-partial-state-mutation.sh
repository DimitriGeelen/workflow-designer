#!/usr/bin/env bash
# _t445-partial-state-mutation.sh — does the inbox-route probe's THREE-state machine
# actually fire on all three states, or only on the one the live tree happens to be in?
#
# T-445 / G-032. `_t436-inbox-route-probe.sh` gained a PARTIAL arm after AEF measured
# their own tree at 1 row of 112 pending. My tree cannot produce that state: the
# vendored handover.sh is unfixed here, so leg A is pinned at 0 and the PARTIAL and
# FIXED arms would never run. An arm that has never been exercised is indistinguishable
# from one that cannot fire — so this drives the probe against fixtures that force each
# state, through its real entry point, with the block it really extracts from the
# shipped handover.
#
# WHY NOT UNIT-TEST THE COMPARISON
# The comparison is three lines of shell; testing it in isolation would prove the
# arithmetic and nothing about whether the probe reaches it. These fixtures move the
# INPUT the probe reads and let the probe do everything else, including extracting the
# block from the vendored file. If the extraction breaks, every case here goes UNKNOWN
# rather than green.
#
# EXIT
#   0  all three states reproduce with the expected verdict
#   1  a state did not reproduce — the probe's arm is dead, or its verdict text moved
#   2  cannot answer (probe missing, or it abstained on a fixture, which means the
#      fixture and not the arm is at fault)
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
PROBE="tools/_t436-inbox-route-probe.sh"
[ -x "$PROBE" ] || [ -f "$PROBE" ] || { echo "UNKNOWN — no $PROBE. Cannot answer."; exit 2; }

legs=0; fails=0
ok()  { legs=$((legs + 1)); echo "  ok    $*"; }
bad() { legs=$((legs + 1)); echo "  FAIL  $*" >&2; fails=$((fails + 1)); }

SP="$(mktemp -d)"; trap 'rm -rf "$SP"' EXIT

# DEFECT — column-0 entries, the shape the live inbox actually writes. The block's
# `\n  - ` split matches nothing, so 0 rows for 2 pending.
cat > "$SP/defect.yaml" <<'YEOF'
observations:
- id: OBS-901
  text: "column-zero, as the real inbox writes it"
  status: pending
  promoted_to: null
- id: OBS-902
  text: "second"
  status: pending
  promoted_to: null
YEOF

# PARTIAL — two-space entries so the split matches, but two of the three carry no
# `text:` field, so the block's `if obs_id and text` drops them. 1 row, 3 pending:
# AEF's shape reproduced locally without touching the vendored bytes.
cat > "$SP/partial.yaml" <<'YEOF'
observations:
  - id: OBS-901
    text: "the one row an eye lands on"
    status: pending
    promoted_to: null
  - id: OBS-902
    status: pending
    promoted_to: null
  - id: OBS-903
    status: pending
    promoted_to: null
YEOF

# FIXED — every pending entry emits. 2 of 2: G-032's stated closure condition.
cat > "$SP/fixed.yaml" <<'YEOF'
observations:
  - id: OBS-901
    text: "first"
    status: pending
    promoted_to: null
  - id: OBS-902
    text: "second"
    status: pending
    promoted_to: null
YEOF

echo "=== T-445: do all three arms of the inbox-route state machine fire? ==="
echo

drive() { # drive <fixture> <expected-rc> <expected-verdict-substring>
  local fixture="$1" want_rc="$2" want_txt="$3" out rc
  out="$(bash "$PROBE" "$SP/$fixture.yaml" 2>&1)"; rc=$?
  if [ "$rc" -eq 2 ]; then
    echo "UNKNOWN — the probe abstained on $fixture.yaml. The fixture is at fault, not"
    echo "  the arm; refusing to score. Probe said:"
    echo "$out" | sed 's/^/    /'
    exit 2
  fi
  if [ "$rc" -eq "$want_rc" ] && printf '%s' "$out" | grep -qF "$want_txt"; then
    ok "$fixture reproduces: rc=$rc, verdict names '$want_txt'"
  else
    bad "$fixture did NOT reproduce: rc=$rc (wanted $want_rc), verdict missing
        '$want_txt'. The arm is dead or its text moved. Probe said:
$(echo "$out" | sed 's/^/          /')"
  fi
}

drive defect  0 "PASS [DEFECT]"
drive partial 1 "PARTIAL — the block emitted 1 of 3"
drive fixed   1 "FIXED — the block emitted 2 of 2"

echo
echo "  legs=$legs fails=$fails"
# T-430 abstention guard — three cases that all silently skipped must not read as green.
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no cases ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "FAIL — a state of the probe's machine does not reproduce. Until it does, a" >&2
  echo "  green from that probe says nothing about the state it claims to detect." >&2
  exit 1
fi
echo "PASS — DEFECT, PARTIAL and FIXED each reproduce through the probe's real entry"
echo "  point, so the PARTIAL arm my tree cannot reach is proven live."
