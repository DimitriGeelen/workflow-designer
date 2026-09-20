# G2 — Forward path: workflow → program

**Gatherer G2, value review, 2026-09-20.** Evidence only. No classification, no
recommendations. Every row cites a path:line, a command + its output, a commit hash, or a
record id. Anything not verified in this pass is marked **UNVERIFIED**.

**Boundary compliance (T-559):** all reads were inside `/opt/832-Workflow-designer`
(including its vendored `.agentic-framework/`). Nothing outside the repo was read. No
`fw audit` run (OBS-358). No mutation of `.tasks/`, `.context/`, `dist/`,
`build/gallery/`, or `examples/aef-processes/rendered/`.

**One incidental write occurred and is disclosed:** `tests/test_t258_annotation_seam.py`
writes a screenshot to `.playwright-mcp/t258-annotation-badges.png` as part of its normal
run. That path was not in the prohibited set, but it is a write and is recorded here.

---

## 0. Commands run in this pass (all read-only except the disclosed screenshot)

| Command | rc | Output (abbreviated) |
|---|---|---|
| `.agentic-framework/bin/fw help` | 0 | v1.6.354; **no `designer` and no `bpmn` row in the printed help** |
| `.agentic-framework/bin/fw designer --help` | 0 | usage: `status`/`path`/`sync --from <file>` |
| `.agentic-framework/bin/fw designer status` | 0 | `version: 0.8.0 … PRESENT ✓ (sha256 matches pin)` |
| `.agentic-framework/bin/fw designer url` | 0 | `http://localhost:3000/designer` |
| `.agentic-framework/bin/fw bpmn` | 0 | usage: `compile` / `compile --write` / `promote` / `promote --write` / `claim` |
| `.agentic-framework/bin/fw bpmn compile tests/fixtures/valid/inception-gonogo.bpmn` | **1** | `error: compiler not found at /opt/832-Workflow-designer/.agentic-framework/tools/bpmn_to_tasks.py` |
| `.agentic-framework/bin/fw bpmn promote all` | 0 (shell) | `error: promoter not found at /opt/832-Workflow-designer/.agentic-framework/tools/bpmn_promote.py` |
| `ls .agentic-framework/tools/` | 2 | `No such file or directory` |
| `python3 tests/test_promote_contract.py` | **0** | `OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)` |
| `python3 tests/test_two_lane_joint_contract.py` | **0** | `OK: two-lane joint promote contract — two-lane-joint.bpmn (sha 2ba55eedbd90)` |
| `python3 tests/test_typed_event_fixture_contract.py` | **0** | `OK: typed-event fixture contract — typed-events.bpmn (sha 5467071b3a39), boundary-events.bpmn (sha 37eec1b0f10a)` |
| `python3 tests/test_designer_export_contract.py` | **0** | `PASS: designer export-contract guard — 8 owner-bearing node(s) … teeth proven` |
| `python3 tests/test_roundtrip_serialization.py` | **0** | `36 keys / 36 LIVE / 0 BLIND …` / `OK: round-trip serialization is a semantic fixed point` |
| `python3 tests/test_bridge_seam_roundtrip.py` | **0** | `selftest … detectsDrop: true, missingCount 27/27` / `OK: bridge emissions survive editor import with no silent drop` |
| `python3 tests/test_t258_annotation_seam.py` | **0** | `OK: annotation seam v0 loop green — ready handshake, badge intake, … spoof rejection` |

`tests/run-bridge-tests.sh` (2211 lines, 94+ legs) was **NOT** run: it contains legs that
read and, per its own comments at `:2144-2147`, have been observed to move files under
`.context/audits/` — inside my prohibited write set. Status of that suite is therefore
**UNVERIFIED in this pass** (last independently-reported result: `docs/reports/T-356-third-party-fidelity.md:109` — "69 passed, 0 failed").

---

## 1. The product's export/save path

`src/aef-workflow-designer.html`, 997254 bytes, one file. Last change
`66e04cff 2026-09-09` ("T-690: extensionElements before conditionExpression").

| Item | Location | Status | Evidence | Invoked by | Last change | Non-use readings found |
|---|---|---|---|---|---|---|
| `buildBpmnXml(state)` — the single serializer | `src/aef-workflow-designer.html:10158` | EXISTS | 9 call sites: `:7370, :7373, :7392, :7401, :8645, :8650, :8655, :8886, :11107, :11242` | autosave/history, XML panel, Save-to-file, Save-to-project, seed capture | 66e04cff 2026-09-09 | — (in constant use) |
| `parseBpmnXml(text)` — the single deserializer | `src/aef-workflow-designer.html:10422` | EXISTS | call sites `:7375, :9632` | file open, history restore | same | — |
| **Export format #1: BPMN 2.0 XML file download** | `:8653-8666` (`$('btn-save').onclick`) | EXISTS | `a.download = \`${id}.v${v}.bpmn\`` at `:8663`; blob type `application/xml` at `:8656` | Save button in the editor UI | same | — |
| **Export format #2: BPMN XML to clipboard / on-screen panel** | `:8644-8652` (`btn-xml`, `btn-copy-xml`) | EXISTS | `colorizeXml(buildBpmnXml(state))` `:8645`; `navigator.clipboard.writeText(raw)` `:8651` | editor UI | same | — |
| **Export format #3: durable versioned save to project** (`POST /api/save`) | `:8903`; server `tools/gallery-serve.py` | EXISTS | body `{id, bpmn, png, note}` at `:8905`; PNG thumbnail via `captureThumbnail()` `:8902`; button revealed only if `/api/health` answers (`:8909` region, comment at `:8869-8871`) | editor UI when the write-capable sidecar is up | gallery-serve.py `04c3366e 2026-09-07` | — |
| **Export format #4: canonical YAML** | — | **ABSENT from the product** | grep for `toYaml|exportYaml|yamlFrom` in `src/aef-workflow-designer.html` → 0 hits. The editor emits BPMN-XML only; YAML is the *hand-authored/bridge* form (`tools/yaml-to-bpmn.py` goes YAML→BPMN, one direction) | n/a | n/a | **B NEVER WIRED** — `docs/designer/schema.md:106` §3 defines the YAML canonical form as the source-controlled representation, but no code path in the editor writes it |
| **Export format #5: task YAML / manifest** | — | **ABSENT from the product** | see §3 | n/a | n/a | — |

### The `aef:` extension namespace — what the export carries

26 distinct `aef:*` markers appear in the editor source (`grep -oE 'aef:[a-zA-Z]+' | sort | uniq -c`):
`aef:eventDef` (17), `aef:link` (13), `aef:position` (12), `aef:meta` (10), `aef:uid` (9),
`aef:workflowMeta` (3), `aef:ready` (3), `aef:waypoint` (2), `aef:routing` (2), `aef:io` (2),
`aef:endpoint` (2), `aef:decisionOutputs` (2), `aef:decisionInput` (2), `aef:boundaryPos` (2),
`aef:annotate` (2), `aef:anchors` (2), `aef:routingHint`, `aef:output`, `aef:loopDetour`,
`aef:laneMeta`, `aef:input`, `aef:forceStraight`, `aef:extensionElements`, `aef:contextReads`,
`aef:constituents`, `aef:artifactsWrites` (1 each).

Two of these — `aef:ready` and `aef:annotate` — are **postMessage** types, not serialized
elements (see §6). The serialized vocabulary is specified at `docs/designer/schema.md:570`
§7.2 (21 rows). `docs/designer/architecture.md` was not needed to establish any row above
and was **not read** in this pass.

The governance-bearing payload of `aef:workflowMeta`, as emitted at
`src/aef-workflow-designer.html:10192-10207`:

| Attribute | Emitted | Citation |
|---|---|---|
| `id` | always | `:10193` |
| `uuid` | only when set (T-224 S1, spliced after `id`) | `:10199` |
| `version` | always (default `"1"`) | `:10194` |
| `schemaVersion` | always (default `2`) | `:10195` |
| `title`, `description`, `source`, `tier_default` | conditional | `:10200-10203` |
| `pageWidth` | conditional (T-255, view layout) | `:10206` |

**What the export does NOT carry** (re-measured in `T-209` and independently confirmed by
the grep counts in `.tasks/active/T-209-…md`): `aef_provenance` 0 occurrences,
`status="captured"` 0 occurrences; `provenance` 2 / `reconcile` 6 / `promote` 5 — all
inside comments. These are the AEF-OUTPUT fields; 832 emits none of them.

---

## 2. The bridge and the non-probe tooling

`tools/` holds 330 entries; **52** are non-probe (278 are `_tNNN-*` per-task probes).
`tests/` holds 182 files.

| Item | Location | Status | Evidence | Invoked by (non-comment) | Last change | Non-use readings found |
|---|---|---|---|---|---|---|
| **The bridge** — YAML→BPMN renderer | `tools/yaml-to-bpmn.py` (383 lines) | EXISTS | docstring `:1-20`; `TYPE_MAP` at `:29+`; emits no BPMN-DI by design (`:16-18`) | `tests/test_bridge_aef_passthrough.py:28`, `tests/test_editor_bridge_structured_parity.py:33`, `tests/test_editor_extension_shape_consistency.py:30`, `tests/test_editor_namespace_consistency.py:64`, `tests/test_harness_cross_form_agreement.py:12`, `tools/_bridge-seam-roundtrip-cdp.mjs`, `tests/run-bridge-tests.sh` | `4a1a30e1 2026-07-19` | **Tests-only.** No production/CLI caller found outside the test tree; it is not wired into `fw`. Reading: **B NEVER WIRED** to any operator surface — by stated design, `tools/README.md:29-31`: "Standalone by design (not wired into the vendored `fw` CLI) to respect the product/framework boundary" → carries a positive recorded reason, so also **E NOT WANTED (as an fw verb)** |
| **The validator** | `tools/validate-workflow.py` (1773 lines) | EXISTS | docstring `:1-32`; two validators, `Validator` (YAML) + `XmlValidator` (BPMN); exit codes 0/1/2 `:19-23` | `tests/run-validator-tests.sh:19`, `tests/test_check_pass_reachability.py:62`, `tests/test_dead_leg_census.py:91`, `tests/test_harness_emitter_fidelity.py:60`, `tests/test_editor_namespace_consistency.py:63`, and **imported by path** by `tests/test_promote_contract.py:48-52` | `445d726f 2026-08-03` | Same as the bridge: tests-only, with the same positive recorded reason at `tools/README.md:29-31`. Note `validate-workflow.py:29-31` says the framework "may later adopt it as `fw workflow validate`" — that verb is **ABSENT** from `fw help` |
| **The compiler (BPMN→tasks)** | **not in 832** — `.agentic-framework/tools/bpmn_to_tasks.py` (referenced, absent) | **ABSENT here** | `.agentic-framework/agents/bpmn/bpmn.sh:8` sets `COMPILER="$FW_ROOT/tools/bpmn_to_tasks.py"`; `ls .agentic-framework/tools/` → `No such file or directory`; invoking returns rc 1 with `error: compiler not found` | nothing, in this repo | n/a | **A BROKEN in this checkout** — the verb is routed but its target file was never vendored. Whether AEF's own checkout has it is **UNVERIFIED** (out of boundary) |
| **Corpus geometry checker** | `tools/check-lane-bands.py` | EXISTS | docstring `:2-6` — "None of them check *geometry*: whether a node's y-box actually falls inside the lane band" | `tests/check-corpus-geometry.sh:23,52,69`; referenced by `tools/bake-clean-layout.py:18` | `58835de7 2026-07-03` | Tests-only; wired into a suite that is itself a leg of `run-bridge-tests.sh` |
| Off-page connector CLI (832's own) | `tools/bpmn-cli.py` (218 lines) | EXISTS | docstring `:1-40`; "Boundary (T-559): operates ONLY on 832's own store … Never invokes AEF tooling" `:26-28` | `tools/_bpmn-claim-cli-verify.py:26` (isolated temp repo) | `e2962376 2026-07-22` | Single caller is its own verifier probe. Reading: **D UNMEASURED** for operator use — the store shows 4 recorded claims (`.context/designer/registry.yaml`, `via: ui` ×?, `via: cli` ×?) but all 4 target `claim-smoke-*` projects, i.e. smoke fixtures, not real maps |
| Write-capable gallery/designer server | `tools/gallery-serve.py` | EXISTS | docstring `:2-7`; provides `/api/save`, `/api/list`, `/api/health`, `/api/version` | imported by `tools/_bpmn-claim-cli-verify.py:40`, `_gallery-claim-verify.py:26`, `_gallery-list-verify.py:33`, `_offpage-seam-parity-verify.py:19`; `tools/serve-gallery.sh` | `04c3366e 2026-09-07` | — |
| Clean-layout baker | `tools/bake-clean-layout.py` | EXISTS | docstring `:2-7` | (writes `examples/aef-processes/rendered/` — not run here) | `0fdd0e04 2026-08-17` | **UNVERIFIED** — not invoked in this pass by constraint |
| Dead-leg census | `tools/census-dead-legs.py` | EXISTS | docstring `:2-6` | `tests/test_dead_leg_census.py` | `a303c7cb 2026-07-29` | — |
| Rendered-corpus thumbnailer | `tools/gen-rendered-thumbs.mjs` | EXISTS | header `:1-5` | UNVERIFIED | `05d28d24 2026-08-26` | **D UNMEASURED** |

**Corpus size:** `examples/aef-processes/` holds 24 `*.workflow.yaml` + `rendered/` (25 files).

---

## 3. Write-out mode (T-201) — does a compile→`.tasks/` path exist today?

| Item | Location | Status | Evidence | Invoked by | Last change | Non-use readings |
|---|---|---|---|---|---|---|
| T-201 inception task | `.tasks/completed/T-201-write-out-mode-bpmn-compile-emits-real-t.md` | EXISTS, `status: work-completed`, `workflow_type: inception`, `owner: human` | — | — | `last_update: 2026-08-16` | — |
| T-201 **decision** | same file, `## Decision` | **GO**, recorded `2026-07-18T10:31:06Z`, "Approved via Watchtower (no rationale captured)" | Also in `## Updates` at `2026-07-18T10:31:06Z` | — | — | — |
| T-201 seam ruling (IW-2) | same file, Open Questions | disposition `answered`, confidence 3 | "false binary; **manifest-as-seam**. Content authority=832, gated-write=AEF via `fw bpmn promote`→`fw task create`" | — | — | — |
| T-201 reconcile rule (IW-3) | same file | `answered`, confidence 3 | keyed on `(uid, source_bpmn_sha)`: new→create / unchanged→no-op / changed→propose-not-clobber / deleted→orphan-and-flag | — | — | — |
| T-201 research artifact | `docs/reports/T-201-writeout-mode-inception.md` | EXISTS | listed by `ls docs/reports/` | — | UNVERIFIED (not git-logged this pass) | — |
| **What shipped on 832's side** | `tests/test_designer_export_contract.py` + task `T-202` | EXISTS, **PASSES** | `T-202` (`.tasks/completed/T-202-write-out-guard-designer-bpmn-export-car.md`) has all 4 Agent ACs `[x]`; run today: `PASS: designer export-contract guard — 8 owner-bearing node(s) each carry a non-empty aef:uid and a defined lane authority; uid/authority checks proven to have teeth; console OK` rc 0 | own `## Verification` line; the designer test harness | UNVERIFIED (file mtime Aug 2) | — |
| **A compile→`.tasks/` path, invocable from 832 today** | — | **ABSENT** | `fw bpmn compile <f>` → rc 1 `error: compiler not found at …/.agentic-framework/tools/bpmn_to_tasks.py`; `fw bpmn promote all` → `error: promoter not found at …/tools/bpmn_promote.py`; `ls .agentic-framework/tools/` → no such directory | — | — | **A BROKEN** (wrapper present, target file absent) **+ E NOT WANTED on this side** — `tests/test_promote_contract.py:6-11`: "T-559 is SYMMETRIC. 832 cannot run AEF's `fw bpmn compile`/`promote` … **There is no live end-to-end run from either side.**" |

**The exact command, if it existed, would be:**
`cd /opt/832-Workflow-designer && .agentic-framework/bin/fw bpmn compile --write <file.bpmn> && .agentic-framework/bin/fw bpmn promote all --write`
— documented in `.agentic-framework/agents/bpmn/bpmn.sh:14-24`. **Both halves fail at step 0 in this repo.**

**The manifest projection is implemented only inside a test.** `grep -rn 'def extract_manifest' tests/ tools/` yields exactly one definition:
`tests/test_promote_contract.py:137`. Its only other consumer is
`tests/test_two_lane_joint_contract.py`. There is **no shipped 832 tool** that projects a
`.bpmn` into the `{name, owner, workflow_type}` manifest the seam is defined on — the
projection exists as a test-local reimplementation of AEF's read.

---

## 4. T-209 — the producer-contract test

| Item | Location | Status | Evidence |
|---|---|---|---|
| T-209 task | `.tasks/active/T-209-832-side-compile-promote-create-producer.md` | **`status: started-work`, `owner: human`, `horizon: later`**, `workflow_type: test`, created `2026-07-19`, last_update `2026-08-23` | frontmatter |
| Agent ACs | same | **3 of 3 `[x]`** | `## Acceptance Criteria → ### Agent` |
| Human AC | same | **1 of 1 `[ ]` — unchecked** | `- [ ] [REVIEW] Decline AEF's offset-78 producer-contract proposal as already satisfied?` |
| The test T-209 proposed building | — | **was never built; DEFER recommended** | "**DEFER — do NOT build a new promote/manifest producer-contract test.** The contract is covered by T-206 + T-208." |
| The tests that DO cover it | `tests/test_promote_contract.py` (T-206), `tests/test_two_lane_joint_contract.py` (T-208) | **EXIST and PASS today** | ran both, rc 0 each, outputs in §0. Both report "uid totality + byte-determinism + teeth verified" |
| The third suite (option C, typed events) | `tests/test_typed_event_fixture_contract.py` (T-212) | **EXISTS and PASSES** | rc 0; pins `typed-events.bpmn` sha `5467071b3a39` + `boundary-events.bpmn` sha `37eec1b0f10a`; T-209 body records it was filed and closed `39f69bcb`, wired at `tests/run-bridge-tests.sh:203` |
| Blocker task on T-209's status | `.tasks/active/T-714-ra-018-ctl-029-t-209-has-all-agent-acs-t.md` | EXISTS, all 3 Agent ACs `[ ]` | Verbatim audit output quoted in the task: `[WARN] CTL-029: T-209 has all Agent ACs ticked but status='started-work' - completable, not closed` |
| Prior post-mortem on T-209's own reasoning | `.tasks/completed/T-470-t-209-offers-the-operator-two-different-.md` | EXISTS, completed | Addendum in T-209: "**Re-measuring the part you doubt is not the same as re-measuring the part that can expire.**" |

**Answer to the brief's question:** the test named in T-209 does not exist because it was
recommended *against*; the coverage it would have provided **exists and passes** under two
other names. T-209 is blocked on a single **human** ruling (decline a peer's proposal),
open since `2026-07-19` — **14 months** by the task's own dates.
Non-use reading for T-209 itself: **E NOT WANTED (positive recorded reason — declined as
redundant, re-measured 2026-08-10)**, held open by an unticked Human AC.

---

## 5. `fw designer`

| Item | Location | Status | Evidence | Invoked by | Last change | Non-use readings |
|---|---|---|---|---|---|---|
| `fw designer` verb | `.agentic-framework/bin/fw:4258-4260` → `.agentic-framework/agents/designer/designer.sh` | **EXISTS and runs** | `fw designer --help` rc 0; dispatch `designer) … exec "$AGENTS_DIR/designer/designer.sh" "$@"` | operator | agents dated Aug 2 | — |
| …its presence in `fw help` | `fw help` output | **ABSENT** | `fw help \| grep -niE 'designer\|bpmn'` matched **only** the trailing path lines (`Framework: …/.agentic-framework`, `Project: …`). Neither `designer` nor `bpmn` is listed as a command | — | — | **C UNDISCOVERABLE** — both verbs work but are absent from the only listing an operator would consult |
| Subcommands actually present | `designer.sh:332-336` | `status`, `path`, `sync`, `url`, `draft` | grep of the dispatch case | — | — | `--help` text advertises only `status`/`path`/`sync` — **`url` and `draft` are undocumented in the tool's own usage** |
| `fw designer status` here | — | EXISTS, reports green | `version: 0.8.0`, `sha256: cab3c751…`, `bytes: 903600`, `vendored at: vendor/designer/aef-workflow-designer-0.8.0.html`, `status: PRESENT ✓ (sha256 matches pin)` | — | — | — |
| **Pin currency** | `.agentic-framework/policy/designer-pin.yaml:20-22` vs `dist/MANIFEST.yaml` | **STALE by 4 minor versions** | pin `version: "0.8.0"`, `bytes: 903600`, `source_tag: designer-v0.8.0`; manifest `latest: "0.12.0"`, `bytes: 997254`, `released: 2026-09-20T16:51:03Z`, `src_commit: d31278fb…`, `supersedes: "0.11.0"`. Both `vendor/designer/aef-workflow-designer-0.8.0.html` and the pin are dated **Aug 2**; `dist/` holds 0.9.0, 0.10.0, 0.11.0, 0.12.0 cut since | — | pin file Aug 2; 0.12.0 cut **today** | **D UNMEASURED** — the drift check exists (`fw:1457-1483`) and would WARN, but its verdict here is "PRESENT ✓" because the *pin* moved with neither the artifact nor the release; the check compares vendored-vs-pin, not pin-vs-upstream-latest |
| `fw designer draft` | `designer.sh` `do_draft_new` | **PRESENT but inoperable in 832** | seeds a `spec_version: 1` YAML into `$PROJECT_ROOT/.context/designer/projects/$name`, but requires `"$PROJECT_ROOT/bin/fw" watchtower url` — and `ls bin/` in 832 → `No such file or directory` (framework is at `.agentic-framework/bin/fw`). Also requires a live `/api/list` at `http://localhost:3000` | — | — | **A BROKEN in this checkout** (hardcoded `$PROJECT_ROOT/bin/fw` path assumption) |
| `fw bpmn` verb | `.agentic-framework/bin/fw:4262-4264` | EXISTS (wrapper); compile+promote targets ABSENT (§3); `claim` routes to `web.designer_registry.claim_ghost` which **does** exist (`.agentic-framework/web/designer_registry.py`) | `fw bpmn claim` with no args → argument-count error, i.e. the route is live | — | — | see §3 |

---

## 6. Reverse direction (AEF record → editable process map)

| Item | Location | Status | Evidence | Invoked by | Last change | Non-use readings |
|---|---|---|---|---|---|---|
| T-184 "Child-3: Reverse discovery" | `.tasks/active/T-184-child-3-reverse-discovery-aef-record---e.md` | **DESIGNED-ONLY** — `status: captured`, `workflow_type: inception`, `owner: human`, `horizon: later` | Problem Statement, Assumptions, Exploration Plan, Scope Fence, Go/No-Go all **empty template comments**; 0 of 3 Agent ACs checked; `## Decision` unfilled | — | `last_update 2026-08-16` | **E NOT WANTED (for now), positively recorded**: `revisit_at: 2026-10-01`; `revisit_evidence_needed: "A concrete request (ours or AEF's) to render an existing AEF task record as an editable map"`; description records "DEFERRED by operator 2026-07-11". Recommendation block: `DEFER` — "No agent work has started … there is nothing to verify yet" |
| Reviewer verdict on T-184 | same file, `## Reviewer Verdict (v1.5)` | PASS, scan `R-3b001a2c`, `2026-07-29` | — | — | — | — |
| Parent decomposition doc | `docs/reports/T-175-child-decomposition.md` | referenced by T-184's description | **UNVERIFIED** — not opened in this pass | — | — | — |
| **Annotation seam v0** — the one reverse-flowing artifact that shipped | `src/aef-workflow-designer.html:2655-2740`; contract `docs/aef-designer-integration-protocol.md:125-168` | **EXISTS, PASSES** | `:2655` "T-258: annotation seam v0 (T-250 GO, shape A postMessage)"; handshake out at `:2680` `window.parent.postMessage(…)`; intake at `:2726-2730` `if (!d \|\| d.type !== 'aef:annotate') return;`. Test rc 0: "ready handshake, badge intake, display-only invariants, spoof rejection, wipe + doc-switch contracts" | `tests/test_t258_annotation_seam.py` → `tools/_t258-annotation-seam-cdp.mjs`; the live producer is AEF Watchtower `/api/overlay` (their side) | UNVERIFIED for the mjs; capability declared in `dist/MANIFEST.yaml` `capabilities: {annotation_seam: 1}` | — |
| …its scope limit | `docs/aef-designer-integration-protocol.md:160-162` | — | "**Read-only overlay: never serialized into BPMN, never in autosave, stripped from thumbnails, dropped on document switch.**" — AEF state reaches the map as **badges**, never as editable structure | — | — | This is the precise boundary between what shipped and what T-184 was about |
| Live AEF payload fixture | `tests/fixtures/aef-overlay/live-payload-2026-07-27.json`, `draft-knowledge-leveling-v3.bpmn` | EXISTS | `ls tests/fixtures/aef-overlay/` | `tools/_t258-annotation-seam-cdp.mjs` | 2026-07-27 payload | — |
| AEF-authored inbound BPMN fixtures | `tests/fixtures/aef-inbound/` — `README.md`, `t406-clean-leading-boilerplate.bpmn`, `t406-incidental-leading-boilerplate.bpmn`, `_t413-first-run.txt` | EXISTS | `ls` | `tools/_t406-doc-comment-provenance-cdp.mjs`, `tools/_t414-mutation-check.sh` | — | These prove AEF→832 **file** inbound is exercised; they are BPMN, not task records |
| An AEF **task record** → map renderer | — | **ABSENT** | no artifact found under `tools/`, `tests/`, `src/` that reads `.tasks/*.md` or an AEF task manifest and emits BPMN/YAML map structure | — | — | **B NEVER WIRED** — the inception that would authorise it (T-184) has never been run |
| `fw designer draft` as a partial reverse surface | §5 | PARTIAL / inoperable here | seeds a *blank* two-lane spec, not an AEF record | — | — | — |

---

## 7. Round-trip integrity

| Item | Location | Status | Evidence | In CI? | Last change | Non-use readings |
|---|---|---|---|---|---|---|
| Editor round-trip fixed point (parse→build) | `tests/test_roundtrip_serialization.py` → `tools/_roundtrip-serialization-cdp.mjs` | **EXISTS, PASSES** (ran headless chromium for real, not skipped) | rc 0; `"summary": "36 keys / 36 LIVE / 0 BLIND / 4 DRIFT-ELSEWHERE / 0 NOT-EXERCISABLE / 0 NEVER-PRESENT over 19 fixtures"`, `"proven_fraction": "36/36"`, controls `held: true`; `OK: round-trip serialization is a semantic fixed point across all aef-bpmn fixtures` | **NO** | `11a2dcc7 2026-07-11` | — |
| Bridge→editor cross-seam (no silent drop) | `tests/test_bridge_seam_roundtrip.py` → `tools/_bridge-seam-roundtrip-cdp.mjs` | **EXISTS, PASSES** | rc 0; self-test mangles the aef namespace URI and detects the drop: `"perturbable": true, "detectsDrop": true, "missingCount": 27, "total": 27`; `OK: bridge emissions survive editor import with no silent drop across all workflows` | **NO** | `0f4cde18 2026-07-11` | — |
| YAML→BPMN→validator-clean corpus contract | `tests/run-bridge-tests.sh:1-11` | EXISTS; **result UNVERIFIED this pass** | header: "This is the round-trip contract: canonical YAML → BPMN → validator-clean. Exit 0 iff all corpus files round-trip clean." 2211 lines | **NO** | `66e04cff 2026-09-09` | Not run — its own comments (`:2144-2147`) record that a leg has moved `.context/audits/` files, inside my prohibited write set |
| `aef.x-*` passthrough contract | `tests/test_bridge_aef_passthrough.py` | EXISTS | header `:1-11` (closes FC-13: "the bridge emitted only a hardcoded set of aef.* keys and silently dropped every other one") | **NO** | `4a1a30e1 2026-07-19` | not run this pass |
| Field-coverage parity (4 sibling guards) | `test_editor_bridge_field_coverage.py` (T-059, `6278aaee 2026-07-03`), `test_editor_bridge_meta_parity.py` (T-060, `0dda2c31 2026-08-20`), `test_editor_bridge_structured_parity.py` (T-063, `fd6f26a5 2026-07-04`), `test_editor_namespace_consistency.py` (T-044), `test_editor_extension_shape_consistency.py` (T-053) | EXIST | headers name the family explicitly: "namespace: T-044; shape: T-053; coverage: T-059; meta-parity: T-060; structured: this" | **NO** | as listed | not run this pass |
| Rule-form parity (YAML vs BPMN validator) | `tests/test_rule_form_parity.py` | EXISTS | header: "A rule present on one form and absent on the other means files on the unguarded form can sit in `fixtures/valid/` asserting a cleanliness nothing ever evaluated. T-317 found that the expensive way." | **NO** | `b2fb61c0 2026-08-02` | not run this pass |
| Doc-comment round-trip | `tests/test_t311_doc_comment_roundtrip.py` | EXISTS | `ls` | **NO** | UNVERIFIED | not run this pass |
| **CI** | `.onedev-buildspec.yml` (33 lines, full file read) | **ABSENT — there is no test job** | The file declares exactly **one** job, `Push to GitHub Mirror`, whose only step is `!PushRepository` to `github.com/DimitriGeelen/workflow-designer`. Triggers: `BranchUpdateTrigger` on `'**'`, `TagCreateTrigger` on `'**'`. No `!CommandStep`, no test invocation, no reference to `tests/` anywhere in the file | — | — | **B NEVER WIRED** — every round-trip guard in this repo runs only when a human or agent invokes it locally. Nothing in automation ever runs them. Corollary: the "green" of any suite above is a point-in-time local measurement, never a continuously enforced gate |

---

## 8. Non-use diagnosis summary (evidence only — no reading is selected)

| Item with no observed non-test use | A BROKEN | B NEVER WIRED | C UNDISCOVERABLE | D UNMEASURED | E NOT WANTED (recorded reason) |
|---|---|---|---|---|---|
| `fw bpmn compile` / `promote` (in 832) | ✔ target file absent, rc 1 | ✔ no caller | — | — | ✔ `test_promote_contract.py:6-11` T-559 symmetric boundary |
| `tools/yaml-to-bpmn.py` | — | ✔ tests-only | — | — | ✔ `tools/README.md:29-31` "Standalone by design (not wired into the vendored `fw` CLI)" |
| `tools/validate-workflow.py` | — | ✔ tests-only; `fw workflow validate` absent from `fw help` | — | — | ✔ same README note + `validate-workflow.py:29-31` |
| `fw designer` / `fw bpmn` verbs | — | — | ✔ neither appears in `fw help` | — | — |
| `fw designer draft` | ✔ `$PROJECT_ROOT/bin/fw` does not exist in 832 | — | ✔ undocumented in its own `--help` | — | — |
| designer pin 0.8.0 vs release 0.12.0 | — | — | — | ✔ drift check compares vendored-vs-pin only | — |
| `tools/bpmn-cli.py` | — | — | — | ✔ only `claim-smoke-*` entries in `.context/designer/registry.yaml` | — |
| Round-trip suites | — | ✔ no CI job exists | — | — | — |
| T-184 reverse discovery | — | ✔ never built | — | — | ✔ `revisit_at: 2026-10-01` + `revisit_evidence_needed` + operator DEFER 2026-07-11 |
| T-209 producer-contract test | — | — | — | — | ✔ DEFER, re-measured 2026-08-10, coverage proven by T-206+T-208 |
| Editor YAML export | — | ✔ no code path | — | — | — |

---

## 9. Data gaps (explicitly unverified)

1. `tests/run-bridge-tests.sh` — **not run** (write risk to `.context/audits/`, per its own `:2144-2147`). Its 94-leg pass/fail state today is unknown; last third-party report is `docs/reports/T-356-third-party-fidelity.md:109`.
2. `docs/reports/T-201-writeout-mode-inception.md` — exists, **not read**. The guardrail table G1–G6 and §3a/§3b are cited by T-201/T-202 but not independently checked here.
3. `docs/reports/T-175-child-decomposition.md` — **not read**.
4. `docs/designer/architecture.md` — **not read** (not needed for any row above).
5. Whether AEF's own checkout carries `tools/bpmn_to_tasks.py` / `bpmn_promote.py` — **unknowable from here** (T-559 boundary; I did not route around it).
6. Whether any human has ever run the file-download Save or `/api/save` against a real (non-`claim-smoke`, non-`t101-review`) map — `.context/designer/projects/` holds 6 entries, 5 of which are named `t101-review-*` / `t293-retest-*` / `claim-smoke-*`; only `audit-process` reads as a real map. Not conclusive.
7. `tools/gen-rendered-thumbs.mjs` and `tools/bake-clean-layout.py` invocation sites — **unverified** (both write into `examples/aef-processes/rendered/`, in my prohibited set).
8. Last-change dates given as "Aug 2" for several `.tasks/` and `.agentic-framework/` files are **filesystem mtimes**, not commit dates — the repo appears to have a bulk Aug 2 mtime floor.
