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
#   RESOLVED 2026-09-01 (T-663) — the exclusion below is GONE and the script is wired.
#   The control no longer pins a baseline at all (it self-compares one build, so it cannot
#   decay), and the injection moved from a document to a build via T308_OLD_SRC, because
#   after T-364 no real document is unstable any more. Teeth 8/8. Left standing as the
#   record of what the unwatched state hid:
#
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
# EXIT CODES (this sweep's own)
#   0  every non-excluded script ran and passed
#   1  at least one REGRESSED or reported a DEAD CONTROL, or an exclusion is stale
#   2  refusal — could not establish a population. Never 1 from a broken scan (T-430).
#   3  INCOMPLETE (T-548) — no regression, but at least one instrument did not finish
#      (rc=124) or declined to certify (rc=2). Distinct from 1 because "it broke" and
#      "I never found out" are different claims and only one of them sends a reader
#      looking for a bug. Still non-zero: an uncovered instrument is not a green.
#
# PROBE EXIT CODES (what a teeth script tells THIS file)
#   0  passed          1  a leg failed — a regression in the thing it guards
#   2  ABSTAINED       — declined to certify. Parameterised and run without its input.
#   4  DEAD CONTROL    — the UNMUTATED control leg failed, so no mutation below it proves
#                        anything. The guard itself is broken. T-666.
# 124  did not finish within the cap.

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
"_t423-additive-export-teeth.py|PARAMETERISED, same shape as _t430: it needs T423_EXPORT_DIR pointing at a directory of REAL browser-produced exports, because it damages an export and requires the guard to notice - damaging a hand-written stand-in would test the stand-in. Run bare it correctly REFUSES (rc 2) rather than inventing an input. It IS wired: tests/run-bridge-tests.sh runs the cdp probe with T423_EXPORT_OUT and hands the directory straight to these teeth in the same leg, so the sweep excluding it costs no coverage."
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
#     4  DEAD CONTROL (T-666). Split out of 2, because 2 was carrying two opposite claims.
#        An honest refusal and a dead control are not the same event and must not read the
#        same. `_t358-teeth.py` guarded T-358's lane-fabrication diagnosis and was dead for
#        six days (T-665): it was never excluded, it ran on every sweep, and every one of
#        those runs printed "ABSTAINED … rather than treating this as a regression in what
#        it guards" — advice that is correct for a parameterised probe and exactly backwards
#        for a broken one. Nothing regressed in what it guards; the guard died, which is
#        strictly worse, and the reader was told to relax about it.
#
#        So DEAD exits 1, not 3. Uncovered ground (124, 2) is "I never found out". A dead
#        control is "I found out, and the instrument is broken" — a finding needing a fix,
#        which is what 1 means here. It does NOT get the regression sentence: a dead control
#        says nothing whatsoever about the thing it guards, so claiming a regression there
#        would be the mislabel running in the other direction.
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
# T-551: capture each probe's output instead of discarding it.
#
# This loop used to redirect every probe to /dev/null, so the only thing surviving a run was
# an integer. That was tolerable while the sweep's job was "did anything regress". It stopped
# being tolerable once three instruments started failing ONLY inside a full run — _t523
# (rc=1), _t366 (rc=2) and _t344's leg 2 — each of them green on every standalone attempt
# afterwards. Three failures, and not one byte kept from any of them, while _t523 alone prints
# nine named legs when you run it by hand.
#
# The cost of the redirect was never speed. It was that the sweep could say WHICH probe failed
# and never WHY, so every occurrence of an intermittent had to be re-hunted from scratch and
# none of them could be.
#
# Captured for passing probes too, and dropped only once the verdict is known: a probe that
# passes while printing something alarming would otherwise be invisible by construction, which
# is the same blind spot one level down.
CAPDIR="$(mktemp -d "${TMPDIR:-/tmp}/t509-capture-XXXXXX")"
trap 'rm -rf "$CAPDIR"' EXIT INT TERM
CAPTURE_LINES="${T509_CAPTURE_LINES:-30}"

pass=0; ran=0
declare -a REGRESSED=() TIMEDOUT=() ABSTAINED=() DEAD=() TIGHT=()
declare -A CAPFILE=()

# Print what a probe actually said, bounded. The tail is the right end to keep: these scripts
# print per-leg lines followed by a summary, so the last lines carry both the verdict and the
# legs that produced it. Truncation is STATED — a silently clipped report is how you end up
# reading the wrong evidence confidently.
emit_capture() {
  local name="$1" cap="${CAPFILE[$1]:-}"
  if [ -z "$cap" ] || [ ! -s "$cap" ]; then
    echo "      (no output captured — the probe printed nothing before it exited)" >&2
    return
  fi
  local total; total=$(wc -l < "$cap")
  if [ "$total" -gt "$CAPTURE_LINES" ]; then
    echo "      --- last $CAPTURE_LINES of $total lines from $name ---" >&2
  else
    echo "      --- output from $name ($total line(s)) ---" >&2
  fi
  tail -n "$CAPTURE_LINES" "$cap" | sed 's/^/      | /' >&2
}

for f in "${ALL[@]}"; do
  if reason="$(is_excluded "$f")"; then continue; fi
  case "$f" in *.py) runner="python3";; *) runner="bash";; esac
  ran=$((ran + 1))
  cap="$CAPDIR/$f.out"
  CAPFILE["$f"]="$cap"
  started=$SECONDS
  timeout "$TIMEOUT" "$runner" "tools/$f" > "$cap" 2>&1
  rc=$?
  elapsed=$((SECONDS - started))
  case "$rc" in
    0)   pass=$((pass + 1)); rm -f "$cap";;
    124) TIMEDOUT+=("$f (did not finish within ${TIMEOUT}s)");;
    2)   ABSTAINED+=("$f (rc=2, declined to certify)");;
    4)   DEAD+=("$f (rc=4, its own control leg failed)");;
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

echo "RAN $ran, passed $pass, regressed ${#REGRESSED[@]}, dead-control ${#DEAD[@]}, did-not-finish ${#TIMEDOUT[@]}, abstained ${#ABSTAINED[@]}"

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
  if [ "${#REGRESSED[@]}" -ne 0 ] || [ "${#DEAD[@]}" -ne 0 ]; then
    echo "SWEEP INCOMPLETE — separately from the finding(s) below, the sweep did not" >&2
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
    # What it managed to print before the kill localises WHERE it was slow, which is the
    # first thing anyone measuring the cost needs and the thing a bare rc=124 withholds.
    emit_capture "${x%% *}"
  done
  for x in "${ABSTAINED[@]}"; do
    echo "  - ABSTAINED: $x" >&2
    echo "      It refused to certify. Its abstention IS its output; read that output" >&2
    echo "      rather than treating this as a regression in what it guards." >&2
    # And here it is, rather than an instruction to go and find it. An abstention whose
    # reasoning is discarded is indistinguishable from a probe that said nothing at all.
    emit_capture "${x%% *}"
  done
fi

# DEAD prints before REGRESSED and neither one exits: the combined exit is at the bottom.
# Same argument as the INCOMPLETE ordering above — an exit inside the first branch makes the
# second unreachable in exactly the runs where both are true (PL-203), and a run with both a
# regression and a dead guard is the run where you most need to see both.
if [ "${#DEAD[@]}" -ne 0 ]; then
  echo >&2
  echo "SWEEP FAIL — an instrument's own CONTROL leg failed. It is not reporting on what" >&2
  echo "it guards; it is broken, and every leg below its control proves nothing:" >&2
  for x in "${DEAD[@]}"; do
    echo "  - DEAD CONTROL: $x" >&2
    echo "      Deliberately NOT filed as an abstention. A parameterised probe that" >&2
    echo "      declines is doing its job; this one cannot do its job. Nothing is claimed" >&2
    echo "      here about the thing it guards — that claim is exactly what died." >&2
    emit_capture "${x%% *}"
  done
fi

if [ "${#REGRESSED[@]}" -ne 0 ]; then
  echo >&2
  echo "SWEEP FAIL — an instrument that passed on 2026-08-15 no longer does:" >&2
  for x in "${REGRESSED[@]}"; do
    echo "  - $x" >&2
    emit_capture "${x%% *}"
  done
  # KEEP THIS SENTENCE ON ONE LINE. Two probes read the sweep's SOURCE for the literal phrase
  # "a real regression in the thing it guards" and assert it is withheld from timeouts and
  # abstentions — _t548-sweep-classification-teeth.py refuses outright if it cannot find it,
  # and _t364-tie-guard-teeth.py goes red. Splitting it across echo calls for line width broke
  # both within one run of writing this comment's own commit.
  echo "These are hermetic and leave the repo untouched, so a red here is a real regression in the thing it guards." >&2
  echo "Its own output is above — and note that for the class of probes that fail only" >&2
  echo "inside a full run, re-running it directly is precisely what does NOT reproduce" >&2
  echo "it, so the capture above may be the only account this failure will ever have (T-551)." >&2
fi

if [ "${#REGRESSED[@]}" -ne 0 ] || [ "${#DEAD[@]}" -ne 0 ]; then
  exit 1
fi

if [ "${#TIMEDOUT[@]}" -ne 0 ] || [ "${#ABSTAINED[@]}" -ne 0 ]; then
  exit 3
fi

echo "SWEEP PASS — $pass/$ran runnable teeth scripts green."
exit 0
