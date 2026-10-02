#!/usr/bin/env bash
# T-952 — the bridge-suite ratchet must reach an audit line, and that line must discriminate.
#
# Same lesson as _t657, applied one rail over: a detector with no delivery surface is the
# defect, not the detector. _t813 has run daily since T-917, correctly, into `logger` and
# nothing else — `grep -c '_t813\|run-history'` on audit.sh was 0. This prober guards the
# DELIVERY so the new line cannot quietly rot back into that state.
#
# IT DOES NOT RETYPE THE AUDIT BLOCK. It greps the real check_bridge_suite_ratchet function
# out of audit.sh and runs THAT against a stub tool, so a rewrite is reported rather than
# skipped. It never touches the project's real tests/.run-history.tsv.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.
set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/lib/mutation-assert.sh"

PROJ="${T952_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/tools/project-audit.sh"   # T-999: the rail moved out of vendored audit.sh, which re-vendors overwrite

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-952: the suite ratchet must reach an audit line ==="
echo

# --- extract the real region by FUNCTION NAME, never a retyped copy ----------
# Anchored on the function, not on a comment string: the 1.7.68 re-vendor deleted a
# comment-anchored region out from under _t657 and sent it to rc=3 for five days (T-945).
extract() {
    python3 - "$SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"^check_bridge_suite_ratchet\(\) \{.*?^\}$", src, re.S | re.M)
if not m:
    sys.stderr.write(
        "COULD-NOT-MEASURE: check_bridge_suite_ratchet() is not in tools/project-audit.sh.\n"
        "  The suite ratchet has no delivery surface — which is the state T-952 found it\n"
        "  in and exists to prevent. If the rail was renamed rather than removed,\n"
        "  re-anchor this extractor.\n")
    sys.exit(3)
sys.stdout.write(m.group(0) + "\ncheck_bridge_suite_ratchet\n")
PY
}
BLOCK="$TMP/block.sh"
extract > "$BLOCK" || exit 3
[ -s "$BLOCK" ] || { echo "COULD-NOT-MEASURE: extracted region was empty" >&2; exit 3; }

# --- a throwaway project root carrying a stub ratchet ------------------------
# mode=held  -> exits 0, floor held
# mode=rose  -> exits 1, failures rose (the case that must reach the operator)
# mode=stale -> exits 1, newest completed run too old
make_root() {
    local mode="$1"
    local root="$TMP/root-$mode-$RANDOM"
    mkdir -p "$root/tools" "$root/tests"
    printf 'stub\n' > "$root/tests/.run-history.tsv"
    case "$mode" in
      held) cat > "$root/tools/_t952-bridge-suite-ratchet.py" <<'PY'
print("baseline floor : 32 failure(s)   (STUBFLOOR)")
print("latest complete: 32 failure(s), 122 passed, rc=1, 999s")
print("               : 2026-09-30T13:57:30Z  (0d 2h old)")
print("OK - floor held at exactly 32.")
raise SystemExit(0)
PY
        ;;
      rose) cat > "$root/tools/_t952-bridge-suite-ratchet.py" <<'PY'
print("baseline floor : 32 failure(s)   (STUBFLOOR)")
print("latest complete: 41 failure(s), 113 passed, rc=1, 999s")
print("               : 2026-09-30T13:57:30Z  (0d 2h old)")
print("FAIL: failures ROSE - 41 against a floor of 32 (+9). STUBCANARY")
raise SystemExit(1)
PY
        ;;
      stale) cat > "$root/tools/_t952-bridge-suite-ratchet.py" <<'PY'
print("baseline floor : 32 failure(s)   (STUBFLOOR)")
print("latest complete: 32 failure(s), 122 passed, rc=1, 999s")
print("               : 2026-09-20T13:57:30Z  (10d 2h old)")
print("FAIL: the newest completed run is 10d 2h old, past the 48h limit. STUBCANARY")
raise SystemExit(1)
PY
        ;;
    esac
    echo "$root"
}

# verdict <project_root> [block] -> "LEVEL::message::evidence::remedy"
verdict() {
    local proot="$1" block="${2:-$BLOCK}"
    (
        set +u
        PROJECT_ROOT="$proot"
        pass() { echo "PASS::$1"; }
        warn() { echo "WARN::$1::${2:-}::${3:-}"; }
        fail() { echo "FAIL::$1::${2:-}::${3:-}"; }
        . "$block"
    ) 2>&1
}

# ---------------------------------------------------------------------------
echo "--- a risen failure count produces a WARN naming the rise"
ROSE=$(make_root rose)
OUT=$(verdict "$ROSE")
MISSING=""
echo "$OUT" | grep -q '^WARN::'   || MISSING="$MISSING not-a-warn"
echo "$OUT" | grep -q 'ROSE'      || MISSING="$MISSING the-verdict"
echo "$OUT" | grep -q '41'        || MISSING="$MISSING the-count"
if [ -z "$MISSING" ]; then
    ok "red ratchet -> WARN carrying the risen count"
else
    bad "WARN incomplete:$MISSING | got: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
# THE PATH ASSERTION. A verdict appearing is not evidence it came from the tool: a
# hardcoded sentence would satisfy every leg above. Assert the line carries bytes that
# exist ONLY in this run's stub output.
echo "--- ...and the WARN carries the TOOL's own bytes, not a hardcoded message"
if echo "$OUT" | grep -q 'STUBCANARY\|STUBFLOOR'; then
    ok "evidence quotes the stub's unique output — the line surfaces what the tool said"
else
    bad "the WARN never quoted the tool's output; it could be reporting anything"
fi

# ---------------------------------------------------------------------------
echo "--- a held floor passes, and names the measurement"
HELD=$(make_root held)
OUT=$(verdict "$HELD")
if echo "$OUT" | grep -q '^PASS::' && echo "$OUT" | grep -q '32'; then
    ok "green ratchet -> PASS naming the held floor"
else
    bad "held floor did not pass cleanly: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- staleness reaches the line too, not just a failure count"
STALE=$(make_root stale)
OUT=$(verdict "$STALE")
if echo "$OUT" | grep -q '^WARN::' && echo "$OUT" | grep -qi '48h limit\|old'; then
    ok "a stale run reaches the audit as a WARN — a dead schedule is visible"
else
    bad "staleness did not surface: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- NO HISTORY is NOT EVALUATED, never a pass (T-3105)"
BARE="$TMP/bare-$RANDOM"; mkdir -p "$BARE/tools" "$BARE/tests"
cat > "$BARE/tools/_t952-bridge-suite-ratchet.py" <<'PY'
raise SystemExit(0)
PY
OUT=$(verdict "$BARE")
if echo "$OUT" | grep -q '^WARN::' && echo "$OUT" | grep -q 'NOT EVALUATED'; then
    ok "absent history -> NOT EVALUATED warning, not a silent pass"
else
    bad "absent history produced: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- inert when the ratchet tool is absent"
NOTOOL="$TMP/notool-$RANDOM"; mkdir -p "$NOTOOL/tools" "$NOTOOL/tests"
OUT=$(verdict "$NOTOOL")
if [ -z "$(echo "$OUT" | tr -d '[:space:]')" ]; then
    ok "no tool, no verdict — and no error"
else
    bad "block spoke with no tool present: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: neutralise the exit-code test and the risen count must fall silent"
MUT="$TMP/block-mutant.sh"
# Force the success branch — the pre-T-952 world, where the ratchet's verdict existed and
# reached no one.
sed 's|^    if \[ "\$_rc" -eq 0 \]; then|    if true; then|' "$BLOCK" > "$MUT"
BASELINE=$(verdict "$ROSE")
if ! MUTATED=$(assert_mutation_complete "$BLOCK" "$MUT" '^    if \[ "\$_rc" -eq 0 \]; then' 'success-branch test'); then
    bad "$MUTATED"
elif ! echo "$BASELINE" | grep -q '^WARN::'; then
    bad "PRECONDITION FAILED — the unmutated block does not warn on the risen fixture, so its silence under mutation proves nothing"
else
    OUT=$(verdict "$ROSE" "$MUT")
    if ! echo "$OUT" | grep -q '^WARN::'; then
        ok "mutant swallows a verdict the unmutated block demonstrably emits"
    else
        bad "mutant still warned; the legs above cannot fail and prove nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
