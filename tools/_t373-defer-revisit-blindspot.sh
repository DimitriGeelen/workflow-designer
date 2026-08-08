#!/usr/bin/env bash
# _t373-defer-revisit-blindspot.sh — a DEFER decision with no revisit date is not
# "nothing to do", and until now the daily scan could not tell the difference.
#
# THE CLAIM, IN TWO HALVES:
#   (a) `fw inception decide <id> defer` never sets `revisit_at` — the string does not
#       occur anywhere in lib/inception.sh.
#   (b) revisit-due-scan.sh skipped any task without a valid revisit_at, so the state
#       (a) produces is exactly the state the scanner cannot see.
#
# Together: the canonical way to create a deferral produced a task that would never
# ripen, and nothing reported it. Absence carried two meanings — "deliberately no
# date" and "nobody set one" — and the silent branch was the harmful one.
#
# WHY THIS DRIVES THE REAL SCANNER. Quoting `[ -z "$revisit_at" ] && continue` proves
# the line exists, not that the behaviour follows from it: PROJECT_ROOT resolution,
# frontmatter parsing and the date comparison all sit between that line and the
# outcome. This runs the actual script against real task files in a synthetic project.
#
# TEETH IN BOTH DIRECTIONS. A scan that reports nothing for the dateless task proves
# nothing on its own — a scanner pointed at the wrong directory, or broken outright,
# reports nothing for everything. So every run also requires a RIPE task to be found
# and a FUTURE-dated task to be correctly ignored. If those two do not behave, the
# dateless verdict is declared unreadable and the harness exits non-zero.
#
# WHAT IS DELIBERATELY NOT TESTED: `fw inception decide` itself. Recording an inception
# decision is operator authority, and the obvious end-to-end test is the one I must not
# run. Half (a) is therefore established statically — an occurrence count over the whole
# file, which is decisive for "cannot set it" in a way a sampled read would not be.
#
# Usage: bash tools/_t373-defer-revisit-blindspot.sh
# Exit 0 = controls behaved and the remedy discriminates. 1 = otherwise.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# T373_SCAN lets the harness run against a DIFFERENT scanner build — used to prove it
# has teeth by pointing it at the pre-fix version (PL-061: a check that cannot go red is
# not evidence). Defaults to the live one.
SCAN="${T373_SCAN:-$REPO/.agentic-framework/agents/context/revisit-due-scan.sh}"
INCEPTION="$REPO/.agentic-framework/lib/inception.sh"

pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

echo "T-373 — DEFER produces the task state the revisit scanner cannot see"
echo

# --- half (a): static, whole-file occurrence count ---------------------------
echo "(a) can the DEFER path set revisit_at at all?"
n_occ=$(grep -c "revisit_at" "$INCEPTION" 2>/dev/null || true)
if [ "${n_occ:-0}" -eq 0 ]; then
  ok "revisit_at occurs 0 times in lib/inception.sh — no code path can set it"
else
  bad "revisit_at occurs $n_occ time(s) in lib/inception.sh — re-read; the premise may have changed"
fi
echo

# --- half (b): drive the real scanner ----------------------------------------
echo "(b) what does the real scanner do with each shape?"
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/.tasks/active" "$ROOT/.context/working"
touch "$ROOT/.framework.yaml"   # the PROJECT_ROOT marker the scanner walks up to find

RIPE=$(date -u -d '-3 days' +%Y-%m-%d 2>/dev/null || date -u -v-3d +%Y-%m-%d)
FUTURE=$(date -u -d '+30 days' +%Y-%m-%d 2>/dev/null || date -u -v+30d +%Y-%m-%d)

# A: the shape `fw inception decide ... defer` actually produces — parked, DEFER
#    recorded in the body, no revisit_at anywhere.
cat > "$ROOT/.tasks/active/T-901-dateless.md" <<EOF
---
id: T-901
name: "dateless deferral — the shape inception decide defer produces"
status: captured
horizon: later
---
## Decision

**Decision**: DEFER

**Rationale**: parked pending evidence
EOF

# B: positive control — a deferral with a date already past. MUST be reported.
cat > "$ROOT/.tasks/active/T-902-ripe.md" <<EOF
---
id: T-902
name: "ripe deferral"
status: captured
horizon: later
revisit_at: $RIPE
---
## Decision

**Decision**: DEFER

**Rationale**: revisit when the upstream lands
EOF

# C: negative control — dated, not yet due. MUST stay quiet in BOTH files.
cat > "$ROOT/.tasks/active/T-903-future.md" <<EOF
---
id: T-903
name: "future deferral"
status: captured
horizon: later
revisit_at: $FUTURE
---
## Decision

**Decision**: DEFER

**Rationale**: not yet
EOF

# D: a normal active task, no Decision block at all. Must appear in NEITHER file —
#    otherwise the new rule is just "report every task that lacks a date", which
#    would bury the signal it exists to raise.
cat > "$ROOT/.tasks/active/T-904-normal.md" <<EOF
---
id: T-904
name: "ordinary task, no decision recorded"
status: started-work
horizon: now
---
## Context
nothing deferred here
EOF

PROJECT_ROOT="$ROOT" bash "$SCAN"
rc=$?
DUE="$ROOT/.context/working/.revisits-due.txt"
UND="$ROOT/.context/working/.revisits-undated.txt"
[ "$rc" -eq 0 ] && ok "scanner exits 0" || bad "scanner exits $rc"

has() { [ -f "$1" ] && grep -q "$2" "$1" 2>/dev/null; }

# Controls first: if these misbehave, nothing else is interpretable.
if has "$DUE" "T-902"; then
  ok "CONTROL ripe deferral T-902 is reported — the scanner works and is pointed correctly"
else
  bad "CONTROL ripe deferral T-902 NOT reported — scanner broken or mis-rooted; read nothing below"
fi
if has "$DUE" "T-903"; then
  bad "CONTROL future-dated T-903 reported as ripe — date comparison is wrong"
else
  ok "CONTROL future-dated T-903 correctly not ripe"
fi

# The finding, and the remedy.
if has "$UND" "T-901"; then
  ok "dateless deferral T-901 IS surfaced (separate signal: .revisits-undated.txt)"
else
  bad "dateless deferral T-901 still invisible — the remedy does not fire"
fi
if has "$DUE" "T-901"; then
  bad "T-901 leaked into .revisits-due.txt — that file means 'ripe today'; a dateless"
  bad "      deferral is not ripe, and widening that signal is the ambiguity we removed"
else
  ok "T-901 kept OUT of .revisits-due.txt — the two signals stay distinct"
fi
if has "$UND" "T-903"; then
  bad "dated deferral T-903 reported as undated — the remedy cannot tell dated from not"
else
  ok "dated deferral T-903 not reported as undated — remedy discriminates"
fi
if has "$UND" "T-904"; then
  bad "ordinary task T-904 reported as an undated deferral — rule is too broad, it would"
  bad "      report most of the corpus and bury the signal"
else
  ok "ordinary non-deferred task T-904 not reported — rule is scoped to DEFER decisions"
fi

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
echo "  Partition is now total: a DEFER is either dated (ripe -> .revisits-due.txt, or"
echo "  pending) or explicitly surfaced as dateless. Absence is no longer the silent case."
exit 0
