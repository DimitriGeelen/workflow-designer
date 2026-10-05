#!/usr/bin/env bash
# =============================================================================
#  T-1049 — UPGRADE THE FRAMEWORK: AEF 1.7.740 -> 1.8.2, THROUGH THE RE-VENDOR PROTOCOL
#  Run with:   bash /opt/832-Workflow-designer/runme.sh
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh --dry-run
# =============================================================================
#
#  WHY NOW: AEF released 1.8.2 today. It brings the crontab-path fix (1.8.1), the fix for
#  the hourly reindex job that could fill the disk (T-3860), and the inbox fix that stops
#  delivery receipts counting as unread mail (T-3792/T-3840).
#
#  WHAT IT DOES (each step asks y/N first; nothing is pushed):
#    1. fw upgrade from a fresh clone of the v1.8.2 tag (pinned by commit, not "latest").
#       Our 50 local files under .agentic-framework/ are kept by .fwvendor-preserve.yaml.
#       This also rewrites CLAUDE.md's framework sections, .claude/settings.json hooks and
#       the git hooks; then this script puts our re-vendor gate back into pre-commit.
#    2. PRISTINE COMMIT: .agentic-framework/ exactly as the upgrade wrote it, nothing else.
#       NOTE: last time this commit's post-commit hook ran ~10 minutes (T-1004, still open).
#       The commit has landed while it runs; let it finish.
#    3. BASELINE ADVANCE: .vendor-divergence.yaml points at that commit, committed alone.
#    4. CRON: checks the installed crontab points at the vendored framework (not the temp
#       clone); if not, offers `fw cron install` to rewrite it.
#  Afterwards the agent re-applies each of our local fixes the upgrade overwrote (they show
#  by name), and reviews CLAUDE.md / settings.json before committing them.
#  The agent ran --dry-run only.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TAG=v1.8.2
TAG_SHA=ddf8672005f846a1328ebcf802b338d46951dcd4
URL=https://github.com/DimitriGeelen/agentic-engineering-framework.git
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-1049 started $TS  log: $LOG"
. "$PROJ/tools/runme-signal.sh"; runme_signal_init "T-1049 AEF 1.8.2 upgrade" "$LOG"

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
SRC=$(mktemp -d /tmp/t1049-aef182.XXXXXX)
# runme_signal_init's EXIT trap, plus removing the temp clone
trap '_rc=$?; rm -rf "$SRC"; if [ "$_rc" = 0 ]; then runme_signal done "rc=0"; else runme_signal STOPPED "rc=$_rc"; fi' EXIT
fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
cd "$PROJ" || fail "project dir missing"
VF=.agentic-framework/VERSION
DIV=.agentic-framework/.vendor-divergence.yaml
CRON=/etc/cron.d/agentic-audit-832-workflow-designer

# --- preflight: nothing in the project is written before all of these pass ---
pgrep -f "fw upgrade /opt/832-Workflow-designer" >/dev/null && fail "another fw upgrade is running"
[ "$(git rev-parse --abbrev-ref HEAD)" = "bleeding-edge" ] || fail "not on bleeding-edge"
echo "ok  on bleeding-edge"
[ -z "$(git diff --cached --name-only)" ] || fail "something is already staged; unstage it first (git restore --staged .)"
echo "ok  nothing staged"
git diff --quiet -- .agentic-framework || fail "uncommitted edits under .agentic-framework/; the pristine commit would absorb them"
echo "ok  no uncommitted edits under .agentic-framework/"
bash tools/_t1000-install-hook.sh --check >/dev/null || fail "the re-vendor gate is not installed (bash tools/_t1000-install-hook.sh)"
echo "ok  re-vendor gate installed in .git/hooks/pre-commit"
v_head=$(git show "HEAD:$VF" | tr -d '[:space:]'); v_tree=$(tr -d '[:space:]' < "$VF")
[ "$v_head" = "1.7.740" ] && [ "$v_tree" = "1.7.740" ] || fail "expected framework 1.7.740 in HEAD and tree, found $v_head / $v_tree"
echo "ok  framework now $v_tree"
git ls-files --error-unmatch .fwvendor-preserve.yaml >/dev/null 2>&1 && git diff --quiet -- .fwvendor-preserve.yaml \
  || fail ".fwvendor-preserve.yaml is not committed as-is"
echo "ok  .fwvendor-preserve.yaml committed ($(grep -c '^  - ' .fwvendor-preserve.yaml) local files kept)"
echo "..  cloning $TAG"
# Full history, not --depth 1: 1.8.2 refuses a source that does not contain our recorded
# version_sha (foreign-source guard), and a shallow clone does not.
git -c advice.detachedHead=false clone -q --branch "$TAG" "$URL" "$SRC/fw" || fail "could not clone $TAG"
git -C "$SRC/fw" cat-file -e "$(sed -n 's/^version_sha: *//p' .framework.yaml)^{commit}" 2>/dev/null \
  || fail "the $TAG clone does not contain our recorded version_sha; the upgrade would refuse"
[ "$(git -C "$SRC/fw" rev-parse HEAD)" = "$TAG_SHA" ] || fail "$TAG now points at $(git -C "$SRC/fw" rev-parse HEAD), not the commit this script was checked against ($TAG_SHA)"
[ "$(tr -d '[:space:]' < "$SRC/fw/VERSION")" = "1.8.2" ] || fail "clone VERSION is not 1.8.2"
echo "ok  clone is $TAG at ${TAG_SHA:0:9}, VERSION 1.8.2"
up() { (cd "$SRC/fw" && env -u PROJECT_ROOT FRAMEWORK_ROOT="$SRC/fw" bin/fw upgrade "$PROJ" "$@"); }
up --dry-run > "$SRC/dry.txt" 2>&1 || { tail -20 "$SRC/dry.txt"; fail "fw upgrade --dry-run failed"; }
grep -q "DELETED" "$SRC/dry.txt" && { grep DELETED "$SRC/dry.txt"; fail "the upgrade would delete local files not in .fwvendor-preserve.yaml"; }
echo "ok  upgrade dry-run: $(grep -c PRESERVE "$SRC/dry.txt") local files preserved, 0 deleted; $(grep -o '[0-9]* change(s) would be made' "$SRC/dry.txt")"

echo
echo "WILL RUN:"
echo "  1. fw upgrade from $TAG (writes .agentic-framework/, CLAUDE.md, .claude/, git hooks, .framework.yaml, cron)"
echo "     then put the re-vendor gate back into .git/hooks/pre-commit"
echo "  2. commit .agentic-framework/ only, except $DIV and runtime files (pristine commit)"
echo "  3. set baseline_commit in $DIV to that commit; commit it alone"
echo "  4. check $CRON points at the vendored framework; offer fw cron install if not"
echo "  Not pushed. CLAUDE.md / .claude/ / .framework.yaml stay uncommitted for the agent to review."
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing in the project written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
runme_confirm "Step 1/4: run fw upgrade to $TAG now?" || fail "not confirmed at step 1; nothing written"
runme_signal step "1/4 fw upgrade"
up || fail "fw upgrade exited non-zero (see above). Nothing committed; git status shows what it wrote"
[ "$(tr -d '[:space:]' < "$VF")" = "1.8.2" ] || fail "after the upgrade $VF is not 1.8.2"
bash tools/_t1000-install-hook.sh >/dev/null && bash tools/_t1000-install-hook.sh --check >/dev/null || fail "could not re-install the re-vendor gate"
echo "ok  framework 1.8.2 in the working tree; re-vendor gate re-installed"

runme_confirm "Step 2/4: create the pristine vendor commit?" || fail "not confirmed at step 2; the upgrade is in the working tree, uncommitted — re-run is not possible from here, tell the agent"
runme_signal step "2/4 pristine commit"
git add -A -- .agentic-framework || fail "git add failed"
git reset -q HEAD -- "$DIV" .agentic-framework/.context/settings.yaml .agentic-framework/.context/sidecar 2>/dev/null
git diff --cached --name-only | grep -v '^\.agentic-framework/' | grep -q . && fail "something outside .agentic-framework/ got staged; nothing committed (git restore --staged . to reset)"
n=$(git diff --cached --name-only | wc -l)
echo "..  committing $n vendored paths (the post-commit hook may run several minutes, T-1004)"
git commit -q -m "T-1049: pristine vendor commit — AEF 1.8.2 as fw upgrade wrote it (re-vendor protocol step 1, T-1000)" \
  -m "Vendored paths only, from tag v1.8.2 ($TAG_SHA). Excluded: .vendor-divergence.yaml (ours, step 2) and runtime state. Local-only files kept by .fwvendor-preserve.yaml." \
  || fail "commit refused (see above); the index still holds the pristine set — inspect, or git restore --staged . to reset"
P=$(git rev-parse HEAD)
echo "ok  pristine commit $(git rev-parse --short HEAD) ($n paths)"

runme_confirm "Step 3/4: advance the divergence baseline to $(git rev-parse --short HEAD)?" || fail "not confirmed at step 3; the gate refuses every other commit until this is done — tell the agent"
runme_signal step "3/4 baseline advance"
python3 - "$DIV" "$P" <<'PY' || fail "could not rewrite baseline_commit"
import re, sys
p, sha = sys.argv[1:]
lines = open(p).read().split("\n")
out, skip = [], False
for ln in lines:                                    # drop the older baseline_note_previous block
    if ln.startswith("baseline_note_previous:"):
        skip = True; continue
    if skip and (ln.startswith(" ") or ln == ""):
        continue
    skip = False
    out.append(ln)
s = "\n".join(out)
s, n = re.subn(r'^baseline_commit:.*$', 'baseline_commit: %s' % sha, s, count=1, flags=re.M)
if n != 1: sys.exit(1)
s, n = re.subn(r'^baseline_note:', 'baseline_note_previous:', s, count=1, flags=re.M)
if n != 1: sys.exit(1)
s = s.replace('baseline_commit: %s' % sha, 'baseline_commit: %s\nbaseline_note: "T-1049/T-1000 — pristine vendor commit of AEF 1.8.2 (re-vendor protocol step 1). Every declared local fix the upgrade overwrote now shows STALE in tools/_t517; resolve each via tools/_t1000-revendor-worklist.py."' % sha, 1)
import yaml; yaml.safe_load(s)                       # refuse to write a file that no longer parses
open(p, "w").write(s)
PY
git add -- "$DIV" && git commit -q -m "T-1049: advance the divergence baseline to the pristine AEF 1.8.2 commit (re-vendor protocol step 2, T-1000)" \
  || fail "baseline commit refused (see above)"
echo "ok  baseline advanced: $(git rev-parse --short HEAD)"

runme_signal step "4/4 cron check"
if grep -q "/tmp/" "$CRON" 2>/dev/null || ! grep -q "$PROJ/.agentic-framework/bin/fw" "$CRON" 2>/dev/null; then
    echo "!!  $CRON does not point at the vendored framework:"; grep -n "/tmp/" "$CRON" | head -3
    if runme_confirm "Step 4/4: rewrite the crontab with the vendored fw (fw cron install)?"; then
        .agentic-framework/bin/fw cron install || fail "fw cron install failed"
        grep -q "/tmp/" "$CRON" && fail "crontab still has /tmp/ paths after fw cron install"
        echo "ok  crontab rewritten"
    else
        echo "--  crontab left as is (tell the agent)"
    fi
else
    echo "ok  crontab points at the vendored framework ($(grep -c 'agentic-framework/bin/fw' "$CRON") job lines)"
fi
echo
echo "DONE. The agent now re-applies the overwritten local fixes (step 3 of the protocol) and"
echo "reviews CLAUDE.md / .claude/settings.json / .framework.yaml before committing them."
echo "rc=0  (log: $LOG)"
