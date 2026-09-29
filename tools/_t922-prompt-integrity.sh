#!/usr/bin/env bash
# _t922-prompt-integrity.sh — assert every dispatched procAsFit prompt carries the stored mandate
# VERBATIM, BY HASH, and EXACTLY ONCE.
#
# WHY THIS EXISTS AS A SEPARATE INSTRUMENT. T-922's acceptance criterion says the mandate's presence
# is "asserted by hash against the stored mandate, not by eye". The orchestrator asserts a 200-byte
# prefix with grep -qF, which is a weaker claim than the AC makes. Rather than edit the orchestrator
# while it is mid-run (bash reads a script incrementally — editing a running one corrupts its
# execution), the property is verified here against the prompts already on disk, which is the same
# claim checked independently of the thing that produced them.
#
# THE DEFECT THIS GUARDS, MEASURED. T-897 round 2 built a 92,818-byte prompt from a 4.6KB mandate and
# a 9KB handback: python implicit string concatenation multiplied the preamble 78 times. It read as a
# plausible instruction set. A prefix grep PASSES that prompt — the first 200 bytes are perfect. Only
# "exactly one copy" catches it.
#
# THREE CLAIMS, and the third is the load-bearing one:
#   1. bytes [0, mandate_len) of each prompt hash to the stored mandate's sha256  (verbatim, by hash)
#   2. a mandate-unique line occurs EXACTLY ONCE in the prompt                    (not multiplied)
#   3. both checks are DEMONSTRATED ABLE TO FAIL on a mutated copy               (not vacuous)
# Without 3, a check that silently matched nothing would report all-clear, which is the same class of
# false green the whole run exists to avoid.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90

DIR="${1:-.context/working/procasfit9}"
MANDATE="$DIR/mandate.md"
[ -s "$MANDATE" ] || { echo "SETUP BROKEN: no mandate at $MANDATE"; exit 1; }

MB="$(wc -c < "$MANDATE")"
MSHA="$(sha256sum "$MANDATE" | cut -d' ' -f1)"
# A line long and specific enough that it cannot occur by accident, taken FROM the mandate itself
# rather than typed here — a hand-typed needle is a second copy of the vocabulary (T-322).
NEEDLE="$(grep -m1 -F 'Selection rationale precedes execution' "$MANDATE")"
[ -n "$NEEDLE" ] || { echo "SETUP BROKEN: needle line not found in the mandate"; exit 1; }

PASS=0; FAIL=0
ok() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

echo "=== T-922 prompt integrity ==="
echo "mandate: $MB bytes, sha ${MSHA:0:16}"
echo "needle:  ${NEEDLE:0:60}..."
echo

# ── CONTROL FIRST: prove both checks can fail ────────────────────────────────────────────────
# A passing suite over zero prompts, or over a check that matches anything, is not a measurement.
echo "CONTROLS"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT INT TERM

# C1: a prompt whose mandate region has ONE byte changed must fail the hash leg.
{ sed '1s/^procAsFit/procAsFiT/' "$MANDATE"; printf '\n\ntail\n'; } > "$TMP/mutated.md"
MUT_LEN="$(wc -c < "$TMP/mutated.md")"
[ "$MUT_LEN" -gt "$MB" ] || { echo "MUTATION SETUP BROKEN: mutated file not longer than the mandate"; exit 1; }
got="$(head -c "$MB" "$TMP/mutated.md" | sha256sum | cut -d' ' -f1)"
ok "hash leg REJECTS a one-byte-changed mandate region" "$([ "$got" != "$MSHA" ] && echo 0 || echo 1)"

# C2: a prompt carrying the mandate TWICE must fail the exactly-once leg.
cat "$MANDATE" "$MANDATE" > "$TMP/doubled.md"
n="$(grep -cF "$NEEDLE" "$TMP/doubled.md")"
ok "exactly-once leg REJECTS a doubled mandate (counted $n)" "$([ "$n" -ne 1 ] && echo 0 || echo 1)"

# C3: and it ACCEPTS a single clean copy — otherwise C2 passes for the wrong reason.
n1="$(grep -cF "$NEEDLE" "$MANDATE")"
ok "exactly-once leg ACCEPTS one clean copy (counted $n1)" "$([ "$n1" -eq 1 ] && echo 0 || echo 1)"
echo

# ── THE CLAIM, over every prompt actually dispatched ─────────────────────────────────────────
echo "PROMPTS"
shopt -s nullglob
PROMPTS=( "$DIR"/round*-prompt.md )
if [ "${#PROMPTS[@]}" -eq 0 ]; then
    echo "  FAIL  no prompts to check — the denominator is empty, so this suite asserts nothing"
    FAIL=$((FAIL+1))
else
    echo "  (denominator: ${#PROMPTS[@]} prompt file(s) found on disk, not a hand-typed list)"
    for p in "${PROMPTS[@]}"; do
        b="$(basename "$p")"
        psz="$(wc -c < "$p")"
        if [ "$psz" -lt "$MB" ]; then
            ok "$b carries the mandate verbatim by hash" 1 "prompt is $psz bytes, shorter than the mandate's $MB"
            continue
        fi
        h="$(head -c "$MB" "$p" | sha256sum | cut -d' ' -f1)"
        ok "$b: bytes [0,$MB) hash to the stored mandate" \
           "$([ "$h" = "$MSHA" ] && echo 0 || echo 1)" "got ${h:0:16}, want ${MSHA:0:16}"
        c="$(grep -cF "$NEEDLE" "$p")"
        ok "$b: mandate occurs exactly once (counted $c)" "$([ "$c" -eq 1 ] && echo 0 || echo 1)" \
           "a count above 1 is the T-897 multiplication defect; 0 means the mandate is absent"
    done
fi

echo
echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
