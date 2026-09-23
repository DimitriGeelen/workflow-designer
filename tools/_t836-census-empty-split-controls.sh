#!/usr/bin/env bash
# T-836 controls — prove the CARRIER-SHAPE split measures rather than merely prints.
#
# HISTORY THIS FILE EXISTS TO CARRY: the first version of this task asserted that 6 of the
# 30 unreachable values were EMPTY elements. That was false. It was reached by testing text
# and attributes and never testing child elements, so <aef:emits><aef:emit value="pass"/>…
# read as empty. Measured: 0 of 30 are empty; 18 are text, 6 attrs, 6 children. The legs
# below are written against the corrected claim, and Leg 5 exists because of the old one.
#
# All mutation happens on a THROWAWAY ROOT via T810_REPO_ROOT. Leg 7 checksums the real
# corpus before and after to prove the seam artefact AEF pins against was never written.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 3
REPO=$PWD
TOOL=tools/_t810-unreachable-values-census.py
PASS=0; FAIL=0
ok(){ echo "  PASS  $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL  $1"; echo "        $2"; FAIL=$((FAIL+1)); }

TMP=$(mktemp -d) || exit 3
trap 'rm -rf "$TMP"' EXIT
SUM_BEFORE=$(find examples/aef-processes/rendered -name '*.bpmn' -type f -exec sha256sum {} + | sort | sha256sum | cut -d' ' -f1)

mkroot(){
  local R=$1
  mkdir -p "$R/tools" "$R/src" "$R/examples/aef-processes/rendered"
  cp "$REPO/$TOOL" "$R/tools/"
  cp "$REPO/src/aef-workflow-designer.html" "$R/src/"
  cp "$REPO"/examples/aef-processes/rendered/*.bpmn "$R/examples/aef-processes/rendered/"
}
run(){ T810_REPO_ROOT="$1" python3 "$1/tools/$(basename $TOOL)" 2>&1; }
val(){ echo "$1" | sed -n "s/^$2=\([0-9]\+\)$/\1/p" | head -1; }
shapes(){ echo "$(val "$1" UNREACHABLE_CARRIER_TEXT)/$(val "$1" UNREACHABLE_CARRIER_ATTRS)/$(val "$1" UNREACHABLE_CARRIER_CHILDREN)/$(val "$1" UNREACHABLE_EMPTY)"; }

echo "=== T-836 carrier-shape controls (text/attrs/children/empty) ==="

# Leg 1 — baseline on the real repo
B=$(python3 "$TOOL" 2>&1); SB=$(shapes "$B")
[ "$SB" = "18/6/6/0" ] && ok "baseline 18 text / 6 attrs / 6 children / 0 empty" \
  || no "baseline" "got $SB, want 18/6/6/0"

# Leg 2 — throwaway root is faithful (the harness is not the variable)
R0=$TMP/r0; mkroot "$R0"; S0=$(shapes "$(run "$R0")")
[ "$S0" = "18/6/6/0" ] && ok "throwaway root reproduces the baseline" \
  || no "throwaway fidelity" "got $S0 on an unmutated copy — the harness moved the number"

# Leg 3 — a CHILDREN carrier converted to text must move text up and children down
R1=$TMP/r1; mkroot "$R1"
python3 - "$R1" <<'PY'
import sys,glob,re
root=sys.argv[1]
pat=re.compile(r'<aef:emits>.*?</aef:emits>', re.S)
for f in sorted(glob.glob(root+'/examples/aef-processes/rendered/*.bpmn')):
    s=open(f,encoding='utf-8').read()
    m=pat.search(s)
    if m:
        open(f,'w',encoding='utf-8').write(s[:m.start()]+'<aef:emits>T836_TEXT</aef:emits>'+s[m.end():])
        print("MUTATED"); break
else: print("NO_TARGET")
PY
S1=$(shapes "$(run "$R1")")
[ "$S1" = "19/6/5/0" ] && ok "children->text moves the split (18/6/6 -> 19/6/5)" \
  || no "children carrier" "got $S1, want 19/6/5/0 — the child branch is not load-bearing"

# Leg 4 — an ATTRS carrier stripped of attributes must fall to EMPTY.
# This is also the only leg that proves EMPTY can be non-zero at all: the real corpus has
# zero empties, so without a mutation the empty branch is never exercised and a dead
# branch would be indistinguishable from an honest zero (PL-307).
R2=$TMP/r2; mkroot "$R2"
python3 - "$R2" <<'PY'
import sys,glob,re
root=sys.argv[1]
pat=re.compile(r'<aef:timer\b[^>]*?/>')
for f in sorted(glob.glob(root+'/examples/aef-processes/rendered/*.bpmn')):
    s=open(f,encoding='utf-8').read()
    m=pat.search(s)
    if m:
        open(f,'w',encoding='utf-8').write(s[:m.start()]+'<aef:timer/>'+s[m.end():])
        print("MUTATED"); break
else: print("NO_TARGET")
PY
S2=$(shapes "$(run "$R2")")
[ "$S2" = "18/5/6/1" ] && ok "attrs->none falls to EMPTY (18/5/6/1) — empty branch proven live" \
  || no "attrs carrier / empty reachability" "got $S2, want 18/5/6/1"

# Leg 5 — the regression this task's own false premise came from.
# emits must NEVER be classified EMPTY on the untouched corpus.
if echo "$B" | grep -qE '^  emits .* carrier: children$'; then
  ok "emits classified by its real carrier (children), not as empty"
else
  no "emits classification" "emits is not reported as a children carrier — the original false premise is back"
fi

# Leg 6 — prose parity: every line printed before T-836 still prints, byte for byte
git show HEAD:"$TOOL" > "$TMP/old.py" 2>/dev/null
if [ -s "$TMP/old.py" ]; then
  R3=$TMP/r3; mkroot "$R3"; cp "$TMP/old.py" "$R3/tools/$(basename $TOOL)"
  MISSING=$(comm -23 <(run "$R3" | sort) <(run "$R0" | sort))
  [ -z "$MISSING" ] && ok "prose parity: every pre-T-836 line still printed verbatim" \
    || no "prose parity" "lines lost: $(printf '%s' "$MISSING" | head -3 | tr '\n' '|')"
else
  no "prose parity" "could not retrieve HEAD:$TOOL — refusing to pass vacuously"
fi

# Leg 7 — negative control: the harness can report a failure
[ "$SB" = "999/999/999/999" ] && no "negative control" "a deliberately false assertion PASSED" \
  || ok "negative control: a false assertion is reported, not skipped"

# Leg 8 — the real corpus was never written
SUM_AFTER=$(find examples/aef-processes/rendered -name '*.bpmn' -type f -exec sha256sum {} + | sort | sha256sum | cut -d' ' -f1)
[ "$SUM_BEFORE" = "$SUM_AFTER" ] && ok "real corpus unmodified by this run" \
  || no "corpus immutability" "the seam artefact AEF pins against CHANGED during a control run"

echo
echo "controls: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
