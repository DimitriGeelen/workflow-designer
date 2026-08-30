#!/usr/bin/env bash
# T-644 — `lib/ask.py` must reach its imports in a VENDORED install.
#
# WHAT WENT WRONG:
#   ask.py:21 read the framework root as
#       os.environ.get("PROJECT_ROOT", <__file__-derived>)
#   The __file__-derived FALLBACK was correct; the env var that `lib/ask.sh:32`
#   exports unconditionally was not. In a vendored install PROJECT_ROOT is the
#   project, and web/ lives under .agentic-framework/ — so `fw ask` died at
#   `from web.embeddings import ...` with ModuleNotFoundError, every time.
#
#   A DEFAULT THAT IS RIGHT DOES NOT HELP WHEN THE OVERRIDE IS ALWAYS SET.
#
# Sibling of T-643, which is the same class one silence level up: there the failed
# import was CAUGHT and a drifted copy substituted. Here it is loud. Loud is better;
# it was still broken for as long as anyone has been running `fw ask` here.
#
# This prober does NOT retype ask.py's preamble — retyping it would test a model of
# the file (T-635's sin). It executes the real file, in the real environment
# `lib/ask.sh` sets up, and distinguishes "died at the import" from "ran".
#
# Exit 0 = all legs pass.

set -uo pipefail

PROJ="${T644_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FWROOT="$PROJ/.agentic-framework"
ASKPY="$FWROOT/lib/ask.py"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$ASKPY" ] || { echo "FATAL: $ASKPY not found"; exit 3; }

echo "=== T-644: fw ask must reach its imports in a vendored install ==="
echo

# ---------------------------------------------------------------------------
# The preamble is executed by import-machinery, not by re-typing it: read the file,
# stop at the first `from web.` line, exec what came before, then attempt the two
# imports. That runs ask.py's REAL path setup while skipping the ollama/argparse
# body, which is not what is under test.
# ---------------------------------------------------------------------------
run_preamble() {   # $1=PROJECT_ROOT value  -> prints OK | MISSING-WEB | ERR:<type>
    PROJECT_ROOT="$1" T644_ASKPY="$ASKPY" python3 - <<'PY' 2>&1
import os, sys
src = open(os.environ["T644_ASKPY"]).read()
head, _, _ = src.partition("\nfrom web.")
ns = {"__file__": os.environ["T644_ASKPY"], "__name__": "_t644_probe"}
try:
    exec(compile(head, os.environ["T644_ASKPY"], "exec"), ns)
except Exception as e:
    print(f"ERR:{type(e).__name__}"); raise SystemExit
try:
    import web.embeddings, web.ask          # noqa: F401
    print("OK")
except ModuleNotFoundError as e:
    print("MISSING-WEB" if e.name in ("web", "web.embeddings", "web.ask") else f"ERR:{e.name}")
except Exception as e:
    print(f"ERR:{type(e).__name__}")
PY
}

echo "--- the environment lib/ask.sh actually creates (PROJECT_ROOT = the project)"
R=$(run_preamble "$PROJ")
case "$R" in
    OK)          ok "web.embeddings and web.ask both resolve under the exported PROJECT_ROOT" ;;
    MISSING-WEB) bad "still ModuleNotFoundError on web — the fix is not in effect" ;;
    *)           bad "preamble did not complete: $R" ;;
esac

echo "--- the env var can no longer decide it: a nonsense PROJECT_ROOT must not break the import"
R=$(run_preamble "$TMP")
case "$R" in
    OK)          ok "imports survive a PROJECT_ROOT pointing nowhere useful" ;;
    MISSING-WEB) bad "a wrong PROJECT_ROOT still breaks the import — the env var is still load-bearing" ;;
    *)           bad "preamble did not complete: $R" ;;
esac

# ---------------------------------------------------------------------------
echo "--- the defect's precondition still holds (so the fix is load-bearing, not decorative)"
if PROJECT_ROOT="$PROJ" python3 -c "
import sys, os
sys.path = [os.environ['PROJECT_ROOT']]
import web.embeddings
" >/dev/null 2>&1; then
    bad "web/ resolves from PROJECT_ROOT alone — this project is no longer vendored and this file tests a layout that no longer exists"
else
    ok "web/ is NOT under PROJECT_ROOT here (vendored layout — exactly the case that used to fail)"
fi

# ---------------------------------------------------------------------------
echo "--- teeth: restore the single-root insert and the import must die again"
MUT="$TMP/ask-mutant.py"
python3 - "$ASKPY" "$MUT" <<'PY'
import sys, re
src = open(sys.argv[1]).read()
# Replace the whole T-644 block with the shipped one-liner pair.
start = src.index("FRAMEWORK_ROOT = os.path.dirname")
end = src.index("\nfrom web.", start)
shipped = (
    'PROJECT_ROOT = os.environ.get("PROJECT_ROOT", '
    'os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\n'
    'sys.path.insert(0, PROJECT_ROOT)\n'
)
open(sys.argv[2], "w").write(src[:start] + shipped + src[end:])
PY
if [ ! -s "$MUT" ] || ! grep -q "sys.path.insert(0, PROJECT_ROOT)" "$MUT"; then
    echo "  MUTATION FAILED — could not rebuild the shipped preamble; the teeth leg is meaningless"
    FAIL=$((FAIL + 1))
else
    R=$(PROJECT_ROOT="$PROJ" T644_ASKPY="$MUT" python3 - <<'PY' 2>&1
import os, sys
src = open(os.environ["T644_ASKPY"]).read()
head, _, _ = src.partition("\nfrom web.")
ns = {"__file__": os.environ["T644_ASKPY"], "__name__": "_t644_probe"}
exec(compile(head, os.environ["T644_ASKPY"], "exec"), ns)
try:
    import web.embeddings
    print("OK")
except ModuleNotFoundError:
    print("MISSING-WEB")
PY
)
    # __file__ is the mutant in $TMP, so its own fallback resolves to /tmp — the mutant
    # therefore reproduces the shipped behaviour for the right reason: the env var wins.
    if [ "$R" = "MISSING-WEB" ]; then
        ok "shipped single-root insert still fails to find web/ — the fix is what changed the outcome"
    else
        bad "mutant imported successfully ('$R') — this leg cannot fail and proves nothing"
    fi
fi

# ---------------------------------------------------------------------------
echo "--- audit: nothing under lib/ makes the env var the SOLE source of the module path"
# Narrow on purpose, and worth saying so: this greps for the exact shipped shape,
# `sys.path.insert(0, PROJECT_ROOT)`, where the env var is the only root offered. It is
# not a general audit of path handling and does not pretend to be — the survey behind it
# was done once, by hand, in T-644's RCA: ask.py was the only such site under lib/, every
# other insert derives its root from __file__. A regex cannot keep that survey true; it
# can keep THIS shape from coming back.
OTHERS=$(grep -rn "sys\.path\.insert(0, PROJECT_ROOT)" "$FWROOT/lib"/*.py 2>/dev/null || true)
if [ -z "$OTHERS" ]; then
    ok "no lib/*.py inserts PROJECT_ROOT as the only module root"
else
    bad "env-var-only sys.path insert(s) still present: $(echo "$OTHERS" | head -3 | tr '\n' ' ')"
fi

echo
TOTAL=$((PASS + FAIL))
echo "=== $PASS/$TOTAL passed ==="
[ "$FAIL" -eq 0 ] || exit 1
