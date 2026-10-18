# T-1127 AC#1 — independent review (rung-3-termlink-single-reviewer)

Reviewer dispatch: judge-t-1127-r3-c0e166e3c4f4
Revision: 4bb76f2626f2191c0158474bb9d5d3f2f030f0a1
Source: docs/reports/T-1127-evidence/2026-10-19-full/ (six shots; copies in this directory as AC1-judge-t-1127-r3-c0e166e3c4f4-t1127-details-*.png)

## TOP shots (t1127-details-{1024,1440,1920}.png)
For each width I checked:
- Title "Call the service — details" + subtitle, and the Close button (top right): visible and unclipped at all three.
- Element header: serviceTask icon, "serviceTask", "age_1_call": visible at all three.
- BPMN section in two columns: Name (Call the service), Slug (call, read-only), Display ID (age_1_call), UID (n_0851b8c9), Lane (lane_a select): all present at all three.
- Extensions (AEF:) in two columns, filled and empty: Authority, Horizon, Workflow type, Tier, Determinism, Agent type, Endpoint (svc/call), Context reads, Artifacts writes, Side effect (writes the ledger twice); at 1440/1920 also Fabric component and Links; at 1920 also Note and Owner.
- Tier buttons T0/T1/T2/T3 with T2 selected (green): fully visible at all three.
- Orange "hidden in the side panel by this project" under Horizon: present at all three.
- No overlap or horizontal clipping. At 1024 the lowest row (Artifacts writes / Side effect) is cut by the modal's scroll edge. That is ordinary scrolling, the modal has a scrollbar, and the row appears in full in the bottom shot.

## BOTTOM shots (t1127-details-{1024,1440,1920}-bottom.png)
- Lower Extensions: Fabric component, Links, Note, Owner ("— none —", derived from lane): visible and unclipped at all three.
- OTHER EXTENSIONS · 1: explanatory text, read-only customKey row with value "kept", the caption "customKey · on 1 of 2 serviceTask elements" and the "Suggest as a field" button: visible at all three.
- I/O CONTRACT (AEF:): inputs (no inputs) with "+ add input"; outputs (no outputs) with "+ add output": visible at all three, with the section's bottom border showing (true end of content).
- No clipping or overlap. Text wraps cleanly inside the modal at 1024.

## Two-column use of space
Two columns at every width (≈437px each at 1024, ≈437px at 1440, ≈437px at 1920). The modal is capped at about 980px wide and centred, so at 1920 there is spare margin. Even so, the two columns fill the modal and the criterion ("uses the space in two columns") is met.

## Verdict: green
Every listed control is visible, reachable (via the modal's own scroll) and unclipped at 1024, 1440 and 1920, laid out in two columns.

Non-blocking note: at 1920 the modal does not grow past about 980px. That is acceptable under the criterion as written.
