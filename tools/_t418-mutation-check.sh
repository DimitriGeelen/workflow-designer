#!/usr/bin/env bash
# _t418-mutation-check.sh — the teeth went 10/10 on their first run. That is exactly
# when they are least trustworthy: a leg that has never been observed failing is not
# known to be capable of failing.
#
# T-418. Three mutations, each targeting one distinction the teeth claim to protect.
# For each: the named leg must go RED, and (a)/(b) — the red/green pair that only
# checks the headline verdict — must stay GREEN, or the mutation broke more than the
# rule under test and the leg's redness proves nothing about it.
#
# (T-416 §b: anything a change IMPROVES belongs outside the reciprocal, or the check
# reads its own success as damage. Here (a)/(b) are the reciprocal.)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/tools/_t418-producer-attribution.py"
TEETH="$ROOT/tools/_t418-attribution-teeth.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
legs=0
# T-430: every outcome here is recorded by `fails`, so a run in which no mutation was
# built — an anchor drifting, a heredoc going missing — leaves fails=0 and exits 0, and
# reads exactly like a check in which all three mutations were caught. `legs` counts the
# mutations actually driven. It is incremented INSIDE mutate() because that is the leg
# site; blanking mutate() is then a faithful simulation of "no mutation ran".

mutate() { # mutate <name> <leg-that-must-go-red> <python-anchor-replace-heredoc-file>
  legs=$((legs + 1))
  local name="$1" leg="$2" script="$3"
  local mutant="$TMP/mutant-$name.py"
  if ! python3 "$script" "$SRC" "$mutant"; then
    echo "FAIL: mutation '$name' could not be built — re-anchor it before trusting this check." >&2
    fails=$((fails + 1)); return
  fi
  local out="$TMP/$name.out"
  SUBJECT="$mutant" bash "$TEETH" > "$out" 2>&1
  if grep -q "FAIL: $leg" "$out"; then
    echo "  ok  [$name] leg $leg goes red"
  else
    echo "FAIL: [$name] leg $leg stayed green with the distinction removed." >&2
    fails=$((fails + 1))
  fi
  for keep in "(a)" "(b)"; do
    if grep -q "FAIL: $keep" "$out"; then
      echo "FAIL: [$name] reciprocal leg $keep also went red — the mutation broke more
      than the rule under test, so $leg going red proves nothing about it." >&2
      fails=$((fails + 1))
    fi
  done
}

echo "=== T-418 mutation check ==="

# M1 — collapse AMBIGUOUS and UNATTRIBUTED into one verdict word.
cat > "$TMP/m1.py" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = '''        if len(projects) > 1:
            verdicts.append("AMBIGUOUS")
        if slot["unlabelled"]:
            verdicts.append("UNATTRIBUTED")'''
new = '''        if len(projects) > 1 or slot["unlabelled"]:
            verdicts.append("AMBIGUOUS")
            verdicts.append("UNATTRIBUTED")'''
if src.count(old) != 1:
    print("anchor M1 matched %d times" % src.count(old), file=sys.stderr); sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, new))
PY
mutate m1-merge-verdicts "(d)" "$TMP/m1.py"

# M2 — key on the fingerprint in hand instead of deriving offenders from the data.
cat > "$TMP/m2.py" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = '''    bad = 0
    for sender, slot in by_sender.items():'''
new = '''    bad = 0
    known_collapsed = ("d1993c2c3ec44c94",)
    for sender, slot in by_sender.items():
        if sender in known_collapsed:
            pass'''
if src.count(old) != 1:
    print("anchor M2 matched %d times" % src.count(old), file=sys.stderr); sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, new))
PY
mutate m2-fingerprint-literal "(c)" "$TMP/m2.py"

# M3 — let an empty capture render as a clean bill of health (G-022's exact shape).
cat > "$TMP/m3.py" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = '''        print("REFUSED: capture holds no content envelopes — nothing was measured.",
              file=sys.stderr)
        return 2'''
new = '''        print("ATTRIBUTABLE — nothing to report")
        return 0'''
if src.count(old) != 1:
    print("anchor M3 matched %d times" % src.count(old), file=sys.stderr); sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, new))
PY
mutate m3-empty-passes "(f)" "$TMP/m3.py"

echo
# T-430 abstention guard — before the verdict, or the verdict answers first.
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "MUTATION CHECK FAIL — $fails" >&2
  exit 1
fi
echo "MUTATION CHECK PASS — $legs/3 mutations driven: each distinction has a leg that bites, and only it does"
