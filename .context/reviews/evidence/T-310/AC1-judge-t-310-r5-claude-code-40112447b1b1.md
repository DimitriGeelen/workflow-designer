# T-310 Human AC#1 — reviewer judge-t-310-r5-claude-code-40112447b1b1 (rung-5-panel:claude-code)

Revision reviewed: 2c952a3e6d525bf14d41589069f1c3bb8be95d01 (HEAD at review time).

## What I did
1. Ran `node tools/_t310-lane-position-conflict-cdp.mjs` (headless Chromium, real editor
   `src/aef-workflow-designer.html`, fixture `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn`).
   Result: `ok: true`, `reconciled: 2`, `errs: []`, re-import of export reconciles 0.
   Notice text: "⚠ 2 nodes were drawn outside their declared lane — moved back into place".
   Node results: n_check (framework validates the request) lane=framework, centre y 302 in
   framework band 222..382; n_act (agent carries out the work) lane=agent, centre y 142 in agent
   band 62..222; n_start y=110 and n_done y=310 unchanged (agreeing nodes untouched).
2. Took my own screenshot of the live editor after the same import path the 📂 Open / Load
   button uses (`adoptImportedXml(text, {userImport:true})`): `AC1-judge-t-310-r5-claude-code-40112447b1b1-after.png`
   (scratch script in /tmp, outside the repo).
3. Compared visually with `docs/screenshots/t310-both-before.png`.

## What I saw
- Before (old build): "framework validates the request" in the Agent · Initiative lane;
  "agent carries out the work" in the Framework · Authority lane, i.e. swapped.
- After (this build, my screenshot): "framework validates the request" sits in
  **Framework · Authority**; "agent carries out the work" sits in **Agent · Initiative**.
  "request arrives" stays in Agent and "recorded" stays in Framework at their original places.
  x positions are preserved; only the two conflicting nodes moved vertically.
- Notice at the top of the canvas: "⚠ 2 nodes were drawn outside their declared lane — moved
  back into place" (dismissible ×). Count 2 matches.

## Judgement
It reads as a repair: the notice names the cause (drawn outside the declared lane) and says what
was done, the count matches, only the conflicting nodes moved, and nothing that agreed was
rearranged. Expected outcome met. Verdict: green.
