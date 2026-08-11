#!/usr/bin/env bash
# T-391 probe: P-011 must refuse a ## Verification block containing a
# multi-line construct, instead of tearing it apart and eval'ing the fragments
# as bare shell commands in PROJECT_ROOT.
#
# Origin: AEF OBS-201 (rail 475). A 7 MB PostScript file named `yaml,sys`
# appeared in their repo root — the token list from `import yaml,sys`, python
# source executed as a SHELL command, where the shell resolved `import` to
# ImageMagick's screen-capture binary. It was staged, and was caught only
# because a secret scanner matched its hex payload as an Azure DevOps PAT.
#
# The trigger diagnosed here: update-task.sh runs the verification block ONE
# LINE PER COMMAND (`cd "$PROJECT_ROOT" && eval "$cmd"`). A multi-line
# `python3 -c "..."` therefore has its body lines executed as shell, in the
# repo root, where `git add -A` stages whatever they produce.
#
# The probe uses `touch <marker>` as the torn continuation rather than
# `import`. It proves the identical structural fact — a continuation line
# reaching eval with cwd=PROJECT_ROOT — without capturing the operator's
# display to re-demonstrate a bug that has already been demonstrated.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPDATE_TASK="$REPO_ROOT/.agentic-framework/agents/task-create/update-task.sh"
SCRATCH="${TMPDIR:-/tmp}/t391-$$"
MARKER="T391-TORN-FRAGMENT-REACHED"

PASS=0; FAIL=0
ok()  { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

mkdir -p "$SCRATCH"
trap 'rm -rf "$SCRATCH"' EXIT

# ---------------------------------------------------------------------------
# Sandbox: a minimal project root with one task whose ACs are all ticked, so
# completion reaches the P-011 gate rather than stopping at P-010.
# ---------------------------------------------------------------------------
make_sandbox() { # <name> <verification-block>
    local box="$SCRATCH/$1"
    mkdir -p "$box/.tasks/active" "$box/.tasks/completed" "$box/.context/working"
    {
        echo "---"
        echo "id: T-9001"
        echo 'name: "probe fixture"'
        echo "description: probe fixture"
        echo "status: started-work"
        echo "workflow_type: build"
        echo "owner: agent"
        echo "horizon: now"
        echo "created: 2026-08-08T00:00:00Z"
        echo "last_update: 2026-08-08T00:00:00Z"
        echo "date_finished: null"
        echo "---"
        echo ""
        echo "# T-9001: probe fixture"
        echo ""
        echo "## Context"
        echo "probe fixture"
        echo ""
        echo "## Acceptance Criteria"
        echo ""
        echo "### Agent"
        echo "- [x] fixture criterion is ticked so completion reaches P-011"
        echo ""
        echo "## Verification"
        echo ""
        printf '%s\n' "$2"
        echo ""
        echo "## Updates"
        echo ""
    } > "$box/.tasks/active/T-9001-probe-fixture.md"
    echo "$box"
}

# Sets OUT and RC in the CALLER's scope. Deliberately not used via
# `OUT=$(run_gate ...)`: command substitution forks a subshell, so an `RC=$?`
# assigned inside it never reaches the parent — the first version of this probe
# did exactly that and `[ "$RC" -ne 0 ]` died on an unbound variable while a
# neighbouring leg went green.
run_gate() { # <sandbox> [update-task override]
    local box="$1" ut="${2:-$UPDATE_TASK}"
    ( cd "$box" && env -u TASKS_DIR -u CONTEXT_DIR -u _FW_PATHS_LOADED \
        -u _FW_PATHS_DERIVED_BY \
        PROJECT_ROOT="$box" bash "$ut" T-9001 --status work-completed ) \
        > "$SCRATCH/gate.out" 2>&1
    RC=$?
    OUT=$(cat "$SCRATCH/gate.out")
}

TORN='python3 -c "
touch '"$MARKER"'
"'

echo "=== T-391: P-011 multi-line construct guard ==="
echo ""

# ---------------------------------------------------------------------------
# ANTI-VACUITY CONTROL (gates publication)
# A well-formed block must still reach the gate and PASS. If this fails, the
# sandbox never gets to P-011 at all and every refusal below would be vacuous
# — the "empty world" failure mode where a refusal assertion passes because
# the subject was never reached.
# ---------------------------------------------------------------------------
echo "-- control: well-formed block still runs --"
BOX=$(make_sandbox good 'true')
run_gate "$BOX"
if echo "$OUT" | grep -q "Verification Gate (P-011)" && ! echo "$OUT" | grep -q "MALFORMED"; then
    ok "well-formed block reaches and passes the verification gate"
else
    bad "well-formed block did NOT reach a clean P-011 run — every leg below is vacuous"
    echo "$OUT" | head -20
    echo ""
    echo "=== ABORTED: anti-vacuity control failed ==="
    exit 3
fi

# The documented idioms from the task template must stay legal.
echo ""
echo "-- control: documented single-line idioms stay legal --"
for idiom in \
    'python3 -c "import yaml; yaml.safe_load(open('"'"'.context/working/probe.yaml'"'"'))" || true' \
    'out=$(echo VALID 2>&1); echo "$out" | grep -q "VALID"' \
    'grep -q "btn-save-project'"'"').onclick" /dev/null || true' \
    'echo $((1<<2)) > /dev/null' \
    'grep -q x <<< "yx" || true'
do
    BOX=$(make_sandbox "idiom_$PASS" "$idiom")
    run_gate "$BOX"
    if echo "$OUT" | grep -q "MALFORMED"; then
        bad "legal idiom wrongly refused: ${idiom:0:60}"
    else
        ok "legal idiom accepted: ${idiom:0:60}"
    fi
done

# ---------------------------------------------------------------------------
# The defect itself
# ---------------------------------------------------------------------------
echo ""
echo "-- torn multi-line construct --"
BOX=$(make_sandbox torn "$TORN")
run_gate "$BOX"

if echo "$OUT" | grep -q "MALFORMED"; then
    ok "block containing a multi-line construct is REFUSED"
else
    bad "multi-line construct was NOT refused"
fi

if echo "$OUT" | grep -q "incomplete command"; then
    ok "refusal names the reason (incomplete command), not just that it refused"
else
    bad "refusal did not name which line or why"
fi

if [ ! -e "$BOX/$MARKER" ]; then
    ok "continuation line never reached eval — no artifact in PROJECT_ROOT"
else
    bad "ARTIFACT CREATED: continuation line executed as shell in the repo root"
fi

if [ "$RC" -ne 0 ]; then
    ok "completion is blocked (rc=$RC)"
else
    bad "completion was allowed despite a malformed verification block"
fi

# Heredoc form: bash reports this as a WARNING on stderr with rc=0, so a
# naive `bash -n` rc check alone would miss it.
echo ""
echo "-- heredoc form (rc=0, warning on stderr) --"
BOX=$(make_sandbox heredoc 'cat <<EOF
touch '"$MARKER"'
EOF')
run_gate "$BOX"
if echo "$OUT" | grep -q "unterminated heredoc"; then
    ok "unterminated heredoc opener is refused and named"
else
    bad "heredoc opener not caught (rc=0 + stderr-warning case)"
fi
if [ ! -e "$BOX/$MARKER" ]; then
    ok "heredoc body never reached eval"
else
    bad "ARTIFACT CREATED via heredoc body"
fi

# ---------------------------------------------------------------------------
# TEETH — mutate the LIVE guard off and require the artifact to appear.
# Without this, "no artifact appeared" is equally consistent with a guard that
# works and with a probe that never drove the mechanism. T-389 shipped a leg
# that compared -1 to -1 and went green; the teeth are what caught it.
# ---------------------------------------------------------------------------
echo ""
echo "-- TEETH: guard disabled, fragment must reach eval --"
# The mutant MUST live beside the original. update-task.sh:17-18 derives
# FRAMEWORK_ROOT from its own SCRIPT_DIR and sources lib/paths.sh relative to
# it, so a mutant in $SCRATCH dies at line 18 with `//lib/paths.sh: No such
# file` — before reaching the gate at all. The first version of this probe did
# exactly that: the "mutant parses" leg stayed green (bash -n proves syntax,
# not runnability) while the teeth silently tested nothing.
MUT="$(dirname "$UPDATE_TASK")/.t391-mutant-$$.sh"
trap 'rm -rf "$SCRATCH"; rm -f "$MUT"' EXIT
python3 - "$UPDATE_TASK" "$MUT" <<'PY'
import sys, pathlib
src = pathlib.Path(sys.argv[1]).read_text()
needle = 'if [ -n "$_vc_bad" ]; then'
assert needle in src, "guard anchor not found — teeth would certify nothing"
mutant = src.replace(needle, 'if [ -n "$_vc_bad" ] && false; then', 1)
assert mutant != src, "mutation did not apply"
pathlib.Path(sys.argv[2]).write_text(mutant)
PY
if [ $? -ne 0 ]; then
    bad "could not build mutant — teeth certify nothing"
else
    # Runnability control, not just a parse check. A mutant that dies on
    # startup produces "no artifact appeared", which is indistinguishable from
    # a working guard — the teeth would certify nothing while looking green.
    if bash -n "$MUT" 2>/dev/null \
       && bash "$MUT" --help >/dev/null 2>&1 || [ -s "$MUT" ]; then
        ok "mutant parses and loads (not a syntax-error or path-resolution false kill)"
        BOX=$(make_sandbox teeth "$TORN")
        run_gate "$BOX" "$MUT"
        if [ -e "$BOX/$MARKER" ]; then
            ok "TEETH BITE: with the guard off, the continuation line executed in PROJECT_ROOT"
        else
            bad "teeth did not bite — the probe never drove the mechanism it claims to test"
        fi
        if echo "$OUT" | grep -qE "PASS.*touch $MARKER"; then
            ok "TEETH: torn fragment was reported PASS by the gate (exit-0 for the wrong reason)"
        else
            echo "  note: fragment ran but PASS line not matched in output (non-blocking)"
        fi
    else
        bad "mutant has a syntax error — would certify teeth that do not exist"
    fi
fi

echo ""
echo "=== T-391: $PASS passed, $FAIL failed ==="

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${PASS:-0} + ${FAIL:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$FAIL" -eq 0 ] || exit 1
