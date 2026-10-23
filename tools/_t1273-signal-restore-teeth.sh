#!/usr/bin/env bash
# _t1273-signal-restore-teeth.sh — prove, on DUMMIES, that the T-1273 signal patterns restore and the old ones do not.
#
# WHY (T-1273). The sweep's `timeout` TERMed _t910-lanemeta-teeth.sh mid-run and src stayed mutated. The cause is
# two language facts, not a quirk of one script:
#   bash    a trap handler for INT/TERM that RETURNS lets the script resume after the interrupted command;
#   python  an unhandled SIGTERM ends the process without running `finally`.
# This script shows both on throwaway files, never on a real one: the operator declined killing real mutation
# scripts (2026-10-23). Each dummy mimics a teeth script: back up, mutate, run a long "harness", restore, mutate
# again, restore. Under `timeout 1`:
#   OLD bash   (trap cleanup EXIT INT TERM, _t910's)            -> resumes, plants mutant-2, cannot restore it;
#   FIXED bash (trap cleanup EXIT; trap 'exit 143' TERM ...)     -> original, nothing runs after the signal;
#   OLD py     (restore in finally)                             -> mutant-1 left;
#   FIXED py   (signal.signal(SIGTERM, -> sys.exit))            -> original, nothing runs after the signal.
# CONTROL: every dummy, NOT killed, ends with the original bytes, so the difference above is the signal alone.
# The static guard (_t1273-mutation-signal-guard.py) must also flag the OLD dummies and pass the FIXED ones.
# Exit 0 = all assertions hold; 1 = any failed.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90
ROOT="$PWD"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t1273-teeth.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
PASS=0; FAIL=0
ok() { if [ "$2" = 0 ]; then PASS=$((PASS + 1)); echo "  ok    $1"; else FAIL=$((FAIL + 1)); echo "  FAIL  $1${3:+ — $3}"; fi; }

# Each dummy: $1 = the throwaway file, $2 = a log, $3 = seconds the "harness" runs.
cat > "$WORK/old.sh" <<'SH'
F="$1"; LOG="$2"; NAP="$3"; BAK="$F.bak"; ORIG="$(cat "$F")"
cp "$F" "$BAK"
# as _t910: copy back, then verify the bytes (a failed cp is silent; the check is what dies)
restore() { cp "$BAK" "$F" 2>/dev/null; [ "$(cat "$F")" = "$ORIG" ] || { echo "FATAL left mutated" >> "$LOG"; exit 91; }; }
cleanup() { restore; rm -f "$BAK"; }
trap cleanup EXIT INT TERM
echo mutant-1 > "$F"; sleep "$NAP"; echo after-signal >> "$LOG"; restore
echo mutant-2 > "$F"; sleep "$NAP"; restore
SH
sed "s/^trap cleanup EXIT INT TERM\$/trap cleanup EXIT; trap 'exit 130' INT; trap 'exit 143' TERM/" "$WORK/old.sh" > "$WORK/fixed.sh"

cat > "$WORK/old.py" <<'PY'
import sys, time
f, log, nap = sys.argv[1], sys.argv[2], float(sys.argv[3])
orig = open(f).read()
open(f, "w").write("mutant-1\n")
try:
    time.sleep(nap)
finally:
    open(f, "w").write(orig)
open(log, "a").write("after-signal\n")
PY
python3 - "$WORK/old.py" "$WORK/fixed.py" <<'PY'
import sys
s = open(sys.argv[1]).read()
s = s.replace("import sys, time\n", "import signal, sys, time\nsignal.signal(signal.SIGTERM, lambda s, f: sys.exit(128 + s))\n", 1)
open(sys.argv[2], "w").write(s)
PY
grep -q "trap 'exit 143' TERM" "$WORK/fixed.sh" && grep -q "signal.SIGTERM" "$WORK/fixed.py" \
  || { echo "SETUP BROKEN: the fixed dummies were not derived"; exit 1; }

run() {  # run <dummy> <nap> [timeout]  -> sets RC, CONTENT, LOG_TEXT
  local d="$1" nap="$2" t="${3:-}" f="$WORK/victim-$RANDOM" log="$WORK/log-$RANDOM" r
  echo original > "$f"; : > "$log"
  case "$d" in *.py) r=python3 ;; *) r=bash ;; esac
  if [ -n "$t" ]; then timeout "$t" "$r" "$WORK/$d" "$f" "$log" "$nap" >/dev/null 2>&1; else "$r" "$WORK/$d" "$f" "$log" "$nap" >/dev/null 2>&1; fi
  RC=$?; CONTENT="$(cat "$f")"; LOG_TEXT="$(tr '\n' ' ' < "$log")"
}

echo "T-1273 signal-restore teeth (dummies in $WORK)"
echo "control — not killed, every dummy restores"
for d in old.sh fixed.sh old.py fixed.py; do
  run "$d" 0
  ok "$d unkilled: rc 0, file original" "$([ "$RC" = 0 ] && [ "$CONTENT" = original ] && echo 0 || echo 1)" "rc=$RC file=$CONTENT"
done

echo "killed by timeout 1 mid-harness"
run old.sh 2 1
ok "OLD bash resumes after TERM and leaves the mutant (file=$CONTENT, log: $LOG_TEXT)" \
   "$([ "$CONTENT" = mutant-2 ] && [[ "$LOG_TEXT" == *after-signal* ]] && echo 0 || echo 1)"
run fixed.sh 2 1
ok "FIXED bash restores and runs nothing after TERM (rc=$RC file=$CONTENT)" \
   "$([ "$RC" = 124 ] && [ "$CONTENT" = original ] && [ -z "${LOG_TEXT// /}" ] && echo 0 || echo 1)" "log: $LOG_TEXT"
run old.py 2 1
ok "OLD python skips finally on TERM and leaves the mutant (file=$CONTENT)" \
   "$([ "$CONTENT" = mutant-1 ] && echo 0 || echo 1)"
run fixed.py 2 1
ok "FIXED python runs finally and nothing after TERM (rc=$RC file=$CONTENT)" \
   "$([ "$RC" = 124 ] && [ "$CONTENT" = original ] && [ -z "${LOG_TEXT// /}" ] && echo 0 || echo 1)" "log: $LOG_TEXT"

echo "the static guard agrees with the behaviour"
verdict="$(python3 - "$ROOT/tools/_t1273-mutation-signal-guard.py" "$WORK" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("g", sys.argv[1]); g = importlib.util.module_from_spec(spec)
spec.loader.exec_module(g)
w = sys.argv[2]; t = lambda n: open(f"{w}/{n}").read()
print(" ".join([
    "old.sh=" + ("flagged" if g.bash_in_place(t("old.sh")) and g.bash_unsafe(t("old.sh")) else "missed"),
    "fixed.sh=" + ("clean" if not g.bash_unsafe(t("fixed.sh")) else "wrong"),
    "old.py=" + ("flagged" if g.py_in_place(t("old.py")) and not g.SIGTERM_RE.search(t("old.py")) else "missed"),
    "fixed.py=" + ("clean" if g.py_in_place(t("fixed.py")) and g.SIGTERM_RE.search(t("fixed.py")) else "wrong"),
]))
PY
)"
ok "guard: $verdict" "$([ "$verdict" = "old.sh=flagged fixed.sh=clean old.py=flagged fixed.py=clean" ] && echo 0 || echo 1)"

echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
