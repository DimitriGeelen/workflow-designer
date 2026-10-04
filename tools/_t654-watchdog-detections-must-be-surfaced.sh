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
# RE-ANCHORED (T-1039) for the vendored framework 1.7.740. The original 832 fix was an
# audit "Check 1b" that scanned the log directory for NOT REACHED records. Upstream has no
# Check 1b: it surfaces the same consequence structurally. A completed task with no
# episodic summary is flagged by audit Check 1 ("Completed task X has no episodic
# summary", fed by agents/audit/completed-task-scan.py -> missing_episodic), and the
# watchdog itself now prints the failure and the recovery command to stderr as well as to
# the log. So the protected behaviour is, in two links:
#
#   LINK 1  the watchdog (update-task.sh _t522_completion_watchdog) turns a silent abort
#           into a loud one: a log record with task/exit code AND an ERROR on stderr that
#           names the recovery command; and stays quiet on a designed skip.
#   LINK 2  the consequence of an unrecovered abort — a completed task with no episodic —
#           reaches the audit: the scan lists it, the audit warns with the recovery hint,
#           and a recovered task goes quiet.
#
# WHAT IT MUST NOT DO: retype the code under test. It extracts the REAL watchdog function
# from update-task.sh and runs the REAL scan script, both against a scratch directory, so
# a rewrite is reported rather than silently skipped. It never reads or writes the
# project's own .context/working/episodic-gen/ or .tasks/.
#
# TEETH. Each link is mutated in a scratch copy (stderr surface removed; log write removed;
# scan append removed) and the matching leg must go RED. A mutation that does not land
# is a failure, not a skip.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T654_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
UPD="$PROJ/.agentic-framework/agents/task-create/update-task.sh"
AUD="$PROJ/.agentic-framework/agents/audit/audit.sh"
SCAN="$PROJ/.agentic-framework/agents/audit/completed-task-scan.py"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

for f in "$UPD" "$AUD" "$SCAN"; do
    [ -f "$f" ] || { echo "COULD-NOT-MEASURE: $f not found" >&2; exit 3; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-654: unrecovered completion-watchdog detections must surface ==="
echo

# --- extract the real watchdog function -----------------------------------------------
FUNC="$TMP/watchdog.sh"
python3 - "$UPD" > "$FUNC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n_t522_completion_watchdog\(\) \{\n.*?\n\}\n", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: _t522_completion_watchdog not found in update-task.sh\n")
    sys.exit(3)
sys.stdout.write(m.group(0))
PY
rc=$?
[ "$rc" -eq 0 ] && [ -s "$FUNC" ] || { echo "COULD-NOT-MEASURE: could not extract the watchdog" >&2; exit 3; }
bash -n "$FUNC" || { echo "COULD-NOT-MEASURE: extracted watchdog does not parse" >&2; exit 3; }

# The trap must actually be wired to call it with the exit code, or the function is dead code.
if grep -qE "^trap '.*_t522_completion_watchdog \"\\\$_t522_rc\"" "$UPD"; then
    ok "the EXIT trap calls the watchdog with the script's exit code"
else
    bad "no EXIT trap calls _t522_completion_watchdog — the detector is not wired"
fi
# ...and the phase must be set to 'started' somewhere, or the guard never lets it fire.
if grep -q '_T522_COMPLETION_PHASE="started"' "$UPD"; then
    ok "the completion transition arms the watchdog (phase=started)"
else
    bad "nothing sets _T522_COMPLETION_PHASE=started — the watchdog can never fire"
fi

# run_wd <func-file> <phase> <partial> <rc> -> sets ERRTXT (stderr) and LOGFILE
reset_fixture() {
    rm -rf "$TMP/proj"
    mkdir -p "$TMP/proj/.context/working"
}
run_wd() {
    local func="$1" phase="$2" partial="$3" code="$4"
    reset_fixture
    ERRTXT=$(
        (
            set +u
            PROJECT_ROOT="$TMP/proj"; CONTEXT_DIR="$TMP/proj/.context"; TASK_ID=T-8002
            _T522_COMPLETION_PHASE="$phase"; PARTIAL_COMPLETE="$partial"
            RED=""; NC=""
            . "$func"
            _t522_completion_watchdog "$code"
        ) 2>&1 >/dev/null
    )
    LOGFILE="$TMP/proj/.context/working/episodic-gen/T-8002.log"
}

echo "--- LINK 1: an aborted completion is loud, and says how to recover"
run_wd "$FUNC" started false 7
MISSING=""
[ -f "$LOGFILE" ] && grep -q 'episodic-gen NOT REACHED' "$LOGFILE"    || MISSING="$MISSING log-record"
[ -f "$LOGFILE" ] && grep -q 'task_id: T-8002' "$LOGFILE"             || MISSING="$MISSING log-task-id"
[ -f "$LOGFILE" ] && grep -q 'script_exit_code: 7' "$LOGFILE"         || MISSING="$MISSING log-exit-code"
printf '%s' "$ERRTXT" | grep -q 'episodic generation was never reached for T-8002' || MISSING="$MISSING stderr-error"
printf '%s' "$ERRTXT" | grep -q 'generate-episodic T-8002'            || MISSING="$MISSING stderr-recovery-command"
if [ -z "$MISSING" ]; then
    ok "log record (task, exit code) AND a stderr ERROR naming the recovery command"
else
    bad "detection not surfaced; missing:$MISSING | stderr: $(printf '%s' "$ERRTXT" | tr '\n' ' ' | head -c 200)"
fi

echo "--- a designed skip or a normal exit stays quiet"
run_wd "$FUNC" "" false 0
if [ ! -f "$LOGFILE" ] && [ -z "$ERRTXT" ]; then ok "phase not started: no record, no noise"; else bad "fired with no completion in flight"; fi
run_wd "$FUNC" episodic false 0
if [ ! -f "$LOGFILE" ] && [ -z "$ERRTXT" ]; then ok "episodic block reached: no record, no noise"; else bad "fired after the episodic block was reached"; fi
run_wd "$FUNC" started true 0
if [ ! -f "$LOGFILE" ] && [ -z "$ERRTXT" ]; then ok "partial-complete (designed skip): no record, no noise"; else bad "fired on a designed partial-complete skip"; fi

echo "--- LINK 2: the unrecovered consequence reaches the audit"
mk_tasks() {  # <with-episodic: yes|no>
    rm -rf "$TMP/t"; mkdir -p "$TMP/t/tasks/completed" "$TMP/t/episodic" "$TMP/t/reports"
    cat > "$TMP/t/tasks/completed/T-8002-fixture.md" <<'MD'
---
id: T-8002
name: "fixture"
status: work-completed
workflow_type: build
owner: agent
horizon:
created: 2026-08-22T00:00:00Z
last_update: 2026-08-22T00:00:00Z
date_finished: 2026-08-22T00:00:00Z
---

# T-8002

## Acceptance Criteria
- [x] done

## Verification
MD
    [ "$1" = yes ] && printf 'task_id: T-8002\n' > "$TMP/t/episodic/T-8002.yaml"
    return 0
}
missing_of() {  # <scan-script> -> comma list of missing_episodic
    python3 "$1" "$TMP/t/tasks" "$TMP/t/episodic" "$TMP/t/reports" 2>/dev/null \
        | python3 -c "import sys,json; print(','.join(json.load(sys.stdin).get('missing_episodic',[])))" 2>/dev/null
}
mk_tasks no
GOT=$(missing_of "$SCAN")
if [ "$GOT" = "T-8002" ]; then ok "a completed task with no episodic is listed in missing_episodic"; else bad "scan did not list it (got '$GOT')"; fi
mk_tasks yes
GOT=$(missing_of "$SCAN")
if [ -z "$GOT" ]; then ok "the same task, once recovered, goes quiet"; else bad "a recovered task is still listed (got '$GOT')"; fi

# The audit must turn that list into a warning that carries the recovery command.
if grep -q 'Completed task \$task_id has no episodic summary' "$AUD" \
   && grep -q "get('missing_episodic'" "$AUD" \
   && grep -q 'generate-episodic \$task_id' "$AUD"; then
    ok "audit Check 1 warns per missing episodic and names generate-episodic"
else
    bad "audit.sh no longer warns on a completed task with no episodic summary (or lost its recovery hint)"
fi

echo "--- teeth: remove each surface and its leg must go red"
# (a) strip the stderr surface (ERROR + Recover lines) from the watchdog
sed -e '/echo -e "\${RED:-}ERROR: episodic generation was never reached/d' \
    -e '/echo -e "  Recover:/d' "$FUNC" > "$TMP/wd-nostderr.sh"
if cmp -s "$FUNC" "$TMP/wd-nostderr.sh" || ! bash -n "$TMP/wd-nostderr.sh"; then
    bad "MUTATION FAILED (stderr surface) — this leg proves nothing"
else
    run_wd "$TMP/wd-nostderr.sh" started false 7
    if ! printf '%s' "$ERRTXT" | grep -q 'generate-episodic T-8002' && [ -f "$LOGFILE" ]; then
        ok "mutant without the stderr surface: log only, nothing loud — LINK 1 would be RED"
    else
        bad "mutant without the stderr surface still looks surfaced — the leg cannot fail"
    fi
fi
# (b) strip the log write (the >> "$log" redirect group) from the watchdog
python3 - "$FUNC" > "$TMP/wd-nolog.sh" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
n = re.subn(r'\n    \{\n        echo "=== episodic-gen NOT REACHED.*?\n    \} >> "\$log" 2>&1\n', '\n', s, flags=re.S)
sys.stdout.write(n[0])
sys.exit(0 if n[1] == 1 else 1)
PY
if [ $? -ne 0 ] || ! bash -n "$TMP/wd-nolog.sh"; then
    bad "MUTATION FAILED (log write) — this leg proves nothing"
else
    run_wd "$TMP/wd-nolog.sh" started false 7
    if [ ! -f "$LOGFILE" ]; then
        ok "mutant without the log write: no record on disk — the log legs would be RED"
    else
        bad "mutant without the log write still wrote a record"
    fi
fi
# (c) strip the scan's missing-episodic append
sed 's|^\( *\)missing_episodic.append(task_id)|\1pass  # neutralised|' "$SCAN" > "$TMP/scan-mutant.py"
if ! grep -q 'neutralised' "$TMP/scan-mutant.py"; then
    bad "MUTATION FAILED (scan append) — this leg proves nothing"
else
    mk_tasks no
    GOT=$(missing_of "$TMP/scan-mutant.py")
    if [ -z "$GOT" ]; then
        ok "mutant scan misses a completed task with no episodic — the 'listed' leg would be RED"
    else
        bad "mutant scan still lists it — the leg cannot fail"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
