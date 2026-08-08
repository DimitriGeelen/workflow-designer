#!/usr/bin/env bash
# release-designer.sh — cut a versioned, pinnable single-file build of the
# Workflow Designer for AEF to vendor.
#
# T-174 (arc: designer-authoring-surface). 832 is the source of truth; AEF
# vendors a *pinned copy* of the versioned artifact this produces (T-173 GO,
# mechanism M3 + `fw designer`). See docs/aef-designer-integration-protocol.md
# for the pull (re-pin) and upstream-improvement protocol.
#
# Deterministic: same source + same VERSION => byte-identical artifact and
# manifest on every run (no timestamps; manifest is content-derived only).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/src/aef-workflow-designer.html"
DIST="$REPO_ROOT/dist"
VERSION_FILE="$REPO_ROOT/VERSION"

[ -f "$SRC" ]          || { echo "ERROR: source not found: $SRC" >&2; exit 1; }
[ -f "$VERSION_FILE" ] || { echo "ERROR: VERSION file not found: $VERSION_FILE" >&2; exit 1; }

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
[ -n "$VERSION" ] || { echo "ERROR: VERSION is empty" >&2; exit 1; }

ARTIFACT="$DIST/aef-workflow-designer-$VERSION.html"
MANIFEST="$DIST/MANIFEST.yaml"

# Release immutability guard (T-198, G-007). A release is a promise: version X
# means these exact bytes, forever. AEF vendors a pinned copy of a dist/ artifact
# and verifies its sha256 (protocol: docs/aef-designer-integration-protocol.md),
# so rewriting an already-released version in place breaks a consumer's pin with
# NO local signal — the checks below this point can't catch it, because they all
# verify internal self-consistency (artifact==src, manifest==artifact) rather
# than immutability against what was already published.
#
# Fires BEFORE any write (no mkdir, no cp, no manifest), so a refused release
# leaves dist/ byte-identical to its prior state. An unchanged re-cut is NOT a
# mutation and stays green — determinism is this script's contract. Fail-closed;
# the only bypass is explicit and loudly warned, never silent.
if [ -f "$ARTIFACT" ] && ! cmp -s "$SRC" "$ARTIFACT"; then
  RELEASED_SHA="$(sha256sum "$ARTIFACT" | awk '{print $1}')"
  SRC_SHA="$(sha256sum "$SRC" | awk '{print $1}')"
  if [ "${RELEASE_ALLOW_OVERWRITE:-0}" = "1" ]; then
    echo "WARNING: RELEASE_ALLOW_OVERWRITE=1 — deliberately re-cutting an ALREADY-RELEASED version." >&2
    echo "WARNING:   version:      $VERSION" >&2
    echo "WARNING:   released sha: $RELEASED_SHA" >&2
    echo "WARNING:   new sha:      $SRC_SHA" >&2
    echo "WARNING: any consumer pinned to the released sha will now FAIL verification." >&2
  else
    cat >&2 <<MSG
ERROR: refusing to overwrite an already-released version.

  version:      $VERSION
  artifact:     dist/aef-workflow-designer-$VERSION.html
  released sha: $RELEASED_SHA
  current src:  $SRC_SHA

  Version $VERSION is already released and may be pinned by a consumer (AEF
  vendors dist/ artifacts and verifies them by sha256). Rewriting it in place
  would silently break that pin. A version denotes fixed bytes, or it denotes
  nothing.

  Cutting a NEW release? Bump VERSION, then re-run:
    cd $REPO_ROOT && echo "0.3.0" > VERSION && scripts/release-designer.sh

  Re-cutting THIS version on purpose (nothing has pinned it yet)?
    cd $REPO_ROOT && RELEASE_ALLOW_OVERWRITE=1 scripts/release-designer.sh
MSG
    exit 1
  fi
fi

mkdir -p "$DIST"
cp "$SRC" "$ARTIFACT"

# Byte-identical guarantee: the released artifact IS the source at this version.
if ! diff -q "$SRC" "$ARTIFACT" >/dev/null; then
  echo "ERROR: released artifact differs from source" >&2
  exit 1
fi

# Render gate (T-180, arc: designer-authoring-surface). A byte-identical copy can
# still be a broken or stale build — sha256 proves bytes, not that the artifact
# renders or still carries the governance fields. Run the dynamic render-check
# against the freshly built artifact BEFORE writing the manifest, so a failed
# gate never leaves a manifest pointing at a bad build. Fail-closed; the only
# bypass (browser-less envs) is an explicit, loudly-warned opt-out — never silent.
RENDER_TEST="$REPO_ROOT/tests/test_designer_render.py"
if [ "${RELEASE_SKIP_RENDER_CHECK:-0}" = "1" ]; then
  echo "WARNING: RELEASE_SKIP_RENDER_CHECK=1 — render gate SKIPPED; artifact NOT verified to render." >&2
elif [ -f "$RENDER_TEST" ]; then
  echo "Render gate: python3 tests/test_designer_render.py"
  if ! python3 "$RENDER_TEST"; then
    echo "ERROR: render gate FAILED — built artifact did not render / lost governance fields." >&2
    echo "       release aborted (no manifest written). Fix src, or in a browser-less env" >&2
    echo "       re-run with RELEASE_SKIP_RENDER_CHECK=1 (bypass is logged to stderr)." >&2
    exit 1
  fi
else
  echo "WARNING: render test not found ($RENDER_TEST) — render gate skipped." >&2
fi

SHA="$(sha256sum "$ARTIFACT" | awk '{print $1}')"
BYTES="$(wc -c < "$ARTIFACT" | tr -d '[:space:]')"

# T-387 — the four consumer-facing fields AEF asked for at rail 464. They exist so
# AEF can compute BOTH lags from its own seat instead of asking us: `released` gives
# the age of what they hold, `src_commit` lets them measure build lag against our src
# themselves, `supersedes` turns "behind" into a countable chain so "1 behind" and
# "skipped 4" stop being the same number.
#
# DETERMINISM. The header used to claim, unqualified, that re-running at the same
# VERSION yields an identical file. A wall-clock timestamp would have made that false.
# Rather than drop the guarantee or fake the timestamp, re-running at an unchanged
# VERSION with a byte-identical artifact PRESERVES the existing released/src_commit:
# the release happened once, and re-running this script is not a re-cut. Idempotence
# is kept honestly instead of by leaving the timestamp out.
RELEASED=""
SRC_COMMIT=""
if [ -f "$MANIFEST" ]; then
  _prev_version="$(sed -n 's/^latest: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
  _prev_sha="$(sed -n 's/^sha256: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
  if [ "$_prev_version" = "$VERSION" ] && [ "$_prev_sha" = "$SHA" ]; then
    RELEASED="$(sed -n 's/^released: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
    SRC_COMMIT="$(sed -n 's/^src_commit: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
  fi
fi
[ -n "$RELEASED" ] || RELEASED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
[ -n "$SRC_COMMIT" ] || SRC_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"

# `supersedes` is read from what is actually PRESENT in dist/, not from a
# hand-maintained list: a curated chain drifts from what shipped, and the whole
# point of the field is to be countable against reality. Empty for the first release.
# The `|| true` is load-bearing under `set -euo pipefail`: on a FIRST release the
# grep filters out the only entry, exits 1, and takes the whole script down before
# the manifest is written. Found by running the probe, not by reading this line —
# the failure mode is "no manifest and no error message", which reads exactly like
# a silent success from anywhere upstream.
SUPERSEDES="$( { ls "$DIST"/aef-workflow-designer-*.html 2>/dev/null \
  | sed 's/.*aef-workflow-designer-\(.*\)\.html/\1/' \
  | grep -v "^$VERSION\$" \
  | sort -V | tail -1; } || true )"

# dist/ accumulates versioned artifacts; this pointer names the latest and its
# checksum so a consumer (AEF) can pin + verify. NOTE for the consumer half of
# G-024: this file lives at a STABLE path and is overwritten at every cut — it is
# not shipped inside any versioned artifact, so it can answer "is there something
# newer?" provided it is FETCHED rather than vendored. A vendored copy of this file
# reports the state at the time it was copied, which is the failure it exists to fix.
cat > "$MANIFEST" <<EOF
# AEF Workflow Designer — release manifest. Content-derived and idempotent:
# re-running at an unchanged VERSION with a byte-identical artifact reproduces
# this file exactly, including released/src_commit (T-387).
# AEF vendors a pinned copy of the artifact named below and verifies its sha256.
# Protocol: docs/aef-designer-integration-protocol.md
latest: "$VERSION"
artifact: "dist/aef-workflow-designer-$VERSION.html"
sha256: "$SHA"
bytes: $BYTES
source: "src/aef-workflow-designer.html"
# T-387 (AEF rail 464): consumer-facing release identity. None derived from the others.
#   released   — ISO8601 UTC, when this artifact was CUT
#   src_commit — the commit it was built from
#   supersedes — the previous version present in dist/ ("" for the first release)
version: "$VERSION"
released: "$RELEASED"
src_commit: "$SRC_COMMIT"
supersedes: "$SUPERSEDES"
# T-258/T-246: structured capability flags — a consumer (AEF) self-configures
# conditional behaviour at re-pin by reading these instead of sniffing bytes.
# annotation_seam: postMessage aef:ready/aef:annotate read-only badge layer
# (contract: docs/aef-designer-integration-protocol.md §Annotation seam).
capabilities:
  annotation_seam: 1
EOF

echo "Released designer $VERSION"
echo "  artifact: dist/aef-workflow-designer-$VERSION.html"
echo "  sha256:   $SHA"
echo "  bytes:    $BYTES"

# Announce to the rail (T-389, G-024 consumer half). A cut nobody can learn about
# is the gap itself: AEF re-reported a defect fixed 9 days earlier because nothing
# readable told them a newer build existed.
#
# NON-FATAL BY DESIGN, LOUD BY REQUIREMENT. The artifact is the deliverable and it
# is already on disk and verified; a hub that happens to be down must not roll that
# back or fail the cut. But an announce that fails QUIETLY is strictly worse than
# one that fails loudly — AEF's consumer check would keep reporting "current" from a
# stale rail, which is the false-green direction they called unacceptable. So the
# script always states which of the two happened, and names the standalone recovery
# command. `|| ANNOUNCE_RC=$?` is required under `set -e`.
ANNOUNCE_RC=0
if [ "${RELEASE_SKIP_ANNOUNCE:-0}" = "1" ]; then
  echo "  announce: SKIPPED (RELEASE_SKIP_ANNOUNCE=1) — rail still advertises the PREVIOUS release." >&2
else
  "$REPO_ROOT/scripts/announce-release.sh" || ANNOUNCE_RC=$?
  if [ "$ANNOUNCE_RC" -ne 0 ]; then
    echo "WARNING: release $VERSION is CUT but NOT ANNOUNCED (announce exited $ANNOUNCE_RC)." >&2
    echo "WARNING: the rail still advertises the previous release, so a consumer checking" >&2
    echo "WARNING: currency will be told it is up to date when it is not." >&2
    echo "WARNING: re-run the announce alone once the hub is reachable — no re-cut needed:" >&2
    echo "WARNING:   cd $REPO_ROOT && scripts/announce-release.sh" >&2
  fi
fi

# Final line is the one a caller greps. It must never be ambiguous about the announce.
if [ "$ANNOUNCE_RC" -eq 0 ] && [ "${RELEASE_SKIP_ANNOUNCE:-0}" != "1" ]; then
  echo "Release $VERSION: CUT and ANNOUNCED"
else
  echo "Release $VERSION: CUT but NOT ANNOUNCED"
fi
