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

# Content-derived manifest => re-running at the same VERSION yields an identical
# file. dist/ accumulates versioned artifacts; this pointer names the latest and
# its checksum so a consumer (AEF) can pin + verify.
cat > "$MANIFEST" <<EOF
# AEF Workflow Designer — release manifest. Content-derived, deterministic.
# AEF vendors a pinned copy of the artifact named below and verifies its sha256.
# Protocol: docs/aef-designer-integration-protocol.md
latest: "$VERSION"
artifact: "dist/aef-workflow-designer-$VERSION.html"
sha256: "$SHA"
bytes: $BYTES
source: "src/aef-workflow-designer.html"
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
