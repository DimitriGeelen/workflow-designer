#!/usr/bin/env bash
# _t412-announced-pair-teeth.sh — prove the ANNOUNCED pair cannot be completed by ONE word.
#
# The pair (secrecy word x credential noun) is the false-positive control for the whole
# ANNOUNCED class. `password` and `passwd` sit in both tuples, so before T-412 a single
# occurrence satisfied both halves and the pair collapsed into a single-word match —
# `reset-password.md` flagged as key material.
#
# THE GENERATIVE LEG (c) IS THE POINT. Legs (a) and (b) pin the three filenames that were
# actually wrong; a fix that special-cased those strings would pass both. Leg (c) derives its
# cases FROM THE WORD TUPLES THEMSELVES at run time, so a future author who adds a new word to
# both lists — or reverts the span rule to list membership — is caught by construction rather
# than by someone remembering to add a case.
#
# Kept separate from _t410-secret-artifact-teeth.sh on purpose: that file's 13 legs are the
# regression surface for this change and its count is asserted in T-412's ACs.
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

echo "=== T-412 announced-pair teeth (subject: ${SUBJECT#$ROOT/}) ==="

# --- (a) the three real false positives ---------------------------------------
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
bad = [f for f in ("docs/reset-password.md", "docs/password-policy.md",
                   "lib/password_reset_test.py")
       if m.classify(f)[0] == "ANNOUNCED"]
print("FLAGGED:" + ",".join(bad) if bad else "NONE")
PY
)"
if [ "$out" != "NONE" ]; then
  fail "(a) prose about passwords must not be classed key material — a scanner that reds on
     a policy document is reverted, not obeyed. $out"
else
  ok "(a) reset-password.md / password-policy.md / password_reset_test.py not flagged"
fi

# --- (b) RECIPROCAL: real pairs still flag ------------------------------------
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
if [ "$out" != "NONE" ]; then
  fail "(b) genuine two-span pairs must still flag. $out"
else
  ok "(b) password-key / secret-token / credential-token / private-key-store still flagged"
fi

# --- (c) GENERATIVE: no single word may complete the pair ---------------------
# Derived from the tuples at run time. `private-key` legitimately spans its own noun, so
# SELF_SUFFICIENT is excluded by design rather than by omission.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
bad = []
for w in set(m.SECRECY_WORDS) | set(m.CREDENTIAL_NOUNS):
    if any(s in w or w in s for s in m.SELF_SUFFICIENT):
        continue                       # announces on its own, by design
    for probe in ("docs/%s-policy.md" % w, "docs/notes-about-%s.md" % w, "docs/%s.md" % w):
        if m.classify(probe)[0] == "ANNOUNCED":
            bad.append("%s (word %r)" % (probe, w))
print("SINGLE-WORD:" + "; ".join(bad) if bad else "NONE")
PY
)"
if [ "$out" != "NONE" ]; then
  fail "(c) a word that satisfies BOTH halves from one span turns the pair into a
     single-word match wearing a pair's clothes (AEF, rail 501). $out"
else
  ok "(c) generative: no word in either tuple completes the pair alone"
fi

# --- (d) the overlap is still THERE, and still harmless -----------------------
# If a later author 'fixes' this by set-differencing the tuples, (c) keeps passing while the
# rule that permitted the bug returns. This leg fails if the overlap disappears, so the fix
# has to stay the span rule rather than a word-list edit.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
ov = sorted(set(m.SECRECY_WORDS) & set(m.CREDENTIAL_NOUNS))
print(",".join(ov) if ov else "EMPTY")
PY
)"
if [ "$out" = "EMPTY" ]; then
  fail "(d) the tuples no longer overlap. That makes (c) pass for the wrong reason: the
     single-word collapse is prevented by curation instead of by the disjoint-span rule,
     and the next plausible word added to both lists brings the bug straight back."
else
  ok "(d) overlap retained ($out) and made harmless by spans, not by curation"
fi

# --- (e) span discipline on the noun half -------------------------------------
# The noun matches whole `-`-separated parts only; `pass` inside `passenger` is not a noun.
out="$(python3 - "$SUBJECT" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("t", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print("FLAGGED" if m.classify("docs/secret-passenger-list.md")[0] == "ANNOUNCED" else "NONE")
PY
)"
if [ "$out" != "NONE" ]; then
  fail "(e) 'pass' inside 'passenger' must not count as a credential noun. $out"
else
  ok "(e) noun half matches whole parts only (passenger is not pass)"
fi

# --- RECIPROCAL: live tree still clean ----------------------------------------
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
echo "TEETH PASS — 6/6 legs (3 behavioural + generative + anti-curation + span discipline)"
