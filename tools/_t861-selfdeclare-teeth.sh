#!/bin/bash
# T-861 — teeth for the sweep's SELF-DECLARED-broken-guard detection.
#
# WHAT IT DEFENDS. The sweep's rc classification trusted each instrument to volunteer rc=4
# when its own control leg failed. Four did not — they announce it in English and exit 1 —
# so the sweep filed broken guards as regressions in the things they guard. T-851 measured
# it wrong by four (reported 12/2, truth 6/8).
#
# THE FAILURE MODE TO DEFEND AGAINST IS NOT "detection does not fire". That is obvious on
# first use. It is "detection fires on everything", which would satisfy a naive check and be
# worse than the bug: every genuine regression would be excused as a broken guard, and the
# sweep would stop reporting subject failures at all. So the control case here is a probe
# that fails its subject cleanly and MUST stay `regressed`.
#
# A SIBLING SUITE, NOT AN EXTENSION of _t850's. That suite pins fixture counts ("PARTIAL 1
# of 8"); adding stubs there would have broken passing assertions to test something else.
# One concern per file is cheaper than repairing a suite I would then have to re-verify.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SWEEP="${SWEEP:-$ROOT/tools/_t509-instrument-sweep.sh}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t861.XXXXXX")"
trap 'rm -rf "$WORK"; rm -f "${MUT:-}"' EXIT

PASS=0; FAIL=0
NEW_CASES="traceback_is_dead_control control_leg_marker_is_dead_control teeth_broken_marker_is_dead_control abort_marker_is_dead_control marker_named_in_the_report"
CONTROL_CASES="clean_failure_stays_regressed rc4_still_dead_control passing_probe_still_passes empty_selection_still_refuses"

ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

FIX="$WORK/fixroot"; mkdir -p "$FIX/tools"
mk() { printf '%s\n' '#!/bin/bash' "$2" > "$FIX/tools/$1"; chmod +x "$FIX/tools/$1"; }
setup() {
  cp "$SWEEP" "$FIX/tools/_t509-instrument-sweep.sh"; chmod +x "$FIX/tools/_t509-instrument-sweep.sh"
  # Each stub emits a marker copied from a REAL capture during the T-851 triage.
  mk _t900-traceback-teeth.sh   'echo "Traceback (most recent call last):"; echo "AttributeError: nope"; exit 1'
  mk _t901-controlleg-teeth.sh  'echo "  FAIL  control: unmutated source passes all four legs — failing: edit=FAIL"; exit 1'
  mk _t902-teethbroken-teeth.sh 'echo "TEETH BROKEN — the subject renamed the line this anchors on"; exit 1'
  mk _t903-abort-teeth.sh       'echo "ABORT: this probe can no longer test what it claims to test"; exit 1'
  # THE CONTROL: a clean subject failure, no self-declaration. Must stay regressed.
  mk _t904-cleanfail-teeth.sh   'echo "  FAIL  3 the subject lost its idempotence"; exit 1'
  mk _t905-rc4-teeth.sh         'echo "control leg down"; exit 4'
  mk _t906-green-teeth.sh       'exit 0'
  # The four names the sweep excludes must exist or the stale-exclusion check fires first.
  for n in _t350-teeth.sh _t351-teeth.sh _t430-abstention-teeth.sh _t423-additive-export-teeth.py; do
    mk "$n" 'exit 0'
  done
}
run() { bash "$FIX/tools/_t509-instrument-sweep.sh" "$@" 2>&1; }

echo "=== T-861 self-declared-broken-guard teeth ==="
echo "sweep under test: $SWEEP"
echo

# ── mutation mode ───────────────────────────────────────────────────────────────────────
# Strips the T-861 block from a copy and requires the dependent cases to go red WHILE the
# control cases stay green. The copy lives BESIDE the original: the sweep derives its root
# from its own location, so a copy in a temp dir cannot start — measured in T-849, where
# that produced a full-red run that read as a clean kill.
if [ "${1:-}" = "--mutation" ]; then
    MUT="$(dirname "$SWEEP")/.t861-mutated-$$.sh"
    python3 - "$SWEEP" "$MUT" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
m = re.search(r"\n# ── SELF-DECLARED BROKEN GUARDS \(T-861\).*?\n}\n", t, re.S)
if not m:
    sys.exit("mutation anchor not found — the T-861 block was renamed or removed")
t = t[:m.start()] + "\nself_declared_broken() { return 1; }\n" + t[m.end():]
open(dst, "w").write(t)
PYEOF
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutated copy"; exit 1; }
    chmod +x "$MUT"; bash -n "$MUT" || { echo "MUTATION SETUP FAILED: does not parse"; exit 1; }
    echo "=== T-861 MUTATION RUN (detection stubbed to always-false) ==="
    out=$(SWEEP="$MUT" bash "${BASH_SOURCE[0]}" 2>&1)
    printf '%s\n' "$out" | sed 's/^/  | /'
    echo
    broken=""
    for c in $CONTROL_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" || broken="$broken $c"
    done
    if [ -n "$broken" ]; then
        echo "MUTATION SETUP BROKEN — cases unrelated to the detection also failed:$broken"
        echo "The stripped copy is not merely undetecting, it is not working. Every red is false."
        exit 1
    fi
    survivors=""
    for c in $NEW_CASES; do
        printf '%s' "$out" | grep -q "PASS  $c\$" && survivors="$survivors $c"
    done
    if [ -n "$survivors" ]; then
        echo "MUTATION FAILED — these pass WITHOUT the detection:$survivors"
        exit 1
    fi
    echo "MUTATION OK — control cases stayed green, so the stripped sweep still runs;"
    echo "every case that depends on the detection went red."
    exit 0
fi

setup
out=$(run --only _t900 --only _t901 --only _t902 --only _t903 --only _t904 --only _t905 --only _t906)

# ── NEW CASES: each marker is detected ──────────────────────────────────────────────────
for pair in "traceback_is_dead_control|_t900" \
            "control_leg_marker_is_dead_control|_t901" \
            "teeth_broken_marker_is_dead_control|_t902" \
            "abort_marker_is_dead_control|_t903"; do
    name="${pair%%|*}"; stub="${pair#*|}"
    if printf '%s' "$out" | grep -q "DEAD CONTROL: ${stub}.*SELF-DECLARED"; then ok "$name"
    else bad "$name" "$stub was not classified dead-control: $(printf '%s' "$out" | grep -c 'DEAD CONTROL') dead lines seen"; fi
done

# The report must NAME the marker, so a reader can see why it was reclassified rather than
# having to trust the bucket.
if printf '%s' "$out" | grep -q 'output contains "Traceback (most recent call last):"'; then
    ok marker_named_in_the_report
else bad marker_named_in_the_report "the detected marker is not quoted in the report line"; fi

# ── CONTROL CASES: the detection must not swallow everything ────────────────────────────
if printf '%s' "$out" | grep -q '_t904-cleanfail-teeth.sh (rc=1)' && \
   ! printf '%s' "$out" | grep -q '_t904.*SELF-DECLARED'; then
    ok clean_failure_stays_regressed
else bad clean_failure_stays_regressed "a clean subject failure was excused as a broken guard — the detection is over-firing, which is worse than the bug"; fi

if printf '%s' "$out" | grep -q '_t905-rc4-teeth.sh (rc=4, its own control leg failed)'; then
    ok rc4_still_dead_control
else bad rc4_still_dead_control "the rc=4 convention stopped working — this was meant to ADD a path, not replace one"; fi

if printf '%s' "$out" | grep -qE 'PARTIAL 7 of [0-9]+, passed 1,'; then ok passing_probe_still_passes
else bad passing_probe_still_passes "expected passed 1: $(printf '%s' "$out" | grep PARTIAL | tail -1)"; fi

out2=$(run --only zzz-no-such); rc2=0; run --only zzz-no-such >/dev/null 2>&1 || rc2=$?
if [ "$rc2" -ne 0 ] && printf '%s' "$out2" | grep -q 'matched no instrument'; then ok empty_selection_still_refuses
else bad empty_selection_still_refuses "the pre-existing refusal broke (rc=$rc2)"; fi

echo
echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
