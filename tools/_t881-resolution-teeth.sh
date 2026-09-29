#!/bin/bash
# T-881 (arc-005 S2) — teeth for resolution both ways.
#
# WHAT IT DEFENDS. Forward resolution is nearly free once T-880 records a node; the
# reverse query is where a false silence can hide. "No instances" must be a
# MEASUREMENT (n=0 over a stated population), never a broken query that matched
# nothing — and the population must be filtered by the derived binding, or every
# template lists every task and the round-trip check is what catches it.
#
# GATE cases are the ones the binding filter protects: reverse lists exactly the
# bound entities, a template with no bound live entity reports NO-INSTANCES with
# its examined count, and round-trip agreement holds. Under --mutation the filter
# is disabled and every one of them must go red. CONTROLS run first and must hold
# under the mutant: forward resolution, the unknown-template state, per-entity
# NO-POSITION, the YAML-id refusal, and the examined count itself.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/tools/instance-node.py}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t881.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
# T-883: every refusal is audited; a fixture refusal must not land in the live log.
export FW_INSTANCE_REFUSAL_LOG="$WORK/refusals.jsonl"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'MUTATION-ANCHOR binding-filter' "$SUBJECT" || {
    echo "TEETH BROKEN — mutation anchor not found in $SUBJECT."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }

LIVE="$WORK/live"; BUILDONLY="$WORK/buildonly"; mkdir -p "$LIVE" "$BUILDONLY"
mk() { # $1 dir, $2 id, $3 workflow_type, $4 extra frontmatter line
    { printf -- '---\nid: %s\nname: "fixture"\nstatus: started-work\nworkflow_type: %s\n' "$2" "$3"
      [ -n "${4:-}" ] && printf '%s\n' "$4"
      printf -- 'owner: agent\n---\n\n# %s\n' "$2"
    } > "$1/$2-fixture.md"
}
reset_fixtures() {
    rm -f "$LIVE"/*.md "$BUILDONLY"/*.md
    mk "$LIVE" T-9971 build "current_node: frw_3_start"
    mk "$LIVE" T-9972 build
    mk "$LIVE" T-9973 inception "current_node: hum_2_decision"
    mk "$LIVE" T-9974 spike
    mk "$BUILDONLY" T-9975 build "current_node: agt_2_perform"
    mk "$BUILDONLY" T-9976 test
    mk "$BUILDONLY" T-9977 spike
}
run()  { python3 "$SUBJECT" --root "$ROOT" --tasks-dir "$LIVE" "$@" 2>&1; }
runb() { python3 "$SUBJECT" --root "$ROOT" --tasks-dir "$BUILDONLY" "$@" 2>&1; }

# ── controls ─────────────────────────────────────────────────────────────────
c_forward_names_file_and_node() {
    local out; out=$(run resolve T-9973 | tr '\n' '|')
    [[ "$out" == "TEMPLATE examples/aef-processes/rendered/task-lifecycle.bpmn|TEMPLATE examples/aef-processes/rendered/inception-lifecycle.bpmn|NODE hum_2_decision inception-lifecycle|" ]] \
        && ok forward_names_file_and_node || bad forward_names_file_and_node "out=$out"
}
c_forward_reads_no_authored_binding() {
    # the derivation comes from workflow_type; a bogus authored field changes nothing
    mk "$LIVE" T-9978 build "template: inception-lifecycle"
    local out; out=$(run resolve T-9978 | tr '\n' '|')
    [[ "$out" == "TEMPLATE examples/aef-processes/rendered/task-lifecycle.bpmn|NO-POSITION task-lifecycle|" ]] \
        && ok forward_reads_no_authored_binding || bad forward_reads_no_authored_binding "out=$out"
}
c_template_unknown_distinct() {
    local out; out=$(run instances no-such-template); local rc=$?
    [ $rc -eq 3 ] && [[ "$out" == TEMPLATE-UNKNOWN\ no-such-template* ]] \
        && ok template_unknown_distinct || bad template_unknown_distinct "rc=$rc out=$out"
}
c_entity_no_template_distinct() {
    local out; out=$(run resolve T-9974); local rc=$?
    [ $rc -eq 3 ] && [[ "$out" == NO-TEMPLATE\ spike* ]] \
        && ok entity_no_template_distinct || bad entity_no_template_distinct "rc=$rc out=$out"
}
c_no_position_named_per_entity() {
    run instances task-lifecycle | grep -q '^  T-9972 NO-POSITION$' \
        && ok no_position_named_per_entity || bad no_position_named_per_entity "$(run instances task-lifecycle)"
}
c_examined_count_states_population() {
    # the spike entity binds to nothing but IS examined — the population is the whole live dir
    run instances task-lifecycle | grep -q '(examined 4 live entities)' \
        && ok examined_count_states_population || bad examined_count_states_population "$(run instances task-lifecycle | head -1)"
}
c_yaml_id_does_not_resolve() {
    # c_sovereignty is a node id in the canonical YAML and not in the rendered artefact
    grep -q 'c_sovereignty' "$ROOT/examples/aef-processes/task-lifecycle.workflow.yaml" \
        && ! run nodes task-lifecycle | grep -qx 'c_sovereignty' \
        && [[ "$(run set T-9972 c_sovereignty)" == REFUSED* ]] \
        && run nodes task-lifecycle | grep -qx 'frw_3_start' \
        && ! grep -q 'frw_3_start' "$ROOT/examples/aef-processes/task-lifecycle.workflow.yaml" \
        && ok yaml_id_does_not_resolve || bad yaml_id_does_not_resolve "c_sovereignty resolved, or frw_3_start did not"
}
CONTROL_CASES="c_forward_names_file_and_node c_forward_reads_no_authored_binding c_template_unknown_distinct c_entity_no_template_distinct c_no_position_named_per_entity c_examined_count_states_population c_yaml_id_does_not_resolve"

# ── gate cases (the binding filter) ──────────────────────────────────────────
g_reverse_lists_exactly_the_bound() {
    local out; out=$(run instances inception-lifecycle | tr '\n' '|')
    [[ "$out" == "INSTANCES inception-lifecycle 1 (examined 4 live entities)|  T-9973 NODE hum_2_decision|" ]] \
        && ok reverse_lists_exactly_the_bound || bad reverse_lists_exactly_the_bound "out=$out"
}
g_reverse_zero_is_a_measurement() {
    local out; out=$(runb instances inception-lifecycle); local rc=$?
    [ $rc -eq 0 ] && [ "$out" = "NO-INSTANCES inception-lifecycle (examined 3 live entities)" ] \
        && ok reverse_zero_is_a_measurement || bad reverse_zero_is_a_measurement "rc=$rc out=$out"
}
g_roundtrip_agreement_holds() {
    local out; out=$(run roundtrip); local rc=$?
    [ $rc -eq 0 ] && ! echo "$out" | grep -q 'ROUNDTRIP-FAIL' && echo "$out" | grep -q '^ROUNDTRIP-OK inception-lifecycle 1 ' \
        && ok roundtrip_agreement_holds || bad roundtrip_agreement_holds "rc=$rc out=$out"
}
GATE_CASES="g_reverse_lists_exactly_the_bound g_reverse_zero_is_a_measurement g_roundtrip_agreement_holds"

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
anchor='# MUTATION-ANCHOR binding-filter'
i=src.find(anchor)
if i<0: sys.exit("mutation anchor not found")
needle='if not tpls or template not in tpls:'
j=src.find(needle, i)
if j<0: sys.exit("binding filter not found after anchor")
open(sys.argv[2],'w').write(src[:j]+'if False:  # MUTANT: binding filter disabled'+src[j+len(needle):])
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    cmp -s "$SUBJECT" "$MUT" && { echo "MUTATION SETUP FAILED: mutant identical to subject"; exit 1; }
    grep -q 'MUTANT: binding filter disabled' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-881 MUTATION RUN (reverse query ignores the binding) ==="
    out=$(SUBJECT="$MUT" bash "$0" 2>&1)
    echo "$out" | sed 's/^/  | /'
    broken=""
    for c in $CONTROL_CASES; do n=${c#c_}; echo "$out" | grep -q "^  PASS  $n\$" || broken="$broken $n"; done
    [ -n "$broken" ] && { echo "MUTATION SETUP BROKEN — controls failed under the mutant:$broken"; exit 1; }
    survivors=""
    for c in $GATE_CASES; do n=${c#g_}; echo "$out" | grep -q "^  FAIL  $n\$" || survivors="$survivors $n"; done
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against a reverse query that filters nothing:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every binding case went red."
    exit 0
fi

echo "=== T-881 teeth: resolution both ways (subject: ${SUBJECT#$ROOT/}) ==="
run_suite
echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
