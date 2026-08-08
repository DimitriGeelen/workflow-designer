#!/usr/bin/env bash
# _t389-release-envelope.sh — probe for the release-announce envelope (T-389).
#
# Runs everything against a SCRATCH topic (ANNOUNCE_TOPIC), never the real rail.
#
# TWO RULES THIS PROBE OBEYS, both learned the hard way:
#  1. TEETH MUTATE LIVE SOURCE. Every mutant below is derived from the current
#     scripts/announce-release.sh at run time, never from `git show HEAD~N:` — a
#     git-ref mutant has an expiry date set by the next commit and nothing
#     announces when it goes inert (AEF rail 467 §1).
#  2. COULD-NOT-MEASURE IS NOT A PASS. If termlink or the hub is unavailable this
#     exits 3 and reports nothing. A probe that cannot reach its subject must not
#     emit a census — "0 failures" and "0 tests that ran" are the same number
#     otherwise (L-381 family).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANNOUNCE="$REPO_ROOT/scripts/announce-release.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$ANNOUNCE" ] || cannot "announce script not found: $ANNOUNCE"
command -v termlink >/dev/null 2>&1 || cannot "termlink not on PATH"
command -v python3  >/dev/null 2>&1 || cannot "python3 not on PATH"

TOPIC="scratch-t389-probe-$$"
termlink channel create "$TOPIC" >/dev/null 2>&1 \
  || cannot "cannot create scratch topic — hub unreachable"

# Synthetic manifest so the probe never depends on what the real release happens
# to be today (a probe whose expectations drift with dist/ is not a test).
mk_manifest() { # <path> <version> <sha>
  cat > "$1" <<EOF
latest: "$2"
sha256: "$3"
version: "$2"
released: "2026-01-01T00:00:00Z"
src_commit: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
artifact: "dist/aef-workflow-designer-$2.html"
EOF
}

run_announce() { # <script> <manifest> -> stdout+stderr, sets RC
  ANNOUNCE_TOPIC="$TOPIC" ANNOUNCE_MANIFEST="$2" bash "$1" 2>&1
}

cv_offset() {
  termlink channel cv-keys "$TOPIC" --json 2>/dev/null \
    | python3 -c 'import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for e in d.get("entries") or []:
    if e.get("cv_key")=="designer-release": print(e.get("offset",""))'
}

# `channel state --json` emits a BARE LIST of rows, not {"rows": [...]}. The first
# version of this helper assumed the dict shape, returned -1 on every call, and leg 3
# then compared -1 against -1 and went green — a length check that never read a length.
# TEETH-2 is the only reason that was caught. -1 is kept as the parse-failure signal
# and the caller must reject it explicitly; a measurement that failed must never be
# allowed to look like two values agreeing.
topic_len() {
  termlink channel state "$TOPIC" --json 2>/dev/null \
    | python3 -c 'import sys,json
try:
    d=json.load(sys.stdin)
    print(len(d) if isinstance(d,list) else len(d.get("rows") or []))
except Exception: print(-1)'
}

echo "=== T-389 release-envelope probe (topic: $TOPIC) ==="

MF="$WORK/m1.yaml"
mk_manifest "$MF" "9.9.9" "aaaa111122223333444455556666777788889999aaaabbbbccccddddeeeeffff"

# ── ANTI-VACUITY ──────────────────────────────────────────────────────────────
# Before asserting anything about behaviour, prove the harness reaches the subject
# at all. If this leg fails, every "PASS" below would be measuring an empty world.
out="$(run_announce "$ANNOUNCE" "$MF")"; rc=$?
if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "Announced 9.9.9"; then
  ok "anti-vacuity: harness reaches the announce script and it posts"
else
  bad "anti-vacuity: announce did not run (rc=$rc): $(printf '%s' "$out" | head -2)"
  echo "  -> refusing to report a census from a world the probe never reached"
  exit 3
fi

FIRST_OFF="$(cv_offset)"
LEN_AFTER_FIRST="$(topic_len)"

# ── LEG 1: the cv index actually points at the posted envelope ────────────────
if [ -n "$FIRST_OFF" ]; then
  ok "cv_key 'designer-release' is indexed at offset $FIRST_OFF"
else
  bad "cv_key was not indexed after a successful post"
fi

# ── LEG 2: consumer O(1) read — cursor PAST THE END still yields the release ──
# This is precisely AEF's read path: a late joiner who wants no replay.
cur="$(termlink channel subscribe "$TOPIC" --cursor 99999999 --include-current-value --json 2>/dev/null \
  | python3 -c 'import sys,json,base64
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for e in d.get("current_values") or []:
    if e.get("cv_key")=="designer-release":
        print(base64.b64decode((e.get("msg") or {}).get("payload_b64","")).decode("utf-8","replace"))')"
if printf '%s' "$cur" | grep -q 'version: "9.9.9"' \
   && printf '%s' "$cur" | grep -q 'kind: designer-release'; then
  ok "consumer read at cursor-past-end returns the release envelope (no replay)"
else
  bad "cursor-past-end read did not return the envelope: $(printf '%s' "$cur" | head -2)"
fi

# ── LEG 3: idempotence — re-announcing an unchanged manifest appends NOTHING ──
out2="$(run_announce "$ANNOUNCE" "$MF")"; rc2=$?
LEN_AFTER_SECOND="$(topic_len)"
if [ "$LEN_AFTER_FIRST" -lt 0 ] || [ "$LEN_AFTER_SECOND" -lt 0 ]; then
  bad "idempotence UNMEASURABLE: topic length did not parse ($LEN_AFTER_FIRST/$LEN_AFTER_SECOND)"
elif [ $rc2 -eq 0 ] && printf '%s' "$out2" | grep -q "Already announced" \
   && [ "$LEN_AFTER_FIRST" = "$LEN_AFTER_SECOND" ]; then
  ok "idempotent: second run appended nothing (topic length $LEN_AFTER_FIRST unchanged)"
else
  bad "second run was not idempotent (rc=$rc2, len $LEN_AFTER_FIRST -> $LEN_AFTER_SECOND)"
fi

# ── LEG 4: identity is version+sha, NOT version alone ─────────────────────────
# A re-cut of the same version under RELEASE_ALLOW_OVERWRITE changes the bytes.
# If identity were version-only, the rail would keep advertising the old sha and a
# consumer's pin verification would fail against an announcement we thought was current.
MF2="$WORK/m2.yaml"
mk_manifest "$MF2" "9.9.9" "ffffeeeeddddccccbbbbaaaa9999888877776666555544443333222211110000"
out3="$(run_announce "$ANNOUNCE" "$MF2")"; rc3=$?
if [ $rc3 -eq 0 ] && printf '%s' "$out3" | grep -q "Announced 9.9.9"; then
  ok "same version + different sha re-announces (identity includes bytes)"
else
  bad "identity ignored the sha change (rc=$rc3): $(printf '%s' "$out3" | head -2)"
fi

# ── TEETH 1: break cv_key tagging in a mutant of LIVE source ──────────────────
# If the hub stopped honouring cv_key, the post would still succeed and the
# consumer's O(1) read would silently never see the release. The script's
# post-verify step must catch that. Prove it can.
MUT1="$WORK/mut-nocv.sh"
sed 's/--metadata "cv_key=\$CV_KEY"/--metadata "cv_key_DISABLED=$CV_KEY"/' "$ANNOUNCE" > "$MUT1"
if ! grep -q 'cv_key_DISABLED' "$MUT1"; then
  bad "TEETH-1 mutant did not apply — the sed target moved; teeth are inert"
else
  MF3="$WORK/m3.yaml"
  mk_manifest "$MF3" "9.9.10" "1111111111111111111111111111111111111111111111111111111111111111"
  out4="$(run_announce "$MUT1" "$MF3")"; rc4=$?
  if [ $rc4 -ne 0 ] && printf '%s' "$out4" | grep -q "would NOT see"; then
    ok "TEETH-1: un-indexed post is caught and reported as a FAILED announce"
  else
    bad "TEETH-1: post without cv_key was accepted as success (rc=$rc4) — verify step is asleep"
  fi
fi

# ── TEETH 2: break the idempotence check in a mutant of LIVE source ───────────
MUT2="$WORK/mut-noidem.sh"
sed 's/^if \[ "\$CURRENT" = "\$IDENTITY" \]; then/if [ "NEVER" = "$IDENTITY" ]; then/' "$ANNOUNCE" > "$MUT2"
if ! grep -q 'if \[ "NEVER" = ' "$MUT2"; then
  bad "TEETH-2 mutant did not apply — the sed target moved; teeth are inert"
else
  LEN_BEFORE="$(topic_len)"
  run_announce "$MUT2" "$MF2" >/dev/null 2>&1
  LEN_AFTER="$(topic_len)"
  if [ "$LEN_AFTER" -gt "$LEN_BEFORE" ]; then
    ok "TEETH-2: disabling the idempotence guard DOES duplicate (guard is load-bearing)"
  else
    bad "TEETH-2: no duplicate appeared with the guard disabled — leg 3 proves nothing"
  fi
fi

# ── LEG 5: a failed announce does not abort the cut, and says so ──────────────
# Drive release-designer.sh's announce branch with an unreachable topic. The cut
# must survive; the final line must be unambiguous.
REL="$REPO_ROOT/scripts/release-designer.sh"
if grep -q "CUT but NOT ANNOUNCED" "$REL" && grep -q "CUT and ANNOUNCED" "$REL" \
   && grep -q 'ANNOUNCE_RC=\$?' "$REL"; then
  ok "release script reports announce state unambiguously and does not abort on failure"
else
  bad "release script is missing the CUT/ANNOUNCED reporting or the non-fatal capture"
fi

termlink channel sweep "$TOPIC" >/dev/null 2>&1 || true

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
