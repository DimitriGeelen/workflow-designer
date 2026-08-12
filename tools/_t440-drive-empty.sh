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
# THE KNOB IS THE TREE, AND FINDING THAT OUT COST A WHOLE SWEEP
# The first version drove instruments through env vars, argv and cwd. It could drive 2 of
# 73 and reported the other 71 as CANNOT-DRIVE — a measurement that answers almost nothing.
# The reason is in the probes themselves: `const REPO = join(HERE, '..')`. Their population
# is resolved from THEIR OWN FILE PATH, so no environment variable can move it. What moves
# it is which copy of the repository they are executed from.
#
# So the drive is: build a HOLLOW copy of the tree with every population directory emptied,
# and run each instrument out of that copy. `REPO` then points at the hollow tree, the
# corpus globs return nothing, and whatever the instrument prints is what it prints when
# it has examined nothing.
#
# THE POSITIVE CONTROL, AND WHY IT IS NOT OPTIONAL
# Emptying a directory is not the same as emptying an instrument's population — the
# instrument may not read that directory at all. Without a control, "it passed" is
# unreadable: it could mean blind, or it could mean the drive missed. The first harness
# set GALLERY_DIR on `_serve-gallery-verify.py`, which overrides GALLERY_DIR itself at :74,
# ran the script's normal full pass, and filed that green as proof of blindness.
#
# So every instrument is run TWICE — once from the hollow tree, once from a POISONED copy
# whose population directories hold exactly one item that must produce a different result.
# Identical rc/line/verdict signatures mean the drive moved nothing, and the run is
# reported as CANNOT-DRIVE rather than scored. Signatures rather than text, because
# `_serve-gallery-verify.py` binds ephemeral ports and prints PIDs: two runs of the SAME
# configuration already differ, which made an inert knob look load-bearing.
#
# CANNOT-DRIVE IS A FINDING, NOT A GAP IN THE HARNESS
# An instrument whose population cannot be emptied from outside is one nobody can test for
# this defect — including whoever inherits it. It is counted in its own bucket so the
# headline can never quietly absorb it.
#
# EXIT
#   0  every instrument driven refused to pass on an empty population
#   1  at least one passed on an empty population
#   2  cannot answer — no population, or nothing could be driven at all
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
REPO="$PWD"
CENSUS="tools/_t440-zero-population-census.py"
[ -f "$CENSUS" ] || { echo "UNKNOWN — no $CENSUS. Cannot answer."; exit 2; }

ONLY="${1:-}"
PER_RUN_TIMEOUT="${T440_TIMEOUT:-90}"

# Directories that hold a population an instrument can range over. Emptying these is the
# drive; anything not listed here is a population this harness cannot empty, which shows
# up honestly as an inert-knob CANNOT-DRIVE rather than as a pass.
POP_DIRS=(
  "examples/aef-processes/rendered"
  "examples/aef-processes"
  "tests/fixtures/aef-bpmn"
  "tests/fixtures"
  ".tasks/active"
  ".tasks/completed"
  ".context/episodic"
)

STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
HOLLOW="$STAGE/hollow"; POISON="$STAGE/poison"

echo "building hollow + poisoned copies of the tree ..." >&2
for dest in "$HOLLOW" "$POISON"; do
  cp -a "$REPO" "$dest" 2>/dev/null || { echo "UNKNOWN — could not copy the tree. Cannot answer."; exit 2; }
  rm -rf "$dest/.git"                       # keep the copies small; git-reading probes
                                            # will fail loudly there, which is not a pass
  # Delete FILES, keep the directory tree. Removing directories instead looked equivalent
  # and was not: emptying `tests/fixtures` at depth 1 deletes `tests/fixtures/aef-bpmn`,
  # so the poison written there afterwards landed nowhere, every control came back
  # identical, and all five smoke-test instruments were filed CANNOT-DRIVE. A drive that
  # silently fails to place its own control reports the same thing as a sealed instrument.
  for d in "${POP_DIRS[@]}"; do
    [ -d "$dest/$d" ] || continue
    find "$dest/$d" -type f -delete 2>/dev/null
  done
done
# The poisoned copy holds exactly one item per population — enough that any instrument
# actually reading that population produces a different result than it does on the hollow.
# EVERY directory under a population, not just its top. Dropping one poison file at
# `tests/fixtures/` leaves `tests/fixtures/lane-provenance/` empty in BOTH copies, so an
# instrument reading that subdirectory produces identical signatures and is filed as
# sealed when in fact the control never reached it. Under-placed controls do not report
# as under-placed; they report as "nothing to see".
for d in "${POP_DIRS[@]}"; do
  [ -d "$POISON/$d" ] || continue
  while IFS= read -r sub; do
    case "$d" in
      *.tasks*)   printf -- '---\nid: T-000\nname: "t440 poison"\n---\n## Acceptance Criteria\n### Human\n- [ ] unverified\n' \
                    > "$sub/T-000-t440-poison.md" ;;
      *episodic*) printf -- 'task_id: T-000\nsummary: t440 poison\n' > "$sub/T-000.yaml" ;;
      *)          printf -- 'not a well-formed bpmn document\n' > "$sub/_t440-poison.bpmn"
                  printf -- 'not: [a, well, formed\n'            > "$sub/_t440-poison.yaml"
                  # ...and the SOURCE spelling. `*.yaml` is not `*.workflow.yaml`, and an
                  # instrument whose population is the latter saw no control at all: T-447
                  # made bake-clean-layout refuse on an empty corpus, and this harness then
                  # reported BLIND 0 over driven 0 — the repair looking identical to a
                  # sealed instrument, which is PL-160 committed by the file that records
                  # PL-160. The basename matches the .bpmn poison above on purpose, so a
                  # tool checking source↔rendered correspondence sees a COMPLETE corpus of
                  # one rather than a second flavour of emptiness.
                  printf -- 'not: [a, well, formed\n'            > "$sub/_t440-poison.workflow.yaml" ;;
    esac
  done < <(find "$POISON/$d" -type d)
done

mapfile -t POP < <(T440_LIST=1 python3 "$CENSUS")
[ "${#POP[@]}" -gt 0 ] || { echo "UNKNOWN — census returned an empty population."; exit 2; }

blind=(); guarded=(); undrivable=(); driven=0

# What a population change must move and port/PID noise cannot: the exit code, how many
# lines were emitted, and how many carried a per-leg verdict.
sig() { printf '%s|%s|%s' "$2" "$(wc -l <<<"$1")" "$(grep -ciE '\b(pass|fail|ok|error)\b' <<<"$1")"; }

for f in "${POP[@]}"; do
  [ -n "$ONLY" ] && [[ "$f" != *"$ONLY"* ]] && continue
  case "$f" in *.py) runner=python3 ;; *) runner=node ;; esac

  h_out="$(cd "$HOLLOW" && timeout "$PER_RUN_TIMEOUT" "$runner" "$HOLLOW/tools/$f" 2>&1)"; h_rc=$?
  if [ "$h_rc" -eq 124 ]; then
    undrivable+=("$f — timed out at ${PER_RUN_TIMEOUT}s on the hollow tree; verdict unknown")
    continue
  fi
  p_out="$(cd "$POISON" && timeout "$PER_RUN_TIMEOUT" "$runner" "$POISON/tools/$f" 2>&1)"; p_rc=$?
  if [ "$p_rc" -eq 124 ]; then
    undrivable+=("$f — timed out at ${PER_RUN_TIMEOUT}s on the poisoned tree; control inconclusive")
    continue
  fi

  if [ "$(sig "$h_out" "$h_rc")" = "$(sig "$p_out" "$p_rc")" ]; then
    undrivable+=("$f — emptying the tree's populations changes nothing (both rc=$h_rc, same signature). Its population is not in the directories this harness can empty.")
    continue
  fi

  driven=$((driven + 1))

  # Success-shaped: exit 0 AND nothing that reads as an abstention. Exit 0 alone is not
  # enough — an instrument may exit 0 while printing "cannot answer", and scoring that as
  # blind would be the mention-vs-instance mistake one level out.
  if [ "$h_rc" -eq 0 ] && ! grep -qiE 'abstain|unknown|cannot|no corpus|corpus empty|nothing (was )?(measured|examined)' <<<"$h_out"; then
    blind+=("$f — exit 0 on an emptied tree | $(grep -viE '^\s*$' <<<"$h_out" | tail -1 | cut -c1-80)")
  else
    guarded+=("$f — rc=$h_rc on an emptied tree")
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
  echo "CANNOT-DRIVE — the drive provably moved nothing, so these are NOT covered by any"
  echo "verdict below. Not a clean bill:"
  printf '  %s\n' "${undrivable[@]}"
  echo
fi

if [ "${#guarded[@]}" -gt 0 ]; then
  echo "guarded — refused to report success on an emptied tree:"
  printf '  %s\n' "${guarded[@]}"
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
