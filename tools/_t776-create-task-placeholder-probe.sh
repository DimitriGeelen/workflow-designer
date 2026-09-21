#!/usr/bin/env bash
# T-776 (OBS-365) — does create-task.sh leave the operator's own name alone when that name
# contains the id placeholder?
#
# T-660 added a body-wide substitution of the placeholder token by the allocated id, for a
# real reason: without it every inception shipped `Run: fw task review <placeholder>` as
# the operator's literal first step, and an AC whose first step cannot be pasted costs a
# reconstruction before the operator can even begin. That pass ran at the END, after the
# user-supplied name had been injected, so a task NAMED after the placeholder had its own
# name rewritten.
#
# The fix is ordering, not removal: the substitution now runs once, while the template is
# still the template, before any user text exists in the document.
#
# This probe therefore has to assert BOTH directions. Asserting only that the name survives
# would pass just as well if the substitution had been deleted outright — which would
# silently restore the defect T-660 was built to fix. Leg 3 is that guard.

set -uo pipefail

ROOT="/opt/832-Workflow-designer"
SCRIPT="$ROOT/.agentic-framework/agents/task-create/create-task.sh"
PREFIX_COMMIT="7892bb66"   # T-775: the last commit before the T-776 reordering
PLACEHOLDER="T-$(printf 'XXX')"   # assembled, so this file is not itself rewritten by any
                                  # tool that substitutes the literal token (PL-164)
PASS=0
FAIL=0

[ -f "$SCRIPT" ] || { echo "FATAL: script not found: $SCRIPT"; exit 2; }

WORK="$(mktemp -d)"
POISON="$ROOT/.agentic-framework/agents/task-create/.t776-negcontrol.sh"
trap 'rm -rf "$WORK"; rm -f "$POISON"' EXIT

mkfixture() {
    local fx="$WORK/$1"
    rm -rf "$fx"
    mkdir -p "$fx/.tasks/active" "$fx/.tasks/completed" "$fx/.context"
    cp -r "$ROOT/.tasks/templates" "$fx/.tasks/"
    touch "$fx/.framework.yaml"
    printf '%s' "$fx"
}

create() {
    local script="$1" fx="$2" nm="$3"; shift 3
    local before after
    before="$(ls "$fx/.tasks/active/" 2>/dev/null | wc -l)"
    env PROJECT_ROOT="$fx" TASKS_DIR="$fx/.tasks" CONTEXT_DIR="$fx/.context" \
        "$script" --name "$nm" --description 'T-776 probe fixture' "$@" >/dev/null 2>&1
    after="$(ls "$fx/.tasks/active/" 2>/dev/null | wc -l)"
    [ "$after" -gt "$before" ] || return 0
    ls -t "$fx/.tasks/active/"*.md 2>/dev/null | head -1
}

taskid() { basename "$1" | sed -n 's/^\(T-[0-9]*\)-.*/\1/p'; }
ok()  { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf '  FAIL  %s\n' "$1"; shift; for l in "$@"; do printf '        %s\n' "$l"; done; FAIL=$((FAIL + 1)); }

echo "=== T-776: the id placeholder inside a task name ==="
echo
echo "--- the fixed script ---"

FX="$(mkfixture live)"
NAME_B="build tasks ship the literal ${PLACEHOLDER} placeholder"
NAME_I="inception ACs ship the literal ${PLACEHOLDER} placeholder"

# 1. Default branch: the operator's name survives verbatim.
f="$(create "$SCRIPT" "$FX" "$NAME_B" --type build --owner agent)"
if [ -n "${f:-}" ] && grep -qF "name: \"$NAME_B\"" "$f"; then
    ok "build branch — name with the placeholder survives verbatim"
else
    bad "build branch — name was rewritten" "got: $(grep -m1 '^name:' "${f:-/dev/null}" 2>/dev/null)"
fi

# 2. Inception branch — a separate code path, not an inference from leg 1.
f="$(create "$SCRIPT" "$FX" "$NAME_I" --type inception --owner agent --recommendation DEFER --rationale 'T-776 probe fixture')"
if [ -n "${f:-}" ] && grep -qF "name: \"$NAME_I\"" "$f"; then
    ok "inception branch — name with the placeholder survives verbatim"
else
    bad "inception branch — name was rewritten" "got: $(grep -m1 '^name:' "${f:-/dev/null}" 2>/dev/null)"
fi

# 3. T-660 IS NOT REGRESSED. Deleting the substitution would make legs 1 and 2 pass and
#    restore the defect T-660 existed to fix. The review command must carry the REAL id.
if [ -n "${f:-}" ]; then
    id="$(taskid "$f")"
    if grep -q "fw task review $id" "$f"; then
        ok "inception branch — T-660 preserved, review command carries the real id ($id)"
    else
        bad "inception branch — T-660 REGRESSED: review command lost its id" \
            "$(grep -m1 'fw task review' "$f" 2>/dev/null)"
    fi
fi

# 4. An ordinary name leaves NO placeholder anywhere in the file. This is the other half of
#    leg 3: it proves the substitution still ranges over the whole document, not just the
#    title, which is exactly what T-660 changed.
f="$(create "$SCRIPT" "$FX" 'an ordinary inception with no token in its name' --type inception --owner agent --recommendation DEFER --rationale 'T-776 probe fixture')"
if [ -z "${f:-}" ]; then
    bad "ordinary inception — no task file was created"
elif grep -qF "$PLACEHOLDER" "$f"; then
    bad "ordinary inception — a literal placeholder survived in the body" \
        "$(grep -nF "$PLACEHOLDER" "$f" | head -3)"
else
    ok "ordinary inception — zero literal placeholders left in the file"
fi

echo
echo "--- negative control: the genuine pre-fix script from $PREFIX_COMMIT ---"

if ! git -C "$ROOT" show "$PREFIX_COMMIT:.agentic-framework/agents/task-create/create-task.sh" > "$POISON" 2>/dev/null; then
    bad "could not retrieve the pre-fix script from $PREFIX_COMMIT" \
        "Without it this probe cannot show that it is able to fail," \
        "so every PASS above is unsupported."
else
    chmod +x "$POISON"
    FXN="$(mkfixture prefix)"
    f="$(create "$POISON" "$FXN" "$NAME_B" --type build --owner agent)"
    if [ -z "${f:-}" ]; then
        bad "pre-fix script wrote no file"
    else
        id="$(taskid "$f")"
        if grep -qF "name: \"$NAME_B\"" "$f"; then
            bad "pre-fix script left the name intact — this probe is not measuring the defect" \
                "$(grep -m1 '^name:' "$f")"
        elif grep -q "ship the literal $id placeholder" "$f"; then
            ok "pre-fix script reproduces the defect (name rewritten to carry $id)"
        else
            bad "pre-fix script produced an unexpected name" "$(grep -m1 '^name:' "$f")"
        fi
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
