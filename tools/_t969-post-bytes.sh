#!/usr/bin/env bash
# _t969-post-bytes.sh — post a file to a termlink topic in sha-verified parts.
#
# WHY PARTS. The payload guidance is ~6000 chars and both seam files exceed it
# (12,507 and 11,565 bytes). AEF named the convention: --metadata part=k/n.
#
# WHY THE WHOLE-FILE sha256 ON EVERY PART. A per-part checksum proves each chunk
# arrived; only the whole-file digest proves the REASSEMBLY is right. Dropping or
# reordering a part is exactly the failure a per-part check cannot see, and it
# would be found by the receiver rather than by us.
#
# Usage: _t969-post-bytes.sh <topic> <file> [chunk_bytes]
set -uo pipefail

TOPIC="${1:?topic}"
FILE="${2:?file}"
CHUNK="${3:-5000}"

[ -f "$FILE" ] || { echo "FATAL: no such file: $FILE" >&2; exit 2; }

NAME="$(basename "$FILE")"
SUM="$(sha256sum "$FILE" | cut -c1-64)"
SIZE="$(wc -c < "$FILE")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
split -b "$CHUNK" -d -a 2 "$FILE" "$WORK/part."
N="$(ls "$WORK"/part.* | wc -l)"

echo "posting $NAME ($SIZE bytes, sha256 ${SUM:0:16}…) as $N part(s) to $TOPIC"

k=0
for p in "$WORK"/part.*; do
    k=$((k + 1))
    termlink channel post "$TOPIC" --ensure-topic \
        --msg-type file \
        --metadata from_project=832-Workflow-designer \
        --metadata name="$NAME" \
        --metadata sha256="$SUM" \
        --metadata bytes="$SIZE" \
        --metadata part="$k/$N" \
        --payload "$(cat "$p")" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "  FAILED on part $k/$N (exit $rc)" >&2
        exit 3
    fi
    echo "  ok part $k/$N ($(wc -c < "$p") bytes)"
done
echo "done: $NAME in $N part(s), whole-file sha256 $SUM"
