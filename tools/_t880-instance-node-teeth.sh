#!/bin/bash
# T-880 (arc-005 S2) — teeth for the recorded current node.
#
# WHAT IT DEFENDS. T-878 split "process instance" in two: WHICH TEMPLATE is derived
# from workflow_type, WHICH NODE is recorded because it cannot be derived. The one
# thing that can go quietly wrong is the recorded half: a setter that accepts any
# string turns `current_node:` into free text, and a position nobody validated is
# a position nobody can trust — the monitoring goal (G4) collapses on it.
#
# So the GATE cases are the refusals (arbitrary string, node from a template this
# entity is not bound to), and the CONTROLS are everything that must keep working
# when the refusal is switched off: valid nodes recorded, the four states kept
# distinct, no new identifier minted, the derivation naming the rendered artefact.
#
# CONTROLS RUN FIRST. Under --mutation the setter's membership test is disabled;
# a control that fails there means the harness is broken, and a broken harness is
# reported as MUTATION SETUP BROKEN rather than scored as kills.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/tools/instance-node.py}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t880.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
# T-883: every refusal is audited; a fixture refusal must not land in the live log.
export FW_INSTANCE_REFUSAL_LOG="$WORK/refusals.jsonl"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'MUTATION-ANCHOR node-validation' "$SUBJECT" || {
    echo "TEETH BROKEN — mutation anchor not found in $SUBJECT."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }

FIX="$WORK/tasks"; mkdir -p "$FIX"
mk() { # $1 id, $2 workflow_type, $3 extra frontmatter line
    { printf -- '---\nid: %s\nname: "fixture"\nstatus: started-work\nworkflow_type: %s\n' "$1" "$2"
      [ -n "${3:-}" ] && printf '%s\n' "$3"
      printf -- 'owner: agent\n---\n\n# %s\n\n## Acceptance Criteria\n- [ ] x\n' "$1"
    } > "$FIX/$1-fixture.md"
}
reset_fixtures() {
    rm -f "$FIX"/*.md
    mk T-9981 build
    mk T-9982 inception
    mk T-9983 spike
    mk T-9984 build "current_node: frw_11_task"
}
run() { python3 "$SUBJECT" --root "$ROOT" --tasks-dir "$FIX" "$@" 2>&1; }

# ── controls (must hold under the mutant too) ────────────────────────────────
c_valid_node_recorded() {
    local out; out=$(run set T-9981 frw_3_start); local rc=$?
    [ $rc -eq 0 ] && grep -q '^current_node: frw_3_start$' "$FIX/T-9981-fixture.md" \
        && [ "$(run get T-9981)" = "NODE frw_3_start task-lifecycle" ] \
        && ok valid_node_recorded || bad valid_node_recorded "rc=$rc out=$out"
}
c_set_is_placement_one_shot() {
    # T-882 rewrote this control. It used to pin `set` REPLACING a recorded node (frw_11_task -> frw_2_build,
    # an end event hopping back to a gateway) — which is exactly the illegitimate transition S3 exists to
    # refuse. Now: set on a placed entity is REFUSED-PLACED, and the record is unchanged — still one line.
    local out; out=$(run set T-9984 frw_2_build); local rc=$?
    local n; n=$(grep -c '^current_node:' "$FIX/T-9984-fixture.md")
    [ $rc -eq 1 ] && [[ "$out" == REFUSED-PLACED* ]] && [ "$n" = 1 ] && grep -q '^current_node: frw_11_task$' "$FIX/T-9984-fixture.md" \
        && ok set_is_placement_one_shot || bad set_is_placement_one_shot "rc=$rc current_node lines=$n out=$out"
}
c_no_position_distinct() {
    local out; out=$(run get T-9982); local rc=$?
    [ $rc -eq 0 ] && [ "$out" = "NO-POSITION task-lifecycle,inception-lifecycle" ] \
        && ok no_position_distinct || bad no_position_distinct "rc=$rc out=$out"
}
c_no_template_distinct() {
    local out; out=$(run get T-9983); local rc=$?
    [ $rc -eq 3 ] && [[ "$out" == NO-TEMPLATE\ spike* ]] \
        && ok no_template_distinct || bad no_template_distinct "rc=$rc out=$out"
}
c_no_entity_distinct() {
    local out; out=$(run get T-9999); local rc=$?
    [ $rc -eq 2 ] && [ "$out" = "NO-ENTITY T-9999" ] \
        && ok no_entity_distinct || bad no_entity_distinct "rc=$rc out=$out"
}
c_set_on_no_template_records_nothing() {
    local out; out=$(run set T-9983 frw_1_task); local rc=$?
    [ $rc -eq 3 ] && ! grep -q '^current_node:' "$FIX/T-9983-fixture.md" \
        && ok set_on_no_template_records_nothing || bad set_on_no_template_records_nothing "rc=$rc out=$out"
}
c_bind_names_rendered_artefact() {
    local out; out=$(run bind build)
    [ "$out" = "examples/aef-processes/rendered/task-lifecycle.bpmn" ] && [ -f "$ROOT/$out" ] \
        && ok bind_names_rendered_artefact || bad bind_names_rendered_artefact "out=$out"
}
c_bind_is_not_the_yaml() {
    # a node id valid in the rendered artefact and absent from the canonical YAML
    grep -q 'id="frw_3_start"' "$ROOT/examples/aef-processes/rendered/task-lifecycle.bpmn" \
        && ! grep -q 'frw_3_start' "$ROOT/examples/aef-processes/task-lifecycle.workflow.yaml" \
        && ok bind_is_not_the_yaml || bad bind_is_not_the_yaml "frw_3_start present in YAML or absent from rendered"
}
c_inception_binds_both() {
    local out; out=$(run bind inception | tr '\n' ' ')
    [[ "$out" == *task-lifecycle.bpmn*inception-lifecycle.bpmn* ]] \
        && ok inception_binds_both || bad inception_binds_both "out=$out"
}
c_inception_accepts_inception_node() {
    local out; out=$(run set T-9982 hum_2_decision); local rc=$?
    [ $rc -eq 0 ] && [ "$(run get T-9982)" = "NODE hum_2_decision inception-lifecycle" ] \
        && ok inception_accepts_inception_node || bad inception_accepts_inception_node "rc=$rc out=$out"
}
c_no_new_identifier() {
    # a FIELD, not the word: T-878 IW-3 is named in the tool's own prose, and that is fine.
    # control: the same pattern hits where an identifier field IS written (the pinned artefact carries aef:uuid)
    grep -qE "(uuid|instance_id|instanceId)['\":=]" "$ROOT/examples/aef-processes/rendered/task-lifecycle.bpmn" \
        && ! grep -vE '^\s*#' "$SUBJECT" | grep -qE "(uuid|instance_id|instanceId)['\":=]" \
        && ok no_new_identifier || bad no_new_identifier "the delivered surface mints or names a new identifier"
}
c_ac_gate_hint_points_at_existing_node() {
    # AC 5: the dead hint at update-task.sh is repointed; its path exists and its node id is in it.
    local f="$ROOT/.agentic-framework/agents/task-create/update-task.sh"
    local path node
    path=$(grep -oE 'examples/aef-processes/rendered/task-lifecycle\.bpmn' "$f" | head -1)
    node=$(grep -oE 'task-lifecycle node [a-z0-9_]+' "$f" | head -1 | awk '{print $3}')
    [ -n "$path" ] && [ -f "$ROOT/$path" ] && [ -n "$node" ] && grep -q "id=\"$node\"" "$ROOT/$path" \
        && ok ac_gate_hint_points_at_existing_node || bad ac_gate_hint_points_at_existing_node "path=$path node=$node"
}
CONTROL_CASES="c_valid_node_recorded c_set_is_placement_one_shot c_no_position_distinct c_no_template_distinct c_no_entity_distinct c_set_on_no_template_records_nothing c_bind_names_rendered_artefact c_bind_is_not_the_yaml c_inception_binds_both c_inception_accepts_inception_node c_no_new_identifier c_ac_gate_hint_points_at_existing_node"

# ── gate cases (must go red under the mutant) ────────────────────────────────
g_arbitrary_string_refused() {
    local out; out=$(run set T-9981 tl_archive); local rc=$?
    [ $rc -eq 1 ] && ! grep -q '^current_node:' "$FIX/T-9981-fixture.md" \
        && ok arbitrary_string_refused || bad arbitrary_string_refused "rc=$rc out=$out"
}
g_refusal_names_template() {
    local out; out=$(run set T-9981 tl_archive)
    [[ "$out" == REFUSED* ]] && [[ "$out" == *task-lifecycle.bpmn* ]] \
        && ok refusal_names_template || bad refusal_names_template "out=$out"
}
g_foreign_template_node_refused() {
    # hum_2_decision is real, but in inception-lifecycle; a build task is not bound to it
    local out; out=$(run set T-9981 hum_2_decision); local rc=$?
    [ $rc -eq 1 ] && ! grep -q '^current_node:' "$FIX/T-9981-fixture.md" \
        && ok foreign_template_node_refused || bad foreign_template_node_refused "rc=$rc out=$out"
}
g_stale_recorded_node_reported() {
    mk T-9985 build "current_node: tl_archive"
    local out; out=$(run get T-9985); local rc=$?
    [ $rc -eq 1 ] && [[ "$out" == NODE\ tl_archive\ STALE* ]] \
        && ok stale_recorded_node_reported || bad stale_recorded_node_reported "rc=$rc out=$out"
}
GATE_CASES="g_arbitrary_string_refused g_refusal_names_template g_foreign_template_node_refused"
# stale_recorded_node_reported reads the get path, whose membership test the mutant
# does not touch — it is a control of the reader, listed with the readers on purpose.
CONTROL_CASES="$CONTROL_CASES g_stale_recorded_node_reported"

run_suite() {
    for c in $CONTROL_CASES; do reset_fixtures; $c; done
    for c in $GATE_CASES;    do reset_fixtures; $c; done
}

# ── mutation ────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--mutation" ]; then
    MUT="$WORK/instance-node.mutant.py"
    python3 - "$SUBJECT" "$MUT" <<'PY'
import sys,re
src=open(sys.argv[1]).read()
anchor='# MUTATION-ANCHOR node-validation'
i=src.find(anchor)
if i<0: sys.exit("mutation anchor not found")
j=src.find('if a.node in template_nodes(f):', i)
if j<0: sys.exit("membership test not found after anchor")
mut=src[:j]+'if True:  # MUTANT: membership test disabled'+src[j+len('if a.node in template_nodes(f):'):]
open(sys.argv[2],'w').write(mut)
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    cmp -s "$SUBJECT" "$MUT" && { echo "MUTATION SETUP FAILED: mutant identical to subject"; exit 1; }
    grep -q 'MUTANT: membership test disabled' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-880 MUTATION RUN (setter accepts any node id) ==="
    out=$(SUBJECT="$MUT" bash "$0" 2>&1)
    echo "$out" | sed 's/^/  | /'
    broken=""
    for c in $CONTROL_CASES; do
        name=${c#c_}; name=${name#g_}
        echo "$out" | grep -q "^  PASS  $name\$" || broken="$broken $name"
    done
    [ -n "$broken" ] && { echo "MUTATION SETUP BROKEN — controls failed under the mutant:$broken"; exit 1; }
    survivors=""
    for c in $GATE_CASES; do
        name=${c#g_}
        echo "$out" | grep -q "^  FAIL  $name\$" || survivors="$survivors $name"
    done
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against a setter that refuses nothing:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every refusal case went red."
    exit 0
fi

echo "=== T-880 teeth: recorded current node (subject: ${SUBJECT#$ROOT/}) ==="
run_suite
echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
