#!/usr/bin/env bash
# T-588 — differential: upstream's ## Verification extractor vs ours, same fixtures.
#
# WHY THIS EXISTS. `fw update` would replace our verification gate with upstream's.
# Upstream's extractor is one line (lib/verification-port.sh:177):
#
#     sed -n '/^## Verification/,/^## /p' "$file" | sed '$d' | tail -n +2 | ...
#
# and that line has three separable defects, all of which end in a verification GATE
# doing something other than what the task file says. This tool reproduces each one
# instead of asserting it. A defect report that cannot be run is an opinion.
#
# NEITHER EXTRACTOR IS HAND-COPIED. Both are read out of their source file at runtime
# and executed as the bytes found there. A copy agrees with its original today and
# drifts from it silently tomorrow (PL-259) — and the whole subject of this tool is two
# implementations that were supposed to agree.
#
# WHAT THIS TOOL DELIBERATELY DOES NOT DO. It never EVALUATES an extracted line. It
# compares what the two extractors would HAND to the shell. The distinction matters
# because fixture C exists to show prose reaching the eval loop; running it would be
# staging the very accident being reported.
#
# THE CONTROL RUNS FIRST AND ABORTS. Every assertion below is of the form "these two
# outputs differ" — which a harness that cannot see either output satisfies for free.
# So fixture A runs first as a control: the two extractors MUST disagree on it. If they
# agree, this tool cannot tell them apart, and it exits 2 without reporting anything.
#
# Exit: 0 upstream still defective, ours still correct (the expected state today)
#       1 a differential changed — upstream may have FIXED it, or ours regressed. Read.
#       2 could not look (missing clone, extractor line not found, control failed)
#
# Point it at an upstream clone:  T588_UPSTREAM=/path/to/clone tools/_t588-...sh

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Overridable so a mutated COPY of this file, run from a temp dir, still reaches the REAL
# sources. Without this every copy aborts with "update-task.sh does not exist" — which is
# rc 2, the same rc a correctly-aborting control produces, so teeth legs asserting rc 2
# pass on a merely-broken copy. That false green was measured here, not imagined.
REPO="${T588_REPO:-$REPO}"
UP="${T588_UPSTREAM:-}"
OURS_SRC="$REPO/.agentic-framework/agents/task-create/update-task.sh"

abort() { echo; echo "CANNOT LOOK: $*"; echo "Nothing was compared. This tool's silence is not evidence."; exit 2; }

[ -n "$UP" ] || abort "set T588_UPSTREAM to an upstream clone (git clone --depth 1 <upstream_repo>)."
UP_SRC="$UP/lib/verification-port.sh"
[ -f "$UP_SRC" ] || abort "$UP_SRC does not exist."
[ -f "$OURS_SRC" ] || abort "$OURS_SRC does not exist."

# ---------------------------------------------------------------------------
# Pull the load-bearing lines out of both sources. Not found, or found more than
# once, means the thing under test is not the thing we think it is -> abort.
# ---------------------------------------------------------------------------
grab() { # grab <file> <grep-pattern> <label>
  local hits
  hits=$(grep -c -- "$2" "$1" 2>/dev/null || echo 0)
  [ "$hits" = "1" ] || abort "expected exactly 1 line matching $3 in $1, found $hits. The source moved; this tool must be re-pointed, not trusted."
  grep -m1 -- "$2" "$1"
}

UP_LINE=$(grab "$UP_SRC" "sed -n '/\^## Verification/" "the upstream sed extractor") || exit 2
OURS_LN_LINE=$(grab "$OURS_SRC" '_v_exact_ln=\$(grep -n' "our anchored heading locator") || exit 2
OURS_AWK_LINE=$(grab "$OURS_SRC" 'verify_section=\$(awk -v start=' "our awk extractor") || exit 2

# OUR REFUSAL GUARD, LIFTED WHOLE. The first draft of this tool ran only our two
# extraction lines and then asserted "ours refuses on an ambiguous file" — a property of
# code it had not loaded. Both those legs failed, correctly, and the failure was in the
# harness. So the guard is now taken verbatim: everything from the function's opening
# brace down to the extraction comment. That boundary is the point where detection ends
# and execution begins, which is why it is safe to eval — the loop that runs a task's
# commands lies BELOW the cut and is never loaded here.
GUARD_BODY=$(awk '/^run_verification_commands\(\) \{/{f=1;next} f && /# Anchored extraction:/{exit} f{print}' "$OURS_SRC")
[ -n "$GUARD_BODY" ] || abort "could not lift run_verification_commands()'s detection half out of $OURS_SRC."
grep -q 'COULD NOT READ THE BLOCK' <<<"$GUARD_BODY" || abort "the lifted guard does not contain its own refusal message — the cut landed in the wrong place."
grep -q 'eval "\$cmd"' <<<"$GUARD_BODY" && abort "the lifted guard contains the eval loop. Refusing to load code that would RUN fixture commands."

UP_SED=${UP_LINE%%|*}   # keep the sed range; drop the pipe into upstream's comment_strip.py

upstream_extract() { # what upstream would hand to its eval loop
  local file="$1"
  eval "$UP_SED" 2>/dev/null | sed '$d' | tail -n +2 | grep -vE '^\s*$|^\s*#|^\s*```' || true
}

ours_gate() { # our real guard: prints its refusal, or stays silent and lets the block run
  local TASK_FILE="$1"
  local RED='' NC='' CYAN='' YELLOW='' GREEN=''
  local _v_exact _v_prefix _v_inline _v_exact_ln _v_prefix_ln _v_why
  eval "$GUARD_BODY"
}

ours_extract() { # what ours hands to its eval loop, AFTER the guard has allowed it
  local TASK_FILE="$1" _v_exact_ln verify_section guard
  guard=$(ours_gate "$TASK_FILE" 2>&1); local rc=$?
  if [ "$rc" != "0" ]; then printf '__GATE REFUSES__\n%s\n' "$guard"; return 0; fi
  eval "$OURS_LN_LINE"
  eval "$OURS_AWK_LINE"
  printf '%s\n' "$verify_section" | grep -vE '^\s*$|^\s*#|^\s*```' || true
}

# ---------------------------------------------------------------------------
# Fixtures. Each isolates ONE defect so a failure names a cause, not a symptom.
# ---------------------------------------------------------------------------
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/a.md" <<'EOF'
# Fixture A — Verification is the LAST section in the file

## Acceptance Criteria
- [x] done

## Verification
echo LEG-ONE
echo LEG-TWO
echo LEG-THREE-LAST
EOF

cat > "$TMP/b.md" <<'EOF'
# Fixture B — a second, superseded Verification heading

## Verification
echo REAL-LEG

## Notes
prose here

## Verification (superseded)
echo SHOULD-NOT-RUN

## End
EOF

cat > "$TMP/c.md" <<'EOF'
# Fixture C — a prose section whose heading PREFIXES the real one

## Verification Notes
this line is prose, not a command
echo PROSE-REACHED-THE-EVAL-LOOP

## Verification
echo REAL-LEG

## End
EOF

# ---------------------------------------------------------------------------
# CONTROL — must run before any finding is reported.
# ---------------------------------------------------------------------------
echo "CONTROL — the two extractors must be distinguishable before anything is claimed"
ctl_up=$(upstream_extract "$TMP/a.md"); ctl_ours=$(ours_extract "$TMP/a.md")
if [ "$ctl_up" = "$ctl_ours" ]; then
  echo "  upstream and ours produced IDENTICAL output on fixture A."
  abort "the control fixture cannot separate the two extractors, so every 'they differ' assertion below would be vacuous."
fi
echo "  [ok] they differ on fixture A — the comparison can see something."
echo

fail=0
leg() { # leg <name> <expected-substring-or-!absent> <actual> <why-it-matters>
  local name="$1" want="$2" got="$3" why="$4" ok=1
  if [ "${want:0:1}" = "!" ]; then
    grep -qF -- "${want:1}" <<<"$got" && ok=0
  else
    grep -qF -- "$want" <<<"$got" || ok=0
  fi
  if [ "$ok" = "1" ]; then printf '  [ok  ] %s\n' "$name"
  else fail=1; printf '  [FAIL] %s\n         %s\n         --- actual ---\n%s\n' "$name" "$why" "$(sed 's/^/         /' <<<"$got")"; fi
}

echo "DEFECT 1 — the range has no closing heading, so \`sed '\$d'\` eats a real command"
echo "  Fixture A: '## Verification' is the last section. With no following '## ' to close"
echo "  the range, sed prints to EOF and '\$d' deletes the LAST LINE — which is a leg, not a"
echo "  heading. The gate then reports success over the legs that did run."
a_up=$(upstream_extract "$TMP/a.md"); a_ours=$(ours_extract "$TMP/a.md")
leg "upstream DROPS the final leg" "!echo LEG-THREE-LAST" "$a_up" "upstream now emits the last leg — it may have been FIXED. Re-read line 177."
leg "upstream keeps the earlier legs (so the loss is silent)" "echo LEG-ONE" "$a_up" "expected the first leg to survive"
leg "ours keeps all three" "echo LEG-THREE-LAST" "$a_ours" "OUR extractor dropped a leg — this is a regression in OUR tree"
echo

echo "DEFECT 2 — sed ranges RESTART, so a superseded block is executed too"
echo "  Ours does NOT refuse here, and that is measured rather than assumed: the guard"
echo "  compares the first EXACT heading's line against the first PREFIX heading's, and in"
echo "  fixture B both are line 3, so nothing looks ambiguous to it. The anchored extraction"
echo "  then stops at the next '## ' and the superseded block is simply never reached."
echo "  Right outcome, but note the asymmetry: a prefix heading BELOW the real one is"
echo "  invisible to the guard. It is caught by the extractor, not by the check."
b_up=$(upstream_extract "$TMP/b.md"); b_ours=$(ours_extract "$TMP/b.md")
leg "upstream emits the superseded leg" "echo SHOULD-NOT-RUN" "$b_up" "upstream no longer re-opens the range — possibly FIXED"
leg "ours reaches the real leg" "echo REAL-LEG" "$b_ours" "ours lost the real leg"
leg "ours never reaches the superseded leg" "!echo SHOULD-NOT-RUN" "$b_ours" "OUR extractor picked up a superseded block — regression in our tree"
echo

echo "DEFECT 3 — '/^## Verification/' is a PREFIX match, so a prose section opens the range"
echo "  Fixture C is the worst of the three: the range opens at '## Verification Notes' and"
echo "  CLOSES at the real '## Verification'. Prose is handed to the eval loop AND the real"
echo "  block is skipped entirely. Two failures from one match, in opposite directions."
c_up=$(upstream_extract "$TMP/c.md"); c_ours=$(ours_extract "$TMP/c.md")
leg "upstream hands PROSE to the eval loop" "this line is prose, not a command" "$c_up" "upstream no longer prefix-matches — possibly FIXED"
leg "upstream SKIPS the real leg" "!echo REAL-LEG" "$c_up" "upstream now reaches the real block"
leg "ours refuses rather than guessing" "GATE REFUSES" "$c_ours" "ours did not refuse on a prefix-shadowed file"
echo

echo "SOURCES COMPARED (both read at runtime, neither hand-copied)"
echo "  upstream: $(realpath --relative-to="$UP" "$UP_SRC")  ->  ${UP_SED#"${UP_SED%%[![:space:]]*}"}"
echo "  ours:     ${OURS_SRC#"$REPO/"}"
echo
if [ "$fail" = "0" ]; then
  echo "Upstream is still defective in all three directions; ours is still correct."
  echo "This is the expected state. It is also the standing argument against \`fw update\`."
  exit 0
fi
echo "A DIFFERENTIAL MOVED. Either upstream fixed something (good — re-open the update"
echo "question) or ours regressed (bad). The failing leg above says which."
exit 1
