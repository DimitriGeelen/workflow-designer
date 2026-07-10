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

mkdir -p "$DIST"
cp "$SRC" "$ARTIFACT"

# Byte-identical guarantee: the released artifact IS the source at this version.
if ! diff -q "$SRC" "$ARTIFACT" >/dev/null; then
  echo "ERROR: released artifact differs from source" >&2
  exit 1
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
EOF

echo "Released designer $VERSION"
echo "  artifact: dist/aef-workflow-designer-$VERSION.html"
echo "  sha256:   $SHA"
echo "  bytes:    $BYTES"
