#!/usr/bin/env bash
# _t440-drive-empty.sh — drive each in-population instrument to an EMPTY population and
# read what it says. T-440, the execution half.
#
# WHY THIS EXISTS SEPARATELY FROM THE CENSUS
# _t440-zero-population-census.py names who computes an exit code from a tally. It refuses
# to say who is BLIND, because deciding that statically needs interprocedural analysis:
# `_t293-endpoint-reach-cdp.mjs` increments `failures` inside a helper, and whether the
# helper is ever called is decided in another function. A classifier that guesses there
# produces the confident-but-unfounded verdict this whole task is about.
#
# THE DRIVE
# Each instrument's population comes from somewhere nameable — a corpus directory, a
# fixture dir, an argv file list. Point that somewhere at an EMPTY directory and run it.
#   exit 0 + success-shaped output  -> BLIND. Proven, not inferred.
#   non-zero, or an abstention line -> GUARDED against this drive.
#   no knob to empty                -> CANNOT-DRIVE. Reported by name, never as clean.
#
# CANNOT-DRIVE IS A FINDING, NOT A GAP IN THE HARNESS
# An instrument whose population cannot be emptied from outside is one nobody can test for
# this defect — including the person who will inherit it. It is reported in its own bucket
# and counted, so the headline number can never quietly absorb it.
#
# EXIT
#   0  every instrument driven refused to pass on an empty population
#   1  at least one passed on an empty population
#   2  cannot answer — no population, or nothing could be driven at all
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
CENSUS="tools/_t440-zero-population-census.py"
[ -f "$CENSUS" ] || { echo "UNKNOWN — no $CENSUS. Cannot answer."; exit 2; }

ONLY="${1:-}"                       # optional substring filter, for iterating on one file
EMPTY="$(mktemp -d)"; trap 'rm -rf "$EMPTY"' EXIT
mkdir -p "$EMPTY/rendered"          # some probes expect a subdir shape, not just a path

mapfile -t POP < <(T440_LIST=1 python3 "$CENSUS")
[ "${#POP[@]}" -gt 0 ] || { echo "UNKNOWN — census returned an empty population."; exit 2; }

blind=(); guarded=(); undrivable=(); driven=0

# The knob an instrument exposes for its own population. Read from the file, because a
# hard-coded table here would go stale silently — the exact failure mode being audited.
knobs_of() { grep -o -E '\b[A-Z][A-Z0-9_]*_(CORPUS|FIXDIR|DIR|ROOT|SRC)\b' "tools/$1" | sort -u; }

for f in "${POP[@]}"; do
  [ -n "$ONLY" ] && [[ "$f" != *"$ONLY"* ]] && continue

  env_args=(); why=""
  while read -r k; do
    [ -z "$k" ] && continue
    case "$k" in
      *_SRC)  continue ;;           # a source FILE, not a population — emptying it is a
                                    # different experiment (corrupt input, not no input)
      *)      env_args+=("$k=$EMPTY"); why="$why $k" ;;
    esac
  done < <(knobs_of "$f")

  workdir="$PWD"
  if [ "${#env_args[@]}" -eq 0 ]; then
    # second chance: an argv-taking probe is driven with an empty dir as its only argument
    if grep -qE 'process\.argv\.slice|sys\.argv\[1:\]|argparse' "tools/$f"; then
      why=" argv"
    # third: a probe that globs RELATIVE paths has cwd as its population knob. `_norec-
    # verify.py` globs `.tasks/active/*.md` with no env override — run it from an empty
    # directory and its world is empty. This is a real drive, not a trick: any caller
    # invoking it from the wrong directory gets exactly this run.
    elif grep -qE "['\"]\.?(tasks|context|examples|tools|src|docs)/" "tools/$f"; then
      why=" cwd"
      workdir="$EMPTY"
    else
      undrivable+=("$f — exposes no corpus/dir knob, no argv, no relative-path population")
      continue
    fi
  fi

  case "$f" in *.py) run=(python3 "$PWD/tools/$f") ;; *) run=(node "$PWD/tools/$f") ;; esac
  [ "$why" = " argv" ] && run+=("$EMPTY")

  out="$(cd "$workdir" && timeout 90 env "${env_args[@]}" "${run[@]}" 2>&1)"; rc=$?

  if [ "$rc" -eq 124 ]; then
    undrivable+=("$f — timed out at 90s under the empty drive; verdict unknown")
    continue
  fi

  # ---------------------------------------------------------- POSITIVE CONTROL ON THE DRIVE
  # Setting a knob is not the same as emptying a population, and the first version of this
  # harness could not tell the difference. It set GALLERY_DIR for `_serve-gallery-verify.py`
  # — which at :74 builds its own temp dir and overrides GALLERY_DIR for the subprocess it
  # actually measures. The knob was inert, the script ran its normal full run, passed, and
  # was reported BLIND. A green from an instrument that examined everything, recorded as
  # proof it examines nothing: the exact inversion this task is about, committed by the
  # instrument auditing for it.
  #
  # So before scoring an exit 0, prove the knob is LOAD-BEARING: run again with the same
  # knob pointing at a POISONED population — one item that must produce a different result.
  # Identical output under empty and poisoned means the knob changes nothing, so nothing
  # was driven and the run says nothing about blindness.
  #
  # Note this control also settles the ambiguous case correctly. For a genuinely blind
  # instrument, empty and poisoned DIFFER (poisoned yields a finding), so it scores BLIND.
  # For an inert knob they MATCH. Output-equality alone would have conflated the two.
  poison="$(mktemp -d)"; mkdir -p "$poison/rendered"
  printf 'not a valid fixture\n' > "$poison/_t440-poison.bpmn"
  printf 'not a valid fixture\n' > "$poison/rendered/_t440-poison.bpmn"
  mkdir -p "$poison/.tasks/active"
  printf -- '---\nid: T-000\n---\n## Acceptance Criteria\n### Human\n- [ ] unverified\n' \
    > "$poison/.tasks/active/T-000-t440-poison.md"
  p_env=(); for kv in "${env_args[@]}"; do p_env+=("${kv%%=*}=$poison"); done
  p_work="$workdir"; [ "$workdir" = "$EMPTY" ] && p_work="$poison"
  p_run=("${run[@]}"); [ "$why" = " argv" ] && p_run=("${run[@]:0:${#run[@]}-1}" "$poison")
  pout="$(cd "$p_work" && timeout 90 env "${p_env[@]}" "${p_run[@]}" 2>&1)"; prc=$?
  rm -rf "$poison"

  # Compare a SIGNATURE, not the text. Text comparison — even with digits normalized —
  # is defeated by output that varies for reasons unrelated to the population:
  # `_serve-gallery-verify.py` binds ephemeral ports and prints PIDs, so two runs of the
  # SAME configuration already differ. That made an inert knob look load-bearing and put
  # a fully-executed green in the BLIND column.
  #
  # The signature is what a population change must move and noise cannot: the exit code,
  # how many lines were emitted, and how many of them carried a per-leg verdict. A port
  # number changing moves none of the three. One fewer leg examined moves at least two.
  sig() { local t="$1"; printf '%s|%s|%s' "$2" "$(wc -l <<<"$t")" "$(grep -ciE '\b(pass|fail|ok|error)\b' <<<"$t")"; }
  if [ "$(sig "$out" "$rc")" = "$(sig "$pout" "$prc")" ]; then
    undrivable+=("$f — knob '${why# }' is inert: empty and poisoned populations give the same rc/line/verdict signature (rc=$rc). Nothing was driven.")
    continue
  fi

  driven=$((driven + 1))

  # Success-shaped: exit 0 AND nothing that reads as an abstention or an error. Exit 0
  # alone is not enough — a probe may exit 0 while printing "cannot answer", and calling
  # that blind would be the same mention-vs-instance mistake one level out.
  if [ "$rc" -eq 0 ] && ! grep -qiE 'abstain|unknown|cannot|no corpus|empty|nothing' <<<"$out"; then
    blind+=("$f — exit 0 on an empty population (knob:${why# }) | $(head -1 <<<"$out" | cut -c1-70)")
  else
    guarded+=("$f — rc=$rc (knob:${why# })")
  fi
done

echo "=== T-440 drive: does an empty population produce a green? ==="
echo
echo "  population          ${#POP[@]}  (from $CENSUS)"
[ -n "$ONLY" ] && echo "  filtered to         '$ONLY'"
echo "  driven              $driven"
echo "  BLIND               ${#blind[@]}"
echo "  guarded             ${#guarded[@]}"
echo "  CANNOT-DRIVE        ${#undrivable[@]}"
echo

if [ "${#undrivable[@]}" -gt 0 ]; then
  echo "CANNOT-DRIVE — no way to empty the population from outside. Not a clean bill:"
  printf '  %s\n' "${undrivable[@]}"
  echo
fi

if [ "${#blind[@]}" -gt 0 ]; then
  echo "BLIND — reported success having examined nothing. Measured, not inferred:"
  printf '  %s\n' "${blind[@]}"
  echo
fi

if [ "$driven" -eq 0 ]; then
  echo "ABSTAINED — nothing could be driven, so this run measured nothing. Not a pass." >&2
  exit 2
fi

if [ "${#blind[@]}" -gt 0 ]; then
  echo "FINDINGS: ${#blind[@]} of $driven driven instrument(s) pass on an empty population."
  exit 1
fi
echo "PASS — all $driven driven instrument(s) refused to report success on an empty"
echo "  population. ${#undrivable[@]} could not be driven and are NOT covered by that sentence."
exit 0
