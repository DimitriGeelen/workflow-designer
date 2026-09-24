#!/usr/bin/env bash
# seam-manifest.sh — compute the seam artefact state (file list + sha256 per
# file) of examples/aef-processes/rendered/ at an arbitrary git ref.
#
# T-807 (arc: designer-authoring-surface). AEF's second ask following the
# branch-model adoption (T-805, `agent-chat-arc @1656`): "tag the seam
# artefacts in your release notes so we pin a tag, not a moving head." Under
# the release train (docs/branch-model.md) AEF pins a `designer-v*` tag, not
# `master`'s moving head — but nothing recorded what seam bytes a given tag
# actually carried.
#
# READ-ONLY BY DESIGN. This script never writes to the working tree, `dist/`,
# `VERSION`, or `examples/aef-processes/rendered/` itself — it only reads git
# objects via `git ls-tree` / `git show <ref>:<path>`, which works identically
# for the current worktree, an old tag, or any other ref, without checking
# anything out. That is also what makes it answer for the 16 EXISTING
# `designer-v*` tags, not only the next one: the record was always in git's
# object store, this just makes it queryable by tag name instead of requiring
# ad hoc archaeology.
#
# OUTPUT is deterministic YAML: same ref -> same bytes, always (content
# hashes only, no timestamps). Safe to diff or concatenate into
# docs/releases/seam-manifest.md.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEAM_DIR="examples/aef-processes/rendered"

REF="${1:-}"
if [ -z "$REF" ]; then
  echo "Usage: $0 <tag-or-ref>" >&2
  echo "  Computes the seam manifest (file list + sha256) for" >&2
  echo "  $SEAM_DIR at the given git ref." >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" rev-parse -q --verify "${REF}^{commit}" >/dev/null 2>&1; then
  echo "ERROR: '$REF' does not resolve to a commit in this repo." >&2
  exit 1
fi

RESOLVED_COMMIT="$(git -C "$REPO_ROOT" rev-parse "${REF}^{commit}")"

# `git ls-tree -r --name-only` lists files at the ref without checking
# anything out. Sorted for determinism (tree order is usually stable but not
# guaranteed to match `sort` byte-order across git versions).
mapfile -t FILES < <(git -C "$REPO_ROOT" ls-tree -r --name-only "$REF" -- "$SEAM_DIR" 2>/dev/null | sort)

echo "ref: \"$REF\""
echo "commit: \"$RESOLVED_COMMIT\""
echo "seam_dir: \"$SEAM_DIR\""
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "files: []"
  exit 0
fi
echo "files:"
for f in "${FILES[@]}"; do
  sha="$(git -C "$REPO_ROOT" show "${RESOLVED_COMMIT}:${f}" 2>/dev/null | sha256sum | awk '{print $1}')"
  rel="${f#"$SEAM_DIR"/}"
  echo "  - path: \"$rel\""
  echo "    sha256: \"$sha\""
done
