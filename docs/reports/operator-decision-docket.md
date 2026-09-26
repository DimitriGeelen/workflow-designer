# Operator decision docket

**Generated** — do not hand-edit. Regenerate with:

```
python3 tools/_t872-decision-docket.py > docs/reports/operator-decision-docket.md
```

**77 open decisions** across 68 tasks.

This does **not** reduce the backlog — the count is unchanged. It removes the
gathering cost: answering these otherwise means opening ~69 task files and
reconstructing each context. Ordered by what each one releases.

Reconciliation against `fw reviewer surface`: docket 77, surface reports operator-only 77. Counts agree.

---

## 1. T-340 — Standard BPMN DI is silently discarded on import: the whole bpmndi sub-tree is dropped a
*designer-authoring-surface **[product arc]** · class: `tier0-or-bypass` — the tier the operator owns by definition · unblock score 29*

**Asks:** [REVIEW] Repair semantics for standard BPMN DI on import

**Expected:** one option recorded. No AEF acknowledgement is required for scoped (b) — that expectation belonged to the maximal variant and is withdrawn.

## 2. T-423 — T-357 step 2: emit BPMN DI additively alongside aef:position
*designer-authoring-surface **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 23*

**Asks:** [REVIEW] **May five third-party OMG schema files be vendored into this repo?**

**Expected:** a recorded ruling. Yes → T-423 finishes with no further asks. No → the Agent AC is unsatisfiable as written and the honest close is an explicit scope amendment, which is also yours to record.

## 3. T-358 — Importer FABRICATES lane and pool structure the input never had: every third-party docum
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 22*

**Asks:** [REVIEW] Choose the lane/pool fabrication repair: **A · B · C · AB · no repair**

**Expected:** one option recorded as a decision. The three remaining Agent ACs then become executable and the repair ships under this task.

## 4. T-341 — An unresolvable flowNodeRef silently reassigns the orphaned node to the human (sovereign
*no arc · class: `tier0-or-bypass` — the tier the operator owns by definition · unblock score 20*

**Asks:** [REVIEW] **Rule on the default-lane policy for an orphaned flow node.**

**Expected:** one option recorded in `## Decisions` with rationale, plus a yes/no on announcing.

## 5. T-590 — EWCR Arc-0 Designer contract inventory and one canonical rendered fixture
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 19*

**Asks:** [REVIEW] The inventory is a usable negotiating document for AEF, not a restatement

**Expected:** Yes — every default, inference and derivation has a stated value, a citation, and a named request if it is unratified.

## 6. T-590 — EWCR Arc-0 Designer contract inventory and one canonical rendered fixture
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 19*

**Asks:** [REVIEW] The handoff envelope is safe to send once H2 is answered

**Expected:** Nothing in the envelope asks the Designer to be an authority, and nothing claims a delivery that did not happen.

## 7. T-189 — IW-9: v1.1 mapping-standard delta — collapse triple-encoded authority (Lane=who, workflo
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 18*

**Asks:** [REVIEW] Operator sign-off to graduate the IW-9 delta into the FROZEN v1 standard (v1 → v1.1)

**Expected:** A recorded GO/refine/NO-GO decision on the delta; on GO, explicit authorization to edit the frozen standard (that edit is gated on this sign-off — see Context)

## 8. T-286 — Edge arrowheads render above node-id badges; selected element's badge comes to foregroun
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 14*

**Asks:** [REVIEW] Arrow-over-badge default + selected-badge-forward feels right; endpoint drag handles now grabbable near badges

**Expected:** arrowhead never hidden by a badge when nothing is selected; selected node's badge fully legible; endpoint handle grabbable through the badge area

## 9. T-308 — Bare catch-event neutral rendering when unbound (T-244 GO, path b)
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 14*

**Asks:** [REVIEW] The neutral glyph reads as "an event of unspecified kind", not as a broken or missing node

**Expected:** the bare one reads as neutral/unspecified — clearly not an error state, clearly not a handoff

## 10. T-308 — Bare catch-event neutral rendering when unbound (T-244 GO, path b)
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 14*

**Asks:** [REVIEW] Placing a handoff from the palette still feels discoverable

**Expected:** while placing, the handoff affordance and target fields are present; after reload the *glyph* goes neutral **but the node keeps whatever name you gave it** — so a node you never renamed still reads "← Handoff" under a neutral ring. That is deliberate: the name is your text, and rewriting it would change exported bytes (see **Decisions**). Judge whether that combination reads as "meant to be a handoff, never bound" or just looks broken.

## 11. T-279 — Guided-mode procedural guardrail (package P3, Locks 3+6): revive or retire
*designer-authoring-surface **[product arc]** · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 13*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 12. T-596 — Arc-0 exit gate is uncheckable: the operator decisions it depends on have no register an
*ewcr-governed-delivery **[product arc]** · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 13*

**Asks:** [REVIEW] Confirm the register reads H1 and H3 correctly as **open**, not as already answered

**Expected:** The gate exits non-zero and prints `BLOCKED` for the third Arc-0 clause, listing the open question ids. With H1/H3/H5/H6 open, four ids should be named. Arc 1 cannot start until they are answered — that is the gate doing its job, not a failure.

## 13. T-597 — Both remaining Arc-0 exit clauses are counterparty-owned and nothing said so, so Arc 0 c
*ewcr-governed-delivery **[product arc]** · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 13*

**Asks:** [REVIEW] AEF answered, and answered RED. Rule on what Arc 0 does now.

**Expected:** A ruling on one of — **(a)** *Escalate to AEF's operator.* R6 and R7 sit with their agent and their agent has said the matrix is not built. Their operator, not ours, can commit to building it. **(b)** *Hold.* Arc 0 stays open, Arc 1 does not start, and that is recorded as the honest state rather than worked around. This is the current de facto position. **(c)** *Re-scope the exit gate.* If clause 2's matrix is not going to be built, a gate requiring it can never go green, and a permanently unsatisfiable gate is furniture (T-382). Redefining an exit clause is a sovereignty act and is yours alone — it is the same act `definition_ratified:` exists to protect.

## 14. T-347 — Content inside an ACCEPTED element is silently dropped on import: documentation, foreign
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 12*

**Asks:** [REVIEW] Choose repair semantics for unconsumed element content

**Expected:** a choice recorded in `## Decisions` with its rationale.

## 15. T-280 — Workflow Fabric (SD-15): process-dependency graph — revive or retire
*designer-authoring-surface **[product arc]** · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 11*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 16. T-281 — Audience render lenses (SD-14/§2.2): business/logical/technical/pseudocode views
*designer-authoring-surface **[product arc]** · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 11*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 17. T-565 — IW-0 exit condition: measure the byte impact of always emitting aef:workflowMeta across 
*designer-authoring-surface **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 11*

**Asks:** [REVIEW] **Rule on T-501 IW-0 — "should export always emit `<aef:workflowMeta>`?"**

**Expected:** a decision id (`PD-NNN`) is printed, and IW-0 reads `disposition: answered`.

## 18. T-593 — EWCR handoff envelope records an operator resolution of H2 that no operator made
*ewcr-governed-delivery **[product arc]** · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 11*

**Asks:** [REVIEW] Rule for who may author a decision-attribution field in a seam artifact

**Expected:** you pick (a), (b) or (c). If (a), I file the gate task; I do not build it under this task.

## 19. T-344 — fabric watch-patterns.yaml is the untailored fw context init default and expands to zero
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 10*

**Asks:** [REVIEW] Approve the watch scope and the registration debt it makes visible

**Expected:** the expansion is non-empty and the reported unregistered count is a number you are willing to carry as a standing WARN until the cards are written.

## 20. T-402 — budget-gate allow-regex matches anywhere in the command string: a compound command is al
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 10*

**Asks:** [REVIEW] **Decide local containment while upstream fixes it.**

**Expected:** one of A / B / C recorded as a decision on this task.

## 21. T-282 — callActivity node type (SD-9): sync sub-workflow call with ioMapping
*designer-authoring-surface **[product arc]** · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 9*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 22. T-589 — designer properties panel: add a clickable component-fabric link and a URL field for cod
*designer-authoring-surface **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 9*

**Asks:** [REVIEW] Each URL appearing twice — once in the editable box, once as the rendered

**Expected:** the textarea keeps the raw text you typed; the clickable anchors render underneath it. Both are present at once, by design.

## 23. T-589 — designer properties panel: add a clickable component-fabric link and a URL field for cod
*designer-authoring-surface **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 9*

**Asks:** [REVIEW] `Fabric component` is the right field name and the right target

**Expected:** Watchtower opens the component card for `bpmn-cli` in a new tab.

## 24. T-608 — Draft the AEF attestation request for Arc-0 clauses 1 and 2 - written and unsent, so the
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 9*

**Asks:** [REVIEW] Approve, edit, or reject the draft — and with it, rule on T-597 option (a)

**Expected:** One of — (a) "send it" (with edits, if any), and the agent creates the send-authorisation task with real ACs and brings the envelope and transport back before anything leaves this machine; (b) "hold", and Arc 0 stays open and Arc 1 cannot start — a legitimate answer, and the draft keeps until you want it; (c) a correction to the ask itself.

## 25. T-733 — Contact AEF on R6/R7 after the rail came back empty: re-establish the ask and record tha
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 9*

**Asks:** [REVIEW] Rule on the rail substrate: is a hub whose runtime sits in `/tmp` an acceptable source for citations the Arc-0 register treats as evidence? Options recorded in the register, none actioned.

**Expected:** a ruling on recovery vs re-pinning clauses to quoted content only

## 26. T-345 — audit fabric coverage check is a broken duplicate of its own sibling and cannot report n
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 8*

**Asks:** [REVIEW] Decide retain-and-fix vs remove-as-duplicate for the first fabric block

**Expected:** a recorded choice — repair or delete — in this task's `## Decisions`.

## 27. T-422 — check-arc-id: register the hook or delete the promise
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 8*

**Asks:** [REVIEW] The premise changed after this task was written. Register, delete, or wait?

**Expected:** a decision recorded against T-422; the agent then executes it and closes the task.

## 28. T-579 — The third-party byte-identity gate is RED and no runner has ever seen it
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 8*

**Asks:** [REVIEW] **Choose the new `BASELINE_REF` for the third-party byte-identity gate.**

**Expected:** you pick a ref *after* the `exporter` stamp, re-run step 2, and read a verdict that reflects only changes you have ratified. **If it is still red after that:** the residue is something later than the stamp, most likely DI, and that is a real question about T-423 over a population it never covered — not a pin choice. Say so and leave the pin alone. A gate honestly red is worth more than a green one bought by moving the line it measures from. <!-- Original Human template guidance below. --> <!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking. Remove this section if all criteria are agent-verifiable. Each criterion MUST include Steps/Expected/If-not so the human can act without guessing. ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ── If your Expected clause is grep-able / file-exists / structural (a deterministic shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if verification genuinely needs human taste (tone, feel, layout rhythm). See CLAUDE.md §AC Classification Guidance for the conversion rule. [REVIEW] example (genuine human judgment): - [ ] [REVIEW] Dashboard renders correctly

## 29. T-592 — Verification legs that pipe a self-reporting command into grep discard its exit status
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 8*

**Asks:** [REVIEW] Decide whether the vacuous-verification detector becomes a blocking gate

**Expected:** one of (a)/(b)/(c) recorded, plus a yes/no on the CLAUDE.md paragraph edit.

## 30. T-732 — Drain the H-register: four open operator rulings are the only Arc-0 exit path on our sid
*ewcr-governed-delivery **[product arc]** · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 7*

**Asks:** [REVIEW] Rule H1 — do roadmap Arcs 4–6 supersede the standing DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO?

**Expected:** `operator-decisions.yaml` H1 carries `status: resolved` and a `source_of_truth`

## 31. T-732 — Drain the H-register: four open operator rulings are the only Arc-0 exit path on our sid
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 7*

**Asks:** [REVIEW] Tick T-596's Human AC to set `definition_ratified: true` on clause 3 — without it the clause refuses to be satisfiable at all, and all four rulings above buy nothing

**Expected:** *(none stated — the criterion does not say what answering it looks like)*

## 32. T-209 — 832-side compile->promote->create producer-contract test (AEF rail offset 78 proposal)
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 6*

**Asks:** [REVIEW] Decline AEF's offset-78 producer-contract proposal as already satisfied?

**Expected:** a decision recorded against T-209. The agent then posts the rail reply and files the typed-event task; T-209 closes.

## 33. T-310 — Nodes render outside every lane band (pen_inbound_classifier): long trunk edges are the 
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 6*

**Asks:** [REVIEW] The reconciliation reads as a repair, not as the editor moving your work around

**Expected:** "framework validates the request" sits in **Framework · Authority** and "agent carries out the work" sits in **Agent · Initiative** — on the old build they were in each other's lanes. The notice says 2 nodes were moved back.

## 34. T-310 — Nodes render outside every lane band (pen_inbound_classifier): long trunk edges are the 
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 6*

**Asks:** [REVIEW] Judgement call worth your eyes: is "declared membership wins" the right default?

**Expected:** you agree the semantic (`Lane = who`, T-189) should outrank the geometry, so a map that says "framework owns this" draws it in the framework lane even if that moves it.

## 35. T-310 — Nodes render outside every lane band (pen_inbound_classifier): long trunk edges are the 
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 6*

**Asks:** [REVIEW] Cosmetic: the stacked Clean nudge overlaps top-lane content

**Expected:** you're satisfied this is acceptable. **Known and not hidden:** when BOTH advisories show, the lower one sits at y=52px and can cover a node in the top lane (it covers `agt_2_agent` in that shot). The single nudge already overlapped canvas content at 12px, so this is the same behaviour one row down, and both banners are dismissible — but it is a real overlap and it is your call whether it needs solving.

## 36. T-449 — PROVENANCE pair-draft rows are two-sided at last: AEF's records land, dispatch-loop's ar
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 6*

**Asks:** [REVIEW] Rule which definition of "pair-draft" this table ratifies. Both are coherent

**Expected:** one of a/b/c recorded. If (b) or (c), say so and the agent applies it in a follow-up task — the rows are deliberately unchanged today.

## 37. T-588 — upstream ships an unanchored verification extractor that can silently drop a leg — rule 
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 6*

**Asks:** [REVIEW] **Rule on the CORRECTED recommendation: selective merge, keep refusing, or

**Expected:** one letter. A creates a scoped merge task; B closes the question with a revisit trigger; C is executed and reported precisely.

## 38. T-703 — RA-007: 101 observations pending for more than 7 days
*arc-003 · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 6*

**Asks:** [REVIEW] Rule on the drain path for the 82 carried-by-completed-task items (the bulk of the residue)

**Expected:** a letter recorded on this task; under A, a one-bug task is filed for the verb (recommended — the fix is ~10 lines and OBS-290 has waited 34 days for it)

## 39. T-671 — Component Fabric does not meet the Arc-0 fence for the EWCR scope
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 5*

**Asks:** [REVIEW] The Arc-0 component set is the right scope

**Expected:** the set covers the mapping/inventory, stable-ID and import/export-round-trip surfaces this side owns, and excludes runtime schemas (AEF-owned)

## 40. T-736 — AEF attested Arc-0 clause 1 green with its numbers at @1539 — record the response as T-6
*ewcr-governed-delivery **[product arc]** · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 5*

**Asks:** [REVIEW] Rule on clause 1 — this is the ratification AEF's post explicitly declines

**Expected:** One letter, and the two field edits if A or B. Both fields are yours — the agent left them byte-identical to HEAD and verified that.

## 41. T-827 — Post task-gate and context-memory bpmn bytes to xfer-832-bpmn (AEF @1644 Part A)
*ewcr-governed-delivery **[product arc]** · class: `taste` — genuine judgement — tone, feel, wording · unblock score 5*

**Asks:** [REVIEW] Rule whether the agent may base64-encode these two repo files for outbound transmission on the hub, or whether you post them yourself. Steps: 1. Read AEF's request and exact command at agent-chat-arc @1644 Part A. 2. Decide: (a) authorise the agent to post the bytes to xfer-832-bpmn this once, or (b) run the command yourself, or (c) decline and tell AEF the exchange is off. Expected: a recorded ruling; if (a) or (b), the two files land on xfer-832-bpmn with name and sha256 metadata and AEF posts back exit code plus full compile output. If not: the compile stays blocked indefinitely - both projects' boundary gates are working correctly and neither side can resolve it alone.

**Expected:** All panels visible, no console errors

## 42. T-325 — Classify every validator rule universal vs dialect-relative (T-309 IW-1b)
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 4*

**Asks:** [REVIEW] Rule on the two carriers §1 does not classify, and on whether `W-GW-AMBIGUOUS` should accept the standard's other condition carrier

**Expected:** A recorded ruling on each. On GO for (b) I relax the predicate and re-run both suites; the dialect-relative count then drops from 3 to 1.

## 43. T-351 — serve-gallery.sh can never stop its own server: trap forwards SIGINT, which bash sets to
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 4*

**Asks:** [REVIEW] Decide whether the six pre-existing orphans should be killed

**Expected:** SIX processes, not five — the count in the first draft of this task was asserted from memory and the AC4 census corrected it. Four from 2026-07-22, one from 2026-07-29 (docroot in a session scratchpad), and **one from 2026-08-02 19:10**, which predates this task's work and shows the leak was still producing orphans independently of the T-350 harness. Every listed docroot is gone from disk.

## 44. T-353 — Prepare the corpus for the P-011 errexit gate change (4 latent patterns + 19 DIVERGENT l
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 4*

**Asks:** [REVIEW] Ruling: may an agent edit `## Verification` blocks inside `.tasks/completed/`?

**Expected:** a yes or no recorded here. - **Yes** → the patch set is applied to the 23 archived lines, and the P-011 gate change becomes unblocked (still a separate operator decision, G-008 upstream). - **No** → the archived lines stay as they are, this task closes as a proven proposal, and the gate change stays parked. Nothing breaks either way.

## 45. T-426 — OBS-017 misfire audit: what T-420 and T-421 instruments print when they fire wrongly
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 4*

**Asks:** [REVIEW] **Decide whether the T-421 claim-drift detector gets registered, and on

**Expected:** `fw doctor` clean, and the detector's output appears at end of turn showing `PASS (with 1 upstream item(s))`.

## 46. T-432 — Full fw audit reports 60 FAIL across non-structure sections - never assessed
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 4*

**Asks:** [REVIEW] Whether the push gate should keep running `--sections structure` only

**Expected:** one of a/b/c recorded here, with a one-line reason

## 47. T-433 — The vendor bump is available and its version relation is formally undecidable — an opera
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 4*

**Asks:** [REVIEW] Whether to take the vendor bump now

**Expected:** one of a/b/c recorded here with a one-line reason

## 48. T-586 — kill worktree isolation and pin no-background-install as policy
*no arc · class: `tier0-or-bypass` — the tier the operator owns by definition · unblock score 4*

**Asks:** [RUBBER-STAMP] Apply the worktree deny rules to `.claude/settings.json`

**Expected:** step 2 prints `[denied]` on all three routes and `All worktree routes are denied.`, exiting 0. The bridge-suite leg for T-586 goes green at the same time.

## 49. T-600 — Side-placed event labels do not wrap: long label text overruns the lane boundary
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 4*

**Asks:** [REVIEW] Long event/gateway sentences wrap instead of sprawling, and the map still reads well

**Expected:** With the option on the sentence occupies two or three stacked lines under/beside the circle and no longer runs across the lane divider; with it off the old single-line behaviour returns

## 50. T-601 — Side-placed labels have no pool or lane boundary awareness
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 4*

**Asks:** [REVIEW] Labels stay inside the lane they belong to, and the map is no less readable for it

**Expected:** No label overlaps the lane header strip or extends into a neighbouring lane; labels with nowhere clean to go sit below their shape as before, rather than in a worse position

## 51. T-606 — Renderer output is escaped at the template: /approvals and /tasks show markdown as liter
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 4*

**Asks:** [REVIEW] The approvals surface now reads the way it was written — and you rule on the

**Expected:** block. Commands should appear as inline code, emphasis as bold, task refs as links — not as `&lt;code&gt;` text. 3. Now look at the AC *headline* line (the bold sentence beside the Review badge) on the T-449 and T-575 cards. Some still show literal `**asterisks**` and `backticks`. That is OBS-319: a DIFFERENT defect — that field is raw task-file text that never reaches a renderer, so fixing it means rendering it, and explicitly NOT marking it safe. I kept it out of this task to keep one root cause per task. 4. Decide: fix OBS-319 next, or leave headlines as plain text deliberately. **Expected:** Steps/Expected blocks render as markup; you record a call on OBS-319.

## 52. T-184 — Child-3: Reverse discovery (AEF record -> editable process map)
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 2*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 53. T-185 — Child-4: Collaboration and concurrency (per-element claim/lease)
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 2*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 54. T-186 — Child-5: Hosting and tenancy (tenant-neutral, multi-tenant)
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 2*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 55. T-233 — S5b gallery ghost cards render ghosts as visually-distinct GHOST entries
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 2*

**Asks:** [REVIEW] A ghost entry reads as "not a map yet" at a glance, without reading the badge

**Expected:** The pending-ref entries are obviously a different kind of thing from the map tiles before you read a single word. Clicking one seeds a new map that adopts the ghost's uuid and toasts "Save to project to claim it."

## 56. T-277 — Ratify process-level conformance key and stateKind carrier convention (AEF T-2652)
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 2*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 57. T-368 — Release-state blindness: 8 src commits ahead of the 0.8.0 pin, AEF re-reporting a defect
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 2*

**Asks:** [REVIEW] **Decide whether to cut 0.9.0, and whether AEF should be told to re-pin.**

**Expected:** a decision recorded; if cut, `dist/MANIFEST.yaml` `latest:` reads `0.9.0` and the new artifact's sha256 matches the file.

## 58. T-368 — Release-state blindness: 8 src commits ahead of the 0.8.0 pin, AEF re-reporting a defect
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 2*

**Asks:** [REVIEW] **Is a notation/routing revision actually planned?**

**Expected:** yes-with-scope, or no.

## 59. T-392 — Safe-list early-return shadows the focus-drift gate: T-390 exempted drift pattern 2
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 2*

**Asks:** [REVIEW] Approve changing the central governance hook

**Expected:** A named choice, or a direction to leave the shadow open and document it instead

## 60. T-410 — Watchtower session signing key is committed to the tracked tree and invisible to the sec
*no arc · class: `tier0-or-bypass` — the tier the operator owns by definition · unblock score 2*

**Asks:** [REVIEW] Rule on the history rewrite — the old key stays readable in git history and on the GitHub mirror until you decide

**Expected:** a recorded decision either way — "rewrite" or "rotation is sufficient".

## 61. T-410 — Watchtower session signing key is committed to the tracked tree and invisible to the sec
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 2*

**Asks:** [REVIEW] Rule on whether Watchtower should be LAN-reachable at all

**Expected:** a recorded position on whether a start-up script should be deciding the network exposure of the sovereignty surface.

## 62. T-498 — scope the onboarding-experience arc iteration: which arcs, whose project, what iteration
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 2*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 63. T-537 — termlink_agent_chat_arc_recent returns ok:true over a source that does not contain the a
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 2*

**Asks:** [REVIEW] Rule on how both projects treat `termlink_agent_chat_arc_recent`

**Expected:** A decision exists in `.context/project/decisions.yaml` naming (a) or (b).

## 64. T-540 — bootstrap BVP scoring and produce the first ranking of actionable work
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 2*

**Asks:** [REVIEW] Approve or reject the three driver proposals, and rule on the displaced drivers

**Expected:** `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw bvp driver --list` shows the drivers you accepted, and the register still totals 9.

## 65. T-643 — review-queue renders CLOSE and KEEP-OPEN as unparseable though the library returns them
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 2*

**Asks:** [REVIEW] The two new verdict colours read correctly in your terminal.

**Expected:** CLOSE and KEEP-OPEN are legible against your background and read as *resolutions*, clearly distinct from the grey `?` that means "no verdict I can parse".

## 66. T-647 — T-640's fetcher write-guard over-blocks the stdout idioms: curl -o - and wget -O - are r
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 2*

**Asks:** [REVIEW] The manifest is the right governance object

**Expected:** A short list of command spellings that T-640 deliberately took away, every one of them a genuine file-writer. It is the list of things you can no longer do without an active task.

## 67. T-696 — T-624 chose a template warning as its prevention and twelve days later the number has no
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 2*

**Asks:** [REVIEW] **Rule on the prevention, not the field: A · B · C · D · no repair**

**Expected:** one letter, recorded in this task's `## Decision`.

## 68. T-702 — RA-006: 34 urgent observations still pending in the inbox
*arc-003 · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 2*

**Asks:** [REVIEW] Confirm that "named with reason" closes RA-006, or direct a drain

**Expected:** a letter on this task; under B, three sub-rulings

## 69. T-740 — Value review: the AEF seam and the workflow -> program -> execution chain, and what the 
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 2*

**Asks:** [REVIEW] The review's findings are approved, rejected or modified item by item, and the decisions are recorded.

**Expected:** every non-KEEP row has a recorded disposition, and no Phase 6 execution has happened before that.

## 70. T-742 — Value review: the Workflow Designer product itself — src/, the editor, chain stage 1
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 2*

**Asks:** **[REVIEW] Phase 5 — rule the 22 findings item by item.**

**Expected:** every finding carries a disposition; no finding is executed without one.

## 71. T-742 — Value review: the Workflow Designer product itself — src/, the editor, chain stage 1
*no arc · class: `sovereignty-field` — writes a field whose whole point is that a human set it · unblock score 2*

**Asks:** **[REVIEW] The 12 Sovereign questions in §12.**

**Expected:** Q1–Q12 answered, or explicitly parked with a reason. Q1 (the 0.8.0 pin against 0.12.0 src) and Q6 (whether `rendered/` is regenerated or the editor-saved bytes are ratified) gate other work; the rest do not.

## 72. T-676 — P-002 blocks /resume itself: a session that ends by FILING a task cannot gather state in
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 0*

**Asks:** [REVIEW] **Should P-002 exempt read-only Bash when focus is absent, captured, or

**Expected:** a recorded ruling. Nothing edits `check-active-task.sh` before it.

## 73. T-695 — Task-template boilerplate is scored as if it were the task: an empty file rates 4 of 5 o
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 0*

**Asks:** [REVIEW] **Choose how to stop the template scoring itself: A · B · C · no repair**

**Expected:** one letter, recorded in this task's `## Decision`.

## 74. T-743 — Consumer intake: take our own Watchtower to designer 0.12.0
*no arc · class: `unclassified` — asks for a ruling; no deterministic signal to delegate on · unblock score 0*

**Asks:** **[REVIEW] The 0.12.0 editor is the one you want to be using.**

**Expected:** the editor works, and four releases of accumulated change (0.9 → 0.12) read as an improvement on 0.8.0 rather than a regression for your workflow.

## 75. T-811 — Thirty authored corpus values still unreachable in the panel (T-810 census residue)
*no arc · class: `inception-decision` — a go/no-go on an exploration — nothing else can settle it · unblock score 0*

**Asks:** [REVIEW] Review exploration findings and approve go/no-go decision

**Expected:** Decision recorded, task completed

## 76. T-858 — 403 handler writes a whole HTML document to htmx callers, so the toast scrapes JavaScrip
*no arc · class: `taste` — genuine judgement — tone, feel, wording · unblock score 0*

**Asks:** [REVIEW] The toast a real 403 produces reads as a sentence, and the full-page recovery UI is untouched

**Expected:** step 4's toast reads `Session expired — reload the page and try again.` — one sentence, no `function(){`, no `var t=`, no page title, not truncated mid-word. Step 5 still shows the full-page recovery UI, unchanged from before this task.

## 77. T-866 — S1: the Hypothesis section and its form — a fill-in shape that makes a vague hypothesis 
*hypothesis-first-inceptions · class: `tier0-or-bypass` — the tier the operator owns by definition · unblock score 0*

**Asks:** [REVIEW] **Exercise the gate live on a real inception.**

**Expected:** refused at 1 and 2 with a message naming what is missing; accepted at 3.

