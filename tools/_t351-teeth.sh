#!/usr/bin/env bash
# _t351-teeth.sh — prove each check in _t351-shutdown-probe.sh CAN fail, and fails for its
# OWN stated reason. Every leg requires a SPECIFIC substring: a leg that accepts any
# non-zero exit banks syntax errors as evidence (T-338 (d), T-343 (d), T-348 (c), and it
# cost two false reds on T-350).
#
# Legs (b) and (c) attack the PROBE's own scope rather than the subject — the T-335
# lesson. (a) alone would leave the probe's harness precondition and its
# still-alive-but-socket-closed arm as assertions nobody has ever seen fire.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROBE="$ROOT/tools/_t351-shutdown-probe.sh"
SRC="$ROOT/tools/serve-gallery.sh"
pass=0; fail=0

cleanup() { rm -f "$ROOT"/tools/.t351-mut-*.sh "$ROOT"/tools/.t351-stub-*.sh; }
trap cleanup EXIT
cleanup

# Reap by PID delta: a mutant with a broken shutdown path leaks by definition, and this
# harness must not add to the orphan population that T-351 exists to measure.
run_probe() { # $1=probe path  $2..=env assignments already applied by caller
  local before after pid
  before="$(pgrep -f 'gallery-serve\.py' 2>/dev/null | sort -u | tr '\n' ' ')"
  out="$(timeout 200 bash "$1" 2>&1)"; rc=$?
  after="$(pgrep -f 'gallery-serve\.py' 2>/dev/null | sort -u | tr '\n' ' ')"
  for pid in $after; do
    case " $before " in *" $pid "*) ;; *) kill -TERM "$pid" 2>/dev/null || true ;; esac
  done
}

check() { # $1=id  $2=desc  $3=expected substring   (out/rc already set)
  local id="$1" desc="$2" want="$3"
  if [ "$rc" -eq 0 ]; then
    echo "LEG $id: FAILED TO GO RED — probe still passed with the mutation applied ($desc)" >&2
    fail=$((fail+1)); return
  fi
  if [ "$rc" -eq 124 ]; then
    echo "LEG $id: BROKEN — probe timed out; a red on a hang proves nothing about $desc" >&2
    fail=$((fail+1)); return
  fi
  if ! echo "$out" | grep -qF "$want"; then
    echo "LEG $id: RED FOR THE WRONG REASON — probe failed but never said: $want" >&2
    echo "$out" | grep -E '^FAIL' | sed 's/^/    /' >&2
    fail=$((fail+1)); return
  fi
  echo "LEG $id: ok — red, naming its own condition ($desc)"
  echo "         -> $(echo "$out" | grep -F "$want" | head -1 | cut -c1-150)"
  pass=$((pass+1))
}

echo "== T-351 teeth =="

# ── (a) THE SUBJECT: revert the fix to the INT-only trap ───────────────────────────────
# This is the pre-T-351 code verbatim. The child ignores INT, so the parent exits and
# leaves it holding the port — the orphan-manufacturing behaviour itself.
echo "[leg a] trap reverted to kill -INT (the pre-fix code)"
mut_a="$ROOT/tools/.t351-mut-a.sh"
cp "$SRC" "$mut_a"; chmod +x "$mut_a"
python3 - "$mut_a" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = 'trap \'kill -TERM "$SRV" 2>/dev/null || true\' INT TERM'
if old not in s:
    sys.stderr.write("anchor missing\n"); sys.exit(1)
open(p, 'w').write(s.replace(old, 'trap \'kill -INT "$SRV" 2>/dev/null || true\' INT TERM', 1))
PY
if [ $? -ne 0 ]; then
  echo "LEG a: BROKEN — mutation did not apply (anchor missing); a red here would prove nothing" >&2
  fail=$((fail+1))
else
  SERVE_GALLERY="$mut_a" run_probe "$PROBE"
  # AC3 requires the red to NAME the surviving PID and the port, not merely return non-zero.
  check a "INT-only trap orphans the server" "is STILL HELD by PID(s)"
fi

# ── (b) THE HARNESS'S OWN SCOPE: remove `set -m` from the probe ────────────────────────
# Without job control the probe's own `&` hands the subject SIG_IGN for SIGINT, so the
# INT leg cannot deliver anything. The REQUIREMENT is that the probe says so, naming
# itself — not that it goes red blaming serve-gallery.sh. Without this leg, the harness
# precondition added for exactly that reason would be an assertion nobody has seen fire.
echo "[leg b] probe stripped of 'set -m' must blame ITSELF, not the subject"
mut_b="$ROOT/tools/.t351-mut-b.sh"
python3 - "$PROBE" "$mut_b" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
if '\nset -m\n' not in s:
    sys.stderr.write("anchor missing\n"); sys.exit(1)
open(dst, 'w').write(s.replace('\nset -m\n', '\n# set -m removed by teeth leg (b)\n', 1))
PY
if [ $? -ne 0 ]; then
  echo "LEG b: BROKEN — mutation did not apply (anchor missing); a red here would prove nothing" >&2
  fail=$((fail+1))
else
  run_probe "$mut_b"
  check b "no job control: INT is undeliverable and the probe must name the harness" "Cause is almost certainly a missing"
fi

# ── (c) THE ARM NO REAL SUBJECT EXERCISES: socket closed, process alive ────────────────
# The probe asserts BOTH port-released and child-exited. Real serve-gallery.sh always
# does both, so the second arm has no natural population — the T-346 "prove the bucket
# can fill" problem. A stub subject that releases the port on TERM and keeps running
# makes it fillable. Without this, "port released" and "process gone" would be one
# assertion wearing two, and a server that closed its socket and hung would read clean.
echo "[leg c] stub subject releases the port but does not exit"
stub="$ROOT/tools/.t351-stub-c.sh"
cat > "$stub" <<'STUB'
#!/usr/bin/env bash
exec python3 -c '
import socket, signal, sys, time
srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("0.0.0.0", int(sys.argv[1]))); srv.listen(5)
def on_term(signum, frame):
    srv.close()          # port goes free ...
    while True:          # ... but this process does not
        time.sleep(1)
signal.signal(signal.SIGTERM, on_term)
signal.signal(signal.SIGINT, on_term)
while True: time.sleep(1)
' "$1"
STUB
chmod +x "$stub"
SERVE_GALLERY="$stub" run_probe "$PROBE"
check c "socket closed, process survives — the arm a port-only check would miss" "STILL ALIVE after SIG"

# Leg (c)'s stub ignores nothing and traps everything, so it needs a hard kill.
pkill -KILL -f 't351-stub-c' 2>/dev/null || true

echo
echo "teeth: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
