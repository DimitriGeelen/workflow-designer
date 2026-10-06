# T-308 AC1 — neutral glyph reads as "event of unspecified kind"
Reviewer: reviewer-judge-t-308-r5-claude-code-8f8f23a9feb9 (rung-5-panel:claude-code) · revision 6e7bfdf5

## What I did
- Confirmed the live Watchtower designer (`http://192.168.10.107:3013/designer/app`, HTTP 200) is serving T-308 code (11 matches for `isBareCatchEvent|sessionAuthoredLinks` in the served page).
- Drove it in headless Chromium with an isolated, throwaway profile using my own CDP probe (`probe-judge-t-308-r5-claude-code-8f8f23a9feb9.mjs.txt`; raw output `probe-log-judge-t-308-r5-claude-code-8f8f23a9feb9.json`). Nothing was saved to the server.
- Imported `tests/fixtures/aef-bpmn/bare-catch-event.bpmn` with `adoptImportedXml(text,{userImport:true})`, the same call the Load file-picker makes (`src/aef-workflow-designer.html` ~10641). I did not drive the OS file dialog.
- Compared the bare node with the uuid-bound handoff, the legacy-slug handoff and the typed message catch, on the canvas and in the inspector.

## Findings
- Canvas (`ac1-row-bare-bound-slug-typed-judge-t-308-r5-claude-code-8f8f23a9feb9.png`):
  - **bare** `n_bare` "awaiting upstream signal": a plain BPMN double ring (2 circles, 0 paths). The stroke is `--text-faint` #5a6173 on the dark node fill. There is no chevron, no red and no warning glyph of its own.
  - **bound** `n_bound` / `n_slug`: a lime (#c4ee54) ring with an inward chevron (1 circle, 1 path). This is unchanged.
  - **typed** `n_typed`: a green ring with an envelope. This is unchanged.
  - The "⚠ no authority" badge appears on every node in the lane (start excepted), the bound and typed nodes included. It comes from lane/authority validation and is not part of the bare node's styling.
- Inspector:
  - Bare (`ac1-panel-n_bare-judge-t-308-r5-claude-code-8f8f23a9feb9.png`): the badge is the double ring with the type name `intermediateEvent`. An "EVENT KIND" note reads "carries no kind and no handoff target … valid as it stands and exports unchanged", followed by a "← Make this a handoff" button. None of the dead target fields are shown.
  - Bound (`ac1-panel-n_bound-judge-t-308-r5-claude-code-8f8f23a9feb9.png`): the full Extensions section is present (Workflow ref, Ref display name, Target picker, Open target workflow, Link ID).
  - Typed (`ac1-panel-n_typed-judge-t-308-r5-claude-code-8f8f23a9feb9.png`): the Bus topic and boundary fields are present.

## Judgement
- The bare node reads as the standard BPMN "intermediate event, no trigger": a neutral, unspecified event.
- It is clearly **not a handoff**: it has a different colour and no chevron, and it sits directly next to two real handoffs.
- It is clearly **not an error**: there is no red, no dashed or broken outline and no node-specific warning, and the panel explicitly says the event is valid.
- One mild caveat: muted grey could read as "inactive" to a viewer who doesn't know BPMN. The double ring and the panel note offset this, and it does not read as broken or missing.

Verdict: green.
