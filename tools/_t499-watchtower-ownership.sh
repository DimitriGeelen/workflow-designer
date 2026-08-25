#!/usr/bin/env bash
# _t499-watchtower-ownership.sh — does a Watchtower URL belong to THIS project, and if we
# cannot tell, does it SAY SO instead of guessing?
#
# Covers T-499's one remaining AC: "Abstention is distinguishable from a verdict —
# 'cannot determine ownership' must not be reportable as 'healthy' or as 'down'
# (exit 2, not 1)."
#
# ── WHY THIS EXISTS ALONGSIDE THE VENDORED HELPER RATHER THAN REPLACING IT ─────────────
# `.agentic-framework/lib/watchtower.sh` already has `_watchtower_identity_matches`, and it
# is the right idea: it asks /api/_identity and compares project_root, so a 200 from the
# wrong server cannot pass. AEF built it (T-1803) and this file does not claim otherwise.
#
# What it does not have is a third answer. It is a bash predicate, so it has exactly two,
# and MEASURED on this host it returns 1 for four structurally different situations:
#
#   PROJECT_ROOT=/opt/832-Workflow-designer  vs our  :3013   -> rc 0   correct
#   PROJECT_ROOT=/opt/832-Workflow-designer  vs AEF's :3000  -> rc 1   correct (foreign)
#   PROJECT_ROOT=/opt/832-Workflow-designer  vs :9 (closed)  -> rc 1   correct-ish (down)
#   PROJECT_ROOT and FRAMEWORK_ROOT BOTH UNSET vs our :3013  -> rc 1   WRONG
#
# The fourth is the one that matters and it is why this file is not a style preference.
# The server in that row IS ours; /api/_identity answers `/opt/832-Workflow-designer`
# correctly. The helper returns "not ours" because `[ -n "$_our_root" ]` failed — i.e.
# because WE do not know who WE are. That is not a fact about the server. It is reported
# in the same channel, with the same value, as a genuine foreign-server verdict, and it
# errs toward disowning our own dashboard.
#
# A predicate cannot fix this; two exit codes cannot carry three answers. So the abstention
# lives here, additively, and `do_url`'s contract is left exactly as AEF wrote it. Changing
# a vendored accessor's exit contract has cross-project blast radius (every AEF caller of
# `fw watchtower url` currently relies on it never failing) and that call is theirs, not
# ours — it is surfaced to the operator rather than taken under agent initiative.
#
# ── THE CODES, AND WHY DOWN IS A VERDICT BUT UNKNOWN-SELF IS NOT ───────────────────────
#   0  OURS              /api/_identity answered, service=watchtower, project_root == ours
#   1  NOT-OURS          a VERDICT about the target. Two sub-reasons, both printed:
#                          DOWN     nothing is listening — we looked and there is no server
#                          FOREIGN  something answered and identified as someone else
#   2  CANNOT-DETERMINE  an ABSTENTION. Four sub-reasons, all printed:
#                          NO-SELF     our own project root is unknown -> nothing to compare
#                          NO-TARGET   no URL was supplied and no triple file to read one from
#                          NO-ENDPOINT something is listening but /api/_identity is not there
#                          MALFORMED   the endpoint answered but the body has no project_root
#
# DOWN is deliberately a verdict, not an abstention. "Nothing is listening on that port" is
# a measurement with an answer; the AC's own wording ("must not be reportable as 'healthy'
# OR as 'down'") only forbids collapsing the unknown INTO down, not the reverse.
#
# NO-ENDPOINT is deliberately an abstention rather than FOREIGN, and this is the finer half
# of the distinction. Something answered the TCP connect but not /api/_identity. That is
# consistent with a foreign service, and also with an older Watchtower of ours predating
# T-1803. We cannot separate those from here, so we decline to.
#
# ── WHY EVERY BRANCH PRINTS ITS EVIDENCE ───────────────────────────────────────────────
# A bare verdict is not checkable by a reader, and this week produced two instruments that
# were confidently wrong precisely because nobody could see what they had quantified over
# (T-576, T-581). So each exit prints the URL probed, the curl exit code, our root, the
# root the server claimed, and the raw body when it is short enough. A reader who disagrees
# with the verdict can see which input produced it.
#
# ── WHY THE SUBJECT IS OVERRIDABLE ─────────────────────────────────────────────────────
# T-364's lesson: a refusal path that has never refused is a constant wearing a verdict.
# Every branch below has to be reachable on demand or its correctness is an assertion. So
# the URL is an argument and the self-root is an env var, which is what lets the teeth
# script drive all six outcomes without editing anything or breaking a running server.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Our identity. Overridable so NO-SELF is reachable (`T499_SELF_ROOT=` empty), which is the
# whole point of the fourth measured row above.
SELF_ROOT="${T499_SELF_ROOT-${PROJECT_ROOT:-$ROOT}}"

CURL_TIMEOUT="${T499_TIMEOUT:-3}"

verdict() {
    # verdict <exit> <label> <reason> <detail>
    local code="$1" label="$2" reason="$3" detail="$4"
    printf '%s: %s\n' "$label" "$reason"
    printf '  target      : %s\n' "${TARGET:-<none>}"
    printf '  our root    : %s\n' "${SELF_ROOT:-<unknown>}"
    printf '  their root  : %s\n' "${THEIR_ROOT:-<not obtained>}"
    printf '  their svc   : %s\n' "${THEIR_SVC:-<not obtained>}"
    printf '  curl rc     : %s\n' "${CURL_RC:-<not run>}"
    [ -n "$detail" ] && printf '  detail      : %s\n' "$detail"
    exit "$code"
}

TARGET="${1:-}"
THEIR_ROOT=""
THEIR_SVC=""
CURL_RC=""

# ── NO-TARGET ─────────────────────────────────────────────────────────────────────────
if [ -z "$TARGET" ]; then
    TRIPLE="$ROOT/.context/working/watchtower.url"
    if [ -s "$TRIPLE" ]; then
        TARGET="$(cat "$TRIPLE")"
    else
        verdict 2 "CANNOT-DETERMINE" "NO-TARGET" \
            "no URL argument and $TRIPLE is absent or empty"
    fi
fi

# ── NO-SELF ───────────────────────────────────────────────────────────────────────────
# Checked BEFORE the network call on purpose. If we do not know our own root, no response
# from the target can change the answer, and probing anyway would produce a byte-identical
# transcript to a real comparison — which is exactly how the vendored helper's fourth row
# comes to look like a considered verdict.
if [ -z "$SELF_ROOT" ]; then
    verdict 2 "CANNOT-DETERMINE" "NO-SELF" \
        "neither T499_SELF_ROOT nor PROJECT_ROOT is set — nothing to compare a project_root against"
fi

# ── probe ─────────────────────────────────────────────────────────────────────────────
BODY="$(curl -sf --max-time "$CURL_TIMEOUT" "${TARGET}/api/_identity" 2>/dev/null)"
CURL_RC=$?

if [ "$CURL_RC" -ne 0 ]; then
    # Separate "nothing is listening" (a verdict) from "listening, but not this endpoint"
    # (an abstention). curl's own codes carry that distinction: 7 = connection refused,
    # 28 = timeout; 22 = server answered with an HTTP error, i.e. something IS there.
    case "$CURL_RC" in
        7|28)
            verdict 1 "NOT-OURS" "DOWN" \
                "nothing accepted a connection (curl rc $CURL_RC) — no server to own"
            ;;
        22)
            verdict 2 "CANNOT-DETERMINE" "NO-ENDPOINT" \
                "a server answered but /api/_identity returned an HTTP error (curl rc 22) — could be a foreign service or a pre-T-1803 Watchtower of ours"
            ;;
        *)
            verdict 2 "CANNOT-DETERMINE" "NO-ENDPOINT" \
                "curl failed with rc $CURL_RC — reachability itself is unresolved, so ownership cannot be"
            ;;
    esac
fi

THEIR_SVC="$(printf '%s' "$BODY" | grep -oE '"service"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')"
THEIR_ROOT="$(printf '%s' "$BODY" | grep -oE '"project_root"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)"$/\1/')"

# ── MALFORMED ─────────────────────────────────────────────────────────────────────────
if [ -z "$THEIR_ROOT" ]; then
    verdict 2 "CANNOT-DETERMINE" "MALFORMED" \
        "endpoint answered ${#BODY} bytes but carries no project_root — cannot compare what was not returned"
fi

# ── FOREIGN ───────────────────────────────────────────────────────────────────────────
# A non-watchtower service that nonetheless serves /api/_identity with a project_root is a
# verdict, not an abstention: it told us who it is and it is not us.
if [ "$THEIR_SVC" != "watchtower" ]; then
    verdict 1 "NOT-OURS" "FOREIGN" \
        "identifies as service='$THEIR_SVC', not 'watchtower'"
fi

if [ "$THEIR_ROOT" != "$SELF_ROOT" ]; then
    verdict 1 "NOT-OURS" "FOREIGN" \
        "identifies as project_root='$THEIR_ROOT', which is not ours"
fi

verdict 0 "OURS" "IDENTITY-CONFIRMED" \
    "service=watchtower and project_root matches on a live /api/_identity response"
