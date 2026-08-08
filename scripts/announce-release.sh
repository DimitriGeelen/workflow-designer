#!/usr/bin/env bash
# announce-release.sh — publish the current release identity to the AEF rail as
# ONE cv-indexed envelope, so AEF can answer "am I current?" with a live read.
#
# T-389 (arc: designer-authoring-surface), closing the consumer half of G-024.
#
# WHY THIS EXISTS, AND WHY IT IS NOT A FILE.
# G-024 is release-state blindness: AEF re-reported a defect we had fixed 9 days
# earlier because nothing they could read told them a newer build existed. The
# obvious fix — publish dist/LATEST.yaml — was proposed and REFUSED by both sides
# (rail 469/471 §2). A pointer that answers "is there something newer?" must live
# outside the thing being versioned AND be read live; a vendored copy of such a
# pointer is back inside a versioned thing, the version being "whenever I last
# vendored". A second file would have had the identical failure mode and both
# sides would have felt better with nothing fixed.
#
# AEF also cannot fetch: their T-559 boundary forbids reading our working tree,
# and they will not guess repo URLs unasked (rail 471 §3). So the rail — which we
# both already run, and which is re-read rather than held — is the transport.
#
# WHY cv_key AND NOT "SCAN THE RAIL". Measured on the live 470-message rail:
#     channel state  (full replay)  1,443,501 bytes   0.08s   grows without bound
#     channel cv-keys (indexed)             99 bytes   0.01s   constant
# AEF flagged "is reading channel state cheap enough for a routine check?" as
# unverified. It has two answers 14,580x apart and the expensive one is the one
# you get by default. Tagging the envelope with metadata.cv_key lets a consumer
# read the CURRENT release in O(1) via `channel subscribe --include-current-value`
# with a cursor past the end — no replay, no cursor bookkeeping, no vendored copy.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# ANNOUNCE_MANIFEST exists so the probe can drive this with a synthetic release
# identity. Without it the "identity is version+sha, not version alone" rule is
# untestable — and an untested rule about silent staleness is the thing this
# script exists to prevent. Default is the real manifest.
MANIFEST="${ANNOUNCE_MANIFEST:-$REPO_ROOT/dist/MANIFEST.yaml}"

# The rail. Overridable so the probe can exercise this against a scratch topic
# without posting to the real channel.
RAIL="${ANNOUNCE_TOPIC:-dm:0e7ee6cad65137fc:6a646ce8b1bc6560}"
CV_KEY="designer-release"

[ -f "$MANIFEST" ] || { echo "ERROR: no manifest to announce: $MANIFEST" >&2; exit 1; }

# Read release identity FROM THE MANIFEST — never re-derive it here. The manifest
# is what the cut produced and what AEF verifies against; a second derivation could
# disagree with it, and then the rail would advertise something that was never built.
_f() { sed -n "s/^$1: *\"\(.*\)\"/\1/p" "$MANIFEST" | head -1; }
VERSION="$(_f version)"
RELEASED="$(_f released)"
SRC_COMMIT="$(_f src_commit)"
SHA="$(_f sha256)"
ARTIFACT="$(_f artifact)"

[ -n "$VERSION" ] || { echo "ERROR: manifest has no version: field" >&2; exit 1; }
[ -n "$SHA" ]     || { echo "ERROR: manifest has no sha256: field" >&2; exit 1; }

# version + sha256 together are the identity. Version alone would let a re-cut of
# the same version (RELEASE_ALLOW_OVERWRITE) silently keep the old announcement.
IDENTITY="$VERSION $SHA"

command -v termlink >/dev/null 2>&1 || {
  echo "ERROR: termlink not on PATH — cannot announce." >&2
  exit 1
}

# ── Idempotence ────────────────────────────────────────────────────────────────
# Read the CURRENT advertised value and compare identity. Deliberately NOT done
# with --client-msg-id: that dedupes on a ~5 minute TTL, and "have we already
# announced 0.8.0?" is a question that spans days. The rail's own current value is
# the only thing that answers it durably.
CURRENT=""
if CUR_JSON="$(termlink channel subscribe "$RAIL" --cursor 99999999 \
                 --include-current-value --json 2>/dev/null)"; then
  CURRENT="$(printf '%s' "$CUR_JSON" \
    | python3 -c 'import sys,json,base64
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for e in d.get("current_values") or []:
    if e.get("cv_key")!="'"$CV_KEY"'": continue
    b=(e.get("msg") or {}).get("payload_b64")
    if not b: continue
    t=base64.b64decode(b).decode("utf-8","replace")
    v=s=""
    for ln in t.splitlines():
        if ln.startswith("version:"): v=ln.split(":",1)[1].strip().strip("\"")
        if ln.startswith("sha256:"):  s=ln.split(":",1)[1].strip().strip("\"")
    print(v+" "+s)' 2>/dev/null || true)"
fi

if [ "$CURRENT" = "$IDENTITY" ]; then
  echo "Already announced: $VERSION ($SHA) — rail unchanged, nothing posted."
  exit 0
fi

# ── The envelope ───────────────────────────────────────────────────────────────
# Self-describing: `kind` lets a reader tell a release envelope from the prose that
# shares this topic even if metadata were stripped in transit. version/released/
# src_commit are the three AEF asked for at rail 464; sha256/artifact are what their
# pin verification already needs, so including them saves a second round trip.
PAYLOAD="$(cat <<EOF
kind: designer-release
version: "$VERSION"
released: "$RELEASED"
src_commit: "$SRC_COMMIT"
sha256: "$SHA"
artifact: "$ARTIFACT"
source: "832-Workflow-designer dist/MANIFEST.yaml"
EOF
)"

POST_JSON="$(printf '%s' "$PAYLOAD" | termlink channel post "$RAIL" \
  --msg-type release \
  --metadata "cv_key=$CV_KEY" \
  --metadata "event_type=designer-release" \
  --ensure-topic --json 2>&1)" || {
    echo "ERROR: rail post failed for $VERSION" >&2
    printf '%s\n' "$POST_JSON" | head -5 >&2
    exit 1
  }

POST_OFFSET="$(printf '%s' "$POST_JSON" \
  | python3 -c 'import sys,json
try: print((json.load(sys.stdin).get("delivered") or {}).get("offset",""))
except Exception: pass' 2>/dev/null || true)"

# ── Verify the hub INDEXED it, not merely accepted it ──────────────────────────
# A successful post proves the envelope was appended. It does NOT prove the cv_key
# metadata was honoured — and if it was not, the consumer's O(1) read never sees
# this release while we believe we announced it. That is the exact silent-failure
# shape this whole gap is about (PL-034: internal self-consistency cannot detect a
# broken promise). So re-read the index and require it to point at OUR offset.
INDEXED="$(termlink channel cv-keys "$RAIL" --json 2>/dev/null \
  | python3 -c 'import sys,json
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for e in d.get("entries") or []:
    if e.get("cv_key")=="'"$CV_KEY"'": print(e.get("offset",""))' 2>/dev/null || true)"

if [ -z "$POST_OFFSET" ] || [ "$INDEXED" != "$POST_OFFSET" ]; then
  echo "ERROR: envelope posted (offset ${POST_OFFSET:-?}) but cv_key '$CV_KEY' indexes" >&2
  echo "       '${INDEXED:-<none>}'. The consumer's O(1) currency read would NOT see" >&2
  echo "       this release. Treating as a FAILED announce." >&2
  exit 1
fi

echo "Announced $VERSION to $RAIL (offset $POST_OFFSET, cv_key=$CV_KEY)"
