# T-347 Human AC#1 — "Choose repair semantics for unconsumed element content"

Reviewer dispatch: judge-t-347-r1-cbcf4197d9ba · revision af3a1d1c2fe90cdcca6302fe06e6e8cef7f4837b · rung-1-same-vendor-independent

## Expected (from the criterion)
"a choice recorded in `## Decisions` with its rationale."

## What I checked

### 1. Steps 1-2 re-run (instrument)
`timeout 300 node tools/_t347-accepted-element-content-cdp.mjs` → exit 0. Positive control `arc-lifecycle`: no shape lost.
PER-SHAPE VERDICT (denominator = carriers only):
- documentation  1/2 carriers lose it (bizagi-nested-ns; i18n-documentation now keeps 1->1)
- extChildren    6/7 lose it (aef-draft-inception-readiness-v2 keeps 87->87)
- property       1/2 lose it (caseagile-local-ns; kitchen-sink keeps 1->1)
- loopChars      2/2 lose it
- unknownAttrs   3/3 lose it
Several losses are now partial (e.g. caseagile extChildren 405->144, bizagi 30->5), not "always to exactly zero"
as the 2026-08-03 text says. The 2026-10-18 currency note in `docs/reports/T-347-accepted-element-content.md`
already records the 1/2 and 6/7 figures, so the report is current. The loss is still live on every shape, so the
case the choice rests on (unconsumed content is silently lost on real third-party files) still holds.

### 2. Step 3 / Expected — choice recorded in `## Decisions`
`.tasks/active/T-347-content-inside-an-accepted-element-is-si.md`, `## Decisions`, entry
"2026-10-10 — what the designer does with content it does not understand (operator ruling, recorded by the agent)":
- **Chose:** (a) preserve-and-re-emit (R1). R2 is an operator-approved *suggestion* per unknown kind (not automatic (b)),
  plus per-project/per-workflow field visibility.
- **Why:** nothing is lost silently (cites the measured loss on third-party files).
- **Rejected:** (c) refuse (Greenfield's maps could not be opened); (b) as an automatic mapping.
- **Open:** R1a (a second pool kept unchanged with an import notice) awaits operator confirmation; R2 and visibility go to
  inception T-1118.
Introduced by commit d436d048 (2026-10-10, "operator ruling recorded"). The decision is cross-referenced in the T-347
report's currency note and the task's 2026-10-18 update.

### 3. Consistency
The choice is one of the three offered options. It matches the T-337 precedent and "diagram XML is never silently
migrated" cited in the criterion. The rationale addresses the evidence and gives reasons for rejecting both alternatives.

## Limits
- The ruling was given in chat, and an agent recorded it. I cannot see the chat, so I cannot independently confirm the
  operator's exact wording. The criterion's Expected is that the choice is *recorded with rationale*, and I verified that directly.
- R1a is explicitly still open. It is a sub-option of the implementation, not the (a)/(b)/(c) choice this criterion asks for.
- R1 is not built (the loss is still live). That is the scope of the task's other ACs, not this one.

## Verdict: green
