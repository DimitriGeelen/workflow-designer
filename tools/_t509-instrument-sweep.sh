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
#   0  every non-excluded script ran and passed
#   1  at least one REGRESSED, or an exclusion is stale
#   2  refusal — could not establish a population. Never 1 from a broken scan (T-430).
#   3  INCOMPLETE (T-548) — no regression, but at least one instrument did not finish
#      (rc=124) or declined to certify (rc=2). Distinct from 1 because "it broke" and
#      "I never found out" are different claims and only one of them sends a reader
#      looking for a bug. Still non-zero: an uncovered instrument is not a green.

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

# ── CLASSIFICATION (T-548) ────────────────────────────────────────────────────────────
# Until T-548 every non-zero exit was counted as `fail` and announced as "an instrument
# that passed on 2026-08-15 no longer does … a red here is a real regression in the thing
# it guards". Two exit codes make that sentence false, and both were being said anyway:
#
#   124  GNU timeout's code. The instrument DID NOT FINISH. Nothing regressed in the thing
#        it guards — the sweep never found out either way. T-543 measured the case that
#        exposed it: _t525-fabric-coverage-teeth.py costs 86.04s against this 90s cap and
#        passes 7/7 standalone, so it crosses whenever the machine is busy, and the reader
#        was sent hunting a fabric-coverage bug that does not exist.
#
#     2  ABSTENTION. The exclusion list above already argues this, for one file, by name:
#        _t364 "exits 2 BY DESIGN, refusing to certify … converting that to a suite failure
#        would punish the honesty." That reasoning is about a PROPERTY and was written into
#        an exemption keyed on a FILENAME, so every other probe that declines to certify was
#        still recorded as a regression. T-509's own shape, in T-509's own tool — which is
#        why this is fixed in the classifier rather than by adding two more names.
#
# The three-way exit code exists so a caller can tell them apart without parsing prose.
# An incomplete sweep is NOT reported as green: exit 3 still fails the suite. The defect
# being repaired is the MISLABEL, not the redness — a probe that cannot finish inside its
# budget is a real condition needing attention, just a different one from a regression.
pass=0; ran=0
declare -a REGRESSED=() TIMEDOUT=() ABSTAINED=() TIGHT=()
for f in "${ALL[@]}"; do
  if reason="$(is_excluded "$f")"; then continue; fi
  case "$f" in *.py) runner="python3";; *) runner="bash";; esac
  ran=$((ran + 1))
  started=$SECONDS
  timeout "$TIMEOUT" "$runner" "tools/$f" > /dev/null 2>&1
  rc=$?
  elapsed=$((SECONDS - started))
  case "$rc" in
    0)   pass=$((pass + 1));;
    124) TIMEDOUT+=("$f (did not finish within ${TIMEOUT}s)");;
    2)   ABSTAINED+=("$f (rc=2, declined to certify)");;
    *)   REGRESSED+=("$f (rc=$rc)");;
  esac
  # Headroom, reported on GREEN runs too. _t525 sat at 86s of a 90s budget — 95.6% — and
  # nothing said so until the run it first crossed, at which point it presented as a
  # regression in fabric coverage. A budget that is nearly spent is visible in advance or
  # it is not visible at all; this is the leading indicator the old loop threw away by
  # never measuring elapsed time.
  if [ "$rc" -eq 0 ] && [ $((elapsed * 100)) -ge $((TIMEOUT * 75)) ]; then
    TIGHT+=("$f (${elapsed}s of ${TIMEOUT}s budget)")
  fi
done

if [ "$ran" -eq 0 ]; then
  echo "REFUSING: every script was excluded, so a green result would be about nothing." >&2
  exit 2
fi

echo "RAN $ran, passed $pass, regressed ${#REGRESSED[@]}, did-not-finish ${#TIMEDOUT[@]}, abstained ${#ABSTAINED[@]}"

if [ "${#TIGHT[@]}" -ne 0 ]; then
  echo
  echo "HEADROOM WARNING — passed, but close to the ${TIMEOUT}s cap. These will start"
  echo "reporting as did-not-finish under load before they report anything else:"
  for x in "${TIGHT[@]}"; do echo "  - $x"; done
fi

# The uncovered section prints BEFORE the regression exit, and this ordering is load-bearing.
# The first version exited 1 inside the regression branch, so a timeout occurring in the same
# run as a regression was never mentioned — the louder finding swallowed the instrument nobody
# heard from, which is a quieter version of the same defect this task exists to fix. Caught by
# leg 5 of _t548's teeth on their first run, not by reading the code back.
if [ "${#TIMEDOUT[@]}" -ne 0 ] || [ "${#ABSTAINED[@]}" -ne 0 ]; then
  echo >&2
  if [ "${#REGRESSED[@]}" -ne 0 ]; then
    echo "SWEEP INCOMPLETE — separately from the regression(s) below, the sweep did not" >&2
    echo "cover everything it names:" >&2
  else
    echo "SWEEP INCOMPLETE — no regression found, but the sweep did not cover everything" >&2
    echo "it names. This is not a green and it is not a regression report:" >&2
  fi
  for x in "${TIMEDOUT[@]}"; do
    echo "  - DID NOT FINISH: $x" >&2
    echo "      Nothing is claimed about what it guards — it was killed, not failed." >&2
    echo "      Raising T509_TIMEOUT buys headroom the instrument will consume again if" >&2
    echo "      its cost tracks a growing tree; measure the cost before moving the cap." >&2
  done
  for x in "${ABSTAINED[@]}"; do
    echo "  - ABSTAINED: $x" >&2
    echo "      It refused to certify. Its abstention IS its output; read that output" >&2
    echo "      rather than treating this as a regression in what it guards." >&2
  done
fi

if [ "${#REGRESSED[@]}" -ne 0 ]; then
  echo >&2
  echo "SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:" >&2
  for x in "${REGRESSED[@]}"; do echo "  - $x" >&2; done
  echo "Run it directly for its own output. These are hermetic and leave the repo" >&2
  echo "untouched, so a red here is a real regression in the thing it guards." >&2
  exit 1
fi

if [ "${#TIMEDOUT[@]}" -ne 0 ] || [ "${#ABSTAINED[@]}" -ne 0 ]; then
  exit 3
fi

echo "SWEEP PASS — $pass/$ran runnable teeth scripts green."
exit 0
