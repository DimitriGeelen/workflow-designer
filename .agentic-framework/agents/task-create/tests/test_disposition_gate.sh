#!/usr/bin/env bash
# T-203 regression: check_disposition_gate must NOT mis-tokenize an IW-N/Q-N that
# appears inside rationale PROSE (a legitimate cross-reference to another question)
# as a new question marker — while STILL blocking a genuinely under-disposed
# inception (teeth). Exercises the REAL function extracted verbatim from
# update-task.sh, so a future edit to the function is what this test measures.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../update-task.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Extract the function verbatim: decl line .. first column-0 closing brace.
awk '/^check_disposition_gate\(\) \{/{f=1} f{print} f&&/^\}/{exit}' "$SRC" > "$TMP/fn.sh"
if ! grep -q "check_disposition_gate()" "$TMP/fn.sh"; then
  echo "FAIL: could not extract check_disposition_gate from $SRC" >&2; exit 1
fi

# Harness: stub the ambient vars/helpers the function references, then call it.
cat > "$TMP/run.sh" <<'EOF'
GREEN=''; YELLOW=''; RED=''; NC=''
SKIP_DISPOSITION_GATE=false
log_gate_bypass() { :; }
TASK_FILE="$1"
source "$2"
check_disposition_gate
EOF

# (a) fully disposed, but IW-1's rationale cross-references "IW-2" in prose.
cat > "$TMP/pass.md" <<'EOF'
---
id: T-FIXTURE-PASS
workflow_type: inception
---
## Open Questions
- **IW-1: First question?**
  confidence: 3
  disposition: answered
  rationale: Resolved; the dominant cost is IW-2, not this one (prose cross-reference).
- **IW-2: Second question?**
  confidence: 3
  disposition: answered
  rationale: Resolved independently.

## Exploration Plan
EOF

# (b) IW-1 has no disposition line at all — genuinely under-disposed.
cat > "$TMP/fail.md" <<'EOF'
---
id: T-FIXTURE-FAIL
workflow_type: inception
---
## Open Questions
- **IW-1: First question?**
  confidence: 1
  rationale: No disposition line — genuinely under-disposed.

## Exploration Plan
EOF

rc=0

if bash "$TMP/run.sh" "$TMP/pass.md" "$TMP/fn.sh" >/dev/null 2>&1; then
  echo "PASS: cross-reference fixture accepted (no false under-disposed)"
else
  echo "FAIL: cross-reference fixture wrongly blocked (T-203 regression)" >&2; rc=1
fi

if bash "$TMP/run.sh" "$TMP/fail.md" "$TMP/fn.sh" >/dev/null 2>&1; then
  echo "FAIL: under-disposed fixture wrongly accepted (gate lost its teeth)" >&2; rc=1
else
  echo "PASS: under-disposed fixture correctly blocked (teeth intact)"
fi

[ "$rc" -eq 0 ] && echo "OK: disposition gate — cross-ref tolerated, under-disposed blocked"
exit $rc
