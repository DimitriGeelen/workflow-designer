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
# THREE STATES, NOT TWO  (T-445, after AEF measured their own tree)
# This probe originally asked "did it emit anything?". That is the wrong question, and
# the peer proved it with a number: their fixed tree emitted 1 row for 112 pending, and
# their :386 site 1 for 3. A zero can read as "nothing pending". ONE well-formed row
# under a "112 pending" heading reads as a section that WORKED — and it is the row an
# eye lands on. The partial answer is worse than the empty one.
#   DEFECT   rows == 0        the recorded state
#   PARTIAL  0 < rows < N     the dangerous state — looks fixed, drops the rest
#   FIXED    rows == N        the closure signal for G-032
# G-032's closure condition already demanded count EQUALITY ("line count matches
# `fw note count`"). This probe did not hold that bar: it tested `rows -eq 0` and
# deferred the comparison to prose in a failure message. A bar stated in a string is
# not a bar the instrument holds.
#
# USAGE
#   _t436-inbox-route-probe.sh [inbox-path]      default: .context/inbox.yaml
#   The argument exists so the state machine can be mutation-driven against fixtures
#   (tools/_t445-partial-state-mutation.sh) — an arm that has never been exercised is
#   indistinguishable from one that cannot fire.
#
#   _t436-inbox-route-probe.sh --json [inbox-path]
#   Gauge mode for G-032's `closure_check_command:` (lib/gaps.py contract: pure JSON on
#   stdout, exit 0, `verdict: READY|NOT_READY`). READY only for FIXED. It re-runs THIS
#   script and classifies its verdict line rather than re-deriving the state, so the
#   gauge and the human-readable probe can never drift apart. Abstention emits no
#   `verdict` key at all — gaps.py then reads UNKNOWN, which refuses closure while
#   staying distinguishable from a measured NOT_READY.
#
# EXIT
#   0  DEFECT — the defect is present as recorded (pending > 0, content lines == 0).
#      PASS here means NOT FIXED — read the text, not the code.
#   1  a leg moved: PARTIAL or FIXED, or leg R went red (in which case the probe itself
#      can no longer be trusted and leg A says nothing). Read the verdict line.
#   2  cannot answer (no inbox, no pending observations, block not found).
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

if [ "${1:-}" = "--json" ]; then
  shift
  raw="$(bash "$0" "$@" 2>&1)"
  python3 - "$raw" <<'PYEOF'
import json, re, sys
raw = sys.argv[1]
m = re.search(r'(PARTIAL|FIXED) — the block emitted (\d+) of (\d+)', raw)
if m:
    state, rows, pending = m.group(1), int(m.group(2)), int(m.group(3))
    print(json.dumps({"verdict": "READY" if state == "FIXED" else "NOT_READY",
                      "state": state, "rows": rows, "pending": pending,
                      "gap": "G-032"}))
elif "PASS [DEFECT]" in raw:
    n = re.search(r'listed 0 of (\d+)', raw)
    print(json.dumps({"verdict": "NOT_READY", "state": "DEFECT", "rows": 0,
                      "pending": int(n.group(1)) if n else None, "gap": "G-032"}))
else:
    # No verdict key: gaps.py reads UNKNOWN. Cannot-answer must not become NOT_READY —
    # both refuse closure, but only one of them is a measurement.
    print(json.dumps({"state": "ABSTAINED", "gap": "G-032",
                      "reason": raw.strip().splitlines()[0] if raw.strip() else "no output"}))
PYEOF
  exit 0
fi

INBOX="${1:-.context/inbox.yaml}"
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
  STATE=DEFECT
  ok "A the block emitted 0 content lines for $PENDING pending observations"
elif [ "$a_lines" -lt "$PENDING" ]; then
  STATE=PARTIAL
  bad "A PARTIAL — the block emitted $a_lines of $PENDING. This does NOT close G-032.
        A section headed '$PENDING pending' carrying $a_lines row(s) reads as one that
        worked, which is why this state is worse than the zero it replaced. Measured
        first by AEF on their own tree (1 of 112, and 1 of 3 at the urgent site)."
else
  STATE=FIXED
  bad "A FIXED — the block emitted $a_lines of $PENDING pending observations. Row count
        matches the pending count, which is exactly G-032's closure condition. Verify
        against \`fw note count\` and close the gap."
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
  echo "CHANGED [$STATE] — a leg moved. Read leg A." >&2
  case "$STATE" in
    PARTIAL) echo "  PARTIAL is not progress toward closure; it is the same silence with" >&2
             echo "  a plausible row on top. G-032 stays watching." >&2 ;;
    FIXED)   echo "  FIXED is the closure signal G-032 names. Confirm against a" >&2
             echo "  non-empty inbox, then close." >&2 ;;
  esac
  exit 1
fi
echo "PASS [DEFECT] — the defect is present as recorded: the handover prints the count"
echo "  and not the finding, and nothing reports that it listed 0 of $PENDING."
