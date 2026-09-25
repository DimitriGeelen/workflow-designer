#!/bin/bash
# T-850 — teeth for the sweep's subset selection.
#
# WHY A FIXTURE ROOT. The real sweep costs ~11 minutes over 65 instruments, which is the
# very problem this feature exists to fix; a test suite that invoked it would inherit the
# defect. The sweep resolves its own root as dirname($0)/.., so a COPY of it inside a
# throwaway tools/ directory of tiny stub instruments exercises the real code against a
# population of 8 in under a second. The 4 excluded names must exist as stubs too, or the
# stale-exclusion check refuses before the run loop — that check is load-bearing and is
# not being worked around, it is being satisfied honestly.
#
# THE CONTROL SET IS THE POINT. `--mutation` strips the T-850 blocks and requires the new
# cases to go red WHILE the pre-existing behaviour (full run, classification, refusal on an
# empty population) stays green. Without that second half, a mutated copy that merely fails
# to start reads as a successful kill — measured on T-849 the same day, where all 14 cases
# went red because the copy could not source its own library.

set -uo pipefail
SWEEP="${SWEEP:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/tools/_t509-instrument-sweep.sh}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t850.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
NEW_CASES="list_runs_nothing list_names_population only_selects_one only_two_patterns only_equals_form only_no_match_refuses only_needs_a_pattern unknown_flag_refused filtered_says_not_a_sweep filtered_omits_full_sentence filtered_still_classifies help_exits_zero"
CONTROL_CASES="full_run_emits_sweep_sentence full_run_classifies_all_four empty_population_refused"

# ── mutation mode ─────────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--mutation" ]; then
    MUT="$WORK/_t509-mutated.sh"
    python3 - "$SWEEP" "$MUT" <<'PYEOF'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
before = len(t)
# Remove the three T-850 additions: the argument parser, the --list/--only block, and the
# partial summary branch. Each is removed by its own anchors so a rename fails loudly here
# rather than producing a copy that is quietly still patched.
cuts = [
    (r"\n# ── SUBSET SELECTION \(T-850\).*?\n\[ \"\$\{#ONLY\[@\]\}\" -gt 0 \] && FILTERED=1\n", "parser"),
    (r"if \[ \"\$LIST_ONLY\" -eq 1 \]; then.*?coverage statement: it cannot tell you the corpus is clean, only these are\.\"\nfi\n\n", "list/only"),
    (r"if \[ \"\$FILTERED\" -eq 1 \]; then\n  # Deliberately a DIFFERENT SENTENCE.*?NOT a sweep\"\nelse\n", "summary-branch"),
]
for pat, name in cuts:
    t, n = re.subn(pat, "\n" if name == "parser" else "", t, count=1, flags=re.S)
    if n != 1:
        sys.exit(f"mutation anchor not found: {name} — the T-850 block was renamed or removed")
# the summary branch removal leaves a dangling `fi` after the RAN line
t = t.replace('did-not-finish ${#TIMEDOUT[@]}, abstained ${#ABSTAINED[@]}"\nfi\n',
              'did-not-finish ${#TIMEDOUT[@]}, abstained ${#ABSTAINED[@]}"\n', 1)
# FILTERED/LIST_ONLY are gone, so the `set -u` references must go with them
t = t.replace('if [ "$FILTERED" -eq 1 ]; then\n', 'if false; then\n')
if len(t) >= before:
    sys.exit("mutation removed nothing")
open(dst, 'w').write(t)
PYEOF
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutated copy"; exit 1; }
    bash -n "$MUT" || { echo "MUTATION SETUP FAILED: mutated copy does not parse"; exit 1; }
    echo "=== T-850 MUTATION RUN (subset selection stripped) ==="
    out=$(SWEEP="$MUT" bash "${BASH_SOURCE[0]}" 2>&1)
    printf '%s\n' "$out" | sed 's/^/  | /'
    echo
    broken=""
    for c in $CONTROL_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" || broken="$broken $c"
    done
    if [ -n "$broken" ]; then
        echo "MUTATION SETUP BROKEN — cases unrelated to the feature also failed:$broken"
        echo "The stripped copy is not merely unpatched, it does not work. Every red in this"
        echo "run is a false red and the mutation proves nothing."
        exit 1
    fi
    survivors=""
    for c in $NEW_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" && survivors="$survivors $c"
    done
    if [ -n "$survivors" ]; then
        echo "MUTATION FAILED — these cases pass WITHOUT the feature:$survivors"
        exit 1
    fi
    echo "MUTATION OK — the 3 control cases stayed green, so the stripped sweep still runs;"
    echo "every case that depends on subset selection went red, so they measure it."
    exit 0
fi

PASS=0; FAIL=0

ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

# ── fixture ───────────────────────────────────────────────────────────────────────────
FIX="$WORK/fixroot"
mkdir -p "$FIX/tools"
cp "$SWEEP" "$FIX/tools/_t509-instrument-sweep.sh"
chmod +x "$FIX/tools/_t509-instrument-sweep.sh"
mk() { printf '%s\n' '#!/bin/bash' "$2" > "$FIX/tools/$1"; chmod +x "$FIX/tools/$1"; }
# One stub per exit code the sweep classifies, plus a marker write so "did it run?" is
# observable rather than inferred from a count.
mk _t900-ok-teeth.sh       'touch "$T850_MARK/t900.ran"; exit 0'
mk _t901-red-teeth.sh      'touch "$T850_MARK/t901.ran"; exit 1'
mk _t902-abstain-teeth.sh  'exit 2'
mk _t903-dead-teeth.sh     'exit 4'
# The four names the sweep excludes must exist or the stale-exclusion check fires first.
for n in _t350-teeth.sh _t351-teeth.sh _t430-abstention-teeth.sh _t423-additive-export-teeth.py; do
  mk "$n" 'exit 0'
done

MARK="$WORK/marks"; mkdir -p "$MARK"
run() { rm -rf "$MARK"; mkdir -p "$MARK"; T850_MARK="$MARK" bash "$FIX/tools/_t509-instrument-sweep.sh" "$@" 2>&1; }
rc_of() { rm -rf "$MARK"; mkdir -p "$MARK"; T850_MARK="$MARK" bash "$FIX/tools/_t509-instrument-sweep.sh" "$@" >/dev/null 2>&1; echo $?; }

echo "=== T-850 sweep subset teeth ==="
echo "sweep under test: $SWEEP"
echo

# ── CONTROL CASES: behaviour that must be identical with and without the feature ──────
out=$(run)
if printf '%s' "$out" | grep -q '^RAN 4, passed 1,'; then ok full_run_emits_sweep_sentence
else bad full_run_emits_sweep_sentence "no 'RAN 4, passed 1,' line: $(printf '%s' "$out" | grep '^RAN' | head -1)"; fi

if printf '%s' "$out" | grep -q '^RAN 4, passed 1, regressed 1, dead-control 1, did-not-finish 0, abstained 1$'; then
  ok full_run_classifies_all_four
else bad full_run_classifies_all_four "classification changed: $(printf '%s' "$out" | grep '^RAN' | head -1)"; fi

# Every stub excluded -> the sweep must refuse rather than report a clean run over nothing.
EMPTY="$WORK/emptyroot"; mkdir -p "$EMPTY/tools"
cp "$SWEEP" "$EMPTY/tools/_t509-instrument-sweep.sh"
for n in _t350-teeth.sh _t351-teeth.sh _t430-abstention-teeth.sh _t423-additive-export-teeth.py; do
  printf '#!/bin/bash\nexit 0\n' > "$EMPTY/tools/$n"; chmod +x "$EMPTY/tools/$n"
done
eout=$(bash "$EMPTY/tools/_t509-instrument-sweep.sh" 2>&1); erc=$?
if [ "$erc" -ne 0 ] && printf '%s' "$eout" | grep -q 'REFUSING: every script was excluded'; then
  ok empty_population_refused
else bad empty_population_refused "expected refusal, rc=$erc: $(printf '%s' "$eout" | tail -1)"; fi

# ── NEW CASES ─────────────────────────────────────────────────────────────────────────
out=$(run --list)
if [ ! -e "$MARK/t900.ran" ] && [ ! -e "$MARK/t901.ran" ]; then ok list_runs_nothing
else bad list_runs_nothing "--list executed an instrument (marker present)"; fi

if printf '%s' "$out" | grep -q 'would-run _t900-ok-teeth.sh' && printf '%s' "$out" | grep -q 'EXCLUDED  _t350-teeth.sh'; then
  ok list_names_population
else bad list_names_population "--list did not name both a would-run and an excluded entry"; fi

out=$(run --only _t900)
if printf '%s' "$out" | grep -q 'PARTIAL 1 of 8,' && [ -e "$MARK/t900.ran" ] && [ ! -e "$MARK/t901.ran" ]; then
  ok only_selects_one
else bad only_selects_one "expected 'PARTIAL 1 of 8,' and only t900 to have run: $(printf '%s' "$out" | grep PARTIAL | tail -1)"; fi

out=$(run --only _t900 --only _t901)
if printf '%s' "$out" | grep -q 'PARTIAL 2 of 8,'; then ok only_two_patterns
else bad only_two_patterns "two patterns did not select two: $(printf '%s' "$out" | grep PARTIAL | tail -1)"; fi

out=$(run --only=_t900)
if printf '%s' "$out" | grep -q 'PARTIAL 1 of 8,'; then ok only_equals_form
else bad only_equals_form "--only=PAT form not honoured"; fi

out=$(run --only zzz-no-such); rc=$(rc_of --only zzz-no-such)
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'matched no instrument'; then ok only_no_match_refuses
else bad only_no_match_refuses "empty selection did not refuse (rc=$rc)"; fi

out=$(run --only); rc=$(rc_of --only)
# NOT merely "rc != 0": an unpatched sweep ignores argv and exits non-zero anyway because
# the fixture holds a failing stub. The refusal MESSAGE is the only feature-specific proof.
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'REFUSING: --only needs a pattern'; then
  ok only_needs_a_pattern
else bad only_needs_a_pattern "no '--only needs a pattern' refusal (rc=$rc) — an unpatched sweep also exits non-zero here"; fi

out=$(run --onyl _t900); rc=$(rc_of --onyl _t900)
if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q "unknown argument"; then ok unknown_flag_refused
else bad unknown_flag_refused "a typo'd flag did not refuse (rc=$rc) — it may have run the whole sweep"; fi

out=$(run --only _t900)
if printf '%s' "$out" | grep -q 'NOT a sweep' && printf '%s' "$out" | grep -q 'instrument(s) were NOT run'; then
  ok filtered_says_not_a_sweep
else bad filtered_says_not_a_sweep "filtered run did not disclaim coverage"; fi

# The load-bearing one: a subset must never satisfy a reader grepping for the sweep line.
if ! printf '%s' "$out" | grep -q '^RAN '; then ok filtered_omits_full_sentence
else bad filtered_omits_full_sentence "filtered run emitted the full-run 'RAN ' sentence — a subset could be read as coverage"; fi

out=$(run --only _t901); rc=$(rc_of --only _t901)
# Same trap: 'regressed 1' appears in a full fixture run too. Pin the PARTIAL framing so
# this case can only pass when the classification happened INSIDE a filtered run.
if printf '%s' "$out" | grep -q 'PARTIAL 1 of 8, passed 0, regressed 1' && [ "$rc" -ne 0 ]; then
  ok filtered_still_classifies
else bad filtered_still_classifies "filtered run over a failing instrument did not classify it as PARTIAL+regressed (rc=$rc): $(printf '%s' "$out" | grep -E 'PARTIAL [0-9]|^RAN ' | tail -1)"; fi

out=$(run --help); rc=$(rc_of --help)
if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'NOT a coverage claim'; then ok help_exits_zero
else bad help_exits_zero "--help rc=$rc or missing the coverage disclaimer"; fi

echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
