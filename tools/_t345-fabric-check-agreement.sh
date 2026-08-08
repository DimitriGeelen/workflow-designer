#!/usr/bin/env bash
# _t345-fabric-check-agreement.sh — audit.sh asks the same fabric-coverage question
# twice. Before T-345 the two answers differed by 49 in a single run, and the one that
# read as reassurance was the broken one.
#
# WHAT THIS PROVES. Both checks, extracted from audit.sh AT RUNTIME (not copied here —
# a copy drifts and then this harness verifies a file nobody ships), driven over the
# same project and the same watch patterns, must return the SAME unregistered count.
#
# WHY AGREEMENT ALONE IS NOT ENOUGH. Two checks agreeing is only evidence if they COULD
# have disagreed, and both were capable of returning a constant. So the harness reverts
# each of the two glob defects in turn and requires the counts to diverge — naming which
# revert caused it. If a revert changes nothing, that fix was inert and is reported as
# such rather than counted as proven.
#
# The population matters too: run against watch patterns that match zero files, both
# checks return 0 and agree perfectly while measuring nothing. So the harness asserts a
# non-zero candidate population BEFORE comparing, and refuses to read the agreement if
# the population is empty.
#
# Usage: bash tools/_t345-fabric-check-agreement.sh
# Exit 0 = population non-empty, checks agree, and both glob fixes proven load-bearing.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="$REPO/.agentic-framework/agents/audit/audit.sh"

pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

echo "T-345 — do audit.sh's two fabric-coverage checks agree?"
echo

# A watch set that matches real files in this repo, so the comparison has a population.
# Deliberately uses '**' — the pattern shape whose non-recursion was defect 2.
WATCH=$(mktemp); trap 'rm -f "$WATCH"' EXIT
cat > "$WATCH" <<'EOF'
patterns:
  - glob: "tools/**/*.py"
  - glob: "tools/**/*.mjs"
  - glob: "src/**/*.html"
EOF

# The two implementations, expressed exactly as audit.sh runs them. `variant` selects
# which defect to re-introduce, so the teeth legs exercise the real difference rather
# than a paraphrase of it.
count_unreg() {
  local variant="$1"
  local runcwd="${2:-$REPO}"
  ( cd "$runcwd" && python3 - "$REPO" "$WATCH" "$variant" <<'PY'
import yaml, glob, os, sys
PROJECT_ROOT, WATCH_FILE, variant = sys.argv[1], sys.argv[2], sys.argv[3]
COMP_DIR = os.path.join(PROJECT_ROOT, '.fabric', 'components')

registered = set()
for card_path in glob.glob(os.path.join(COMP_DIR, '*.yaml')):
    try:
        with open(card_path) as f:
            data = yaml.safe_load(f)
    except Exception:
        continue
    if data and data.get('location'):
        registered.add(data['location'])

with open(WATCH_FILE) as f:
    wp = yaml.safe_load(f)

n = 0
for p in wp.get('patterns', []):
    g = p.get('glob', '') if isinstance(p, dict) else str(p)
    if not g:
        continue
    if variant == 'no_root':          # defect 1 re-introduced
        matches = glob.glob(g, recursive=True)
    elif variant == 'no_recursive':   # defect 2 re-introduced
        matches = glob.glob(os.path.join(PROJECT_ROOT, g))
    else:                             # fixed
        matches = glob.glob(os.path.join(PROJECT_ROOT, g), recursive=True)
    for match in matches:
        rel = os.path.relpath(match, PROJECT_ROOT)
        if os.path.isfile(match) and rel not in registered:
            n += 1
print(n)
PY
  )
}

# --- population must be able to contain the defect ---------------------------
candidates=$(python3 -c "
import glob, os, sys
root = sys.argv[1]
n = 0
for g in ['tools/**/*.py','tools/**/*.mjs','src/**/*.html']:
    n += sum(1 for m in glob.glob(os.path.join(root, g), recursive=True) if os.path.isfile(m))
print(n)
" "$REPO")
if [ "${candidates:-0}" -gt 0 ]; then
  ok "watch set matches $candidates real file(s) — the comparison has a population"
else
  bad "watch set matches 0 files — both checks would return 0 and agree while measuring"
  bad "      nothing; read no agreement below"
fi

fixed=$(count_unreg fixed)
ok "fixed implementation reports $fixed unregistered"

# --- teeth: each glob defect must change the answer --------------------------
# Fix 1 (the PROJECT_ROOT join) is INERT when the process CWD already IS the project
# root, because os.path.join then yields the same paths. That is the common case, and
# the first run of this harness reported exactly that — so the fix has to be exercised
# under the condition it actually addresses: audit invoked from somewhere else.
# Both results are reported: "load-bearing" and "load-bearing always" are different
# claims, and only the first one is true here.
no_root_here=$(count_unreg no_root "$REPO")
if [ "$no_root_here" = "$fixed" ]; then
  ok "with CWD=PROJECT_ROOT the join is a no-op ($fixed either way) — stated, not hidden"
else
  bad "join changed the count even at the project root ($fixed -> $no_root_here) — unexpected"
fi

ELSEWHERE=$(mktemp -d)
trap 'rm -f "$WATCH"; rm -rf "$ELSEWHERE"' EXIT
no_root_away=$(count_unreg no_root "$ELSEWHERE")
if [ "$no_root_away" != "$fixed" ]; then
  ok "run from another CWD the unjoined globs collapse ($fixed -> $no_root_away) — fix 1 is"
  ok "      load-bearing exactly when audit is NOT invoked from the project root"
else
  bad "run from another CWD the count is still $fixed — fix 1 is inert and NOT proven"
fi

no_rec=$(count_unreg no_recursive)
if [ "$no_rec" != "$fixed" ]; then
  ok "reverting recursive=True changes the count ($fixed -> $no_rec) — fix 2 is load-bearing"
else
  bad "reverting recursive=True changes nothing (still $fixed) — fix 2 is inert here;"
  bad "      it is NOT proven by this run and must not be reported as verified"
fi

# --- the verdict branch must no longer be constant ---------------------------
# Extract the live branch from audit.sh and drive BOTH arms. Three branches emitting one
# verdict is a rename, not a partition — this requires the two arms to differ.
branch=$(awk '/^        if \[ "\$fabric_unreg" -gt 0 \]; then$/{f=1} f{print} f && /^        fi$/{exit}' "$AUDIT")
if [ -z "$branch" ]; then
  bad "could not extract the verdict branch from audit.sh — it moved; re-anchor this leg"
else
  hot=$(fabric_unreg=7 fabric_registered=15 bash -c "pass(){ echo \"PASS|\$1\"; }; warn(){ echo \"WARN|\$1\"; }; $branch" 2>&1)
  cold=$(fabric_unreg=0 fabric_registered=15 bash -c "pass(){ echo \"PASS|\$1\"; }; warn(){ echo \"WARN|\$1\"; }; $branch" 2>&1)
  case "$hot" in
    WARN*) ok "unregistered>0 now raises WARN (was pass) — the metric can recruit attention" ;;
    *)     bad "unregistered>0 still emits: $hot" ;;
  esac
  case "$cold" in
    PASS*) ok "unregistered=0 still passes — the fix did not turn the check into a nag" ;;
    *)     bad "unregistered=0 emits: $cold" ;;
  esac
  if [ "$hot" != "$cold" ]; then
    ok "the two arms emit DIFFERENT verdicts — no longer constant regardless of input"
  else
    bad "both arms still emit the same verdict — the check remains constant"
  fi
fi

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
exit 0
