#!/usr/bin/env bash
# T-767 — ownership must follow the presence of a real Human acceptance criterion.
#
# Operator ruling on SQ-2 (2026-09-21): "should an agent-produced task ever be born on a
# human with zero human ACs? No. No, that's wrong per definition."
#
# This script is the negative control for that fix plus the standing measurement of the
# population it was found in. It is NOT a notice: every leg below has a verdict, the
# refusal leg fails loudly if the gate stops refusing, and the exit code is the answer.
#
#   --self-test    run the four behavioural legs against a THROWAWAY project root
#   --measure      classify the live owner:human population (read-only)
#   (no args)      both; exit 0 only if every leg passes
#
# The behavioural legs never touch the real .tasks/ tree: a throwaway root is built in
# mktemp -d and the real task-id counter is never advanced.

set -uo pipefail

PROJECT="${PROJECT:-/opt/832-Workflow-designer}"
FW="$PROJECT/.agentic-framework"
CREATE="$FW/agents/task-create/create-task.sh"

pass=0; fail=0
ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL  $1"; fail=$((fail+1)); }

make_root() {
    local r; r="$(mktemp -d)"
    mkdir -p "$r/.tasks/active" "$r/.tasks/completed" "$r/.tasks/templates" "$r/.context/working"
    cp "$PROJECT/.tasks/templates/"*.md "$r/.tasks/templates/" 2>/dev/null
    echo "$r"
}

self_test() {
    echo "== behavioural legs (throwaway root, real .tasks untouched) =="
    local r out rc
    r="$(make_root)"

    # LEG 1 — the negative control. The old shape must be REFUSED.
    out="$(PROJECT_ROOT="$r" "$CREATE" --name "leg1 old shape" --description "d" \
             --type build --owner human 2>&1)"; rc=$?
    if [ "$rc" -ne 0 ] && echo "$out" | grep -q -- '--human-ac'; then
        ok "owner:human with no Human AC is refused, and the message names --human-ac"
    else
        bad "old shape was NOT refused (rc=$rc) — the gate is gone or silent"
        echo "$out" | head -3 | sed 's/^/        /'
    fi

    # LEG 2 — the positive control. The new shape must succeed AND seed a real criterion.
    out="$(PROJECT_ROOT="$r" "$CREATE" --name "leg2 new shape" --description "d" \
             --type build --owner human --human-ac "[REVIEW] verify the thing" 2>&1)"; rc=$?
    local f; f="$(ls "$r/.tasks/active/"*.md 2>/dev/null | head -1)"
    if [ "$rc" -eq 0 ] && [ -n "$f" ] && \
       awk '/^### Human/{h=1;next} /^## /{h=0} h && /^- \[ \]/{n++} END{exit !(n>0)}' "$f"; then
        ok "owner:human with --human-ac succeeds and the file carries a real Human AC"
    else
        bad "new shape failed (rc=$rc) or no Human AC was seeded into the file"
        echo "$out" | head -3 | sed 's/^/        /'
    fi

    # LEG 3 — the exemption must hold. T-2543/T-2577 gated writers are human-by-policy.
    rm -rf "$r"; r="$(make_root)"
    out="$(PROJECT_ROOT="$r" FW_TASK_ORIGIN=bpmn-promote "$CREATE" --name "leg3 gated" \
             --description "d" --type build --owner human 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ]; then
        ok "bpmn-promote origin still creates owner:human without --human-ac (T-2543 bar intact)"
    else
        bad "the new gate broke the T-2543/T-2577 gated-writer path (rc=$rc)"
        echo "$out" | head -3 | sed 's/^/        /'
    fi

    # LEG 4 — inception is exempt because its template already ships a go/no-go Human AC.
    rm -rf "$r"; r="$(make_root)"
    # --recommendation/--rationale are SUPPLIED, not bypassed: the T-679 filing gate
    # requires them under $CLAUDECODE, and its two escape hatches (--i-am-human,
    # FW_ALLOW_EMPTY_RECOMMENDATION=1) are both on this project's non-delegated list.
    out="$(PROJECT_ROOT="$r" "$CREATE" --name "leg4 inception" --description "d" \
             --type inception --owner human \
             --recommendation DEFER \
             --rationale "control fixture for T-767; this task is never worked" 2>&1)"; rc=$?
    f="$(ls "$r/.tasks/active/"*.md 2>/dev/null | head -1)"
    if [ "$rc" -eq 0 ] && [ -n "$f" ] && \
       awk '/^### Human/{h=1;next} /^## /{h=0} h && /^- \[ \]/{n++} END{exit !(n>0)}' "$f"; then
        ok "inception is exempt and still born with its go/no-go Human AC"
    else
        bad "inception create broke or lost its Human AC (rc=$rc)"
        echo "$out" | head -3 | sed 's/^/        /'
    fi

    rm -rf "$r"
}

measure() {
    echo "== live population (read-only) =="
    python3 - "$PROJECT" <<'PY'
import sys, os, re, glob
root = sys.argv[1]
c1, c2, c3, tot = [], [], [], 0
for f in sorted(glob.glob(os.path.join(root, ".tasks/active/*.md"))):
    t = open(f, encoding="utf-8", errors="replace").read()
    m = re.search(r'^owner:[ \t]*(\S*)\s*$', t, re.M)
    if not m or m.group(1) != "human":
        continue
    tot += 1
    # Human AC checkboxes = '- [' lines under a '### Human' heading, until the next '## '
    n, inh = 0, False
    for line in t.splitlines():
        if line.startswith("### Human"): inh = True; continue
        if line.startswith("## "): inh = False
        if inh and line.startswith("- ["): n += 1
    if n: continue
    tid = os.path.basename(f).split("-")[0] + "-" + os.path.basename(f).split("-")[1]
    unchecked = len(re.findall(r'^- \[ \]', t, re.M))
    if unchecked == 0: c1.append(tid)
    elif re.search(r'^- \[ \] \[First criterion\]', t, re.M): c2.append(tid)
    else: c3.append(tid)
print("  owner:human active tasks ......................... %d" % tot)
print("  of those, ZERO Human AC checkboxes ............... %d" % (len(c1)+len(c2)+len(c3)))
print("    class 1 - completable, nothing for the human ... %d  %s" % (len(c1), " ".join(c1)))
print("    class 2 - placeholder ACs never filled ......... %d  %s" % (len(c2), " ".join(c2)))
print("    class 3 - real unchecked ACs, none of them Human %d  %s" % (len(c3), " ".join(c3)))
print("  NOTE: these are NOT reassigned by this task (T-767 AC5). Measurement only.")
PY
}

case "${1:-all}" in
    --self-test) self_test ;;
    --measure)   measure; exit 0 ;;
    all)         self_test; echo; measure ;;
    *) echo "usage: $0 [--self-test|--measure]" >&2; exit 2 ;;
esac

echo
echo "legs: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
