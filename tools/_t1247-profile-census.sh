#!/usr/bin/env bash
# T-1247 census: every tools/*.mjs that starts Chrome with --user-data-dir must make that dir with the shared helper
# (tools/_cdp-profile.mjs makeProfileDir), so the profile is removed on signals and swept after a SIGKILL.
# Lists each offender; exit 1 if any, 0 if none.
set -u
ROOT="${T1247_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
bad=0; n=0
for f in "$ROOT"/tools/*.mjs; do
  [ "$(basename "$f")" = "_cdp-profile.mjs" ] && continue
  command grep -q -- 'user-data-dir=' "$f" || continue
  n=$((n + 1))
  if ! command grep -q "from './_cdp-profile.mjs'" "$f" || command grep -Eq 'udd *= *mkdtempSync' "$f"; then
    echo "NO HELPER: ${f#$ROOT/}"; bad=$((bad + 1))
  fi
done
echo "profile census: $n harness(es) start Chrome with --user-data-dir, $bad without the T-1247 helper"
[ "$bad" -eq 0 ]
