#!/bin/bash
# T-882 (arc-005 S3) — teeth for the guarded advance.
#
# WHAT IT DEFENDS. T-880 records a position; T-882 is the first thing in G4 that can
# REFUSE. A recorded position may move only along a sequenceFlow the template of
# record carries, read from the artefact — an advance that only ever succeeds
# demonstrates no guard. So the GATE cases are the refusals: out of order, backwards,
# past an end event, two hops through a gateway, across templates. Under --mutation
# the successor check is disabled and every one of them must go red.
#
# CONTROLS RUN FIRST and must hold under the mutant: legal hops are recorded, either
# branch of an exclusive gateway is legal, a first hop lands on the start event, an
# inception moves inside inception-lifecycle, `set` still places a pre-existing
# entity (backfill) and refuses to re-place one (REFUSED-PLACED), and the three
# absence states keep their exit codes. The NO-POSITION start rule and REFUSED-PLACED
# are guards too, but they live on paths the mutant does not touch — listed with the
# controls on purpose (the same classification T-880 records for its stale reader).

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/tools/instance-node.py}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t882.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'MUTATION-ANCHOR successor-check' "$SUBJECT" || {
    echo "TEETH BROKEN — mutation anchor not found in $SUBJECT."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }

TPL="examples/aef-processes/rendered/task-lifecycle.bpmn"
FIX="$WORK/tasks"; mkdir -p "$FIX"
mk() { # $1 id, $2 workflow_type, $3 extra frontmatter line
    { printf -- '---\nid: %s\nname: "fixture"\nstatus: started-work\nworkflow_type: %s\n' "$1" "$2"
      [ -n "${3:-}" ] && printf '%s\n' "$3"
      printf -- 'owner: agent\n---\n\n# %s\n\n## Acceptance Criteria\n- [ ] x\n' "$1"
    } > "$FIX/$1-fixture.md"
}
reset_fixtures() {
    rm -f "$FIX"/*.md
    mk T-9971 build "current_node: frw_3_start"
    mk T-9972 build
    mk T-9973 build "current_node: frw_11_task"
    mk T-9974 build "current_node: frw_5_outcome"
    mk T-9975 inception "current_node: hum_1_record"
    mk T-9976 inception "current_node: hum_2_decision"
    mk T-9977 build "current_node: agt_2_perform"
    mk T-9978 spike
}
run() { python3 "$SUBJECT" --root "$ROOT" --tasks-dir "$FIX" "$@" 2>&1; }
node_of() { grep '^current_node:' "$FIX/$1-fixture.md" | sed 's/^current_node: *//'; }
node_lines() { grep -c '^current_node:' "$FIX/$1-fixture.md"; }

# ── controls (must hold under the mutant too) ────────────────────────────────
c_legal_transition_recorded() {
    local out; out=$(run advance T-9971 agt_2_perform); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9971)" = "agt_2_perform" ] && [ "$(node_lines T-9971)" = 1 ] \
        && [ "$(run get T-9971)" = "NODE agt_2_perform task-lifecycle" ] \
        && ok legal_transition_recorded || bad legal_transition_recorded "rc=$rc out=$out"
}
c_gateway_branch_a_legal() {
    local out; out=$(run advance T-9974 frw_4_enter); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9974)" = "frw_4_enter" ] \
        && ok gateway_branch_a_legal || bad gateway_branch_a_legal "rc=$rc out=$out"
}
c_gateway_branch_b_legal() {
    local out; out=$(run advance T-9974 agt_3_request); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9974)" = "agt_3_request" ] \
        && ok gateway_branch_b_legal || bad gateway_branch_b_legal "rc=$rc out=$out"
}
c_first_hop_onto_start() {
    local out; out=$(run advance T-9972 frw_1_task); local rc=$?
    [ $rc -eq 0 ] && [ "$(run get T-9972)" = "NODE frw_1_task task-lifecycle" ] \
        && ok first_hop_onto_start || bad first_hop_onto_start "rc=$rc out=$out"
}
c_first_hop_mid_flow_refused_names_start() {
    local out; out=$(run advance T-9972 frw_3_start); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [[ "$out" == *frw_1_task* ]] \
        && ! grep -q '^current_node:' "$FIX/T-9972-fixture.md" \
        && ok first_hop_mid_flow_refused_names_start || bad first_hop_mid_flow_refused_names_start "rc=$rc out=$out"
}
c_inception_moves_within_template() {
    local out; out=$(run advance T-9975 hum_2_decision); local rc=$?
    [ $rc -eq 0 ] && [ "$(run get T-9975)" = "NODE hum_2_decision inception-lifecycle" ] \
        && ok inception_moves_within_template || bad inception_moves_within_template "rc=$rc out=$out"
}
c_set_places_from_no_position() {
    local out; out=$(run set T-9972 frw_6_run); local rc=$?
    [ $rc -eq 0 ] && [ "$(node_of T-9972)" = "frw_6_run" ] \
        && ok set_places_from_no_position || bad set_places_from_no_position "rc=$rc out=$out"
}
c_set_refused_once_placed() {
    local out; out=$(run set T-9971 frw_10_finalize); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-PLACED* ]] && [[ "$out" == *advance* ]] \
        && [ "$(node_of T-9971)" = "frw_3_start" ] && [ "$(node_lines T-9971)" = 1 ] \
        && ok set_refused_once_placed || bad set_refused_once_placed "rc=$rc out=$out"
}
c_no_entity_distinct() {
    local out; out=$(run advance T-9999 frw_1_task); local rc=$?
    [ $rc -eq 2 ] && [ "$out" = "NO-ENTITY T-9999" ] \
        && ok no_entity_distinct || bad no_entity_distinct "rc=$rc out=$out"
}
c_no_template_distinct() {
    local out; out=$(run advance T-9978 frw_1_task); local rc=$?
    [ $rc -eq 3 ] && [[ "$out" == NO-TEMPLATE\ spike* ]] && ! grep -q '^current_node:' "$FIX/T-9978-fixture.md" \
        && ok no_template_distinct || bad no_template_distinct "rc=$rc out=$out"
}
c_flows_come_from_the_artefact() {
    # The artefact carries the flow the legal hop used; the tool's code carries no node id.
    grep -q 'sourceRef="frw_3_start" targetRef="agt_2_perform"' "$ROOT/$TPL" \
        && ! python3 -c "import ast,sys;t=ast.parse(open(sys.argv[1]).read());t.body=[n for n in t.body if not (isinstance(n,ast.Expr) and isinstance(getattr(n,'value',None),ast.Constant))];print(ast.unparse(t))" "$SUBJECT" | grep -qE '\b(frw|agt|hum)_[0-9]+_[a-z]+\b' \
        && ok flows_come_from_the_artefact || bad flows_come_from_the_artefact "a node id is written into the tool, or the artefact lacks the flow"
}
CONTROL_CASES="c_legal_transition_recorded c_gateway_branch_a_legal c_gateway_branch_b_legal c_first_hop_onto_start c_first_hop_mid_flow_refused_names_start c_inception_moves_within_template c_set_places_from_no_position c_set_refused_once_placed c_no_entity_distinct c_no_template_distinct c_flows_come_from_the_artefact"

# ── gate cases (must go red under the mutant) ────────────────────────────────
g_out_of_order_refused_unchanged() {
    local out; out=$(run advance T-9971 frw_10_finalize); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] \
        && [ "$(node_of T-9971)" = "frw_3_start" ] && [ "$(node_lines T-9971)" = 1 ] \
        && ok out_of_order_refused_unchanged || bad out_of_order_refused_unchanged "rc=$rc out=$out"
}
g_refusal_names_current_target_file_successors() {
    local out; out=$(run advance T-9971 frw_10_finalize)
    [[ "$out" == REFUSED-TRANSITION\ T-9971:* ]] && [[ "$out" == *frw_3_start*frw_10_finalize* ]] \
        && [[ "$out" == *"$TPL"* ]] && [[ "$out" == *"successor(s) of frw_3_start in $TPL: agt_2_perform"* ]] \
        && ok refusal_names_current_target_file_successors || bad refusal_names_current_target_file_successors "out=$out"
}
g_backwards_refused() {
    local out; out=$(run advance T-9977 frw_3_start); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [ "$(node_of T-9977)" = "agt_2_perform" ] \
        && ok backwards_refused || bad backwards_refused "rc=$rc out=$out"
}
g_past_end_refused() {
    local out; out=$(run advance T-9973 frw_1_task); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [[ "$out" == *"end event"* ]] \
        && [ "$(node_of T-9973)" = "frw_11_task" ] \
        && ok past_end_refused || bad past_end_refused "rc=$rc out=$out"
}
g_gateway_two_hops_refused() {
    local out; out=$(run advance T-9974 frw_6_run); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [ "$(node_of T-9974)" = "frw_5_outcome" ] \
        && ok gateway_two_hops_refused || bad gateway_two_hops_refused "rc=$rc out=$out"
}
g_cross_template_refused() {
    # frw_10_finalize is a real node — in task-lifecycle, which this inception is ALSO bound to.
    local out; out=$(run advance T-9976 frw_10_finalize); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-TRANSITION* ]] && [ "$(node_of T-9976)" = "hum_2_decision" ] \
        && ok cross_template_refused || bad cross_template_refused "rc=$rc out=$out"
}
GATE_CASES="g_out_of_order_refused_unchanged g_refusal_names_current_target_file_successors g_backwards_refused g_past_end_refused g_gateway_two_hops_refused g_cross_template_refused"

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
anchor='# MUTATION-ANCHOR successor-check'
i=src.find(anchor)
if i<0: sys.exit("mutation anchor not found")
probe='if node in succ:'
j=src.find(probe, i)
if j<0: sys.exit("successor test not found after anchor")
open(sys.argv[2],'w').write(src[:j]+'if True:  # MUTANT: successor test disabled'+src[j+len(probe):])
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    cmp -s "$SUBJECT" "$MUT" && { echo "MUTATION SETUP FAILED: mutant identical to subject"; exit 1; }
    grep -q 'MUTANT: successor test disabled' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-882 MUTATION RUN (advance accepts any hop from a recorded position) ==="
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
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against an advance that refuses nothing:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every refusal case went red."
    exit 0
fi

echo "=== T-882 teeth: guarded advance (subject: ${SUBJECT#$ROOT/}) ==="
run_suite
echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
