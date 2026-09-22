#!/usr/bin/env bash
# _t813-history-trap-controls.sh — does the run-history trap fire when it matters?
#
# T-813, value review finding F-03.
#
# The whole reason the recorder is an EXIT trap rather than a line at the end of
# run-bridge-tests.sh is that the runs most worth recording are the ones a tail-of-script
# recorder drops: a red run, an interrupted run, a scheduler's timeout. A control that only
# ever drives a green run would prove none of that and would pass against the naive
# implementation this one was chosen over.
#
# So the branches are: green, RED, and INTERRUPTED. The last two are the point.
#
# Runs against a SYNTHETIC script carrying the same trap wiring, not against the real
# 742-second suite — driving the real one three times would cost 37 minutes and would make
# this control something nobody runs, which is the F-03 disease rather than its cure. The
# trap lines are extracted from the real runner at run time (never from a git ref, per the
# teeth rule that a git-ref mutant has an expiry date nothing announces), so if the wiring in
# run-bridge-tests.sh changes shape this control notices.
#
# Exit: 0 all branches recorded | 1 a branch failed to record | 3 could not set up

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$REPO/tests/run-bridge-tests.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$RUNNER" ] || cannot "runner not found: $RUNNER"

# The real runner must actually carry the wiring this control models. Without this the
# synthetic below could pass forever after someone removed the trap from the real script.
grep -q '_t813_record' "$RUNNER" || cannot \
  "run-bridge-tests.sh no longer mentions _t813_record — the recorder is gone from the real
  runner, so this control is modelling wiring that does not exist"
grep -q "trap '_t813_record" "$RUNNER" || cannot \
  "run-bridge-tests.sh no longer installs the _t813_record trap"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Synthetic runner: same trap wiring, trivial body, outcome chosen by $1.
make_runner() {
    cat > "$WORK/fake-suite.sh" <<'SCRIPT'
#!/usr/bin/env bash
set -u
ROOT="$FAKE_ROOT"
TMP="$(mktemp -d)"
pass=0
fail=0
_T813_START=$(date +%s)
_T813_HISTORY="$ROOT/tests/.run-history.tsv"
_T813_RECORDED=0
_t813_record() {
    [ "$_T813_RECORDED" = "1" ] && return 0
    _T813_RECORDED=1
    local rc=$1
    local dur=$(( $(date +%s) - _T813_START ))
    local sha
    sha=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$pass" "$fail" "$rc" "$dur" "$sha" \
        >> "$_T813_HISTORY" 2>/dev/null || true
}
trap '_t813_record "$?"; rm -rf "$TMP"' EXIT
trap '_t813_record 130; rm -rf "$TMP"; trap - INT; kill -INT $$' INT
trap '_t813_record 143; rm -rf "$TMP"; trap - TERM; kill -TERM $$' TERM

case "$1" in
  green) pass=10; fail=0 ;;
  red)   pass=3;  fail=7 ;;
  hang)  pass=5;  fail=0; sleep 8 ;;
esac
[ "$fail" -eq 0 ]
SCRIPT
    chmod +x "$WORK/fake-suite.sh"
}

reset_history() {
    rm -rf "$WORK/repo"; mkdir -p "$WORK/repo/tests"
    : > "$WORK/repo/tests/.run-history.tsv"
}

rows() { grep -c . "$WORK/repo/tests/.run-history.tsv" 2>/dev/null || echo 0; }
last()  { tail -1 "$WORK/repo/tests/.run-history.tsv" 2>/dev/null; }

make_runner

echo "=== T-813 history-trap controls ==="

# --- A: a GREEN run is recorded.
reset_history
FAKE_ROOT="$WORK/repo" bash "$WORK/fake-suite.sh" green >/dev/null 2>&1
if [ "$(rows)" = "1" ] && [ "$(last | cut -f3)" = "0" ] && [ "$(last | cut -f4)" = "0" ]; then
    ok "A green run recorded (fail=0, rc=0)"
else
    bad "A green run should be recorded" "rows=$(rows) last='$(last)'"
fi

# --- B: a RED run is recorded. The branch a green-only control would miss.
reset_history
FAKE_ROOT="$WORK/repo" bash "$WORK/fake-suite.sh" red >/dev/null 2>&1
if [ "$(rows)" = "1" ] && [ "$(last | cut -f3)" = "7" ] && [ "$(last | cut -f4)" = "1" ]; then
    ok "B RED run recorded (fail=7, rc=1) — a history of only green runs answers the wrong question"
else
    bad "B red run should be recorded with its counts" "rows=$(rows) last='$(last)'"
fi

# --- C: an INTERRUPTED run is recorded. The branch that makes the trap necessary at all.
reset_history
FAKE_ROOT="$WORK/repo" bash "$WORK/fake-suite.sh" hang >/dev/null 2>&1 &
_pid=$!
sleep 1
kill -TERM "$_pid" 2>/dev/null
# BASH DEFERS A SIGNAL UNTIL THE RUNNING FOREGROUND COMMAND RETURNS. The synthetic sleeps,
# so the handler fires when the sleep ends, not when the signal lands. That is bash, not a
# defect in the recorder, and it is benign for the real suite: its legs are seconds long, so
# a Ctrl-C or a scheduler TERM is handled at the next leg boundary. The control waits the
# command out rather than pretending the signal is instantaneous.
wait "$_pid" 2>/dev/null
# EXACTLY ONE row: the re-raise lets EXIT fire after the signal handler, and without the
# once-only guard this wrote two records per interrupted run. Measured, then fixed.
if [ "$(rows)" = "1" ] && [ "$(last | cut -f4)" = "143" ]; then
    ok "C interrupted run recorded ONCE, rc=143 — a tail-of-script recorder drops this entirely"
else
    bad "C interrupted run should be recorded exactly once with rc=143" "rows=$(rows) last='$(last)'"
fi

# --- D: records ACCUMULATE. An append that silently truncates would pass A/B/C.
reset_history
for _ in 1 2 3; do
    FAKE_ROOT="$WORK/repo" bash "$WORK/fake-suite.sh" green >/dev/null 2>&1
done
if [ "$(rows)" = "3" ]; then
    ok "D three runs append three records (history accumulates, not overwrites)"
else
    bad "D history should accumulate" "expected 3 rows, got $(rows)"
fi

# --- E: the reader must call an EMPTY history could-not-measure, never green.
reset_history
if T813_REPO_ROOT="$WORK/repo" python3 "$REPO/tools/_t813-suite-age.py" >/dev/null 2>&1; then
    bad "E empty history should NOT exit 0" "the reader reported success over zero records"
else
    _rc=$?
    if [ "$_rc" -eq 3 ]; then
        ok "E empty history -> exit 3 (could-not-measure, not 'green')"
    else
        bad "E empty history should exit 3" "got $_rc"
    fi
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
