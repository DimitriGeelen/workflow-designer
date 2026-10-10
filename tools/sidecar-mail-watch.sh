#!/usr/bin/env bash
# sidecar-mail-watch.sh — wake a NON-INJECTABLE agent session when sidecar mail waits for it (T-1108).
#
# A Claude Code background session owns no tmux pane and no TermLink session, so the sidecar receiver
# cannot type mail into it: every consult is recorded INJECT_BLOCKED / WAITING_NO_RECIPIENT and "waits for
# the agent's next prompt" — i.e. for a human. A background agent is woken only by one of its own background
# tasks exiting. This is that task: armed like tools/runme-watch.sh, it exits as soon as a consult for this
# agent is waiting and has not already been shown (the receiver's own view: awaiting_handover() minus
# seen.withheld()), printing who sent it and the msg id. Re-arm after each wake.
#
# Origin: 2026-10-09, a consult from dimitri-mint-dev sat 7 min unseen (21:31:25Z -> 21:38:34Z) until the
# operator prompted; a second one arrived while the RCA was being written, unseen the same way.
#
#   bash tools/sidecar-mail-watch.sh            # run in the BACKGROUND; exits 0 on mail
#   SIDECAR_WATCH_POLL=15 SIDECAR_WATCH_MAX=0  (seconds; 0 = no limit, the default since T-1117; a positive MAX
#   exits 3 when it passes with no mail — for tests. The old 8 h default only ended the watch.)
#   --once      check once: exit 0 if mail waits, 1 if not (for tests / session-start)
# Exit: 0 mail waiting · 1 (--once) none · 2 cannot read the receiver state (NOT CHECKED) · 3 timed out
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
POLL=${SIDECAR_WATCH_POLL:-15}
MAX=${SIDECAR_WATCH_MAX:-0}
ONCE=0; [ "${1:-}" = "--once" ] && ONCE=1
# Each consult is reported ONCE: it stays "waiting" until the next prompt hands it over, so without this a
# re-armed watcher would fire on the same message forever. Ids reported go here (one per line).
SEEN=${SIDECAR_WATCH_SEEN:-$ROOT/.context/working/sidecar-mail-watch.seen}

check() {  # prints "<from> <conversation> <msg_id>" per unseen waiting consult; rc 2 = could not read
    (cd "$ROOT" && python3 - <<'PY'
import json, sys
sys.path.insert(0, '.agentic-framework/lib')
try:
    from sidecar import receiver, seen
    waiting = receiver.awaiting_handover()
    held = seen.withheld(waiting)
except Exception as e:
    print('NOT CHECKED: %s' % e, file=sys.stderr); sys.exit(2)
for m in waiting:
    if m in held:
        continue
    try:
        d = json.load(open(receiver._messages_dir() / (m + '.json')))
    except Exception:
        d = {}
    print('%s %s %s' % (d.get('from') or '?', d.get('conversation_id') or '-', m))
PY
    )
}

# T-1117: record who armed this watch (as runme-watch.sh does, T-1050), so the session-start check can say
# MAIL WATCH MISSING when the session that armed it is gone. Removed when mail is reported (the agent re-arms).
WATCH_REC=${SIDECAR_MAIL_WATCH_FILE:-$ROOT/.context/working/sidecar-mail.watch}
if [ "$ONCE" = 0 ]; then
    armer=""; p=$$
    while [ -n "$p" ] && [ "$p" -gt 1 ]; do
        [ "$(cat /proc/"$p"/comm 2>/dev/null)" = claude ] && { armer=$p; break; }
        p=$(awk '{print $4}' /proc/"$p"/stat 2>/dev/null)
    done
    mkdir -p "$(dirname "$WATCH_REC")" 2>/dev/null
    printf 'watch_pid=%s claude_pid=%s armed=%s\n' "$$" "${armer:-none}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$WATCH_REC" 2>/dev/null
fi

t0=$(date +%s)
while :; do
    out=$(check); rc=$?
    if [ "$rc" = 2 ]; then echo "sidecar-mail-watch: NOT CHECKED (receiver state unreadable)"; exit 2; fi
    [ -n "$out" ] && [ -f "$SEEN" ] && out=$(printf '%s\n' "$out" | grep -vF -f "$SEEN" || true)
    if [ -n "$out" ]; then
        [ "$ONCE" = 1 ] || printf '%s\n' "$out" | awk '{print $3}' >> "$SEEN"
        echo "sidecar-mail-watch: mail waiting (read it: .agentic-framework/bin/fw sidecar inbox --peek, or the receiver message):"
        printf '  %s\n' "$out" | sed 's/^  \([^ ]*\) \([^ ]*\) /  from \1  conversation \2  msg /'
        [ "$ONCE" = 1 ] || rm -f "$WATCH_REC"
        exit 0
    fi
    [ "$ONCE" = 1 ] && exit 1
    [ "$MAX" -gt 0 ] && [ $(( $(date +%s) - t0 )) -ge "$MAX" ] && { echo "sidecar-mail-watch: no mail in ${MAX}s"; exit 3; }
    sleep "$POLL"
done
