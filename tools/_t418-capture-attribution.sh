#!/usr/bin/env bash
# _t418-capture-attribution.sh — project a topic's envelopes down to the four fields
# attribution actually needs, and write NOTHING else to disk.
#
# T-418. Capture half of the capture/verdict split; the verdict lives in
# tools/_t418-producer-attribution.py and never touches the network.
#
# WHY THE PROJECTION IS THE POINT
# --------------------------------
# Attribution is a question about {offset, sender_id, msg_type, metadata}. Message
# bodies answer none of it. T-417 landed a 1.6MB rail dump in a tracked tree because
# the capture kept bytes it did not need and a bulk `git add` four minutes later
# published every message of a 464-message conversation. So the payload is dropped
# HERE, at the capture, rather than filtered later by whoever remembers to.
#
# The fixtures this writes are therefore committable by construction: they carry
# routing metadata and no conversation.
#
# READ IDENTITY: this shells out to `termlink`, which on this host resolves to
# identity.key (fingerprint d1993c2c…) and NOT to the MCP identity.json. That is
# harmless for a READ — the topic argument is explicit and no cursor is advanced —
# but it is exactly why rail-sweep.py forbids the same shell-out for a CAPTURE OF
# WHICH TOPICS ARE MINE. Do not widen this script into topic enumeration.
set -uo pipefail

TOPIC="${1:-}"
DEST="${2:-}"
LIMIT="${3:-1000}"

if [ -z "$TOPIC" ] || [ -z "$DEST" ]; then
  echo "usage: $0 <topic> <dest.jsonl> [limit]" >&2
  exit 2
fi

RAW="$(mktemp)"
trap 'rm -f "$RAW"' EXIT

if ! timeout 120 termlink channel subscribe "$TOPIC" --cursor 0 --limit "$LIMIT" --json \
     > "$RAW" 2>/dev/null; then
  echo "ERROR: subscribe failed for topic $TOPIC" >&2
  exit 2
fi

python3 - "$RAW" "$DEST" "$TOPIC" <<'PY' || exit 2
import json, sys
src, dest, topic = sys.argv[1], sys.argv[2], sys.argv[3]
kept = 0
with open(dest, "w", encoding="utf-8") as out:
    for line in open(src, encoding="utf-8"):
        line = line.strip()
        if not line:
            continue
        try:
            env = json.loads(line)
        except json.JSONDecodeError:
            # A row we cannot parse is dropped LOUDLY — a silently short capture would
            # let the detector return a clean verdict over a partial population.
            print("ERROR: unparseable envelope in capture; refusing to write a partial"
                  " fixture", file=sys.stderr)
            sys.exit(2)
        out.write(json.dumps({
            "topic": topic,
            "offset": env.get("offset"),
            "sender_id": env.get("sender_id"),
            "msg_type": env.get("msg_type"),
            "metadata": env.get("metadata"),
        }, sort_keys=True) + "\n")
        kept += 1
print("captured %d envelope(s) from %s -> %s (payloads dropped at capture)"
      % (kept, topic, dest))
PY
