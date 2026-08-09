#!/usr/bin/env bash
# _t411-census-teeth.sh — prove the census SEPARATES machine-written from authored, and
# refuses to report a proportion over nothing.
#
# The whole value of this tool is one distinction: `application` is 100% present and ~98%
# machine-written, so a census that cannot tell the two apart reports the flattering number
# and answers AEF's question wrongly. Leg 3 is the load-bearing one.
#
# Each leg copies the real subject into a throwaway tree (the script resolves its registers
# from its own location), so the shipped file is exercised rather than a reimplementation.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJECT="${SUBJECT:-$ROOT/tools/memory-application-census.py}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { echo "  ok  $*"; }

# mktree <name> — throwaway tree with the subject at tools/ and empty registers
mktree() {
  local d="$TMP/$1"
  mkdir -p "$d/tools" "$d/.context/project"
  cp "$SUBJECT" "$d/tools/"
  printf 'learnings: []\n' > "$d/.context/project/learnings.yaml"
  printf 'decisions: []\n' > "$d/.context/project/decisions.yaml"
  printf 'patterns: []\n'  > "$d/.context/project/patterns.yaml"
  echo "$d"
}
run() { python3 "$1/tools/$(basename "$SUBJECT")" "${@:2}" 2>&1; }

echo "=== T-411 census teeth (subject: ${SUBJECT#$ROOT/}) ==="

# --- CONTROL: a populated tree censuses cleanly -------------------------------
d="$(mktree control)"
printf 'learnings:\n- id: X-1\n  application: "Grep the tree for siblings first."\n' \
  > "$d/.context/project/learnings.yaml"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "CONTROL: a populated tree must census, else every red below is the fixture. rc=$rc
$out"
else
  ok "CONTROL  populated tree censuses (rc=0)"
fi

# --- (a) ANTI-VACUITY (PL-084) ------------------------------------------------
# "0% authored" over zero records reads exactly like a measured result.
d="$(mktree empty)"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(a) an empty population must exit 2 — a proportion over zero records is a
     statement about nothing, and it renders identically to a real one. rc=$rc
$out"
elif ! echo "$out" | grep -q "VACUOUS"; then
  fail "(a) exited 2 but not for the stated vacuity reason
$out"
else
  ok "(a) empty population -> rc=2 VACUOUS"
fi

# --- (b) THE LOAD-BEARING LEG: machine template is not AUTHORED ---------------
# `Apply when encountering similar <slug> issues` comes from healing/lib/resolve.sh:133.
# It is grammatical, specific-looking and carries the pattern name. Counting it as content
# is exactly how 2.3% becomes 3.8% — the flattering answer to the question AEF asked.
d="$(mktree classes)"
cat > "$d/.context/project/learnings.yaml" <<'YAML'
learnings:
- id: M-1
  application: "Apply when encountering similar retest-link-unreachable issues"
- id: A-1
  application: "Pin a whole-tree absence invariant, not a single-line regex match."
- id: P-1
  application: TBD
- id: P-2
  application: ""
YAML
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(b) census must succeed here. rc=$rc
$out"
elif ! echo "$out" | grep -qE "AUTHORED +1 "; then
  fail "(b) expected exactly 1 AUTHORED — if the machine template is being counted as
     authored, the headline proportion is inflated and the answer to AEF is wrong
$out"
elif ! echo "$out" | grep -qE "MACHINE +1 "; then
  fail "(b) the healing template must be classed MACHINE, not folded into another class
$out"
elif ! echo "$out" | grep -qE "PLACEHOLDER +2 "; then
  fail "(b) TBD and empty-string must both count as PLACEHOLDER
$out"
else
  ok "(b) AUTHORED/MACHINE/PLACEHOLDER split 1/1/2 — template not banked as content"
fi

# --- (b2) reciprocal: authored text must NOT be swallowed by the machine regex -
# Without this, (b) is equally satisfied by a classifier that calls everything MACHINE.
d="$(mktree authored)"
cat > "$d/.context/project/learnings.yaml" <<'YAML'
learnings:
- id: A-1
  application: "Apply the retry wrapper when a similar timeout appears in the importer."
YAML
out="$(run "$d")"; rc=$?
if ! echo "$out" | grep -qE "AUTHORED +1 "; then
  fail "(b2) authored prose that merely CONTAINS the words apply/similar must stay
     AUTHORED — the regex is anchored on the full template for a reason
$out"
else
  ok "(b2) authored prose containing 'apply'/'similar' stays AUTHORED"
fi

# --- (c) verbatim quoting: the count must be checkable -------------------------
if ! echo "$out" | grep -q "retry wrapper"; then
  fail "(c) AUTHORED values must be printed verbatim — a bare count is a claim the
     reader cannot check, which is the failure this whole task is about
$out"
else
  ok "(c) AUTHORED values printed verbatim"
fi

# --- (d) EMITTER DRIFT GUARD ---------------------------------------------------
# The MACHINE regex mirrors a literal in someone else's source. If that literal moves and
# nothing notices, machine text silently starts counting as authored.
d="$(mktree drift)"
out="$(run "$d" --verify-emitters)"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(d) --verify-emitters must fail when the emitter sources are absent. rc=$rc
$out"
elif ! echo "$out" | grep -q "EMITTER DRIFT"; then
  fail "(d) exited 2 but not for the drift reason
$out"
else
  ok "(d) emitter drift detected when the keyed literal is gone"
fi

# --- RECIPROCAL: the live tree censuses, over its real population --------------
out="$(python3 "$SUBJECT" --verify-emitters 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "RECIPROC: the live registers must census. rc=$rc
$out"
elif ! echo "$out" | grep -qE "population: [0-9]{3,} record"; then
  fail "RECIPROC: censused, but not over a three-digit population — a pass over a
     truncated read would look identical
$out"
elif ! echo "$out" | grep -q "emitters ok: 2"; then
  fail "RECIPROC: both live emitters must still carry their literals
$out"
else
  ok "RECIPROC live registers census over their full population"
fi

echo
if [ "$fails" -ne 0 ]; then
  echo "TEETH FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "TEETH PASS — 7/7 legs (control + 5 cases + reciprocal on the live registers)"
