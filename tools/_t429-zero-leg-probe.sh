#!/usr/bin/env bash
# _t429-zero-leg-probe.sh — run a suite with EVERY LEG NEUTERED and report what it returns.
#
# T-429.
#
# WHY THIS EXISTS AND THE CENSUS IS NOT ENOUGH
# --------------------------------------------
# _t429-abstention-census.py reads source and reasons about branches. Its FIRST DRAFT got
# that reasoning backwards — it matched `-eq 0` near `exit 1` and declared the ordinary
# verdict line a guard. A static classifier is a belief about behaviour. This is the
# behaviour: neuter the suite's assertion helper so no leg can record anything, run the
# real file, print the real exit code.
#
# HOW A LEG IS NEUTERED
# ---------------------
# Every suite here funnels its assertions through one helper whose body increments a tally.
# The helper is FOUND, not assumed: the first function in the file whose body contains a
# `x=$((x+1))`. Its body is replaced with `:`. Nothing else in the file is touched — the
# fixture still builds, the checker still runs, output still prints. Only the recording of
# outcomes disappears, which is precisely the condition under audit.
#
# WHY THE COPY LIVES IN tools/ AND NOT IN /tmp
# --------------------------------------------
# These suites open with `cd "$(dirname "$0")/.."` to reach the repo root. A copy in /tmp
# resolves that to /tmp and the suite dies on its own setup — which would produce a
# non-zero exit for the WRONG REASON and read as a pass of this probe. The copy therefore
# sits beside the original, under a dot-name, and is removed on exit including on abort.
#
# USAGE
#   tools/_t429-zero-leg-probe.sh tools/_tNNN-something.sh
#
# EXIT
#   0  the suite FAILED with no legs (it is guarded — the good outcome)
#   1  the suite RETURNED 0 with no legs (it abstained silently — the finding)
#   2  cannot answer: no helper found, or the neutered copy died during setup
set -uo pipefail

SUITE="${1:-}"
[ -n "$SUITE" ] || { echo "usage: $0 <suite.sh>"; exit 2; }
cd "$(dirname "$0")/.." || exit 2
[ -f "$SUITE" ] || { echo "UNKNOWN — no such suite: $SUITE"; exit 2; }

NEUTERED="tools/.t429-neutered-$$.sh"
trap 'rm -f "$NEUTERED"' EXIT INT TERM

# Find the assertion helper and blank its body. Reported, so a wrong pick is visible.
HELPER="$(python3 - "$SUITE" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# function bodies: name() { ... } at top level, brace-matched shallowly
for m in re.finditer(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", src, re.M):
    name, start = m.group(1), m.end()
    depth, i = 1, start
    while i < len(src) and depth:
        if src[i] == "{": depth += 1
        elif src[i] == "}": depth -= 1
        i += 1
    body = src[start:i]
    if re.search(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$\(\(\s*\1\s*\+\s*1\s*\)\)", body):
        print("%s %d %d" % (name, start, i - 1))
        break
PY
)"

[ -n "$HELPER" ] || { echo "UNKNOWN — no assertion helper found in $SUITE; cannot neuter it."; exit 2; }
set -- $HELPER
NAME="$1"; BSTART="$2"; BEND="$3"

python3 - "$SUITE" "$NEUTERED" "$BSTART" "$BEND" <<'PY'
import sys
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
a, b = int(sys.argv[3]), int(sys.argv[4])
open(sys.argv[2], "w", encoding="utf-8").write(src[:a] + "\n  : # T-429 neutered\n" + src[b:])
PY

chmod +x "$NEUTERED"
OUT="$(bash "$NEUTERED" 2>&1)"; RC=$?

echo "=== T-429 zero-leg probe: $SUITE ==="
echo "  assertion helper neutered: ${NAME}()"
echo "  exit code with no legs recorded: $RC"
echo "  last line of its output: $(printf '%s' "$OUT" | tail -1)"
echo

if printf '%s' "$OUT" | grep -qiE 'no such file|command not found|cannot|not found.*fixture'; then
  echo "  (note: the neutered run produced setup-shaped errors; read the output before"
  echo "   trusting a non-zero verdict — a suite that died in setup is not a guarded one.)"
fi

if [ "$RC" -eq 0 ]; then
  echo "ABSTAINED — the suite verified nothing and reported success."
  echo "  Its caller records a green. So does P-011. So does a human reading the log."
  exit 1
fi
echo "GUARDED — the suite refused to report success without running legs."
exit 0
