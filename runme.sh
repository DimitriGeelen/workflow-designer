#!/usr/bin/env bash
# =============================================================================
#  T-993 — CUT RELEASE 0.15.2: the authoring kit revised from the Evergreen trial (K1-K8)
#  Run with:   bash /opt/832-Workflow-designer/runme.sh 0.15.2
#  Dry run:    bash /opt/832-Workflow-designer/runme.sh 0.15.2 --dry-run
# =============================================================================
#
#  WHAT THIS DOES, each step confirmed separately, stopping at the first failure:
#    1. scripts/release-designer.sh: writes dist/aef-workflow-designer-0.15.2.html, the
#       authoring kit dist/aef-authoring-kit-0.15.2/, and MANIFEST.yaml; runs the render gate
#       (ON); announces the release on the hub rail.
#    2. commits exactly those dist/ paths as the release commit.
#    3. creates the annotated tag designer-v0.15.2 on that commit.
#    4. pushes bleeding-edge and the tag to origin.
#  Same pattern as 0.14.0, 0.15.0 and 0.15.1 (tag on the bleeding-edge release commit). master is NOT advanced
#  here; that remains a separate decision. Notes: docs/releases/RELEASE-NOTES-0.15.2.md
#
#  THE VERSION IS YOUR ARGUMENT (G-007): the script refuses without it or if it differs from
#  ./VERSION. THE AGENT DOES NOT RUN THIS: a release is a promise over immutable bytes, a tag
#  and a push are outward, and check-tier0.sh cannot see commands inside a script (OBS-449).
#  The agent ran --dry-run only.
# =============================================================================
[ -z "${BASH_VERSION:-}" ] && exec bash "$0" "$@"
set -uo pipefail

PROJ=/opt/832-Workflow-designer
TS=$(date +%Y%m%dT%H%M%S)
LOG="$PROJ/.context/working/runme-$TS.log"
mkdir -p "$PROJ/.context/working" && touch "$LOG" || { echo "cannot write log $LOG"; exit 1; }
exec > >(tee -a "$LOG") 2>&1
echo "runme.sh T-993 started $TS  log: $LOG"

fail() { echo "STOPPED: $*"; echo "rc=1  (log: $LOG)"; exit 1; }
confirm() { local a; read -r -p "$1 [y/N] " a </dev/tty || a=n; [ "$a" = y ] || [ "$a" = Y ]; }

V="${1:-}"; DRY=0; [ "${2:-}" = "--dry-run" ] && DRY=1
[ -n "$V" ] || fail "pass the version as the first argument, e.g.  bash $0 0.15.2"
cd "$PROJ" || fail "project dir missing"
TAG="designer-v$V"
ART="dist/aef-workflow-designer-$V.html"
KIT="dist/aef-authoring-kit-$V"

# --- preflight: each check says what it proves; nothing is written before all pass ---
[ "$(tr -d '[:space:]' < VERSION)" = "$V" ] || fail "./VERSION is '$(tr -d '[:space:]' < VERSION)', not '$V'"
echo "ok  ./VERSION is $V"
bash tools/_t808-version-parity.sh >/dev/null || fail "APP_VERSION in src does not match VERSION"
echo "ok  APP_VERSION matches VERSION"
[ "$(git rev-parse --abbrev-ref HEAD)" = "bleeding-edge" ] || fail "not on bleeding-edge"
echo "ok  on bleeding-edge"
git diff --quiet HEAD -- VERSION src/aef-workflow-designer.html scripts/release-designer.sh tools/build-authoring-kit.py docs/authoring-kit tools/validate-workflow.py \
  || fail "uncommitted changes in files the release is built from; commit them first"
echo "ok  the release inputs are committed"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && fail "tag $TAG already exists locally"
git ls-remote --exit-code --tags origin "$TAG" >/dev/null 2>&1 && fail "tag $TAG already exists on origin"
echo "ok  tag $TAG does not exist (local or origin)"
# RESUMABLE (T-992, after a 0.15.1 run stopped at step 3): if $V is already cut AND committed AND the
# artifact equals src AND the kit verifies, steps 1-2 are DONE and are skipped without a prompt
# (T-940: a confirm for a no-op teaches that the answer does not matter). A half-written dist/
# (exists but uncommitted, or differing) still refuses: that needs a human look.
CUT_DONE=0
if [ -e "$ART" ] || [ -e "$KIT" ]; then
  { [ -f "$ART" ] && [ -d "$KIT" ]; } || fail "$ART / $KIT only partly present: look before re-running"
  git ls-files --error-unmatch "$ART" >/dev/null 2>&1 && git diff --quiet HEAD -- "$ART" "$KIT" dist/MANIFEST.yaml \
    || fail "$V is in dist/ but not committed cleanly: look before re-running"
  cmp -s src/aef-workflow-designer.html "$ART" || fail "$ART differs from src"
  (cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || fail "$KIT does not verify against its SHA256SUMS"
  CUT_DONE=1
  echo "ok  $V already cut and committed ($(git log -1 --format=%h -- "$ART")): steps 1-2 done, resuming at step 3"
else
  echo "ok  no $V artifact or kit in dist/ yet"
fi

echo
echo "WILL RUN:"
echo "  1. scripts/release-designer.sh          (render gate ON, announce ON)"
echo "  2. git commit $ART $KIT dist/MANIFEST.yaml"
echo "  3. git tag -a $TAG"
echo "  4. git push origin bleeding-edge && git push origin $TAG"
if [ "$DRY" = 1 ]; then echo; echo "DRY RUN: nothing written."; echo "rc=0  (log: $LOG)"; exit 0; fi

echo
if [ "$CUT_DONE" = 0 ]; then
confirm "Step 1/4: cut release $V (writes dist/, announces)?" || fail "not confirmed at step 1; nothing written"
scripts/release-designer.sh || fail "release-designer.sh failed (see above); dist/ may need a look"
{ [ -f "$ART" ] && cmp -s src/aef-workflow-designer.html "$ART"; } || fail "$ART missing or differs from src"
(cd "$KIT" && sha256sum -c SHA256SUMS --quiet) || fail "the kit does not verify against its SHA256SUMS"
echo "ok  artifact == src, kit verifies"

confirm "Step 2/4: commit the release files?" || fail "not confirmed at step 2; dist/ is written but NOT committed"
git add "$ART" "$KIT" dist/MANIFEST.yaml || fail "git add failed"
git commit -q -m "T-993: release designer $V — authoring kit revised from the Evergreen trial (K1-K8, ledger L5-L15)" \
  -m "Notes: docs/releases/RELEASE-NOTES-$V.md" || fail "commit failed"
echo "ok  release commit $(git rev-parse --short HEAD)"
fi
REL=$(git log -1 --format=%H -- "$ART")

SHA=$(sha256sum "$ART" | awk '{print $1}')
confirm "Step 3/4: tag $TAG on the release commit $(git rev-parse --short "$REL")?" || fail "not confirmed at step 3; committed, NOT tagged (re-run this script to resume)"
git tag -a "$TAG" "$REL" -m "designer $V (sha256 $SHA) + authoring kit" || fail "tag failed"
echo "ok  tagged $TAG"

confirm "Step 4/4: push bleeding-edge and $TAG to origin?" || fail "not confirmed at step 4; tagged locally, NOT pushed"
git push origin bleeding-edge || fail "push of bleeding-edge failed"
git push origin "$TAG" || fail "push of $TAG failed"
echo
echo "DONE: release $V cut, committed, tagged $TAG and pushed."
echo "rc=0  (log: $LOG)"
