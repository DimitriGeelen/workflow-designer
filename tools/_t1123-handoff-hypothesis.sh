#!/bin/bash
# T-1123: lib/inception-readiness.sh inception_handoff_blockers must report a GO-recommended
# inception whose ## Hypothesis the decide gate (audit_inception_hypothesis, T-866) would refuse,
# and must NOT block NO-GO / DEFER handoffs or a GO with a checkable hypothesis.
# Fixtures are synthetic task files in a temp dir; the predicate is the vendored one.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FW="$ROOT/.agentic-framework"
. "$FW/lib/inception-readiness.sh" || { echo "FAIL: readiness lib did not load"; exit 1; }
. "$FW/lib/task-audit.sh" 2>/dev/null || true
command -v audit_inception_hypothesis >/dev/null || { echo "FAIL: audit_inception_hypothesis missing"; exit 1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mk() { # name rec success-clause
  cat > "$T/$1.md" <<EOF
---
id: T-9999
workflow_type: inception
---
## Hypothesis

We believe that x,
we will achieve y.
We will know that we are successful when we see $3.

## Recommendation

**Recommendation:** $2

**Rationale:** because.
EOF
}
PH='[NEEDS YOU: name something a person could go and look at]'
mk go-placeholder GO "$PH"
mk go-checkable   GO "at most 4 field rows shown by default on 42 service tasks"
mk nogo-placeholder NO-GO "$PH"
mk defer-placeholder DEFER "$PH"
# GO with no hypothesis section at all
printf -- '---\nid: T-9999\nworkflow_type: inception\n---\n## Recommendation\n\n**Recommendation:** GO\n\n**Rationale:** because.\n' > "$T/go-missing.md"
# Recommendation inside an HTML comment must not count
printf -- '---\nid: T-9999\nworkflow_type: inception\n---\n## Hypothesis\n\nWe believe that x,\nwe will achieve y.\nWe will know that we are successful when we see %s.\n\n## Recommendation\n\n<!--\n**Recommendation:** GO\n-->\n**Recommendation:** DEFER\n\n**Rationale:** because.\n' "$PH" > "$T/commented-go.md"

pass=0; fail=0
expect() { # file want(blocked|clear)
  local b; b=$(inception_handoff_blockers "$T/$1.md" | grep -c '^hypothesis-unready')
  local got=clear; [ "$b" -gt 0 ] && got=blocked
  if [ "$got" = "$2" ]; then pass=$((pass+1)); echo "ok   $1: $got"; else fail=$((fail+1)); echo "FAIL $1: got $got, want $2"; fi
}
expect go-placeholder blocked
expect go-missing blocked
expect go-checkable clear
expect nogo-placeholder clear
expect defer-placeholder clear
expect commented-go clear
# The predicate still always returns 0 (OBS-566 contract)
inception_handoff_blockers "$T/go-placeholder.md" >/dev/null; rc=$?
[ "$rc" = 0 ] && { pass=$((pass+1)); echo "ok   returns 0 with a finding"; } || { fail=$((fail+1)); echo "FAIL returned $rc"; }
# Parity: a blocked fixture is exactly one the decide gate refuses at GO
if ! audit_inception_hypothesis "$T/go-placeholder.md" go 2>/dev/null && audit_inception_hypothesis "$T/go-checkable.md" go 2>/dev/null; then
  pass=$((pass+1)); echo "ok   parity with the decide gate"
else fail=$((fail+1)); echo "FAIL parity with the decide gate"; fi
echo "T-1123: $pass passed, $fail failed"
[ "$fail" = 0 ]
