#!/usr/bin/env bash
# _t509-instrument-sweep.sh — run every teeth script that CAN be run, every time.
#
# WHY THIS EXISTS
#   T-508 wired one teeth script into the bridge suite and noted that it was the only one.
#   Measured here: 24 `tools/*teeth*` scripts exist, 22 had no standing caller, and 19 of
#   them PASS TODAY. "One-shot by design" — the naming convention by which
#   _t451-unwired-guard-census.py excuses every *teeth* / *probe* / *mutation* file from
#   its backlog — is therefore false for 19 of 24. They are re-runnable, hermetic (verified:
#   running all 24 left `git status` byte-identical), and were simply never called.
#
#   PL-192 already stated the principle from T-495: "an instrument excused by its own
#   watchdog's naming convention must be scheduled deliberately." It was applied to the one
#   probe that prompted it. This applies it to the population.
#
# WHAT THE UNWATCHED STATE WAS HIDING, found in the first sweep:
#   _t364-t308-teeth.py's CONTROL leg is red — `maps=24 identical=0 drifted=24`. A pinned
#   baseline decaying silently, inside the instrument whose job is to prove another
#   instrument works. Nobody could have known, because nothing ran it. That is the whole
#   argument for this file.
#
#   CORRECTED 2026-08-15 (T-510), and the correction is instructive. This comment first said
#   "the teeth script's own stored reference shas went stale". It carries no stored shas.
#   `run()` passes REF="3bf37909~1" to _t308, so the comparison is CURRENT BUILD vs A PINNED
#   GIT REF. The first diagnosis came from running _t308 WITHOUT that argument, seeing rc=0,
#   and concluding the gate was fine and the teeth stale — two different comparisons treated
#   as one. Reproduced properly: 24 maps, every one drifted, and every one by EXACTLY +51
#   bytes. That uniformity is the tell. It is T-399 shipping producer identity — one line,
#   18 spaces + `exporter="aef-workflow-designer"` + newline = 51 bytes on every document.
#   So the red is EXPECTED, not a regression: the control's `identical=24` became false the
#   moment T-399 landed, by design. The conclusion "a pinned baseline decayed" survived; the
#   mechanism I published for it was wrong, and I had inferred it from an exit code instead
#   of reading the tool.
#
# WHY NOT A BASELINE FILE
#   There is no pre-existing backlog to grandfather: every script this sweep runs is green
#   as of 2026-08-15, so gating on green is honest and cannot paint the suite red over
#   somebody else's debt (the T-491 rule). The excluded ones are excluded BY NAME WITH A
#   REASON, printed on every run, because a silent exclusion is how a sweep comes to cover
#   less than its name claims.
#
# EXIT CODES
#   0  every non-excluded script passed
#   1  at least one regressed, or an exclusion is stale
#   2  refusal — could not establish a population. Never 1 from a broken scan (T-430).

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT" >&2; exit 2; }

TIMEOUT="${T509_TIMEOUT:-90}"

# ── EXCLUSIONS ────────────────────────────────────────────────────────────────────────
# Each entry is "name|reason". The reason is printed on every run. Not one of these is
# excluded for being inconvenient; each is excluded for a property that makes running it
# here wrong, and each is a candidate for the operator to rule on separately.
EXCLUDE=(
"_t350-teeth.sh|drives real serve-gallery servers (exceeded 90s here) AND its own header records that an earlier mutant, whose safety stub silently failed to apply, DELETED THIS REPOSITORY. Wiring a repo-deleting mutation harness into a suite that runs on every commit is not an agent's call."
"_t351-teeth.sh|drives real shutdown probes with live server PIDs; exceeded 90s. Same family as _t350 and the same operator question."
"_t430-abstention-teeth.sh|PARAMETERISED, not standalone: it takes suite paths as argv and correctly refuses with 'UNKNOWN - no suites named' when given none. Wiring it bare would gate the suite on a usage error, which would look like a finding and be noise."
"_t364-byteid-precondition-teeth.py|exits 2 BY DESIGN, refusing to certify: it states that uid randomness can permute element ids so an 'identical' verdict is not trustworthy until the uid is pinned (T-364). Its abstention IS its output; converting that to a suite failure would punish the honesty."
"_t364-t308-teeth.py|exits 2 with a red control - maps=24 identical=0 drifted=24 - because it compares the current build against a PINNED GIT REF (3bf37909~1, 2026-08-04) that the exporter has moved past. Every map drifts by exactly +51 bytes: T-399's producer-identity line. EXPECTED, not a regression. Not wired because the remedy is not a mere re-pin - moving BASELINE_REF past T-364 makes the injected fixture comparable, so 'unusable' goes to 0 and the teeth leg goes red for the opposite reason. Its docstring prescribes a NEW genuinely-unstable injection, and choosing that is a decision."
)

is_excluded() { # $1 = basename -> prints reason, returns 0 if excluded
  local e
  for e in "${EXCLUDE[@]}"; do
    if [ "${e%%|*}" = "$1" ]; then printf '%s' "${e#*|}"; return 0; fi
  done
  return 1
}

mapfile -t ALL < <(ls tools/ 2>/dev/null | grep -Ei 'teeth' | sort)
if [ "${#ALL[@]}" -eq 0 ]; then
  echo "REFUSING: no tools/*teeth* found. A sweep over nothing is not a pass." >&2
  exit 2
fi

echo "== Instrument sweep (T-509) =="
echo "POPULATION: ${#ALL[@]} teeth script(s) on disk, ${#EXCLUDE[@]} excluded by name below."

# A stale exclusion is a standing exemption for a file that no longer exists — PL-004's
# stale-entry half, the same failure the unwired-guard baseline ratchets against.
stale=0
for e in "${EXCLUDE[@]}"; do
  n="${e%%|*}"
  if [ ! -f "tools/$n" ]; then
    echo "  STALE EXCLUSION: tools/$n is excluded but no longer exists" >&2
    stale=$((stale + 1))
  fi
done
# Checked and exited BEFORE the run loop, deliberately. Two reasons. (1) A stale entry means
# the exclusion list no longer describes the tree, and running a sweep off a list known to be
# wrong produces a verdict about the wrong population. (2) Placed after the loop, this exit
# is UNREACHABLE whenever any script also fails — which is how the first version tested: the
# control went rc=1 off the run-failure branch while the stale branch had never executed, and
# the assertion "rc=1" would have certified a line that never ran (the control-passes-for-the
# -wrong-reason trap T-491 hit).
if [ "$stale" -ne 0 ]; then
  echo "SWEEP FAIL — $stale stale exclusion(s); an exemption outliving its file is an amnesty." >&2
  exit 1
fi

echo
echo "EXCLUDED, and why:"
for e in "${EXCLUDE[@]}"; do
  printf '  %s\n      %s\n' "${e%%|*}" "${e#*|}"
done
echo

pass=0; fail=0; ran=0
declare -a FAILED=()
for f in "${ALL[@]}"; do
  if reason="$(is_excluded "$f")"; then continue; fi
  case "$f" in *.py) runner="python3";; *) runner="bash";; esac
  ran=$((ran + 1))
  if timeout "$TIMEOUT" "$runner" "tools/$f" > /dev/null 2>&1; then
    pass=$((pass + 1))
  else
    rc=$?
    fail=$((fail + 1))
    FAILED+=("$f (rc=$rc)")
  fi
done

if [ "$ran" -eq 0 ]; then
  echo "REFUSING: every script was excluded, so a green result would be about nothing." >&2
  exit 2
fi

echo "RAN $ran, passed $pass, failed $fail"
if [ "$fail" -ne 0 ]; then
  echo >&2
  echo "SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:" >&2
  for x in "${FAILED[@]}"; do echo "  - $x" >&2; done
  echo "Run it directly for its own output. These are hermetic and leave the repo" >&2
  echo "untouched, so a red here is a real regression in the thing it guards." >&2
  exit 1
fi
echo "SWEEP PASS — $pass/$ran runnable teeth scripts green."
exit 0
