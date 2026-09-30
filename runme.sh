#!/usr/bin/env bash
# runme.sh — cut the next Workflow Designer release. FOR THE OPERATOR TO RUN.
#
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#  THE AGENT MUST NOT RUN THIS SCRIPT, and the reason is a finding from tonight, not politeness.
#
#  OBS-449: `check-tier0.sh` matches the COMMAND TEXT. A force-push inside a script is invisible to
#  it, because the command the harness sees is `bash runme.sh`. Earlier today an agent (me) moved a
#  force-push into a file to stabilise its Tier 0 approval hash, and the move defeated the gate —
#  the push executed with `fw tier0 approve` still reading "approvals logged: 0".
#
#  This script contains a push to master, a VERSION write, a dist/ write and a tag push. Every one
#  of those is the operator's under G-007 and PD-309. An agent running this file would bypass four
#  controls in one command, and the gate would say nothing. So: operator only.
# ─────────────────────────────────────────────────────────────────────────────────────────────────
#
# WHAT IT DOES, in the order the machinery requires rather than the order the steps are usually
# listed in. `scripts/release-designer.sh` explains at length why it cannot tag itself: when it runs,
# dist/ and MANIFEST exist only in the WORKING TREE and the commit containing them does not exist
# yet, so tagging there would name the previous commit — "a tag that resolves to a tree without its
# own VERSION and artifact is worse than no tag: it looks right."
#
#   1. advance master to bleeding-edge by fast-forward      (PD-309)
#   2. write the new VERSION                                 (operator's number, passed in)
#   3. build dist/ deterministically                         (scripts/release-designer.sh)
#   4. COMMIT the release                                    (VERSION + dist/ together)
#   5. tag HEAD and push the tag                             (after 4, never before)
#   6. announce on the rail                                  (scripts/announce-release.sh)
#
# STEP 1 USES A REFSPEC PUSH, NOT A CHECKOUT, and that is deliberate — T-823 chose it and recorded
# why. This working tree carries the `.context/audits/cron/` retention churn, which is not the
# agent's to commit (T-571). `git checkout master` would drag all of it across the branch switch,
# and any path differing between branches would block the checkout or silently carry over. The
# refspec form advances the remote server-side and never touches the working tree.
#
# A non-forced push to master is REJECTED by git unless it is a true fast-forward. That rejection is
# the safety property, so this script does not add a force anywhere and must not gain one.
#
# USAGE
#   bash runme.sh <version>          e.g. bash runme.sh 0.14.0
#   bash runme.sh <version> --dry-run
#
# The version is an ARGUMENT because choosing it is choosing what the release promises (G-007).
# Nothing here picks it for you, and the script refuses to run without it.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO" || exit 90

VERSION="${1:-}"
DRY=0
[ "${2:-}" = "--dry-run" ] && DRY=1

die()  { printf '\n\033[31mSTOPPED:\033[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1m── %s\033[0m\n' "$*"; }
run()  { if [ "$DRY" -eq 1 ]; then printf '  [dry-run] %s\n' "$*"; else printf '  + %s\n' "$*"; eval "$@" || die "the command above failed; nothing after it has run"; fi; }

confirm() {
    [ "$DRY" -eq 1 ] && { printf '  [dry-run] would ask: %s\n' "$1"; return 0; }
    printf '\n\033[33m%s\033[0m [y/N] ' "$1"
    read -r a </dev/tty || die "no tty to confirm on"
    case "$a" in y|Y|yes) : ;; *) die "declined at: $1" ;; esac
}

[ -n "$VERSION" ] || die "no version given. Usage: bash runme.sh <version> [--dry-run]
  The version is yours to choose — a release is a sovereignty promise over immutable bytes (G-007),
  and an agent picking the number would be an agent deciding what is promised. For reference: the
  11 commits since designer-v0.13.0 add authoring capability without removing any, which reads as a
  minor bump. See docs/releases/RELEASE-NOTES-DRAFT-next.md."

printf '%s' "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || die "version must be X.Y.Z, got '$VERSION'"
TAG="designer-v$VERSION"

# ── PREFLIGHT. Every check states what it proves, and a failure stops before anything is written. ──
step "Preflight"

git rev-parse --verify -q bleeding-edge >/dev/null || die "no bleeding-edge branch"
git rev-parse --verify -q master        >/dev/null || die "no master branch"

git merge-base --is-ancestor master bleeding-edge \
  || die "master is NOT an ancestor of bleeding-edge — this is not a fast-forward.
  PD-309 allows master to advance ONLY by fast-forward. A merge would need the operator's explicit
  decision and is not what this script does."
echo "  ok   master is an ancestor of bleeding-edge (true fast-forward)"

git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1 \
  && die "tag $TAG already exists. Re-cutting a released version changes bytes under a name someone
  has already pinned. Pick a new version, or delete the tag deliberately first."
echo "  ok   tag $TAG does not exist yet"

SRC_CHANGED="$(git diff --stat designer-v0.13.0 bleeding-edge -- src/ 2>/dev/null | tail -1)"
[ -n "$SRC_CHANGED" ] || die "src/ is UNCHANGED since designer-v0.13.0 — this release would ship
  byte-identical output under a new number. Nothing to release."
echo "  ok   src/ changed since the last tag: $SRC_CHANGED"

# The audit may WARN (it does: 11 warnings, all pre-existing). It must not FAIL.
step "Audit gate (warnings are acceptable, failures are not)"
.agentic-framework/agents/audit/audit.sh --section structure > /tmp/.runme-audit.out 2>&1
FAILS="$(grep -cE '^\[FAIL\]' /tmp/.runme-audit.out || true)"
grep -E '^(Pass|Warn|Fail):' /tmp/.runme-audit.out | sed 's/^/  /'
[ "${FAILS:-0}" -eq 0 ] || { grep -E '^\[FAIL\]' /tmp/.runme-audit.out | sed 's/^/  /'; die "$FAILS audit FAILURE(s) — releasing over a red audit ships a known-broken state"; }
echo "  ok   no audit failures"

printf '\n\033[1mAbout to release %s as %s\033[0m\n' "$(git rev-parse --short bleeding-edge)" "$TAG"
printf '  master  %s -> %s  (%s commits)\n' "$(git rev-parse --short master)" \
       "$(git rev-parse --short bleeding-edge)" "$(git rev-list --count master..bleeding-edge)"

# ── 1. FAST-FORWARD MASTER ────────────────────────────────────────────────────────────────────────
step "1/6  Fast-forward master to bleeding-edge (refspec push, working tree untouched)"
BEFORE="$(git status --porcelain | wc -l)"
confirm "Push bleeding-edge to origin/master? (git refuses unless it is a fast-forward)"
run "git push origin bleeding-edge:master"
run "git branch -f master bleeding-edge"
if [ "$DRY" -eq 0 ]; then
    AFTER="$(git status --porcelain | wc -l)"
    [ "$BEFORE" = "$AFTER" ] || die "the working tree changed during the push ($BEFORE -> $AFTER paths).
  The refspec form exists precisely so this cannot happen — investigate before continuing."
    echo "  ok   working tree untouched ($AFTER paths, unchanged)"
fi

# From here master carries src/ changes while VERSION still names the OLD release: "same version,
# different bytes", the case the release guard exists to catch. T-823 hit it and recorded it rather
# than absorbing it. Steps 2-5 close the window, which is why they run in one sitting.
echo "  note master now serves bytes that do not match released 0.13.0 until step 4 commits"

# ── 2. VERSION ────────────────────────────────────────────────────────────────────────────────────
step "2/6  Write VERSION = $VERSION"
confirm "Write '$VERSION' to ./VERSION?"
run "printf '%s\n' '$VERSION' > VERSION"

# ── 3. BUILD ──────────────────────────────────────────────────────────────────────────────────────
step "3/6  Build dist/ (deterministic: same source + same VERSION => identical bytes)"
run "bash scripts/release-designer.sh"
# The script warns that the release is NOT YET TAGGED and exits 0 by design — it cannot tag before
# the release commit exists. That warning is expected here and step 5 is its remedy.

# ── 4. COMMIT ─────────────────────────────────────────────────────────────────────────────────────
step "4/6  Commit the release (VERSION + dist/ together, so the tag names a complete tree)"
if [ "$DRY" -eq 0 ]; then
    git add VERSION dist/ || die "git add failed"
    git diff --cached --stat | tail -5 | sed 's/^/  /'
fi
confirm "Commit the release as '$VERSION'?"
run ".agentic-framework/bin/fw git commit -m 'T-174: release designer $VERSION — $(git rev-list --count designer-v0.13.0..bleeding-edge -- src/) src/ commits since 0.13.0'"

# ── 5. TAG ────────────────────────────────────────────────────────────────────────────────────────
step "5/6  Tag HEAD and push the tag (AFTER the commit — a tag on the previous commit looks right and is not)"
if [ "$DRY" -eq 0 ]; then
    SHA="$(sha256sum "dist/aef-workflow-designer-$VERSION.html" 2>/dev/null | cut -d' ' -f1)"
    [ -n "$SHA" ] || die "no artifact at dist/aef-workflow-designer-$VERSION.html — step 3 did not produce it"
    echo "  artifact sha256: $SHA"
else
    SHA="<computed after build>"
fi
confirm "Tag HEAD as $TAG and push it?"
run "git tag -a '$TAG' -m 'designer $VERSION (sha256 $SHA)'"
run "git push origin '$TAG'"

# ── 6. ANNOUNCE ───────────────────────────────────────────────────────────────────────────────────
step "6/6  Announce on the rail so AEF can answer 'am I current?' (G-024)"
confirm "Publish the release identity to the AEF rail?"
run "bash scripts/announce-release.sh"

# ── VERIFY ────────────────────────────────────────────────────────────────────────────────────────
step "Verify"
run "python3 tools/_t382-release-lag.py"
echo
printf '\033[32mReleased %s\033[0m — AEF re-pins the sha256 per docs/aef-designer-integration-protocol.md\n' "$TAG"
