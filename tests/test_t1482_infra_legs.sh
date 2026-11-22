#!/usr/bin/env bash
# T-1482 (operator's option 2, 2026-11-22): the tier engine tells "the browser did not start" apart from a red verdict.
#   I1 a browser leg whose output says "no devtools port" (the waitPortFile / person-sees wording) is retryable, as
#      "did not open a DevTools port" always was (the miss left a DIFFER marker for a Chrome start failure on pool-132)
#   I2 such a red attempt is named in <leglog>.infra (tier, leg, attempt); an ordinary red attempt is not
# Control: T1482_TIERS=<the tier engine before T-1482> fails I1 and I2.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIERS=${T1482_TIERS:-$ROOT/tools/_t1288-tiers.sh}
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
out=$(cd "$ROOT" && TMP="$W" T1288_LEGLOG="$W/legs.tsv" bash -c '
    T1288_TIERS="core browser"; source "'"$TIERS"'" >/dev/null 2>&1
    pass=0; fail=0; report() { :; }
    nochrome() { echo "NOT RUN label-clearance: exception: Error: no devtools port"; fail=$((fail + 1)); }
    realred()  { echo "FAIL  L2 a node outside the pool"; fail=$((fail + 1)); }
    echo "NOT RUN x: Error: no devtools port" > "$TMP/o1"; : > "$TMP/s"; touch -d "@$(( $(date +%s) - 5 ))" "$TMP/s"
    _T1288_TO_MARK="$TMP/none"; _t1288_retryable "$TMP/o1" "$TMP/s" && echo "retryable=yes" || echo "retryable=no"
    _t1288_run browser leg-nochrome first nochrome >/dev/null
    _t1288_run browser leg-realred first realred >/dev/null
    echo "infra=$(cut -f2 "$T1288_LEGLOG.infra" 2>/dev/null | tr "\n" ",")"' 2>&1)
fails=0
grep -qx 'retryable=yes' <<<"$out" && echo "PASS  I1 'no devtools port' is a retryable browser failure" || { echo "FAIL  I1: $(grep retryable= <<<"$out")"; fails=1; }
grep -qx 'infra=leg-nochrome,' <<<"$out" && echo "PASS  I2 the Chrome-start red is named in legs.tsv.infra, the real red is not" || { echo "FAIL  I2: $(grep infra= <<<"$out")"; fails=1; }
[ "$fails" = 0 ] && echo "T-1482 infra legs: GREEN" || echo "T-1482 infra legs: RED"
exit "$fails"
