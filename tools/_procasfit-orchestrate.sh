#!/usr/bin/env bash
# _procasfit-orchestrate.sh — run N sequential procAsFit rounds, each fed the previous handback.
#
# WHAT THIS IS NOT. It does not execute the mandate. It builds prompts, dispatches workers,
# collects artefacts and records what happened. The work is the workers'.
#
# FOUR THINGS T-897's FOUR-ROUND RUN LEARNED THE EXPENSIVE WAY, each encoded here as a check:
#
#   1. A DISPATCH STATUS IS NOT EVIDENCE. termlink_spawn returned {ok:true, status:"ready"} for a
#      session registered 62.6 HOURS EARLIER IN ANOTHER PROJECT (OBS-405). Nothing ran. So a round
#      closes on its HANDBACK FILE existing and being non-trivial, never on an exit code alone.
#
#   2. PROMPT LENGTH MUST BE ARITHMETIC, NOT EYEBALLED. Round 2's prompt built to 92,818 bytes from
#      a 9KB handback and a 4.6KB mandate — python implicit string concatenation multiplied the
#      preamble 78 times. It read as a plausible instruction set. Only comparing the byte count
#      against what the inputs could account for caught it. Asserted every round, both directions.
#
#   3. CUMULATIVE FEEDING DOES NOT SCALE. T-897's prompts went 4.6K -> 15K -> 26K -> 37K because
#      each round carried every prior handback. At that curve round 9 is a quarter of a megabyte.
#      This feeds the PREVIOUS handback only.
#
#   4. ALIVE IS NOT RUNNING. A worker was verified alive by pid and then refused at the model by
#      quota. The artefact is the only thing that closes a round.
#
# A FAILED ROUND IS RECORDED, NEVER SKIPPED. The next round is then fed the last REAL handback and
# the substitution is written into its prompt, because a round silently fed someone else's output
# is a round whose result means something other than it appears to.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90
REPO="$PWD"

ROUNDS="${1:-9}"
DIR="${2:-.context/working/procasfit9}"
MANDATE="$DIR/mandate.md"
LOG="$DIR/run-log.tsv"
TIMEOUT_SECS="${PROCASFIT_TIMEOUT:-5400}"   # 90 min per round
MAX_PROMPT=200000                            # hard ceiling; the arithmetic check is the real guard

mkdir -p "$DIR"
[ -f "$MANDATE" ] || { echo "FATAL: no mandate at $MANDATE — write it before running."; exit 2; }
MANDATE_SHA="$(sha256sum "$MANDATE" | cut -d' ' -f1)"
MANDATE_BYTES="$(wc -c < "$MANDATE")"

[ -f "$LOG" ] || printf 'round\tdispatched_at\texit\tsecs\tprompt_bytes\thandback_bytes\tverdict\n' > "$LOG"

say() { printf '%s\n' "$*"; }

# The handback a round is fed. Falls back to the last REAL one, and says so.
last_real_handback() {
    local r
    for (( r = ROUNDS; r >= 1; r-- )); do
        local f="$DIR/round${r}-handback.md"
        [ -s "$f" ] && { printf '%s' "$f"; return 0; }
    done
    return 1
}

say "=== procAsFit orchestration: $ROUNDS rounds ==="
say "mandate: $MANDATE ($MANDATE_BYTES bytes, sha ${MANDATE_SHA:0:12})"
say ""

for (( R = 1; R <= ROUNDS; R++ )); do
    PROMPT="$DIR/round${R}-prompt.md"
    OUT="$DIR/round${R}.out"
    HB="$DIR/round${R}-handback.md"
    [ -s "$HB" ] && { say "round $R: handback already present — skipping (resume)"; continue; }

    # ── build the prompt: mandate VERBATIM + at most one previous handback ────────────────────
    FEED=""; FEED_BYTES=0; FEED_NOTE=""
    if [ "$R" -gt 1 ]; then
        PREV="$DIR/round$((R-1))-handback.md"
        if [ -s "$PREV" ]; then
            FEED="$PREV"
        elif FEED="$(last_real_handback)"; then
            FEED_NOTE="NOTE: round $((R-1)) produced no handback. You are being fed $(basename "$FEED") instead — the most recent round that actually produced one. Treat the gap as a failed round, not as work that did not need doing."
        else
            FEED=""
            FEED_NOTE="NOTE: no previous round produced a handback. Treat this as round 1 and say so in yours."
        fi
        [ -n "$FEED" ] && FEED_BYTES="$(wc -c < "$FEED")"
    fi

    {
        cat "$MANDATE"
        if [ -n "$FEED" ] || [ -n "$FEED_NOTE" ]; then
            printf '\n\n---\n\n## Previous round handback (round %d of %d)\n\n' "$R" "$ROUNDS"
            [ -n "$FEED_NOTE" ] && printf '%s\n\n' "$FEED_NOTE"
            [ -n "$FEED" ] && cat "$FEED"
        fi
        printf '\n\n---\n\nThis is round %d of %d. Write your handback to %s/round%d-handback.md using the Write tool before you finish. A round with no handback file is a FAILED round.\n' \
            "$R" "$ROUNDS" "$REPO/$DIR" "$R"
    } > "$PROMPT"

    PB="$(wc -c < "$PROMPT")"
    # THE ARITHMETIC CHECK. Everything in the prompt is the mandate, the feed, or ~600 bytes of
    # scaffolding. A prompt materially larger than its inputs is a construction bug, not a long
    # prompt — this is the check that would have caught the 92,818-byte round 2.
    ACCOUNTED=$(( MANDATE_BYTES + FEED_BYTES + ${#FEED_NOTE} + 700 ))
    if [ "$PB" -gt "$ACCOUNTED" ] || [ "$PB" -lt "$MANDATE_BYTES" ] || [ "$PB" -gt "$MAX_PROMPT" ]; then
        say "round $R: PROMPT SETUP BROKEN — $PB bytes, inputs account for at most $ACCOUNTED"
        printf '%d\t%s\t-\t-\t%d\t0\tPROMPT-SETUP-BROKEN\n' "$R" "$(date -u +%FT%TZ)" "$PB" >> "$LOG"
        continue
    fi
    # And the mandate must be in there verbatim, not paraphrased by a shell quoting accident.
    if ! grep -qF "$(head -c 200 "$MANDATE")" "$PROMPT"; then
        say "round $R: PROMPT SETUP BROKEN — mandate not present verbatim"
        printf '%d\t%s\t-\t-\t%d\t0\tMANDATE-NOT-VERBATIM\n' "$R" "$(date -u +%FT%TZ)" "$PB" >> "$LOG"
        continue
    fi

    say "round $R/$ROUNDS: dispatching ($PB bytes; feed=$(basename "${FEED:-none}"))"
    START=$(date +%s)
    TS="$(date -u +%FT%TZ)"
    timeout "$TIMEOUT_SECS" claude -p "$(cat "$PROMPT")" > "$OUT" 2>&1
    RC=$?
    SECS=$(( $(date +%s) - START ))

    # ── the artefact is the verdict ───────────────────────────────────────────────────────────
    HBB=0; [ -f "$HB" ] && HBB="$(wc -c < "$HB")"
    if [ "$HBB" -ge 500 ]; then
        VERDICT="OK"
    elif [ "$HBB" -gt 0 ]; then
        VERDICT="HANDBACK-TRIVIAL"
    else
        VERDICT="FAILED-NO-HANDBACK"
    fi
    say "round $R: exit=$RC ${SECS}s handback=${HBB}B -> $VERDICT"
    printf '%d\t%s\t%d\t%d\t%d\t%d\t%s\n' "$R" "$TS" "$RC" "$SECS" "$PB" "$HBB" "$VERDICT" >> "$LOG"
done

say ""
say "=== RUN LOG ==="
cat "$LOG"
say ""
OKN=$(awk -F'\t' 'NR>1 && $7=="OK"' "$LOG" | wc -l)
BAD=$(awk -F'\t' 'NR>1 && $7!="OK"' "$LOG" | wc -l)
say "rounds with a real handback: $OKN"
say "rounds that did not:         $BAD"
[ "$BAD" -eq 0 ] || say "NOTE: the failed rounds are listed above by verdict. They are not skipped rounds."
exit 0
