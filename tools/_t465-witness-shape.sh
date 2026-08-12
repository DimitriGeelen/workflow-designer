#!/usr/bin/env bash
# _t465-witness-shape.sh — the G-037 witness must state the QUESTION, not just the answer.
#
# `recursive_sees_ignored` is root-dependent: ugrep applies ignore files at or below the
# search root and never above it, so the same needle in the same tree answers differently
# depending on where the sweep starts. A bare verdict cannot be compared against a later
# reading of itself, and comparison is the only thing the witness exists for.
#
# WHAT THIS SCRIPT CAN AND CANNOT DO — stated up front because the gap it serves is exactly
# an instrument that quietly measures something other than its subject. This script is a
# SCRIPT, so its `grep` is /usr/bin/grep (GNU). It can therefore:
#   - re-measure the GATE side of the fixture live, and check the witness's gate numbers
#   - check the witness's SHAPE and internal consistency
# It CANNOT measure the agent side. Spawning is what escapes the shim, so an agent-side
# number obtained from here would be a GNU number wearing a ugrep label — the precise
# confusion G-037 names. Those fields are taken on trust from the tool shell that wrote
# them, and leg AGENT-SIDE below says so out loud rather than letting a green imply cover.
#
# EXIT  0 witness well-formed and its checkable half agrees with reality
#       1 at least one leg failed
#       2 cannot answer (witness absent, or the fixture proved nothing)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Overridable so this checker can be FALSIFIED against a mutated copy without writing to
# the live witness. A check that can only be exercised by damaging its own subject gets run
# once, carefully, and never again (T-463).
W="${WITNESS:-$ROOT/.context/working/.grep-witness}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
legs=0
leg()  { legs=$((legs + 1)); }
fail() { leg; echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { leg; echo "  ok  $*"; }

echo "=== T-465 witness shape (subject: .context/working/.grep-witness) ==="

if [ ! -f "$W" ]; then
  echo "UNKNOWN — no witness at $W. A missing witness is not a pass; it is the" >&2
  echo "absence of the only agent-side reading that exists." >&2
  exit 2
fi

# field <key> — value of a key=value line, ignoring comments.
field() { /usr/bin/grep -E "^$1=" "$W" | head -1 | cut -d= -f2-; }

# --- FIXTURE: rebuild it and re-measure the half this script is entitled to measure ----
mkdir -p "$TMP/fix/sub/pyc"
printf 'sub/pyc/\n' > "$TMP/fix/.gitignore"
printf 'NEEDLE\n'   > "$TMP/fix/sub/pyc/x.txt"
printf 'NEEDLE\n'   > "$TMP/fix/sub/other.txt"
gate_a=$(cd "$TMP/fix"     && /usr/bin/grep -rl NEEDLE . 2>/dev/null | wc -l)
gate_b=$(cd "$TMP/fix/sub" && /usr/bin/grep -rl NEEDLE . 2>/dev/null | wc -l)

# --- VACUITY: the fixture must actually contain something to hide ---------------------
# If GNU cannot see both files from both roots, the fixture never posed the question and
# every verdict below would be an answer about nothing (PL-084).
if [ "$gate_a" -ne 2 ] || [ "$gate_b" -ne 2 ]; then
  echo "UNKNOWN — the fixture is vacuous: GNU grep saw $gate_a file(s) from root A and" >&2
  echo "$gate_b from root B, expected 2 and 2. With nothing for the ignore rule to hide," >&2
  echo "an agent-side 'no' and a broken probe are indistinguishable. Refusing to judge." >&2
  exit 2
fi
ok "VACUITY  fixture poses the question (GNU sees 2 files from both roots)"

# --- SHAPE: the verdict must be qualified by the root it was taken from ---------------
verdict="$(field recursive_sees_ignored)"
sroot="$(field recursive_sees_ignored_search_root)"
if [ -z "$verdict" ]; then
  fail "SHAPE: no recursive_sees_ignored — G-037's closure command reads this key and would
     silently score the INPUTS axis as not-ready for a missing-field reason rather than a
     measured one"
elif [ -z "$sroot" ]; then
  fail "SHAPE: recursive_sees_ignored='$verdict' carries no recursive_sees_ignored_search_root.
     This is the T-465 defect itself: an answer whose question is unstated cannot be
     compared to a later reading, which is the witness's whole job."
else
  ok "SHAPE    verdict '$verdict' is qualified by its search root ($sroot)"
fi

# --- BOTH ROOTS: one labelled root is still a one-sided reading -----------------------
va="$(field recursive_sees_ignored_root_a)"
vb="$(field recursive_sees_ignored_root_b)"
if [ -z "$va" ] || [ -z "$vb" ]; then
  fail "ROOTS: need both recursive_sees_ignored_root_a and _root_b; got a='$va' b='$vb'.
     Root-dependence is only visible when the same probe is taken from a root where the
     ignore rule is in scope and one where it is not."
elif [ "$va" = "$vb" ]; then
  fail "ROOTS: both roots report '$va'. Either the fixture's rule was in scope from both
     roots (so the probe did not vary the thing it claims to vary), or ugrep's root
     handling has changed and the recorded mechanism no longer holds."
else
  ok "ROOTS    the two roots disagree (A=$va, B=$vb) — root-dependence is captured, not asserted"
fi

# --- CONSISTENCY: the canonical answer is the rule-in-scope answer ---------------------
if [ -n "$verdict" ] && [ -n "$va" ] && [ "$verdict" != "$va" ]; then
  fail "CONSISTENCY: canonical recursive_sees_ignored='$verdict' but the rule-in-scope root
     measured '$va'. The canonical key is meant to BE the rule-in-scope reading (that is the
     condition a gate running from the repo root sits in); disagreeing means one of them is
     stale."
else
  ok "CONSISTENCY canonical verdict matches the rule-in-scope root reading"
fi

# --- GATE NUMBERS: the half this script may legitimately check -------------------------
wga="$(field gate_hits_root_a)"; wgb="$(field gate_hits_root_b)"
if [ "$wga" != "$gate_a" ] || [ "$wgb" != "$gate_b" ]; then
  fail "GATE: witness records gate hits A=$wga B=$wgb; re-measuring now gives A=$gate_a
     B=$gate_b. The gate side is the half that does NOT depend on the shim, so a mismatch
     here means the witness drifted from reality on its most checkable claim."
else
  ok "GATE     recorded gate-side counts (A=$wga B=$wgb) reproduce on a live re-measure"
fi

# --- AGENT SIDE: the honest limit, recorded as a leg so it is never mistaken for cover --
aga="$(field agent_hits_root_a)"; agb="$(field agent_hits_root_b)"
if [ -z "$aga" ] || [ -z "$agb" ]; then
  fail "AGENT-SIDE: agent_hits_root_a/_b absent — the only numbers that required the tool
     shell are the ones missing"
else
  ok "AGENT-SIDE recorded as A=$aga B=$agb, TAKEN ON TRUST — this script runs /usr/bin/grep
      and cannot verify them; measuring them from here would produce a GNU number wearing
      a ugrep label, which is the confusion G-037 names"
fi

echo
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "WITNESS FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "WITNESS PASS — $legs legs recorded (vacuity + shape + roots + consistency + gate + agent-side limit)"
