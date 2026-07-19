#!/usr/bin/env bash
# G-009 regression (T-210): check_acceptance_criteria must strip one-line AC comments
# that contain a literal '>' (AC comments routinely cite XML/HTML tags). The old
# `[^>]*` one-line strip stopped at the first '>', left the comment in place, and the
# following range strip then swallowed the `### Human` header — mis-attributing an
# unchecked Human AC as an unchecked agent AC and HARD-BLOCKING the partial-complete
# review handoff. This exercises the REAL function extracted verbatim from
# update-task.sh, so a future edit to the function is what this test measures.
#
#   pass fixture  — all agent ACs checked (comments contain '>'), one unchecked Human
#                   AC → must NOT block (agent-complete; Human AC is not blocking).
#   teeth fixture — one genuinely unchecked AGENT AC (comments also contain '>') →
#                   must STILL block (the gate keeps its teeth).
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../update-task.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Extract the function verbatim: decl line .. first column-0 closing brace.
awk '/^check_acceptance_criteria\(\) \{/{f=1} f{print} f&&/^\}/{exit}' "$SRC" > "$TMP/fn.sh"
if ! grep -q "check_acceptance_criteria()" "$TMP/fn.sh"; then
  echo "FAIL: could not extract check_acceptance_criteria from $SRC" >&2; exit 1
fi

# Harness: stub the ambient vars/helpers the function references, then call it.
# check_acceptance_criteria exits 1 on block and falls through (return) on pass;
# it also sets PARTIAL_COMPLETE/HUMAN_AC_* which we don't assert here — the exit
# code is the gate signal.
cat > "$TMP/run.sh" <<'EOF'
GREEN=''; YELLOW=''; RED=''; NC=''
SKIP_AC=false
PARTIAL_COMPLETE=false
log_gate_bypass() { :; }
TASK_FILE="$1"
source "$2"
check_acceptance_criteria
EOF

# (a) PASS: every agent AC is checked AND carries a one-line comment containing '>'
#     (a bpmn tag). One unchecked Human [REVIEW] AC. The gate must not block.
cat > "$TMP/pass.md" <<'EOF'
---
id: T-FIXTURE-PASS
workflow_type: build
---
## Acceptance Criteria

### Agent
- [x] Serializes each event as `<bpmn:startEvent>` correctly. <!-- emits <bpmn:startEvent> + <extensionElements> -->
- [x] Attaches via `<bpmn:boundaryEvent attachedToRef=..>`. <!-- native attrs; kind rides <aef:eventDef kind=..> -->
- [x] Round-trip guard stays green. <!-- export->import->export stable; asserts <aef:eventDef> present -->

### Human
- [ ] [REVIEW] Nodes render correctly across visual modes.
  **Steps:** open the served designer, place each event.
  **Expected:** distinct legible glyphs.
  **If not:** screenshot the failing mode.

## Verification
EOF

# (b) TEETH: one genuinely unchecked AGENT AC (comments also contain '>'). Must block.
cat > "$TMP/fail.md" <<'EOF'
---
id: T-FIXTURE-FAIL
workflow_type: build
---
## Acceptance Criteria

### Agent
- [x] Serializes each event as `<bpmn:startEvent>` correctly. <!-- emits <bpmn:startEvent> -->
- [ ] Attaches via `<bpmn:boundaryEvent attachedToRef=..>`. <!-- NOT done yet: <bpmn:boundaryEvent> -->

### Human
- [ ] [REVIEW] Nodes render correctly.
  **Steps:** open the served designer.
  **Expected:** legible glyphs.
  **If not:** screenshot.

## Verification
EOF

rc=0

if bash "$TMP/run.sh" "$TMP/pass.md" "$TMP/fn.sh" >/dev/null 2>&1; then
  echo "PASS: '>'-comment fixture accepted (Human AC not miscounted as agent AC)"
else
  echo "FAIL: '>'-comment fixture wrongly blocked (G-009 regression)" >&2; rc=1
fi

if bash "$TMP/run.sh" "$TMP/fail.md" "$TMP/fn.sh" >/dev/null 2>&1; then
  echo "FAIL: unchecked-agent-AC fixture wrongly accepted (gate lost its teeth)" >&2; rc=1
else
  echo "PASS: unchecked-agent-AC fixture correctly blocked (teeth intact)"
fi

[ "$rc" -eq 0 ] && echo "OK: AC comment strip — '>'-bearing comments tolerated, teeth intact"
exit $rc
