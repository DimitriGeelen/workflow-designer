#!/usr/bin/env bash
# _t420-gate-mutation-check.sh — prove the attribution gate can BLOCK, can ALLOW,
# and discriminates between them for the right reason.
#
# T-420.
#
# WHY A MUTATION CHECK AND NOT A SMOKE TEST
# ------------------------------------------
# A gate is a thing that says no. The failure mode that costs something is a gate
# that says yes to everything — and a suite that only ever feeds it compliant calls
# cannot tell that apart from a gate that works. So every BLOCK case here is a
# mutation of a call that is otherwise correct: exactly one field is spoiled, and
# the verdict has to move.
#
# The reciprocal matters just as much: case 1 is the positive control. If it ever
# starts failing, every PASS below is uninterpretable, because a gate that refuses
# everything is not enforcing attribution — it is broken, and it looks stricter.
#
# WHAT THIS DOES NOT PROVE
# -------------------------
# That the enumeration (module docstring, class A/B/C) is still true. These cases
# exercise the RULES against synthetic calls; they cannot notice that a tool has
# since gained a metadata parameter, or that a new producer shipped. That premise
# has a date on it and no instrument — which is PL-142's shape, stated rather than
# papered over. `bash tools/_t420-gate-mutation-check.sh` will stay green through
# exactly that kind of expiry.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
GATE="tools/_t420-rail-attribution-gate.py"
LABEL="$(basename "$PWD")"

pass=0; fail=0

# check <name> <expected-exit> <json>
check() {
  local name="$1" want="$2" json="$3" got
  printf '%s' "$json" | python3 "$GATE" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    printf '  ok    %-46s exit=%s\n' "$name" "$got"
    pass=$((pass + 1))
  else
    printf '  FAIL  %-46s exit=%s want=%s\n' "$name" "$got" "$want"
    fail=$((fail + 1))
  fi
}

echo "=== T-420 attribution gate — mutation check (label: $LABEL) ==="

# 1 POSITIVE CONTROL. A correct rail post. If this blocks, nothing below means
#   anything: an all-block gate passes every BLOCK case for the wrong reason.
check "correct channel_post (positive control)" 0 \
  "{\"tool_name\":\"mcp__termlink__termlink_channel_post\",\"tool_input\":{\"topic\":\"dm:a:b\",\"payload\":\"hello\",\"metadata\":{\"from_project\":\"$LABEL\",\"thread\":\"T-420\"}}}"

# 2 MUTATION: drop the label. Nothing else changes.
check "M1 label dropped" 2 \
  '{"tool_name":"mcp__termlink__termlink_channel_post","tool_input":{"topic":"dm:a:b","payload":"hello","metadata":{"thread":"T-420"}}}'

# 3 MUTATION: metadata map absent entirely (the 239-envelope shape on the real rail).
check "M2 no metadata map at all" 2 \
  '{"tool_name":"mcp__termlink__termlink_channel_post","tool_input":{"topic":"dm:a:b","payload":"hello"}}'

# 4 MUTATION: label present but empty. Presence-only checks pass this.
check "M3 label present but empty" 2 \
  '{"tool_name":"mcp__termlink__termlink_channel_post","tool_input":{"topic":"dm:a:b","payload":"hello","metadata":{"from_project":""}}}'

# 5 MUTATION: label is another co-resident project's. This is not hypothetical —
#   offsets 2 and 4 on the live rail carry 010-termlink under OUR fingerprint.
check "M4 another project's label" 2 \
  '{"tool_name":"mcp__termlink__termlink_channel_post","tool_input":{"topic":"dm:a:b","payload":"hello","metadata":{"from_project":"010-termlink"}}}'

# 6 MUTATION: case-only difference. The AMBIGUOUS class, not the missing class.
check "M5 case-only mismatch" 2 \
  "{\"tool_name\":\"mcp__termlink__termlink_channel_post\",\"tool_input\":{\"topic\":\"dm:a:b\",\"payload\":\"hello\",\"metadata\":{\"from_project\":\"$(printf '%s' "$LABEL" | tr '[:upper:]' '[:lower:]')\"}}}"

# 7 The second content key + the second attribution channel. A payload-only rule
#   waves this through — which is what this gate was going to be before the
#   enumeration. Kept as a case so the regression is caught, not remembered.
check "agent_post via project= (positive control)" 0 \
  "{\"tool_name\":\"mcp__termlink__termlink_agent_post\",\"tool_input\":{\"text\":\"hello\",\"project\":\"$LABEL\"}}"

check "M6 agent_post text with no project" 2 \
  '{"tool_name":"mcp__termlink__termlink_agent_post","tool_input":{"text":"hello","thread":"T-420"}}'

# 8 Rule 2 (DECLARED): producers with no attribution channel at all.
check "M7 channel_reply (unattributable)" 2 \
  '{"tool_name":"mcp__termlink__termlink_channel_reply","tool_input":{"topic":"dm:a:b","offset":1,"text":"hello"}}'

check "M8 channel_forward (no content key at all)" 2 \
  '{"tool_name":"mcp__termlink__termlink_channel_forward","tool_input":{"src_topic":"x","offset":1,"dst_topic":"y"}}'

# 9 NO COLLATERAL. The cost of a gate is what it blocks that it should not.
#   Read-side termlink calls, and every non-termlink tool, must pass untouched.
check "channel_state read (no content key)" 0 \
  '{"tool_name":"mcp__termlink__termlink_channel_state","tool_input":{"topic":"dm:a:b"}}'

check "channel_quote read (verb-shaped name)" 0 \
  '{"tool_name":"mcp__termlink__termlink_channel_quote","tool_input":{"topic":"dm:a:b","offset":7}}'

check "unrelated tool carrying text" 0 \
  '{"tool_name":"Bash","tool_input":{"command":"echo hi","text":"hello"}}'

check "Write with content, not termlink" 0 \
  '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x","content":"hello","text":"hello"}}'

# 10 Fail-open on garbage: a gate that cannot read its input has measured nothing.
check "unparseable hook input fails open" 0 'not json at all'

echo
if [ "$fail" -eq 0 ]; then
  echo "MUTATION CHECK PASS — $pass/$pass cases."
  echo "  Gate blocks 8 distinct spoilings, allows 6 legitimate calls including two"
  echo "  positive controls. It is not an all-block or an all-allow."
  exit 0
fi
echo "MUTATION CHECK FAIL — $fail failed, $pass passed."
exit 1
