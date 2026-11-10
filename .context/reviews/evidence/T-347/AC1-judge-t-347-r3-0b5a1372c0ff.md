# T-347 Human AC#1 — "Choose repair semantics for unconsumed element content"

Reviewer dispatch: judge-t-347-r3-0b5a1372c0ff · revision 6825586eca5c8409989fcdfe9933adb2929dbfe7 · rung-3-termlink-single-reviewer

## Expected
"a choice recorded in `## Decisions` with its rationale."

## Steps 1-2: I ran the instrument myself (HEAD = 6825586ec, the bound revision)
`timeout 300 node tools/_t347-accepted-element-content-cdp.mjs` → rc=0 (/tmp had 9.1 GB free).
PER-SHAPE VERDICT (denominator = carrying files only; n/a files excluded):
- documentation 0/2 carriers LOSE it (9 cannot answer)
- extChildren   0/6 (5 cannot answer)
- property      0/2 (9 cannot answer)
- loopChars     0/2 (9 cannot answer)
- unknownAttrs  0/3 (8 cannot answer)
All shapes survive on every carrier. That matches the two earlier r3 runs and is consistent with (a) having been built.
The criterion's 2026-08-03 note ("lost on 100% ... to exactly zero") is historical context for the decision. It is not part
of Steps or Expected, and those still run as written.

## Step 3 / Expected: the choice is in `## Decisions`
`.tasks/active/T-347-content-inside-an-accepted-element-is-si.md` `## Decisions` has the entry
"### 2026-10-10 — what the designer does with content it does not understand (operator ruling, recorded by the agent)".
`git log -L` shows it was introduced by d436d0482 (2026-10-10).
- Chose: (a) preserve and re-emit (R1), quoted as the operator's choice ("certainly one"). R2 is an operator-approved suggestion,
  not an automatic (b).
- Why: nothing is lost silently, based on the measured loss on third-party carrying files.
- Rejected: (c) refuse, because Greenfield's maps could not be opened; (b) as an automatic mapping.
- Open: R1a, and R2/visibility in their own inception. These are implementation sub-questions and do not reopen (a)/(b)/(c).
The choice is one of the three options and gives a rationale and the rejected alternatives. It is attributed to the operator,
so no direction call is left open for the human.

## Working tree vs bound revision
The working tree's task file differs from 6825586ec only in the frontmatter owner/node, the Human AC checkbox (unticked)
and the removal of a previous verdict line. `## Decisions` is identical.

## Prior evidence checked, not taken on trust
r1 (af3a1d1c) showed partial losses. r3 02b81446 (7b2f9f40) and r3 56ec9fc5 (37ca0477) showed none. My run at 6825586ec
agrees with the r3 runs.

## Limits
I cannot see the chat ruling itself. I verified that it is recorded with its rationale, which is what Expected asks.
`bin/fw` does not exist at the repo root. I used `fw` on PATH, which resolves to .agentic-framework/bin/fw.

## Verdict: green
