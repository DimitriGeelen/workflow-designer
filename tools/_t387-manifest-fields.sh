#!/bin/bash
# T-387 — do the four consumer-facing fields survive a re-run, and do they move
# when they should?
#
# The interesting property is not "the fields are present" — a template emits that.
# It is that `released:` is STICKY across an idempotent re-run and MOVES on a real
# cut. Those pull in opposite directions and only one of them can be checked by
# looking at the file once.
#
# WHY A SANDBOX. The live guard refuses to re-cut 0.8.0 while src has moved past it,
# so the live repo cannot answer the re-run question at all — and a probe that
# reported "idempotent" from a tree where the second run ABORTED would be asserting
# from a refusal. Same shape as T-381's entry leg passing because the fixture was
# never there. The sandbox is a real repo with a real VERSION so both runs execute.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
SCRIPT="$PROJ/scripts/release-designer.sh"
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SB="$SCRATCH/t387-$$-$(date +%s)"

[ -f "$SCRIPT" ] || { echo "COULD-NOT-MEASURE: release script not found" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

mkdir -p "$SB/scripts" "$SB/src" "$SB/dist"
cp "$SCRIPT" "$SB/scripts/release-designer.sh"
git -C "$SB" init -q 2>/dev/null
printf '<html><body>v-one</body></html>\n' > "$SB/src/aef-workflow-designer.html"
printf '0.1.0\n' > "$SB/VERSION"
git -C "$SB" add -A >/dev/null 2>&1
git -C "$SB" -c user.email=p@p -c user.name=probe commit -qm "probe base" >/dev/null 2>&1

run_release() { (cd "$SB" && RELEASE_SKIP_RENDER_CHECK=1 bash scripts/release-designer.sh) >/dev/null 2>&1; }
field() { sed -n "s/^$2: *\"\(.*\)\"/\1/p" "$1" | head -1; }

echo "=== T-387 manifest field behaviour ==="
echo "sandbox: $SB"

# ---------------------------------------------------------------- run one ----
echo
echo "--- first cut (0.1.0)"
run_release
M="$SB/dist/MANIFEST.yaml"
if [ ! -f "$M" ]; then
    echo "COULD-NOT-MEASURE: no manifest produced by the first run" >&2
    exit 3
fi
for f in version released src_commit supersedes; do
    v=$(field "$M" "$f")
    if [ "$f" = "supersedes" ]; then
        # Empty is CORRECT for a first release; assert the key exists rather than
        # that it is non-empty, or the leg would demand a wrong value.
        if grep -q "^supersedes:" "$M"; then ok "field present: $f (empty = first release)"
        else bad "field missing: $f"; fi
    elif [ -n "$v" ]; then ok "field present: $f = $v"
    else bad "field missing or empty: $f"; fi
done
# Backward compatibility: the existing consumer contract must survive.
for f in latest artifact sha256 source; do
    grep -q "^$f:" "$M" && ok "legacy field kept: $f" || bad "legacy field LOST: $f"
done
grep -q "^capabilities:" "$M" && ok "legacy field kept: capabilities" || bad "legacy field LOST: capabilities"

R1=$(field "$M" released); C1=$(field "$M" src_commit)
cp "$M" "$SB/manifest-run1.yaml"

# ---------------------------------------------------------------- run two ----
# Idempotent re-run: same VERSION, untouched src. released/src_commit must STICK.
echo
echo "--- idempotent re-run (same VERSION, unchanged src)"
sleep 1   # ensure a wall-clock second elapses, so a non-sticky value would differ
run_release
R2=$(field "$M" released); C2=$(field "$M" src_commit)
[ "$R1" = "$R2" ] && ok "released is sticky across re-run ($R1)" \
                  || bad "released MOVED on a re-run: $R1 -> $R2"
[ "$C1" = "$C2" ] && ok "src_commit is sticky across re-run" \
                  || bad "src_commit MOVED on a re-run: $C1 -> $C2"
if diff -q "$SB/manifest-run1.yaml" "$M" >/dev/null; then
    ok "whole manifest byte-identical across re-run (the header's claim holds)"
else
    bad "manifest differs across re-run — header claims idempotence it does not have"
    diff "$SB/manifest-run1.yaml" "$M" | head -6
fi

# TEETH for the stickiness leg. If `released` were wall-clock every run, the leg
# above would be the only thing standing between us and a manifest that churns.
# Prove the leg can fail: strip the reuse block from a copy and re-run with it.
echo
echo "--- teeth (a non-sticky script must turn the stickiness leg RED)"
python3 - "$SB/scripts/release-designer.sh" "$SB/scripts/mutant.sh" <<'PY'
import sys
src = open(sys.argv[1]).read()
start = src.find('RELEASED=""')
end   = src.find('[ -n "$RELEASED" ]')
if start == -1 or end == -1:
    sys.stderr.write("MUTATION FAILED: reuse block not found\n"); sys.exit(4)
open(sys.argv[2], 'w').write(src[:start] + 'RELEASED=""\nSRC_COMMIT=""\n' + src[end:])
PY
if [ $? -ne 0 ]; then
    bad "teeth: could not build the mutant — stickiness leg is uncertified"
elif ! bash -n "$SB/scripts/mutant.sh" 2>/dev/null; then
    bad "teeth: mutant has a syntax error — cannot certify the leg"
else
    ok "teeth: mutant parses (any failure below is behavioural)"
    sleep 1
    (cd "$SB" && RELEASE_SKIP_RENDER_CHECK=1 bash scripts/mutant.sh) >/dev/null 2>&1
    R3=$(field "$M" released)
    [ "$R3" != "$R1" ] && ok "teeth: non-sticky script DOES move released ($R1 -> $R3) — leg has bite" \
                       || bad "teeth: mutant produced the same timestamp; leg would pass on a churning script"
    # restore the good manifest state for the chain leg below
    (cd "$SB" && RELEASE_SKIP_RENDER_CHECK=1 bash scripts/release-designer.sh) >/dev/null 2>&1
fi

# -------------------------------------------------------------- real cut ----
# A genuine new version: released must MOVE and supersedes must name the previous.
echo
echo "--- real cut (0.2.0, changed src)"
PREV_R=$(field "$M" released)
printf '<html><body>v-two</body></html>\n' > "$SB/src/aef-workflow-designer.html"
printf '0.2.0\n' > "$SB/VERSION"
git -C "$SB" add -A >/dev/null 2>&1
git -C "$SB" -c user.email=p@p -c user.name=probe commit -qm "probe v2" >/dev/null 2>&1
sleep 1
run_release
[ "$(field "$M" version)" = "0.2.0" ] && ok "version tracks the new cut" || bad "version did not advance"
[ "$(field "$M" released)" != "$PREV_R" ] && ok "released MOVED on a real cut" \
                                          || bad "released did NOT move on a real cut — it is frozen, not sticky"
[ "$(field "$M" supersedes)" = "0.1.0" ] && ok "supersedes names the previous release present in dist/" \
                                         || bad "supersedes = '$(field "$M" supersedes)' (expected 0.1.0)"

echo
echo "PASS=$PASS FAIL=$FAIL"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${PASS:-0} + ${FAIL:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$FAIL" -eq 0 ] || exit 1
exit 0
