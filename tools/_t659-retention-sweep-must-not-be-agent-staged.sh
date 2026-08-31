#!/usr/bin/env bash
# T-659 — a retention sweep must not ride into a commit on the back of a directory-wide add.
#
# WHY THIS EXISTS. .context/audits/cron/ is pruned by a retention cron, leaving deletions
# pending in the working tree. Committing them is the operator's housekeeping decision, not a
# side effect of whatever the agent happened to be doing. Three sessions held that line by
# staging explicit paths every time — until one `git add .context/`, run to pick up a single
# episodic file, swept 338 deletions into the index. The rule lived in the agent's head and
# the index does not consult it. This prober guards the mechanism that replaced the habit.
#
# WHAT IT MUST NOT DO: it must never touch this repository's index. Every leg runs in a
# throwaway git repo built in a temp dir. It greps the real guard out of hooks.sh rather than
# retyping it, so a rewrite is reported rather than skipped.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T659_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/git/lib/hooks.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-659: retention-sweep deletions must not be agent-staged ==="
echo

GUARD="$TMP/guard.sh"
python3 - "$SRC" > "$GUARD" <<'PY' || exit 3
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n# T-659: retention-sweep deletions are not the agent's to commit\..*?\n    fi\nfi\n",
              src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: the T-659 guard was not found in hooks.sh\n")
    sys.exit(3)
sys.stdout.write(m.group(0))
PY
[ -s "$GUARD" ] || { echo "COULD-NOT-MEASURE: extracted guard was empty" >&2; exit 3; }

# A throwaway repo whose HEAD contains cron audits plus an ordinary tracked file.
make_repo() {
    local r="$TMP/repo-$RANDOM"
    mkdir -p "$r/.context/audits/cron" "$r/.context/episodic"
    ( cd "$r"
      git init -q .
      git config user.email t@t; git config user.name t
      for i in 1 2 3; do echo "audit $i" > ".context/audits/cron/2026-08-13-000$i.yaml"; done
      echo "seed" > .context/episodic/T-001.yaml
      git add -A >/dev/null 2>&1
      git commit -q -m seed >/dev/null 2>&1
    )
    echo "$r"
}

# run_guard <repo> <CLAUDECODE> [FW_ALLOW_RETENTION_SWEEP] -> "rc<N>|output"
run_guard() {
    local repo="$1" cc="$2" allow="${3:-0}"
    local out rc
    out=$( cd "$repo" && CLAUDECODE="$cc" FW_ALLOW_RETENTION_SWEEP="$allow" bash "$GUARD" 2>&1 )
    rc=$?
    printf 'rc%s|%s' "$rc" "$out"
}

# ---------------------------------------------------------------------------
echo "--- the exact accident: a directory-wide add that sweeps the deletions"
R=$(make_repo)
( cd "$R" && rm .context/audits/cron/2026-08-13-0001.yaml .context/audits/cron/2026-08-13-0002.yaml \
  && echo new > .context/episodic/T-002.yaml && git add .context/ >/dev/null 2>&1 )
OUT=$(run_guard "$R" 1)
MISSING=""
case "$OUT" in rc1\|*) ;; *) MISSING="$MISSING did-not-block";; esac
echo "$OUT" | grep -q '2 retention-sweep deletion'  || MISSING="$MISSING the-count"
echo "$OUT" | grep -q 'git reset HEAD .context/audits/' || MISSING="$MISSING the-remedy"
if [ -z "$MISSING" ]; then
    ok "blocked, counted, and told the agent exactly how to unstage"
else
    bad "guard incomplete:$MISSING | got: $(echo "$OUT" | tr '\n' ' ' | head -c 220)"
fi

# ---------------------------------------------------------------------------
# The whole point is that the correct part of the staging survives. A guard that told the
# agent to throw away the work alongside the mistake would be obeyed and would cost more
# than the mistake did.
echo "--- the remedy it prints actually works, and keeps the legitimate file staged"
( cd "$R" && git reset -q HEAD .context/audits/ )
OUT=$(run_guard "$R" 1)
STAGED=$( cd "$R" && git diff --cached --name-only )
if [ "${OUT%%|*}" = "rc0" ] && echo "$STAGED" | grep -q 'episodic/T-002.yaml' \
   && ! echo "$STAGED" | grep -q 'audits/cron'; then
    ok "after the printed remedy: guard passes, episodic still staged, cron gone"
else
    bad "the printed remedy did not leave a committable index: rc=${OUT%%|*} staged=[$(echo "$STAGED" | tr '\n' ' ')]"
fi

# ---------------------------------------------------------------------------
echo "--- ordinary .context/ work is not obstructed"
R2=$(make_repo)
( cd "$R2" && echo x > .context/episodic/T-003.yaml && git add .context/episodic/T-003.yaml >/dev/null 2>&1 )
OUT=$(run_guard "$R2" 1)
if [ "${OUT%%|*}" = "rc0" ]; then
    ok "staging a normal .context/ file passes clean"
else
    bad "guard fired on a commit with no cron deletions: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
# A cron file that is ADDED or MODIFIED is not a retention sweep. --diff-filter=D is
# load-bearing; without it the daily audit writing a new cron file would be blocked.
echo "--- adding a new cron audit is not a sweep (--diff-filter=D is load-bearing)"
R3=$(make_repo)
( cd "$R3" && echo fresh > .context/audits/cron/2026-08-31-0000.yaml \
  && git add .context/audits/cron/2026-08-31-0000.yaml >/dev/null 2>&1 )
OUT=$(run_guard "$R3" 1)
if [ "${OUT%%|*}" = "rc0" ]; then
    ok "a newly written cron audit commits freely"
else
    bad "guard blocked an ADDED cron file — the daily audit could not commit its own output"
fi

# ---------------------------------------------------------------------------
echo "--- the operator is not obstructed, and the documented bypass works"
R4=$(make_repo)
( cd "$R4" && rm .context/audits/cron/2026-08-13-0001.yaml && git add -A >/dev/null 2>&1 )
OUT=$(run_guard "$R4" 0)          # no CLAUDECODE -> operator
OUT2=$(run_guard "$R4" 1 1)       # agent + documented bypass
if [ "${OUT%%|*}" = "rc0" ] && [ "${OUT2%%|*}" = "rc0" ]; then
    ok "operator commits the sweep freely; FW_ALLOW_RETENTION_SWEEP=1 also passes"
else
    bad "operator or bypass path blocked: operator=${OUT%%|*} bypass=${OUT2%%|*}"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: drop the agent-control test and the operator must start being blocked"
MUT="$TMP/guard-mutant.sh"
sed 's|^if \[ "\${CLAUDECODE:-0}" = "1" \] && \[ "\${FW_ALLOW_RETENTION_SWEEP:-0}" != "1" \]; then|if true; then|' "$GUARD" > "$MUT"
MUTATED=$(grep -c '^if true; then' "$MUT" || true)
BASE=$(run_guard "$R4" 0)
if [ "$MUTATED" -ne 1 ]; then
    bad "MUTATION FAILED — expected exactly 1 control test to neutralise, got $MUTATED"
elif [ "${BASE%%|*}" != "rc0" ]; then
    # PL-297 / PL-299: the unmutated subject must demonstrably behave the other way first.
    bad "PRECONDITION FAILED — unmutated guard already blocks the operator, so the mutant proves nothing"
else
    OUT=$( cd "$R4" && CLAUDECODE=0 bash "$MUT" 2>&1; echo "rc$?" )
    if echo "$OUT" | grep -q 'rc1'; then
        ok "mutant blocks the operator the real guard demonstrably lets through"
    else
        bad "mutant changed nothing; the legs above cannot fail and prove nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
