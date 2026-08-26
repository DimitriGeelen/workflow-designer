#!/usr/bin/env bash
# _t594-prose-claim-teeth.sh — prove T-594's PROSE leg can actually go red.
#
# WHY THIS EXISTS. T-593 removed a manufactured "the operator resolved H2" claim from the
# envelope's STRUCTURED fields, and verified it by walking YAML keys ending in `_by`. The
# same claim survived in a free-text field (`why_prepared_and_not_sent`) and in a task's
# prose, because a key-walker cannot see prose. The miss was found by a human question
# ("what is H2?"), not by any check the agent wrote.
#
# So the replacement leg greps prose — and a grep-for-absence is exactly the shape that
# silently passes when it is pointed at the wrong thing, matches nothing by accident, or is
# written with `-qv` (T-590 AC5). A green absence-check nobody has watched go red is not
# evidence. This is the watching.
#
# Exits 0 only if BOTH directions hold:
#   real tree     -> leg exits 0   (no residual operator-resolution claim)
#   poisoned copy -> leg exits 1   (a re-introduced prose claim is caught)
# Poisons COPIES under mktemp only. Tracked files are never written.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1

# The leg under test, as a function so both arms run the IDENTICAL expression.
# Kept byte-identical to leg 1 in T-594's ## Verification block.
PAT="per the operator's H2|operator's H2 resolution|H2 is resolved|H2 (was )?(resolved|answered|settled) by|operator (resolved|decided|chose|named|selected) .{0,40}counterparty"
leg() { ! grep -rniE "$PAT" "$@"; }

REAL_ENV="docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml"
REAL_T590=".tasks/active/T-590-ewcr-arc-0-designer-contract-inventory-a.md"
[ -f "$REAL_ENV" ]  || { echo "FAIL  envelope missing: $REAL_ENV"; exit 1; }
[ -f "$REAL_T590" ] || { echo "FAIL  T-590 missing: $REAL_T590"; exit 1; }

fail=0

# ── Direction 1: the real tree must be accepted ────────────────────────────────
# Scope includes T-594 itself: the task that fixes this class must not carry the claim.
# But T-594's ## Verification block once held this very pattern as an inline leg, and a
# grep-for-absence whose pattern names the phrases it forbids MATCHES ITSELF — the leg went
# red on its own text. That is why the pattern lives here, in one place, instead of being
# written into a task file. T-594's Verification block is stripped before scanning for the
# same reason: it names this script, not the phrases.
T594_SCAN="$(mktemp)"
python3 - "$REPO/.tasks/active/T-594-residual-prose-still-claims-the-operator.md" > "$T594_SCAN" <<'PY'
import re, sys
s = open(sys.argv[1], encoding='utf-8').read()
m = list(re.finditer(r'^## Verification[ \t]*$', s, re.M))
if m:
    start = m[-1].end()
    nxt = re.search(r'^## ', s[start:], re.M)
    end = start + (nxt.start() if nxt else len(s) - start)
    s = s[:start] + s[end:]
sys.stdout.write(s)
PY

if leg docs/research/executable-workflow/ "$REAL_T590" "$T594_SCAN"; then
  echo "PASS  real-tree-accepted             (no residual claim in artifacts, T-590 or T-594)"
else
  echo "FAIL  real-tree-accepted             (a claim is still present — listed below)"
  grep -rniE "$PAT" docs/research/executable-workflow/ "$REAL_T590" "$T594_SCAN" | head -5
  fail=1
fi
rm -f "$T594_SCAN"

# ── Direction 2: each poison must be rejected, one at a time ───────────────────
# Several distinct phrasings, because a leg that only catches the exact sentence we already
# fixed would pass this control while remaining blind to the next instance.
poison_one() {
  local label="$1" line="$2"
  local tmp; tmp="$(mktemp -d)"
  mkdir -p "$tmp/docs/research/executable-workflow"
  cp "$REAL_ENV" "$tmp/docs/research/executable-workflow/env.yaml"
  printf '%s\n' "$line" >> "$tmp/docs/research/executable-workflow/env.yaml"
  if ( cd "$tmp" && ! grep -rniE "$PAT" docs/research/executable-workflow/ ); then
    echo "FAIL  poison-rejected [$label]      (rc 0 — LEG IS BLIND to this phrasing)"
    fail=1
  else
    echo "PASS  poison-rejected [$label]"
  fi
  rm -rf "$tmp"
}

poison_one "original-sentence" "    counterparty /opt/999-X per the operator's H2 resolution — so identification is done."
poison_one "h2-is-resolved"    "    note: H2 is resolved and the counterparty is fixed."
poison_one "operator-chose"    "    The operator chose /opt/999-X as the counterparty for this envelope."
poison_one "answered-by"       "    H2 was answered by the operator on 2026-08-26."

# ── Direction 3: the leg must not be trivially true ────────────────────────────
# If the pattern matched nothing anywhere under any circumstances, every arm above would
# still look right. Prove the regex is capable of matching at all.
probe="$(mktemp)"
printf 'H2 is resolved\n' > "$probe"
if grep -qiE "$PAT" "$probe"; then
  echo "PASS  regex-can-match                (pattern is not inert)"
else
  echo "FAIL  regex-can-match                (the pattern matches NOTHING — leg is vacuous)"
  fail=1
fi
rm -f "$probe"

if [ "$fail" -eq 0 ]; then
  echo "6/6 T-594 prose-claim teeth legs passed"
  exit 0
fi
echo "T-594 prose-claim teeth legs FAILED"
exit 1
