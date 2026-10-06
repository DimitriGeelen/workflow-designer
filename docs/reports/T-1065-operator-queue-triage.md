# T-1065 — Operator review queue triage (rulings, decisions, inception go/no-go)

Read-only triage done 2026-10-06. No task file was edited and nothing was ticked. Visual and "reads well" checks are out of scope; that excludes two of T-310's three open criteria.

**Summary: 68 open ruling criteria across 63 tasks. LIVE 42 · SETTLED 15 · MOOT 11.**

Classes:
- **SETTLED**: a recorded decision or later work already answers the question.
- **MOOT**: the premise is gone.
- **LIVE**: the operator still has to decide.

"Rec" is the task's own `## Recommendation`.

## Table

| Task | Criterion (short) | Class | Evidence | For LIVE: options · Rec |
|---|---|---|---|---|
| T-184 | Child-3 inception go/no-go | SETTLED | Operator DEFER on 2026-07-11: `.tasks/completed/T-175-*.md:236` ("DEFER child-3, child-4, child-5"). The task description repeats it. | Close by recording the DEFER (`fw inception decide T-184 defer`). Revisit trigger is in the description. |
| T-185 | Child-4 inception go/no-go | SETTLED | Same as T-184 (T-175:236). | Same: record the DEFER. |
| T-186 | Child-5 inception go/no-go | SETTLED | Same as T-184 (T-175:236). | Same: record the DEFER. |
| T-189 | Graduate IW-9 into frozen v1 → v1.1 | SETTLED | PD-087 (2026-07-12, task T-189): "IW-9 authority-collapse graduated to v1.1 ... under Dimitri sovereign GO". | — |
| T-209 | Decline AEF's offset-78 producer-contract proposal? | LIVE | No ruling found. | A: decline as already satisfied · B: build the test. Rec: GO A. |
| T-277 | Ratify conformance key / stateKind (inception) | LIVE | Parked until AEF pings T-2652 with an in-map GO. No operator decision on file. | GO / DEFER / NO-GO. Rec: DEFER. |
| T-279 | Guided-mode guardrail (inception) | SETTLED | H1 in `docs/research/executable-workflow/operator-decisions.yaml` is resolved: operator, 2026-09-21, "The DEFERs (T-279/280/281/282) ... STAND". Commit 22014fea. | Record the DEFER. |
| T-280 | Workflow Fabric SD-15 (inception) | SETTLED | Same H1 ruling (22014fea). | Record the DEFER. |
| T-281 | Audience render lenses (inception) | SETTLED | Same H1 ruling (22014fea). | Record the DEFER. |
| T-282 | callActivity SD-9 (inception) | SETTLED | Same H1 ruling (22014fea). | Record the DEFER. |
| T-310 | Is "declared membership wins" the right default? | LIVE | The premise ("Lane = who", T-189) was retired by the T-888 ruling (405dc2eb, 2026-09-27: a lane is a partition, the element carries authority). The layout question itself is still open. | Move the node to its declared lane, or keep the pixels and flag the conflict. Rec: GO (taste call). Note: T-310 has two other open visual ACs. |
| T-325 | Rule on two §1 carriers + W-GW-AMBIGUOUS branch label | LIVE | No ruling found. | (a) classify laneMeta height/abbr in v1.1 · (b) relax the gateway rule. Rec: GO (b), DEFER (a). |
| T-340 | Repair semantics for BPMN DI on import | SETTLED | PD-200 (2026-08-14, task T-340): "T-340 DI repair semantics: b". This is exactly the command in the AC's step 4. Committed in f4adabc4; check that you were the one who recorded it. | — |
| T-341 | Default-lane policy for an orphaned flow node | LIVE | T-891 (3cb17878) removed the positional guess (laneId=null). Placement is still open; re-checked by T-1033. | Where an orphan lands. Rec: ABSTAIN (no recommendation by design). |
| T-344 | Approve fabric watch scope + registration debt | LIVE | `.fabric/watch-patterns.yaml` has not been tailored since fdf7c98a. | Approve as-is, or tailor first. Rec: NO-GO; tailor first. |
| T-345 | Retain-and-fix vs remove the duplicate fabric block | MOOT | The broken first block (`glob.glob(p['glob'])` / "coverage growing") is no longer in the vendored `audit.sh`. Its last change was the AEF 1.7.68 upgrade (7b5e227e), and AEF is now at 1.8.3. Only one coverage block is left (`audit.sh:2620`). | — |
| T-347 | Repair semantics for unconsumed element content | LIVE | T-602 fixed bpmn:documentation on flow nodes only. The general ruling is not recorded. | (a) preserve and re-emit · others in T-397 brief. Rec: GO (a). |
| T-351 | Kill the six orphan servers? | MOOT | The host rebooted on 2026-10-05 at 13:38 (`uptime -s`). No `http.server` process predates that, so all six July/August orphans are gone. | — |
| T-353 | May an agent edit Verification blocks in `.tasks/completed/`? | SETTLED | PD-308 (2026-09-22, T-802), operator ruling: "NARROW YES" (append control legs only). It names T-353's patch set as not covered and still deferred. | — |
| T-358 | Lane/pool fabrication repair A·B·C·AB·none | LIVE | Narrowed by T-888 (405dc2eb) to the pool half. Re-checked by T-1033 (e4db8955). | A · B · C · AB · no repair. Rec: GO AB (fallback A). |
| T-368 | Cut 0.9.0, tell AEF to re-pin? | MOOT | Tag `designer-v0.9.0` was cut on 2026-08-08 (8cd0c5d3, T-393). Releases now run to 0.15.3. | — |
| T-368 | Is a notation/routing revision planned? | LIVE | No answer recorded. The agent told AEF at RAIL-444 to draft in the current notation. Probably stale, but unconfirmed. | Yes (name it) / No. No rec. |
| T-392 | Approve changing the central governance hook | LIVE | The change shipped anyway (5b38a63a, T-575 "land T-392": the deferred safe-list exit). This would be a retroactive approval. | Approve shape C (as shipped) / revert. Rec: GO C. |
| T-402 | Local containment while upstream fixes the budget-gate regex | MOOT | The upstream fix (AEF T-2919/T-2923) has been vendored since 1.7.68. All 5 bypasses are blocked (e3366734, T-1045). | — |
| T-410 | Rule on history rewrite of the old session key | LIVE | No ruling found. The key is rotated. | Tier-0 rewrite + force-push vs leave it. Rec: probably leave it. |
| T-410 | Should Watchtower be LAN-reachable? | LIVE | No ruling found. | LAN-admit vs localhost-only. Rec: open posture question. |
| T-422 | check-arc-id: register, delete, or wait? | MOOT | `check-arc-id` is now registered by the framework itself (`.claude/settings.json:83`, committed in 6e0747c3/2dee46ba through `fw upgrade`). The "wait for upstream" premise has resolved itself. | — |
| T-423 | May five OMG schema files be vendored? | LIVE | The files are already in `tools/schemas/bpmn20/` (811bbed7, 2026-09-08). No authorisation is recorded, and the OMG licence was never read. | Ratify the vendoring / remove them and amend AC2. Rec: none on the ruling. |
| T-426 | Register the T-421 claim-drift detector, on which event? | LIVE | Not registered anywhere (not in `settings.json` or any hook). | A: Stop hook · other event · don't register. Rec: GO A. |
| T-432 | Push gate: keep `--sections structure` only? | LIVE | No ruling. The backfill prerequisite has been met (T-434). | (a) narrow · (b) widen to the real sections · (c) widen fully. Rec: GO (c). |
| T-433 | Take the vendor bump now? | MOOT | Bumps were taken: 1.7.68 (7b5e227e, T-840), 1.7.740 (T-988), 1.8.2 (T-1049), 1.8.3 (0e542b61, T-1057). | — |
| T-449 | Which "pair-draft" definition does the table ratify? | LIVE | No ruling found. AEF declined to assert their definition over ours. | AEF's definition vs ours. Rec: none on the ruling (GO on the file change). |
| T-498 | Onboarding arc scoping (inception) | MOOT | IW-1/IW-2 answered and IW-3 dissolved: the operator withdrew the premise ("oh i was confused"; T-498 lines 119-123). | Record DEFER or NO-GO and close. |
| T-537 | How both projects treat `termlink_agent_chat_arc_recent` | LIVE | No decision in `decisions.yaml`. | (a) upstream it · (b) standardise around `channel_*`. Rec: GO (either is defensible). |
| T-540 | Approve the three driver proposals + displaced drivers | SETTLED | 2db88a64 (T-542, 2026-08-16): "operator approved all three product drivers". V_WORKFLOW_ROUTING/V_AEF_INTEGRATION/V_SDLC_ENABLEMENT are in and the displaced drivers were dropped. | — |
| T-565 | IW-0: keep always-emitting `<aef:workflowMeta>`? | LIVE | IW-0 is still open in `.tasks/completed/T-501-*.md:529`. | Keep (already shipping) / stop. Rec: none on IW-0 itself. |
| T-579 | Choose a new BASELINE_REF | MOOT | T-581 replaced the pinned ref with recorded goldens (`tests/goldens/third-party/`). The task's own rec says "close it". | — |
| T-588 | Selective merge / keep refusing / update as-is | MOOT | The project left "keep refusing `fw update`" behind (PD-267) and has taken full upgrades through the re-vendor protocol up to 1.8.3 (7b5e227e … 0e542b61). | — |
| T-590 | Inventory is a usable negotiating doc | LIVE | A quality judgement, not a ruling. No evidence it was reviewed. | Accept / name gaps. Rec: GO. |
| T-590 | Envelope safe to send once H2 is answered | SETTLED | H2 resolved by the operator on 2026-08-26 (`operator-decisions.yaml`). The envelope's `to_project` is resolved (0fbcddbb). T-829 (6b39a55b) verified it. | — |
| T-592 | Vacuous-verification detector becomes a blocking gate? | LIVE | Still not wired as a gate. | Blocking gate / advisory only. Rec: GO detector, DEFER gate to you. |
| T-593 | Who may author decision-attribution fields in seam artifacts | LIVE | Partial prevention exists: the PL-148 self-certification rule in `operator-decisions.yaml`. The rule itself is not ruled. | (a) extend the `*_proposed` split with a gate · (b) discipline only · (c) other. Rec: (a). |
| T-596 | Confirm the register read H1/H3 as open | LIVE | The literal question is overtaken: H1 was resolved 2026-09-21 (22014fea) and H3 on 2026-09-22 (403502ea). But ticking it is the trigger that ratifies clause 3 (`definition_ratified`), so it is a real decision. | Tick together with the clause-3 ratification (see T-732 #2). Rec (T-732): after H5/H6. |
| T-597 | Ratify the Arc-0 clause definitions | LIVE | `arc-0-exit-clauses.yaml`: `definition_ratified: false`. | Ratify / correct. No separate rec. |
| T-597 | AEF answered RED — what does Arc 0 do now | LIVE | No ruling found. | (a) escalate to AEF's operator · (b) hold · (c) re-scope the exit gate. Rec: GO (scoped request; partly overtaken by T-610). |
| T-606 | Fix OBS-319 (markdown in AC headlines) or leave plain | LIVE | OBS-319 is resolved-to-carrier T-606 only (inbox). No ruling. | Fix next / leave plain text. Rec: GO. |
| T-608 | Approve/edit/reject the AEF attestation request draft | SETTLED | Operator correction under T-610: contacting AEF was never gated. The request was sent at offset 602, thread EWCR-ARC0-ATTEST-832 (b9e432bb, 2026-08-27). | — |
| T-647 | The T-640 manifest is the right governance object | LIVE | A review of the manifest. No sign-off found. | Accept / name the over-blocks. Rec: GO. |
| T-671 | Arc-0 component set is the right scope | LIVE | A scope review. No sign-off found. | Accept / name wrong in-or-out files. Rec: GO. |
| T-676 | P-002 exempt read-only Bash when focus is absent? | LIVE | No exemption applied. Instances still accrue (2016d51a). | GO / NO-GO / DEFER. Rec: GO Variant B. |
| T-695 | Stop the template scoring itself A·B·C·none | LIVE | No ruling. Rec written by T-1033. | A · B · C · none. Rec: GO A, done upstream. |
| T-696 | Pre-filled voi_score prevention A·B·C·D·none | LIVE | No ruling. | A · B · C · D · none. Rec: GO D, with A as precondition, upstream. |
| T-702 | "Named with reason" closes RA-006, or drain | LIVE | No ruling found. | A: accept enumeration · B: rule the 3 orphans. Rec: GO A. |
| T-703 | Drain path for the 82 carried-by-completed-task items | LIVE | The premise has shifted: T-914 (d1dfb3ea) shipped `fw note resolve`, the disposition option A was waiting for. T-914 left the drain decision to you on purpose. | Authorise the agent to resolve them / review each. Rec: GO A (now really "authorise resolve"). |
| T-732 | Rule H1 (do Arcs 4–6 supersede the DEFERs?) | SETTLED | H1 resolved by the operator on 2026-09-21: "DEFERs ... STAND" (22014fea). The task's own rec says tick it. | — |
| T-732 | Tick T-596 to ratify clause 3 | LIVE | `definition_ratified` is still false. H5 and H6 are still open. | Ratify now / after H5+H6. Rec: rule H5, then H6, then tick. |
| T-733 | Is a /tmp-runtime hub an acceptable evidence source? | LIVE | Premise corrected 2026-09-19: the chain is intact. The substrate question remains. | Recovery vs re-pin clauses to quoted content. Rec: DEFER. |
| T-735 | Rule on "immutable historical records" wording | LIVE | The phrase is not in the repo's CLAUDE.md today (grep finds nothing; `git log -S` shows it never was). It may live in a session note outside the repo, so this is unclear. | A: correct the wording · others. Rec: NO-GO on code, close on A. |
| T-736 | Ratify Arc-0 clause 1 | LIVE | `arc-0-exit-clauses.yaml` clause-1 `definition_ratified: false`. AEF says clause 1 is not satisfied. | Ratify (A) / other. Rec: GO A, rule alongside T-732. |
| T-740 | Rule the AEF-seam value review item by item | LIVE | `VALUE-REVIEW-aef-seam-2026-09-20.md` has no dispositions. | Approve/reject/modify each finding plus the §12 questions. Rec: GO on acting on the findings. |
| T-742 | Rule the 22 product findings | LIVE | No dispositions in the report. Only F-10 was acted on (87a73faa, T-808). | Approve/reject/defer each. Rec: GO (accept as evidence). |
| T-742 | The 12 Sovereign questions in §12 | LIVE | No rulings found. | Per question. Rec: GO. |
| T-743 | The 0.12.0 editor is the one you want | MOOT | 0.12.0 has been superseded by 0.13.0 through 0.15.3 (tags). Re-check on the current release if at all. | — |
| T-811 | 30 unreachable corpus values (inception) | LIVE | No decision recorded. The bounded item was delivered under T-836. | GO / DEFER / NO-GO. Rec: DEFER on the panel work. |
| T-827 | May the agent base64-post two repo files? | MOOT | Already posted: `xfer-832-bpmn` offsets 0–5, 2026-10-01, sha256s match (T-1033, e4db8955). The rec says close it. | — |
| T-866 | Exercise the hypothesis gate live | SETTLED | Refused you live twice (39e5158d, T-874). The gate was re-applied in f532479b (T-1026, 2026-10-04 10:44). Since then it has accepted your GOs on inceptions that carry a `## Hypothesis`: T-1035 (16adb0a2) and T-1054 (87224129). | — |
| T-898 | `aef:workflowMeta source=` write-only (inception) | LIVE | No decision recorded. | GO / DEFER / NO-GO. Rec: DEFER. |
| T-962 | Does the finding marker duplicate "⚠ no authority"? | LIVE | No ruling found. | Keep both / merge. Rec: GO. |

## Batch-closable

Every open ruling or decision criterion on these 23 tasks is SETTLED or MOOT:

T-184, T-185, T-186, T-189, T-279, T-280, T-281, T-282, T-340, T-345, T-351, T-353, T-402, T-422, T-433, T-498, T-540, T-579, T-588, T-608, T-743, T-827, T-866

Caveats:
- **Inceptions:** T-184/185/186/279/280/281/282 and T-498 close by recording the decision (`fw inception decide ... defer`, or no-go for T-498), not by ticking alone. T-184/185/186 keep revisit triggers in their descriptions.
- **Not completed yet:** T-402 (started-work) and T-422 (captured) may still have open Agent ACs. This triage covered Human criteria only.
- **Confirm provenance:** for T-340, check that PD-200 was recorded by you.

**Mixed: do not batch-close.** Tick only the settled criterion on these:
- **T-368:** #1 MOOT, #2 LIVE (notation/routing revision question).
- **T-590:** #2 SETTLED, #1 LIVE (inventory quality review).
- **T-732:** H1 SETTLED, clause-3 ratification LIVE.
- **T-310:** the ruling criterion is LIVE. It also has two out-of-scope visual criteria.
