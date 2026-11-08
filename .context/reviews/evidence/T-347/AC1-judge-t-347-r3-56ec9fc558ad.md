# T-347 Human AC#1 — "Choose repair semantics for unconsumed element content"

Reviewer dispatch: judge-t-347-r3-56ec9fc558ad · revision 37ca04778b969a8e4d99fb539cc54012e1f49345 · rung-3-termlink-single-reviewer

## Expected
"a choice recorded in `## Decisions` with its rationale."

## Steps 1-2: I ran the instrument myself (HEAD = 37ca04778)
`timeout 300 node tools/_t347-accepted-element-content-cdp.mjs` → rc=0. Positive control arc-lifecycle: no shape lost.
PER-SHAPE VERDICT (denominator = carriers only):
- documentation 0/2 carriers lose it
- extChildren   0/6 lose it (e.g. caseagile-local-ns kept 405->405, bizagi-nested-ns kept 30->30)
- property      0/2 lose it
- loopChars     0/2 lose it
- unknownAttrs  0/3 lose it
Every shape now survives on every carrier. This differs from the r1 run on af3a1d1c, which showed 1/2, 6/7, 1/2, 2/2, 3/3.
It is consistent with (a) having been built: T-1325 did flow nodes and flows, and commit 4f474ea43 (T-347) did `<aef:eventDef>`.
The criterion's 2026-08-03 note ("all five shapes are lost on 100% ... to exactly zero") is therefore historical. It is context
for the decision, not the Steps or Expected. Steps 1-2 still run as written, and the choice was taken while the loss was live.

## Step 3 / Expected: the choice is recorded in `## Decisions` (at revision 37ca04778)
`.tasks/active/T-347-content-inside-an-accepted-element-is-si.md`, `## Decisions`, entry
"2026-10-10 — what the designer does with content it does not understand (operator ruling, recorded by the agent)":
- Chose: (a) preserve and re-emit (R1), quoted as the operator's choice in chat ("certainly one"). R2 is a per-kind
  suggestion that the operator approves, not an automatic (b). Per-project and per-workflow field visibility go to their own inception.
- Why: nothing is lost silently, based on the measured loss on third-party files.
- Rejected: (c) refuse, because Greenfield's maps could not be opened; (b) as an automatic mapping.
- Open: R1a awaits the operator's confirmation. It is a sub-option of the implementation, not the (a)/(b)/(c) choice.
The choice is one of the three options and has a rationale and rejected alternatives. It is attributed to the operator, so this
is not an agent taking a direction call for itself. The task body (line ~113) and the 2026-10-18 update cross-reference the ruling.

## Limits
- The ruling was given in chat, and I cannot see the chat. I verified that it is recorded with rationale, which is what Expected asks.
- I verified r1's evidence file independently, not on trust. My instrument numbers differ from it because the code changed since af3a1d1c.

## Verdict: green
