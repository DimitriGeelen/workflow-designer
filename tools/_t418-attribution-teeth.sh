#!/usr/bin/env bash
# _t418-attribution-teeth.sh — the producer-attribution detector must be able to
# return BOTH verdicts, and must not have learned the one fingerprint in hand.
#
# T-418. Subject: tools/_t418-producer-attribution.py
#
# The live capture is red today. A detector only ever observed red is not known to be
# capable of green — that is the same "a leg that has never failed is not known to be
# able to fail" argument as T-416's mutation check, run in the other direction. Legs
# (a) and (b) are the pair; everything after them protects the distinctions.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJECT="${SUBJECT:-$ROOT/tools/_t418-producer-attribution.py}"
FIX="$ROOT/tests/fixtures/termlink-attribution"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
legs=0
# T-430: `fails` alone cannot tell "clean" from "never ran" — both print fails=0 and both
# exit 0. `legs` counts every recorded outcome; the guard below reads legs+fails.
# leg() is defined FIRST so a zero-leg simulation silences the tally that matters, and the
# increment is NOT confined to fail(), the one helper a green run never calls.
# Full rationale: tools/_t400-schema-teeth.sh, tools/_t430-abstention-teeth.sh.
leg()  { legs=$((legs + 1)); }
fail() { leg; echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { leg; echo "  ok  $*"; }

echo "=== T-418 producer-attribution teeth (subject: ${SUBJECT#$ROOT/}) ==="

mk() { # mk <file> <sender> <project|-> <msg_type> <offset>
  local proj_json='null'
  [ "$3" != "-" ] && proj_json="{\"from_project\": \"$3\"}"
  echo "{\"topic\": \"t\", \"offset\": $5, \"sender_id\": \"$2\", \"msg_type\": \"$4\", \"metadata\": $proj_json}" >> "$1"
}

# --- (a) RED on the live capture ------------------------------------------------
out="$(python3 "$SUBJECT" "$FIX"/*.jsonl 2>&1)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(a) live capture must exit 1 (not project-unique). rc=$rc"
elif ! echo "$out" | grep -q "AMBIGUOUS"; then
  fail "(a) live capture is red but no sender was reported AMBIGUOUS.
$out"
else
  ok "(a) live capture red — a fingerprint carrying several from_project values is caught"
fi

# --- (b) GREEN is reachable -----------------------------------------------------
# Without this the detector could be `exit 1` and (a) would still pass.
g="$TMP/green.jsonl"
mk "$g" aaaaaaaaaaaaaaaa 999-peer chat 1
mk "$g" aaaaaaaaaaaaaaaa 999-peer note 2
mk "$g" bbbbbbbbbbbbbbbb 832-Workflow-designer chat 3
out="$(python3 "$SUBJECT" "$g" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] \
  && ok "(b) a single-project capture is GREEN — the detector can pass" \
  || fail "(b) a capture where every sender is project-unique still failed. rc=$rc
$out"

# --- (c) NO FINGERPRINT LITERAL IN THE LOGIC -----------------------------------
# The cheap fix for rail 509 is "treat d1993c2c… as collapsed". That closes the member
# and leaves the class. Fingerprints may appear in prose; they must not appear in code.
stripped="$TMP/nodoc.py"
python3 - "$SUBJECT" "$stripped" <<'PY'
import ast, sys
src = open(sys.argv[1], encoding="utf-8").read()
tree = ast.parse(src)
# Drop every docstring, then re-render: what is left is the logic.
for node in ast.walk(tree):
    if isinstance(node, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
        if (node.body and isinstance(node.body[0], ast.Expr)
                and isinstance(node.body[0].value, ast.Constant)
                and isinstance(node.body[0].value.value, str)):
            node.body.pop(0)
open(sys.argv[2], "w", encoding="utf-8").write(ast.unparse(tree))
PY
if grep -qEi "\b[0-9a-f]{16}\b" "$stripped"; then
  fail "(c) a 16-hex fingerprint literal survives in the detector's LOGIC:
$(grep -nEi "\b[0-9a-f]{16}\b" "$stripped" | head -3)
     Keying on the fingerprint in hand closes this member and leaves the class."
else
  ok "(c) no fingerprint literal in the logic — offenders are derived from the data"
fi

# --- (d) AMBIGUOUS and UNATTRIBUTED are DIFFERENT verdicts ----------------------
# Merging them would be tidier and wrong: one is attribution being wrong, the other is
# attribution being absent, and a remedy for either leaves the other standing.
amb="$TMP/amb.jsonl"; mk "$amb" cccccccccccccccc 999-peer chat 1; mk "$amb" cccccccccccccccc 002-other chat 2
una="$TMP/una.jsonl"; mk "$una" dddddddddddddddd 999-peer chat 1; mk "$una" dddddddddddddddd - chat 2
a_out="$(python3 "$SUBJECT" "$amb" 2>&1)"; u_out="$(python3 "$SUBJECT" "$una" 2>&1)"
if echo "$a_out" | grep -q "AMBIGUOUS" && ! echo "$a_out" | grep -q "UNATTRIBUTED" \
   && echo "$u_out" | grep -q "UNATTRIBUTED" && ! echo "$u_out" | grep -q "AMBIGUOUS"; then
  ok "(d) the two failure classes are reported separately, neither implies the other"
else
  fail "(d) AMBIGUOUS and UNATTRIBUTED are not cleanly separated.
two-project capture said: $(echo "$a_out" | grep -E 'FAIL|ok ' | head -1)
unlabelled capture said:  $(echo "$u_out" | grep -E 'FAIL|ok ' | head -1)"
fi

# --- (e) META envelopes are genuinely skipped ----------------------------------
# The cohort topic's `topic_metadata` envelope carries a from_project of its own,
# written by whoever created the topic. Counting it would manufacture an AMBIGUOUS
# verdict out of bookkeeping — a true finding for a false reason.
m="$TMP/meta.jsonl"
mk "$m" eeeeeeeeeeeeeeee 999-peer chat 1
mk "$m" eeeeeeeeeeeeeeee 010-termlink topic_metadata 2
mk "$m" eeeeeeeeeeeeeeee 002-other receipt 3
out="$(python3 "$SUBJECT" "$m" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] \
  && ok "(e) meta envelopes excluded — bookkeeping cannot manufacture an AMBIGUOUS verdict" \
  || fail "(e) a topic_metadata/receipt envelope was counted as a content post. rc=$rc
$out"

# --- (f) an EMPTY capture is REFUSED, not passed -------------------------------
# G-022, the reason rail-sweep.py exists: an absent measurement rendered as an
# all-clear. A capture with no content envelopes measured nothing.
: > "$TMP/empty.jsonl"
out="$(python3 "$SUBJECT" "$TMP/empty.jsonl" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && echo "$out" | grep -q "REFUSED" \
  && ok "(f) empty capture REFUSED (exit 2) — absence does not render as a clean bill" \
  || fail "(f) an empty capture returned rc=$rc instead of a refusal.
$out"

# --- (g) SELF-CHECK: both directions, and no silent skip -----------------------
s_bad="$TMP/selfbad.jsonl"; mk "$s_bad" ffffffffffffffff 832-Workflow-designer chat 1
s_ok="$TMP/selfok.jsonl";   mk "$s_ok"  1111111111111111 832-Workflow-designer chat 1
out="$(T418_PROJECT=832-Workflow-designer T418_IDENTITY=1111111111111111 \
       python3 "$SUBJECT" --self "$s_bad" 2>&1)"; rc=$?
if [ "$rc" -ne 1 ] || ! echo "$out" | grep -q "self-check"; then
  fail "(g1) our project claimed under a foreign key was not caught. rc=$rc
$out"
else
  ok "(g1) a post claiming us but signed elsewhere is caught"
fi
out="$(T418_PROJECT=832-Workflow-designer T418_IDENTITY=1111111111111111 \
       python3 "$SUBJECT" --self "$s_ok" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] \
  && ok "(g2) correctly-signed posts pass the self-check" \
  || fail "(g2) a correctly-signed post failed the self-check. rc=$rc
$out"
# The dangerous shape: --self asked for, environment missing, detector shrugs and
# reports the topic-wide verdict as though the self-check had run and passed.
out="$(env -u T418_PROJECT -u T418_IDENTITY python3 "$SUBJECT" --self "$s_ok" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] \
  && ok "(g3) --self without an identity REFUSES rather than silently skipping" \
  || fail "(g3) --self ran without T418_IDENTITY and returned rc=$rc — a self-check that
     silently does not run is worse than no self-check. $out"

# --- (h) RECIPROCAL: the committed fixtures carry no message bodies -------------
# The capture drops payloads by construction. If a future edit reintroduces them, these
# fixtures become a conversation transcript in a tracked tree (T-417, third instance).
if grep -l '"payload' "$FIX"/*.jsonl >/dev/null 2>&1; then
  fail "(h) a committed attribution fixture carries payload bytes — the capture must
     project to {offset, sender_id, msg_type, metadata} and drop the body."
else
  ok "(h) committed fixtures are payload-free — routing metadata, no conversation"
fi

echo
# T-430 abstention guard — before the verdict, or the verdict answers first.
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "TEETH FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "TEETH PASS — 10/10 legs (red + green reachable, no literal, classes separated,
             meta skipped, empty refused, self-check both ways + no silent skip,
             fixtures payload-free)"
