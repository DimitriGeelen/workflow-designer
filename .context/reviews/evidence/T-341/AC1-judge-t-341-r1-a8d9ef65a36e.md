# T-341 Human AC#1 — independent review (rung-1-same-vendor-independent)

Revision reviewed: 0b9b0f538995c85e50a96782a0009cb6e6d47bb7 (HEAD; working tree has no diff on the three files checked).

## 1. Ruling: docs/reports/T-888-authority-ruling.md
- Clause 2 (line 17): "The element carries its authority. One field, one home ... The compiler reads it
  directly: never by scanning lane membership". Authority is element-level.
- "Downstream" paragraph on T-341 (lines 86-91): "Under clause 2 the authority half dissolves: an element's
  authority no longer depends on lane membership at all, so no orphan inherits anything. The surviving half
  is the placement question ... which is layout, not governance. The hard-error fix for an unresolvable ref
  ... is filed as its own task."
- HOLDS.

## 2. Editor: src/aef-workflow-designer.html
- Lines 11941-11963: the T-891 comment explains the old `lanes[0]?.id` initialiser was removed; now
  `let laneId = null;` and it is set only if some lane's flowNodeRef list includes the node's id.
- Line 12119: node built with `lane: laneId` (no fallback).
- grep for `.lane ||`, `.lane ??`, and `lanes[0]?.id` finds no other fallback that would reassign an
  orphan to the first lane (the only `lanes[0]?.id` hit is inside the T-891 comment).
- HOLDS: the editor invents no lane for an orphan. (Visual import in a browser was not done. The optional
  step 4 for the editor was checked by reading the code only.)

## 3. Validator: tools/validate-workflow.py
- Lines 1300-1326: rule `E-XML-NODE-UNASSIGNED` raised via `self.err` (ERROR, promoted from WARN by T-891)
  for every flow node not in the `assigned` set built from lane flowNodeRefs.
- Executed check (step 4, validator half): the fixture tests/fixtures/invalid/E-XML-NODE-UNASSIGNED.xml with a
  dangling `<bpmn:flowNodeRef>frw_2_typo</bpmn:flowNodeRef>` added (copy:
  dangling-flownoderef-<dispatch>.xml in this directory). `python3 -I tools/validate-workflow.py` output:
    ERROR [E-XML-LANEREF-DANGLING] flowNodeRef 'frw_2_typo': ... does not resolve to a flow-node bpmn:id
    ERROR [E-XML-NODE-UNASSIGNED] node 'frw_2_b': flow node 'frw_2_b' is in no lane ... must not be invented
    INVALID -- 2 error(s), 2 warning(s); exit=2
- HOLDS. The dangling ref itself is also reported (E-XML-LANEREF-DANGLING).

## Verdict: green
All three parts of the Expected outcome hold. Nothing named in "If not" fails.
