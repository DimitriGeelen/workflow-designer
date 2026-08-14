#!/usr/bin/env bash
# _t497-census-controls.sh — prove the derived-root census SEPARATES guarded from
# unguarded, instead of merely producing a number.
#
# T-497. A census that has never been shown to change its verdict is a belief.
#
# WHY THE FIXTURES ARE PLANTED IN tools/ AND NOT IN A SCRATCHPAD
# --------------------------------------------------------------
# The census derives its root from its own location and globs `tools/**`. A fixture in
# /tmp is outside every glob, so the census would score it "absent" — indistinguishable
# from "correctly not flagged". That is the exact class this whole line of work is
# about (T-494, T-495 x2, T-496, AEF rail 617), and _t429-zero-leg-probe.sh wrote the
# same rule down on 2026-08-11 before any of them. Fixtures therefore sit beside the
# real files and are removed on exit, including on abort.
#
# THEY ARE NOT DOT-NAMED, AND THAT COST A RUN.
# The first draft copied _t429's dot-name convention. `glob.glob('tools/**/*.sh')` does
# NOT match dotfiles, so the census could not see either fixture: control A reported
# CLEAR (the fixture was absent, not clean) and control B passed for the wrong reason,
# because EVERYTHING was clear. A control invisible to the instrument it is testing
# reports on nothing and says PASS. Same shape as T-495, where the probe's own
# `-probe.py` name was excused by the census's one-shot convention.
#
# EXIT  0 all controls behaved   1 a control did not discriminate   2 cannot answer
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

CENSUS="tools/_t497-derived-root-census.py"
[ -f "$CENSUS" ] || { echo "CANNOT ANSWER: no census at $CENSUS"; exit 2; }

UNGUARDED="tools/_t497-ctl-unguarded-$$.sh"
GUARDED="tools/_t497-ctl-guarded-$$.sh"
trap 'rm -f "$UNGUARDED" "$GUARDED"' EXIT INT TERM

pass=0; fail=0
check() {  # check <label> <expected: FLAGGED|CLEAR> <path>
  local label="$1" want="$2" path="$3" got
  if python3 "$CENSUS" --json | python3 -c "
import json,sys
d=json.load(sys.stdin)
sys.exit(0 if '$path' in d['unverified_paths'] else 1)"; then
    got=FLAGGED
  else
    got=CLEAR
  fi
  if [ "$got" = "$want" ]; then
    echo "  PASS  $label — $got"
    pass=$((pass + 1))
  else
    echo "  FAIL  $label — wanted $want, got $got"
    fail=$((fail + 1))
  fi
}

# ---- control A: derives a root, resolves a subject beneath it, NEVER checks it ----
cat > "$UNGUARDED" <<'EOF'
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/tools/validate-workflow.py" --help
EOF

# ---- control B: identical, but tests the composed subject before using it ----
cat > "$GUARDED" <<'EOF'
#!/usr/bin/env bash
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJ="$ROOT/tools/validate-workflow.py"
[ -f "$SUBJ" ] || { echo "missing: $SUBJ" >&2; exit 2; }
python3 "$SUBJ" --help
EOF

echo "== T-497 census controls =="
check "A: derives + resolves + no check" FLAGGED "$UNGUARDED"
check "B: same, with [ -f \"\$SUBJ\" ]"   CLEAR   "$GUARDED"

# ---- control C: the cd-guard must NOT be credited as subject verification ----
# `cd "$(dirname "$0")/.." || exit 2` guards the one step that cannot fail. If the
# census ever counts it as a check, this control goes CLEAR and the suite goes red.
cat > "$UNGUARDED" <<'EOF'
#!/usr/bin/env bash
cd "$(dirname "$0")/.." || exit 2
python3 tools/validate-workflow.py --help
EOF
check "C: cd-guard is NOT subject verification" FLAGGED "$UNGUARDED"

echo "  pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
# A run that asserted nothing must not report success (T-429: 35 of 35 suites did).
[ "$pass" -eq 3 ] || { echo "  ABSTAIN: expected 3 controls, ran $pass"; exit 2; }
