#!/bin/bash
# T-883 (arc-005 S3/B9, V7) — teeth for "the three refusals each land in the audit log".
#
# WHAT IT DEFENDS. A refusal nobody can see afterwards is the same class of defect as no
# refusal. Three legs (out-of-order advance · skipped human gateway · unmet input contract),
# each with a control that proves the LEGITIMATE counterpart writes nothing; one writer
# (instance-node.py), one reader (refusals); a write failure that never changes the refusal.
# Everything runs on mktemp fixtures and a mktemp log; the REAL log is asserted untouched.
# Under --mutation the append is disabled at MUTATION-ANCHOR refusal-audit: every "line
# appended" case must go red, every control must stay green.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="$ROOT/tools/instance-node.py"
TOOL="${T883_TOOL:-$SUBJECT}"
LIB="$ROOT/.agentic-framework/lib/instance-position.sh"
UPD="$ROOT/.agentic-framework/agents/task-create/update-task.sh"
TPL="examples/aef-processes/rendered/task-lifecycle.bpmn"
REAL_LOG="$ROOT/.context/audits/instance-refusals.jsonl"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t883.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

grep -q 'MUTATION-ANCHOR refusal-audit' "$SUBJECT" || { echo "TEETH BROKEN — mutation anchor not found in $SUBJECT."; exit 2; }

PASS=0; FAIL=0; PASSED=""; FAILED=""
ok()  { PASS=$((PASS+1)); PASSED="$PASSED $1"; printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILED="$FAILED $1"; printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

FIX="$WORK/tasks"; mkdir -p "$FIX"
LOG="$WORK/refusals.jsonl"
mk() { # $1 id, $2 workflow_type, $3 extra frontmatter line
    { printf -- '---\nid: %s\nname: "fixture"\nstatus: started-work\nworkflow_type: %s\n' "$1" "$2"
      [ -n "${3:-}" ] && printf '%s\n' "$3"
      printf -- 'owner: agent\n---\n\n# %s\n\n## Acceptance Criteria\n- [ ] x\n' "$1"
    } > "$FIX/$1-fixture.md"
}
reset_fixtures() {
    rm -f "$FIX"/*.md "$LOG"
    mk T-9971 build "current_node: frw_3_start"
    mk T-9972 build
    mk T-9973 spike
}
run() { python3 "$TOOL" --root "$ROOT" --tasks-dir "$FIX" --log "$LOG" "$@" 2>"$WORK/err"; }
node_of() { grep '^current_node:' "$FIX/$1-fixture.md" | sed 's/^current_node: *//'; }
lines() { [ -f "$1" ] && grep -c . "$1" || echo 0; }
field() { python3 -c "import json,sys; print(json.loads(open(sys.argv[1]).readlines()[int(sys.argv[2])])[sys.argv[3]])" "$1" "$2" "$3"; }
real_before=$(lines "$REAL_LOG")

# ── leg 1: out-of-order advance ──────────────────────────────────────────────
t_leg1_out_of_order_appends_line() {
    local out; out=$(run advance T-9971 frw_10_finalize); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [ "$(node_of T-9971)" = frw_3_start ] \
        && [ "$(lines "$LOG")" = 1 ] \
        && [ "$(field "$LOG" 0 case)" = out-of-order-advance ] && [ "$(field "$LOG" 0 rule)" = template-flow ] \
        && [ "$(field "$LOG" 0 node)" = frw_3_start ] && [ "$(field "$LOG" 0 target)" = frw_10_finalize ] \
        && [[ "$(field "$LOG" 0 template)" == *task-lifecycle.bpmn ]] && [ "$(field "$LOG" 0 task)" = T-9971 ] \
        && ok leg1_out_of_order_appends_line || bad leg1_out_of_order_appends_line "rc=$rc out=$out log=$(cat "$LOG" 2>/dev/null)"
}
t_leg1_control_legal_advance_appends_nothing() {
    local out; out=$(run advance T-9971 agt_2_perform); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9971)" = agt_2_perform ] && [ "$(lines "$LOG")" = 0 ] \
        && ok leg1_control_legal_advance_appends_nothing || bad leg1_control_legal_advance_appends_nothing "rc=$rc lines=$(lines "$LOG")"
}
t_line_is_json_with_all_keys() {
    run advance T-9971 frw_10_finalize >/dev/null
    local keys; keys=$(python3 -c "import json,sys; print(' '.join(json.loads(open(sys.argv[1]).readline()).keys()))" "$LOG" 2>/dev/null)
    [ "$keys" = "ts task case rule kind node target template detail actor" ] && [ "$(field "$LOG" 0 kind)" = REFUSED-TRANSITION ] \
        && [ "$(field "$LOG" 0 actor)" = cli ] \
        && ok line_is_json_with_all_keys || bad line_is_json_with_all_keys "keys='$keys'"
}
t_every_refuse_emission_appends() {
    # REFUSED-PLACED (set on a placed entity) and REFUSED (unknown node) go through the same writer.
    run set T-9971 frw_4_enter >/dev/null; local rc1=$?
    run set T-9972 not_a_node >/dev/null; local rc2=$?
    [ $rc1 -eq 1 ] && [ $rc2 -eq 1 ] && [ "$(lines "$LOG")" = 2 ] \
        && [ "$(field "$LOG" 0 rule)" = placement-one-shot ] && [ "$(field "$LOG" 1 rule)" = template-membership ] \
        && ok every_refuse_emission_appends || bad every_refuse_emission_appends "rc1=$rc1 rc2=$rc2 lines=$(lines "$LOG")"
}

# ── leg 2: skipped human gateway (framework-side, through the lib) ───────────
libcall() { ( . "$LIB"; PROJECT_ROOT="$ROOT" FW_INSTANCE_TOOL="$TOOL" FW_INSTANCE_TASKS_DIR="$FIX" FW_INSTANCE_REFUSAL_LOG="$LOG" fw_instance_refused "$@" >"$WORK/o" 2>"$WORK/e"; echo $? ); }
t_leg2_lib_records_framework_refusal() {
    local rc; rc=$(libcall T-9971 skipped-human-gateway R-033 frw_9_human "owner is human")
    [ "$rc" = 0 ] && grep -q '^  audit: REFUSAL-RECORDED T-9971 skipped-human-gateway R-033 frw_9_human' "$WORK/o" && [ ! -s "$WORK/e" ] \
        && [ "$(lines "$LOG")" = 1 ] && [ "$(field "$LOG" 0 case)" = skipped-human-gateway ] && [ "$(field "$LOG" 0 rule)" = R-033 ] \
        && [ "$(field "$LOG" 0 node)" = frw_9_human ] && [ "$(field "$LOG" 0 actor)" = framework ] \
        && [ "$(field "$LOG" 0 template)" = task-lifecycle ] \
        && ok leg2_lib_records_framework_refusal || bad leg2_lib_records_framework_refusal "rc=$rc o=$(cat "$WORK/o") e=$(cat "$WORK/e") lines=$(lines "$LOG")"
}
t_leg2_control_empty_case_is_noop() {
    local rc; rc=$(libcall T-9971 "" R-033 frw_9_human "x")
    [ "$rc" = 0 ] && [ ! -s "$WORK/o" ] && [ ! -s "$WORK/e" ] && [ "$(lines "$LOG")" = 0 ] \
        && ok leg2_control_empty_case_is_noop || bad leg2_control_empty_case_is_noop "rc=$rc lines=$(lines "$LOG")"
}
t_leg2_wiring_r033_refusal_not_bypass() {
    # the call sits between the R-033 message and its exit 1; the --skip-sovereignty branch has no call
    local blk; blk=$(awk '/^check_human_sovereignty\(\)/,/^}/' "$UPD")
    local refusal_branch; refusal_branch=$(echo "$blk" | awk '/Sovereignty gate \(R-033\)/,/exit 1/')
    local bypass_branch; bypass_branch=$(echo "$blk" | awk '/SKIP_SOVEREIGNTY.*= true/,/else/')
    echo "$refusal_branch" | grep -q 'fw_instance_refused "$TASK_ID" skipped-human-gateway R-033 frw_9_human' \
        && ! echo "$bypass_branch" | grep -q 'fw_instance_refused' \
        && ok leg2_wiring_r033_refusal_not_bypass || bad leg2_wiring_r033_refusal_not_bypass "refusal='$refusal_branch'"
}

# ── leg 3: unmet input contract (wiring pins) ────────────────────────────────
t_leg3_wiring_p010_p011_refusal_not_bypass() {
    local p010; p010=$(grep -n 'fw_instance_refused "$TASK_ID" unmet-input-contract P-010 frw_7_all' "$UPD" | cut -d: -f1)
    local p011; p011=$(grep -n 'fw_instance_refused "$TASK_ID" unmet-input-contract P-011 frw_7_all' "$UPD" | cut -d: -f1)
    [ -n "$p010" ] && [ -n "$p011" ] \
        && sed -n "$p010,$((p010+3))p" "$UPD" | grep -q 'exit 1' \
        && sed -n "$p011,$((p011+3))p" "$UPD" | grep -q 'exit 1' \
        && [ "$(grep -c 'fw_instance_refused "$TASK_ID"' "$UPD")" -eq 3 ] \
        && ! grep -B3 'fw_instance_refused "$TASK_ID" unmet-input-contract' "$UPD" | grep -q 'SKIP_' \
        && grep -q 'command -v fw_instance_refused >/dev/null 2>&1 || fw_instance_refused() { return 0; }' "$UPD" \
        && bash -n "$UPD" \
        && ok leg3_wiring_p010_p011_refusal_not_bypass || bad leg3_wiring_p010_p011_refusal_not_bypass "p010=$p010 p011=$p011"
}

# ── reader ───────────────────────────────────────────────────────────────────
t_reader_lists_and_names_rule() {
    run advance T-9971 frw_10_finalize >/dev/null
    libcall T-9972 unmet-input-contract P-010 frw_7_all "2/5 unchecked" >/dev/null
    local all; all=$(run refusals); local one; one=$(run refusals T-9972); local none; none=$(run refusals T-9973)
    [ "$(echo "$all" | grep -c '^REFUSAL ')" = 2 ] \
        && echo "$all" | grep -qE '^REFUSAL [0-9T:Z-]+ T-9971 out-of-order-advance template-flow frw_3_start -> frw_10_finalize$' \
        && [ "$(echo "$one" | grep -c '^REFUSAL ')" = 1 ] && echo "$one" | grep -qE '^REFUSAL [0-9T:Z-]+ T-9972 unmet-input-contract P-010 frw_7_all$' \
        && [ "$none" = "NO-REFUSALS T-9973" ] \
        && ok reader_lists_and_names_rule || bad reader_lists_and_names_rule "all=$all one=$one none=$none"
}
t_reader_empty_log_is_a_state() {
    local out; out=$(run refusals)
    [ "$out" = "NO-REFUSALS" ] && [ "$(lines "$LOG")" = 0 ] \
        && ok reader_empty_log_is_a_state || bad reader_empty_log_is_a_state "out=$out"
}
t_writer_refuses_line_without_rule() {
    local out; out=$(run refused T-9971 --case x --rule "" --node n); local rc=$?
    [ $rc -eq 1 ] && grep -q '^WARNING: audit line not written' "$WORK/err" && [ "$(lines "$LOG")" = 0 ] \
        && ok writer_refuses_line_without_rule || bad writer_refuses_line_without_rule "rc=$rc err=$(cat "$WORK/err")"
}

# ── never fails, never hides ─────────────────────────────────────────────────
t_unwritable_log_never_changes_the_refusal() {
    : > "$WORK/blocker"   # a FILE where the log's parent dir would have to be
    local out; out=$(python3 "$TOOL" --root "$ROOT" --tasks-dir "$FIX" --log "$WORK/blocker/sub/log.jsonl" advance T-9971 frw_10_finalize 2>"$WORK/err"); local rc=$?
    local rc2; rc2=$( . "$LIB"; PROJECT_ROOT="$ROOT" FW_INSTANCE_TOOL="$TOOL" FW_INSTANCE_TASKS_DIR="$FIX" FW_INSTANCE_REFUSAL_LOG="$WORK/blocker/sub/log.jsonl" fw_instance_refused T-9971 skipped-human-gateway R-033 frw_9_human x >"$WORK/o" 2>"$WORK/e"; echo $? )
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && grep -q '^WARNING: audit line not written' "$WORK/err" && [ "$(node_of T-9971)" = frw_3_start ] \
        && [ "$rc2" = 0 ] && grep -q '^WARNING: refusal NOT audited' "$WORK/e" && [ ! -s "$WORK/o" ] \
        && ok unwritable_log_never_changes_the_refusal || bad unwritable_log_never_changes_the_refusal "rc=$rc rc2=$rc2 out=$out err=$(cat "$WORK/err") e=$(cat "$WORK/e")"
}
t_tool_absent_is_silent() {
    local rc; rc=$( . "$LIB"; PROJECT_ROOT="$ROOT" FW_INSTANCE_TOOL="$WORK/does-not-exist.py" FW_INSTANCE_REFUSAL_LOG="$LOG" fw_instance_refused T-9971 skipped-human-gateway R-033 frw_9_human x >"$WORK/o" 2>"$WORK/e"; echo $? )
    [ "$rc" = 0 ] && [ ! -s "$WORK/o" ] && [ ! -s "$WORK/e" ] && [ "$(lines "$LOG")" = 0 ] \
        && ok tool_absent_is_silent || bad tool_absent_is_silent "rc=$rc"
}

# ── location and override ────────────────────────────────────────────────────
t_flag_wins_over_env() {
    local A="$WORK/a.jsonl" B="$WORK/b.jsonl"
    FW_INSTANCE_REFUSAL_LOG="$A" python3 "$TOOL" --root "$ROOT" --tasks-dir "$FIX" --log "$B" advance T-9971 frw_10_finalize >/dev/null 2>&1
    FW_INSTANCE_REFUSAL_LOG="$A" python3 "$TOOL" --root "$ROOT" --tasks-dir "$FIX" advance T-9971 frw_10_finalize >/dev/null 2>&1
    [ "$(lines "$B")" = 1 ] && [ "$(lines "$A")" = 1 ] \
        && ok flag_wins_over_env || bad flag_wins_over_env "a=$(lines "$A") b=$(lines "$B")"
}
t_default_location_under_root_audits() {
    # a throwaway root that carries the binding + artefacts but no .context: the tool must create the log where the framework's audits live
    local R="$WORK/root"; mkdir -p "$R/examples/aef-processes/rendered" "$R/tools"
    cp "$ROOT/examples/aef-processes/template-binding.yaml" "$R/examples/aef-processes/"
    cp "$ROOT/examples/aef-processes/rendered/"*.bpmn "$R/examples/aef-processes/rendered/"
    python3 "$TOOL" --root "$R" --tasks-dir "$FIX" advance T-9971 frw_10_finalize >/dev/null 2>&1
    [ "$(lines "$R/.context/audits/instance-refusals.jsonl")" = 1 ] \
        && ok default_location_under_root_audits || bad default_location_under_root_audits "missing $R/.context/audits/instance-refusals.jsonl"
}
t_no_node_id_in_tool_code() {
    grep -qE 'id="(frw|agt|hum)_[0-9]+_[a-z]+"' "$ROOT/$TPL" || { bad no_node_id_in_tool_code "control: artefact has no lane-prefixed id"; return; }
    local out; out=$(python3 -c "import ast,sys;t=ast.parse(open(sys.argv[1]).read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];print(ast.unparse(t))" "$SUBJECT")
    ! echo "$out" | grep -qE '\b(frw|agt|hum)_[0-9]+_[a-z]+\b' \
        && ok no_node_id_in_tool_code || bad no_node_id_in_tool_code "a node id is in the tool's code"
}
t_earlier_suites_do_not_write_real_log() {
    # T-880/T-881/T-882/T-923 (plain and --mutation) drive refusals on fixtures; since T-883 every refusal is audited, so each suite
    # must point the log at its own mktemp dir — else a test run forges live audit lines.
    local before; before=$(lines "$REAL_LOG")
    bash "$ROOT/tools/_t880-instance-node-teeth.sh" >/dev/null 2>&1
    bash "$ROOT/tools/_t880-instance-node-teeth.sh" --mutation >/dev/null 2>&1
    bash "$ROOT/tools/_t881-resolution-teeth.sh" >/dev/null 2>&1
    bash "$ROOT/tools/_t881-resolution-teeth.sh" --mutation >/dev/null 2>&1
    bash "$ROOT/tools/_t882-advance-teeth.sh" >/dev/null 2>&1
    bash "$ROOT/tools/_t882-advance-teeth.sh" --mutation >/dev/null 2>&1
    bash "$ROOT/tools/_t923-framework-writer-teeth.sh" >/dev/null 2>&1
    [ "$(lines "$REAL_LOG")" = "$before" ] \
        && ok earlier_suites_do_not_write_real_log || bad earlier_suites_do_not_write_real_log "before=$before after=$(lines "$REAL_LOG")"
}
t_real_log_untouched() {
    [ "$(lines "$REAL_LOG")" = "$real_before" ] \
        && ok real_log_untouched || bad real_log_untouched "before=$real_before after=$(lines "$REAL_LOG")"
}

# cases whose pass DEPENDS on a line being appended (must go red under the mutant)
APPEND_CASES="t_leg1_out_of_order_appends_line t_line_is_json_with_all_keys t_every_refuse_emission_appends t_leg2_lib_records_framework_refusal t_reader_lists_and_names_rule t_flag_wins_over_env t_default_location_under_root_audits"
# controls (must stay green under the mutant)
CONTROL_CASES="t_leg1_control_legal_advance_appends_nothing t_leg2_control_empty_case_is_noop t_leg2_wiring_r033_refusal_not_bypass t_leg3_wiring_p010_p011_refusal_not_bypass t_reader_empty_log_is_a_state t_writer_refuses_line_without_rule t_tool_absent_is_silent t_no_node_id_in_tool_code"
# ordering-sensitive (the never-fail case does not depend on the append succeeding; real_log last)
OTHER_CASES="t_unwritable_log_never_changes_the_refusal"

run_all() { for c in $APPEND_CASES $CONTROL_CASES $OTHER_CASES; do reset_fixtures; $c; done; [ "${TOOL}" = "$SUBJECT" ] && t_earlier_suites_do_not_write_real_log; t_real_log_untouched; }

# ── mutation ─────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--mutation" ]; then
    MUT="$WORK/instance-node.mutant.py"
    python3 - "$SUBJECT" "$MUT" <<'PY'
import sys
src=open(sys.argv[1]).read()
anchor='# MUTATION-ANCHOR refusal-audit'
i=src.find(anchor)
if i<0: sys.exit("mutation anchor not found")
j=src.find('written = _append_line(path, row)', i)
if j<0: sys.exit("append call not found after anchor")
src=src[:j]+'written = True  # MUTANT: append disabled'+src[j+len('written = _append_line(path, row)'):]
open(sys.argv[2],'w').write(src)
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    cmp -s "$SUBJECT" "$MUT" && { echo "MUTATION SETUP FAILED: mutant identical to subject"; exit 1; }
    grep -q 'MUTANT: append disabled' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-883 MUTATION RUN (the audit append is disabled; refusals still refuse, nothing lands) ==="
    TOOL="$MUT"
    run_all
    echo
    broken=""; for c in $CONTROL_CASES; do echo " $PASSED " | grep -q " ${c#t_} " || broken="$broken ${c#t_}"; done
    [ -n "$broken" ] && { echo "MUTATION SETUP BROKEN — controls failed under the mutant:$broken"; exit 1; }
    survivors=""; for c in $APPEND_CASES; do echo " $PASSED " | grep -q " ${c#t_} " && survivors="$survivors ${c#t_}"; done
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against a writer that writes nothing:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every append case went red."
    exit 0
fi

echo "=== T-883 teeth: the three refusals land in the audit log ==="
run_all
echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
