# T-565 Human AC#1 — reviewer evidence (rung-3, revision a36d7f4b)

Verdict: ESCALATE. The decision whether to KEEP or CHANGE unconditional `<aef:workflowMeta>` emission is a product-direction ruling. The AC itself reserves it for the operator: "an agent flipping it would convert a carve-out into a ruling nobody made" (T-501 §0). I recorded no decision and flipped nothing.

## What I checked
1. T-501 IW-0 block. The file is now at `.tasks/completed/T-501-map-id-round-trip-defect-triage-aef-cons.md`, NOT `.tasks/active/` as the AC steps say. Lines 155-201 still read `disposition: deferred`. The "EXIT CONDITION EXECUTED 2026-08-23 by T-565" annotation is at line 174, and it contains the three measurements.
2. I found no decision recording a "T-501 IW-0" ruling under `.context/project/`, so the ruling has not been made yet.
3. I ran `node tools/_t565-workflowmeta-emission-census.mjs` today. It exited 0 with PASS. Results:
   - rendered: 24 documents, 0 lack the element. This confirms that population cannot exercise the change.
   - 19 documents lack the element on input and carry it on output, and 0 still lack it. **The AC says 14.** The census now also counts 5 documents under `aef-bpmn` (plus third-party 10 and lane-provenance 4).
   - Emitted block size is about 112-131 bytes per document.
   - Gate coverage: 10 of 19 are inside a named gate's corpus, and **9 are watched by no named gate**. The AC says 4.
4. I ran `node tools/_t358-byteid-thirdparty.mjs` today. It exited 0 with "PASS — the population _t308 cannot reach matches its recorded bytes". **The AC says it exits 1 with PRECONDITION VIOLATED and no runner invokes it.** That is stale: T-579 (`.tasks/active/T-579-*.md`) is `status: work-completed` (2026-08-24).

## Meaning for the operator
- The core claim holds: always-emit is already shipped behaviour, so the ruling is KEEP vs make-conditional.
- The AC's "If not" branch ("T-579 gate is red and unrun") no longer applies. The third-party gate is green now, which removes the stated reason to stay deferred for those 10 documents.
- 9 movers (5 aef-bpmn + 4 lane-provenance) remain unwatched by any byte-identity gate. Weigh that before KEEP.
- Step 4's path is wrong: IW-0 lives in `.tasks/completed/T-501-...md`.
