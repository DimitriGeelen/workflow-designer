#!/bin/bash
# T-923 (arc-005) — teeth for "the framework is the writer".
#
# WHAT IT DEFENDS. T-882 guards a move; T-923 makes update-task.sh perform the moves
# it IS. Two things can rot quietly: the walk (a path that skips the guard, or a
# refusal that writes anyway) and the wrapper (a close that FAILS because a position
# could not be recorded, or a refusal that is swallowed). Everything here runs on
# mktemp fixtures and a temporary rendered dir; nothing touches .tasks/.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
TOOL="$ROOT/tools/instance-node.py"
LIB="$ROOT/.agentic-framework/lib/instance-position.sh"
UPD="$ROOT/.agentic-framework/agents/task-create/update-task.sh"
TPL="examples/aef-processes/rendered/task-lifecycle.bpmn"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t923.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
# T-883: every refusal is audited; a fixture refusal must not land in the live log.
export FW_INSTANCE_REFUSAL_LOG="$WORK/refusals.jsonl"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

FIX="$WORK/tasks"; mkdir -p "$FIX"
mk() { # $1 id, $2 workflow_type, $3 extra frontmatter line
    { printf -- '---\nid: %s\nname: "fixture"\nstatus: started-work\nworkflow_type: %s\n' "$1" "$2"
      [ -n "${3:-}" ] && printf '%s\n' "$3"
      printf -- 'owner: agent\n---\n\n# %s\n\n## Acceptance Criteria\n- [ ] x\n' "$1"
    } > "$FIX/$1-fixture.md"
}
reset_fixtures() {
    rm -f "$FIX"/*.md
    mk T-9961 build "current_node: frw_3_start"
    mk T-9962 build
    mk T-9963 build "current_node: frw_11_task"
    mk T-9964 inception
    mk T-9965 spike
}
run() { python3 "$TOOL" --root "$ROOT" --tasks-dir "$FIX" "$@" 2>&1; }
node_of() { grep '^current_node:' "$FIX/$1-fixture.md" | sed 's/^current_node: *//'; }
node_lines() { grep -c '^current_node:' "$FIX/$1-fixture.md"; }

# ── walk ─────────────────────────────────────────────────────────────────────
t_walk_shortest_path_hops() {
    local out; out=$(run walk T-9961 frw_4_enter); local rc=$?
    local hops; hops=$(echo "$out" | grep '^HOP ' | tr '\n' '|')
    [ $rc -eq 0 ] && [ "$hops" = "HOP frw_3_start -> agt_2_perform|HOP agt_2_perform -> frw_5_outcome|HOP frw_5_outcome -> frw_4_enter|" ] \
        && [ "$(node_of T-9961)" = "frw_4_enter" ] && [ "$(node_lines T-9961)" = 1 ] \
        && ok walk_shortest_path_hops || bad walk_shortest_path_hops "rc=$rc out=$out"
}
t_walk_no_path_refused_unchanged() {
    local out; out=$(run walk T-9963 frw_4_enter); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [[ "$out" == *"$TPL"* ]] \
        && [ "$(node_of T-9963)" = "frw_11_task" ] \
        && ok walk_no_path_refused_unchanged || bad walk_no_path_refused_unchanged "rc=$rc out=$out"
}
t_walk_from_no_position_starts_at_start() {
    local out; out=$(run walk T-9962 frw_3_start); local rc=$?
    local first; first=$(echo "$out" | grep -E '^(START|HOP) ' | head -2 | tr '\n' '|')
    [ $rc -eq 0 ] && [ "$first" = "START frw_1_task|HOP frw_1_task -> frw_2_build|" ] \
        && [ "$(run get T-9962)" = "NODE frw_3_start task-lifecycle" ] \
        && ok walk_from_no_position_starts_at_start || bad walk_from_no_position_starts_at_start "rc=$rc out=$out"
}
t_walk_inception_starts_in_containing_template() {
    local out; out=$(run walk T-9964 hum_2_decision); local rc=$?
    [ $rc -eq 0 ] && echo "$out" | grep -q '^START frw_1_inception$' \
        && [ "$(run get T-9964)" = "NODE hum_2_decision inception-lifecycle" ] \
        && ok walk_inception_starts_in_containing_template || bad walk_inception_starts_in_containing_template "rc=$rc out=$out"
}
t_walk_idempotent_no_rewrite() {
    local before; before=$(cat "$FIX/T-9961-fixture.md")
    local out; out=$(run walk T-9961 frw_3_start); local rc=$?
    [ $rc -eq 0 ] && [[ "$out" == *"already there"* ]] && [ "$(cat "$FIX/T-9961-fixture.md")" = "$before" ] \
        && ok walk_idempotent_no_rewrite || bad walk_idempotent_no_rewrite "rc=$rc out=$out"
}
t_walk_legitimacy_from_artefact() {
    # control: real artefact walks; mutant artefact (one flow removed) refuses the same walk
    local out1; out1=$(run walk T-9962 frw_3_start); local rc1=$?
    reset_fixtures
    local RD="$WORK/rendered"; mkdir -p "$RD"
    cp "$ROOT/examples/aef-processes/rendered/"*.bpmn "$RD/"
    python3 - "$RD/task-lifecycle.bpmn" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
# the element may be self-closing or paired (conditionExpression / extensionElements children)
pat=re.compile(r'<bpmn:sequenceFlow\b[^>]*sourceRef="frw_2_build"[^>]*targetRef="frw_3_start"[^>]*?(?:/>|>.*?</bpmn:sequenceFlow>)', re.S)
n=len(pat.findall(s))
if n!=1: sys.exit("flow not found once: %d" % n)
s=pat.sub('', s)
open(p,'w').write(s)
PY
    local out2; out2=$(python3 "$TOOL" --root "$ROOT" --tasks-dir "$FIX" --rendered-dir "$RD" walk T-9962 frw_3_start 2>&1); local rc2=$?
    [ $rc1 -eq 0 ] && [ $rc2 -eq 1 ] && [[ "$out2" == REFUSED-TRANSITION*"no path"* ]] && ! grep -q '^current_node:' "$FIX/T-9962-fixture.md" \
        && ok walk_legitimacy_from_artefact || bad walk_legitimacy_from_artefact "rc1=$rc1 rc2=$rc2 out2=$out2"
}

# ── transition table ─────────────────────────────────────────────────────────
t_table_names_real_nodes() {
    # shellcheck source=/dev/null
    . "$LIB"
    local a b c d e f
    a=$(fw_instance_node_for_transition captured started-work)
    b=$(fw_instance_node_for_transition issues started-work)
    c=$(fw_instance_node_for_transition started-work issues)
    d=$(fw_instance_node_for_transition started-work work-completed partial)
    e=$(fw_instance_node_for_transition started-work work-completed)
    f=$(fw_instance_node_for_transition started-work captured)
    local all_real=1 n
    for n in "$a" "$b" "$c" "$d" "$e"; do grep -q "id=\"$n\"" "$ROOT/$TPL" || all_real=0; done
    [ "$a" = frw_3_start ] && [ "$b" = agt_2_perform ] && [ "$c" = frw_4_enter ] && [ "$d" = frw_8_partial ] \
        && [ "$e" = frw_11_task ] && [ -z "$f" ] && [ $all_real -eq 1 ] \
        && ok table_names_real_nodes || bad table_names_real_nodes "a=$a b=$b c=$c d=$d e=$e f='$f' real=$all_real"
}

# ── wrapper: never fails, never hides ────────────────────────────────────────
wrap() { # $1 task $2 node ; stdout->$WORK/o stderr->$WORK/e ; echoes rc
    ( . "$LIB"; PROJECT_ROOT="$ROOT" FW_INSTANCE_TASKS_DIR="$FIX" fw_instance_walk "$1" "$2" >"$WORK/o" 2>"$WORK/e"; echo $? )
}
t_wrapper_success_prints_position() {
    local rc; rc=$(wrap T-9961 frw_4_enter)
    [ "$rc" = 0 ] && grep -q '^  position: HOP frw_3_start -> agt_2_perform' "$WORK/o" && [ ! -s "$WORK/e" ] \
        && [ "$(node_of T-9961)" = "frw_4_enter" ] \
        && ok wrapper_success_prints_position || bad wrapper_success_prints_position "rc=$rc o=$(cat "$WORK/o") e=$(cat "$WORK/e")"
}
t_wrapper_refusal_warns_never_fails() {
    local rc; rc=$(wrap T-9963 frw_4_enter)
    [ "$rc" = 0 ] && grep -q '^WARNING:' "$WORK/e" && grep -q 'REFUSED-TRANSITION' "$WORK/e" && [ ! -s "$WORK/o" ] \
        && [ "$(node_of T-9963)" = "frw_11_task" ] \
        && ok wrapper_refusal_warns_never_fails || bad wrapper_refusal_warns_never_fails "rc=$rc o=$(cat "$WORK/o") e=$(cat "$WORK/e")"
}
t_wrapper_silent_on_no_template() {
    local rc; rc=$(wrap T-9965 frw_3_start)
    [ "$rc" = 0 ] && [ ! -s "$WORK/o" ] && [ ! -s "$WORK/e" ] && ! grep -q '^current_node:' "$FIX/T-9965-fixture.md" \
        && ok wrapper_silent_on_no_template || bad wrapper_silent_on_no_template "rc=$rc o=$(cat "$WORK/o") e=$(cat "$WORK/e")"
}
t_wrapper_silent_when_tool_absent() {
    local rc; rc=$( . "$LIB"; PROJECT_ROOT="$ROOT" FW_INSTANCE_TOOL="$WORK/does-not-exist.py" FW_INSTANCE_TASKS_DIR="$FIX" fw_instance_walk T-9961 frw_4_enter >"$WORK/o" 2>"$WORK/e"; echo $? )
    [ "$rc" = 0 ] && [ ! -s "$WORK/o" ] && [ ! -s "$WORK/e" ] && [ "$(node_of T-9961)" = "frw_3_start" ] \
        && ok wrapper_silent_when_tool_absent || bad wrapper_silent_when_tool_absent "rc=$rc"
}
t_wrapper_empty_node_is_noop() {
    local rc; rc=$(wrap T-9961 "")
    [ "$rc" = 0 ] && [ ! -s "$WORK/o" ] && [ ! -s "$WORK/e" ] && [ "$(node_of T-9961)" = "frw_3_start" ] \
        && ok wrapper_empty_node_is_noop || bad wrapper_empty_node_is_noop "rc=$rc"
}

# ── wiring pins ──────────────────────────────────────────────────────────────
t_wiring_pins() {
    local n; n=$(grep -c 'fw_instance_walk ' "$UPD")
    grep -qE 'source "\$FRAMEWORK_ROOT/lib/instance-position.sh".*\|\| true' "$UPD" \
        && grep -q 'command -v fw_instance_walk >/dev/null 2>&1 || fw_instance_walk() { return 0; }' "$UPD" \
        && [ "$n" -ge 7 ] && bash -n "$UPD" \
        && grep -q 'fw_instance_walk "$TASK_ID" frw_6_run' "$UPD" \
        && grep -q 'fw_instance_walk "$TASK_ID" frw_8_partial' "$UPD" \
        && [ "$(grep -c 'fw_instance_walk "$TASK_ID" frw_11_task' "$UPD")" -eq 2 ] \
        && [ "$(grep -c 'fw_instance_walk "$TASK_ID" agt_2_perform' "$UPD")" -eq 2 ] \
        && grep -q 'fw_instance_node_for_transition "$OLD_STATUS" "$NEW_STATUS"' "$UPD" \
        && ok wiring_pins || bad wiring_pins "call sites=$n"
}
t_t880_pin_still_holds() {
    test -f "$ROOT/$TPL" && grep -q 'id="frw_7_all"' "$ROOT/$TPL" && grep -q 'task-lifecycle node frw_7_all' "$UPD" \
        && ok t880_pin_still_holds || bad t880_pin_still_holds "hint or node missing"
}

CASES="t_walk_shortest_path_hops t_walk_no_path_refused_unchanged t_walk_from_no_position_starts_at_start t_walk_inception_starts_in_containing_template t_walk_idempotent_no_rewrite t_walk_legitimacy_from_artefact t_table_names_real_nodes t_wrapper_success_prints_position t_wrapper_refusal_warns_never_fails t_wrapper_silent_on_no_template t_wrapper_silent_when_tool_absent t_wrapper_empty_node_is_noop t_wiring_pins t_t880_pin_still_holds"

echo "=== T-923 teeth: the framework is the writer ==="
for c in $CASES; do reset_fixtures; $c; done
echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
