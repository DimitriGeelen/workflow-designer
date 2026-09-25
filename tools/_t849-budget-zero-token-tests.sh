#!/bin/bash
# T-849 — teeth for the zero-token hole in checkpoint.sh's `budget` safe reader.
#
# WHAT THIS DEFENDS. `checkpoint.sh budget` is the sanctioned reader for
# .budget-status; CLAUDE.md and the /resume skill both send agents to it INSTEAD
# of a raw `cat`, because G-087 recorded that a raw read can return a plausible
# {"level":"ok","tokens":0}. T-3241 built the guard and gave it three rejection
# tests — writer-marked unknown, age, session mismatch. None is about the COUNT.
# A cache written fresh by THIS session carrying tokens: 0 passed all three and
# printed `level: ok`, measured 2026-09-25 against a true 98,461.
#
# WHY A FIXTURE HARNESS AND NOT THE LIVE CACHE. The live .budget-status is
# rewritten by the PostToolUse hook every few calls, so asserting over it is
# asserting over a moving target (T-3326). Every case below runs the real script
# against a fixture CONTEXT_DIR in the scratchpad — paths.sh honours a
# CONTEXT_DIR override for exactly this purpose (T-3141). The live cache is READ
# once, in the last case, and never written.
#
# MUTATION MODE IS NOT OPTIONAL. `--mutation` strips the T-849 block out of a
# throwaway copy and re-runs every case against it, requiring the new ones to go
# RED. A test that passes against unpatched code proves nothing (PL-206) — and
# this session has already shipped one suite whose "expect empty output" cases
# went green over a check that never ran.

set -uo pipefail

CHECKPOINT="${CHECKPOINT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.agentic-framework/agents/context/checkpoint.sh}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t849.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# Cases whose verdict flips when the T-849 block is absent. Mutation mode
# requires EVERY one of these to fail; anything else means the suite is not
# measuring the fix.
NEW_CASES="zero_no_baseline zero_with_baseline tokens_null tokens_absent tokens_string tokens_negative below_baseline raw_passthrough"
# Cases that must behave IDENTICALLY with and without the T-849 block: the three
# precedent rejections, the two healthy reads, and the live smoke test. Under
# mutation these are the CONTROL — they prove the stripped copy still works, so
# that the reds above mean "fix removed" and not "script broken".
CONTROL_CASES="healthy_still_ok healthy_no_baseline_still_ok stale_still_rejected foreign_session_still_rejected writer_unknown_still_rejected live_cache_no_traceback"

# ── mutation mode ───────────────────────────────────────────────────────────────
# Strip the T-849 block out of a throwaway copy and re-run every case against it.
# The eight NEW_CASES must ALL go red; if any of them still passes, this suite is
# not measuring the fix and its green means nothing.
if [ "${1:-}" = "--mutation" ]; then
    # The copy must live BESIDE the original: checkpoint.sh derives FRAMEWORK_ROOT
    # from its own location and sources lib/paths.sh relative to it, so a copy in
    # a temp dir cannot even start. Measured: the first version of this harness
    # put it in $WORK and all 14 cases failed with "//lib/paths.sh: No such file",
    # which LOOKED like a successful mutation kill.
    MUT="$(dirname "$CHECKPOINT")/.t849-mutated-$$.sh"
    trap 'rm -rf "$WORK"; rm -f "$MUT"' EXIT
    python3 - "$CHECKPOINT" "$MUT" <<'PYEOF'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
m = re.search(r"\n# T-849 \(closes the hole.*?not trustworthy'\)\n", t, re.S)
if not m:
    sys.exit("mutation anchor not found — the T-849 block was renamed or removed")
open(dst, 'w').write(t[:m.start()] + "\n" + t[m.end():])
PYEOF
    [ -f "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutated copy"; exit 1; }
    chmod +x "$MUT"
    bash -n "$MUT" || { echo "MUTATION SETUP FAILED: mutated copy does not parse"; exit 1; }
    echo "=== T-849 MUTATION RUN (T-849 block stripped) ==="
    out=$(CHECKPOINT="$MUT" bash "${BASH_SOURCE[0]}" 2>&1)
    printf '%s\n' "$out" | sed 's/^/  | /'
    echo
    # FIRST: prove the mutated copy still RUNS. The cases that do not depend on
    # the T-849 block must stay green. If they went red too, the mutation broke
    # the script rather than removing the fix, and every red below is a false red.
    broken=""
    for c in $CONTROL_CASES; do
        if ! printf '%s' "$out" | grep -q "PASS  $c\$"; then broken="$broken $c"; fi
    done
    if [ -n "$broken" ]; then
        echo "MUTATION SETUP BROKEN — cases unrelated to the fix also failed:$broken"
        echo "The mutated copy is not merely unpatched, it is not working. Every red"
        echo "in this run is a false red and the mutation proves nothing."
        exit 1
    fi
    # THEN: the cases that do depend on it must all be red.
    survivors=""
    for c in $NEW_CASES; do
        if printf '%s' "$out" | grep -q "PASS  $c\$"; then survivors="$survivors $c"; fi
    done
    if [ -n "$survivors" ]; then
        echo "MUTATION FAILED — these cases pass WITHOUT the fix:$survivors"
        echo "A case that is green against unpatched code is not a test (PL-206)."
        exit 1
    fi
    echo "MUTATION OK — the $(set -- $CONTROL_CASES; echo $#) control cases stayed green,"
    echo "so the mutated copy runs; the $(set -- $NEW_CASES; echo $#) cases that depend on"
    echo "the T-849 block all went red, so they are measuring it."
    exit 0
fi

PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

# Build a fixture CONTEXT_DIR whose cache is FRESH and whose session_id matches,
# so age and session-mismatch can never be the reason a case goes unknown.
run_budget() {
    local cache_json="$1"
    local dir="$WORK/ctx.$$.$RANDOM"
    mkdir -p "$dir/working"
    printf 'session_id: S-TEST-849\n' > "$dir/working/session.yaml"
    printf '%s' "$cache_json" > "$dir/working/.budget-status"
    CONTEXT_DIR="$dir" "$CHECKPOINT" budget 2>&1
}

cache() { # cache <tokens-field> [extra-fields]
    printf '{"level": "ok", %s, "timestamp": %s, "session_id": "S-TEST-849"%s}' \
        "$1" "$(date +%s)" "${2:+, $2}"
}

expect_unknown() { # expect_unknown <name> <output> <substring...>
    local name="$1" out="$2"; shift 2
    if ! printf '%s' "$out" | grep -q '^level: unknown'; then
        bad "$name" "expected 'level: unknown', got: $(printf '%s' "$out" | head -2 | tr '\n' ' ')"
        return
    fi
    local s
    for s in "$@"; do
        if ! printf '%s' "$out" | grep -qF "$s"; then
            bad "$name" "reason does not name '$s' — got: $(printf '%s' "$out" | grep '^reason:' | head -1)"
            return
        fi
    done
    ok "$name"
}

echo "=== T-849 budget-guard zero-token teeth ==="
echo "script under test: $CHECKPOINT"
echo

# 1. tokens: 0 with no baseline to contradict — still not a healthy zero.
out=$(run_budget "$(cache '"tokens": 0')")
expect_unknown "zero_no_baseline" "$out" \
    "the writer recorded no measurement" "NOT the same as a healthy zero"

# 2. tokens: 0 beside a real baseline — the reason must name the CONTRADICTION,
#    not the generic no-measurement wording. This is the differential control.
out=$(run_budget "$(cache '"tokens": 0' '"baseline_tokens": 88847')")
expect_unknown "zero_with_baseline" "$out" "impossible" "baseline_tokens: 88847"

# 3/4/5/11. A level without a usable count is not a gauge.
out=$(run_budget "$(cache '"tokens": null')")
expect_unknown "tokens_null" "$out" "no numeric token count"
out=$(run_budget '{"level": "ok", "timestamp": '"$(date +%s)"', "session_id": "S-TEST-849"}')
expect_unknown "tokens_absent" "$out" "no numeric token count"
out=$(run_budget "$(cache '"tokens": "96832"')")
expect_unknown "tokens_string" "$out" "no numeric token count"
out=$(run_budget "$(cache '"tokens": -5')")
expect_unknown "tokens_negative" "$out" "no measurement"

# 6. Non-zero but below baseline — the same impossibility, caught for counts
#    other than zero, which is what makes this a differential test and not a
#    special case for the literal number 0.
out=$(run_budget "$(cache '"tokens": 5000' '"baseline_tokens": 88847')")
expect_unknown "below_baseline" "$out" "below baseline_tokens: 88847" "impossible"

# 7. raw_level/raw_tokens passthrough survives on a NEW rejection path — the
#    reader must still be able to see what the cache claimed.
out=$(run_budget "$(cache '"tokens": 0' '"baseline_tokens": 88847')")
if printf '%s' "$out" | grep -q '^raw_level: ok' && printf '%s' "$out" | grep -q '^raw_tokens: 0'; then
    ok "raw_passthrough"
else
    bad "raw_passthrough" "expected raw_level: ok and raw_tokens: 0, got: $(printf '%s' "$out" | tr '\n' ' ')"
fi

# 8/9. THE GAUGE MUST STILL WORK. A fix that reports unknown for everything
#     would pass every case above and be worse than the bug (OBS-293: a
#     permanently red check trains its reader to ignore it).
out=$(run_budget "$(cache '"tokens": 96832' '"baseline_tokens": 88847, "headroom_tokens": 711153, "headroom_ratio": 0.89')")
if printf '%s' "$out" | grep -q '^level: ok' && printf '%s' "$out" | grep -q '^tokens: 96832' \
   && printf '%s' "$out" | grep -q '^headroom_ratio: 0.89'; then
    ok "healthy_still_ok"
else
    bad "healthy_still_ok" "healthy cache no longer reports ok+tokens+headroom: $(printf '%s' "$out" | tr '\n' ' ')"
fi
out=$(run_budget "$(cache '"tokens": 50000')")
if printf '%s' "$out" | grep -q '^level: ok' && printf '%s' "$out" | grep -q '^tokens: 50000'; then
    ok "healthy_no_baseline_still_ok"
else
    bad "healthy_no_baseline_still_ok" "expected ok/50000, got: $(printf '%s' "$out" | tr '\n' ' ')"
fi

# 10. The precedent tests must not have been broken by the new block.
out=$(run_budget '{"level": "ok", "tokens": 96832, "timestamp": 1, "session_id": "S-TEST-849"}')
expect_unknown "stale_still_rejected" "$out" "old (max"
out=$(run_budget '{"level": "ok", "tokens": 96832, "timestamp": '"$(date +%s)"', "session_id": "S-OTHER"}')
expect_unknown "foreign_session_still_rejected" "$out" "not this session"
out=$(run_budget '{"level": "unknown", "tokens": 96832, "timestamp": '"$(date +%s)"', "session_id": "S-TEST-849"}')
expect_unknown "writer_unknown_still_rejected" "$out" "writer marked this measurement unknown"

# 12. The real script, on the real cache, does not traceback. Read-only.
if live=$("$CHECKPOINT" budget 2>&1) && printf '%s' "$live" | grep -q '^level: '; then
    ok "live_cache_no_traceback"
else
    bad "live_cache_no_traceback" "live read failed or printed no level: $(printf '%s' "$live" | tail -3 | tr '\n' ' ')"
fi

echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
