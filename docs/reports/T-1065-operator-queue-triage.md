# T-1065: Operator queue triage (every open Human criterion in `.tasks/active/`)

Re-run on 2026-10-21. It replaces the 2026-10-06 version (commit 0a414758), which covered only rulings and used LIVE/SETTLED/MOOT. This one covers **every** open `### Human` criterion and uses four classes:

- **LIVE**: the operator still has to answer this now.
- **SETTLED**: already ruled or overtaken elsewhere (the old MOOT class is folded in, marked *premise gone*).
- **REVIEWER**: goes to the independent reviewer (`fw reviewer judge T-XXX --criterion N`). The routing class is cited.
- **PLACEHOLDER**: inception template text with nothing to review yet.

Read-only. No task file was edited except T-1065's own, and nothing was ticked.

**Summary: 78 open Human criteria across 69 tasks. LIVE 19 · SETTLED 26 · REVIEWER 30 · PLACEHOLDER 3.**

## Method

1. Extraction: every unchecked `- [ ]` under `### Human` in `.tasks/active/*.md`, with HTML comments stripped. That gives 78 criteria across 69 tasks. The script is in `/tmp/t1065w/extract.py`, which is not committed.
2. Routing: `.agentic-framework/bin/fw task delegate T-XXX --dry-run --json` for all 69 tasks. All exited 0, and their criterion count matches 78. The AEF ruling id is D-626. Route totals:
   - unclassified → REVIEWER-JUDGES: 32
   - inception-decision → REVIEWER-JUDGES: 17
   - sovereignty-field → OPERATOR-ONLY: 11
   - tier0-or-bypass → OPERATOR-ONLY: 5
   - act-in-the-world → OPERATOR-ONLY: 5
   - taste → REVIEWER-JUDGES: 4
   - agent-self: 2
   - render-surface → REVIEWER-JUDGES: 1
   - converted to Agent (the Expected clause is a shell check): 1
3. Checking for settlement: `.context/project/decisions.yaml` (PD-355 … PD-416, everything after 2026-10-06), `docs/research/executable-workflow/operator-decisions.yaml` and `arc-0-exit-clauses.yaml`, the 2026-10-06 report's citations (re-checked where the state could have moved), and the live repo state.
4. **The route is a keyword match, not a verdict.** Some OPERATOR-ONLY routes come from a single word: T-358 and T-1242 'sovereignty'/'tier0', T-340 '--force', T-866 'Tier 0'. Some reviewer routes are rulings on governance settings. When the class here differs from the route, the row says why. Under PD-357, AEF's route wins for anything that goes to the reviewer: the reviewer may still escalate to the operator.

## LIVE (19): questions for the operator, with a recommended answer

| # | Task / crit | Route | Question as the operator would get it | Recommended answer |
|---|---|---|---|---|
| 1 | T-358 #1 | sovereignty-field | Which lane/pool fabrication repair: A, B, C, AB or none? (The lane half is already gone, T-888 405dc2eb.) | **AB**, falling back to A. |
| 2 | T-368 #2 | unclassified, kept LIVE (only you know the plan) | Is a notation/routing revision planned beyond T-1090's routing prefs (PD-360/361)? | **No further revision planned.** AEF keeps drafting in the current notation. |
| 3 | T-392 #1 | sovereignty-field | Do you retroactively approve the governance-hook change that shipped as shape C (5b38a63a, T-575)? | **Approve C as shipped.** |
| 4 | T-410 #1 | tier0-or-bypass | Rewrite history and force-push to purge the old, already rotated session key? | **No.** Leave history alone: the key is rotated and dead. |
| 5 | T-410 #2 | sovereignty-field | Should Watchtower be LAN-reachable? (It binds `0.0.0.0:3013` today and `watchtower.url` is the LAN IP.) | **Yes, LAN-only**, matching how you use it now. Never internet-facing. |
| 6 | T-426 #1 | unclassified, kept LIVE (it is a `.claude/settings.json` hook registration, B-005 operator edit) | Register the T-421 claim-drift detector, and on which event? It is still not in `settings.json`. | **Register it on Stop (A)**, through a launcher job. |
| 7 | T-592 #1 | unclassified, kept LIVE (a new blocking gate changes enforcement) | Should the vacuous-verification detector become a blocking gate? | **Keep it advisory now.** Make it blocking only after a clean run with no false positives. |
| 8 | T-593 #1 | sovereignty-field | Who may author decision-attribution fields in seam artifacts? | **(a)** Extend the `*_proposed` split with a gate. Agents write only `*_proposed`. |
| 9 | T-596 #1 | inception-decision (keyword), kept LIVE: ticking it ratifies clause 3 | The register reads H1/H3 as open, but both are now resolved (H1 22014fea, then reversed by PD-400; H3 403502ea). Ratify clause 3 now? | **Ratify clause 3 after H5 and H6** (still `open` in `operator-decisions.yaml`), as T-732 recommends. |
| 10 | T-597 #1 | agent-self (misroute), kept LIVE: ratifying a definition | Ratify the Arc-0 exit-clause definitions (`definition_ratified: false`)? | **Ratify** them, together with T-736 and T-732 #2 in one sitting. |
| 11 | T-597 #2 | sovereignty-field | AEF answered RED on clause 1. What does Arc 0 do now? | **(a)** A scoped request to AEF. This has partly happened already (T-608 sent it, b9e432bb; T-736 records a later green). |
| 12 | T-676 #1 | inception-decision (keyword), kept LIVE: it changes P-002 enforcement | Should P-002 exempt read-only Bash when no task focus is set? | **GO, Variant B.** |
| 13 | T-696 #1 | sovereignty-field | How do we prevent a pre-filled `voi_score` that rates an unassessed task: A, B, C, D or none? Note PD-377 (T-1178) kept the prefill with a note, which is the same warning-only prevention this task says failed. | **D**, with A as a precondition, done upstream. |
| 14 | T-703 #1 | act-in-the-world | May the agent drain the 82 carried-by-completed-task notes with `fw note resolve` (T-914)? | **Yes**, authorise the agent to resolve them. |
| 15 | T-732 #2 | unclassified | Tick T-596 to set clause 3 `definition_ratified: true`? | This is the same decision as #9. One answer closes both. |
| 16 | T-736 #1 | unclassified, kept LIVE: a ratification | Ratify Arc-0 clause 1? | **Ratify (A)** alongside #9 and #10. |
| 17 | T-740 #1 | sovereignty-field | Rule the AEF-seam value review (`VALUE-REVIEW-aef-seam-2026-09-20.md`) item by item. | **Accept the findings as evidence and act on them.** Rule the §12 questions separately. |
| 18 | T-742 #2 | sovereignty-field | Answer the 12 Sovereign questions in §12. | Per question. They have no blanket answer. |
| 19 | T-986 #1 | unclassified, kept LIVE (PD-355 excludes project objectives) | Do the written objectives say what 832 is for, in your words? | Read them and correct them. The reviewer cannot judge your own words. |

## SETTLED (26): already decided, so close them via the operator-only routes

| Task / crit | Where it was settled |
|---|---|
| T-184, T-185, T-186 (inception) | Operator DEFER on 2026-07-11: `.tasks/completed/T-175-*.md:236`. Record it with `fw inception decide … defer`. |
| T-279, T-280, T-282 (inception) | **PD-400** (operator, 2026-10-19, T-732): H1 reversed, "revive and build T-279 … T-280 … T-282; callActivity first". Record **GO**, not the DEFER the 10-06 report said. |
| T-1213 (inception) | **PD-399** (operator, 2026-10-19, T-1203): ownership by risk assessment, with an independent reviewer at every agent close. This is the sovereignty call the criterion names. Record GO. |
| T-498 (inception) | *Premise gone*: the operator withdrew it ("oh i was confused", T-498:119-123). Record NO-GO or DEFER. |
| T-189 #1 | PD-087 (2026-07-12): IW-9 graduated to v1.1 "under Dimitri sovereign GO". |
| T-340 #1 | PD-200 (2026-08-14): "T-340 DI repair semantics: b". |
| T-351 #1 | *Premise gone*: the host rebooted on 2026-10-05, so the six orphan servers are gone (10-06 report). |
| T-353 #1 | PD-308 (2026-09-22, T-802): "NARROW YES". |
| T-368 #1 | `designer-v0.9.0` was tagged (8cd0c5d3, T-393), and many releases have shipped since. |
| T-422 #1 | `check-arc-id` is registered by the framework: `.claude/settings.json:87`. |
| T-423 #1 | **PD-356** (2026-10-06, T-1074): "A: keep the five XSDs, add OMG's copyright and permission notice". |
| T-433 #1 | The vendor bumps were taken: 1.7.68 (7b5e227e), 1.8.2 (T-1049), 1.8.3 (0e542b61), and later. |
| T-540 #1 | 2db88a64 (T-542): "operator approved all three product drivers". |
| T-579 #1 | *Premise gone*: T-581 replaced `BASELINE_REF` with recorded goldens. |
| T-586 #1 | The deny rules are in `.claude/settings.json:309-311` (72727215, an operator edit). `python3 tools/_t586-worktree-denial-guard.py` prints "All worktree routes are denied." |
| T-588 #1 | PD-267, plus full upgrades through the re-vendor protocol. |
| T-590 #2 | H2 was resolved on 2026-08-26 and the envelope was sent and verified (0fbcddbb, 6b39a55b). |
| T-608 #1 | The request was sent at offset 602, thread EWCR-ARC0-ATTEST-832 (b9e432bb). The operator's correction under T-610 says contacting AEF was never gated. |
| T-732 #1 | **PD-400** (2026-10-19): H1 ruled (reversed). |
| T-743 #1 | *Premise gone*: 0.12.0 has been superseded by many releases. |
| T-827 #1 | Already posted, and the sha256s match the current files (T-1033, e4db8955). See also PD-401 (T-969). |
| T-866 #1 | The gate was exercised live: it refused twice (39e5158d), then accepted GOs on T-1035 (16adb0a2) and T-1054 (87224129). |

Batch-closable tasks (every open Human criterion is SETTLED): **T-184, T-185, T-186, T-189, T-279, T-280, T-282, T-340, T-351, T-353, T-422, T-423, T-433, T-498, T-540, T-579, T-586, T-588, T-608, T-743, T-827, T-866, T-1213** (23 tasks). Mixed tasks, where only the settled criterion can be ticked: T-368 #1, T-590 #2, T-732 #1.

## REVIEWER (30): send to `fw reviewer judge T-XXX --criterion N`

| Task / crit | Route | Note |
|---|---|---|
| T-1212 #1 | unclassified | Screenshot review. The criterion already names the reviewer. |
| T-1241 #1 | unclassified | Lens screenshot review. |
| T-1241 #2 | unclassified | "The operator can follow it": a large-UX check. 832 proposed `large-ux` as a carve-out (T-1077), but AEF has not ruled, so it goes to the reviewer, who may escalate. |
| T-308 #1, #2 | taste | PD-355 covers small visual checks. |
| T-310 #1 | taste | |
| T-310 #2 | unclassified | Layout default ("declared membership wins"). Its premise moved after T-888. |
| T-325 #1 | unclassified | §1 carriers and W-GW-AMBIGUOUS. Rec: GO (b), DEFER (a). |
| T-347 #1 | unclassified | Rec (a), preserve and re-emit. PD-409 (T-1217) already applied (a) to link events. |
| T-432 #1 | unclassified | Push-gate sections. Rec (c). |
| T-449 #1 | unclassified | Which "pair-draft" definition. |
| T-537 #1 | unclassified | `termlink_agent_chat_arc_recent` treatment. |
| T-565 #1 | unclassified | IW-0: always emit `<aef:workflowMeta>` (already shipping). |
| T-589 #1 | unclassified | The field name "Fabric component". |
| T-590 #1 | unclassified | Is the inventory usable as a negotiating document. |
| T-606 #1 | render-surface | The approvals surface reads correctly, plus OBS-319. |
| T-643 #1 | inception-decision (keyword "NO-GO") | Really a taste check on verdict colours. |
| T-647 #1 | unclassified | Is the manifest the right governance object. |
| T-671 #1 | unclassified | Arc-0 component scope. |
| T-695 #1 | unclassified | How to stop the template scoring itself. Rec A. |
| T-733 #1 | unclassified | Is a `/tmp`-runtime hub an acceptable evidence source. Rec DEFER. |
| T-735 #1 | agent-self | The wording fix. The phrase is not in the repo (`git log -S` finds nothing). Rec: close on A. |
| T-742 #1 | unclassified | The 22 product findings. Only F-10 has been acted on (87a73faa). |
| T-884 #1 | converted (shell-check Expected) | Reviewer-closeable. Better moved to `### Agent`. |
| T-893 #1 | taste | |
| T-962 #1 | unclassified | Marker vs "⚠ no authority". |
| T-1093 (inception) | inception-decision | Rec GO (export formats, an owner request). |
| T-277 (inception) | inception-decision | Rec DEFER (parked on AEF T-2652). |
| T-811 (inception) | inception-decision | Rec DEFER (the bounded item shipped under T-836). |
| T-898 (inception) | inception-decision | Rec DEFER. |

For the four inceptions, AEF routes the go/no-go to the reviewer, who judges whether a human is needed. Recording it is still `fw inception decide`, which in 832 runs as a launcher job.

## PLACEHOLDER (3)

These are inception template boxes ("Review exploration findings and approve go/no-go decision") on inceptions whose own Recommendation says the exploration has not been done. There is nothing to review yet.

| Task | Why it is not a question yet |
|---|---|
| T-1107 | Rec DEFER: "the field survey … has not been done". The stopgap is T-1106. |
| T-1115 | Rec DEFER: the delivery design has not been read and AEF/TermLink have not been asked. Note: PD-363 (2026-10-10) answered its question D only. |
| T-1242 | Rec DEFER: the evidence has not been gathered (cross-vendor advice, AEF v1.1 / T-4415). Its tier0 route comes from a keyword. |

## Changes since the 2026-10-06 version

- These moved from LIVE to SETTLED: T-423 (PD-356) and T-732 #1 (PD-400). T-279/T-280/T-282 changed from a DEFER to a **GO** (PD-400).
- These closed in the meantime and are gone from the queue: T-209, T-281, T-341, T-344 (PD-405..407), T-345 (PD-408), T-402, T-702.
- These are new since: T-1093, T-1107, T-1115, T-1212, T-1213, T-1241, T-1242. The 10-06 scope also left these out: T-308, T-586, T-589, T-643, T-884, T-893, T-986.
