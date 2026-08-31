#!/usr/bin/env bash
# T-654 — a detection that reaches only a log file is not a detection.
#
# WHY THIS EXISTS. update-task.sh's T-522 EXIT trap catches the case where a
# work-completed transition began but execution left the script before the episodic
# stage. It fired twice in this project's history (T-542 and T-574, both 2026-08-22),
# wrote a correct diagnosis and the exact recovery command to
# .context/working/episodic-gen/<task>.log — and both sat unrecovered for nine days
# across twelve audits. The detector was never the weak part. Its delivery was.
#
# audit.sh Check 1b (T-654) closes that loop. This prober is its regression witness.
#
# WHAT IT MUST NOT DO: it must not retype the check. It greps the real block out of
# audit.sh and executes THAT against a scratch directory, so a rewrite is reported
# rather than silently skipped. It never reads or writes the project's own
# .context/working/episodic-gen/.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T654_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/audit/audit.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-654: unrecovered completion-watchdog detections must surface in the audit ==="
echo

extract_check() {
    python3 - "$SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n# Check 1b: the T-522 completion watchdog.*?\n    fi\nfi\n", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: Check 1b block not found in audit.sh\n")
    sys.exit(3)
sys.stdout.write(m.group(0))
PY
}
CHECK="$TMP/check.sh"
extract_check > "$CHECK" || exit 3
[ -s "$CHECK" ] || { echo "COULD-NOT-MEASURE: extracted block was empty" >&2; exit 3; }

# Harness: stub pass/warn/fail so the verdict is machine-readable, then run the REAL block.
# run <check-file> -> the verdict lines it produced
run_check() {
    local check="$1"
    (
        set +u
        CONTEXT_DIR="$TMP/ctx"
        episodic_dir="$TMP/ctx/episodic"
        pass() { echo "PASS::$1"; }
        warn() { echo "WARN::$1::${2:-}::${3:-}"; }
        fail() { echo "FAIL::$1"; }
        . "$check"
    ) 2>&1
}

reset_fixture() {
    rm -rf "$TMP/ctx"
    mkdir -p "$TMP/ctx/working/episodic-gen" "$TMP/ctx/episodic"
}

write_notreached_log() {
    local task="$1" when="$2"
    cat > "$TMP/ctx/working/episodic-gen/${task}.log" <<EOF
=== episodic-gen NOT REACHED: $when ===
task_id: $task
detected_by: T-522 completion watchdog (EXIT trap)
script_exit_code: 0
EOF
}

# ---------------------------------------------------------------------------
echo "--- no detections on record: says so, does not warn"
reset_fixture
OUT=$(run_check "$CHECK")
if echo "$OUT" | grep -q '^PASS::Completion watchdog: no aborted completions'; then
    ok "empty log dir: pass, no warning"
else
    bad "empty log dir produced: $(echo "$OUT" | head -2 | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
echo "--- an ordinary invocation log is not a detection"
reset_fixture
printf '=== episodic-gen invocation: 2026-08-31T00:00:00Z ===\nall good\n' \
    > "$TMP/ctx/working/episodic-gen/T-8001.log"
OUT=$(run_check "$CHECK")
if echo "$OUT" | grep -q '^PASS::Completion watchdog: no aborted completions'; then
    ok "a log without 'NOT REACHED' is ignored — the check keys on the detection, not the file"
else
    bad "an ordinary invocation log was counted: $(echo "$OUT" | head -2 | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
echo "--- a detection whose episodic was never generated: WARNS, and says which and when"
reset_fixture
write_notreached_log T-8002 2026-08-22T09:58:01Z
OUT=$(run_check "$CHECK")
MISSING=""
echo "$OUT" | grep -q '^WARN::'                        || MISSING="$MISSING not-a-warn"
echo "$OUT" | grep -q 'T-8002'                         || MISSING="$MISSING the-task-id"
echo "$OUT" | grep -q '2026-08-22T09:58:01Z'           || MISSING="$MISSING the-timestamp"
echo "$OUT" | grep -q 'generate-episodic'              || MISSING="$MISSING the-recovery-command"
if [ -z "$MISSING" ]; then
    ok "warns and is actionable (task + when it was detected + how to recover)"
else
    bad "warning incomplete:$MISSING | got: $(echo "$OUT" | tr '\n' ' ' | head -c 220)"
fi

# ---------------------------------------------------------------------------
echo "--- the SAME detection, once recovered, must go quiet"
reset_fixture
write_notreached_log T-8002 2026-08-22T09:58:01Z
printf 'task_id: T-8002\n' > "$TMP/ctx/episodic/T-8002.yaml"
OUT=$(run_check "$CHECK")
if echo "$OUT" | grep -q '^PASS::Completion watchdog: 1 detected abort' && ! echo "$OUT" | grep -q '^WARN::'; then
    ok "recovered detection: pass that still COUNTS it (history is kept, the nag is not)"
else
    bad "a recovered detection did not go quiet: $(echo "$OUT" | head -2 | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
echo "--- two detections, one recovered: only the open one is named"
reset_fixture
write_notreached_log T-8002 2026-08-22T09:58:01Z
write_notreached_log T-8003 2026-08-22T10:15:07Z
printf 'task_id: T-8002\n' > "$TMP/ctx/episodic/T-8002.yaml"
OUT=$(run_check "$CHECK")
if echo "$OUT" | grep -q 'T-8003' && ! echo "$OUT" | grep -q 'T-8002'; then
    ok "names T-8003 (open) and not T-8002 (recovered)"
else
    bad "mixed state named the wrong set: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: drop the recovered-check and the quiet leg must start warning"
MUT="$TMP/check-mutant.sh"
# Delimiter is '|', not '#': the replacement text contains a '#' and sed reads it as
# the delimiter, failing with "unknown option to `s'". Caught by this leg's own
# MUTATION FAILED guard — which is the argument for asserting that the mutation
# landed rather than assuming it did.
sed 's|^\( *\)\[ -f "$episodic_dir/${_wd_task}\.yaml" \] && continue|\1: # neutralised|' \
    "$CHECK" > "$MUT"
if ! grep -q '# neutralised' "$MUT"; then
    bad "MUTATION FAILED — could not neutralise the recovered-check; this leg proves nothing"
else
    reset_fixture
    write_notreached_log T-8002 2026-08-22T09:58:01Z
    printf 'task_id: T-8002\n' > "$TMP/ctx/episodic/T-8002.yaml"
    OUT=$(run_check "$MUT")
    if echo "$OUT" | grep -q '^WARN::'; then
        ok "mutant warns on a RECOVERED detection — the recovered-check is what produces the quiet"
    else
        bad "mutant stayed quiet too — the leg above cannot fail and proves nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
