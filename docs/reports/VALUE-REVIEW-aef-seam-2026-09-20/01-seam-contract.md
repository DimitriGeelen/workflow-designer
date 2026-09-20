# 01 — AEF↔Designer seam contract and the Arc-0 exit gate (GATHERER G1)

**Gathered 2026-09-20.** Evidence only. No classification, no recommendation.
Every row cites a path:line, a command + its output, a commit, or a rail offset.
Status column is verified against the live tree: EXISTS / PARTIAL / DESIGNED-ONLY / ABSENT.

Commands run for this file (all read-only):
- `bash tools/_t596-arc0-exit-gate.sh` → exit 1
- `bash tools/_t596-arc0-exit-gate.sh --self-test` → exit 0, 13/13
- `python3 tools/_t382-release-lag.py` → exit 0
- `sha256sum src/aef-workflow-designer.html dist/aef-workflow-designer-0.12.0.html`
- `.agentic-framework/bin/fw review-queue`
- `termlink_channel_search` on topic `agent-chat-arc` (read-only MCP verb, no post)

---

## 1. The three Arc-0 exit clauses

Register: `docs/research/executable-workflow/arc-0-exit-clauses.yaml` (EXISTS, 314 lines, last
commit `116cc3b4` 2026-09-20 under T-736).

| Item | Source | Status of source | Data point (with citation) | Window | Kind |
|---|---|---|---|---|---|
| Exit gate text | `roadmap-5be23719.md:147-148` | EXISTS | "topology is non-empty and validated; every blocker finding has a contract disposition and testable scenario; no unresolved source-of-truth ambiguity enters Arc 1" | since 2026-08-25 | structure |
| Ownership table | `roadmap-5be23719.md:64` (Arc 0 row) | EXISTS | AEF column: "Runtime schemas, invariants, refusal matrix, task/evidence contracts, AEF topology". Designer column: "Inventory visual/mapping schema, stable IDs, import/export and round-trip constraints" | since 2026-08-25 | structure |
| Fence table | `roadmap-5be23719.md:353-362` | EXISTS | Fence 1 "Component Fabric non-empty, enriched, validated" evidence owner "Arc 0 task owner; operator reviews uncertainty"; fence 2 "Contract/refusal matrix complete" owner "architecture task owner" | since 2026-08-25 | structure |
| **clause-1** owner | `arc-0-exit-clauses.yaml:95` | EXISTS | `owner: aef`, key phrase "AEF topology" | 2026-08-26→ | structure |
| clause-1 `definition_ratified` | `arc-0-exit-clauses.yaml:103` | EXISTS | `false` — "written by the agent from the §6 fence text. They are PROPOSALS" (`:36-39`) | unchanged 25d | structure |
| clause-1 `attestation` | `arc-0-exit-clauses.yaml:115` | EXISTS | `null` | unchanged since file creation | structure |
| clause-1 `blocks_arc_0_exit` | `arc-0-exit-clauses.yaml:264` | EXISTS | `true` | — | structure |
| clause-1 counterparty answer #1 (RED) | `arc-0-exit-clauses.yaml:121-149`; rail `agent-chat-arc` @650 | EXISTS, re-read live 2026-09-20 | AEF measured 1134 cards, 52 edgeless of 1047, 13 source files with no card, 749 cards outside any watch pattern. Their verdict non_empty=yes, enriched=no, validated=no. Verbatim: *"clause 1 is NOT satisfied on our side, by our own measurement"* | 2026-08-27 | value |
| clause-1 counterparty answer #2 (GREEN) | `arc-0-exit-clauses.yaml:204-252`; rail @1539 | EXISTS, re-read live 2026-09-20 | AEF T-3394, artifact `docs/research/executable-workflow/arc-0-clause-1-attestation.md`, commit `174f31777`, measured at `996a4f9a5`: 1279 cards, 544 Unknown-subsystem, intersection with CORE write set 0, BROAD 0; control `tools/ewcr-arc0-coverage-check.py` coverage lib 166/169, web 162/164, agents 140/140, bin 9/9, policy 8/8, Unknown 0 on all. Scope: **Arc-0 write set only** | 2026-09-19/20 | value |
| clause-1 effect of the green | `arc-0-exit-clauses.yaml:247-252` | EXISTS | "attestation stays null until the operator rules at /review/T-732; Arc 0 remains 0 of 3 satisfied until then." AEF's own disclaimer at `:242-245`: "this post is transport evidence, not collaboration completion" | 2026-09-20 | structure |
| **clause-2** owner/state | `arc-0-exit-clauses.yaml:266-290` | EXISTS | `owner: aef`, `definition_ratified: false`, `attestation: null`, `artifact_absent_locally: true`, `blocks_arc_0_exit: true`. Named as a requirement in six places (roadmap:64,:139,:229,:358, architecture:857, questions:148) and "was never built here" | since 2026-08-26 | structure |
| clause-2 counterparty block | rail @1539 (quoted at `arc-0-exit-clauses.yaml:254-259`) | EXISTS | AEF's governed task T-3389 title records "(blocked: reviews not transferred)"; its Human AC needs four external reviews copied into `docs/research/executable-workflow/reviews/` from 0503-codex-cli-playground — "THAT DIRECTORY DOES NOT EXIST IN THIS REPOSITORY". Two closes, both **their** operator's | 2026-09-20 | friction |
| **clause-3** owner/state | `arc-0-exit-clauses.yaml:292-314` | EXISTS | `owner: shared`, `definition_ratified: false` with `ratification_pending` = "becomes ratified when the operator ticks T-596's Human AC"; `method: local-register`; `blocks_arc_0_exit: true`. No `attestation` field (by design — local method) | since 2026-08-26 | structure |
| Gate verdict, live | `bash tools/_t596-arc0-exit-gate.sh` → exit **1** | EXISTS, runs | `clause-1 BLOCKED — aef answered on 2026-08-27 19:37:01+00:00 and did NOT attest`; `clause-2 BLOCKED — awaiting attestation from aef`; `clause-3 BLOCKED by 4 open question(s)` (open H1,H3,H5,H6; resolved H2,H4). "Arc 0 is still 0 of 3" | 2026-09-20 | usage |
| Gate self-test | `bash tools/_t596-arc0-exit-gate.sh --self-test` → exit **0** | EXISTS, runs | 13/13 control legs pass, incl. 9 poison arms and 2 "accept path reachable" arms (the gate can go green) | 2026-09-20 | value |
| **Gate is unaware of the T-736 green** | `grep -n "superseding\|1539\|T-736" tools/_t597_arc0_clauses.py` → 0 hits | PARTIAL | The gate still narrates only the @650 RED. The register's `counterparty_response_superseding` block (`:204`) is not read by any code. A reader running the gate sees a 2026-08-27 red and no mention of the 2026-09-20 green | 2026-09-20 | friction |

## 2. Rail-citation integrity — the register's claim vs live measurement

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Register claim | `arc-0-exit-clauses.yaml:45-78` | EXISTS | "**EVERY RAIL OFFSET CITED IN THIS FILE IS NOW DANGLING**"; `dangling_offsets: [602, 643, 650, 734, 737, 741, 742]`; `hub_topic_store: empty-on-restart` | written 2026-09-16 (T-733, commit `1198f05c`) | structure |
| Live re-measurement | `termlink_channel_search topic=agent-chat-arc` run 2026-09-20 | **REFUTES the claim** | @602 (T-610 attestation request), @643 (R6/R7 routing), @650 (AEF RED), @734, @737, @741, @744, @777, @1536, @1539 **all return full payloads today**. The chain is intact and readable | 2026-09-20 | value |
| The agent's own correction | `.context/inbox.yaml:1632` OBS-354; rail @1536 | EXISTS | OBS-354: "OBS-353 IS WRONG… 'every rail offset our Arc-0 register cites is now dangling'. Both halves are false." Rail @1536: "That conclusion was wrong. The whole EWCR-ARC0-ATTEST-832 chain is intact… @602 @629 @639 @643 @734 @737 @741 @744 @777 @786, one linear chain" | 2026-09-19/20 | value |
| **The retraction never reached the register** | `git log -- arc-0-exit-clauses.yaml` | PARTIAL | Commit `116cc3b4` (2026-09-20, T-736) edited this very file to add the clause-1 green and left `:45-78` asserting the dangling claim verbatim. The register and the inbox now disagree, and the register is the artifact the counterparty reads | open as of 2026-09-20 | friction |
| Timestamp trustworthiness | rail @1536 | EXISTS | "all eleven EWCR threads report last activity at exactly 2026-09-07 19:36, identical to the minute. That is a bulk-replay artifact… Do not cite a time from this log as evidence of when something was said." Corroborated at `arc-0-exit-clauses.yaml:196-197` | since 2026-09-16 restore | structure |

## 3. The H-register (clause 3's evaluator)

`docs/research/executable-workflow/operator-decisions.yaml` (EXISTS, 215 lines).

| H | Status | blocks_arc_0_exit | source_of_truth | Citation |
|---|---|---|---|---|
| H1 — do Arcs 4–6 supersede the DEFERs + AEF T-2669 NO-GO | **open** | true | none | `operator-decisions.yaml:40-58` |
| H2 — name the AEF counterparty project | **resolved** | true | `handoff-ewcr-v1-designer-fixture.yaml` → `to_project_resolution` | `:60-80`; note at `:77-80` records "RATIFICATION IS SEPARATE AND STILL OPEN. T-590's H2 acceptance criterion is a Human AC and remains unticked" |
| H3 — assign the two correlations | **open** | true | none | `:82-117`. Superseding observation 2026-08-29: **three** correlation values now in circulation (`ewcr-v1`, `ewcr-v1-designer-fixture`, `EWCR-ARC0-ATTEST-832`) — the third a rail thread name minted by an agent at @602 |
| H4 — GO/NO-GO on the §5 slice | **resolved** | true | `.tasks/completed/T-587-…md` → `## Decision` | `:119-137` |
| H5 — reconcile §9 governance deviations | **open** | true | none | `:139-177`. T-620 measured deviation 2 conforming; deviations 1/3/4 "cannot be settled by inspecting the tree" |
| H6 — route R6 and R7 to AEF | **open** | true | none | `:179-215`. Transport done at @643 2026-08-27; "H6 does NOT become `resolved` on the strength of having sent it" |
| Peer input on H3 | rail @777 | EXISTS | 0503 side reports **PD-003 (T-038, 2026-08-26)**: initiative `ewcr-v1`, AEF correlation `ewcr-v1-aef-arc0`, Designer correlation `ewcr-v1-designer-fixture`; "EWCR-ARC0-ATTEST-832 is only the TermLink conversation/thread label". **Not recorded in `operator-decisions.yaml` H3** (grep for `ewcr-v1-aef-arc0` in that file → 0 hits) | 2026-08-29 | friction |
| Manifest precondition | `source-manifest.yaml:19-26` | EXISTS | `designer_agent_correlation: UNASSIGNED`, `shared_initiative_correlation: UNASSIGNED`, note: "No peer handoff may be opened until they are assigned, because Phase 4 completion is defined as read-back on the SAME correlation." A handoff has been open since 2026-08-27 | 24 days | friction |

## 4. Seam tasks — completion vs ratification

All from `.tasks/active/`, `fw review-queue` run 2026-09-20.

| Task | status | owner | Human ACs ticked | Age in review queue | Citation |
|---|---|---|---|---|---|
| T-590 contract inventory | work-completed | human | **0 / 3** | 25d, GO | `.tasks/active/T-590-…md` |
| T-596 exit gate mechanised | work-completed | human | **0 / 1** | 25d, GO | `.tasks/active/T-596-…md` |
| T-597 clauses counterparty-owned | work-completed | human | **0 / 2** | 25d, GO | `.tasks/active/T-597-…md` |
| T-608 attestation request draft | work-completed | human | **0 / 1** | 24d, GO | `.tasks/active/T-608-…md` |
| T-671 Arc-0 fabric fence | work-completed | human | **0 / 1** | 17d, GO | `.tasks/active/T-671-…md` |
| T-732 drain the H-register | **captured** | human | **0 / 5** | 4d, NO-REC | `.tasks/active/T-732-…md` |
| T-733 contact AEF on R6/R7 | work-completed | human | **0 / 1** | 4d, DEFER | `.tasks/active/T-733-…md` |
| T-735 audit store overwrite | work-completed | human | **0 / 1** | 0d, NO-GO | `.tasks/active/T-735-…md` |
| T-736 AEF clause-1 green | work-completed | human | **0 / 1** | 0d, GO | `.tasks/active/T-736-…md` |
| **Total** | — | — | **0 of 16 Human ACs ticked across all nine seam tasks** | oldest 25d | value |
| Whole-project context | `fw review-queue` | EXISTS | 9 inception decisions pending (oldest 71d) + **64 tasks with Human ACs awaiting verification** (oldest T-308, 53d) | — | cost |

## 5. Integration protocol — PULL and PUSH, proven vs described

`docs/aef-designer-integration-protocol.md` (EXISTS, 182 lines).

| Step | Direction | Status | Evidence the doc itself cites | Kind |
|---|---|---|---|---|
| Read `dist/MANIFEST.yaml`, copy artifact, sha256-verify, record pin, serve via `fw designer` | PULL 1–5 (`:26-32`) | DESIGNED-ONLY as written — `:39-41` states the AEF side **cannot** read /opt/832 (T-559) so step 2 as written is not executable | none | structure |
| Realised as a 832-side **push** over termlink `file_send` | PULL, `:37-50` | **PROVEN ONCE** | "This is how release 0.1.0 was delivered (2026-07-10): file_send → AEF session, 394110 bytes, sha256 d0e0177c…0317d" (`:44-45`). No later delivery is cited in the document | usage |
| `fw designer sync --from <received-path>` sha256-verifies against `policy/designer-pin.yaml` | PULL, `:46-47` | EXISTS on the vendored side: `.agentic-framework/agents/designer/designer.sh:31` reads `policy/designer-pin.yaml`; `sync --from-tag` at `:140` requires `source_origin` | usage |
| Pull-at-tag intake | `.agentic-framework/policy/designer-pin.yaml:6-18` | EXISTS | "first used for 0.4.0"; `source_origin: ssh://git@192.168.10.201:6611/workflow-designer` | usage |
| Deterministic rebuild for audit | `:55-56` | UNVERIFIED here (not run) | `scripts/release-designer.sh` "byte-identical artifact + checksum on every run". Would be verified by running it at VERSION 0.12.0 and comparing sha256 | structure |
| Render gate on release cut | `:58-62` | EXISTS | `tests/test_designer_render.py`; bypass `RELEASE_SKIP_RENDER_CHECK=1` warns on stderr | structure |
| Provenance tag per release | `:64` | EXISTS, complete | `git tag \| grep -c designer` → **15**; every version 0.1.0…0.12.0 has a `designer-v*` tag | structure |
| PUSH (improvements AEF→832): file upstream via termlink, 832 implements, AEF re-pins | `:68-80` | PARTIAL | The doc cites "the T-173 / T-175 collaboration threads, and the ring20 RCA upstreams" (`:74-75`) but names no post-0.1.0 re-pin. Peer pin is still 0.8.0 (see §6) | usage |
| Durable vs lossy channel rules | `:84-112` | EXISTS, with a named failure | "AEF's IW-1 question failed to reach 832 durably (2026-07-10): delivered by inject, never submitted, lost on continue" (`:102-104`) | friction |
| Annotation seam (postMessage `aef:ready` / `aef:annotate`) | `:125-166` | EXISTS in contract + manifest flag | `dist/MANIFEST.yaml:23-24` `capabilities: {annotation_seam: 1}`; ratified T-250 GO, rail 216. Whether AEF's `/api/overlay` currently drives it is **UNVERIFIED** from this side (would need an AEF-side probe or a rail read-back) | usage |
| Transport constraint contradicting the protocol | rail @737 §5 | EXISTS | "Our OBS-108 constraint stands: file transfer between our two projects is not a delivery mechanism for seam bytes until that closes, so this is refs-and-hashes only" — i.e. the *proven* PULL mechanism is currently self-embargoed for seam bytes | 2026-08-29→ | friction |

## 6. Release state: VERSION, dist/, pin, lag

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| VERSION | `VERSION` | EXISTS | `0.12.0` | — | structure |
| Released artifact | `dist/MANIFEST.yaml:6-18` | EXISTS | `latest 0.12.0`, `artifact dist/aef-workflow-designer-0.12.0.html`, `sha256 2b448b61…31cf8c`, `bytes 997254`, `released 2026-09-20T16:51:03Z`, `src_commit d31278fb…`, `supersedes 0.11.0` | today | structure |
| src vs released bytes | `sha256sum` (run) | EXISTS | **Identical**: both `2b448b61b7fa6c33f347535748c4df828f5d7c1d4b11322e3b25dc609631cf8c`. Build lag = 0 | 2026-09-20 | value |
| dist/ contents | `ls dist/` | EXISTS | 16 artifacts, 0.1.0 → 0.12.0, plus MANIFEST.yaml | — | cost |
| **Peer pin** | `.agentic-framework/policy/designer-pin.yaml:20-27` | EXISTS, **stale** | `version 0.8.0`, sha256 `cab3c751…`, `source_tag designer-v0.8.0`. Last changed by commit `405a39d9` **2026-07-29** | **53 days** | friction |
| Releases the peer has not adopted | `git log -1 --format=%ad <tag>` | EXISTS | 0.9.0 (2026-08-08), 0.10.0 (2026-08-15), 0.11.0 (2026-08-23), 0.12.0 (2026-09-20) — **four releases**, oldest unadopted 43 days | 43d | value |
| Release-lag probe | `python3 tools/_t382-release-lag.py` → exit **0**, verdict OK | EXISTS, runs | "unshipped product commits since designer-v0.12.0: 0"; "peer pin behind: 0.8.0 -> 0.12.0 (our release is 0 days old)" | 2026-09-20 | usage |
| Probe's own stated bound | probe output | EXISTS | "read from a VENDORED copy of the peer's policy. This reports what they had pinned at our last re-vendor, NOT what they have pinned now. It can therefore only UNDER-report adoption lag." | — | structure |
| Audit reporting of that state | `.context/audits/cron/2026-09-20-2130.yaml:59` | EXISTS | `level: PASS — "Release lag: src, released artifact and peer pin are in step"` — printed while the pin is four versions and 53 days behind, because the gate keys on the *age of the newest release* (`.agentic-framework/agents/audit/audit.sh:2253-2268`) | today | friction |
| Prior record of the same class | `fw review-queue` | EXISTS | T-368 "Release-state blindness: 8 src commits ahead of the 0.8.0 pin" — GO, **43 days** awaiting a Human AC | 43d | value |

## 7. Standards

| Standard | Version / status line | Freeze status | Counterparty ratification | Citation |
|---|---|---|---|---|
| `docs/standards/aef-bpmn-mapping-v1.md` | "**Version:** 1.1 (2026-07-12) · **Status:** frozen core + provisional annex" | Part I **frozen** (guarded by `tests/test_mapping_standard_conformance.py`); Part II **provisional** from `:146` | PARTIAL — G-3 inception marker "ratified… (AEF operator, termlink T-175; 832 sovereign GO, T-195)"; IW-9 authority collapse matched to "AEF's Child-2 compiler (T-2531)". **Remaining Part II items (`tier` default, AC-seeding) stay provisional pending their own rulings** (`:11`) | `aef-bpmn-mapping-v1.md:1-11,146` |
| `docs/standards/aef-bpmn-forward-compile-v1.md` | "**Version:** 1.1 (2026-07-12) · **Status:** 832-side support deliverable for the AEF-led forward bridge" | Adds no new contract; guarded by `tests/test_forward_fixtures.py` | DESIGNED-ONLY on the AEF half: "**No translator is built here.** The generative direction, enrichment, and the approval gate are AEF's" (`:22`) | `aef-bpmn-forward-compile-v1.md:1-22` |
| Total standards | `ls docs/standards/` | EXISTS | **2 files only**; both dated 2026-07-12, unchanged for 70 days | 70d | structure |
| Open ratification asks R1–R7 | `designer-contract-inventory.md:299-307` | EXISTS | 8 named requests to AEF (R1, R2, R3, R3a, R4, R5, R5b, R6, R7). R2 "open since 2026-07-11 on thread T-175". R3 blocks Arc 1's "render without inventing semantics" gate. R5 asks AEF to read back the pilot fixture sha256 `b6a9afd7…1685b` | 71d for R2 | friction |
| R6/R7 disposition today | rail @1539 | EXISTS | R6: blocked on a review transfer inside AEF's repo, **their** operator's call. R7: AEF "will not name a source of truth blind"; answered on the rail by T-736 with IW-11 quoted inline. R1–R5b: no answer recorded anywhere in this tree (grep) | 2026-09-20 | value |

## 8. Fixtures and the rendered corpus

| Item | Source | Status | Data point | Window | Kind |
|---|---|---|---|---|---|
| Pilot fixture | `docs/research/executable-workflow/fixtures/ewcr-pilot-human-gate-script-human-gate.bpmn` | EXISTS | 12351 bytes, sha256 `b6a9afd7eb03…1685b` (quoted at rail @737). **Sole file in `fixtures/`** | since 2026-08-26 | structure |
| What references it | grep | EXISTS | `T-590`, completed `T-591`, `source-manifest.sha256`, `source-manifest.yaml`, `designer-contract-inventory.md`, `tools/_t591-roundtrip-teeth.sh` — all 832-side. No AEF-side read-back recorded | — | usage |
| Envelope delivery state | `handoff-ewcr-v1-designer-fixture.yaml:320-340` | **DESIGNED-ONLY** | `state: prepared`, `delivered: false`, `delivered_at: null`, `transport: null`, `accepted: false`, `read_back_received: false`, `verdict: null` | unchanged 25d | usage |
| Envelope's stated reason for non-delivery | same, `:330-340` | **stale premise** | "`fw`, `git`, `curl` and `python3` are all denied by the session permission profile… Sending is also a separate authorisation". That send-authorisation premise was later **overturned by the operator** — `arc-0-exit-clauses.yaml:18-23`: "That was invented, and the operator corrected it… The invented gate stalled Arc 0 for three sessions." The envelope still carries it | 2026-08-26→ | friction |
| `source-manifest.sha256` coverage | rail @737 §1 | EXISTS but narrow | `sha256sum -c` → exit 0, **6/6 OK**, over a set that omits `source-manifest.yaml`, `operator-decisions.yaml`, `arc-0-exit-clauses.yaml`, `reflection-designer.md` — "the two members your attestation actually turns on". Nine-member expansion is an open operator decision | 2026-08-29→ | friction |
| Rendered corpus | `examples/aef-processes/rendered/` | EXISTS | 24 `.bpmn` + `README.md`; 24 `*.workflow.yaml` sources | — | structure |
| What governs regeneration | `examples/aef-processes/rendered/README.md:1-21` | EXISTS | "generated, not hand-authored" from `../*.workflow.yaml` via `tools/yaml-to-bpmn.py` (T-040). "The canonical source of truth is always the `.workflow.yaml`. Do not edit these `.bpmn` files by hand" | — | structure |
| The README contradicts the standing rule | `.context/episodic/T-300.yaml:26,41` | PARTIAL | T-300 removed the regen step: bake writes the editor's own serialized XML byte-verbatim; the YAML geometry patch was removed because "**with regen forbidden** … the YAML patch is no longer load-bearing". Running the README's regen command today is the act T-300 proved destructive (`+2839/-3904`, reverted) | since 2026-07-29 | friction |
| Note on that citation | — | UNVERIFIED | T-300's episodic cites "G-012" for "regen forbidden", but `.context/project/concerns.yaml:2` G-012 is a *different* gap (vendored reviewer policy absent). No concerns entry mentions regen. Would be verified by an operator naming the correct gap id | — | friction |
| Who writes into the corpus | `.context/project/concerns.yaml` G-048 (`:3016`), G-049 (`:3064`) | EXISTS, both `watching` | G-049 (severity **high**): "`tools/gallery-serve.py:653` reads `promote = bool(payload.get('promote')) or ALLOW_NEW_CORPUS`… Any caller able to POST /api/save — an agent included — can publish directly into `examples/aef-processes/rendered/`". G-048: `/api/save` write path has no `_within_repo` containment, only one regex | detected 2026-09-05/06 | friction |
| Staleness signal | `for y in *.workflow.yaml; [ $y -nt $bpmn ]` | 10 of 24 `.bpmn` older than their YAML by mtime | mtime is not proof (checkout order); git shows `rendered/` last touched 2026-07-29 (T-300) vs a `.workflow.yaml` commit 2026-07-31 (T-313) | — | UNVERIFIED — would need `bake-clean-layout.py --check` run to settle |

## 9. Reports about the seam

| Report | Status | Established as FACT | Left open |
|---|---|---|---|
| `docs/reports/T-732-h-register-dossier.md` (189 lines, 2026-09-16) | EXISTS | Clause table: clause-1 answered red, clause-2 artifact absent, clause-3 H2/H4 resolved & H1/H3/H5/H6 open. Recommendations quoted verbatim per PL-323. Approvals route `http://192.168.10.107:3013/approvals` | Its own correction (`:30-36`): clause 3 is "partly counterparty-blocked too, through H6" — whether AEF answered R6/R7 "is not established in this register". Filing tasks for Arcs 1/3/5/6 deliberately out of scope per the T-681 GO |
| `docs/research/executable-workflow/aef-transport-verdict.md` (T-680, 2026-09-05) | EXISTS | "the 999-AEF seam is **live**. It was recorded as unreachable. That record was wrong." 66 posts labelled 999-AEF at offsets 100–969. **`sender_id` cannot separate producers on this mesh** — 3 distinct sender_ids vs 18 producer labels; AEF posts attributable to a non-ours sender_id: **0** | The DM mailbox `dm:3bba15e681b3a078:…` is a no-reader (resolves to `framework-agent-systemd`, 010-termlink's unit) — 5 DMs sent there were never delivered (rail @1031) |
| `docs/reports/T-681-ewcr-next-arc-inception.md` | EXISTS | (cited via T-732 dossier) operator GO recommends against decomposing counterparty-blocked work: "manufactures a backlog that measures as progress and cannot move" (2026-09-05) | — |
| `docs/research/executable-workflow/cannot-represent-yet.md` (T-590) | EXISTS | Research artifact; 3 named gaps (§2.1 three pilot steps with no node, §6.2.2 declared failure routes, §6.3 edges as interfaces). "A gap is not a defect" | Nothing ratified; its dispositions await R1–R7 |
| `aef-attestation-request-draft.md` (T-608) | EXISTS | Draft of the @602 ask | Its Human AC is 0/1 at 24d |
| T-590/T-596/T-597/T-671/T-733/T-735/T-736 reports | **ABSENT as `docs/reports/` files** | — | Only T-681 and T-732 have report files; the rest carry their findings in task files and in `docs/research/executable-workflow/`. `ls docs/reports/ \| wc -l` → 106 |

## 10. Non-use diagnosis (evidence gathered, not classified)

For each seam artifact with no observed use, what the tree says for each reading.

| Artifact | A BROKEN | B NEVER WIRED | C UNDISCOVERABLE | D UNMEASURED | E NOT WANTED |
|---|---|---|---|---|---|
| `tools/_t596-arc0-exit-gate.sh` (+ `_t596_arc0_check.py`, `_t597_arc0_clauses.py`) | **No** — runs, exit 1 with a coherent verdict; self-test 13/13 exit 0 | **Evidence for**: `grep -rl` finds callers only in 2 task files, 2 handovers, 3 fabric cards and itself. **Not called by `audit.sh`, not in `.context/cron-registry.yaml` (6 jobs, all `fw audit` or retention), not in `tests/`** | **Evidence for**: `.agentic-framework/bin/fw help` returns 0 lines matching arc/ewcr/seam. Reachable only by typing the path | **Evidence for**: no run log, no `.context/` record of gate runs; its verdict is written nowhere a reader passes | **Against**: T-732 dossier (2026-09-16) and T-736 (2026-09-20) both still treat the gate's clauses as the live frame |
| `arc-0-exit-clauses.yaml` `counterparty_response_superseding` block | — | **Evidence for**: no code reads it (`grep` in `_t597_arc0_clauses.py` → 0 hits), so the green is invisible to the only mechanical reader | — | **Evidence for**: the gate is the instrument, and it does not measure this field | — |
| `handoff-ewcr-v1-designer-fixture.yaml` (the envelope) | — | **Evidence for**: `delivered: false` 25 days after preparation; no transport ever attached | — | — | **Evidence for**: rail @737 §5 records a live self-embargo — "file transfer between our two projects is not a delivery mechanism for seam bytes until [OBS-108] closes". **Against**: R5 (read back the fixture) is still listed as an open ask at `designer-contract-inventory.md:304` |
| `docs/standards/*` (2 files, 70 days unchanged) | — | **Against**: both are guarded by named test files (`test_mapping_standard_conformance.py`, `test_forward_fixtures.py`) | — | **Evidence for**: no record in this tree of AEF exercising the forward-compile spec since T-2531 | **Evidence for**: Part II items are explicitly "pending their own rulings" — a positive recorded reason they sit still |
| Peer pin at 0.8.0 / four unadopted releases | — | — | — | **Evidence for**: the only instrument (`_t382-release-lag.py`) states in its own output that it reads a vendored copy and "can only UNDER-report adoption lag"; the audit prints PASS | **Evidence for**: protocol `:34-35` says re-pin is the consumer's act ("never track HEAD"), so non-adoption may be the counterparty's standing choice. **UNVERIFIED** — a rail read-back of AEF's current `policy/designer-pin.yaml` would settle it |
| `fixtures/` (one file) | — | **Evidence for**: referenced only by 832-side artifacts; no counterparty read-back recorded | — | — | — |

## 11. Data gaps (what I could not verify, and what would verify it)

1. **AEF's current pin** — only a vendored copy is readable here (T-559 blocks reading /opt/999). Verified by a rail read-back of their `policy/designer-pin.yaml` version+sha256.
2. **Whether AEF's `/api/overlay` currently drives the annotation seam** — contract exists both sides on paper; no live handshake observed. Verified by an AEF-side probe or a rail read-back.
3. **`scripts/release-designer.sh` determinism** — claimed at protocol `:55-56`, not re-run here (would mutate dist/). Verified by a rebuild into a temp dir + sha256 compare.
4. **Rendered-corpus freshness** — mtime says 10 of 24 are older than their YAML; git history says otherwise. Verified by `python3 tools/bake-clean-layout.py --check` (not run; it may write).
5. **The "G-012 = regen forbidden" citation** — no concerns entry matches. Verified by an operator naming the correct gap id, or by registering it.
6. **`fw audit` full-run seam checks** — not run (OBS-358: hangs). Only saved cron records read.
7. **AEF's `arc-0-clause-1-attestation.md`** — quoted at rail @1539, not readable from this side (T-559). Verified by file transfer or by the operator reading it at /review/T-732.
8. **Whether R1, R3, R3a, R4, R5, R5b were ever answered** — grep finds no answer in this tree; absence of a record is not a record of absence. Verified by a rail search on those ids.
