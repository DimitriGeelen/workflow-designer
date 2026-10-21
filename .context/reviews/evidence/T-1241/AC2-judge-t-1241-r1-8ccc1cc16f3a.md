# T-1241 Human AC#2: operator opens aef-task-lifecycle in the business lens and can follow it

Reviewer: judge-t-1241-r1-8ccc1cc16f3a (rung-1-same-vendor-independent). Bound revision: 9a638fca96af5c182734887211c51f9eaa1ce5d6.

## What I did
1. Took `src/aef-workflow-designer.html` and `.agentic-framework/.context/designer/projects/aef-task-lifecycle/v3.bpmn`
   from the bound revision (`git show 9a638fca:...`) into a scratch dir.
2. Opened the designer in headless Chromium (Playwright) at 1440x900, waited for `_appReady`, and imported v3 of the map.
3. Looked for the lens switch (step 2 of the criterion's steps).

## What I found
- `document.getElementById('lens-select')`: **absent**. `typeof setLens`: **undefined**.
- Toolbar at the revision: "AEF · BPMN Workflow Designer v0.24.0 · + instances: unavailable − fit + ⤢ ◧ ◨ ⛶ + Add Lane Reset
  ✨ Clean layout View XML ⚙ Settings Load… Save". There is no Lens control.
- `grep -ci lens` on the designer source at 9a638fca: 0 matches. `tools/gallery-serve.py` at 9a638fca: 0 matches (no
  `/api/lens-definition` route). `lens-definition.interim.json`, `tools/_t1241-lens-shots.py` and
  `docs/reports/T-1241-evidence/` are not in the tree at 9a638fca.
- Screenshot: `AC2-judge-t-1241-r1-8ccc1cc16f3a-rev9a638fca-1440.png`. The map renders with the technical noise the
  criterion says should be gone: id captions under each node (`aef_t_create` …), the pool label
  "AEF task lifecycle · workflow:aef-task-lifecycle", and the workflow panel with ID, tier and Kind fields.

So at the bound revision step 2 ("Switch the toolbar lens to Business") can't be done, and the criterion is not met.

## Note (not evidence for this verdict)
The working tree has **uncommitted** lens changes (`git status`: `M src/aef-workflow-designer.html`,
`M tools/gallery-serve.py`, `?? lens-definition.interim.json`, `?? tools/_t1241-lens-shots.py`,
`?? docs/reports/T-1241-evidence/`). I did not judge them. My verdict is bound to 9a638fca, and uncommitted work is
not that revision.
