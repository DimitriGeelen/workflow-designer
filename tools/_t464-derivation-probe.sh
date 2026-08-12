#!/usr/bin/env bash
# _t464-derivation-probe.sh — prove the T-400 RECIPROC leg DERIVES its expected population
# instead of restating it, in both directions, without touching the live register.
#
# WHY THIS EXISTS. The leg spelled its expectation as the literal `schema ok: 25 entries`.
# The register grew to 34 and the leg went red — for nine consecutive gap registrations,
# none of which had any reason to come and edit tools/_t400-schema-teeth.sh. The literal
# is gone now, but "it is derived" is a claim, and a claim about a guard is worth exactly
# what a claim about a register field is worth (G-027). So it is measured.
#
# FOUR MUTATIONS, because a one-directional proof is half a proof:
#   M0 baseline   an untouched copy is green         (else every red below is the fixture)
#   M1 truncation subject under-reports, register unchanged -> leg MUST fail
#   M2 growth     register gains a real entry        -> leg MUST stay green
#   M3 regression the old literal put back at 34     -> leg MUST fail (the defect was real)
#
# M1 is the one that matters. Truncating the FILE would move the subject's count and the
# derived count together and prove nothing — the hazard the leg names is a subject that
# reads FEWER entries than the register holds. So the mutation is applied to the SUBJECT's
# traversal, and the register is left alone.
#
# The live register is never written. Everything runs in a relocated ROOT under $TMP, and
# the last leg asserts the live file's sha256 is unchanged — because a check that damages
# the artefact it inspects will eventually be run by someone who skips the restore (T-463).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIVE_REG="$ROOT/.context/project/concerns.yaml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
legs=0
leg()  { legs=$((legs + 1)); }
fail() { leg; echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { leg; echo "  ok  $*"; }

SHA_BEFORE="$(sha256sum "$LIVE_REG" | cut -d' ' -f1)"

echo "=== T-464 derivation probe (subject: tools/_t400-schema-teeth.sh RECIPROC leg) ==="

build() { # build a fresh relocated ROOT
  rm -rf "$TMP/tree"
  mkdir -p "$TMP/tree/tools" "$TMP/tree/.context/project"
  cp "$ROOT/tools/_t400-schema-teeth.sh" "$ROOT/tools/concerns-schema.py" "$TMP/tree/tools/"
  cp "$LIVE_REG" "$TMP/tree/.context/project/concerns.yaml"
}
run() { bash "$TMP/tree/tools/_t400-schema-teeth.sh" 2>&1; }

N="$(grep -c '^- id: ' "$LIVE_REG")"
if [ "${N:-0}" -lt 2 ]; then
  fail "PRE: counted ${N:-0} column-0 '- id:' lines in the live register — the probe's own
     denominator is broken, so every verdict below would be about nothing (PL-084)."
else
  ok "PRE  live register holds $N entries (counted textually, column-0 '- id:')"
fi

# --- M0 baseline -------------------------------------------------------------
build
out="$(run)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "M0: an untouched relocated copy must be green, else M1-M3 measure the fixture. rc=$rc
$out"
elif ! echo "$out" | grep -q "passes over all $N entries"; then
  fail "M0: green, but the leg did not report the derived population $N — the derivation
     may not be running at all
$out"
else
  ok "M0  untouched copy green, leg reports the derived population $N"
fi

# --- M1 truncated read -------------------------------------------------------
build
python3 - "$TMP/tree/tools/concerns-schema.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
new = s.replace("    return out\n",
                "    return out[:5]   # T-464 probe: simulated truncated read\n", 1)
assert new != s, "T-464 probe could not apply the truncation mutation"
open(p, "w").write(new)
PY
if [ $? -ne 0 ]; then
  fail "M1: the mutation did not apply — a probe that silently fails to mutate reports the
     unmutated run as evidence"
else
  out="$(run)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    fail "M1: the subject was cut to 5 entries and the leg stayed GREEN. The expectation is
     not independent of the subject — it is being derived from the thing it guards, which
     is the vacuity the leg's own failure text warns about
$out"
  elif ! echo "$out" | grep -q "not over the derived population"; then
    fail "M1: red, but not for the population reason — some other leg broke and this probe
     would bank an unrelated failure as proof (the tool-crash-as-baseline class, T-463)
$out"
  else
    ok "M1  subject truncated to 5, register untouched -> leg fails, names the population"
  fi
fi

# --- M2 growth ---------------------------------------------------------------
build
cat >> "$TMP/tree/.context/project/concerns.yaml" <<'EOF'
- id: G-999
  type: gap
  status: watching
  severity: low
  title: "T-464 synthetic growth probe"
  decision_trigger: "discarded with the temp tree"
EOF
grown=$((N + 1))
out="$(run)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "M2: one genuine entry added and the leg went RED — it tracks nothing; this is the
     exact failure T-464 was filed for, reproduced. rc=$rc
$out"
elif ! echo "$out" | grep -q "passes over all $grown entries"; then
  fail "M2: green, but not over $grown — the derived count did not follow the register
$out"
else
  ok "M2  register grown to $grown -> leg stays green and moves with it"
fi

# --- M3 the defect itself ----------------------------------------------------
build
python3 - "$TMP/tree/tools/_t400-schema-teeth.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
new = s.replace('grep -q "schema ok: $expect entries"',
                'grep -q "schema ok: 25 entries"', 1)
assert new != s, "T-464 probe could not restore the historical literal"
open(p, "w").write(new)
PY
if [ $? -ne 0 ]; then
  fail "M3: could not put the old literal back — the assertion string this probe expects to
     find has changed shape, so the regression direction is unmeasured"
else
  out="$(run)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    fail "M3: the historical literal (25) was restored against a $N-entry register and the
     suite still passed — meaning the leg is not actually comparing anything
$out"
  else
    ok "M3  historical literal restored at $N entries -> red (the reported defect was real)"
  fi
fi

# --- integrity ---------------------------------------------------------------
SHA_AFTER="$(sha256sum "$LIVE_REG" | cut -d' ' -f1)"
if [ "$SHA_BEFORE" != "$SHA_AFTER" ]; then
  fail "INTEGRITY: the live register changed during the probe ($SHA_BEFORE -> $SHA_AFTER).
     A check that damages the artefact it inspects will eventually be run by someone who
     skips the restore."
else
  ok "INTEGRITY live register byte-identical (${SHA_BEFORE:0:16}), mutations stayed in \$TMP"
fi

echo
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "PROBE FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "PROBE PASS — $legs legs recorded (pre + M0-M3 + integrity)"
