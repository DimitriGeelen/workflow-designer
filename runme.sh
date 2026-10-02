#!/usr/bin/env bash
# =============================================================================
#  T-988 via T-1000 — LAND THE AEF 1.7.740 UPGRADE THROUGH THE RE-VENDOR PROTOCOL (steps 1-2)
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHY: re-vendoring silently erased local fixes twice (T-995). The protocol you chose (option A,
#  docs/reports/T-1000-revendor-gate.md) makes every erased fix visible by name:
#    1. PRISTINE COMMIT  the upgrade as `fw upgrade` wrote it, vendored paths only.
#    2. BASELINE ADVANCE .vendor-divergence.yaml baseline_commit := that commit, committed alone.
#    (3. the agent then runs the worklist and re-applies each lost fix in its own commit.)
#  The pre-commit gate (tools/_t1000-revendor-gate.sh) enforces 1 and 2.
#
#  WHAT IS DELIBERATELY NOT PRISTINE, and how it is handled:
#    - .agentic-framework/.vendor-divergence.yaml  ours: kept OUT of step 1, committed in step 2
#    - .agentic-framework/lib/inception.sh         the T-996 block is REMOVED from what step 1
#      stages (the working tree keeps it); it comes back in step 3 from the worklist
#    - policy/designer-pin.yaml, vendor/designer/  T-988's own designer pull (local-config): go
#      in as they are; the pin will show as a false STALE in step 3 and is resolved "present"
#  Nothing outside .agentic-framework/ is touched or committed (the gate refuses it anyway).
#  Nothing is pushed. The agent ran --dry-run only.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-988/T-1000 started $TS  log: $LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
confirm() { local a; read -r -p "$1 [y/N] " a </dev/tty || a=n; [ "$a" = y ] || [ "$a" = Y ]; }
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
cd "$PROJ" || fail "project dir missing"
VF=.agentic-framework/VERSION
DIV=.agentic-framework/.vendor-divergence.yaml
INC=.agentic-framework/lib/inception.sh

# --- preflight: nothing is written before all of these pass ---
[ "$(git rev-parse --abbrev-ref HEAD)" = "bleeding-edge" ] || fail "not on bleeding-edge"
echo "ok  on bleeding-edge"
[ -z "$(git diff --cached --name-only)" ] || fail "something is already staged; unstage it first (git restore --staged .)"
echo "ok  nothing staged"
bash tools/_t1000-install-hook.sh --check >/dev/null || fail "the re-vendor gate is not installed (bash tools/_t1000-install-hook.sh)"
echo "ok  re-vendor gate installed in .git/hooks/pre-commit"
v_head=$(git show "HEAD:$VF" | tr -d '[:space:]'); v_tree=$(tr -d '[:space:]' < "$VF")
[ "$v_head" = "1.7.68" ] && [ "$v_tree" = "1.7.740" ] || fail "expected HEAD 1.7.68 and working tree 1.7.740, found $v_head / $v_tree"
echo "ok  upgrade present: framework $v_head (HEAD) -> $v_tree (working tree)"
n_mod=$(git status --porcelain -uall -- .agentic-framework | grep -v "^?? \|$DIV" | wc -l)
n_new=$(git status --porcelain -uall -- .agentic-framework | grep -c "^?? ")
echo "ok  pristine set: $n_mod modified/deleted + $n_new new vendored path(s); $DIV excluded"
# The pristine inception.sh = working tree minus exactly the T-996 block (verified, not assumed).
PRISTINE_INC=$(mktemp)
python3 - "$INC" "$PRISTINE_INC" <<'PY' || fail "could not derive the pristine inception.sh (T-996 block not found exactly once)"
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
a = s.find('    # 832 T-996: the marker is a side effect')
b = s.find('    if [ ! -f "$review_marker" ]; then\n        echo -e "${RED}ERROR: Task review required', a)
if a < 0 or b < 0 or s.count('# 832 T-996: the marker is a side effect') != 1:
    sys.exit(1)
open(dst, 'w').write(s[:a] + s[b:])
PY
grep -q "832 T-996" "$PRISTINE_INC" && fail "T-996 text still present in the derived pristine file"
echo "ok  pristine lib/inception.sh derived: T-996 block removed ($(($(wc -l < "$INC") - $(wc -l < "$PRISTINE_INC"))) lines); the working tree keeps it"

echo
echo "WILL RUN:"
echo "  1. stage .agentic-framework/ (all changes and new files) EXCEPT $DIV; stage the pristine inception.sh;"
echo "     commit 'T-988: pristine vendor commit — AEF $v_tree as fw upgrade wrote it (protocol step 1)'"
echo "  2. set baseline_commit in $DIV to that commit; commit that file alone (protocol step 2)"
echo "  Not pushed. Afterwards the agent runs the worklist (step 3)."
if [ "$DRY" = 1 ]; then rm -f "$PRISTINE_INC"; echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
confirm "Step 1/2: create the pristine vendor commit ($((n_mod + n_new)) paths)?" || { rm -f "$PRISTINE_INC"; fail "not confirmed at step 1; nothing written"; }
git add -A -- .agentic-framework || fail "git add failed"
git reset -q HEAD -- "$DIV" || fail "could not keep $DIV out of the pristine commit"
mode=$(git ls-files -s -- "$INC" | cut -d' ' -f1)
git update-index --cacheinfo "$mode,$(git hash-object -w "$PRISTINE_INC"),$INC" || fail "could not stage the pristine inception.sh"
rm -f "$PRISTINE_INC"
git diff --cached --name-only | grep -v '^\.agentic-framework/' | head -3 | grep -q . && fail "something outside .agentic-framework/ got staged; nothing committed (git restore --staged . to reset)"
git commit -q -m "T-988: pristine vendor commit — AEF $v_tree as fw upgrade wrote it (re-vendor protocol step 1, T-1000)" \
  -m "Vendored paths only. Excluded: .vendor-divergence.yaml (ours, step 2). lib/inception.sh without the T-996 block (re-applied in step 3)." \
  || fail "commit refused (see above); the index still holds the pristine set — inspect, or git restore --staged . to reset"
P=$(git rev-parse HEAD)
echo "ok  pristine commit $(git rev-parse --short HEAD)"

confirm "Step 2/2: advance the divergence baseline to $(git rev-parse --short HEAD)?" || fail "not confirmed at step 2; the gate will refuse every other commit until this is done — re-run this script"
python3 - "$DIV" "$P" "$v_tree" <<'PY' || fail "could not rewrite baseline_commit"
import re, sys
p, sha, ver = sys.argv[1:]
s = open(p).read()
s2, n = re.subn(r'^baseline_commit:.*$', 'baseline_commit: %s' % sha, s, count=1, flags=re.M)
if n != 1:
    sys.exit(1)
s2 = re.sub(r'^baseline_note:', 'baseline_note_previous:', s2, count=1, flags=re.M)
s2 = s2.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-988/T-1000 — pristine vendor commit of AEF %s (re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % (sha, ver), 1)
open(p, 'w').write(s2)
PY
git add -- "$DIV" && git commit -q -m "T-988: advance the divergence baseline to the pristine AEF $v_tree commit (re-vendor protocol step 2, T-1000)" \
  || fail "baseline commit refused (see above)"
echo "ok  baseline advanced: $(git rev-parse --short HEAD)"
echo
echo "DONE: steps 1-2. The agent now runs step 3 (tools/_t1000-revendor-worklist.py) and re-applies each lost fix."
echo "rc=0  (log: $LOG)"
