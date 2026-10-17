#!/bin/bash
# T-1160 (OBS-437) — teeth for the closed-record guard and the read-only successors verb.
#
# WHAT IT DEFENDS. On 2026-09-29, with focus on T-882, `instance-node.py advance T-880 frw_7_all`
# rewrote current_node in the COMPLETED record of T-880 and nothing refused it: the PreToolUse gate
# judges the focused task, not the file written. The tool now guards its own writes: a record in a
# completed/ tasks directory may move only onto an end event (REFUSED-CLOSED otherwise, audited).
# Under --mutation the archive test is disabled and every refusal case must go red.
#
# CONTROLS RUN FIRST and must hold under the mutant: the framework's own close (walk a completed/
# record to frw_end_task, through intermediate nodes) still lands; a partial-complete record
# (status work-completed, still in active/) still walks to frw_4_partial; an active record still
# advances; `successors` lists the legal hops, the startEvent from NO-POSITION, none past an end
# event, flags a closed record, and writes nothing — not the record, not the audit log.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/tools/instance-node.py}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t1160.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
# T-883: every refusal is audited; a fixture refusal must not land in the live log.
export FW_INSTANCE_REFUSAL_LOG="$WORK/refusals.jsonl"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'MUTATION-ANCHOR closed-check' "$SUBJECT" || {
    echo "TEETH BROKEN — mutation anchor not found in $SUBJECT."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }

ACT="$WORK/active"; DONE="$WORK/completed"; mkdir -p "$ACT" "$DONE"
mk() { # $1 dir, $2 id, $3 status, $4 current_node ('' = none)
    { printf -- '---\nid: %s\nname: "fixture"\nstatus: %s\nworkflow_type: build\n' "$2" "$3"
      [ -n "$4" ] && printf 'current_node: %s\n' "$4"
      printf -- 'owner: agent\n---\n\n# %s\n' "$2"
    } > "$1/$2-fixture.md"
}
reset_fixtures() {
    rm -f "$ACT"/*.md "$DONE"/*.md "$FW_INSTANCE_REFUSAL_LOG"
    mk "$DONE" T-9961 work-completed frw_3_run        # closed, about to be walked to its end
    mk "$ACT"  T-9962 work-completed frw_3_run        # partial-complete: work-completed, still active/
    mk "$ACT"  T-9963 started-work   frw_gw_outcome   # live, at a gateway
    mk "$DONE" T-9964 work-completed frw_gw_outcome   # closed, at a gateway (OBS-437's shape)
    mk "$DONE" T-9965 work-completed frw_1_start      # closed, early in the flow
    mk "$DONE" T-9966 work-completed ''               # closed, never positioned
    mk "$ACT"  T-9967 started-work   ''               # live, never positioned
    mk "$ACT"  T-9968 work-completed frw_end_task     # at the end
}
run() { python3 "$SUBJECT" --root "$ROOT" --tasks-dir "$ACT" --tasks-dir "$DONE" "$@" 2>&1; }
file_of() { ls "$ACT/$1-fixture.md" "$DONE/$1-fixture.md" 2>/dev/null | head -1; }
node_of() { grep '^current_node:' "$(file_of "$1")" | sed 's/^current_node: *//'; }
audit_lines() { [ -f "$FW_INSTANCE_REFUSAL_LOG" ] && wc -l < "$FW_INSTANCE_REFUSAL_LOG" || echo 0; }

# ── controls (must hold under the mutant too) ────────────────────────────────
c_close_walk_to_end_lands() {
    local out; out=$(run walk T-9961 frw_end_task); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9961)" = "frw_end_task" ] && echo "$out" | grep -q '^HOP ' \
        && ok close_walk_to_end_lands || bad close_walk_to_end_lands "rc=$rc out=$out"
}
c_partial_complete_walks_on() {
    local out; out=$(run walk T-9962 frw_4_partial); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9962)" = "frw_4_partial" ] \
        && ok partial_complete_walks_on || bad partial_complete_walks_on "rc=$rc out=$out"
}
c_active_advance_unaffected() {
    local out; out=$(run advance T-9963 frw_2_enter); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9963)" = "frw_2_enter" ] \
        && ok active_advance_unaffected || bad active_advance_unaffected "rc=$rc out=$out"
}
c_successors_lists_legal_hops() {
    local out; out=$(run successors T-9963); local rc=$?
    [ $rc -eq 0 ] && echo "$out" | grep -q '^SUCCESSORS frw_gw_outcome task-lifecycle: .*frw_2_enter' \
        && echo "$out" | grep -q 'agt_3_request' \
        && ok successors_lists_legal_hops || bad successors_lists_legal_hops "rc=$rc out=$out"
}
c_successors_agrees_with_advance() {
    # every hop successors names, advance accepts (the verb answers the question advance would)
    local hop rc out bad_hops=""
    for hop in $(run successors T-9963 | sed -n 's/^SUCCESSORS frw_gw_outcome task-lifecycle: //p' | tr ',' ' '); do
        reset_fixtures; out=$(run advance T-9963 "$hop"); rc=$?
        [ $rc -eq 0 ] || bad_hops="$bad_hops $hop(rc=$rc)"
    done
    [ -z "$bad_hops" ] && ok successors_agrees_with_advance || bad successors_agrees_with_advance "refused:$bad_hops"
}
c_successors_no_position_is_start() {
    local out; out=$(run successors T-9967); local rc=$?
    [ $rc -eq 0 ] && echo "$out" | grep -q '^SUCCESSORS NO-POSITION task-lifecycle: frw_start_task (startEvent)$' \
        && ok successors_no_position_is_start || bad successors_no_position_is_start "rc=$rc out=$out"
}
c_successors_end_has_none() {
    local out; out=$(run successors T-9968); local rc=$?
    [ $rc -eq 0 ] && echo "$out" | grep -q '^SUCCESSORS frw_end_task task-lifecycle: (none' \
        && ok successors_end_has_none || bad successors_end_has_none "rc=$rc out=$out"
}
c_successors_flags_closed() {
    local out; out=$(run successors T-9964); local rc=$?
    [ $rc -eq 0 ] && echo "$out" | grep -q '^CLOSED .*T-9964-fixture.md: only an end event is accepted (.*frw_end_task' \
        && ok successors_flags_closed || bad successors_flags_closed "rc=$rc out=$out"
}
c_successors_writes_nothing() {
    local before after; before=$(cat "$ACT"/*.md "$DONE"/*.md | sha256sum)
    run successors T-9963 >/dev/null; run successors T-9964 >/dev/null; run successors T-9966 >/dev/null
    after=$(cat "$ACT"/*.md "$DONE"/*.md | sha256sum)
    [ "$before" = "$after" ] && [ "$(audit_lines)" = 0 ] \
        && ok successors_writes_nothing || bad successors_writes_nothing "records or audit log changed (audit=$(audit_lines))"
}
CONTROL_CASES="c_close_walk_to_end_lands c_partial_complete_walks_on c_active_advance_unaffected c_successors_lists_legal_hops c_successors_agrees_with_advance c_successors_no_position_is_start c_successors_end_has_none c_successors_flags_closed c_successors_writes_nothing"

# ── gate cases (must go red under the mutant) ────────────────────────────────
g_closed_advance_refused() {
    # frw_gw_outcome -> frw_2_enter IS a sequenceFlow: only the archive guard can refuse it
    local before; before=$(cat "$(file_of T-9964)")
    local out; out=$(run advance T-9964 frw_2_enter); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-CLOSED* ]] && [ "$(cat "$(file_of T-9964)")" = "$before" ] \
        && [ "$(audit_lines)" = 1 ] && grep -q '"case": "closed-record"' "$FW_INSTANCE_REFUSAL_LOG" \
        && ok closed_advance_refused || bad closed_advance_refused "rc=$rc audit=$(audit_lines) out=$out"
}
g_closed_walk_off_end_refused() {
    local out; out=$(run walk T-9965 agt_2_perform); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-CLOSED* ]] && [ "$(node_of T-9965)" = "frw_1_start" ] \
        && ok closed_walk_off_end_refused || bad closed_walk_off_end_refused "rc=$rc out=$out"
}
g_closed_set_refused() {
    local out; out=$(run set T-9966 frw_3_run); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-CLOSED* ]] && ! grep -q '^current_node:' "$(file_of T-9966)" \
        && ok closed_set_refused || bad closed_set_refused "rc=$rc out=$out"
}
GATE_CASES="g_closed_advance_refused g_closed_walk_off_end_refused g_closed_set_refused"

run_suite() {
    for c in $CONTROL_CASES; do reset_fixtures; $c; done
    for c in $GATE_CASES;    do reset_fixtures; $c; done
}

# ── mutation ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--mutation" ]; then
    MUT="$WORK/instance-node.mutant.py"
    python3 - "$SUBJECT" "$MUT" <<'PY'
import sys
src=open(sys.argv[1]).read()
anchor='# MUTATION-ANCHOR closed-check'
i=src.find(anchor)
if i<0: sys.exit("mutation anchor not found")
probe='if not _is_closed_record(path):'
j=src.find(probe, i)
if j<0: sys.exit("archive test not found after anchor")
open(sys.argv[2],'w').write(src[:j]+'if True:  # MUTANT: archive test disabled'+src[j+len(probe):])
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    cmp -s "$SUBJECT" "$MUT" && { echo "MUTATION SETUP FAILED: mutant identical to subject"; exit 1; }
    grep -q 'MUTANT: archive test disabled' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-1160 MUTATION RUN (closed records accept any move) ==="
    out=$(SUBJECT="$MUT" bash "$0" 2>&1)
    echo "$out" | sed 's/^/  | /'
    broken=""
    for c in $CONTROL_CASES; do
        name=${c#c_}
        echo "$out" | grep -q "^  PASS  $name\$" || broken="$broken $name"
    done
    [ -n "$broken" ] && { echo "MUTATION SETUP BROKEN — controls failed under the mutant:$broken"; exit 1; }
    survivors=""
    for c in $GATE_CASES; do
        name=${c#g_}
        echo "$out" | grep -q "^  FAIL  $name\$" || survivors="$survivors $name"
    done
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against a guard that refuses nothing:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every refusal case went red."
    exit 0
fi

echo "=== T-1160 teeth: closed-record guard + successors (subject: ${SUBJECT#$ROOT/}) ==="
run_suite
echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
bash "$0" --mutation | tail -1
