#!/usr/bin/env bash
# _t351-shutdown-probe.sh — does serve-gallery.sh actually stop the server it started?
#
# Covers T-351 AC1 (both signals, runtime-discovered port, listener AND process asserted)
# and AC4 (orphan census before/after, counted rather than assumed).
#
# ── WHY THIS HARNESS SETS `set -m`, WHICH IS THE WHOLE POINT ──────────────────────────
# The defect under test is that bash sets SIGINT to SIG_IGN for children started with `&`
# when job control is off, and an ignored disposition survives exec. A harness that
# backgrounds the subject with job control off hands the subject that same ignore — and
# then bash *cannot install an INT trap at all*, because a signal ignored on entry to the
# shell cannot be trapped. The SIGINT case would then "fail" for a reason that has nothing
# to do with the fix, or worse, pass by never delivering anything. `set -m` puts the
# subject in its own process group with default dispositions, which is what a terminal
# does. Without this line the SIGINT leg measures the harness, not the subject.
set -uo pipefail
set -m

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SG="${SERVE_GALLERY:-$ROOT/tools/serve-gallery.sh}"
pass=0; fails=0
ok()   { echo "  ok   $*"; pass=$((pass+1)); }
fail() { echo "FAIL $*" >&2; fails=$((fails+1)); }

free_port() {
  python3 -c 'import socket
s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
}

# Always exits 0 so a no-listener grep-miss does not trip anything upstream.
listeners_on_port() {
  { ss -ltnpH "sport = :$1" 2>/dev/null \
      | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u | tr '\n' ' '; } || true
}

# Cleanup must work against a subject whose stop path is BROKEN — which is precisely when
# this probe runs. The first version ended each case with `kill -TERM "$parent"; wait
# "$parent"`, i.e. it assumed the very thing under test. Against the teeth mutants (an
# INT-only trap; a stub that traps TERM and keeps running) the parent never died and the
# unbounded `wait` hung the whole harness for 400s per case until the outer timeout
# fired. Same defect class as the subject, in the tool built to find it: a stop path
# nobody checked. Escalate and bound — TERM first (so a well-behaved subject exits
# cleanly and the exit is observable), KILL only after it has demonstrably not worked.
stop_hard() {
  local pid="$1" i
  [ -n "$pid" ] || return 0
  kill -TERM "$pid" 2>/dev/null || true
  for i in $(seq 1 30); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.1
  done
  kill -KILL "$pid" 2>/dev/null || true
  for i in $(seq 1 20); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.1
  done
}

# AC4: the census must show start time and docroot per process. A bare count cannot
# distinguish "cleaned up" from "nothing matched", and cannot tell an orphan from July
# apart from a server this probe started thirty seconds ago.
census_pids() { pgrep -f 'gallery-serve\.py' 2>/dev/null | sort -n | tr '\n' ' '; }
census_detail() {
  local pid started args
  for pid in $(pgrep -f 'gallery-serve\.py' 2>/dev/null | sort -n); do
    started="$(ps -o lstart= -p "$pid" 2>/dev/null | sed 's/^ *//')"
    args="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)"
    printf '    pid=%-8s started=%-25s %s\n' "$pid" "${started:-?}" "${args:-<gone>}"
  done
}

# ── AC1 ────────────────────────────────────────────────────────────────────────────────
# Start a real server on a port discovered free at runtime, send the parent the signal a
# user would send, and require BOTH that the port is released and that the specific child
# PIDs are gone. Port-free alone is not enough: a process that closed its socket and hung
# would pass a port check while still being an orphan.
run_case() {
  local sig="$1" port dir log parent held survivors leaked pid
  port="$(free_port)"; dir="$(mktemp -d)"; log="$(mktemp)"

  GALLERY_DIR="$dir" "$SG" "$port" >"$log" 2>&1 &
  parent=$!

  for _ in $(seq 1 400); do
    [ -n "$(listeners_on_port "$port" | tr -d ' ')" ] && break
    kill -0 "$parent" 2>/dev/null || break
    sleep 0.1
  done
  held="$(listeners_on_port "$port")"
  if [ -z "${held// /}" ]; then
    fail "SETUP($sig): serve-gallery.sh never bound :$port — a shutdown test against a server that never started would pass for the wrong reason"
    tail -5 "$log" | sed 's/^/      /' >&2
    stop_hard "$parent"
    rm -rf "$dir" "$log"; return
  fi

  # HARNESS PRECONDITION, not an assertion about the subject. If the signal we are about
  # to send is one the subject is IGNORING, then whatever happens next says nothing about
  # its shutdown path — and without this arm the probe would go red pointing at
  # serve-gallery.sh when the fault is in this file (dropping `set -m` does exactly that).
  # SigIgn is a hex mask; signal N is bit N-1, so SIGINT (2) is 0x2, SIGTERM (15) is 0x4000.
  local mask sigign
  case "$sig" in INT) mask=$((0x2)) ;; TERM) mask=$((0x4000)) ;; *) mask=0 ;; esac
  sigign="$(awk '/^SigIgn:/{print $2}' "/proc/$parent/status" 2>/dev/null)"
  if [ "$mask" -ne 0 ] && [ -n "$sigign" ] && [ $(( 0x$sigign & mask )) -ne 0 ]; then
    fail "HARNESS($sig): subject PID $parent has SIG$sig set to SIG_IGN (SigIgn=0x$sigign) — this probe cannot deliver it, so the result would measure the harness, not serve-gallery.sh. Cause is almost certainly a missing \`set -m\` in this file."
    stop_hard "$parent"
    for pid in $held; do stop_hard "$pid"; done
    rm -rf "$dir" "$log"; return
  fi

  kill -"$sig" "$parent" 2>/dev/null || true

  for _ in $(seq 1 100); do
    [ -z "$(listeners_on_port "$port" | tr -d ' ')" ] && break
    sleep 0.1
  done
  leaked="$(listeners_on_port "$port")"

  survivors=""
  for pid in $held; do
    kill -0 "$pid" 2>/dev/null && survivors="$survivors $pid"
  done

  if [ -n "${leaked// /}" ]; then
    fail "AC1($sig): parent PID $parent was sent SIG$sig but :$port is STILL HELD by PID(s):${leaked% } — the server outlived the script that started it (orphaned, exactly the T-351 defect)"
  elif [ -n "${survivors// /}" ]; then
    fail "AC1($sig): :$port was released but gallery-serve.py PID(s)${survivors} are STILL ALIVE after SIG$sig — closed its socket without exiting, which a port-only check would have called clean"
  else
    ok "SIG$sig on the parent stopped the server (:$port released, child PID(s) ${held% } gone)"
  fi

  # Never leak, whatever the verdict — the harness that exists to catch orphans must not
  # add to the population it is counting.
  for pid in $survivors $leaked; do stop_hard "$pid"; done
  stop_hard "$parent"
  rm -rf "$dir" "$log"
}

echo "== T-351 shutdown probe =="
before_pids="$(census_pids)"
before_n="$(echo "$before_pids" | wc -w)"
echo "[AC4] gallery-serve.py processes BEFORE: $before_n"
census_detail

echo "[AC1] shutdown by signal"
run_case TERM
run_case INT

after_pids="$(census_pids)"
after_n="$(echo "$after_pids" | wc -w)"
echo "[AC4] gallery-serve.py processes AFTER: $after_n"
census_detail

# The probe must not change the population. A net-zero delta is only meaningful because
# the identities are compared too — two processes swapped one-for-one would net to zero.
new_pids=""
for pid in $after_pids; do
  case " $before_pids " in *" $pid "*) ;; *) new_pids="$new_pids $pid" ;; esac
done
if [ -n "${new_pids// /}" ]; then
  fail "AC4: this probe LEAKED gallery-serve.py PID(s):${new_pids} — they were not resident before it ran"
else
  ok "AC4: census identities unchanged across the run ($before_n before, $after_n after; no new PIDs)"
fi

echo
echo "probe: $pass passed, $fails failed"
[ "$fails" -eq 0 ] || exit 1
