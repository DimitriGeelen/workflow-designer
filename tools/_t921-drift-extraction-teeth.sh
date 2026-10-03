#!/usr/bin/env bash
# _t921-drift-extraction-teeth.sh — prove the T-921 quote-stripping change to the focus-drift
# extractor BITES, and prove each of its two halves is load-bearing.
#
# WHY THE BAR IS HIGHER HERE. This edits an enforcement gate. A change that removes false
# positives by removing the gate's ability to see anything at all would look identical in a
# green suite — every false positive gone, and every true positive with them. So the suite is
# built around two mutations that must REGRESS specific rows:
#
#   MUTANT A  the shell-invoking guard always says "not executing"
#             -> the two `bash -c` rows must go from T-910 to empty (the naive fix T-920 disproved)
#   MUTANT B  the stripper is removed
#             -> the data row must go from empty back to T-910 (today's false positive returns)
#
# If either mutation leaves every row unchanged, the half it targets is decorative and the suite
# says so rather than reporting a pass.
#
# THE FOUR ROWS come from T-920's measurements against the pre-change extractor, not from
# reasoning about the code. The two `bash -c` rows are the ones that separate this fix from the
# naive one; a suite without them proves nothing.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90
HOOK=".agentic-framework/agents/context/check-active-task.sh"
WORK="$(mktemp -d)"
PASS=0; FAIL=0
trap 'rm -rf "$WORK"' EXIT INT TERM

ok()  { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

# Extract both functions into a sourceable file. Anchored on the function names, not line
# numbers — a range that slides off its subject is the defect this whole area is about.
# T-1005 retarget (1.7.740): the extractor is now _fw_drift_target_in_clause +
# _fw_extract_drift_target, built on upstream's _fw_chain_split / _fw_strip_quoted from
# lib/safe-commands.sh, which ask() sources. The shell-invoker guard is the `bash|sh -c`
# arm and the stripper is the _fw_strip_quoted view -- the same two halves, new homes.
LIB=".agentic-framework/agents/context/lib/safe-commands.sh"
extract() {
  sed -n '/^_fw_drift_target_in_clause() {/,/^}/p;/^_fw_extract_drift_target() {/,/^}/p' "$1"
}

# mutate <src> <dst> <old> <new> <expected-count> — asserts the count, asserts the bytes moved.
mutate() {
  local src="$1" dst="$2" old="$3" new="$4" want="$5"
  OLD="$old" NEW="$new" WANT="$want" SRC="$src" DST="$dst" python3 - <<'PY' || return 1
import os, sys
old, new, want = os.environ['OLD'], os.environ['NEW'], int(os.environ['WANT'])
s = open(os.environ['SRC'], encoding='utf-8').read()
n = s.count(old)
if n != want:
    sys.stderr.write("MUTATION SETUP BROKEN: expected %d occurrence(s), found %d\n" % (want, n))
    sys.exit(1)
open(os.environ['DST'], 'w', encoding='utf-8').write(s.replace(old, new))
PY
  if cmp -s "$src" "$dst"; then
    echo "    MUTATION SETUP BROKEN: $dst is byte-identical to $src after a replacement that reported success"
    return 1
  fi
  return 0
}

# ask <fnfile> <command> -> prints the extracted target
ask() { FNF="$1" CMD="$2" LIBF="$LIB" bash -c 'source "$LIBF"; source "$FNF"; _fw_extract_drift_target "$CMD"'; }

V=fw; W=task; U=update; TT=T-910
DATA=".agentic-framework/bin/fw note \"OBS-421 said $V $W $U $TT --status work-completed closes it\" --tag bug"
CODE1="bash -c \"echo hi; $V $W $U $TT --status work-completed\""
CODE2="bash -c \"cd /x && $V $W $U $TT\""
PLAIN="$V $W $U $TT --status work-completed"

echo "=== T-921 drift-extraction teeth ==="
echo

# ── CONTROL SET, FIRST ────────────────────────────────────────────────────────────────────────
# An extractor that fails to source returns empty for EVERY input, which reads as "all false
# positives fixed". These three separate that from a working fix, and nothing below is scored
# until they hold.
echo "CONTROLS (run first — a dead extractor returns empty for everything and looks like success)"
extract "$HOOK" > "$WORK/live.sh"
if [ ! -s "$WORK/live.sh" ]; then
  echo "  SETUP BROKEN: could not extract the functions from $HOOK — anchors moved."
  echo "=== SUMMARY ==="; echo "PASS: 0"; echo "FAIL: 1"; exit 1
fi
ok "both functions extracted from the live hook" "$(grep -q '_fw_drift_target_in_clause() {' "$WORK/live.sh" && grep -q '_fw_extract_drift_target() {' "$WORK/live.sh" && echo 0 || echo 1)"
_plain="$(ask "$WORK/live.sh" "$PLAIN")"
ok "extractor is LIVE — an unquoted invocation still extracts ($_plain)" "$([ "$_plain" = "$TT" ] && echo 0 || echo 1)" "got '$_plain', expected $TT"
_none="$(ask "$WORK/live.sh" "echo hello world")"
ok "extractor is DISCRIMINATING — an unrelated command extracts nothing" "$([ -z "$_none" ] && echo 0 || echo 1)" "got '$_none'"
echo

# ── THE FOUR DESIGN ROWS ──────────────────────────────────────────────────────────────────────
echo "THE FOUR ROWS (from T-920's measurements against the pre-change extractor)"
r="$(ask "$WORK/live.sh" "$DATA")";  ok "DATA  note quoting a command  -> empty (false positive removed)" "$([ -z "$r" ] && echo 0 || echo 1)" "got '$r'"
r="$(ask "$WORK/live.sh" "$CODE1")"; ok "CODE  bash -c \"echo hi; …\"   -> $TT (true positive preserved)" "$([ "$r" = "$TT" ] && echo 0 || echo 1)" "got '$r'"
r="$(ask "$WORK/live.sh" "$CODE2")"; ok "CODE  bash -c \"cd /x && …\"   -> $TT (true positive preserved)" "$([ "$r" = "$TT" ] && echo 0 || echo 1)" "got '$r'"
r="$(ask "$WORK/live.sh" "$PLAIN")"; ok "PLAIN unquoted invocation     -> $TT (unaffected)"              "$([ "$r" = "$TT" ] && echo 0 || echo 1)" "got '$r'"
echo

# ── MUTANT A: the shell-invoking guard is neutralised ─────────────────────────────────────────
# This is the naive fix T-920 disproved. Both CODE rows must regress to empty; if they do not,
# the guard is decorative and the change is the unsafe one wearing the safe one's comments.
echo "MUTANT A  the shell-invoking guard always answers 'not executing'"
if mutate "$WORK/live.sh" "$WORK/mutA.sh" \
     'if [[ "$clause" =~ ^(bash|sh)[[:space:]]+-c[[:space:]]+(.*)$ ]]; then' \
     'if false && [[ "$clause" =~ ^(bash|sh)[[:space:]]+-c[[:space:]]+(.*)$ ]]; then   # T-921 MUTANT A' 1; then
  ok "mutation applied and bytes moved" 0
  a1="$(ask "$WORK/mutA.sh" "$CODE1")"; a2="$(ask "$WORK/mutA.sh" "$CODE2")"
  ok "CODE row 1 REGRESSES to empty without the guard" "$([ -z "$a1" ] && echo 0 || echo 1)" "got '$a1' — guard is not load-bearing"
  ok "CODE row 2 REGRESSES to empty without the guard" "$([ -z "$a2" ] && echo 0 || echo 1)" "got '$a2' — guard is not load-bearing"
  ad="$(ask "$WORK/mutA.sh" "$DATA")"
  ok "DATA row is UNCHANGED by this mutation (isolates the guard)" "$([ -z "$ad" ] && echo 0 || echo 1)" "got '$ad'"
else ok "mutation applied" 1 "MUTATION SETUP BROKEN — not scored"; fi
echo

# ── MUTANT B: the stripper is removed ─────────────────────────────────────────────────────────
# Today's behaviour. The DATA row must regress to the false positive; if it does not, the strip
# never ran and the DATA row above passed for some other reason.
echo "MUTANT B  the quote-stripper is removed"
if mutate "$WORK/live.sh" "$WORK/mutB.sh" \
     'view=$(_fw_strip_quoted "$clause") && clause="$view"' \
     ': # T-921 MUTANT B' 1; then
  ok "mutation applied and bytes moved" 0
  bd="$(ask "$WORK/mutB.sh" "$DATA")"
  ok "DATA row REGRESSES to $TT without the stripper" "$([ "$bd" = "$TT" ] && echo 0 || echo 1)" "got '$bd' — the strip never ran"
  b1="$(ask "$WORK/mutB.sh" "$CODE1")"
  ok "CODE row 1 is UNCHANGED by this mutation (isolates the stripper)" "$([ "$b1" = "$TT" ] && echo 0 || echo 1)" "got '$b1'"
else ok "mutation applied" 1 "MUTATION SETUP BROKEN — not scored"; fi
echo

# ── NO SHAPE THAT BLOCKS TODAY STOPS BLOCKING ─────────────────────────────────────────────────
# Every currently-matching shell-invoking form, plus the three documented unquoted patterns.
#
# `eval "<verb> T-N"` is DELIBERATELY ABSENT. It looked like a regression on the first run and is
# not: measured against the pre-change extractor it returns empty there too, because pattern 1
# anchors on whitespace-or-start and the character before the verb is a quote. Listing it here
# would assert a guarantee this gate has never made. Same pre-existing gap T-920 found for
# `bash -c "<verb> …"` with no leading space.
echo "REGRESSION: shapes that block today must still block"
while IFS='|' read -r label cmd; do
  [ -z "$label" ] && continue
  r="$(ask "$WORK/live.sh" "$cmd")"
  ok "still blocks: $label" "$([ "$r" = "$TT" ] && echo 0 || echo 1)" "got '$r'"
done <<EOF
sh -c chained|sh -c "true; $V $W $U $TT"
ssh remote|ssh host "cd /x && $V $W $U $TT"
find -exec|find . -name x -exec $V $W $U $TT \\;
xargs|echo x | xargs -I{} $V $W $U $TT
unquoted pattern 1|$V $W $U $TT
unquoted pattern 2|fw context add-learning "note" --task $TT
unquoted pattern 3|git commit -m "$TT: subject"
EOF
echo

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
