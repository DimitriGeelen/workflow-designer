#!/usr/bin/env bash
# T-774 (OBS-363) — does create-task.sh survive a task name that contains its own
# frontmatter keys?
#
# The defect: every frontmatter substitution was an unanchored `t.replace('<key>:', …)`
# over a document into which the user-supplied NAME had already been injected. The first
# match could land inside the name. Two severities, both measured before the fix:
#   count=1 keys  (owner, workflow_type, created, last_update, description)
#                 -> name corrupted AND the field silently EMPTIED
#   unbounded keys (status, horizon, tags, related_tasks)
#                 -> name corrupted, field survives
#
# This probe drives the SHIPPED script, not a transcription of its logic. A copy of the
# substitution would only prove that the copy behaves as it was written.
#
# It writes nothing into this project's own .tasks/ — a test that leaves T-NNN debris in
# the register corrupts the thing the script exists to maintain.
#
# The last leg is a NEGATIVE CONTROL: it rebuilds the pre-fix behaviour in a throwaway
# copy of the script and requires the defect to REAPPEAR. A probe that has only ever
# passed has not been shown to measure anything (PL-178).

set -uo pipefail

ROOT="/opt/832-Workflow-designer"
SCRIPT="$ROOT/.agentic-framework/agents/task-create/create-task.sh"
PASS=0
FAIL=0

[ -f "$SCRIPT" ] || { echo "FATAL: script not found: $SCRIPT"; exit 2; }

WORK="$(mktemp -d)"

# The negative-control copy MUST live beside the original: create-task.sh derives
# FRAMEWORK_ROOT from "$(dirname "$0")/../.." and sources lib/paths.sh from it, so a copy
# in /tmp cannot start at all. Measured — the first version of this probe put it in $WORK
# and the control reported "no task file", which reads exactly like a passing fix and is
# not one. Hidden name, removed on every exit path including failure.
POISON="$ROOT/.agentic-framework/agents/task-create/.t774-negcontrol.sh"
trap 'rm -rf "$WORK"; rm -f "$POISON"' EXIT

mkfixture() {
    local fx="$WORK/$1"
    rm -rf "$fx"
    mkdir -p "$fx/.tasks/active" "$fx/.tasks/completed" "$fx/.context"
    cp -r "$ROOT/.tasks/templates" "$fx/.tasks/"
    touch "$fx/.framework.yaml"
    printf '%s' "$fx"
}

# run_case <script> <fixture> <name> [extra create-task args...]
# Creates one task and echoes the path of the file that appeared.
run_case() {
    local script="$1" fx="$2" nm="$3"; shift 3
    local before after
    before="$(ls "$fx/.tasks/active/" 2>/dev/null | wc -l)"
    env PROJECT_ROOT="$fx" TASKS_DIR="$fx/.tasks" CONTEXT_DIR="$fx/.context" \
        "$script" --name "$nm" --description 'T-774 probe fixture' "$@" >/dev/null 2>&1
    after="$(ls "$fx/.tasks/active/" 2>/dev/null | wc -l)"
    [ "$after" -gt "$before" ] || return 1
    ls -t "$fx/.tasks/active/"*.md 2>/dev/null | head -1
}

# field <file> <key>  — the frontmatter value, empty string when the field is blank
field() {
    sed -n '2,30p' "$1" | grep -m1 "^$2:" | sed "s/^$2:[[:space:]]*//"
}

check() {
    local label="$1" got="$2" want="$3"
    if [ "$got" = "$want" ]; then
        printf '  PASS  %s\n' "$label"
        PASS=$((PASS + 1))
    else
        printf '  FAIL  %s\n        got:  [%s]\n        want: [%s]\n' "$label" "$got" "$want"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== T-774: frontmatter substitution anchoring ==="
echo
echo "--- the shipped script, against names carrying its own keys ---"

FX="$(mkfixture live)"

# 1. OBS-363 as measured on T-768: the ownership token mid-name.
f="$(run_case "$SCRIPT" "$FX" 'SQ-9 upstream: report the owner:human-with-zero-ACs fault' --type build --owner agent)"
if [ -n "${f:-}" ]; then
    check "owner: in name — name survives intact" \
        "$(field "$f" name)" '"SQ-9 upstream: report the owner:human-with-zero-ACs fault"'
    check "owner: in name — ownership field is set, not emptied" "$(field "$f" owner)" "agent"
else
    echo "  FAIL  owner: case — no task file was created"; FAIL=$((FAIL + 2))
fi

# 2. workflow_type — same count=1 class, same silent emptying.
f="$(run_case "$SCRIPT" "$FX" 'the workflow_type: field is blank' --type build --owner agent)"
if [ -n "${f:-}" ]; then
    check "workflow_type: in name — name survives" "$(field "$f" name)" '"the workflow_type: field is blank"'
    check "workflow_type: in name — field is set" "$(field "$f" workflow_type)" "build"
else
    echo "  FAIL  workflow_type: case — no task file"; FAIL=$((FAIL + 2))
fi

# 3. status — unbounded substitution. Uses --start so the replacement is NOT an identity;
#    with the default captured->captured the leg would be green while asserting nothing.
f="$(run_case "$SCRIPT" "$FX" 'why status: captured never advances' --type build --owner agent --start)"
if [ -n "${f:-}" ]; then
    check "status: in name — name survives" "$(field "$f" name)" '"why status: captured never advances"'
    check "status: in name — field advanced" "$(field "$f" status)" "started-work"
else
    echo "  FAIL  status: case — no task file"; FAIL=$((FAIL + 2))
fi

# 4. created — count=1, and the timestamp is what got injected into the name.
f="$(run_case "$SCRIPT" "$FX" 'the created: stamp drifts under owner:human' --type build --owner human --human-ac 'the ownership field is not empty')"
if [ -n "${f:-}" ]; then
    check "created: in name — name survives" "$(field "$f" name)" '"the created: stamp drifts under owner:human"'
    check "created: in name — field is a timestamp" \
        "$(field "$f" created | grep -cE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T')" "1"
    check "created: in name — ownership still set" "$(field "$f" owner)" "human"
else
    echo "  FAIL  created: case — no task file"; FAIL=$((FAIL + 3))
fi

# 5. The inception branch. It is a near-duplicate of the default branch and carried the
#    identical defect; fixing one would have left every inception exposed.
f="$(run_case "$SCRIPT" "$FX" 'the horizon: now default and the owner: token' --type inception --owner agent --horizon later --recommendation DEFER --rationale 'T-774 probe fixture')"
if [ -n "${f:-}" ]; then
    check "inception branch — name survives" "$(field "$f" name)" '"the horizon: now default and the owner: token"'
    check "inception branch — horizon applied" "$(field "$f" horizon)" "later"
    check "inception branch — ownership applied" "$(field "$f" owner)" "agent"
else
    echo "  FAIL  inception case — no task file"; FAIL=$((FAIL + 3))
fi

echo
echo "--- negative control: restore the pre-fix substitution, require the defect back ---"

# Rebuild the exact pre-fix behaviour for the ownership field in a throwaway copy: an
# unanchored first-match replace over a document that already carries the name.
sed "s|t = _fm(t, 'owner:', 'owner: ' + e\['TC_OWNER'\])|t = t.replace('owner:', 'owner: ' + e['TC_OWNER'], 1)|g" \
    "$SCRIPT" > "$POISON"
chmod +x "$POISON"

if ! grep -q "t.replace('owner:'" "$POISON"; then
    echo "  FAIL  negative control could not be built — the anchor line was not found."
    echo "        The probe cannot demonstrate that it is able to fail, so it is asserting nothing."
    FAIL=$((FAIL + 1))
else
    FXN="$(mkfixture poisoned)"
    f="$(run_case "$POISON" "$FXN" 'SQ-9 upstream: report the owner:human-with-zero-ACs fault' --type build --owner agent)"
    if [ -n "${f:-}" ]; then
        nm="$(field "$f" name)"
        ow="$(field "$f" owner)"
        if [ "$ow" = "" ] && [ "$nm" != '"SQ-9 upstream: report the owner:human-with-zero-ACs fault"' ]; then
            printf '  PASS  pre-fix copy reproduces the defect (name rewritten, ownership emptied)\n'
            printf '        name: %s\n' "$nm"
            PASS=$((PASS + 1))
        else
            printf '  FAIL  pre-fix copy came out CLEAN — this probe does not detect the defect it claims to.\n'
            printf '        name: [%s]  owner: [%s]\n' "$nm" "$ow"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "  FAIL  negative control produced no task file"
        FAIL=$((FAIL + 1))
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
