#!/usr/bin/env bash
# T-656 — D2 must say WHAT the review queue is waiting for, not only how long.
#
# WHY THIS EXISTS. D2 was built from age alone. A task whose every criterion the human had
# already ticked counted identically to one they had not opened. Measured 2026-08-31:
# T-093 (57 days, 7/7 ticked) and T-178 (51 days, 6/6 ticked) were HALF of the >30d FAIL,
# and neither was waiting on a decision — only on the administrative status flip. The
# control's own remediation line sent the operator to `fw task verify`, which lists
# unchecked Human ACs, of which those two tasks have none. Fifty-seven days of a FAIL
# asking for something that had already been given.
#
# WHAT THIS PROBER MUST NOT DO: it must not retype the block. It greps the real D2 region
# out of audit.sh and runs THAT against fixture JSON, so a rewrite is reported rather than
# skipped. It never reads the project's own tasks.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

# T-661: mutation completeness is asserted by the shared helper — "the original form is
# gone", not "my marker appears exactly N times". See tools/lib/mutation-assert.sh.
. "$(dirname "${BASH_SOURCE[0]}")/lib/mutation-assert.sh"

PROJ="${T656_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/audit/audit.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-656: the review queue must distinguish judgement from the status flip ==="
echo

extract_d2() {
    python3 - "$SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n# T-656: the queue is split by WHAT IT IS WAITING FOR.*?\n    pass \"D2: Human review queue [^\"]*no pending items\"\nfi\n", src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: the D2 region was not found in audit.sh\n")
    sys.exit(3)
sys.stdout.write(m.group(0))
PY
}
D2="$TMP/d2.sh"
extract_d2 > "$D2" || exit 3
[ -s "$D2" ] || { echo "COULD-NOT-MEASURE: extracted D2 region was empty" >&2; exit 3; }

# scan <task-json-rows...> -> the ACTIVE_SCAN document the block consumes
scan() {
    python3 - "$@" <<'PY'
import json, sys
tasks = []
for row in sys.argv[1:]:
    parts = row.split(":")
    entry = {"id": parts[0], "age_hours": int(parts[1]), "age_days": int(parts[1]) // 24}
    # An empty third field means the key is ABSENT — a scan predating T-656.
    if parts[2] != "":
        entry["unticked"] = int(parts[2])
    tasks.append(entry)
json.dump({"review_queue": {"tasks": tasks}}, sys.stdout)
PY
}

# verdict <scan-json> [<block>] -> "LEVEL::message::evidence::remedy"
verdict() {
    local scan_json="$1" block="${2:-$D2}"
    (
        set +u
        ACTIVE_SCAN="$scan_json"
        pass() { echo "PASS::$1"; }
        warn() { echo "WARN::$1::${2:-}::${3:-}"; }
        fail() { echo "FAIL::$1::${2:-}::${3:-}"; }
        . "$block"
    ) 2>&1
}

# 800h = 33d (>30d tier), 400h = 16d (>14d tier), 100h = 4d (normal)
# ---------------------------------------------------------------------------
echo "--- mixed >30d queue: the two kinds are counted and named separately"
OUT=$(verdict "$(scan 'T-1:800:2' 'T-2:800:0')")
MISSING=""
echo "$OUT" | grep -q '^FAIL::'                                  || MISSING="$MISSING not-a-fail"
echo "$OUT" | grep -q '2 task(s) waiting >30d'                   || MISSING="$MISSING the-total"
echo "$OUT" | grep -q '1 awaiting judgement: T-1'                || MISSING="$MISSING the-judgement-group"
echo "$OUT" | grep -q '1 signed off, awaiting only the status flip: T-2' || MISSING="$MISSING the-flip-group"
if [ -z "$MISSING" ]; then
    ok "both groups named, total preserved (neither is dropped)"
else
    bad "split incomplete:$MISSING | got: $(echo "$OUT" | tr '\n' ' ' | head -c 240)"
fi

# ---------------------------------------------------------------------------
echo "--- an all-signed-off queue does not claim anyone is awaiting judgement"
OUT=$(verdict "$(scan 'T-1:800:0' 'T-2:900:0')")
if echo "$OUT" | grep -q '2 signed off' && ! echo "$OUT" | grep -q 'awaiting judgement'; then
    ok "says signed off, says nothing about judgement"
else
    bad "an all-signed-off queue still reported judgement: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- ...and its remediation names the command that actually clears them"
if echo "$OUT" | grep -q 'work-completed'; then
    ok "remediation offers the status flip, not just 'fw task verify'"
else
    bad "remediation for signed-off tasks does not mention closing them: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- an all-unticked queue is unchanged: no flip language, no flip advice"
OUT=$(verdict "$(scan 'T-1:800:3' 'T-2:800:1')")
if ! echo "$OUT" | grep -q 'signed off' && ! echo "$OUT" | grep -q 'work-completed'; then
    ok "genuine review backlog reads exactly as before — the change is additive"
else
    bad "flip language leaked into a queue with nothing signed off: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- a scan with no 'unticked' field (pre-T-656) is treated as awaiting judgement"
OUT=$(verdict "$(scan 'T-1:800:')")
if echo "$OUT" | grep -q 'awaiting judgement' && ! echo "$OUT" | grep -q 'signed off'; then
    ok "absent field sorts to the conservative side — an unknown is not a sign-off"
else
    bad "a missing 'unticked' was read as signed off: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- the >14d tier splits too, and a young queue still passes"
OUT=$(verdict "$(scan 'T-1:400:0' 'T-2:400:2')")
if echo "$OUT" | grep -q '^WARN::' && echo "$OUT" | grep -q 'signed off' && echo "$OUT" | grep -q 'awaiting judgement'; then
    ok ">14d tier: warns and splits"
else
    bad ">14d tier did not split: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi
OUT=$(verdict "$(scan 'T-1:100:0')")
if echo "$OUT" | grep -q '^PASS::.*awaiting human action (normal)'; then
    ok "a young queue still passes — the split did not promote anything"
else
    bad "a 4-day queue no longer passes: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: collapse the split and the mixed queue must stop distinguishing"
MUT="$TMP/d2-mutant.sh"
# Force both classification tests false, so every task falls to the judgement group — the
# pre-T-656 behaviour, reached without touching anything else in the block.
sed 's|if \[ "\$unticked" -eq 0 \]; then|if false; then|g' "$D2" > "$MUT"
# T-661: this is the literal shape 999-AEF reported at @897 — a count pinned at 2 where
# the invariant is "none of them survive". A third correct classification test would have
# turned this leg red for being right. Half-mutation is still caught, by the survivor
# count rather than by the total.
if ! REVERTED=$(assert_mutation_complete "$D2" "$MUT" 'if \[ "\$unticked" -eq 0 \]; then' 'classification test'); then
    bad "$REVERTED"
else
    OUT=$(verdict "$(scan 'T-1:800:2' 'T-2:800:0')" "$MUT")
    if ! echo "$OUT" | grep -q 'signed off' && echo "$OUT" | grep -q '2 awaiting judgement'; then
        ok "mutant lumps both into judgement — the split is what produces the distinction"
    else
        bad "mutant still split the queue — the legs above cannot fail and prove nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
