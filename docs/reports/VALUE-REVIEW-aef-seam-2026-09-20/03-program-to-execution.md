# G3 — Program → Execution

**Role:** GATHERER G3 · **Domain:** does anything actually RUN an authored workflow?
**Date:** 2026-09-20 · **Mode:** read-only evidence collection. No classification, no recommendations.
**Scope fence:** every read was inside `/opt/832-Workflow-designer`. No project-boundary hook block was hit.

Every status below is one of **EXISTS** / **PARTIAL** / **DESIGNED-ONLY** / **ABSENT**, and every one
carries command output, a `path:line`, or a record ID. A design document is never cited as proof that
something is built.

---

## 0. Headline table — the program→execution chain, component by component

| Component | Specified where | Status | Proof of status | Notes |
|---|---|---|---|---|
| `fw workflow run` executor | `README.md:15`; `docs/designer/README.md:42`; `docs/designer/schema.md:660,683`; `docs/reports/T-002-…:102` | **ABSENT** | `grep -nE '^\s*workflow\)' .agentic-framework/bin/fw` → exit 1, no match. `fw help` (exit 0, 7863-line script) lists 60+ verbs; `workflow` is not among them. | 16 files in the repo name it; zero implement it. Consistently marked "planned"/"out of scope" in all 16. |
| `fw bpmn compile` (BPMN → AEF task skeletons) | `.agentic-framework/bin/fw:4262-4265`; `agents/bpmn/AGENT.md` | **PARTIAL — wired, help works, execution BROKEN** | `fw bpmn --help` → exit 0, full usage text. `fw bpmn compile examples/aef-processes/rendered/task-gate.bpmn` → **exit 1**, stderr: `error: compiler not found at /opt/832-Workflow-designer/.agentic-framework/tools/bpmn_to_tasks.py`. `find . -name bpmn_to_tasks.py` → no match. `ls .agentic-framework/tools` → `No such file or directory`. | The only wired program→governed-work path in this tree, and it fails on first invocation. This compiles to *task proposals*, not execution. |
| `fw corpus` (spec-driven corpus authoring / lint / explain) | `.agentic-framework/bin/fw:4266-4281` | **ABSENT (dispatch exists, target missing)** | `fw corpus --help` → **exit 2**, `python3: can't open file '…/.agentic-framework/tools/corpus_spec.py'`. `fw corpus lint --help` → **exit 2**, same for `corpus_lint.py`. | Same root cause: `.agentic-framework/tools/` was never vendored. |
| `fw designer` (vendor + serve pinned build) | `.agentic-framework/bin/fw:4258-4261` | **EXISTS** | `fw designer help` → exit 0, prints verbs `status` / `path` / … | Serves the artifact; does not run a workflow. |
| EWCR runtime (procedure registry, validator, ledger, fold, router, instance state machine, dispatcher, adapters) | `docs/research/executable-workflow/architecture-c9070637.md` §§6–7 | **DESIGNED-ONLY** | Dossier self-labels: `:3` "working architecture dossier — **exploration, not implementation authorisation**"; `:19` "Proposed architecture vocabulary in this dossier, **not shipped AEF primitives**"; `:426` "Illustrative—not settled—node/edge contract"; `:481` "# Illustrative contract, not a shipped file format". | See §2 for the full per-component status list. |
| Per-node execution traces / run records | expected by dossier §7.3 (append-only ledger), §7.5 (per-node sequence) | **ABSENT** | See §4. `grep -rl n_attempt .` returns only authoring artifacts. No `*trace*`/`*ledger*`/`*instance*`/`*attempt*` file exists outside vendored AEF docs. | Expected data gap; recorded as such. |
| Execution authority inside this repo | Arc-2 clause, `roadmap-5be23719.md:66` | **ABSENT — and measured as absent by the project itself** | `docs/reports/T-682-arc-2-boundary-inventory.md:23` "Execution authority — ABSENT FROM THE REQUEST SURFACE"; `:33` "no request path reaches an execution primitive, and no execution primitive takes request-derived [input]"; `:40-44` secret authority: patterns `secret/password/token/credential/api_key/apikey/private_key` → "**Zero matches**". | T-682 `work-completed`, `arc_id: ewcr-governed-delivery`. |
| `aef:endpoint` (node → skill/command binding) | `docs/designer/schema.md:239` "what executes this step" | **EXISTS as carried text; ABSENT as a binding** | `docs/standards/aef-bpmn-mapping-v1.md:42` classifies `aef:endpoint` as **Presentational (diagram cosmetics)** — "MUST treat them as derived, never authoritative… A change to a presentational attribute alone MUST be a no-op for the task graph." `grep -c tier tools/validate-workflow.py` → 0; the 4 `endpoint` hits in that file are edge `source`/`target`, not `aef:endpoint`. | Direct contradiction between two docs in this repo. See §5. |
| `aef:meta@tier` (per-node authority tier) | mapping-v1 §2 frozen governance meta-keys (`horizon`, `workflowType`, `tier`, `agentType`) | **EXISTS as carried data; nothing enforces it** | 77 occurrences across 15 of 25 rendered maps (values `1`×54, `2`×13, `0`×10). `grep -c '\btier\b' tools/validate-workflow.py` → **0**. | See §6. |
| `aef:laneMeta@authority` | mapping-v1 §3 (lane = sole authority-of-record) | **EXISTS and IS enforced — at validation time only** | `tools/validate-workflow.py:61-62` `AUTHORITIES = {sovereignty, authority, initiative, external, none}`; `:113` `REQUIRED_LANE_FIELDS`; `:331,818-857` `_check_iw9_authority` (lane authority → task owner, disagreement is a violation). | Enforced against the *document*, never against a *run*. See §6. |
| `_t681-s2-mutation-control-prototype.py` | `docs/research/executable-workflow/` | **EXISTS — NOT RUN by G3 (would write inside the repo)** | `:34` `ROOT = os.path.join(HERE, "s2-root")` where `HERE` is the repo docs dir; `:63` `shutil.rmtree(ROOT, ignore_errors=True)`; `:64-66` `makedirs` + `copy2`. | See §7 for a full read-only analysis and a static liveness check. |
| Arc-0 component set (28 files) | `arc-0-component-set.txt` | **EXISTS — all 28 present** | Existence loop over the manifest: `PRESENT=28 ABSENT=0`. | Every member is an authoring/validation artifact. None is a runtime. See §3. |
| Arc-0 exit clauses 1/2/3 | `arc-0-exit-clauses.yaml` | **UNRATIFIED (all three)** | Parsed: clause-1 `owner: aef, definition_ratified: False, attestation: None`; clause-2 same; clause-3 `owner: shared, definition_ratified: False`. | |
| Consolidated refusal/threat matrix (Arc-0 candidate task 3) | `roadmap-5be23719.md:139-141,358` | **ABSENT — absence is mechanically asserted** | T-597's own P-011 leg, re-run by G3: `python3 -c "import glob;m=[f for f in glob.glob('docs/**/*.md',recursive=True)+glob.glob('docs/**/*.yaml',recursive=True) if 'refusal-matrix' in f or 'threat-matrix' in f];assert not m,m"` → **PASS** (exit 0). | `docs/reports/T-732-h-register-dossier.md:20`: "Artifact does not exist in this repository and was never the Designer side's to build." |
| Architecture source doc cited by the roadmap | `roadmap-5be23719.md:4` → `docs/architecture/executable-workflow-contract-runtime.md` | **ABSENT in this repo** | `ls docs/architecture/` → `No such file or directory`. `find . -name executable-workflow-contract-runtime.md` → no match. | The roadmap's own "Architecture source" is a dangling path here. Its content survives as `architecture-c9070637.md` (a copy under `docs/research/executable-workflow/`). |

---

## 1. `fw workflow run` — exact determination

**Command run (vendored fw, v1.6.354):**

```
$ .agentic-framework/bin/fw help          # exit 0
$ grep -nE '^\s*workflow\)' .agentic-framework/bin/fw   # exit 1 — NO MATCH
$ grep -n -i workflow .agentic-framework/bin/fw | wc -l # 30 matches, ZERO of them a verb
```

All 30 `workflow` matches in `bin/fw` fall into three groups, none of which is a `workflow` verb:

1. `workflow_type` — the **task** frontmatter field (`:2598, :2628, :2677, :2729`).
2. `.context/project/workflows/*.yaml` — the **orchestrator v1 dispatch** workflow format, an unrelated
   concept (`:1764-1805, :2301-2345`). `ls .context/project/workflows/` → **`No such file or directory`**;
   `fw doctor` would print `INFO  No .context/project/workflows/ — orchestrator v1 not yet provisioned` (`:2330`).
3. Prose/comments (`:668` inception help line, `:1459` vendored-build comment, `:4418`, `:4581-4904`
   `workflow_resolved_via` dispatch filter).

**The near-miss verbs.** The `bin/fw` case statement has 100 top-level verbs. Four are BPMN/workflow-adjacent
and **none of them is in `fw help`**:

| Verb | `bin/fw` line | In `fw help`? | Live result |
|---|---|---|---|
| `bpmn` | 4262 | **no** | `--help` exit 0; `compile` **exit 1**, compiler file missing |
| `corpus` | 4266 | **no** | **exit 2**, `corpus_spec.py` missing |
| `designer` | 4258 | **no** | `help` exit 0 |
| `arc` | 3685 | **no** | `list`/`show` exit 0, work fine |
| `bvp` | 3693 | **no** | (not exercised — mutating verbs excluded by brief) |
| `orchestrator` | 4383 | **no** | (not exercised) |
| `workflow` | — | — | **does not exist** |
| `fabric` | 4255 | yes | — |

`fw review` (referenced by `review-emission.bpmn`) →
`Unknown command: review`, **exit 1**.

**README claim check.** `README.md:15` — "usable today without the planned `fw workflow run` executor" — is
**accurate**: the executor is absent, and the repo consistently labels it planned/out-of-scope in all 16
places it is named (`tools/validate-workflow.py:16` "explicitly out of scope (T-002 scope fence)";
`docs/reports/T-020-…:79` "**placeholder only** — no execution; a documented 'run boundary'").

---

## 2. EWCR (arc-002) — every named component, statused

Sources: `roadmap-5be23719.md` (393 ll.), `architecture-c9070637.md` (1008 ll.).

### 2a. What the runtime is SPECIFIED to do

`architecture-c9070637.md:24-28` (Definition): "a **proposed**, AEF-integrated control plane that turns a
ratified workflow procedure into a task-bound workflow instance. It coordinates human and agent work by
allowing only policy-validated transitions, executing only bounded approved action types, materialising and
validating the delivery artefacts between steps, and recording redacted, durable evidence for every attempt
and decision."

Success criterion (`:44-52`): "A successful command alone is not success; bypassing a control must be
demonstrably impossible at the runner boundary. The pilot runner must therefore **execute outside the
agent's OS identity** through an authenticated interface with runner-owned append-only state."

### 2b. What "executable contract" means concretely

Four things, per the dossier:

1. **A ratified, content-hashed, immutable procedure version** (`:188` "Once ratified it is immutable…
   This prevents a running agent from editing the procedure that limits its own authority"; `:691`
   "Ratified definitions are immutable and content-hashed").
2. **A node that names an action-catalogue reference, never a shell string** (`:476-478`, illustrative YAML
   at `:480-490`: `action: project.verified_test_suite`, `implementation.path` + `content_hash`,
   `invocation.argv` structured, `cwd: selected_worktree`).
3. **Typed I/O with a constrained guard language** (`:448-455` `edge: required_outputs, guard:
   output.test_report.status == "passed"`; `:455` "The guard language must be constrained, typed,
   deterministic, and auditable; it must never be arbitrary code").
4. **An append-only ledger where current state is a deterministic fold** (`:713-722`).

Against that definition, the repo's own gap register `cannot-represent-yet.md:66-79` marks **every**
§6.2.1 field as carrier **"none"** in the frozen surface: `action:`, `implementation.path`+`content_hash`,
`interpreter`, `invocation.argv`, `invocation.cwd`, `invocation.environment`, typed `inputs:`/`outputs:`,
`controls.capability_profile` ("none, and **must not**"), `controls.timeout_seconds`,
`controls.idempotency` ("presupposes an *instance*, which we do not model"), `controls.retry`,
`controls.output_redaction_profile` ("none, and **must not**").

### 2c. The refusal matrix

Two distinct things share the name and must not be conflated:

| Thing | Where | Status |
|---|---|---|
| **The consolidated refusal/threat matrix artifact** (Arc-0 candidate task 3, roadmap `:139-141`; fence row `:358`) | should be a file | **ABSENT.** Mechanically asserted by T-597's P-011 leg (re-run by G3: PASS). `roadmap-5be23719.md:64` assigns it to the **AEF column**, not the Designer column. |
| **The 20 initial acceptance scenarios** (`architecture-c9070637.md:909-930`) — the de-facto refusal specification | prose in the dossier | **DESIGNED-ONLY.** No test, tool or script in this repo references them as a suite. |

The 20 scenarios, condensed (each is a refusal that must be provable): unratified procedure cannot
instantiate · unresolved action/profile refs refused pre-dispatch · human gate unskippable · registered
script cannot run from another worktree · missing typed input blocks advance · unmeasured component scope
routes to policy not zero-impact · duplicate remote result is idempotent · unsupported provider capability
refuses rather than substitutes · resume uses durable envelope · completed instance renders a visual trace
· agent-user edits cannot mutate instance state · shared-host identity alone is refused as ambiguous ·
bound-task mutation between gates forces revalidation · hub-delivered-but-never-enumerated reply becomes
operator-visible · ratification-to-attempt drift has its own refusal route · `--force`-equivalents cannot
bypass the runner · deadlines survive restart and cannot double-fire · cancellation blocks later advance ·
racing proposals admit exactly one · Watchtower cannot mutate state directly.

Additional refusal semantics: attempt outcomes are `succeeded | failed | timed_out | cancelled | refused`
(`:727`), and "**a refusal means preflight or policy denied execution before side effect**" (`:728-729`).

### 2d. Every named component of the design, statused

From the end-state architecture block (`architecture-c9070637.md:393-408`), the node vocabulary
(`:459-470`), the state machine (`:702-711`), the lifecycle diagrams (`:685-698`) and the fabric section
(`:778-813`):

| Plane | Named component | Status | Proof |
|---|---|---|---|
| Authoring/operator | Designer | **EXISTS** | `src/aef-workflow-designer.html` present; 25 rendered BPMN maps under `examples/*/rendered/` |
| Authoring/operator | procedure catalogue | **ABSENT** | no catalogue file/verb; `fw help` has none; `.context/` has none |
| Authoring/operator | visual live-instance view | **ABSENT** | no instance model exists to view (`cannot-represent-yet.md:77` "presupposes an *instance*, which we do not model") |
| Authoring/operator | review | **EXISTS (task review, not workflow review)** | `fw task review T-XXX` at `bin/fw:3094`; `fw review-queue` in `fw help` |
| Governance control | validator | **PARTIAL** | `tools/validate-workflow.py` (1773 ll.) validates **document** schema/lane-authority/IW-9. It does **not** validate ratification, action refs, profiles, or tier (`grep -c '\btier\b'` → 0) |
| Governance control | ratification registry | **ABSENT** | no registry file, no `ratified` field in any `.bpmn`/`.workflow.yaml` (`aef:workflowMeta` attrs are only `id, uuid, version, schemaVersion, title, tier_default, pageWidth`) |
| Governance control | router | **ABSENT** | no router artifact; `roadmap:292-321` Arc 6 |
| Governance control | policy decision | **ABSENT** | — |
| Governance control | task binding (task ↔ instance stable IDs) | **ABSENT** | no instance IDs exist anywhere; see §4 |
| Governance control | profile resolver | **ABSENT** | `cannot-represent-yet.md:75` capability_profile carrier "none, and **must not**" |
| Governance control | audit/evidence writer | **ABSENT** | see §4 |
| Runtime data | instance state machine (`created→preflighted→ready→running→waiting/paused/failed→compensating→completed/cancelled`, `:705-710`) | **ABSENT** | no code implements any of these states |
| Runtime data | dispatcher | **ABSENT** | — |
| Runtime data | provider adapters | **ABSENT** | — |
| Runtime data | workers | **ABSENT** | — |
| Runtime data | human-gate notifier | **PARTIAL (AEF substrate, not workflow-bound)** | `fw approvals` + `web/blueprints/approvals.py:540` `/api/approvals/decide` exist, but are bound to **tasks**, not workflow nodes |
| Runtime data | wait/event listener | **ABSENT** | `cannot-represent-yet.md:50` — event *kind* + *binding* are carried; "Absent: a **timeout**, a **correlation source**, and any notion of the event *resuming an instance* — because we have no instance" |
| Runtime data | retry/compensation | **ABSENT** | `cannot-represent-yet.md:52` "G-2h — absent entirely" |
| Node vocab (`:459-470`) | human gate | **PARTIAL** | `userTask` in sovereignty lane exists; `cannot-represent-yet.md:44` "G-1 — the decision mapping itself… No carrier for the admissible decision options, the mapping from option to route, or the 'cannot auto-advance' property" |
| Node vocab | script | **PARTIAL** | `scriptTask` exists; "G-2 — everything that makes it *registered*… six named absences" (`:45`) |
| Node vocab | command | **ABSENT** | "G-2b — no node kind, and no way to distinguish `script` from `command`" (`:46`) |
| Node vocab | agent prompt | **PARTIAL** | `serviceTask` + `agentType` ∈ {primary, termlink-worker, human}; "G-2c — no versioned prompt reference, no resolved profile, no outcome check" (`:47`) |
| Node vocab | service | **PARTIAL** | `serviceTask`; "G-2d — no connector type, no redaction profile, no idempotency rule, no retry policy" (`:48`) |
| Node vocab | call workflow | **ABSENT** | "`callActivity` is **absent from the editor entirely**" (`:49`); `T-282 DEFER`, still `status: captured` |
| Node vocab | wait event | **PARTIAL** | "the closest thing on this whole page to a runtime hook" (`:50`) |
| Node vocab | gateway | **PARTIAL** | `exclusiveGateway`/`parallelGateway` exist; "G-2g — **the condition is a *label*, not a predicate**… A label is none of those [typed/deterministic/auditable]" (`:51`) |
| Node vocab | compensate | **ABSENT** | "G-2h — absent entirely" (`:52`) |
| Fabrics | Context Fabric | **EXISTS (AEF substrate)** | `.context/project/{decisions,learnings,patterns,assumptions,practices}.yaml` all present |
| Fabrics | Component Fabric | **EXISTS (AEF substrate)** | `.fabric/components/` = 378 cards; `.fabric/watch-patterns.yaml` |
| Fabrics | **Workflow Fabric** (process-topology join, `:792-806`) | **ABSENT** | `T-280` "Workflow Fabric (SD-15)… revive or retire" — `fw inception status`: `captured / pending` |
| Fabrics | BVP | **EXISTS (AEF substrate)** | `fw bvp` verb at `bin/fw:3693`; `policy/` present |
| Fabrics | TermLink | **EXISTS (AEF substrate)** | `fw termlink` verb; `tests/fixtures/termlink-attribution/*.jsonl` |
| Fabrics | Watchtower | **EXISTS (AEF substrate)** | 30 blueprints under `.agentic-framework/web/blueprints/`; live port in `.context/working/watchtower.{pid,port,url}` |

### 2e. "Which parts have any implementation"

Exactly three, and none of them executes a workflow:

1. **The authoring/validation surface** — the editor, `tools/yaml-to-bpmn.py`, `tools/validate-workflow.py`,
   `tools/bpmn-cli.py`, 24 contract tests. (Arc-0 set, §3.)
2. **The Arc-2 Designer-owned isolation proof** — `tools/_t682-boundary-inventory.py`,
   `tools/_t683-save-containment-verify.py`, `tools/_t684-mutation-control.py`. This proves the editor
   **cannot** reach execution authority; it is a negative result, not a runtime.
3. **The Arc-0 fabric fence** — `tools/_t671-arc0-fabric-fence.py`, `_t671-arc0-edge-derive.py`,
   `_t623-fabric-denominator-scope-probe.py`.

Everything in the control plane and data plane is DESIGNED-ONLY.

---

## 3. `arc-0-component-set.md` / `.txt` — per-component existence

`arc-0-component-set.txt` is the machine-readable manifest (28 lines). Existence loop over every line:

**`PRESENT=28  ABSENT=0`** — no component in the Arc-0 set is missing.

| Group | Count | Members | Status |
|---|---:|---|---|
| The product | 1 | `src/aef-workflow-designer.html` | **EXISTS** |
| Mapping/export/diagnostic tooling | 3 | `tools/yaml-to-bpmn.py`, `tools/validate-workflow.py`, `tools/bpmn-cli.py` | **EXISTS** (all 3) |
| Contract and round-trip suites | 24 | `tests/run-bridge-tests.sh`, `tests/run-validator-tests.sh`, and 22 `tests/test_*.py` (`test_bridge_aef_passthrough`, `test_bridge_seam_roundtrip`, `test_corpus_fixture_pins`, `test_designer_export_contract`, `test_editor_bridge_field_coverage`, `test_editor_bridge_meta_parity`, `test_editor_bridge_structured_parity`, `test_editor_extension_shape_consistency`, `test_editor_namespace_consistency`, `test_finding_anchorability`, `test_forward_fixtures`, `test_mapping_standard_conformance`, `test_roundtrip_serialization`, `test_rule_dialect_axis`, `test_rule_form_parity`, `test_t259_eventdef_preservation`, `test_t311_doc_comment_roundtrip`, `test_two_lane_joint_contract`, `test_typed_event_fixture_contract`, `test_typed_events`, `test_validate_iw9`, `test_xml_node_type_vocab`) | **EXISTS** (all 24) |

**The fact that matters for this domain:** the Arc-0 set contains **zero runtime components, by design.**
`arc-0-component-set.md:36` — "Runtime schemas, registries, ledgers and refusal matrices are **AEF-owned**
and deliberately excluded; that is the ownership boundary, not a gap." The set is 1 editor + 3 mapping
tools + 24 tests. Nothing in it can run a workflow, and nothing in it was ever intended to.

Measured coverage recorded in the same document (`:76-79`, `:115-116`): Arc-0 members with a *complete*
component card at the time of writing = **0 of 28**; whole-tree fabric = "102 registered, 259 unregistered
(of 358 watched — 28% covered)", "46/102 cards have no edges". Current card count: `ls .fabric/components/`
→ **378**.

---

## 4. Execution traces — EXPECTED DATA GAP, CONFIRMED ABSENT

**There is no per-node execution record of any kind anywhere in this repository.** Stated explicitly, as
instructed, because this is an expected gap and the absence is itself the finding.

Searches run (all excluding `.git/`):

| Search | Result |
|---|---|
| `find . \( -iname '*trace*' -o -iname '*ledger*' -o -iname '*instance*' -o -iname '*attempt*' -o -iname '*run-record*' -o -iname '*runlog*' \)` | 11 hits, **all** inside `.agentic-framework/` vendored AEF docs/tests (`11-git-traceability.md`, `T-1709-aef-review-instance.md`, `resolver-trace.txt`, `node_modules/@types/node/trace_events.d.ts`) plus `.tasks/completed/T-064-map-git-commit-traceability-flow…`. Zero workflow execution records. |
| `grep -rl n_attempt .` (a real node uid from `task-gate.bpmn`) | 6 files, **all authoring artifacts**: `.editor-versions/task-gate/v{1,2,3}.bpmn`, `examples/aef-processes/rendered/task-gate.bpmn`, `examples/aef-processes/task-gate.workflow.yaml`, `build/gallery/rendered/task-gate.bpmn`. No file pairs a node uid with a result. |
| `find . -name '*.jsonl'` | 6 files, none an execution trace: `.context/working/continuous-run.jsonl` (4 lines — the `claude-fw` **session wrapper** restart log: `{"ts":…,"event":"start","reason":"armed","restart_count":0,"wrapper_pid":2964…}`), `.context/audits/t696-voi-recurrence.jsonl`, `.context/bvp-driver-proposals.jsonl`, `tests/fixtures/termlink-attribution/*.jsonl` (2 test fixtures), `.agentic-framework/docs/reports/arc-010-hm-a-demo-005-transcript.jsonl` (vendored AEF demo). |
| `.context/` tree inventory | `approvals arcs audits bvp-driver-proposals.jsonl bvp-weight-history.yaml bypass-log.yaml cron cron-registry.yaml designer episodic handovers inbox.yaml locks project sessions settings.yaml working` — **no** `runs/`, `instances/`, `traces/`, `ledger/`. |
| `.context/designer/` | `projects/` (7 dirs) + `registry.yaml` — **authoring** project registry, not runs. |
| `.editor-versions/` | per-map `v1..vN.bpmn` + `.png` + `index.json` — **authoring version history**, not execution. |
| `tools/` | 300+ `_tNNN-*` probes; none emits a node-level run record. |
| `docs/` | no run artifacts. |

**Nothing anywhere records a node uid + pass/fail + time + cost.** The dossier requires exactly that
(`architecture-c9070637.md:713-716` "Every transition is an immutable envelope in the runner-owned
append-only event ledger: per-agent authenticated identity, timestamps, source/target state, node/edge,
reason, bound-task content hash, materialised input/output references, correlation IDs, and the prior
accepted ledger position/hash"). Nothing implements it.

Corroborating primary record: `docs/reports/T-682-arc-2-boundary-inventory.md:23,33` — execution authority
is **ABSENT from the request surface**; "no request path reaches an execution primitive, and no execution
primitive takes request-derived [input]".

---

## 5. `aef:endpoint` — the endpoints-pointing-at-nothing check

### 5a. Syntax, census, and the governing contradiction

`aef:endpoint` is a **child element** (`<aef:endpoint>text</aef:endpoint>`) inside a node's
`<bpmn:extensionElements>`, **not** an attribute. (`grep -c 'aef:endpoint='` on the rendered corpus → **0**
for every file; the attribute form does not exist.)

Census over `examples/aef-processes/rendered/*.bpmn` (24) + `examples/app-processes/rendered/*.bpmn` (1):

- **108** `aef:endpoint` elements, **107 distinct values**, across **23 of 25** files.
- The two files with none: `task-lifecycle.bpmn`, and one other (the census counts 23/25 carriers).
- For scale: the same corpus carries **641** `aef:uid`, 314 `aef:position`, 206 `aef:meta`, 71 `aef:laneMeta`.

**The contradiction, in this repo, between two of its own documents:**

| Document | What it says about `aef:endpoint` |
|---|---|
| `docs/designer/schema.md:239` | "**`endpoint`** — **what executes this step.** Format depends on the task type: `serviceTask`: agent prompt path … or framework command …; `userTask`: watchtower view URL …; `scriptTask`: framework command …" |
| `docs/standards/aef-bpmn-mapping-v1.md:42` (Part I — **Frozen v1**, §1 "This partition is **normative**") | "**Presentational (diagram cosmetics):** `aef:position`, `aef:anchors`, **`aef:endpoint`**, `aef:waypoint`, `aef:routing`, … The reverse compile MAY write these (layout) but **MUST treat them as derived, never authoritative. A change to a presentational attribute alone MUST be a no-op for the task graph.**" |

`aef:endpoint` is the **only** entry in that presentational list that is not a geometry/layout datum. The
frozen standard also states (`:36-37`) that "The forward compile MUST read **only**" the semantic class —
so by the ratified standard, a compiler is **forbidden** from reading `aef:endpoint`.

**Consistent with that, nothing validates endpoint content:**

- `tools/validate-workflow.py` — 4 `endpoint` matches, all at `:444-451`, and all are edge
  `source`/`target` refs, not `aef:endpoint`. **Zero** validation of `aef:endpoint`.
- `tools/yaml-to-bpmn.py:56` — `META_KEYS = ("determinism", "tier", "authority", "endpoint", …)` —
  **carriage only** (YAML↔BPMN passthrough), no resolution.
- `tools/bpmn-cli.py` — 0 matches.
- `src/aef-workflow-designer.html` — the only `endpoint` matches are CSS classes
  (`.edge-handle-endpoint-hit`, `:619-621`), i.e. edge-handle geometry.

### 5b. Resolution quality caveat (read this before the table)

"Resolves?" below means *a target with that name exists in this tree*. It does **not** mean the endpoint is
machine-resolvable. Of the **63** script-path endpoints:

| Anchor from which the written path resolves | Count |
|---|---:|
| Literal, from repo root | **2** |
| Framework-relative (`.agentic-framework/<path>`) | **13** |
| **Bare filename — resolves from no anchor at all; found only by repo-wide basename search** | **48** |

Examples of the 48: `commit.sh:113`, `resume.sh:147`, `update-task.sh:949-1027`, `traverse.sh:159-173`,
`lib/diagnose.sh:157-204`, `AGENT.md:33-37`. 13 of the 14 distinct bare filenames are unique under
`.agentic-framework/` (so a human can find them); **`AGENT.md` is ambiguous across 15 candidate files**
(`agents/{audit,bpmn,context,dispatch,git,gpu-recover,handover,healing,onboarding-test,resume,session-capture,task-create,termlink,termlink/bvp-estimator,ux-review}/AGENT.md`)
and appears in 5 endpoints with no disambiguator.

A second caveat: many endpoint values are **line-range pointers** (`commit.sh:113`,
`update-task.sh:1907-1996`). `.tasks/completed/T-298` records the failure mode in this exact corpus:
"five corrections: classify L113→L23 + lookup L147→L55 (older-vendor drift; RCA: **function-start pointers
drift**, menu-block pointers survived — cite names/blocks not line starts)". G3 verified file existence,
**not** that any cited line range still contains what the endpoint claims.

### 5c. Summary counts

| | Count |
|---|---:|
| `aef:endpoint` occurrences | 108 |
| Distinct values | 107 |
| Resolves **YES** | **98** |
| Resolves **NO** | **9** |
| Resolves **UNKNOWN** | **0** |

Kind breakdown: script-path 63 · fw-command 33 · prose 7 · watchtower-route 4 · env-var 1.

The 9 NO, in full:

| Value | Workflow | Why NO |
|---|---|---|
| `fw review` | `review-emission` | `fw review` → `Unknown command: review`, exit 1. No `review)` verb in `bin/fw`. (`review-queue`, `reviewer`, `ux-review`, `task review` exist; bare `review` does not.) |
| `git agent commit -m "<task>: Checkpoint handover"` | `session-handover` | `git agent` is not a command; the real form is `fw git commit` / `agents/git/git.sh commit` |
| `type-specific suggestions (diagnose.sh:164-195)` | `error-escalation-ladder` | free prose with an embedded pointer |
| `add automated check; update audit agent (diagnose.sh:197-199)` | `error-escalation-ladder` | free prose |
| `new practice / protocol in CLAUDE.md (diagnose.sh:201-203)` | `error-escalation-ladder` | free prose |
| `edit .tasks/active/T-XXX (replace placeholder ACs)` | `task-gate` | free prose (imperative, not a target) |
| `cp <target> <target>.bak-$(date +%s)` | `upgrade-process` | free prose / shell template with an unbound `<target>` |
| `restore <target> from <target>.bak-<ts>` | `upgrade-process` | free prose |
| `check AC boxes / repair` | `verification-gate` | free prose |

All four watchtower-route endpoints **do** resolve (they were the plausible "pointing at nothing"
candidates and they are not): `arcs.py:1253` `/arcs/<arc_id>/close`, `inception.py:313`
`/inception/<task_id>` (×2), `approvals.py:540` `POST /api/approvals/decide`. The env-var endpoint
resolves too: `agents/context/check-active-task.sh:24` (`FW_SAFE_MODE`) and `:410` (`FW_SWITCH_FOCUS`).

### 5d. Full endpoint-resolution table (107 distinct values)

| # | `aef:endpoint` value | Kind | Resolves? | What it resolves to (proof) | Occurs in workflow/node-uid |
|---:|---|---|---|---|---|
| 1 | `.agentic-framework/lib/inception.sh:_inject_recommendation_block` | script-path | **YES** | `.agentic-framework/lib/inception.sh` [repo-root] | inception-lifecycle/n_reco01 |
| 2 | `.context/working/.gate-bypass-log.yaml` | script-path | **YES** | `.context/working/.gate-bypass-log.yaml` [repo-root] | task-gate/n_log |
| 3 | `AGENT.md:17-37 (category table + checklist scan lines)` | script-path | **YES** | `.agentic-framework/agents/audit/AGENT.md (+14 more)` [basename-only] | session-capture/n_scan |
| 4 | `AGENT.md:33-37` | script-path | **YES** | `.agentic-framework/agents/audit/AGENT.md (+14 more)` [basename-only] | session-capture/g_found |
| 5 | `AGENT.md:38-40 (checklist capture lines)` | script-path | **YES** | `.agentic-framework/agents/audit/AGENT.md (+14 more)` [basename-only] | session-capture/n_capture |
| 6 | `AGENT.md:41-42 (fw note list — promote or dismiss; fw note for new observations)` | script-path | **YES** | `.agentic-framework/agents/audit/AGENT.md (+14 more)` [basename-only] | session-capture/n_inbox |
| 7 | `AGENT.md:54-61 (Output section)` | script-path | **YES** | `.agentic-framework/agents/audit/AGENT.md (+14 more)` [basename-only] | session-capture/n_report |
| 8 | `FW_SWITCH_FOCUS=1 / FW_SAFE_MODE=1` | env-var | **YES** | `agents/context/check-active-task.sh:24` (FW_SAFE_MODE), `:410` (FW_SWITCH_FOCUS) | task-gate/n_override |
| 9 | `POST /api/approvals/decide (Watchtower)` | watchtower-route | **YES** | `.agentic-framework/web/blueprints/approvals.py:540` | tier0-escalation/n_record_reject |
| 10 | `Watchtower /inception/T-XXX  \|  fw inception decide` | watchtower-route | **YES** | `.agentic-framework/web/blueprints/inception.py:313` | inception-review/n_review |
| 11 | `add automated check; update audit agent (diagnose.sh:197-199)` | prose | **NO** | free text — no resolvable target | error-escalation-ladder/n_c |
| 12 | `agents/context/check-active-task.sh` | script-path | **YES** | `.agentic-framework/agents/context/check-active-task.sh` [fw-rel] | task-gate/n_intercept |
| 13 | `agents/context/check-tier0.sh` | script-path | **YES** | `.agentic-framework/agents/context/check-tier0.sh` [fw-rel] | tier0-escalation/n_intercept |
| 14 | `agents/healing/lib/diagnose.sh:23-204` | script-path | **YES** | `.agentic-framework/agents/healing/lib/diagnose.sh` [fw-rel] | error-escalation-ladder/n_diagnose |
| 15 | `agents/healing/lib/resolve.sh (log) + lib/promote.sh / lib/harvest.sh (graduate 3+ apps)` | script-path | **YES** | `.agentic-framework/agents/healing/lib/resolve.sh` [fw-rel] | error-escalation-ladder/n_capture |
| 16 | `agents/task-create/create-task.sh` | script-path | **YES** | `.agentic-framework/agents/task-create/create-task.sh` [fw-rel] | task-lifecycle/n_file |
| 17 | `agents/task-create/create-task.sh --type inception` | script-path | **YES** | `.agentic-framework/agents/task-create/create-task.sh` [fw-rel] | inception-lifecycle/n_crea01 |
| 18 | `bypass.sh:76-113 (log_bypass_entry)` | script-path | **YES** | `.agentic-framework/agents/git/lib/bypass.sh` [basename-only] | git-commit-flow/n_logbypass |
| 19 | `check AC boxes / repair` | prose | **NO** | free text — no resolvable target | verification-gate/n_remediate |
| 20 | `commit.sh:113 (git commit -m … "${git_args[@]}")` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/n_commit |
| 21 | `commit.sh:66 ($bypass == true)` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/g_bypass |
| 22 | `commit.sh:67-76 (prompt if empty; empty → ERROR exit 1)` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/n_reason |
| 23 | `commit.sh:78-79 (git commit -m … ; NO --no-verify)` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/n_commit_bypass |
| 24 | `commit.sh:8-64 (arg loop + check_git_repo + message-required)` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/n_parse |
| 25 | `commit.sh:83-85 (REMINDER: create-task.sh)` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/n_reminder |
| 26 | `commit.sh:96-110 (found_task=extract_task_id "$message")` | script-path | **YES** | `.agentic-framework/agents/git/lib/commit.sh` [basename-only] | git-commit-flow/g_taskref |
| 27 | `context.sh generate-episodic` | script-path | **YES** | `.agentic-framework/agents/context/context.sh` [basename-only] | session-handover/n_enrich |
| 28 | `cp <target> <target>.bak-$(date +%s)` | prose | **NO** | free text — no resolvable target | upgrade-process/n_backup |
| 29 | `edit .tasks/active/T-XXX (replace placeholder ACs)` | prose | **NO** | free text — no resolvable target | task-gate/n_scope |
| 30 | `fw arc approve-driver ${arc_id} --i-am-human` | fw-command | **YES** | `bin/fw` case `arc)` | arc-lifecycle/n_approve_driver |
| 31 | `fw arc rescore ${arc_id}` | fw-command | **YES** | `bin/fw` case `arc)` | arc-lifecycle/n_bvp |
| 32 | `fw arc review ${arc_id}` | fw-command | **YES** | `bin/fw` case `arc)` | arc-lifecycle/n_review |
| 33 | `fw arc start ${arc_id}` | fw-command | **YES** | `bin/fw` case `arc)` | arc-lifecycle/n_start |
| 34 | `fw arc tag ${arc_id} T-XXXX` | fw-command | **YES** | `bin/fw` case `arc)` | arc-lifecycle/n_tag |
| 35 | `fw assumption add / research artifact docs/reports/T-XXX-*.md` | fw-command | **YES** | `bin/fw` case `assumption)` | inception-lifecycle/n_expl01 |
| 36 | `fw assumption invalidate ${assumption_id} --evidence '...'` | fw-command | **YES** | `bin/fw` case `assumption)` | assumption-validation/n_invalidate |
| 37 | `fw assumption validate ${assumption_id} --evidence '...'` | fw-command | **YES** | `bin/fw` case `assumption)` | assumption-validation/n_validate |
| 38 | `fw dispatch send` | fw-command | **YES** | `bin/fw` case `dispatch)` | cross-host-dispatch/n_send |
| 39 | `fw harvest` | fw-command | **YES** | `bin/fw` case `harvest)` | harvest-pipeline/n_start |
| 40 | `fw healing resolve ${task_id} --mitigation "..."` | fw-command | **YES** | `bin/fw` case `healing)` | healing-loop/n_resolve |
| 41 | `fw healing resolve T-XXX --mitigation "what fixed it"` | fw-command | **YES** | `bin/fw` case `healing)` | error-escalation-ladder/n_resolve |
| 42 | `fw inception decide ${task_id} defer --i-am-human` | fw-command | **YES** | `bin/fw` case `inception)` | inception-lifecycle/n_df01 |
| 43 | `fw inception decide ${task_id} go --i-am-human` | fw-command | **YES** | `bin/fw` case `inception)` | inception-lifecycle/n_go01 |
| 44 | `fw inception decide ${task_id} no-go --i-am-human` | fw-command | **YES** | `bin/fw` case `inception)` | inception-lifecycle/n_ng01 |
| 45 | `fw inception decide T-XXX defer` | fw-command | **YES** | `bin/fw` case `inception)` | inception-review/n_defer |
| 46 | `fw inception decide T-XXX go` | fw-command | **YES** | `bin/fw` case `inception)` | inception-review/n_go |
| 47 | `fw inception decide T-XXX no-go` | fw-command | **YES** | `bin/fw` case `inception)` | inception-review/n_nogo |
| 48 | `fw promote L-XXX --name "..." --directive D1` | fw-command | **YES** | `bin/fw` case `promote)` | promotion-pipeline/n_promote |
| 49 | `fw promote suggest` | fw-command | **YES** | `bin/fw` case `promote)` | promotion-pipeline/n_suggest |
| 50 | `fw release` | fw-command | **YES** | `bin/fw` case `release)` | release-pipeline/n_start |
| 51 | `fw review` | fw-command | **NO** | no `review)` verb; `fw review` -> "Unknown command: review", exit 1 | review-emission/n_start |
| 52 | `fw task review ${task_id}` | fw-command | **YES** | `bin/fw` case `task)` | inception-lifecycle/n_revw01 |
| 53 | `fw task review T-XXX` | fw-command | **YES** | `bin/fw` case `task)` | inception-review/n_request |
| 54 | `fw task update ${task_id} --status issues` | fw-command | **YES** | `bin/fw` case `task)` | task-lifecycle/n_issues |
| 55 | `fw task update ${task_id} --status started-work` | fw-command | **YES** | `bin/fw` case `task)` | healing-loop/n_resume |
| 56 | `fw task update ${task_id} --status work-completed` | fw-command | **YES** | `bin/fw` case `task)` | task-lifecycle/n_complete_req |
| 57 | `fw task update T-XXX --status issues` | fw-command | **YES** | `bin/fw` case `task)` | error-escalation-ladder/n_issues |
| 58 | `fw tier0 approve  \|  Watchtower approval surface` | fw-command | **YES** | `bin/fw` case `tier0)` | tier0-escalation/n_human_decide |
| 59 | `fw work-on "name" --type build` | fw-command | **YES** | `bin/fw` case `work-on)` | task-gate/n_create |
| 60 | `fw work-on ${task_id}` | fw-command | **YES** | `bin/fw` case `work-on)` | inception-lifecycle/n_strt01; task-lifecycle/n_start |
| 61 | `git agent commit -m "<task>: Checkpoint handover"` | fw-command | **NO** | literal `git agent` is not a command; the real form is `fw git commit` | session-handover/n_commit |
| 62 | `hooks.sh:271-358 (pre-commit) + hooks.sh:55-88 (commit-msg)` | script-path | **YES** | `.agentic-framework/agents/git/lib/hooks.sh` [basename-only] | git-commit-flow/g_hooks |
| 63 | `lib/arc.sh:344` | script-path | **YES** | `.agentic-framework/lib/arc.sh` [fw-rel] | arc-lifecycle/n_create |
| 64 | `lib/arc.sh:643` | script-path | **YES** | `.agentic-framework/lib/arc.sh` [fw-rel] | arc-lifecycle/n_close |
| 65 | `lib/arc.sh:770` | script-path | **YES** | `.agentic-framework/lib/arc.sh` [fw-rel] | arc-lifecycle/n_abandon |
| 66 | `lib/assumption.sh:do_assumption_add` | script-path | **YES** | `.agentic-framework/lib/assumption.sh` [fw-rel] | assumption-validation/n_add |
| 67 | `lib/decision.sh:103-147` | script-path | **YES** | `.agentic-framework/agents/context/lib/decision.sh` [basename-only] | context-memory/n_decision |
| 68 | `lib/diagnose.sh:157-204` | script-path | **YES** | `.agentic-framework/agents/healing/lib/diagnose.sh` [basename-only] | healing-loop/n_suggest |
| 69 | `lib/diagnose.sh:classify_failure` | script-path | **YES** | `.agentic-framework/agents/healing/lib/diagnose.sh` [basename-only] | healing-loop/n_classify |
| 70 | `lib/diagnose.sh:find_similar_patterns (python3 lib/ask.py)` | script-path | **YES** | `.agentic-framework/agents/healing/lib/diagnose.sh` [basename-only] | healing-loop/n_lookup |
| 71 | `lib/episodic.sh:242-441` | script-path | **YES** | `.agentic-framework/agents/context/lib/episodic.sh` [basename-only] | context-memory/n_episodic |
| 72 | `lib/focus.sh:49-127` | script-path | **YES** | `.agentic-framework/agents/context/lib/focus.sh` [basename-only] | context-memory/n_focus |
| 73 | `lib/init.sh:26-77` | script-path | **YES** | `.agentic-framework/lib/init.sh` [fw-rel] | context-memory/n_init |
| 74 | `lib/learning.sh:91-126` | script-path | **YES** | `.agentic-framework/agents/context/lib/learning.sh` [basename-only] | context-memory/n_learning |
| 75 | `lib/notify.sh:fw_notify` | script-path | **YES** | `.agentic-framework/lib/notify.sh` [fw-rel] | audit-process/n_notify |
| 76 | `lib/pattern.sh:124-157` | script-path | **YES** | `.agentic-framework/agents/context/lib/pattern.sh` [basename-only] | context-memory/n_pattern |
| 77 | `lib/promote.sh:4-5 (fw promote); cross-project lib/harvest.sh` | script-path | **YES** | `.agentic-framework/lib/promote.sh` [fw-rel] | context-memory/n_promote |
| 78 | `new practice / protocol in CLAUDE.md (diagnose.sh:201-203)` | prose | **NO** | free text — no resolvable target | error-escalation-ladder/n_d |
| 79 | `restore <target> from <target>.bak-<ts>` | prose | **NO** | free text — no resolvable target | upgrade-process/n_rollback |
| 80 | `resume.sh:119-127 (get_git_state:61-70)` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_git |
| 81 | `resume.sh:130-144 (get_active_tasks:30-59)` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_tasks |
| 82 | `resume.sh:147` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/g_ho |
| 83 | `resume.sh:148-186 ([TODO] count -> stale WARN; sed section extracts)` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_ho |
| 84 | `resume.sh:187-188` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_noho |
| 85 | `resume.sh:192-257 (three independent if-exists blocks)` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_intel |
| 86 | `resume.sh:259-272` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_synth |
| 87 | `resume.sh:95-99 (get_session:81, get_focus:72)` | script-path | **YES** | `.agentic-framework/agents/resume/resume.sh` [basename-only] | resume-status/n_wm |
| 88 | `traverse.sh:159-173 (diff-tree --name-only -r ref; log -1 %s)` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/n_diff |
| 89 | `traverse.sh:162-165` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/g_changed |
| 90 | `traverse.sh:175-210 (while read file; case skip; card grep)` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/n_scan |
| 91 | `traverse.sh:183-187 (inner scan of components/*.yaml, grep ^location)` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/g_card |
| 92 | `traverse.sh:191-201 (depends_on type==writes → print targets)` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/n_writes |
| 93 | `traverse.sh:206-208` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/n_nocard |
| 94 | `traverse.sh:212-213` | script-path | **YES** | `.agentic-framework/agents/fabric/lib/traverse.sh` [basename-only] | fabric-blast-radius/n_total |
| 95 | `type-specific suggestions (diagnose.sh:164-195)` | prose | **NO** | free text — no resolvable target | error-escalation-ladder/n_b |
| 96 | `update-task.sh: RCA 1430-1431/319-398, evolution 1465-1466/681-734, inception 1450-1458 (collapsed)` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/g_gates |
| 97 | `update-task.sh:1010-1026` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/g_verify |
| 98 | `update-task.sh:1104-1117 (--force sets all SKIP_* flags)` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/n_authorise |
| 99 | `update-task.sh:1406-1408 (fn 58-75)` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/g_sovereign |
| 100 | `update-task.sh:1412-1413 (fn 80-190)` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/g_ac |
| 101 | `update-task.sh:1494,1706` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/n_write |
| 102 | `update-task.sh:1742-1782` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/n_finalize |
| 103 | `update-task.sh:1907-1996 (context.sh generate-episodic)` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/n_episodic |
| 104 | `update-task.sh:35-54` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/n_logbypass |
| 105 | `update-task.sh:949-1027` | script-path | **YES** | `.agentic-framework/agents/task-create/update-task.sh` [basename-only] | verification-gate/n_verify |
| 106 | `watchtower:/arcs/${arc_id}/close  \|  fw arc close --i-am-human` | watchtower-route | **YES** | `.agentic-framework/web/blueprints/arcs.py:1253` | arc-lifecycle/n_close_decide |
| 107 | `watchtower:/inception/${task_id}` | watchtower-route | **YES** | `.agentic-framework/web/blueprints/inception.py:313` | inception-lifecycle/n_dcsn01 |
