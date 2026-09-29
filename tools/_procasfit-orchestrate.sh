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
# AND TWO THAT T-922's OWN FIRST RUN LEARNED, both from one incident (2026-09-29, OBS-437/OBS-438):
#
#   5. A QUOTA REFUSAL IS NOT A ROUND RESULT, AND MUST STOP THE RUN. Round 2 hit
#      "You've hit your session limit · resets 3:10am" 26 minutes in. Rounds 3-9 were then
#      dispatched anyway and died in 4-5 SECONDS EACH — seven rounds consumed in 33 seconds,
#      all seven .out files BYTE-IDENTICAL (md5 e721d019). The verdict column said
#      FAILED-NO-HANDBACK eight times, which is true and useless: it cannot tell "this round
#      tried and failed" from "this round never ran". The mandate's own clause — three attempts
#      at the same wall is context burned, not progress — was violated by the ORCHESTRATOR.
#      So: the refusal is detected, given its own verdict, and either waited out or the run stops.
#      Remaining rounds are never burned against a known wall.
#
#   6. A HANDBACK WRITTEN ONLY AT THE END IS A HANDBACK YOU MAY NEVER WRITE. Round 2 closed T-882
#      (commit 162afe3b) and opened T-923 with 25 lines of real implementation — then died with
#      handback_bytes=0. Its 26 minutes of work is in the tree but was invisible to the run record
#      and to every later round. The prompt now requires the skeleton FIRST and filling as it goes.
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
TIMEOUT_SECS="${PROCASFIT_TIMEOUT:-5400}"      # 90 min per round
MAX_PROMPT=200000                               # hard ceiling; the arithmetic check is the real guard
WAIT_FOR_RESET="${PROCASFIT_WAIT_FOR_RESET:-1}" # 1 = sleep to the quota reset and retry the round
MAX_QUOTA_WAITS="${PROCASFIT_MAX_WAITS:-3}"     # per round; a wall that outlives this stops the run
MAX_WAIT_SECS="${PROCASFIT_MAX_WAIT_SECS:-21600}"  # never sleep more than 6h on one parse

mkdir -p "$DIR"
[ -f "$MANDATE" ] || { echo "FATAL: no mandate at $MANDATE — write it before running."; exit 2; }
MANDATE_SHA="$(sha256sum "$MANDATE" | cut -d' ' -f1)"
MANDATE_BYTES="$(wc -c < "$MANDATE")"

[ -f "$LOG" ] || printf 'round\tdispatched_at\texit\tsecs\tprompt_bytes\thandback_bytes\tverdict\n' > "$LOG"

say() { printf '%s\n' "$*"; }
# BYTES, not characters. ${#var} is locale-dependent and these strings contain em-dashes, so
# ${#PRED_NOTE} undercounts its own byte length — in the very arithmetic whose job is to catch a
# prompt bigger than its inputs. An off-by-an-unmeasured-amount check is the defect, not the guard.
blen() { printf '%s' "${1-}" | wc -c; }
logrow() {  # round exit secs prompt_bytes handback_bytes verdict
    printf '%d\t%s\t%s\t%s\t%d\t%d\t%s\n' "$1" "$(date -u +%FT%TZ)" "$2" "$3" "$4" "$5" "$6" >> "$LOG"
}

# The handback a round is fed. Falls back to the last REAL one, and says so.
last_real_handback() {
    local r
    for (( r = ROUNDS; r >= 1; r-- )); do
        local f="$DIR/round${r}-handback.md"
        [ -s "$f" ] && { printf '%s' "$f"; return 0; }
    done
    return 1
}

# ── FINDING 5: is this output a quota refusal rather than a round result? ──────────────────────
# Matched on the worker's OWN output only, and only consulted when no handback was produced — a
# round that delivered its artefact is OK no matter what its log mentions.
QUOTA_RX='hit your (session|usage) limit|session limit ·|usage limit reached|resets [0-9]+:[0-9]+'
is_quota_refusal() { [ -s "$1" ] && grep -Eqi "$QUOTA_RX" "$1"; }

# Seconds until the reset time the refusal names, e.g. "resets 3:10am (Europe/Berlin)".
# Prints nothing if it cannot parse one — the caller then stops rather than guessing a sleep.
secs_to_reset() {
    python3 - "$1" <<'PYX' 2>/dev/null
import re, sys, datetime, zoneinfo
txt = open(sys.argv[1], encoding='utf-8', errors='replace').read()
m = re.search(r'resets\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:\(([^)]+)\))?', txt, re.I)
if not m:
    sys.exit(1)
hh = int(m.group(1)); mm = int(m.group(2) or 0); ap = (m.group(3) or '').lower()
if ap == 'pm' and hh != 12: hh += 12
if ap == 'am' and hh == 12: hh = 0
try:
    tz = zoneinfo.ZoneInfo(m.group(4)) if m.group(4) else None
except Exception:
    tz = None
now = datetime.datetime.now(tz)
tgt = now.replace(hour=hh, minute=mm, second=0, microsecond=0)
if tgt <= now:
    tgt += datetime.timedelta(days=1)
print(int((tgt - now).total_seconds()) + 180)   # +3 min margin past the stated reset
PYX
}

# ── FINDING 6 support: name the state the round actually inherits ─────────────────────────────
# A worker that inherits a half-finished unit must be TOLD, or it re-selects from scratch and the
# orphaned work rots uncommitted. Round 2 left T-923 at started-work with 25 uncommitted lines of
# implementation when quota killed it.
#
# THIS STATES WHAT IS IN THE TREE, NOT WHAT A PRIOR ATTEMPT PRESUMABLY DID. An earlier draft said
# "a previous attempt at this round was cut off and it DID change state" — true of round 2, false
# of rounds 3-9, whose prior .out was a 4-second refusal that changed nothing. Naming the observed
# paths is evidence; narrating an unobserved predecessor is inference wearing its clothes.
inherited_state_note() {
    local dirty started
    dirty="$(cd "$REPO" && git status --porcelain -- ':!.context/audits' ':!.playwright-mcp' \
              ':!.editor-versions' ':!.context/working' ':!.context/locks' ':!.context/episodic' \
              2>/dev/null | head -20)"
    started="$(cd "$REPO" && grep -l '^status: started-work' .tasks/active/*.md 2>/dev/null \
              | xargs -r -n1 basename 2>/dev/null | sed 's/-.*//' | tr '\n' ' ')"
    [ -z "$dirty" ] && [ -z "$started" ] && return 1
    printf 'STATE YOU INHERIT, observed at dispatch time (git + the task register, not a claim about who left it). An earlier round of this run was cut off by a quota refusal after closing a task and opening another, so some of this may be a half-finished unit. Census it before selecting new work: finish or park what is open through the proper verb rather than leaving it uncommitted. Re-read git log yourself — this snapshot is already aging.\n\nTasks at started-work: %s\n\nUncommitted paths (first 20, housekeeping excluded):\n%s\n' \
        "${started:-none}" "${dirty:-none}"
}

# ── SELF-TEST ─────────────────────────────────────────────────────────────────────────────────
# Exercises the REAL functions above (not a replica) against the REAL artefacts of the failed run.
# Both directions matter: a detector that never fires burns the remaining rounds, and one that
# always fires stalls a healthy run in a sleep loop forever. Run: _procasfit-orchestrate.sh selftest
if [ "${1:-}" = "selftest" ]; then
    P=0; F=0
    t() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; P=$((P+1)); else echo "  FAIL  $1"; F=$((F+1)); fi; }
    echo "=== orchestrator self-test (fixtures: this run's own artefacts) ==="
    REF="$DIR/round3.out"; GOOD="$DIR/round1.out"
    [ -s "$REF" ] || { echo "SETUP BROKEN: no $REF to test against"; exit 1; }
    [ -s "$GOOD" ] || { echo "SETUP BROKEN: no $GOOD control"; exit 1; }

    is_quota_refusal "$REF";  t "FIRES on the real quota refusal (round3.out)" $?
    is_quota_refusal "$GOOD"; t "does NOT fire on a real successful round's output (round1.out)" $([ $? -ne 0 ] && echo 0 || echo 1)
    printf 'all done, no problems\n' > "$DIR/.selftest-clean.tmp"
    is_quota_refusal "$DIR/.selftest-clean.tmp"; t "does NOT fire on ordinary output" $([ $? -ne 0 ] && echo 0 || echo 1)
    rm -f "$DIR/.selftest-clean.tmp"

    S="$(secs_to_reset "$REF")"
    t "parses a sleep from 'resets 3:10am (Europe/Berlin)' (got ${S:-nothing})" \
      "$([ -n "$S" ] && [ "$S" -gt 180 ] && [ "$S" -le 86580 ] && echo 0 || echo 1)"
    printf 'You have hit your session limit with no reset time stated\n' > "$DIR/.selftest-noreset.tmp"
    S2="$(secs_to_reset "$DIR/.selftest-noreset.tmp")"
    t "refuses to invent a sleep when no reset time is stated (-> stop, not guess)" \
      "$([ -z "$S2" ] && echo 0 || echo 1)"
    rm -f "$DIR/.selftest-noreset.tmp"

    echo; echo "PASS: $P  FAIL: $F"
    [ "$F" -eq 0 ] || exit 1
    exit 0
fi

say "=== procAsFit orchestration: $ROUNDS rounds ==="
say "mandate: $MANDATE ($MANDATE_BYTES bytes, sha ${MANDATE_SHA:0:12})"
say "quota policy: wait_for_reset=$WAIT_FOR_RESET max_waits_per_round=$MAX_QUOTA_WAITS"
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

    # Not gated on RETRY: inherited state is worth naming to every round, and gating it on an
    # inferred prior attempt is what made the earlier wording false for rounds 3-9.
    PRED_NOTE="$(inherited_state_note || true)"

    # The tail is built as a variable so the arithmetic check below can account for it EXACTLY
    # rather than against a guessed constant.
    TAIL="$(printf 'This is round %d of %d. Write your handback to %s/round%d-handback.md.\n\nWRITE IT AS A SKELETON FIRST, BEFORE YOU START WORKING, and fill each section as you go. Do not leave it to the end. Round 2 of this run closed a task and opened another with real implementation, then died on a quota refusal with an empty handback — 26 minutes of work that no later round could see. A round with no handback file is a FAILED round regardless of what it accomplished.\n' \
        "$R" "$ROUNDS" "$REPO/$DIR" "$R")"

    {
        cat "$MANDATE"
        if [ -n "$FEED" ] || [ -n "$FEED_NOTE" ]; then
            printf '\n\n---\n\n## Previous round handback (round %d of %d)\n\n' "$R" "$ROUNDS"
            [ -n "$FEED_NOTE" ] && printf '%s\n\n' "$FEED_NOTE"
            [ -n "$FEED" ] && cat "$FEED"
        fi
        [ -n "$PRED_NOTE" ] && printf '\n\n---\n\n%s\n' "$PRED_NOTE"
        printf '\n\n---\n\n%s\n' "$TAIL"
    } > "$PROMPT"

    PB="$(wc -c < "$PROMPT")"
    # THE ARITHMETIC CHECK. Every byte in the prompt is the mandate, the feed, one of the two
    # notes, or the tail — all of them known here. Slack covers only the printf separators, so
    # this is far tighter than a guessed allowance. This is the check that would have caught the
    # 92,818-byte round 2 of T-897.
    ACCOUNTED=$(( MANDATE_BYTES + FEED_BYTES + $(blen "$FEED_NOTE") + $(blen "$PRED_NOTE") + $(blen "$TAIL") + 120 ))
    if [ "$PB" -gt "$ACCOUNTED" ] || [ "$PB" -lt "$MANDATE_BYTES" ] || [ "$PB" -gt "$MAX_PROMPT" ]; then
        say "round $R: PROMPT SETUP BROKEN — $PB bytes, inputs account for at most $ACCOUNTED"
        logrow "$R" - - "$PB" 0 PROMPT-SETUP-BROKEN
        continue
    fi
    # And the mandate must be in there verbatim, not paraphrased by a shell quoting accident.
    if ! grep -qF "$(head -c 200 "$MANDATE")" "$PROMPT"; then
        say "round $R: PROMPT SETUP BROKEN — mandate not present verbatim"
        logrow "$R" - - "$PB" 0 MANDATE-NOT-VERBATIM
        continue
    fi

    # Prompt construction can be exercised without spending a round: PROCASFIT_DRYRUN=1 builds
    # every prompt and runs both setup checks, then stops short of the model.
    if [ "${PROCASFIT_DRYRUN:-0}" = "1" ]; then
        say "round $R: DRYRUN — prompt built and checked ($PB bytes, accounted $ACCOUNTED, feed=$(basename "${FEED:-none}")$([ -n "$PRED_NOTE" ] && echo ', +predecessor-note'))"
        continue
    fi

    # ── dispatch, with the quota wall as a first-class outcome ────────────────────────────────
    WAITS=0
    while : ; do
        say "round $R/$ROUNDS: dispatching ($PB bytes; feed=$(basename "${FEED:-none}")$([ -n "$PRED_NOTE" ] && echo '; +predecessor-note')$([ "$WAITS" -gt 0 ] && echo "; post-quota attempt $((WAITS+1))"))"
        START=$(date +%s)
        timeout "$TIMEOUT_SECS" claude -p "$(cat "$PROMPT")" > "$OUT" 2>&1
        RC=$?
        SECS=$(( $(date +%s) - START ))

        HBB=0; [ -f "$HB" ] && HBB="$(wc -c < "$HB")"
        if [ "$HBB" -ge 500 ]; then
            say "round $R: exit=$RC ${SECS}s handback=${HBB}B -> OK"
            logrow "$R" "$RC" "$SECS" "$PB" "$HBB" OK
            break
        fi

        # No usable artefact. Before calling it a failed round, ask whether the model refused.
        if is_quota_refusal "$OUT"; then
            WAITS=$(( WAITS + 1 ))
            SLEEP="$(secs_to_reset "$OUT")"
            say "round $R: QUOTA REFUSAL after ${SECS}s (handback=${HBB}B) — this is not a round result"
            if [ "$WAIT_FOR_RESET" != "1" ] || [ "$WAITS" -gt "$MAX_QUOTA_WAITS" ] \
               || [ -z "$SLEEP" ] || [ "$SLEEP" -gt "$MAX_WAIT_SECS" ]; then
                say "round $R: STOPPING THE RUN at the wall — waits=$WAITS parsed_sleep=${SLEEP:-unparseable}"
                say "          Rounds $R..$ROUNDS are NOT dispatched. Re-run this script to resume;"
                say "          completed rounds are skipped by their handback."
                logrow "$R" "$RC" "$SECS" "$PB" "$HBB" QUOTA-EXHAUSTED-RUN-STOPPED
                exit 3
            fi
            logrow "$R" "$RC" "$SECS" "$PB" "$HBB" "QUOTA-WAIT-${WAITS}"
            say "round $R: sleeping ${SLEEP}s to the stated reset, then retrying THIS round (not counting it done)"
            sleep "$SLEEP"
            continue
        fi

        if [ "$HBB" -gt 0 ]; then
            say "round $R: exit=$RC ${SECS}s handback=${HBB}B -> HANDBACK-TRIVIAL"
            logrow "$R" "$RC" "$SECS" "$PB" "$HBB" HANDBACK-TRIVIAL
        else
            say "round $R: exit=$RC ${SECS}s handback=0B -> FAILED-NO-HANDBACK"
            logrow "$R" "$RC" "$SECS" "$PB" "$HBB" FAILED-NO-HANDBACK
        fi
        break
    done
done

say ""
say "=== RUN LOG ==="
cat "$LOG"
say ""
OKN=$(awk -F'\t' 'NR>1 && $7=="OK"' "$LOG" | wc -l)
BAD=$(awk -F'\t' 'NR>1 && $7!="OK" && $7 !~ /^QUOTA-WAIT-/' "$LOG" | wc -l)
WAITED=$(awk -F'\t' 'NR>1 && $7 ~ /^QUOTA-WAIT-/' "$LOG" | wc -l)
say "rounds with a real handback: $OKN"
say "rounds that did not:         $BAD"
say "quota waits absorbed:        $WAITED (not rounds — the same round retried)"
[ "$BAD" -eq 0 ] || say "NOTE: the failed rounds are listed above by verdict. They are not skipped rounds."
exit 0
