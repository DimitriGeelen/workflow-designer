#!/usr/bin/env bash
# _t913-bypass-reason-teeth.sh — prove an UNEXPLAINED gate bypass is now recorded distinguishably
# from an explained one, and that both halves of that claim are load-bearing.
#
# THE DEFECT, precisely. `log_gate_bypass` has always read $REASON (update-task.sh:96), and
# `--reason`/`-r` has always set it (:1478). What it could not do is tell these four apart:
#     an unexplained bypass · an explained one whose reason was blank · a logging failure ·
#     a tool that never supported reasons
# All four wrote `reason: ''`. Measured on the T-910 close of 2026-09-28.
#
# THE LEDGER IS APPEND-ONLY AND IS NOT A TEST FIXTURE. Every case below runs the real function
# against a SCRATCH PROJECT_ROOT under mktemp. Nothing here writes to
# .context/working/.gate-bypass-log.yaml, and the last case asserts that.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90
REPO="$PWD"
SRC=".agentic-framework/agents/task-create/update-task.sh"
WORK="$(mktemp -d)"
PASS=0; FAIL=0
trap 'rm -rf "$WORK"' EXIT INT TERM
ok() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

# Extract the function by NAME, not by line range — a range slides off its subject silently.
extract() { sed -n '/^log_gate_bypass() {/,/^}/p' "$1"; }

# mutate <src> <dst> <old> <new> <want> — asserts the count AND that the bytes moved.
mutate() {
  local src="$1" dst="$2" old="$3" new="$4" want="$5"
  OLD="$old" NEW="$new" WANT="$want" SRC="$src" DST="$dst" python3 - <<'PY' || return 1
import os, sys
old, new, want = os.environ['OLD'], os.environ['NEW'], int(os.environ['WANT'])
s = open(os.environ['SRC'], encoding='utf-8').read()
n = s.count(old)
if n != want:
    sys.stderr.write("MUTATION SETUP BROKEN: expected %d, found %d\n" % (want, n)); sys.exit(1)
open(os.environ['DST'], 'w', encoding='utf-8').write(s.replace(old, new))
PY
  cmp -s "$src" "$dst" && { echo "    MUTATION SETUP BROKEN: $dst byte-identical after a successful replacement"; return 1; }
  return 0
}

# call <fnfile> <reason-global> <flag> <caller> [explicit] -> prints the ledger rows it wrote
call() {
  local fnf="$1" reason="$2" flag="$3" caller="$4" explicit="${5:-}"
  local root; root="$(mktemp -d "$WORK/root.XXXXXX")"
  mkdir -p "$root/.context/working"
  FNF="$fnf" ROOT="$root" R="$reason" F="$flag" C="$caller" E="$explicit" bash -c '
    PROJECT_ROOT="$ROOT"; TASK_ID="T-000"; REASON="$R"; YELLOW=""; NC=""
    source "$FNF"
    if [ -n "$E" ]; then log_gate_bypass "$F" "$C" "$E"; else log_gate_bypass "$F" "$C"; fi
  ' 2>/dev/null
  cat "$root/.context/working/.gate-bypass-log.yaml" 2>/dev/null
}

echo "=== T-913 bypass-reason teeth ==="
echo

# ── CONTROLS, FIRST ───────────────────────────────────────────────────────────────────────────
# A logger that fails to source writes NOTHING, and "no unexplained bypasses found" is exactly
# what that looks like. Nothing below is scored until the logger is proven to write at all.
echo "CONTROLS (a logger that writes nothing looks identical to a clean ledger)"
extract "$SRC" > "$WORK/live.sh"
if [ ! -s "$WORK/live.sh" ]; then
  echo "  SETUP BROKEN: could not extract log_gate_bypass from $SRC — anchor moved."
  echo "=== SUMMARY ==="; echo "PASS: 0"; echo "FAIL: 1"; exit 1
fi
out="$(call "$WORK/live.sh" "a real reason" "--skip-x" "some_gate")"
ok "the logger WRITES — a row is produced at all" "$([ -n "$out" ] && echo 0 || echo 1)" "wrote nothing"
ok "the row is parseable YAML" "$(printf '%s\n' "$out" | python3 -c 'import sys,yaml; d=yaml.safe_load(sys.stdin); sys.exit(0 if isinstance(d,list) and d else 1)' && echo 0 || echo 1)"
echo

# ── THE CLAIM ─────────────────────────────────────────────────────────────────────────────────
echo "THE CLAIM: explained and unexplained rows differ, and both say which they are"
exp="$(call "$WORK/live.sh" "operator said so" "--skip-sovereignty" "check_human_sovereignty")"
une="$(call "$WORK/live.sh" "" "--skip-sovereignty" "check_human_sovereignty")"
printf '%s\n' "$exp" | grep -q "reason: 'operator said so'";      ok "explained: the reason is written verbatim" $?
printf '%s\n' "$exp" | grep -q 'explained: true';                 ok "explained: flagged true" $?
printf '%s\n' "$une" | grep -q 'UNEXPLAINED';                     ok "unexplained: carries the marker" $?
printf '%s\n' "$une" | grep -q -- '--reason';                     ok "unexplained: names the remedy in the record" $?
printf '%s\n' "$une" | grep -q 'explained: false';                ok "unexplained: flagged false" $?
[ "$exp" != "$une" ];                                             ok "the two rows are NOT byte-identical (the whole defect)" $?
# The audit question the empty string could not be asked.
n="$(printf '%s\n' "$une" | grep -c 'UNEXPLAINED')"
ok "the ledger is countable: grep finds $n unexplained row(s)" "$([ "$n" -eq 1 ] && echo 0 || echo 1)"
echo

# ── APOSTROPHE ESCAPING STILL HOLDS (T-1861) ──────────────────────────────────────────────────
echo "REGRESSION: operator text with an apostrophe must not corrupt the YAML"
ap="$(call "$WORK/live.sh" "it's the operator's call" "--skip-x" "g")"
printf '%s\n' "$ap" | python3 -c 'import sys,yaml; d=yaml.safe_load(sys.stdin); sys.exit(0 if d[0]["reason"]=="it'"'"'s the operator'"'"'s call" else 1)'
ok "apostrophes survive round-trip through yaml.safe_load" $?
echo

# ── THE EXPLICIT THIRD PARAMETER ──────────────────────────────────────────────────────────────
echo "THE EXPLICIT CHANNEL (for call sites that hold a reason in hand)"
ex="$(call "$WORK/live.sh" "" "--skip-render-review" "check_render_surface_human_ac" "screenshots attached")"
printf '%s\n' "$ex" | grep -q "reason: 'screenshots attached'"; ok "explicit 3rd arg is used when \$REASON is empty" $?
printf '%s\n' "$ex" | grep -q 'explained: true';                ok "explicit 3rd arg counts as explained" $?
pre="$(call "$WORK/live.sh" "global wins?" "--skip-x" "g" "explicit wins")"
printf '%s\n' "$pre" | grep -q "reason: 'explicit wins'";        ok "explicit 3rd arg takes precedence over \$REASON" $?
echo

# ── MUTANT: the marker is removed ─────────────────────────────────────────────────────────────
# Without it an unexplained bypass writes an empty string again — today's defect. If this does not
# regress, the marker is decorative.
echo "MUTANT  the UNEXPLAINED marker is removed"
if mutate "$WORK/live.sh" "$WORK/mut.sh" \
     '_reason_raw="UNEXPLAINED' '_reason_raw="" # T-913 MUTANT: "UNEXPLAINED' 1; then
  ok "mutation applied and bytes moved" 0
  m="$(call "$WORK/mut.sh" "" "--skip-sovereignty" "g")"
  printf '%s\n' "$m" | grep -q "reason: ''"; ok "REGRESSES to the empty string without the marker" $?
  n2="$(printf '%s\n' "$m" | grep -c 'UNEXPLAINED')"
  ok "and becomes uncountable again (0 unexplained rows found)" "$([ "$n2" -eq 0 ] && echo 0 || echo 1)"
else ok "mutation applied" 1 "MUTATION SETUP BROKEN — not scored"; fi
echo

# ── THE APPEND-ONLY LEDGER WAS NOT TOUCHED ────────────────────────────────────────────────────
echo "THE REAL LEDGER IS NOT A TEST FIXTURE"
real="$REPO/.context/working/.gate-bypass-log.yaml"
if [ -f "$real" ]; then
  # NOT EVALUATED rather than PASS when the caller did not pin the hash first. The earlier form
  # defaulted LEDGER_SHA to the file's CURRENT hash, so it compared the file to itself and could
  # not fail — a tautology living in a parameter default (T-3105: not evaluated is not passed).
  if [ -n "${LEDGER_SHA:-}" ]; then
    ok "the project's own bypass ledger is unchanged by this run" \
       "$([ "$(sha256sum "$real" | cut -d' ' -f1)" = "$LEDGER_SHA" ] && echo 0 || echo 1)"
  else
    echo "  NOT EVALUATED  ledger-unchanged: run with LEDGER_SHA=\$(sha256sum <ledger> | cut -d' ' -f1)"
    echo "                 A default of 'the file's current hash' compares it to itself."
  fi
  ok "no scratch row leaked into it (no T-000 rows)" "$(grep -q "task: 'T-000'" "$real" && echo 1 || echo 0)"
else
  ok "no project ledger present to disturb" 0
fi

echo
echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
