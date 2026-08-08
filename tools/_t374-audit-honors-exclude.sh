#!/usr/bin/env bash
# _t374-audit-honors-exclude.sh — does `fw audit` respect the `exclude:` key that
# `fw fabric drift` respects?
#
# THE DEFECT. `.fabric/watch-patterns.yaml` supports `exclude:` (top-level and
# per-pattern). expand_patterns.py implements it; register.sh and drift.sh go
# through expand_patterns.py; audit.sh's two fabric coverage blocks each inlined
# their own loop over `patterns:` and never looked at `exclude:`. So the same
# config produced different populations depending on which command you ran —
# measured 1 vs 50 on `tools/**/*.mjs` with `exclude: ["tools/_*"]`.
#
# WHY THE INPUT MUST CARRY AN exclude: KEY. This is the whole point of the probe
# and the easiest thing to get wrong. Over a config with no `exclude:`, the two
# implementations are IDENTICAL by construction — a probe built on this repo's
# real watch-patterns.yaml would pass against the broken audit and the fixed one
# alike, and would read as coverage. The discriminator has to be in the fixture,
# so the fixture is synthetic and its exclude key is the only reason it exists.
#
# WHY IT DRIVES THE REAL audit.sh. The claim is about what `fw audit` reports,
# and every step between the config and that line — PROJECT_ROOT resolution,
# expander invocation, the shell/python boundary, the verdict branch — is a place
# the behaviour can differ from what the source suggests. Restating the logic here
# would test a copy (PL-061).
#
# Usage: bash tools/_t374-audit-honors-exclude.sh
#   T374_AUDIT=<path>  drive a different audit.sh build (used to prove teeth).
#                      Must live under a real framework tree so FRAMEWORK_ROOT,
#                      and therefore the expander path, still resolve.
# Exit 0 = the audit's population matches the expander's on an excluding config.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT="${T374_AUDIT:-$REPO/.agentic-framework/agents/audit/audit.sh}"
EXPANDER="$REPO/.agentic-framework/agents/fabric/lib/expand_patterns.py"

pass=0; fail=0
ok()  { echo "  PASS  $1"; pass=$((pass+1)); }
bad() { echo "  FAIL  $1"; fail=$((fail+1)); }

echo "T-374 — does fw audit honor exclude: the way fw fabric drift does?"
echo

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

mkdir -p "$ROOT/.fabric/components" "$ROOT/code" "$ROOT/.tasks/active" \
         "$ROOT/.tasks/completed" "$ROOT/.tasks/templates" "$ROOT/.context/working"
touch "$ROOT/.framework.yaml" "$ROOT/.tasks/templates/default.md"

# Three watched candidates; the exclude key removes two of them.
echo "print('durable')" > "$ROOT/code/keep.py"
echo "print('probe 1')" > "$ROOT/code/_scratch_one.py"
echo "print('probe 2')" > "$ROOT/code/_scratch_two.py"

cat > "$ROOT/.fabric/watch-patterns.yaml" <<'EOF'
patterns:
  - glob: "code/**/*.py"
exclude:
  - "code/_*"
EOF

# One card, for the single file that survives the exclude. So:
#   honoring exclude   -> watched 1, unregistered 0
#   ignoring exclude   -> watched 3, unregistered 2
# The two builds are separated by the UNREGISTERED count, which every build
# prints — the denominator text only exists post-T-344 and cannot be compared
# across the boundary this probe straddles.
cat > "$ROOT/.fabric/components/keep.yaml" <<'EOF'
id: C-001
name: keep
type: module
location: code/keep.py
EOF

# --- 1: the expander is the reference implementation --------------------------
exp_n=$(python3 "$EXPANDER" "$ROOT/.fabric/watch-patterns.yaml" "$ROOT" 2>/dev/null | wc -l)
if [ "$exp_n" -eq 1 ]; then
  ok "expand_patterns.py honors exclude: 3 candidates -> $exp_n watched"
else
  bad "expand_patterns.py returned $exp_n, expected 1 — the reference implementation"
  bad "      does not behave as assumed; every comparison below is unreadable"
fi

# --- 2: the fixture can actually discriminate ---------------------------------
# Without this, a fixture whose exclude matched nothing would make legs 3-4 pass
# against both builds. Assert the exclude REMOVES something before reading it.
raw_n=$(cd "$ROOT" && python3 -c "
import glob
print(len([f for f in glob.glob('code/**/*.py', recursive=True)]))")
if [ "$raw_n" -gt "$exp_n" ]; then
  ok "fixture discriminates: $raw_n files match the glob, $exp_n survive exclude"
else
  bad "fixture does NOT discriminate ($raw_n vs $exp_n) — an exclude that removes"
  bad "      nothing cannot tell the two implementations apart; fix the fixture"
fi

# --- 3-4: what does the real audit report? ------------------------------------
audit_out=$(cd "$ROOT" && PROJECT_ROOT="$ROOT" bash "$AUDIT" --section structure 2>&1)
line=$(echo "$audit_out" | grep -E "\[(PASS|WARN)\] Fabric: .*registered" | head -1)
n_unreg=$(echo "$line" | sed -n 's/.*registered, \([0-9]\+\) unregistered.*/\1/p')

if [ -z "$line" ]; then
  bad "no 'Fabric: N registered, M unregistered' line in the audit output — the"
  bad "      verdict text moved, or the synthetic root was rejected; re-anchor"
elif [ "${n_unreg:-x}" = "0" ]; then
  ok "audit reports 0 unregistered — it honored exclude: (agrees with the expander)"
else
  bad "audit reports $n_unreg unregistered, expander says 0 — audit IGNORED exclude:."
  bad "      Its coverage population is the un-excluded one, so fw audit and"
  bad "      fw fabric drift describe different sets from one config."
fi

drift_line=$(echo "$audit_out" | grep -E "\[(PASS|WARN)\] Fabric drift:" | head -1)
if [ -z "$drift_line" ]; then
  bad "no 'Fabric drift:' line in the audit output — re-anchor this leg"
elif echo "$drift_line" | grep -qE "no fabric card"; then
  bad "sibling drift check reports unregistered files: $drift_line"
  bad "      the second block ignores exclude: even if the first one honors it"
else
  ok "sibling drift check agrees — both blocks read the same excluded set"
fi

# --- 5: a broken install must not read as an empty watch set ------------------
# T-344's defect was one message for two states. Its own fix must not reproduce
# it: expander-missing and watch-set-empty both yield zero watched files.
broken_out=$(cd "$ROOT" && PROJECT_ROOT="$ROOT" FRAMEWORK_ROOT_OVERRIDE=1 \
             bash -c "AUDIT='$AUDIT'; sed 's#^FABRIC_EXPANDER=.*#FABRIC_EXPANDER=\"/nonexistent/expand_patterns.py\"#' \"\$AUDIT\" > '$ROOT/audit-broken.sh'; bash '$ROOT/audit-broken.sh' --section structure" 2>&1)
if echo "$broken_out" | grep -q "expander unavailable"; then
  ok "missing expander is reported as an install problem, distinctly from an empty watch set"
elif echo "$broken_out" | grep -q "expands to 0 files"; then
  bad "a missing expander is reported as 'watch set expands to 0 files' — two states,"
  bad "      one message, sending the reader to edit a config that is not the problem"
else
  bad "missing expander produced neither message; output did not match either arm"
fi

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
exit 0
