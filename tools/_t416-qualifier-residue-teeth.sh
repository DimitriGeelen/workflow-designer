#!/usr/bin/env bash
# _t416-qualifier-residue-teeth.sh — a word spent as the QUALIFIER cannot be re-spent as the NOUN.
#
# T-412 required the pair to match at disjoint spans and proved it with a generative leg that
# probed every word ALONE. That leg is why this defect survived: a name carrying TWO members
# of the password family satisfies both halves at two different spans, and no single-word
# probe can construct that name. The generative leg here enumerates PAIRS.
#
# Leg (c) is the one that matters. Leg (a) pins the four names T-415 measured; a fix that
# special-cased those strings would pass it.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJECT="${SUBJECT:-$ROOT/tools/tracked-secret-artifacts.py}"

fails=0
legs=0
# T-430: `fails` alone cannot tell "clean" from "never ran" — both print fails=0 and both
# exit 0. `legs` counts every recorded outcome; the guard below reads legs+fails.
# leg() is defined FIRST so a zero-leg simulation silences the tally that matters, and the
# increment is NOT confined to fail(), the one helper a green run never calls.
# Full rationale: tools/_t400-schema-teeth.sh, tools/_t430-abstention-teeth.sh.
leg()  { legs=$((legs + 1)); }
fail() { leg; echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { leg; echo "  ok  $*"; }

echo "=== T-416 qualifier-residue teeth (subject: ${SUBJECT#$ROOT/}) ==="

# --- (a) the T-415 witnesses -----------------------------------------------------
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
bad = [f for f in ("docs/secret-password-rotation.md", "docs/credential-password-guide.md",
                   "docs/passwd-password-migration.md", "config/auth-password-policy.json")
       if m.classify(f)[0] == "ANNOUNCED"]
print("FLAGGED:" + ",".join(bad) if bad else "NONE")
PY
)"
[ "$out" = "NONE" ] \
  && ok "(a) two-qualifier prose names unflagged (incl. AEF's auth-password-policy.json)" \
  || fail "(a) a name built from two qualifiers and no credential noun is not key material. $out"

# --- (b) RECIPROCAL: genuine pairs still flag ------------------------------------
# Without this, (a) is satisfied by deleting the ANNOUNCED class entirely.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
want = ("config/password-key.txt", "config/secret-token.bak", "config/app_secret_key",
        "etc/credential-token.dat", "x/private-key-store.dat", "x/privkey.dat")
miss = [f for f in want if m.classify(f)[0] is None]
print("MISSED:" + ",".join(miss) if miss else "NONE")
PY
)"
[ "$out" = "NONE" ] \
  && ok "(b) genuine pairs still flag — pre-existing behaviour, unchanged by this fix" \
  || fail "(b) a real announced pair stopped flagging. $out"

# --- (f) A MISS THIS FIX CLOSES, kept apart from (b) on purpose ------------------
# `mypasswordkey.bin` has no separators, so under T-412's rule the whole-part noun match
# found nothing and it went UNFLAGGED — a real secret, missed. Masking substitutes `-` and
# thereby creates the part boundary, so `key` becomes visible.
#
# This is separated from (b) because (b) must stay GREEN when the mutation check reverts the
# fix — that is what proves (a)/(c) are isolating the residue rule rather than collapsing the
# class. This leg legitimately goes red there, and conflating the two made the mutation check
# report the improvement as collateral damage.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print("FLAGGED" if m.classify("x/mypasswordkey.bin")[0] == "ANNOUNCED" else "MISSED")
PY
)"
[ "$out" = "FLAGGED" ] \
  && ok "(f) no-separator name mypasswordkey.bin now flags (masking creates the boundary)" \
  || fail "(f) mypasswordkey.bin unflagged — the separator masking creates is what makes the
     noun visible in a name that has no separators of its own. $out"

# --- (c) GENERATIVE OVER PAIRS ---------------------------------------------------
# Every ORDERED pair of secrecy words, with no credential noun present. T-412's generative
# leg probed single words and could not build these names; that is the whole reason this
# class survived it. SELF_SUFFICIENT is excluded by design — those announce alone.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
bad = []
words = [w for w in m.SECRECY_WORDS
         if not any(s in w or w in s for s in m.SELF_SUFFICIENT)]
for a in words:
    for b in words:
        for probe in ("docs/%s-%s-policy.md" % (a, b),
                      "docs/%s-%s.md" % (a, b),
                      "notes/about-%s-and-%s.txt" % (a, b)):
            if m.classify(probe)[0] == "ANNOUNCED":
                bad.append("%s (%s + %s)" % (probe, a, b))
print("PAIRED:" + "; ".join(bad) if bad else "NONE")
PY
)"
[ "$out" = "NONE" ] \
  && ok "(c) generative: no PAIR of secrecy words completes the rule without a noun" \
  || fail "(c) two qualifiers completed the pair with no credential noun between them —
     a word spent as the qualifier was re-spent as the noun. $out"

# --- (d) the overlap is still THERE ----------------------------------------------
# Inherited from T-412 and still load-bearing: if a later author repairs this by
# set-differencing the tuples, (c) keeps passing while the rule that permits it returns.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
ov = sorted(set(m.SECRECY_WORDS) & set(m.CREDENTIAL_NOUNS))
print(",".join(ov) if ov else "EMPTY")
PY
)"
[ "$out" != "EMPTY" ] \
  && ok "(d) overlap retained ($out), made harmless by residue rather than by curation" \
  || fail "(d) the tuples no longer overlap — (c) now passes for the wrong reason."

# --- (e) masking must SUBSTITUTE, not delete -------------------------------------
# Deleting the qualifier closes the gap and lets a noun be assembled from the neighbours
# either side of it. This name has no whole-part noun; it must only produce one if the
# implementation deletes.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
# 'to' + <secret masked out> + 'ken' -> deletion yields the whole part 'token'.
print("FLAGGED" if m.classify("docs/to-secret-ken.md")[0] == "ANNOUNCED" else "NONE")
PY
)"
[ "$out" = "NONE" ] \
  && ok "(e) qualifier masked to a separator — no noun assembled across the seam" \
  || fail "(e) 'to' + 'ken' became 'token' once the qualifier between them was removed.
     Masking must substitute a separator, not delete. $out"

# --- RECIPROCAL: live tree still clean -------------------------------------------
out="$(python3 "$SUBJECT" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "RECIPROC: live tree must still scan clean. rc=$rc
$out"
elif ! echo "$out" | grep -qE "scan ok: [0-9]{4,} tracked file"; then
  fail "RECIPROC: passed, but not over a four-digit population
$out"
else
  ok "RECIPROC live tree clean over its full population"
fi

echo
# T-430 abstention guard — before the verdict, or the verdict answers first.
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "TEETH FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "TEETH PASS — 7/7 legs (2 behavioural + closed-miss + generative-over-pairs + anti-curation + mask-not-delete + live)"
