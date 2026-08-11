#!/usr/bin/env bash
# _t436-inbox-route-probe.sh — does the handover actually carry observation CONTENT,
# or only the count?
#
# T-436 / G-032. The handover has a block whose entire purpose is to list pending
# observation summaries into the handover document (handover.sh, anchored on the
# comment "# List pending observation summaries"). It splits the inbox with
# `re.split(r'\n  - ', content)` while the inbox writes `- id:` at COLUMN 0, so it
# matches nothing and emits zero lines — inside a section that still prints its
# heading and its count, and therefore looks complete.
#
# WHY A RECIPROCAL LEG IS MANDATORY
# Leg A alone ("the block emitted 0 lines") is unfalsifiable: a harness that fails to
# invoke anything produces the same 0. Leg R runs the SAME extracted block against a
# synthetic inbox written in the `  - ` shape and requires it to emit lines. Only the
# pair separates "the pattern does not match this file's indentation" from "this probe
# is broken".
#
# WHY IT CAN ABSTAIN
# The probe reads the LIVE inbox. With zero pending observations the block is
# unreachable and the question cannot be asked — that is exit 2, never 0. This matters
# because emptying the inbox is the one action that makes the defect invisible without
# fixing it, and G-032 explicitly refuses it as closure.
#
# EXIT
#   0  the defect is present as recorded (pending > 0, content lines emitted == 0).
#      PASS here means NOT FIXED — read the text, not the code.
#   1  a leg moved. Leg A emitting lines is the fix landing; leg R going red means the
#      probe itself can no longer be trusted and leg A says nothing.
#   2  cannot answer (no inbox, no pending observations, block not found).
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
INBOX=".context/inbox.yaml"
HANDOVER=".agentic-framework/agents/handover/handover.sh"

legs=0; fails=0
ok()  { legs=$((legs + 1)); echo "  ok    $*"; }
bad() { legs=$((legs + 1)); echo "  FAIL  $*" >&2; fails=$((fails + 1)); }

[ -f "$INBOX" ]    || { echo "UNKNOWN — no $INBOX. Cannot answer."; exit 2; }
[ -f "$HANDOVER" ] || { echo "UNKNOWN — no $HANDOVER. Cannot answer."; exit 2; }

PENDING=$(grep -c 'status: pending' "$INBOX" 2>/dev/null) || PENDING=0
if [ "$PENDING" -eq 0 ]; then
  echo "ABSTAINED — 0 pending observations, so the listing block is unreachable and"
  echo "  this probe cannot distinguish 'fixed' from 'nothing to list'. Emptying the"
  echo "  inbox is NOT closure for G-032." >&2
  exit 2
fi

echo "=== T-436: does the handover carry the finding, or only the count? ==="
echo "  live inbox: $PENDING pending"
echo

SP="$(mktemp -d)"; trap 'rm -rf "$SP"' EXIT

# Extract the listing block from the shipped handover, so the probe measures the REAL
# code rather than a copy that can drift away from it.
# NOTE the `python3 <<` line is INDENTED in the shipped file. A `^python3` anchor
# misses it, leaving a shell line at the top of the .py — which crashes the extraction
# and makes BOTH legs emit 0, i.e. the crash is indistinguishable from the defect and
# leg A reports a false ok. Caught by leg R on this probe's first run; the assertions
# below exist so it cannot recur silently.
sed -n '/# List pending observation summaries/,/^PYEOF$/p' "$HANDOVER" \
  | sed '1d;/python3 *<</d;/^PYEOF$/d' > "$SP/block.py"
for marker in 'import re' 're.split' 'print('; do
  grep -qF "$marker" "$SP/block.py" || {
    echo "UNKNOWN — extracted block is missing '$marker'; the anchor in $HANDOVER moved"
    echo "  or the extraction is broken. Refusing to score: a crashed block emits 0 lines"
    echo "  and would read as the defect."
    exit 2
  }
done
python3 -c "compile(open('$SP/block.py').read().replace('\$INBOX_FILE','/dev/null'),'b','exec')" 2>/dev/null || {
  echo "UNKNOWN — extracted block does not compile. Refusing to score (see above)."
  exit 2
}

run_block() { # run_block <inbox-path> -> line count on stdout
  sed "s|\$INBOX_FILE|$1|g" "$SP/block.py" > "$SP/run.py"
  python3 "$SP/run.py" 2>/dev/null | grep -c '^- ' || true
}

# ------------------------------------------------------------------ A: the live inbox
a_lines="$(run_block "$INBOX")"
if [ "$a_lines" -eq 0 ]; then
  ok "A the block emitted 0 content lines for $PENDING pending observations"
else
  bad "A the block emitted $a_lines lines. If this is the fix landing, G-032 can close
        once the count matches \`fw note count\` ($PENDING)."
fi

# ------------------------------- R: the reciprocal — the block works on `  - ` indent
cat > "$SP/synthetic.yaml" <<'YEOF'
observations:
  - id: OBS-901
    text: "synthetic fixture, two-space indent"
    status: pending
    promoted_to: null
  - id: OBS-902
    text: "second synthetic fixture"
    status: pending
    promoted_to: null
YEOF
r_lines="$(run_block "$SP/synthetic.yaml")"
if [ "$r_lines" -gt 0 ]; then
  ok "R the same block emits $r_lines lines on \`  - \` indentation — so leg A measures
        the file's shape, not a dead harness"
else
  bad "R the block emitted nothing even on the indentation it was written for. The probe
        cannot be trusted and leg A proves nothing."
fi

echo
echo "  legs=$legs fails=$fails"
# T-430 abstention guard — must precede the verdict, or the verdict answers first.
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "CHANGED — a leg moved. Read leg A: the route carrying content is the fix." >&2
  exit 1
fi
echo "PASS — the defect is present as recorded: the handover prints the count and not"
echo "  the finding, and nothing reports that it listed 0 of $PENDING."
