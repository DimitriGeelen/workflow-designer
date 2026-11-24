# T-1499 Human AC#1 — independent image review (reviewer dispatch judge-t-1499-r3-19f9c84a6fe5)

Revision reviewed: 1b4cafa84868b634d7165fbd633707a497cec07b (matches HEAD at review time).
Images opened: notes-phases-{1024,1440,1920}.png (this change) and notes-phases-before-1440.png (0.49.0 baseline, for contrast). Crops made with PIL at 2x from the 1440 and 1920 "after" shots (crop-after1440-phase, crop-after1920-phase). Cited copies are in this directory with the reviewer suffix.
Not opened: notes-phases-before-1024.png and notes-phases-before-1920.png (not needed for the "after" judgement).

## What I checked

1. Notes vs phase rows (clear): in all three after-shots the note boxes ("Opportunity always from a customer request", "Product status set by Tacton") sit above the phase bracket band. No note box sits on a bracket or a phase name. The before-1440 baseline shows the defect being fixed: the note box overlaps the "Opportunity" phase label.
2. Lines traceable: the leader from "Opportunity always from a customer request" runs down to sal_1_opportunity, and the leader from "Product status set by Tacton" runs down to sal_3_product. Both are traceable to their step.
3. Phase names legible: "1 Qualification", "Opportunity", "Fase in Salesforce", "Fase", "2 Needs Analysis" are readable. In the zoomed crops the dotted leader crosses the "Opportunity" label (at 1440, 1920 and 1024). The letters stay readable: a halo is visible around them.
4. Third note NOT fully readable: Greenfield's sample was supposed to have three notes above the pool. In every after-shot only two notes are fully visible. The third ("Proposal ... sales lead...") is clipped at the right viewport edge at 1920 (only "Proposal / sales lea" is visible) and is off-screen at 1440 and 1024. Its text and its step link cannot be read in any supplied image, so "each note readable" and "each line going to its step" are not shown for that note.
5. Side note (not criterion-relevant): the sidebar shows different workflow ids/versions across the shots (process_nooteboom_v2, process_nooteboom, process_nooteboom_v3). The shots are not from one identical load.

## Judgement

The two visible notes meet the criterion: notes clear of the phase rows, lines traceable, names legible. The third note is not shown in full in any of the three after-shots, so the criterion is not met as written for "each note readable". Fix: recapture at 1024/1440/1920 with the pool scrolled (or the viewport widened) so all three notes and their leaders are in frame, then re-judge.

Verdict: amber.
