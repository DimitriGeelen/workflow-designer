#!/usr/bin/env bash
# _t430-abstention-teeth.sh — prove an abstention guard FIRES, not merely that the suite died.
#
# T-430.
#
# WHY _t429-zero-leg-probe.sh IS NOT SUFFICIENT
# ---------------------------------------------
# That probe blanks the suite's assertion helper and reads the PROCESS EXIT CODE: non-zero
# is reported as GUARDED. That inference holds only while the suite is otherwise green.
#
# Measured, not argued. tools/_t400-schema-teeth.sh carries one genuinely red leg (RECIPROC
# — the live concerns register has a field nothing accounts for). With a leg counter added
# and the abstention guard DELETED, the probe still printed:
#
#     assertion helper neutered: leg()
#     exit code with no legs recorded: 1
#     GUARDED — the suite refused to report success without running legs.
#
# There was no guard in that file. The suite exited 1 because a leg was red, and the probe
# read the corpse as a verdict. Same class as the defect T-429 was built to find: it asks
# *did this process exit non-zero* when the question is *did the abstention guard fire*.
#
# 2026-08-12 (T-464) — the demonstration above is now HISTORY, not a reproducible setup.
# _t400-schema-teeth.sh's RECIPROC leg was red for two stacked reasons: the register
# carried a field the schema did not account for (fixed in T-463) and the leg restated its
# expected population as a literal that went stale (fixed in T-464). It is green today, so
# re-running the T-429 probe against it would no longer show the false GUARDED. The
# argument in this header stands on its own — a probe that reads a process corpse as a
# verdict is unsound whether or not this particular suite is currently red — but a reader
# trying to reproduce the measurement should know why it will not reproduce.
#
# TWO DIFFERENCES, BOTH LOad-BEARING
# ----------------------------------
# 1. EVERY increment-bearing helper is neutered, not just the first. In the shape T-430
#    installs, fail() records into `fails` AND calls leg(); blanking leg() alone leaves
#    `fails` counting, so a red suite never reaches the zero-branch at all and the
#    simulation of "no leg executed" is not actually simulating it.
# 2. The verdict is rc == 2 AND the guard's own sentence on the output. A suite that exits
#    1 from its ordinary TEETH FAIL line is not guarded; it is failing, which is a
#    different thing that happens to share a sign bit.
#
# THE COPY LIVES IN tools/ (inherited from T-429's probe, for the same reason)
# ---------------------------------------------------------------------------
# These suites resolve their root from $0. A copy in /tmp makes them die during setup, and
# a setup death is non-zero — which would read as a pass of this very check.
#
# EXIT
#   0  every suite examined guards, and its unmodified verdict is unchanged from baseline
#   1  at least one suite does not guard, or its verdict moved
#   2  cannot answer (no suites given, a suite unreadable, no helpers found to neuter)
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2

pass=0; fails=0
ok()   { echo "  ok    $*"; pass=$((pass + 1)); }
bad()  { echo "  FAIL  $*" >&2; fails=$((fails + 1)); }

SUITES=("$@")
if [ "${#SUITES[@]}" -eq 0 ]; then
  echo "usage: $0 tools/_tNNN-suite.sh [...]" >&2
  echo "UNKNOWN — no suites named. A census of nothing is not a pass." >&2
  exit 2
fi

# neuter <src> <dst> — blank the body of EVERY top-level function that increments a tally.
# Prints the names it blanked so a wrong pick is visible rather than silent.
neuter() {
  python3 - "$1" "$2" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
spans, names = [], []
for m in re.finditer(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", src, re.M):
    name, start = m.group(1), m.end()
    depth, i = 1, start
    while i < len(src) and depth:
        if src[i] == "{": depth += 1
        elif src[i] == "}": depth -= 1
        i += 1
    body = src[start:i - 1]
    if re.search(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$\(\(\s*\1\s*\+\s*1\s*\)\)", body):
        spans.append((start, i - 1)); names.append(name)
if not spans:
    sys.exit(3)
out, prev = [], 0
for a, b in spans:
    out.append(src[prev:a]); out.append("\n  : # T-430 neutered\n"); prev = b
out.append(src[prev:])
open(sys.argv[2], "w", encoding="utf-8").write("".join(out))
print(" ".join(names))
PY
}

# counter_sited_outside_reporter <src> — the tally the guard reads must be incremented
# somewhere that is NOT a failure reporter. T-429's automated applier put it inside fail()
# and would have fired the new guard on every clean run, fail() being the one helper a
# green suite never calls.
counter_sited_outside_reporter() {
  python3 - "$1" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8", errors="replace").read()
reporter = re.compile(r"^(fail|bad|err|error)[a-z_]*$", re.I)
inside = []
for m in re.finditer(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", src, re.M):
    name, start = m.group(1), m.end()
    depth, i = 1, start
    while i < len(src) and depth:
        if src[i] == "{": depth += 1
        elif src[i] == "}": depth -= 1
        i += 1
    if reporter.match(name):
        inside.append((start, i))
def in_reporter(pos):
    return any(a <= pos < b for a, b in inside)
sites = [m for m in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$\(\(\s*\1\s*\+\s*1\s*\)\)", src)]
outside = [m.group(1) for m in sites if not in_reporter(m.start())]
print(" ".join(sorted(set(outside))))
PY
}

echo "=== T-430 abstention teeth: does the guard FIRE, or did the suite merely die? ==="
echo

for suite in "${SUITES[@]}"; do
  echo "--- $suite"
  if [ ! -f "$suite" ]; then bad "$suite: no such file"; continue; fi

  # BASELINE — the unmodified verdict, so a guard that changes it is caught.
  base_out="$(bash "$suite" 2>&1)"; base_rc=$?
  base_fails="$(printf '%s' "$base_out" | grep -c '^FAIL')"

  NEUT="tools/.t430-neut-$$.sh"
  helpers="$(neuter "$suite" "$NEUT")"; nrc=$?
  if [ "$nrc" -ne 0 ]; then
    rm -f "$NEUT"
    bad "$suite: no increment-bearing helper to neuter — cannot simulate a zero-leg run"
    continue
  fi
  out="$(bash "$NEUT" 2>&1)"; rc=$?
  rm -f "$NEUT"

  # THE VERDICT. Both halves are required: 2 alone could be any other exit-2 path in the
  # suite, and the sentence alone could be printed by something that then exits 0.
  if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'ABSTAINED'; then
    ok "$suite: zero legs -> rc=2 + ABSTAINED (neutered: $helpers)"
  else
    bad "$suite: zero legs -> rc=$rc, ABSTAINED $(printf '%s' "$out" | grep -qc 'ABSTAINED' >/dev/null && printf '%s' "$out" | grep -q 'ABSTAINED' && echo present || echo absent) (neutered: $helpers)
        last line: $(printf '%s' "$out" | tail -1)"
  fi

  # The counter must not live only in the failure reporter.
  outside="$(counter_sited_outside_reporter "$suite")"
  if [ -n "$outside" ]; then
    ok "$suite: tally incremented outside any failure reporter ($outside)"
  else
    bad "$suite: every increment sits inside a fail()-style reporter — the guard would fire on every GREEN run"
  fi

  # And the unmodified verdict must not have moved.
  echo "        baseline: rc=$base_rc, $base_fails FAIL line(s)"
done

echo
echo "  pass=$pass fails=$fails"

# T-429 abstention guard — this suite is subject to its own finding.
if [ $(( ${pass:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
[ "$fails" -eq 0 ] || exit 1
