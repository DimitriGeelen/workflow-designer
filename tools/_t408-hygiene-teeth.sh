#!/usr/bin/env bash
# _t408-hygiene-teeth.sh — prove verification-hygiene.py's ratchet has teeth (T-408 AC5).
#
# Every leg names its OWN condition. A leg that asserts only "rc != 0" banks syntax errors
# and typos as proof that the property holds — three times on this arc already (T-338 leg
# (d), T-343 leg (d), T-348 leg (c)), and once on T-399 where my own fix failed the teeth
# because the test tree, not the fix, was wrong.
#
# The subject runs against a SYNTHETIC tree in $TMP, never the real .tasks/. The tool
# resolves ROOT from its own directory, so a copy at $TMP/tools/ scans $TMP/.tasks/.
# Pointing it at the real tree would make the mutation cases edit live task files.
#
# CONTROL and RECIPROC are why a red in a mutation case means anything:
#   CONTROL  the unmutated synthetic tree passes -> a later red is the mutation, not the tree
#   RECIPROC a NEW, legitimately-clean task file passes -> the guard fires on carriers,
#            not merely on "a file the baseline has never seen". No mutation case can
#            cover this direction: they all prove the guard CAN go red.
set -uo pipefail   # deliberately NOT -e: run every leg, report all failures

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJECT="${SUBJECT:-$ROOT/tools/verification-hygiene.py}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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

# A task file with the given ## Verification body.
mk() { # mk <dir> <name> <verification-body>
  mkdir -p "$TMP/.tasks/$1"
  cat > "$TMP/.tasks/$1/$2.md" <<EOF
---
id: ${2%%-*}
name: "synthetic $2"
status: started-work
---

# $2

## Acceptance Criteria
- [x] synthetic

## Verification

# a comment line, skipped
$3

## Updates
EOF
}

build_tree() {
  rm -rf "$TMP/.tasks" "$TMP/tools"
  mkdir -p "$TMP/tools"
  cp "$SUBJECT" "$TMP/tools/verification-hygiene.py"
  # Two grandfathered carriers, one of each shape. TWO, not one, so a case that removes
  # one still leaves the baseline non-empty and the vacuity guard is not what fires.
  mk active    "T-901-legacy-diff"  'diff -q src/aef-workflow-designer.html build/gallery/designer.html'
  mk completed "T-902-legacy-port"  'curl -sf http://localhost:8834/api/health'
  # Clean members, so the population is not 100% carriers.
  mk active    "T-903-clean"        'python3 -c "import sys; sys.exit(0)"'
  mk completed "T-904-clean"        'test -f README.md'
}

adopt() { python3 "$TMP/tools/verification-hygiene.py" --adopt >/dev/null 2>&1; }
run()   { python3 "$TMP/tools/verification-hygiene.py" 2>&1; }

echo "=== T-408 hygiene teeth (subject: ${SUBJECT#$ROOT/}) ==="

# --- CONTROL -----------------------------------------------------------------
build_tree; adopt
out="$(run)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "CONTROL: the unmutated synthetic tree must pass, else every red below is the tree. rc=$rc
$out"
else
  case "$out" in
    *"no carrier outside the 2-file baseline"*) ok "CONTROL  clean tree passes, baseline = 2 files" ;;
    *) fail "CONTROL: passed, but not for the stated reason (expected a 2-file baseline):
$out" ;;
  esac
fi

# --- (a) new hard-coded port in a file the baseline never saw ----------------
build_tree; adopt
mk active "T-905-new-port" 'curl -sf http://127.0.0.1:3001/health'
out="$(run)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(a) a NEW port carrier must exit 1, got rc=$rc
$out"
elif ! echo "$out" | grep -q "T-905-new-port"; then
  fail "(a) exited 1 but never named T-905-new-port — it went red about something else
$out"
elif ! echo "$out" | grep -q "hardcoded-port"; then
  fail "(a) named the file but not the carrier KIND (hardcoded-port)
$out"
else
  ok "(a) new hard-coded port -> rc=1, names T-905-new-port as hardcoded-port"
fi

# --- (b) new serve-root diff in a file the baseline never saw ----------------
build_tree; adopt
mk active "T-906-new-diff" 'diff -q src/aef-workflow-designer.html build/gallery/designer.html'
out="$(run)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(b) a NEW serve-root diff must exit 1, got rc=$rc
$out"
elif ! echo "$out" | grep -q "T-906-new-diff"; then
  fail "(b) exited 1 but never named T-906-new-diff
$out"
elif ! echo "$out" | grep -q "serve-root-diff"; then
  fail "(b) named the file but not the carrier KIND (serve-root-diff)
$out"
else
  ok "(b) new serve-root diff -> rc=1, names T-906-new-diff as serve-root-diff"
fi

# --- (b2) a new carrier LINE inside a GRANDFATHERED file ---------------------
# The reason the baseline is keyed on line-hash and not on per-file counts: a file that
# is already excused for one line must not become a free slot for a different one.
build_tree; adopt
mk active "T-901-legacy-diff" 'diff -q src/aef-workflow-designer.html build/gallery/designer.html
curl -sf http://127.0.0.1:9999/health'
out="$(run)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(b2) a NEW line in a grandfathered file must exit 1 (per-file excuse is not a slot), got rc=$rc
$out"
elif ! echo "$out" | grep -q "9999"; then
  fail "(b2) exited 1 but did not quote the offending new line
$out"
else
  ok "(b2) new carrier line inside a grandfathered file -> rc=1, quotes the line"
fi

# --- (c) baseline entry whose file is gone -----------------------------------
# Stated outcome is a STANDING NOTICE at rc=0, not a red: removing a carrier must never
# be punished. The notice is what stops a cleaned file re-acquiring one silently.
build_tree; adopt
rm -f "$TMP/.tasks/active/T-901-legacy-diff.md"
out="$(run)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(c) removing a carrier must NOT fail the scan, got rc=$rc
$out"
elif ! echo "$out" | grep -q "RATCHET AVAILABLE"; then
  fail "(c) exited 0 but issued no standing notice — the slot would stay open silently
$out"
elif ! echo "$out" | grep -q "T-901-legacy-diff"; then
  fail "(c) issued the notice but did not name the file whose entry is stale
$out"
else
  ok "(c) removed carrier -> rc=0 with a standing RATCHET AVAILABLE notice naming the file"
fi

# --- (c2) --tighten turns the ratchet one way only ---------------------------
build_tree; adopt
rm -f "$TMP/.tasks/active/T-901-legacy-diff.md"
python3 "$TMP/tools/verification-hygiene.py" --tighten >/dev/null 2>&1
mk active "T-901-legacy-diff" 'diff -q src/aef-workflow-designer.html build/gallery/designer.html'
out="$(run)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(c2) after --tighten, re-acquiring the dropped carrier must exit 1, got rc=$rc
$out"
else
  ok "(c2) after --tighten a cleaned file cannot re-acquire its carrier -> rc=1"
fi

# --- (d) empty population ----------------------------------------------------
build_tree; adopt
rm -rf "$TMP/.tasks"
out="$(run)"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(d) an empty population must exit 2 (vacuity), got rc=$rc — a clean verdict over
     nothing would otherwise read exactly like a clean tree
$out"
elif ! echo "$out" | grep -q "VACUOUS"; then
  fail "(d) exited 2 but not for the stated vacuity reason
$out"
else
  ok "(d) empty population -> rc=2 VACUOUS, not a silent pass"
fi

# --- (e) empty baseline ------------------------------------------------------
build_tree; adopt
python3 - "$TMP/tools/verification-hygiene-baseline.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d["carriers"]={}
json.dump(d,open(p,"w"),indent=1)
PY
out="$(run)"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(e) an empty baseline must exit 2, got rc=$rc"
elif ! echo "$out" | grep -q "VACUOUS"; then
  fail "(e) exited 2 but not for the stated vacuity reason
$out"
else
  ok "(e) empty baseline -> rc=2 VACUOUS"
fi

# --- (g) work-completed MOVES the task file: active/ -> completed/ -----------
# T-409. The baseline was keyed on relpath, so this move made a grandfathered carrier
# look like a brand-new one at an unseen path — a red naming a task nobody edited, fired
# exactly when the operator finally acted on G-015. All three remaining active carriers
# (T-093, T-102, T-105) were queued for this move.
build_tree; adopt
mv "$TMP/.tasks/active/T-901-legacy-diff.md" "$TMP/.tasks/completed/T-901-legacy-diff.md"
out="$(run)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(g) completing a grandfathered task must NOT go red — the carrier moved with the
     file, it is the same task. rc=$rc
$out"
elif echo "$out" | grep -q "RATCHET AVAILABLE"; then
  fail "(g) exited 0 but issued a stale notice for a file that merely MOVED — that notice
     would invite --tighten, which would then drop a still-present carrier from the baseline
$out"
else
  ok "(g) grandfathered carrier survives the active/ -> completed/ move -> rc=0, no notice"
fi

# --- (g2) basename collision across the two directories ----------------------
# The one way basename keying could launder a carrier: same basename both sides.
build_tree; adopt
cp "$TMP/.tasks/active/T-903-clean.md" "$TMP/.tasks/completed/T-903-clean.md"
out="$(run)"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(g2) a basename present in BOTH directories must exit 2 — one file's exemption
     would otherwise cover the other's carrier. got rc=$rc
$out"
elif ! echo "$out" | grep -q "COLLISION"; then
  fail "(g2) exited 2 but not for the stated collision reason
$out"
else
  ok "(g2) basename in both active/ and completed/ -> rc=2 COLLISION, not silent laundering"
fi

# --- RECIPROCAL CONTROL ------------------------------------------------------
# The direction no mutation case can reach. Every case above proves the guard CAN go red;
# only this proves it is not simply red about "a file the baseline has never seen".
build_tree; adopt
mk active "T-907-brand-new-clean" 'python3 tools/verification-hygiene.py
test -f README.md'
out="$(run)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "RECIPROC: a brand-new task file with NO carrier must pass. Exiting 1 here means the
     guard fires on novelty, not on carriers — it would tax every new task. rc=$rc
$out"
else
  ok "RECIPROC brand-new clean task file passes -> guard keys on carriers, not novelty"
fi

# --- (f) the two tools agree on what a carrier is ----------------------------
# _t350-verification-hygiene.py carries its own copy of these regexes. If they drift, one
# tool excuses what the other flags and the baseline stops meaning anything.
#
# Compared by BEHAVIOUR, not by scraping regexes out of the source. The first version of
# this leg did scrape, failed to recover the patterns, and reported itself vacuous — which
# is the leg working, but a source-shaped agreement check would keep breaking on
# reformatting while saying nothing about what the tools actually do.
T350="$ROOT/tools/_t350-verification-hygiene.py"
if [ ! -f "$T350" ]; then
  fail "(f) _t350-verification-hygiene.py is missing — the agreement cannot be checked"
else
  build_tree; adopt
  cp "$T350" "$TMP/tools/"
  drift=0; checked=0
  # T-901 carries a diff, T-902 a port, T-903 nothing. T-350's tool is per-task and exits
  # non-zero on a carrier; ours lists carrier files. They must agree on all three.
  for probe in "T-901:carrier" "T-902:carrier" "T-903:clean"; do
    id="${probe%%:*}"; want="${probe##*:}"
    python3 "$TMP/tools/_t350-verification-hygiene.py" "$id" >/dev/null 2>&1
    t350_rc=$?
    if python3 "$TMP/tools/verification-hygiene.py" --adopt 2>/dev/null | grep -q .; then :; fi
    ours=$(python3 - "$TMP/tools/verification-hygiene-baseline.json" "$id" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); tid=sys.argv[2]
print("carrier" if any(tid in k for k in d.get("carriers",{})) else "clean")
PY
)
    checked=$((checked + 1))
    t350=$([ "$t350_rc" -ne 0 ] && echo carrier || echo clean)
    if [ "$t350" != "$want" ]; then
      fail "(f) T-350's tool calls $id '$t350', expected '$want' — the probe tree is wrong,
     so any agreement below would be agreement about nothing"
      drift=1
    elif [ "$ours" != "$want" ]; then
      fail "(f) our tool calls $id '$ours', T-350's calls it '$t350' — one excuses what the
     other flags, and the baseline stops meaning anything"
      drift=1
    fi
  done
  if [ "$checked" -ne 3 ]; then
    fail "(f) checked $checked probes, expected 3 — agreement over a short population"
  elif [ "$drift" -eq 0 ]; then
    ok "(f) both tools classify all 3 probe tasks identically (2 carrier, 1 clean)"
  fi
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
echo "TEETH PASS — 12/12 legs (control + 8 mutations + reciprocal + agreement)"
