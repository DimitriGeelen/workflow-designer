#!/usr/bin/env bash
# T-848 — tests for the realization-ledger checker.
#
# WRITTEN AND RUN BEFORE THE CHECKER EXISTED. First run recorded in T-848 failing for the right
# reason (script absent), not passing vacuously.
#
# WHAT MATTERS HERE. The checker must be THREE-VALUED: a prediction whose trigger has not fired
# is NOT_YET_DUE, and must never be counted as satisfied. That is the whole discipline this
# session has been arguing for, applied to the instrument built at the end of it — and the
# temptation it guards against is real, because a ledger that reports "6 of 7 predictions holding"
# by counting untriggered rows as holding is exactly the false green.
set -uo pipefail
REPO="${T848_REPO_ROOT:-/opt/832-Workflow-designer}"
CHK="$REPO/tools/_t848-realization-check.py"
S=$(mktemp -d); trap 'rm -rf "$S"' EXIT
P=0; F=0; N=0
ok(){ P=$((P+1)); N=$((N+1)); printf 'ok %d - %s\n' "$N" "$1"; }
bad(){ F=$((F+1)); N=$((N+1)); printf 'not ok %d - %s\n' "$N" "$1"; }

if [ ! -f "$CHK" ]; then
  bad "checker $CHK does not exist yet — implementation not written"
  printf '\n# passed %d, failed %d\n' "$P" "$F"
  echo "# RED FOR THE RIGHT REASON: pre-implementation state required by T-848's tests-first AC."
  exit 1
fi

# ── fixture ledger: one of each status, plus a malformed row ──────────────────
cat > "$S/led.jsonl" <<'EOF'
{"id":"R-001","source":"T-x","prediction":"a","observable":"b","status":"OBSERVED_TRUE","observed":"yes"}
{"id":"R-002","source":"T-y","prediction":"c","observable":"d","status":"OBSERVED_FALSE","observed":"no"}
{"id":"R-003","source":"T-z","prediction":"e","observable":"f","status":"NOT_YET_DUE","trigger":"later"}
{"id":"R-004","source":"T-w","prediction":"g","observable":"h","status":"NOT_YET_DUE","trigger":"later"}
EOF

out=$(python3 "$CHK" "$S/led.jsonl" 2>&1) || true

echo "$out" | grep -q 'OBSERVED_TRUE *: *1'  && ok "counts OBSERVED_TRUE"      || bad "OBSERVED_TRUE count wrong"
echo "$out" | grep -q 'OBSERVED_FALSE *: *1' && ok "counts OBSERVED_FALSE"     || bad "OBSERVED_FALSE count wrong"
echo "$out" | grep -q 'NOT_YET_DUE *: *2'    && ok "counts NOT_YET_DUE"        || bad "NOT_YET_DUE count wrong"

# THE CENTRAL ASSERTION: untriggered rows must not be reported as satisfied.
echo "$out" | grep -qi 'NOT a pass\|not counted as satisfied\|not satisfied' \
  && ok "states plainly that NOT_YET_DUE is not a pass" \
  || bad "does not say NOT_YET_DUE is unsatisfied — a reader will count it as holding"

# A hit RATE must be over RESOLVED rows only, never over the total.
# -i: the checker prints "RESOLVED rows only" in caps. The first draft of this line grepped
# lowercase and failed on a correct implementation — a false RED, which is the cheap direction
# to be wrong in but still a bug in the test rather than the code.
echo "$out" | grep -qi 'resolved' && ok "reports a denominator of RESOLVED rows" \
                                  || bad "no resolved-row denominator — a rate over the total is misleading"

# ── malformed rows are reported, never silently skipped ──────────────────────
printf '%s\n' '{not json' >> "$S/led.jsonl"
out2=$(python3 "$CHK" "$S/led.jsonl" 2>&1) || true
echo "$out2" | grep -qi 'unparseable\|malformed\|skipped' \
  && ok "an unparseable row is REPORTED, not dropped" \
  || bad "unparseable row vanished — a ledger that silently skips is a ledger that lies"

# ── empty ledger must NOT read as success ───────────────────────────────────
: > "$S/empty.jsonl"
out3=$(python3 "$CHK" "$S/empty.jsonl" 2>&1) || true
echo "$out3" | grep -qi 'no rows\|empty' \
  && ok "an empty ledger says so rather than reporting a clean run" \
  || bad "empty ledger reported as if it had measured something"

# ── an unknown status value must not be silently bucketed ───────────────────
printf '%s\n' '{"id":"R-009","source":"T-q","prediction":"x","observable":"y","status":"PROBABLY"}' > "$S/bad.jsonl"
out4=$(python3 "$CHK" "$S/bad.jsonl" 2>&1) || true
echo "$out4" | grep -qi 'unknown status' \
  && ok "an unrecognised status is named, not bucketed" \
  || bad "unrecognised status was silently absorbed"

# ── it must REPORT, not gate: exit 0 even with OBSERVED_FALSE rows ───────────
python3 "$CHK" "$S/led.jsonl" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "exits 0 with a failed prediction present (reports, does not gate)" \
               || bad "exited $rc on a ledger containing OBSERVED_FALSE — this must not gate"

printf '\n# passed %d, failed %d\n' "$P" "$F"
[ "$F" -eq 0 ]
