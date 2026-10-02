#!/usr/bin/env bash
# runme-watch.sh — the agent's side of runme-signal.sh (832 T-1003).
#
# Run it in the BACKGROUND when handing the operator a runme.sh. It remembers where the event
# file and the TermLink topic stand now, then exits — printing the new event line(s) — as soon as
# anything new appears in either. Its exit is what wakes the agent; the agent reads the log, acts,
# and re-arms it for the next event.
#
#   bash tools/runme-watch.sh [timeout-seconds]      default 28800 (8 h); exit 0 = event, 3 = timeout
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FILE="${RUNME_EVENTS_FILE:-$ROOT/.context/working/runme.events}"
TOPIC="${RUNME_SIGNAL_TOPIC:-runme-832}"
LIMIT="${1:-28800}"

lines() { [ -f "$FILE" ] && wc -l < "$FILE" || echo 0; }
topic_next() {  # next offset on the topic (0 when the topic does not exist / hub unreachable)
    timeout 20 termlink channel subscribe "$TOPIC" --json --limit 1000 --cursor "${1:-0}" 2>/dev/null \
      | python3 -c 'import sys,json
o=[json.loads(l).get("offset") for l in sys.stdin if l.strip().startswith("{")]
o=[x for x in o if isinstance(x,int)]
print(max(o)+1 if o else int(sys.argv[1]))' "${1:-0}" 2>/dev/null || echo "${1:-0}"
}

f0=$(lines)
t0=0; command -v termlink >/dev/null 2>&1 && { t=$(topic_next 0); while [ "$t" != "$t0" ]; do t0=$t; t=$(topic_next "$t0"); done; }
start=$(date +%s)
while [ $(( $(date +%s) - start )) -lt "$LIMIT" ]; do
    f=$(lines)
    if [ "$f" -gt "$f0" ]; then
        echo "runme event (file):"; tail -n +"$((f0 + 1))" "$FILE"; exit 0
    fi
    if command -v termlink >/dev/null 2>&1; then
        new=$(timeout 20 termlink channel subscribe "$TOPIC" --cursor "$t0" --limit 50 2>/dev/null | grep -E '^\[[0-9]+\]')
        [ -n "$new" ] && { echo "runme event (topic $TOPIC):"; echo "$new" | cut -c1-400; exit 0; }
    fi
    sleep 3
done
echo "runme-watch: no event in ${LIMIT}s"
exit 3
