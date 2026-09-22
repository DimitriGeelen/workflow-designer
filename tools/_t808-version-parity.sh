#!/usr/bin/env bash
# _t808-version-parity.sh — APP_VERSION in src/ MUST equal ./VERSION.
#
# T-808, value review finding F-10. The designer now renders its own build number in the
# header. That string is a literal inside src/aef-workflow-designer.html rather than a
# build-time substitution, because release-designer.sh asserts `diff -q SRC ARTIFACT` and
# AEF pins the resulting sha256 — substituting at build time would break the byte-identity
# contract for the sake of a header string.
#
# A literal is only safe if something mechanical keeps it honest. That is this file.
#
# T-399 rejected a version constant in src on exactly the grounds this guard answers: a
# second copy of VERSION "kept in step with the real one by good intentions". This is not
# good intentions. release-designer.sh runs this BEFORE it writes anything to dist/, so a
# drifted version is refused rather than shipped and noticed later.
#
# COULD-NOT-MEASURE IS NOT A PASS (the L-381 family, and _t389's rule #2). If APP_VERSION
# cannot be found at all, this FAILS. A guard that silently passes when its subject has
# been renamed or deleted is worse than no guard, because the release keeps reporting green
# while the thing it guarded is gone.
#
# Exit: 0 they agree | 1 they disagree, or either value could not be read

set -uo pipefail

REPO_ROOT="${T808_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$REPO_ROOT/src/aef-workflow-designer.html"
VERSION_FILE="$REPO_ROOT/VERSION"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

[ -f "$SRC" ]          || fail "source not found: $SRC"
[ -f "$VERSION_FILE" ] || fail "VERSION file not found: $VERSION_FILE"

FILE_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
[ -n "$FILE_VERSION" ] || fail "VERSION file is empty — nothing to compare against"

# Anchored to the declaration, not to a bare version-shaped string: src is ~997 KB of
# markup and script and contains plenty of other dotted triples (see the T-361 and T-399
# comment blocks, which quote released versions in prose). Matching loosely here would
# make the guard assert on whichever number happened to appear first.
APP_VERSION="$(sed -n "s/^const APP_VERSION = '\([^']*\)';.*/\1/p" "$SRC" | head -1)"

if [ -z "$APP_VERSION" ]; then
    fail "APP_VERSION declaration not found in $SRC.
      Looked for a line of the form:  const APP_VERSION = 'X.Y.Z';
      If the constant was renamed or removed, this guard is now blind and the header
      version can drift unnoticed — that is a failure, not a pass. Fix the constant or
      retire this guard deliberately."
fi

COUNT="$(grep -c "^const APP_VERSION = " "$SRC")"
if [ "$COUNT" -ne 1 ]; then
    fail "expected exactly 1 APP_VERSION declaration in src, found $COUNT.
      The point of the constant is that there is only one. Two declarations means the
      second can drift from VERSION while this guard reads the first and reports green."
fi

if [ "$APP_VERSION" != "$FILE_VERSION" ]; then
    cat >&2 <<MSG
FAIL: version drift — the header would lie about which build is on screen.

  ./VERSION                    $FILE_VERSION
  APP_VERSION in src/          $APP_VERSION

  These must agree. The designer renders APP_VERSION in its header, and F-10 exists
  because a product that cannot state its own build let a four-release delivery gap go
  unnoticed for weeks. A wrong version is worse than none: it answers the question
  confidently and incorrectly.

  Fix: set both to the version being released.
    cd $REPO_ROOT && echo "$FILE_VERSION" > VERSION
    and edit APP_VERSION in src/aef-workflow-designer.html to match.
MSG
    exit 1
fi

echo "ok: APP_VERSION and VERSION agree ($FILE_VERSION)"
exit 0
