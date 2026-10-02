#!/usr/bin/env bash
# T-1006: a learning is confirmed by a green evidence re-run plus agreement from >= 2 vendors other
# than the author's; disagreement escalates; the operator rules only on value/priority. Stub reviewers.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$ROOT/tools/learning-ledger.py"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "PASS $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }
L() { python3 "$T" --ledger "$W/l.yaml" "$@"; }
# controls: every stub reviewer name used below has disagreed with a planted-false lesson
cat > "$W/ctl.yaml" <<'YAML'
learnings:
- {id: C1, learning: planted, evidence: e, source: loop, destination: guide, status: proposed, occurrences: 1,
   verdicts: [{reviewer: codex, vendor: openai, verdict: disagree}, {reviewer: glm, vendor: zai, verdict: disagree},
              {reviewer: r-openai, vendor: openai, verdict: disagree}, {reviewer: r-zai, vendor: zai, verdict: disagree},
              {reviewer: gpt-other, vendor: openai, verdict: disagree}, {reviewer: sonnet, vendor: anthropic, verdict: disagree},
              {reviewer: gemini, vendor: google, verdict: disagree}]}
YAML
C() { python3 "$T" --ledger "$W/l.yaml" confirm "$@" --controls "$W/ctl.yaml"; }

stub() {  # stub <name> <reply> — a reviewer that ignores its prompt and prints a fixed reply
  printf '#!/bin/sh\nprintf %%s %q\n' "$2" > "$W/$1"; chmod +x "$W/$1"; }
stub agree    '{"verdict": "agree", "reason": "matches BPMN semantics"}'
stub disagree 'thinking... {"verdict": "disagree", "reason": "evidence does not show it"}'
stub refine   '{"verdict": "refine", "reason": "too broad", "refinement": "narrower"}'
stub garbage  'I think this is probably fine overall.'

fresh() {
  cat > "$W/l.yaml" <<YAML
legacy_until: L1
learnings:
- {id: L1, learning: old, evidence: e, source: human, destination: rubric, status: promoted,
   occurrences: 1, confirmed_by: operator, promoted: {where: sidecar:x}}
- {id: L2, learning: new lesson, evidence: e, source: loop, destination: guide, status: proposed,
   occurrences: 1, evidence_cmd: 'true', proposed_change: add a line}
YAML
}

# 1. quorum met: two vendors agree, evidence green -> confirmed
fresh; L review L2 --reviewer-cmd "$W/agree" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor zai --name glm >/dev/null
C L2 >/dev/null && grep -q "status: confirmed" "$W/l.yaml" && L check >/dev/null \
  && ok "two vendors + green evidence confirms" || bad "two vendors + green evidence confirms"

# 2. two reviewers of the SAME vendor are one view
fresh; L review L2 --reviewer-cmd "$W/agree" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor openai --name gpt-other >/dev/null
C L2 > "$W/o" ; grep -q "need 2" "$W/o" && ! grep -q "status: confirmed" "$W/l.yaml" \
  && ok "same-vendor agreement does not reach quorum" || bad "same-vendor agreement does not reach quorum"

# 3. the author's vendor does not count
fresh; L review L2 --reviewer-cmd "$W/agree" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor anthropic --name sonnet >/dev/null
C L2 > "$W/o" ; grep -q "agree from 1 vendor" "$W/o" \
  && ok "author vendor excluded" || bad "author vendor excluded"

# 4. a disagree escalates even with two agrees
fresh; for v in openai zai; do L review L2 --reviewer-cmd "$W/agree" --vendor $v --name r-$v >/dev/null; done
L review L2 --reviewer-cmd "$W/disagree" --vendor google --name gemini >/dev/null
C L2 > "$W/o"; grep -q "status: escalated" "$W/l.yaml" && grep -q "standing disagree" "$W/o" \
  && ok "disagree escalates" || bad "disagree escalates"

# 5. a refine also blocks (the lesson must be reworded and re-reviewed)
fresh; for v in openai zai; do L review L2 --reviewer-cmd "$W/agree" --vendor $v --name r-$v >/dev/null; done
L review L2 --reviewer-cmd "$W/refine" --vendor google --name gemini >/dev/null
! C L2 >/dev/null && grep -q "refinement: narrower" "$W/l.yaml" \
  && ok "refine blocks and records the refinement" || bad "refine blocks and records the refinement"

# 6. failing evidence refuses despite quorum
fresh; sed -i "s/evidence_cmd: 'true'/evidence_cmd: 'false'/" "$W/l.yaml"
for v in openai zai; do L review L2 --reviewer-cmd "$W/agree" --vendor $v --name r-$v >/dev/null; done
C L2 > "$W/o"; grep -q "evidence_cmd exits 1" "$W/o" \
  && ok "red evidence refuses" || bad "red evidence refuses"

# 7. an unparseable reply is no-verdict, never agree
fresh; L review L2 --reviewer-cmd "$W/garbage" --vendor openai --name codex >/dev/null; rc=$?
[ $rc -eq 3 ] && grep -q "verdict: no-verdict" "$W/l.yaml" \
  && ok "garbage reply = no-verdict (rc 3)" || bad "garbage reply = no-verdict (rc 3)"

# 8. operator: confirm --by and a correctness ruling are refused; value ruling recorded
fresh; ! C L2 --by operator 2>/dev/null && ! L rule L2 --kind correctness --decision yes 2>/dev/null \
  && L rule L2 --kind priority --decision "after 0.15.3" >/dev/null && grep -q "kind: priority" "$W/l.yaml" \
  && ok "operator rules value/priority only" || bad "operator rules value/priority only"

# 9. check: legacy L1 valid; a hand-edited 'confirmed' without the panel is flagged
fresh; L check >/dev/null || bad "legacy entry flagged"
sed -i "s/status: proposed/status: confirmed/" "$W/l.yaml"
L check > "$W/o"; grep -q "without a green evidence re-run" "$W/o" && grep -q "without agreement from 2 vendors" "$W/o" \
  && ok "check flags a confirmation without evidence/quorum" || bad "check flags a confirmation without evidence/quorum"

# 10. a reviewer's later verdict replaces its earlier one (re-review after refinement)
fresh; L review L2 --reviewer-cmd "$W/refine" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor zai --name glm >/dev/null
C L2 >/dev/null && ok "latest verdict per reviewer counts" || bad "latest verdict per reviewer counts"

# 11. parallel reviews (each slow) must not lose each other's verdict
printf '#!/bin/sh\nsleep 1\nprintf %%s %q\n' '{"verdict": "agree", "reason": "slow"}' > "$W/slow"; chmod +x "$W/slow"
fresh; L review L2 --reviewer-cmd "$W/slow" --vendor openai --name codex >/dev/null &
L review L2 --reviewer-cmd "$W/slow" --vendor zai --name glm >/dev/null & wait
[ "$(grep -c 'verdict: agree' "$W/l.yaml")" -eq 2 ] && ok "parallel reviews both recorded" || bad "parallel reviews both recorded"

# 12. revising the wording voids earlier verdicts; re-review on the new revision confirms
fresh; for v in openai zai; do L review L2 --reviewer-cmd "$W/agree" --vendor $v --name r-$v >/dev/null; done
L revise L2 --learning "narrower lesson" --why "codex refinement" >/dev/null
C L2 > "$W/o"; c1=$?
for v in openai zai; do L review L2 --reviewer-cmd "$W/agree" --vendor $v --name r-$v >/dev/null; done
C L2 >/dev/null; c2=$?
[ $c1 -ne 0 ] && grep -q "need 2" "$W/o" && [ $c2 -eq 0 ] && grep -q "why_revised: codex refinement" "$W/l.yaml" \
  && ok "revision voids old verdicts; new ones count" || bad "revision voids old verdicts; new ones count"

# 13. reviewer calibration: an agree from a reviewer fooled by a plant, or with no control result, does not count
fresh; L review L2 --reviewer-cmd "$W/agree" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor zai --name glm-untested >/dev/null
C L2 > "$W/o"; u=$?
sed -i 's/{reviewer: glm, vendor: zai, verdict: disagree}/{reviewer: glm-untested, vendor: zai, verdict: agree}/' "$W/ctl.yaml"
C L2 > "$W/o2"; f=$?
# and a calibrated pair still confirms even with an uncounted extra agree alongside
L review L2 --reviewer-cmd "$W/agree" --vendor google --name gemini >/dev/null; C L2 >/dev/null; g=$?
[ $u -ne 0 ] && grep -q "glm-untested (no control result yet)" "$W/o" && grep -q "agree from 1 vendor" "$W/o" \
  && [ $f -ne 0 ] && grep -q "glm-untested (fooled by a planted-false control)" "$W/o2" && [ $g -eq 0 ] \
  && ok "uncalibrated or fooled reviewer's agree does not count" || bad "uncalibrated or fooled reviewer's agree does not count"

# 14. a confirmation made before calibration is flagged by check; re-check demotes it if quorum now fails
fresh; L review L2 --reviewer-cmd "$W/agree" --vendor openai --name codex >/dev/null
L review L2 --reviewer-cmd "$W/agree" --vendor zai --name glm >/dev/null
C L2 >/dev/null && python3 - "$W/l.yaml" <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
x = [e for e in d['learnings'] if e['id'] == 'L2'][0]; x['confirmation'].pop('reviewers_calibrated')
yaml.safe_dump(d, open(p, 'w'), sort_keys=False)
PY
L check > "$W/o"; k=$?
sed -i 's/{reviewer: glm, vendor: zai, verdict: disagree}/{reviewer: glm, vendor: zai, verdict: agree}/' "$W/ctl.yaml"
C L2 >/dev/null; r=$?
[ $k -ne 0 ] && grep -q "before reviewers had to pass" "$W/o" && [ $r -ne 0 ] && grep -q "status: proposed" "$W/l.yaml" \
  && grep -q "demoted_from: confirmed" "$W/l.yaml" && ok "pre-calibration confirmation flagged; failed re-check demotes" \
  || bad "pre-calibration confirmation flagged; failed re-check demotes"

echo "t1006: $pass passed, $fail failed"
[ $fail -eq 0 ]
