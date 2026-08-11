#!/usr/bin/env bash
# _t421-drift-mutation-check.sh — prove the claim-drift detector can move.
#
# T-421.
#
# Every mutation is applied to a SCRATCH COPY of the tree, handed to the detector
# via T421_ROOT. The real .claude/settings.json and CLAUDE.md are never touched —
# T-420 established this session what hand-editing the first one costs, and a test
# that spoils a live enforcement file to prove a point has traded a real gate for a
# green line.
#
# THE CASE THAT MATTERS MOST IS N2
# ---------------------------------
# The detector's whole job is separating an assertion from a mention. CLAUDE.md
# contains a sentence saying check-visual-verification "blocks `git commit` when
# .css/.html files are staged" — an assertion verb, in the same sentence as the hook
# name, about a hook that is genuinely not registered. If the opt-in exclusion ever
# stops working, that line becomes a finding, and a detector that reports a
# deliberately-off hook as a broken promise is one people learn to ignore.
#
# So N2 is not a nice-to-have negative: it is the difference between an instrument
# and a nag.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
REAL="$PWD"
DET="$REAL/tools/_t421-enforcement-claim-drift.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0

mkscratch() {   # mkscratch <dir>
  local d="$1"
  mkdir -p "$d/.claude" "$d/.tasks/templates" "$d/.agentic-framework/agents"
  cp -r "$REAL/.agentic-framework/agents/context" "$d/.agentic-framework/agents/context"
  cp "$REAL/.claude/settings.json" "$d/.claude/settings.json"
  cp "$REAL/CLAUDE.md" "$d/CLAUDE.md"
  cp "$REAL"/.tasks/templates/*.md "$d/.tasks/templates/" 2>/dev/null
}

# findings <root> -> newline-separated hook names reported as CLAIMED-BUT-OFF
#
# T-426: the header text this keys on changed when provenance split the report in two.
# That mismatch is worth naming rather than silently repairing — it broke P1/M1/M3
# into EMPTY findings, i.e. the mutation check reported "no drift" for a tree that
# still had drift. A parser coupled to a human-readable heading fails toward silence,
# which is the same failure shape the detector itself exists to catch. Left as string
# matching (the detector has no --json yet) but both headings are asserted by P0 below,
# so a future rewording fails loudly here instead of quietly zeroing the suite.
# Both parsers key on the per-entry PROVENANCE MARKER rather than on indentation.
# Indentation matched the explanatory paragraph under the UPSTREAM block too, so
# upstream() returned "check-arc-id hook never someone upstream written" — five English
# words promoted to hook names. Matching `[authored]` / `[inherited at seed]` keys on
# something the entry has and prose does not.
findings() {
  T421_ROOT="$1" python3 "$DET" 2>/dev/null \
    | awk '/\[authored\]$/{print $1}' | sort -u
}

# upstream <root> -> hook names reported as claimed-by-seeded-prose (not our drift)
upstream() {
  T421_ROOT="$1" python3 "$DET" 2>/dev/null \
    | awk '/\[inherited at seed\]$/{print $1}' | sort -u
}

check() {   # check <name> <expected-newline-list> <actual>
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    printf '  ok    %-44s [%s]\n' "$name" "$(echo "$got" | tr '\n' ' ')"
    pass=$((pass + 1))
  else
    printf '  FAIL  %-44s got[%s] want[%s]\n' "$name" \
      "$(echo "$got" | tr '\n' ' ')" "$(echo "$want" | tr '\n' ' ')"
    fail=$((fail + 1))
  fi
}

echo "=== T-421 claim-drift detector — mutation check ==="

# ---- P0 THE PARSER'S OWN ANCHORS EXIST ---------------------------------------
# findings()/upstream() key on two headings. If either is reworded, every leg that
# uses them silently returns EMPTY and the suite reports a clean tree. Assert the
# anchors themselves so a rewording fails HERE, loudly, in one line — instead of
# turning six real cases green. (T-426: this is exactly how the provenance change
# broke P1/M1/M3, and the failure looked like "no drift found".)
# Both parsers key on the `[inherited at seed]` / `[authored]` markers. The real tree's
# only claim is inherited, so nothing else in this suite would notice that marker being
# reworded — it would just return empty and every leg would go green on a clean bill of
# health. `[authored]` is covered transitively: M1 must return a name through it.
anchors="$(T421_ROOT="$REAL" python3 "$DET" 2>/dev/null | grep -c '\[inherited at seed\]$')"
check "P0 provenance marker the parser expects exists" "1" "$anchors"

# ---- P1 POSITIVE CONTROL -----------------------------------------------------
# An unmutated scratch copy must reproduce the real tree's finding exactly. If this
# drifts, every case below is measuring a scratch tree that is not the subject.
mkscratch "$WORK/base"
BASE="$(findings "$WORK/base")"
check "P1 unmutated scratch == real finding" "check-arc-id" "$BASE"

# ---- N1 NO FALSE POSITIVE ON REFERENCE-ONLY ----------------------------------
# Five scripts self-declare REFERENCE ONLY. None may appear as a finding.
check "N1 no self-declared REFERENCE-ONLY reported" "" \
  "$(echo "$BASE" | grep -E '^(pl007-scanner|session-end|session-silent-scanner|stop-guard|subagent-stop)$')"

# ---- N2 NO FALSE POSITIVE ON A DOCUMENTED OPT-IN -----------------------------
# See the header. CLAUDE.md asserts check-visual-verification "blocks git commit".
check "N2 documented opt-in not reported" "" \
  "$(echo "$BASE" | grep -E '^check-visual-verification$')"

# ---- M1 INJECT A CLAIM -------------------------------------------------------
# Take a hook that is off and unclaimed, and write a sentence that claims it.
# The detector must notice a promise that did not exist a moment ago.
mkscratch "$WORK/m1"
printf '\nThe check-heredoc-cmd-sub hook blocks any edit containing a heredoc.\n' \
  >> "$WORK/m1/CLAUDE.md"
check "M1 injected claim is detected" "$(printf 'check-arc-id\ncheck-heredoc-cmd-sub')" \
  "$(findings "$WORK/m1")"

# ---- M2 SATISFY THE CLAIM ----------------------------------------------------
# Register the hook the tree promises. The finding must disappear — a detector that
# cannot go green is not measuring registration, it is asserting a constant.
mkscratch "$WORK/m2"
python3 - "$WORK/m2/.claude/settings.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["hooks"]["PreToolUse"].append({
    "matcher": "Write|Edit",
    "hooks": [{"type": "command", "command": "/x/bin/fw hook check-arc-id"}],
})
json.dump(d, open(p, "w"), indent=2)
PY
check "M2 registering the hook clears the finding" "" "$(findings "$WORK/m2")"

# ---- M3 CLAIM WITHOUT AN ASSERTION VERB --------------------------------------
# A bare mention must NOT become a finding. This is the mention/assertion split
# tested from the other side: same hook name, same file, no verb.
mkscratch "$WORK/m3"
printf '\nSee also check-heredoc-cmd-sub for details.\n' >> "$WORK/m3/CLAUDE.md"
check "M3 bare mention is not a claim" "check-arc-id" "$(findings "$WORK/m3")"

# ---- M4 BASELINE GROWTH ------------------------------------------------------
# The gate form: a pinned baseline must fail on a NEW false promise and pass on the
# known one.
printf '# baseline\ncheck-arc-id\n' > "$WORK/baseline.txt"
T421_ROOT="$WORK/base" python3 "$DET" --baseline "$WORK/baseline.txt" --quiet >/dev/null 2>&1
r_known=$?
T421_ROOT="$WORK/m1" python3 "$DET" --baseline "$WORK/baseline.txt" --quiet >/dev/null 2>&1
r_grown=$?
check "M4a baseline passes the known finding" "0" "$r_known"
check "M4b baseline fails on a NEW finding"   "1" "$r_grown"

# ---- M6 PROVENANCE DISCRIMINATES (T-426) -------------------------------------
# The defect: the detector asked "does the tree say this?" and never "did WE say it?"
# — so a sentence seeded from upstream read as our drift, and the remedy it printed
# (register the hook / delete the sentence) sent us to fork a vendored default.
#
# A scratch tree with REAL history is the only way to test this, because provenance is
# git blame. Seed commit adds everything (so the templates' arc_id claim arrives WITH
# its file = inherited); a second commit adds a claim of our own = authored.
#
# Both directions asserted. A one-sided test would pass on a detector that simply
# called everything inherited — which would be a detector that can never fail.
mkscratch "$WORK/m6"
(
  cd "$WORK/m6" || exit 1
  git init -q .
  git -c user.email=t@t -c user.name=t add -A
  git -c user.email=t@t -c user.name=t commit -qm "seed" --no-verify
  printf '\nThe check-heredoc-cmd-sub hook blocks any edit containing a heredoc.\n' >> CLAUDE.md
  git -c user.email=t@t -c user.name=t add -A
  git -c user.email=t@t -c user.name=t commit -qm "authored later" --no-verify
) >/dev/null 2>&1
check "M6a seeded claim is UPSTREAM, not our drift" "check-arc-id" "$(upstream "$WORK/m6")"
check "M6b claim written after seed IS our drift"  "check-heredoc-cmd-sub" "$(findings "$WORK/m6")"

# ---- M7 PROVENANCE FAILS LOUD, NOT SILENT ------------------------------------
# No git history at all (every other scratch in this file). Provenance is unknowable,
# and the detector must treat unknown as OURS — an instrument that goes quiet when it
# cannot measure is the failure this whole task is about.
check "M7 no git history -> claim still reported" "check-arc-id" "$(findings "$WORK/base")"

# ---- M5 REFUSES TO ANSWER ON A MISSING INPUT ---------------------------------
# An empty hook directory is an absent measurement, not a clean bill of health.
mkdir -p "$WORK/m5/.agentic-framework/agents/context" "$WORK/m5/.claude"
cp "$REAL/.claude/settings.json" "$WORK/m5/.claude/settings.json"
T421_ROOT="$WORK/m5" python3 "$DET" --quiet >/dev/null 2>&1
check "M5 empty hook dir exits UNKNOWN (2)" "2" "$?"

echo
if [ "$fail" -eq 0 ]; then
  echo "MUTATION CHECK PASS — $pass/$pass cases."
  echo "  Detector moves in both directions (claim added -> found, hook registered ->"
  echo "  cleared), stays silent on a bare mention and on a documented opt-in, and"
  echo "  refuses to answer rather than pass when an input is missing."
  exit 0
fi
echo "MUTATION CHECK FAIL — $fail failed, $pass passed."
exit 1
