#!/usr/bin/env bash
# T-654 — a task that reaches .tasks/completed/ must not still store horizon: now.
#
# WHY THIS EXISTS. CTL-030 fails on T-542 and T-574: both sit in .tasks/completed/
# while their frontmatter still says `horizon: now`. The audit can see the lie but
# not its author. update-task.sh has TWO paths that move a file into completed/:
#
#   region B  (~line 2064)  the ordinary transition, started-work → work-completed.
#                           Nulls the stored horizon at line ~2147 (T-2163/T-2300).
#   region A  (~line 1541)  the PARTIAL-COMPLETE RECHECK, work-completed →
#                           work-completed on a file still in active/. Moves the
#                           file, generates the episodic — and never touches horizon.
#
# `fw task archive-eligible` routes exclusively through region A (bin/fw:3403 re-invokes
# `fw task update <id> --status work-completed`). So the sweep the audit RECOMMENDS —
# right now, on two stuck tasks — is the one path that leaves the horizon lie behind.
#
# That is the claim this prober tests. It is a claim about a live code path, not about
# the two historical records, and it is worth testing precisely because running the
# recommended command would otherwise manufacture two fresh CTL-030 FAILs.
#
# WHAT IT MUST NOT DO:
#   1. It must not touch the real .tasks/ or the real .context/. Completing a live task
#      to watch a field is not reversible. Every leg runs update-task.sh against a
#      throwaway PROJECT_ROOT under mktemp.
#   2. It must not retype the fix. It runs the REAL update-task.sh, so a rewrite of
#      either region is reported rather than skipped.
#
# BOTH HALVES OR NEITHER (001-CashWeb @851): a rig that proves "region A leaves
# horizon: now" proves nothing on its own — a sandbox too broken to null ANY horizon
# looks identical. Leg 2 drives the ORDINARY path through the same sandbox and
# requires horizon: null. Only the pair separates "region A is defective" from
# "this rig cannot null a horizon".
#
# OUTCOME. Confirmed, and fixed in update-task.sh region A (the added null carries a
# `# T-654` marker, which the teeth leg anchors on). Two things nearly hid it:
#   - leg 2 went green through region B and looked like an answer to leg 3's question.
#     A partial-complete run leaves `status: started-work`, so the obvious way to build
#     the fixture never enters region A at all. Asserting WHICH path archived the file
#     is what separated the two worlds.
#   - the first mutant lived in a bare temp dir, could not source lib/paths.sh, and
#     nulled nothing — a dead subject reads exactly like a regressed one.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T654_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
UPDATE="$PROJ/.agentic-framework/agents/task-create/update-task.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -x "$UPDATE" ] || { echo "COULD-NOT-MEASURE: $UPDATE not executable" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM
ROOT="$TMP/sandbox"

echo "=== T-654: a task in completed/ must not still store horizon: now ==="
echo

mkdir -p "$ROOT/.tasks/active" "$ROOT/.tasks/completed" \
         "$ROOT/.context/working" "$ROOT/.context/episodic"
printf 'project: t654-sandbox\n' > "$ROOT/.framework.yaml"
git -C "$ROOT" init -q 2>/dev/null
git -C "$ROOT" config user.email t654@example.invalid
git -C "$ROOT" config user.name  t654

# write_task <id> <status> <owner> <human-ac-state: x| >
# The Human AC state is the whole experiment: an unticked one routes the FIRST
# completion into partial-complete (stays in active/), which is the state region A
# exists to resolve.
write_task() {
    local id="$1" status="$2" owner="$3" human_box="$4"
    cat > "$ROOT/.tasks/active/${id}-probe.md" <<EOF
---
id: $id
name: "t654 probe"
description: >
  t654 probe

status: $status
workflow_type: build
owner: $owner
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-08-31T00:00:00Z
last_update: 2026-08-31T00:00:00Z
date_finished:
---

## Context

Probe fixture. Not a real task.

## Acceptance Criteria

### Agent
- [x] agent criterion

### Human
- [$human_box] human criterion

## Verification

# none

## Updates
EOF
    printf 'current_task: %s\n' "$id" > "$ROOT/.context/working/focus.yaml"
}

# complete <id> -> runs the REAL update-task.sh against the sandbox root.
complete() {
    local id="$1"
    ( unset TASKS_DIR CONTEXT_DIR _FW_PATHS_LOADED _FW_PATHS_DERIVED_BY
      cd "$ROOT" || exit 9
      PROJECT_ROOT="$ROOT" TASKS_DIR="$ROOT/.tasks" CONTEXT_DIR="$ROOT/.context" \
      CLAUDECODE="" \
        bash "$UPDATE" "$id" --status work-completed
    ) > "$TMP/$id.out" 2>&1
    echo "$?"
}

# stored_horizon <id> -> the horizon value as it now stands, wherever the file is
stored_horizon() {
    local id="$1" f
    f=$(ls "$ROOT/.tasks/completed/${id}-probe.md" 2>/dev/null \
        || ls "$ROOT/.tasks/active/${id}-probe.md" 2>/dev/null) || return 1
    grep '^horizon:' "$f" | head -1 | sed 's/^horizon:[[:space:]]*//'
}

located_in() {
    local id="$1"
    [ -f "$ROOT/.tasks/completed/${id}-probe.md" ] && { echo completed; return; }
    [ -f "$ROOT/.tasks/active/${id}-probe.md" ]    && { echo active;    return; }
    echo missing
}

# ---------------------------------------------------------------------------
echo "--- leg 1 (control, ordinary path): started-work -> completed nulls the horizon"
write_task T-9001 started-work agent x
RC1=$(complete T-9001)
LOC1=$(located_in T-9001); H1=$(stored_horizon T-9001 || echo "<none>")
if [ "$LOC1" != "completed" ]; then
    echo "COULD-NOT-MEASURE: the ordinary path did not move the file (loc=$LOC1, rc=$RC1)" >&2
    echo "  --- update-task.sh output ---" >&2; tail -20 "$TMP/T-9001.out" >&2
    exit 3
fi
if [ "$H1" = "null" ]; then
    ok "ordinary completion: in completed/, horizon: null — the rig CAN observe a nulled horizon"
else
    bad "ordinary completion left horizon: '$H1' — expected null. Rig or region B is broken; leg 2 would prove nothing."
fi

# ---------------------------------------------------------------------------
echo "--- leg 2 (the claim): partial-complete, then the recheck that archives it"
write_task T-9002 started-work agent " "
RC2A=$(complete T-9002)
LOC2A=$(located_in T-9002)
if [ "$LOC2A" != "active" ]; then
    echo "COULD-NOT-MEASURE: an unticked Human AC did not produce partial-complete (loc=$LOC2A, rc=$RC2A)" >&2
    echo "  --- update-task.sh output ---" >&2; tail -20 "$TMP/T-9002.out" >&2
    exit 3
fi
ok "partial-complete reached: file stayed in active/ with an unticked Human AC"

# What is the stored horizon of a task that is partial-complete and STILL IN ACTIVE/?
# update-task.sh's own comment at the null site (T-2300) asserts an answer:
#   "Partial-complete branch does NOT touch this — that file stays in active/ and
#    renders via the stored horizon."
# That sentence is a claim about behaviour, sitting in a comment, where nothing tests it.
# It is worth one line to find out, because the task it describes is a task waiting on a
# HUMAN: if its horizon is nulled while it sits in active/, the record the operator is
# meant to act on has quietly lost its scheduling axis.
H2P=$(stored_horizon T-9002 || echo "<none>")
if [ "$H2P" = "now" ]; then
    ok "partial-complete in active/: horizon still 'now' — matches the comment at the null site"
else
    bad "partial-complete in active/: horizon is '$H2P', but update-task.sh's T-2300 comment claims the partial branch does not touch it. One of the two is wrong."
fi

# The human ticks their box. This is the ONLY edit — exactly what a human does before
# re-running completion, and what `fw task archive-eligible` assumes has happened.
sed -i 's/^- \[ \] human criterion/- [x] human criterion/' "$ROOT/.tasks/active/T-9002-probe.md"
printf 'current_task: T-9002\n' > "$ROOT/.context/working/focus.yaml"

RC2B=$(complete T-9002)
LOC2B=$(located_in T-9002); H2=$(stored_horizon T-9002 || echo "<none>")
if [ "$LOC2B" != "completed" ]; then
    echo "COULD-NOT-MEASURE: the recheck did not archive the task (loc=$LOC2B, rc=$RC2B)" >&2
    echo "  --- update-task.sh output ---" >&2; tail -20 "$TMP/T-9002.out" >&2
    exit 3
fi
# WHICH path archived it? update-task.sh has two, and only one of them can reach the
# single `horizon: null` site (update-task.sh:2147, the only writer in the framework —
# grep proves it). Region A (the partial-complete recheck, ~1541) prints
# "Re-checking partial-complete status..."; region B (the ordinary transition, ~2064)
# does not, and is gated on OLD_STATUS != work-completed. Asserting the horizon without
# asserting the path would let a green here mean either "region A nulls it" or "this
# fixture never entered region A" — two different worlds, one indistinguishable result.
if grep -q 'Re-checking partial-complete status' "$TMP/T-9002.out"; then
    ARCHIVER="region-A (partial-complete recheck)"
else
    ARCHIVER="region-B (ordinary transition)"
fi
echo "        (archived by: $ARCHIVER)"
if [ "$H2" = "null" ]; then
    ok "archived after human sign-off via $ARCHIVER: horizon: null"
else
    bad "archived via the partial-complete recheck but horizon is '$H2' — this is the CTL-030 source (update-task.sh region A never nulls it)"
fi

# ---------------------------------------------------------------------------
# Leg 3 is the one that matters, and leg 2 is the reason it needs writing.
#
# Leg 2 reached completed/ with a nulled horizon and looked like a green for the whole
# question — until it was asked WHICH path did it, and answered "region B". A
# partial-complete run leaves `status: started-work`; ticking the human box and
# re-running is therefore an ORDINARY transition, and region A is never entered. The
# green was real and about the wrong path.
#
# Region A's entry condition is a file sitting in active/ that already stores
# `status: work-completed` — the state `fw audit` calls a "stuck partial-complete task"
# and `fw task archive-eligible` exists to sweep. Constructing it directly is not
# cheating: it is the only way to reach the branch, and it is the state the sweep finds.
echo "--- leg 3 (region A): a task stuck in active/ AS work-completed, then archived"
write_task T-9005 work-completed human x
RC3=$(complete T-9005)
LOC3=$(located_in T-9005); H3=$(stored_horizon T-9005 || echo "<none>")
if grep -q 'Re-checking partial-complete status' "$TMP/T-9005.out"; then
    ARCHIVER3="region-A (partial-complete recheck)"
else
    ARCHIVER3="region-B (ordinary transition)"
fi
if [ "$LOC3" != "completed" ] || [ "$ARCHIVER3" != "region-A (partial-complete recheck)" ]; then
    echo "COULD-NOT-MEASURE: leg 3 did not enter region A (loc=$LOC3, path=$ARCHIVER3, rc=$RC3)" >&2
    echo "  --- update-task.sh output ---" >&2; tail -20 "$TMP/T-9005.out" >&2
    exit 3
fi
ok "region A entered and the task was archived (this is what 'fw task archive-eligible' drives)"
if [ "$H3" = "null" ]; then
    ok "region A archived it with horizon: null"
else
    bad "region A archived it with horizon: '$H3' — region A moves the file to completed/ but never reaches the null site (update-task.sh:2147 is inside region B, which is gated on OLD_STATUS != work-completed). This is the CTL-030 source, and 'fw task archive-eligible' drives straight through it."
fi

# ---------------------------------------------------------------------------
# Teeth. Leg 2 can only be trusted if it would have FAILED before the fix. Revert the
# fix in a mutant copy and require leg 2's assertion to flip while leg 1's holds — the
# same both-halves discipline the file header describes, applied to the mutant.
echo "--- teeth: revert the region-A null and leg 3 must stop passing (leg 1 must not)"
# The mutant cannot simply live in $TMP. update-task.sh derives FRAMEWORK_ROOT from its
# own location (line 17) and sources lib/paths.sh, lib/enums.sh, lib/keylock.sh from
# there; a copy in a bare temp dir dies on the first `source` and nulls nothing — which
# reads exactly like "the fix regressed", and did, until this was chased down. So the
# mutant gets a framework-shaped farm: its own agents/task-create/update-task.sh, with
# every other framework directory symlinked to the real one. Nothing real is written.
FARM="$TMP/fw-farm"
mkdir -p "$FARM/agents/task-create"
for _d in "$PROJ/.agentic-framework"/*; do
    _b=$(basename "$_d")
    [ "$_b" = "agents" ] && continue
    ln -s "$_d" "$FARM/$_b"
done
for _d in "$PROJ/.agentic-framework/agents"/*; do
    _b=$(basename "$_d")
    [ "$_b" = "task-create" ] && continue
    ln -s "$_d" "$FARM/agents/$_b"
done
for _f in "$PROJ/.agentic-framework/agents/task-create"/*; do
    _b=$(basename "$_f")
    [ "$_b" = "update-task.sh" ] && continue
    ln -s "$_f" "$FARM/agents/task-create/$_b"
done
MUT="$FARM/agents/task-create/update-task.sh"
# Anchored on the fix's own `# T-654` marker so the mutation reverts REGION A ONLY. The
# generic anchor (the _sed_i text alone) matches both null sites, breaks the ordinary
# path too, and then leg 3's regression cannot be attributed to region A at all — which
# is what this leg reported before the marker existed.
sed 's|^\([[:space:]]*\)_sed_i .*# T-654$|\1: # T-654 reverted|' "$UPDATE" > "$MUT"
REVERTED=$(grep -c '# T-654 reverted' "$MUT" || true)
REMAINING=$(grep -c 'horizon: null/" "\$TASK_FILE"' "$MUT" || true)
if [ "$REVERTED" -ne 1 ]; then
    bad "MUTATION FAILED — expected exactly 1 T-654-marked null to revert, neutralised $REVERTED. Assert the count: a partial mutation is indistinguishable from a passing subject."
elif [ "$REMAINING" -lt 1 ]; then
    bad "MUTATION TOO BROAD — region B's null was neutralised as well ($REMAINING left); leg 1 would fail for the wrong reason."
else
    UPDATE_SAVED="$UPDATE"; UPDATE="$MUT"
    write_task T-9006 work-completed human x
    complete T-9006 >/dev/null
    M_ARCHIVED=$(stored_horizon T-9006 || echo "<none>")

    write_task T-9007 started-work agent x
    complete T-9007 >/dev/null
    M_ORDINARY=$(stored_horizon T-9007 || echo "<none>")
    UPDATE="$UPDATE_SAVED"

    if [ "$M_ARCHIVED" != "null" ] && [ "$M_ORDINARY" = "null" ]; then
        ok "mutant: region-A horizon='$M_ARCHIVED' (regressed), region-B horizon='null' (intact) — leg 3 is load-bearing and leg 1 is independent of it"
    elif [ "$M_ORDINARY" != "null" ]; then
        bad "mutant broke the ORDINARY path too (horizon='$M_ORDINARY') — the mutation is too broad to attribute leg 3's failure to region A"
    else
        bad "mutant still nulled region A's horizon ('$M_ARCHIVED') — leg 3 cannot fail and proves nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
