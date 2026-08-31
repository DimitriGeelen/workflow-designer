#!/usr/bin/env bash
# T-657 — the vendor-divergence guard must report through a surface someone reads.
#
# WHY THIS EXISTS. tools/_t517-vendor-divergence.py was never wrong. It was found red after
# a long unread stretch twice — at "1 unrecorded" from commit 10a537c1 until 2026-08-29, and
# at 6 unrecorded on 2026-08-31 — and it was correct both times. Its only host was a
# ~13-minute bridge suite nothing runs on a schedule. Detection was never the variable;
# delivery was. This prober guards the DELIVERY, so the audit line cannot quietly rot back
# into the state the tool spent two months in.
#
# WHAT IT MUST NOT DO: it must not retype the audit block. It greps the real T-657 region out
# of audit.sh and runs THAT against a stub tool, so a rewrite is reported rather than skipped.
# It never touches the project's real .vendor-divergence.yaml.
#
# WHY A STUB TOOL: the subject under test is the AUDIT LINE — does it classify, count, and
# surface what the tool said. The tool's own correctness is _t517's business. A stub lets the
# line be driven through both verdicts deterministically, which the real tool cannot do
# without mutating the manifest.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T657_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SRC="$PROJ/.agentic-framework/agents/audit/audit.sh"
REAL_TOOL="$PROJ/tools/_t517-vendor-divergence.py"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$SRC" ] || { echo "COULD-NOT-MEASURE: $SRC not found" >&2; exit 3; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-657: the divergence guard must reach a surface someone reads ==="
echo

# --- extract the real region, never a retyped copy --------------------------
extract() {
    python3 - "$SRC" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.search(r"\n# T-657: give the vendored-divergence guard a delivery surface\..*?\n    fi\nfi\n",
              src, re.S)
if not m:
    sys.stderr.write("COULD-NOT-MEASURE: the T-657 region was not found in audit.sh\n")
    sys.exit(3)
sys.stdout.write(m.group(0))
PY
}
BLOCK="$TMP/block.sh"
extract > "$BLOCK" || exit 3
[ -s "$BLOCK" ] || { echo "COULD-NOT-MEASURE: extracted region was empty" >&2; exit 3; }

# --- a throwaway project root carrying a stub tool --------------------------
# mode=green -> stub exits 0 and reports a declared count
# mode=red   -> stub exits 1 and names UNRECORDED paths
make_root() {
    local mode="$1"
    local root="$TMP/root-$mode-$RANDOM"
    mkdir -p "$root/tools"
    if [ "$mode" = green ]; then
        cat > "$root/tools/_t517-vendor-divergence.py" <<'PY'
print("vendor baseline : deadbeef (2158 files)")
print("declared        : 45")
print("OK - every diverged path is declared.")
raise SystemExit(0)
PY
    else
        cat > "$root/tools/_t517-vendor-divergence.py" <<'PY'
print("vendor baseline : deadbeef (2158 files)")
print("  UNRECORDED  [content] .agentic-framework/lib/CANARY_ONE.py")
print("  UNRECORDED  [content] .agentic-framework/lib/CANARY_TWO.py")
print("FAIL - 2 unrecorded, 0 stale, 0 reclassified.")
raise SystemExit(1)
PY
    fi
    echo "$root"
}

# verdict <project_root> <framework_root> [block] -> "LEVEL::message::evidence::remedy"
verdict() {
    local proot="$1" froot="$2" block="${3:-$BLOCK}"
    (
        set +u
        PROJECT_ROOT="$proot"; FRAMEWORK_ROOT="$froot"
        pass() { echo "PASS::$1"; }
        warn() { echo "WARN::$1::${2:-}::${3:-}"; }
        fail() { echo "FAIL::$1::${2:-}::${3:-}"; }
        . "$block"
    ) 2>&1
}

# ---------------------------------------------------------------------------
echo "--- an undeclared divergence produces a WARN that names the count"
RED=$(make_root red)
OUT=$(verdict "$RED" "$TMP/framework")
MISSING=""
echo "$OUT" | grep -q '^WARN::'            || MISSING="$MISSING not-a-warn"
echo "$OUT" | grep -q '2 undeclared'       || MISSING="$MISSING the-count"
echo "$OUT" | grep -q 'T-657'              || MISSING="$MISSING the-provenance"
if [ -z "$MISSING" ]; then
    ok "red tool -> WARN carrying the count"
else
    bad "WARN incomplete:$MISSING | got: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
# THE PATH ASSERTION. A verdict appearing is not evidence the verdict came from the tool:
# a hardcoded string would satisfy every leg above. T-654's first green came through the
# wrong branch entirely and read as a pass. So assert the WARN carries bytes that exist
# ONLY in this run's stub output.
echo "--- ...and the WARN carries the TOOL's own bytes, not a hardcoded message"
if echo "$OUT" | grep -q 'CANARY_ONE'; then
    ok "evidence contains the stub's unique path — the line surfaces what the tool said"
else
    bad "the WARN never quoted the tool's output; it could be reporting anything"
fi

# ---------------------------------------------------------------------------
echo "--- a clean tree passes, and reports the declared count it was given"
GREEN=$(make_root green)
OUT=$(verdict "$GREEN" "$TMP/framework")
if echo "$OUT" | grep -q '^PASS::' && echo "$OUT" | grep -q '45 diverged path'; then
    ok "green tool -> PASS naming 45 declared paths"
else
    bad "clean tree did not pass cleanly: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
# Upstream safety: this block is vendored into a manifest-less framework repo. It must be
# inert there rather than erroring or reporting a phantom verdict.
echo "--- inert in the framework's own repo (PROJECT_ROOT == FRAMEWORK_ROOT)"
OUT=$(verdict "$RED" "$RED")
if [ -z "$(echo "$OUT" | tr -d '[:space:]')" ]; then
    ok "self-hosted framework repo: no verdict emitted"
else
    bad "block spoke in a repo that vendors nothing: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

echo "--- inert when the divergence tool is absent"
BARE="$TMP/bare"; mkdir -p "$BARE/tools"
OUT=$(verdict "$BARE" "$TMP/framework")
if [ -z "$(echo "$OUT" | tr -d '[:space:]')" ]; then
    ok "no tool, no verdict — and no error"
else
    bad "block spoke with no tool present: $(echo "$OUT" | tr '\n' ' ' | head -c 200)"
fi

# ---------------------------------------------------------------------------
# The cost claim is load-bearing: "run it more often" was unaffordable only because the
# check was priced at its 13-minute HOST. If the standalone tool is ever actually slow,
# the audit is the wrong home and this prober should say so before the audit gets blamed.
echo "--- the real check is cheap enough to belong in an audit (<30s)"
if [ -f "$REAL_TOOL" ]; then
    _s=$(date +%s%N)
    ( cd "$PROJ" && python3 "$REAL_TOOL" >/dev/null 2>&1 )
    _e=$(date +%s%N)
    _ms=$(( (_e - _s) / 1000000 ))
    if [ "$_ms" -lt 30000 ]; then
        ok "standalone divergence check: ${_ms}ms (the 13 minutes was the host, not this)"
    else
        bad "standalone check took ${_ms}ms — an audit line is the wrong host for it"
    fi
else
    echo "  SKIP  real tool not present at $REAL_TOOL"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: neutralise the exit-code test and the red tree must fall silent"
MUT="$TMP/block-mutant.sh"
# Force the failure branch unreachable — the pre-T-657 world, where the tool's verdict
# existed and reached no one. Reached without touching anything else in the block.
sed 's|^    if \[ \$? -ne 0 \]; then|    if false; then|' "$BLOCK" > "$MUT"
MUTATED=$(grep -c 'if false; then' "$MUT" || true)
BASELINE=$(verdict "$RED" "$TMP/framework")
if [ "$MUTATED" -ne 1 ]; then
    # T-656: assert the mutation LANDED. A sed that matched nothing leaves an unmutated
    # subject that passes every leg and certifies teeth the prober does not have.
    bad "MUTATION FAILED — expected exactly 1 exit-code test to neutralise, got $MUTATED"
elif ! echo "$BASELINE" | grep -q '^WARN::'; then
    # AND assert the FIXTURE landed. Caught live while writing this: an unbound-variable
    # bug left $RED empty, the unmutated block emitted nothing, the mutant also emitted
    # nothing, and this leg reported PASS — certifying teeth on a subject that was never
    # exercised. "Silence after mutation" only means something if there was noise before it.
    bad "PRECONDITION FAILED — the unmutated block does not warn on the red fixture, so its silence under mutation proves nothing"
else
    OUT=$(verdict "$RED" "$TMP/framework" "$MUT")
    if ! echo "$OUT" | grep -q '^WARN::'; then
        ok "mutant swallows a verdict the unmutated block demonstrably emits"
    else
        bad "mutant still warned; the legs above cannot fail and prove nothing"
    fi
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
