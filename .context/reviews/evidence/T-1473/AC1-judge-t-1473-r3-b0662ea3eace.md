# T-1473 Human AC#1 — reviewer evidence (judge-t-1473-r3-b0662ea3eace)

Revision reviewed: e4f24ba64b5938c7e7726413e4bc15687480ff6e
Images (copies): phases-1024-*.png, phases-1440-*.png, phases-1920-*.png (originals: docs/reports/T-1473-shots/)
Fixture reference: tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn (Process_Nooteboom)

## Phase sets in the fixture (categoryValue names)
- Row "Fase": Opportunity; Configuratie; Offerte & onderhandeling; Order; Productie & service
- Row "Fase in Salesforce": 1 Qualification; 2 Needs Analysis (blijft tot Proposal); 3 Proposal; 4 Negotiation; 5 Closed Won; Sales Order: Open Order → Complete + Download

## What the images show
- The two tiers are separate: the upper bracket tier holds the numbered Salesforce stages, the lower tier holds Opportunity / Configuratie. The tiers do not align with each other, so they read as two different phase sets.
- Bracket placement is consistent with step content: in the 1440 shot, Opportunity spans Start, "Opportunity aanmaken" and "Knop Tacton"; Configuratie starts at "Opportunity – Solution". In the 1920 shot, "2 Needs Analysis" starts over "Knop Tacton (status: Needs Analysis)", which matches its status.
- Dashed dividers sit in gaps between nodes at the Opportunity/Configuratie boundary (1440 at x≈1083; 1920 at x≈812 and x≈1445). They cross only edges (the trigger elbow, the dashed Product→Solution edge), not node bodies or labels.
- The 1024 and 1440 shots clip phase names at the canvas edge: "2 Needs Analysis (blijft t…" (1024, 1440), "Configuratio…" (1440). These are viewport clips, so the names are partly unreadable in the opening view.
- None of the three shots shows the right-hand part of the pool. Phases 3 Proposal, 4 Negotiation, 5 Closed Won, Sales Order, Offerte & onderhandeling, Order and Productie & service are off-screen or only partly visible (1920 shows a sliver of "3" and an "Op…" node at the right edge). I cannot judge whether those stretches are labelled and divided correctly.
- The row names "Fase" and "Fase in Salesforce" are not drawn anywhere in the shots. The rows are told apart by tier and content only.
- The 1920 shot carries a "Restored your unsaved work" toast and shows the id process_nooteboom_v2, while the 1024 and 1440 shots show process_nooteboom. So the 1920 image is not the fixture "as it opens"; it is a restored draft.
- Node readability: all visible step labels are legible in all three shots; the pre-existing notices (3 nodes outside lane, no authority) overlay the top of the canvas but do not cover the phase brackets.

## Judgement
Met for the visible stretch: phase names read as labels of their stretches, the two rows are distinct, and the dividers place steps without hiding them. Not met as shown: names are clipped at 1024 and 1440, the right-hand phases are not shown at any width, and the 1920 image is a restored draft rather than the opening state. Verdict: amber.
