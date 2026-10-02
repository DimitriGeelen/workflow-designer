#!/bin/bash
# Instance position writer (T-923, arc-005 "process-instances").
#
# A governed entity (a task) is an INSTANCE of the task-lifecycle template
# (examples/aef-processes/rendered/task-lifecycle.bpmn — T-878, T-880). Its position
# on that template is recorded as `current_node:` in its own frontmatter and may move
# only along a sequenceFlow the template carries (T-882's guard). update-task.sh IS
# the process the template draws: when it starts work it is frw_3_start, when it
# enters issues it is frw_4_enter, when it runs the completion battery it is
# frw_6_run, and so on. So it writes the node it is, here, through the guard.
#
# Two functions, both safe to call from a `set -euo pipefail` close path:
#
#   fw_instance_node_for_transition <old-status> <new-status> [partial]
#       The task-lifecycle node the framework is at when it performs that status
#       transition. Empty string when the template has no node for it (a pause,
#       started-work -> captured, is not modelled — a template gap, recorded as such).
#
#   fw_instance_refused <task-id> <case> <rule> <node> [detail] [project-root]
#       T-883 (arc-005 S3/B9, V7): a gate in update-task.sh refused a transition. Record
#       it in the instance audit log (.context/audits/instance-refusals.jsonl) through the
#       tool's `refused` verb — the tool is the ONE writer of that log — with actor=framework.
#       Never fails the caller; silent when the tool or artefact is absent; a refused or
#       failed write is a WARNING on stderr. Empty case/rule/node → no-op (a line that
#       names no rule cannot be written, so it is not attempted).
#
#   fw_instance_walk <task-id> <node> [project-root]
#       Ask tools/instance-node.py to WALK the entity to <node>: shortest legal path,
#       one validated hop at a time. NEVER fails the caller — this runs on every
#       transition of every task:
#         rc 0 (walked / already there)   -> echoed as `  position: ...` lines
#         rc 1 (the template REFUSED)     -> WARNING on stderr carrying the tool's own
#                                            REFUSED-TRANSITION line; record unchanged;
#                                            the status change still stands, because
#                                            status-transitions.yaml is authoritative
#                                            for STATUS and the map for POSITION
#         rc 2/3 (NO-ENTITY / NO-TEMPLATE) -> silent (a spike is not an instance)
#         tool or artefact absent          -> silent no-op (vendored framework in a
#                                            project without the seam)
#
# Override points, used by tools/_t923-framework-writer-teeth.sh and _t883-refusal-audit-teeth.sh:
#   FW_INSTANCE_TOOL         path to instance-node.py   (default <root>/tools/instance-node.py)
#   FW_INSTANCE_TASKS_DIR    fixture tasks dir           (default: the tool's own .tasks/active + completed)
#   FW_INSTANCE_REFUSAL_LOG  audit log file              (read by the tool itself; default <root>/.context/audits/instance-refusals.jsonl)

fw_instance_node_for_transition() {
    local old="${1:-}" new="${2:-}" partial="${3:-}"
    case "$new" in
        started-work)
            case "$old" in
                issues|blocked) echo agt_2_perform ;;   # back to performing the work
                *)              echo frw_3_start ;;     # captured (or legacy refined) -> started
            esac ;;
        issues|blocked)  echo frw_4_enter ;;
        work-completed)
            if [ "$partial" = "partial" ]; then echo frw_8_partial; else echo frw_11_task; fi ;;
        *)               echo "" ;;                     # captured (pause): not modelled
    esac
}

fw_instance_walk() {
    local task_id="${1:-}" node="${2:-}" root="${3:-${PROJECT_ROOT:-$(pwd)}}"
    [ -n "$task_id" ] && [ -n "$node" ] || return 0
    local tool="${FW_INSTANCE_TOOL:-$root/tools/instance-node.py}"
    local tpl="$root/examples/aef-processes/rendered/task-lifecycle.bpmn"
    [ -f "$tool" ] && [ -f "$tpl" ] && command -v python3 >/dev/null 2>&1 || return 0
    local -a extra=()
    [ -n "${FW_INSTANCE_TASKS_DIR:-}" ] && extra=(--tasks-dir "$FW_INSTANCE_TASKS_DIR")
    local out rc
    out=$(python3 "$tool" --root "$root" ${extra[@]+"${extra[@]}"} walk "$task_id" "$node" 2>&1); rc=$?
    case "$rc" in
        0) [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/  position: /' ;;
        1) printf 'WARNING: instance position NOT advanced for %s — the template refused (status changed anyway: status-transitions.yaml is authoritative for status, the map for position):\n  %s\n' "$task_id" "$out" >&2 ;;
        *) : ;;
    esac
    return 0
}

fw_instance_refused() {
    local task_id="${1:-}" rcase="${2:-}" rule="${3:-}" node="${4:-}" detail="${5:-}" root="${6:-${PROJECT_ROOT:-$(pwd)}}"
    [ -n "$task_id" ] && [ -n "$rcase" ] && [ -n "$rule" ] && [ -n "$node" ] || return 0
    local tool="${FW_INSTANCE_TOOL:-$root/tools/instance-node.py}"
    local tpl="$root/examples/aef-processes/rendered/task-lifecycle.bpmn"
    [ -f "$tool" ] && [ -f "$tpl" ] && command -v python3 >/dev/null 2>&1 || return 0
    local -a extra=()
    [ -n "${FW_INSTANCE_TASKS_DIR:-}" ] && extra=(--tasks-dir "$FW_INSTANCE_TASKS_DIR")
    local out rc
    out=$(python3 "$tool" --root "$root" ${extra[@]+"${extra[@]}"} refused "$task_id" --case "$rcase" --rule "$rule" --node "$node" --detail "$detail" --actor framework 2>&1); rc=$?
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^REFUSAL-RECORDED '; then
        printf '%s\n' "$out" | sed 's/^/  audit: /'
    else
        printf 'WARNING: refusal NOT audited for %s (%s / %s at %s):\n  %s\n' "$task_id" "$rcase" "$rule" "$node" "$out" >&2
    fi
    return 0
}
