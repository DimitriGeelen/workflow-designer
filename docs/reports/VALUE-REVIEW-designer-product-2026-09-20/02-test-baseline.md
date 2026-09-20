# 02 — Test Baseline (Gatherer leg, DG-8)

**Status: COMPLETE** — all 8 sections written. Measured 2026-09-21.

**Headline, for a reader who stops here:** the 49 runners in `tests/` give
**48 PASS / 0 FAIL / 1 TIMEOUT@90s**. The thing that actually gates —
`tests/run-bridge-tests.sh`, which invokes **107** executables, not 45 — gives
**131 passed / 7 failed, exit 1, in 742 seconds.** One of the 7 is a designer
product failure (third-party byte-identity drift); one is about the test runner
itself; five are agentic-framework tooling. Nothing in CI observes any of it.

Value review of Workflow Designer, 2026-09-20 series. This leg closes data gap
DG-8 (prior review recorded suite pass state as UNKNOWN).

Role: EVIDENCE ONLY. No classification, no recommendations. Every data point
cites a command, path, or exit code.

CI context (pre-established, verified below): `.onedev-buildspec.yml` has one
job, a GitHub mirror push, invoking zero tests. **Every number in this file is
a number nobody currently observes.**

---

## Section 0 — Inventory of runners

Command:
`find tests -type f \( -name '*.py' -o -name '*.mjs' -o -name '*.sh' \) | sort`

| Kind | Count | Note |
|---|---|---|
| `tests/test_*.py` | 45 | the actual assertion legs |
| `tests/*.sh` | 4 | `run-bridge-tests.sh`, `run-validator-tests.sh`, `check-corpus-geometry.sh`, `check-corpus-node-cuts.sh` |
| `tests/*.mjs` | **0** | ABSENT. The brief said `.py/.mjs/.sh`; there are **no** `.mjs` files under `tests/`. |
| **Total** | **49** | matches the brief's count of 49 runners |

**Correction to the framing of "49 runners":** they are not 49 peers. Verified by
`grep -oE 'tests/test_[a-z0-9_]+\.py' tests/run-bridge-tests.sh | sort -u | wc -l`
→ **45**. `tests/run-bridge-tests.sh` invokes **all 45** python files as legs. So
the topology is:

- 1 aggregator (`run-bridge-tests.sh`) — the gating runner
- 45 python legs, every one of them reachable only through that aggregator (or
  by hand)
- 3 standalone shell gates (`run-validator-tests.sh`, `check-corpus-geometry.sh`,
  `check-corpus-node-cuts.sh`) which the aggregator does **not** call

There is exactly ONE entry point that covers the python legs, and it is not
wired to anything automatic (see CI note in the header, and §7).

The 20 `.mjs` files that *do* exist live in `tools/` (`tools/_*-cdp.mjs`,
`tools/_cdp-attach.mjs`, …). They are CDP browser drivers **called by** the
python legs, not runners in their own right. Counting them as tests would
double-count.

### Environment as measured

| Thing | Value | Command |
|---|---|---|
| Python | 3.12.3 | `python3 -V` |
| pytest | 9.0.2 (installed, **not used by the suite**) | `python3 -c "import pytest"` |
| Node | v22.22.1 | `node -v` |
| Browser | present and working — every CDP leg passed | see §2 |

---

## Section 1 — Run results (headline numbers)

Every suite was run under `timeout 90`. Repo mutation was checked by diffing
`git status --porcelain -- ':!.context' ':!.tasks'` before and after the full
sweep: **identical — `NO_REPO_MUTATION`.** No test wrote into the repo.

### Headline — READ BOTH ROWS

DG-8 resolves to **two different answers depending on what you run**, and the
gap between them is the finding.

| Measured | Result |
|---|---|
| The 49 runners in `tests/`, each run alone | **48 PASS, 0 FAIL, 1 TIMEOUT@90s** |
| **The gating aggregator, one clean end-to-end run** | **`bridge round-trip: 131 passed, 7 failed` — EXIT 1, 742 s** |

**The suite is RED.** Running the 45 files in `tests/` gives a clean sweep and
is the answer you get if you treat `tests/` as the suite. Running the thing that
actually gates — `tests/run-bridge-tests.sh`, which invokes 107 executables
(§3.0) — gives **7 failing legs out of 138**. Seven of those failures are
invisible to anyone who only runs `tests/`, because all seven live in `tools/`.

### Row 1 detail: the 49 runners in `tests/`, individually

| Outcome | Count of 49 |
|---|---|
| **PASS** (exit 0) | **48** |
| **FAIL** (non-zero, assertion) | **0** |
| **ERROR** | **0** |
| **TIMEOUT at 90s** (exit 124) | **1** — `run-bridge-tests.sh` |
| **CANNOT-RUN** (missing dep/browser/server) | **0** |

45/45 python legs pass; 3/3 standalone shell gates pass.

### Row 2 detail: the aggregator

| Run | Bound | Exit | Wall |
|---|---|---|---|
| A (per brief) | `timeout 90` | **124 TIMEOUT** | 90.0 s |
| B (clean, single) | `timeout 1500` | **1** | **742 s** |
| C (contaminated — two concurrent runs) | `timeout 600`/`900` | killed | see §8.3 |

All three recorded side by side per the ground rule. Run A is the finding the
brief asked for: **the single gating runner cannot complete in 90 seconds.** It
is not hung — it emitted 35 `== section ==` banners before the cut. Run B shows
what it needs: **742 seconds, twelve and a half minutes**, sequential, no
parallelism and no `--fast` path.

**Twelve minutes is the cost of learning the answer to DG-8.** The sum of the 45
`tests/` legs run individually is ~64 s (§2). The other ~11 minutes is the 71
`tools/` legs, several of which each launch their own headless Chrome.

### The 7 failures (clean run B)

| # | Leg | Subject | What it reports |
|---|---|---|---|
| 1 | `tools/_t358-byteid-thirdparty.mjs` | **DESIGNER PRODUCT** | **9 identical, 2 DRIFTED over 11 third-party fixtures** — the current build no longer emits the recorded bytes |
| 2 | `tools/_t527-capture-invariant.sh` | test infrastructure | `1 if-guarded leg(s) discard their probe's output` — `run-bridge-tests.sh:1480` |
| 3 | `tools/_t451-unwired-guard-census.py` | framework | "the unwired-guard backlog MOVED" — ~15+ new unbaselined tools |
| 4 | `tools/verification-hygiene.py` (G-015) | framework | `HYGIENE FAIL — 9 carrier line(s) outside the baseline` |
| 5 | `tools/_t509-instrument-sweep.sh` | framework | "an instrument that passed on 2026-08-15 no longer does" — names `_t525` |
| 6 | `tools/_t525-fabric-coverage-teeth.py` | framework | `7/8 legs passed — FAILED: 6b` |
| 7 | `tools/_t560-absence-census-teeth.py` | framework | `FAIL: leg 5: unoverridden run gave rc=1 over 2986 legs` |

**Only #1 is a designer-product failure. #2 is about the test runner itself.
#3–#7 are agentic-framework tooling** — the §3.1 ratio again.

#### #1 in full, because it is the one that is about the product

```
Byte-identity over THIRD-PARTY documents — current build vs recorded goldens
build : /opt/832-Workflow-designer/src/aef-workflow-designer.html
golden: /opt/832-Workflow-designer/tests/goldens/third-party

  aef-draft-inception-readiness-v2.bpmn identical  (25317 bytes, 35 uid(s) normalised)
  bizagi-nested-ns.bpmn                DRIFTED — first diff line 7
      golden : id="Definitions_id_f2afc6ec-e5fc-4205-837c-4f637bf95ba6"
      current: id="Definitions_id_1f46c2af-002d-4b63-b1d1-7f181acc6065"
  boundary-events.bpmn                 identical  (5958 bytes,  9 uid(s) normalised)
  caseagile-local-ns.bpmn              identical  (13780 bytes, 23 uid(s) normalised)
  collaboration-message-flows.bpmn     identical  (3177 bytes,  3 uid(s) normalised)
  i18n-documentation.bpmn              DRIFTED — first diff line 41
      golden : <bpmn:extensionElements>
  kitchen-sink.bpmn                    identical  (40091 bytes, 81 uid(s) normalised)
  multiple-diagrams.bpmn               identical  (2296 bytes,  1 uid(s) normalised)
  nested-subprocesses.bpmn             identical  (8736 bytes, 13 uid(s) normalised)
  simple.bpmn                          identical  (5158 bytes,  7 uid(s) normalised)
  zeebe-service-task.bpmn              identical  (5179 bytes,  7 uid(s) normalised)
  9 identical, 2 drifted, 0 without a golden, 0 unusable, over 11 third-party fixture(s)
```

Note the two drift shapes are different: `bizagi-nested-ns.bpmn` drifts on a
generated `Definitions_id_…` (identity/uid derivation), `i18n-documentation.bpmn`
drifts at `<bpmn:extensionElements>` on line 41 (element ordering or emission).
The tool's own header says ordering drift *"cannot show up as a flattering
identical"* — i.e. this detector is designed not to false-negative.

I did **not** regenerate or re-pin anything (`tests/goldens/` untouched;
`NO_REPO_MUTATION` verified). Whether the goldens are stale or the build
regressed is a classification question, and classification is the JUDGE's.

### Caveat on #3, #4, #7 — the working tree is dirty

`git status` at session start shows a large set of uncommitted `.context/` and
`.tasks/` changes. Three of the seven failures assert over exactly that
population: #4 names `.tasks/active/T-155-…`, `T-676-…`, `T-708-…`; #7 sweeps
"2986 legs" across task Verification blocks; #3 baselines `tools/` contents.
**These three may be artifacts of an uncommitted working tree rather than
standing defects.** Recorded as-measured; not reconciled. #1, #2, #5, #6 do not
depend on `.tasks/` state.

### A false negative I generated and then corrected

My first sweep classified 4 files as `pytest` because they lack an
`if __name__ == "__main__"` guard: `test_dead_leg_census.py`,
`test_t312_lane_geometry.py`, `test_t313_lane_capacity.py`,
`test_t317_gw_ambiguous_parity.py`. Under `python3 -m pytest` all four returned
**exit 5 (no tests collected)** — they define no `def test_*`.

That is not a failure of those files. They execute their assertions at module
top level, so `python3 tests/<file>.py` runs them — which is exactly how
`run-bridge-tests.sh` invokes them (lines 373, 389, 461, 518). Re-run as
scripts: **all four exit 0.**

The durable fact underneath: **`pytest` is installed in this environment but
collects ZERO tests from `tests/`.** Anyone who walks up to this repo and types
the reflex command `pytest tests/` gets "no tests ran" from 4 files and
`__main__`-guarded no-ops from the other 41. The only way to run this suite is
to know that `tests/run-bridge-tests.sh` exists.

---

## Section 2 — Per-suite run detail

All commands run from repo root. `mode=script` → `timeout 90 python3 <file>`.
`mode=shell` → `timeout 90 bash <file>`.

Assertion counts are taken from each suite's **own** final summary line, because
these suites do not use a framework that reports counts. Where a suite reports no
number, the cell says `self-reported: none`.

| # | Suite | Mode | Exit | Wall | Self-reported result |
|---|---|---|---|---|---|
| 1 | `test_bridge_aef_passthrough.py` | script | 0 | 0.0s | typed-event `aef:eventDef` parity (error/timer/message), binding scalars known |
| 2 | `test_bridge_seam_roundtrip.py` | script | 0 | 5.0s | bridge emissions survive editor import, no silent drop, all workflows |
| 3 | `test_check_pass_reachability.py` | script | 0 | 0.0s | 52 rules over 67 corpus + 54 fixture docs; 51 fire and fall silent; 0 always-fire |
| 4 | `test_corpus_fixture_pins.py` | script | 0 | 0.0s | byte-determinism + validator-clean + teeth for pair-draft diagrams |
| 5 | `test_dead_leg_census.py` | script | 0 | 0.0s | fixture pinned b82668c8, census 4/4, raw-scan hazard 9>4, corpus 0 |
| 6 | `test_designer_export_contract.py` | script | 0 | 2.0s | 8 owner-bearing nodes carry non-empty `aef:uid` + defined lane authority; **teeth proven** |
| 7 | `test_designer_owner_derived.py` | script | 0 | 2.0s | owner retired from AEF_FIELDS, no editable dropdown, read-only readout |
| 8 | `test_designer_render.py` | script | 0 | 2.0s | render 0.12.0, T-177 markers, inspector dropdowns, console clean |
| 9 | `test_editor_behavior.py` | script | 0 | 13.0s | T-234 jump-no-poison + edit-restore; T-237 classification contract |
| 10 | `test_editor_bridge_field_coverage.py` | script | 0 | 4.0s | 17 read-fields, 11 META_KEYS checked |
| 11 | `test_editor_bridge_meta_parity.py` | script | 0 | 0.0s | all 20 editor metaKeys present in bridge META_KEYS (29 keys) |
| 12 | `test_editor_bridge_structured_parity.py` | script | 0 | 0.0s | list/dict/itemlist structured aef keys agree |
| 13 | `test_editor_extension_shape_consistency.py` | script | 0 | 0.0s | 2 bridge element-text fields read via `.textContent` |
| 14 | `test_editor_namespace_consistency.py` | script | 0 | 0.0s | 33 `aef:` declarations across 30 sources all canonical |
| 15 | `test_emitted_comment_claims.py` | script | 0 | 0.0s | 13 PASS legs — emitted comments name no one else's behaviour |
| 16 | `test_finding_anchorability.py` | script | 0 | 4.0s | 23 XmlValidator rules over 96 BPMN docs; 22/23 verified, 1 never witnessed |
| 17 | `test_forward_fixtures.py` | script | 0 | 0.0s | 19 fixtures forward-compatible |
| 18 | `test_harness_cross_form_agreement.py` | script | 0 | 2.0s | 20 pairs, 17 AGREE, 0 disagree, 3 bridge-repaired, 1 untestable |
| 19 | `test_harness_emitter_fidelity.py` | script | 0 | 1.0s | 192 files, 24 permitted names, 2 tolerated, 0 violations |
| 20 | `test_mapping_standard_conformance.py` | script | 0 | 0.0s | 4 frozen governance meta-keys present in both editor + bridge |
| 21 | `test_note_capture_refuses_lost_payload.py` | script | 0 | 0.0s | 6 legs; `fw note` refuses payload-losing calls |
| 22 | `test_promote_contract.py` | script | 0 | 0.0s | manifest owner-bearing uids; uid totality + byte-determinism + teeth |
| 23 | `test_release_immutability.py` | script | 0 | 0.0s | G-007, 5 paths incl. blocked-mutation and dist-untouched-on-block |
| 24 | `test_roundtrip_serialization.py` | script | 0 | 2.0s | round-trip is a semantic fixed point across all aef-bpmn fixtures |
| 25 | `test_rule_dialect_axis.py` | script | 0 | 0.0s | 49 rules classified: 42 universal, 3 dialect-relative, 4 presentational; 5 polarity probes |
| 26 | `test_rule_form_parity.py` | script | 0 | 0.0s | rule-form parity OK (`self-reported: none` — no counts printed) |
| 27 | `test_t125_lane_compaction.py` | script | 0 | 4.0s | vertical-only, fixpoint, containment, overlaps, undo, ceilings; 24 maps |
| 28 | `test_t258_annotation_seam.py` | script | 0 | 2.0s | ready handshake, badge intake, spoof rejection, wipe + doc-switch |
| 29 | `test_t259_eventdef_preservation.py` | script | 0 | 1.0s | start/throw eventDefs survive open→save; **guard bites** |
| 30 | `test_t264_save_target_guards.py` | script | 0 | 1.0s | collision notice, commit-on-blur/Enter, load-source mismatch; **BITE** |
| 31 | `test_t293_endpoint_reach.py` | script | 0 | 2.0s | 12 legs, ALL PASS |
| 32 | `test_t308_bare_catch_render.py` | script | 0 | 1.0s | neutral glyph/panel, export surface zero, session intent dies; **guard bites** |
| 33 | `test_t310_lane_position_conflict.py` | script | 0 | 1.0s | declared lane wins, move reported, nothing leaks to export, idempotent |
| 34 | `test_t311_doc_comment_roundtrip.py` | script | 0 | 1.0s | doc block verbatim, leads export, survives re-import + undo |
| 35 | `test_t312_lane_geometry.py` | script | 0 | 0.0s | all lane-geometry assertions passed (`self-reported: none`) |
| 36 | `test_t313_lane_capacity.py` | script | 0 | 0.0s | all lane-capacity assertions passed (`self-reported: none`) |
| 37 | `test_t314_fixture_repin.py` | script | 0 | 0.0s | two fixtures re-pinned by SHA; membership, heights, validator-clean |
| 38 | `test_t315_lane_grow_on_import.py` | script | 0 | 1.0s | band grown to 591, zero nodes moved, dirty map byte-identical |
| 39 | `test_t316_runner_orphans.py` | script | 0 | 0.0s | **no collectable test file sits outside the gating runner** (4 legs) |
| 40 | `test_t317_gw_ambiguous_parity.py` | script | 0 | 9.0s | 44 maps swept, 1 true positive, boundary pinned at exactly one |
| 41 | `test_two_lane_joint_contract.py` | script | 0 | 0.0s | owner-bearing uids; uid totality + byte-determinism + teeth |
| 42 | `test_typed_event_fixture_contract.py` | script | 0 | 0.0s | byte-determinism + 3 intermediate + 2 boundary kinds + IW-1 + teeth |
| 43 | `test_typed_events.py` | script | 0 | 1.0s | typed events decode/encode; extension-driven typing bites |
| 44 | `test_validate_iw9.py` | script | 0 | 0.0s | 20 checks; O-1/O-3/W-LANE-NO-OWNER incl. absent-authority family |
| 45 | `test_xml_node_type_vocab.py` | script | 0 | 0.0s | validator agrees with bridge and designer; 10 + 1 XML-only |
| 46 | `check-corpus-geometry.sh` | shell | 0 | 3.0s | 24 clean, 0 known-legacy, 0 new-fail, 0 stale, 0 tool-err |
| 47 | `check-corpus-node-cuts.sh` | shell | 0 | 1.0s | 24 unchanged, 0 regressed, 0 improved-stale, total cuts 0 (baseline 0) |
| 48 | `run-validator-tests.sh` | shell | 0 | 6.0s | **54 passed, 0 failed** |
| 49 | `run-bridge-tests.sh` | shell | **124** | **90.0s** | **TIMEOUT** — see §1 |

Sum of individual wall times for legs 1–48: **~64s**.

### Browser dependency — present, not absent

I expected to find CANNOT-RUN suites. There are none. At least 14 legs drive a
real headless Chrome over CDP (`tools/_cdp-attach.mjs` and siblings) and every
one of them passed. `check-corpus-node-cuts.sh` likewise drives the *real*
editor's own `polylineCrossesNodes` rather than re-implementing geometry
(its header cites PL-005 for this). So the browser-dependent surface is not a
hole in this baseline — it is the part of the baseline that actually touches the
product.

### The 1-second node-cut gate

`check-corpus-node-cuts.sh` returned in 1.0s and reported 24 maps swept with
`total cuts 0 (baseline 0)`. A CDP sweep of 24 maps in one second is fast enough
to be worth flagging as an observation rather than asserting it did the work —
recorded here as an open question, not a finding. Its header documents a
four-way contract (regression / stale-baseline / missing-map / driver-error) and
it reported `0 driver-err`, which is the field that would have caught a no-op.

## Section 3 — What each suite asserts ON (product behaviour vs self-referential)

### 3.0 — The 45 files in `tests/` are not the suite

`tests/run-bridge-tests.sh` is **2211 lines** (`wc -l`) and invokes **107
distinct executables**, not 45:

```
grep -oE '\$(ROOT|TOOLS)/[a-zA-Z0-9_/.-]+\.(py|mjs|sh)' tests/run-bridge-tests.sh \
  | sed 's|\$ROOT/||;s|\$TOOLS/||' | sort -u
```
→ 107 paths: **36 under `tests/`**, **71 under `tools/`**.

So the real gating suite is `tests/` **plus** 71 `tools/_tNNN-*-teeth.{py,mjs,sh}`
legs that live outside `tests/` entirely. Any count of "the tests" that reads
only `tests/` undercounts the gating surface by roughly 2:1.

### 3.1 — What the 71 `tools/` legs are actually about

Classified by what each file references (`aef-workflow-designer` /
`examples/aef-processes` / `yaml-to-bpmn` / `validate-workflow` / `bpmn`
→ *designer*; `bin/fw` / `.agentic-framework` / `.tasks/` / `.context/` /
`fabric` / `episodic` / `watchtower` → *framework*):

| Subject | Count of 71 |
|---|---|
| Designer product only | **26** |
| **Agentic-framework tooling only** | **33** |
| Both | 8 |
| Neither (self-contained probes) | 4 |

**This is the single most consequential structural fact in this leg.** The
runner that gates the Workflow Designer product spends a plurality of its legs
asserting on the *agentic framework's own tooling*, not on the designer. Named
examples, all invoked by `run-bridge-tests.sh`:

`_t524-fabric-validate-teeth.py`, `_t525-fabric-coverage-teeth.py`,
`_t549-fabric-coverage-mutation-teeth.py`, `_t568-fabric-card-cache-teeth.sh`,
`_t569-card-purpose-markdown-teeth.py` (context fabric);
`_t516-episodic-decisions-teeth.py`, `_t522-episodic-reachability-teeth.py`,
`_t567-episodic-parse-check.py`, `_t567-episodic-yaml-safety-teeth.sh`
(episodic memory);
`_t534-d2-queue-tier-teeth.py`, `_t535-trend-key-teeth.py`,
`_t536-status-desync-teeth.py`, `_t539-gap-closure-gauge-conformance.py`,
`_t541-bvp-driver-handler-teeth.py`, `_t542-cost-blast-radius-teeth.py`,
`_t544-session-cookie-port-teeth.py`, `_t547-hx-prompt-decode-teeth.py`,
`_t550-audit-parse-anchor-teeth.py` (Watchtower / metrics / audit);
`_t574-p011-block-locator-teeth.py`, `_t585-human-ac-visibility-census.py`,
`_t586-worktree-denial-guard.py`, `_t621-operator-ac-classification-guard.py`
(task-system governance).

None of those exercise BPMN authoring, rendering, validation, or export. They
are in this runner because this runner is the only thing that runs anything.

### 3.2 — Per-suite: does it assert on PRODUCT BEHAVIOUR?

Categories used:

- **BEHAVIOUR (live)** — drives the real editor in headless Chrome over CDP, or
  executes `validate-workflow.py` / `yaml-to-bpmn.py` on real input and asserts
  on the output.
- **SOURCE-STATIC** — parses product source text (regex over
  `src/aef-workflow-designer.html` or `tools/yaml-to-bpmn.py`) and asserts on
  constants/structure. Real drift detector; **not** behaviour.
- **FIXTURE-PINNED** — asserts a fixture's bytes/SHA are unchanged. Catches
  fixture drift; says nothing about the product unless a product step produced
  those bytes in the same run.
- **META** — asserts about the test suite itself.

| Suite | Category | Product feature actually covered |
|---|---|---|
| `test_designer_render.py` | BEHAVIOUR (live) | editor boots, renders, inspector dropdowns populate, console clean |
| `test_designer_export_contract.py` | BEHAVIOUR (live) | export emits `aef:uid` + lane authority on owner-bearing nodes |
| `test_designer_owner_derived.py` | BEHAVIOUR (live) | owner is derived from lane authority, not user-editable |
| `test_editor_behavior.py` | BEHAVIOUR (live) | node jump / edit-restore / classification (T-234, T-237) |
| `test_bridge_seam_roundtrip.py` | BEHAVIOUR (live) | bridge output survives editor import with no silent drop |
| `test_roundtrip_serialization.py` | BEHAVIOUR (live) | load→save is a semantic fixed point |
| `test_t125_lane_compaction.py` | BEHAVIOUR (live) | lane compaction: vertical-only, fixpoint, containment, undo |
| `test_t258_annotation_seam.py` | BEHAVIOUR (live) | `aef:ready`/`aef:annotate` handshake, badge intake, spoof rejection |
| `test_t259_eventdef_preservation.py` | BEHAVIOUR (live) | start/throw eventDefs survive open→save |
| `test_t264_save_target_guards.py` | BEHAVIOUR (live) | save-target collision notice, blur/Enter commit, mismatch confirm |
| `test_t293_endpoint_reach.py` | BEHAVIOUR (live) | edge endpoint handles reachable above node bodies (drag) |
| `test_t308_bare_catch_render.py` | BEHAVIOUR (live) | unbound catch event renders neutrally; zero export surface |
| `test_t310_lane_position_conflict.py` | BEHAVIOUR (live) | declared lane beats conflicting geometry; idempotent repair |
| `test_t311_doc_comment_roundtrip.py` | BEHAVIOUR (live) | authored doc block verbatim, leads export, survives undo |
| `test_t315_lane_grow_on_import.py` | BEHAVIOUR (live) | under-declared lane band grown on import, nodes not moved |
| `test_typed_events.py` | BEHAVIOUR (live) | typed event decode/encode (error/timer/message) |
| `test_validate_iw9.py` | BEHAVIOUR (validator) | IW-9 rules: type↔lane mismatch, inception sovereignty, lane owner |
| `test_check_pass_reachability.py` | BEHAVIOUR (validator) | every validator rule has a reachable passing state (52 rules) |
| `test_rule_form_parity.py` | BEHAVIOUR (validator) | YAML-form and XML-form rules agree |
| `test_harness_cross_form_agreement.py` | BEHAVIOUR (validator) | 20 rule pairs compared across forms on real documents |
| `test_finding_anchorability.py` | BEHAVIOUR (validator) | 23 XmlValidator rules classified + verified on 96 real BPMN docs |
| `test_t317_gw_ambiguous_parity.py` | BEHAVIOUR (validator) | `W-XML-GW-AMBIGUOUS`, 44 maps swept, boundary pinned |
| `test_bridge_aef_passthrough.py` | BEHAVIOUR (bridge) | `aef.x-*` passthrough and loud-drop |
| `test_t312_lane_geometry.py` | BEHAVIOUR (rule fn) | lane-ordering rule fired via imported module, incl. SKIP-not-PASS |
| `test_t313_lane_capacity.py` | BEHAVIOUR (rule fn) | lane capacity: occupancy≠height, bottom-edge lowest node |
| `test_release_immutability.py` | BEHAVIOUR (release) | G-007: blocked mutation, dist untouched on block, bypass path |
| `test_promote_contract.py` | BEHAVIOUR (promote) | designer→AEF promote: uid totality, byte-determinism, teeth |
| `test_two_lane_joint_contract.py` | BEHAVIOUR (promote) | two-lane joint promote fixture: uid totality + teeth |
| `test_harness_emitter_fidelity.py` | SOURCE-STATIC | every synthesised `<bpmn:*>` is one an emitter can produce (192 files) |
| `test_xml_node_type_vocab.py` | SOURCE-STATIC | validator / bridge / designer agree on node-type vocabulary |
| `test_editor_bridge_meta_parity.py` | SOURCE-STATIC | editor `metaKeys` ⊆ bridge `META_KEYS` (regex over two constants) |
| `test_editor_bridge_field_coverage.py` | SOURCE-STATIC | 17 editor read-fields present in the bridge |
| `test_editor_bridge_structured_parity.py` | SOURCE-STATIC | list/dict/itemlist aef key shapes agree |
| `test_editor_extension_shape_consistency.py` | SOURCE-STATIC | 2 bridge element-text fields read via `.textContent` |
| `test_editor_namespace_consistency.py` | SOURCE-STATIC | 33 `aef:` namespace declarations across 30 sources canonical |
| `test_mapping_standard_conformance.py` | SOURCE-STATIC | frozen standard's 4 meta-keys present in editor + bridge lists |
| `test_rule_dialect_axis.py` | SOURCE-STATIC + probes | 49 rules classified universal/dialect/presentational; 5 live probes |
| `test_emitted_comment_claims.py` | SOURCE-STATIC | emitted comments describe our own bytes only (13 legs) |
| `test_corpus_fixture_pins.py` | FIXTURE-PINNED (+validator) | pair-draft fixture SHAs + validator-clean |
| `test_typed_event_fixture_contract.py` | FIXTURE-PINNED | typed-event fixture SHA + `aef:eventDef` shape + IW-1 |
| `test_t314_fixture_repin.py` | FIXTURE-PINNED (+validator) | two fixtures re-pinned by SHA; membership/heights hold |
| `test_forward_fixtures.py` | FIXTURE-PINNED | 19 fixtures parse forward-compatibly |
| `test_dead_leg_census.py` | META (+fixture pin) | census tool counts DEAD legs correctly; raw-scan hazard shown |
| `test_t316_runner_orphans.py` | **META** | **no collectable test file sits outside the gating runner** |
| `test_note_capture_refuses_lost_payload.py` | **NOT THIS PRODUCT** | `fw note` CLI argument handling — agentic framework, not the designer |
| `check-corpus-geometry.sh` | BEHAVIOUR (corpus) | `check-lane-bands.py` over all 24 corpus maps, rot-proof allowlist |
| `check-corpus-node-cuts.sh` | BEHAVIOUR (live, corpus) | node-cut census via the editor's own `polylineCrossesNodes` |
| `run-validator-tests.sh` | BEHAVIOUR (validator) | 54 checks: golden clean, every `invalid/` → exit 2, `warn/` → exit 1 |
| `run-bridge-tests.sh` | aggregator | all of the above plus 71 `tools/` legs |

**Tally of the 49:** 28 BEHAVIOUR · 11 SOURCE-STATIC · 4 FIXTURE-PINNED ·
2 META · 1 NOT-THIS-PRODUCT · 3 corpus/validator shell gates (counted in
BEHAVIOUR above) · 1 aggregator.

### 3.3 — The suite names its own genre problem

`tests/test_emitted_comment_claims.py:27` states the rule this section is
applying, in the repo's own words:

> `2. PL-034: a guard that checks INTERNAL SELF-CONSISTENCY cannot detect a broken`

That is the SOURCE-STATIC category above, and there are 11 of them.

## Section 4 — Load-bearing product paths with no test

Method: took the item column of §A of
`01-feature-inventory.md` (93 inventoried items — I did **not** re-derive it),
then grepped the **full gating leg set** (49 runners + the 71 `tools/` legs =
107 executables, from `/tmp/tb/legs.txt`) for each item's distinguishing
identifier. A zero means *no gating leg mentions the feature by any of its
identifiers* — which is a strictly weaker claim than "untested", so where I say
UNCOVERED below I mean **no leg names it**.

### 4.1 — Inventoried items with ZERO mentions across all 107 gating legs

| Feature (from 01 §A) | Section | Identifier grepped | Hits |
|---|---|---|---|
| Click-to-place | A2 | `placeNode\|click-to-place\|clickPlace` | **0** |
| Node drag / move | A2 | `onNodeMouseDown\|node drag` | **0** |
| Align / Distribute on a multi-selection | A2/A3 | `alignSelection\|distributeEven\|align-distribute` | **0** |
| Connect mode (draw sequence flow) | A2 | `connectMode\|connect mode` | **0** |
| Per-segment routing nudge | A2 | `onSegmentMouseDown\|segment nudge` | **0** |
| Lane add / delete / reorder / resize | A2 | `addLane\|deleteLane\|reorderLane` | **0** |
| Pool right-edge resize | A2 | `onPoolResize\|poolResize` | **0** |
| Snap guides | A3 | `snapGuide\|guide line` | **0** |
| Label fitting / wrapping / de-collision | A3 | `labelFit\|wrapLabel\|label-overlap` | **0** |
| Orthogonal routing engine | A3 | `orthogonal\|routeEdge\|routing engine` | **0** |
| File picker import | A4 | `file picker\|input type=.file\|openFile` | **0** |
| Clean-on-import option | A4 | `clean-on-import\|cleanOnImport` | **0** |
| Save → download `.bpmn` | A5 | `download\|saveAs` | **0** |
| XML view + copy | A5 | `xml view\|copyXml\|xmlView` | **0** |
| Editor preferences (settings dialog) | A8 | `preferences\|settings dialog\|openSettings` | **0** |
| Save to project (versioned) | A6 | `save to project\|saveProject\|/api/save` | **0** |
| Open project browser | A6 | `open project\|/api/projects` | **0** |
| Keyboard surface (all 9 bindings) | A9 | `keydown\|Ctrl.Cmd\|keyboard` | **0** |

**Eighteen inventoried items — including the two most basic authoring gestures
in a diagram editor (click-to-place a node, drag a node) and the entire
9-binding keyboard surface — are named by nothing in the gating suite.**

Note the shape of what IS covered versus what is not. The covered set is
overwhelmingly *seam* behaviour: parse, emit, validate, round-trip, lane
geometry, extension vocabulary. The uncovered set is overwhelmingly *direct
manipulation*: place, drag, connect, resize, nudge, keyboard. The suite tests
the file format far more than it tests the editor.

### 4.2 — Thinly covered (1–2 mentions, single leg)

| Feature | Hits | Where |
|---|---|---|
| Multi-select (rubber band) | 1 | one leg only |
| Autosave restore on load | 1 | one leg only |
| Foreign / unknown BPMN tag survival | 1 | `tools/_t355-foreign-tag-render-cdp.mjs` only |
| Thumbnail capture | 1 | one leg only |
| Jump to referenced workflow | 1 | one leg only |
| Toast | 1 | one leg only |
| Loop-back detour drag | 2 | |
| Deep-link import (`?load=`) | 2 | |
| Multi-`bpmn:process` documents | 2 | |
| Session library ("Recently opened") | 2 | |

### 4.3 — Cross-check against 01 §C (zero-reference functions)

01 §C lists **10 functions with zero call-sites and zero bare references** in
`src/aef-workflow-designer.html`. Cross-checking those against the gating legs:

- `portPoint` — named by `tools/_typed-events-cdp.mjs` (01 §C already records
  this). That tool IS a gating leg, so a dead product function is reachable from
  a green test. Recorded as a data point, not a verdict.
- The other nine (`clearWaypoints`, `onAddWaypointMouseDown`,
  `currentRenderedMiddleCorners`, `findNodeByUid`, `findNodeByDisplayId`,
  `generateNodeId`, `midOfPath`, `midOfPolyline`, `nodeSideForExitDir`) are
  named by no gating leg — consistent with 01 §C's "External refs: none".

So the test suite does **not** hold the ten orphans alive. Deleting them would
not turn the suite red. (That is a §5 observation, listed here because §C is
where the candidates came from.)

### 4.4 — The product's own census of untested instruments

`tools/_t451-unwired-guard-census.py` is itself a gating leg. I ran it
(`timeout 90 python3 tools/_t451-unwired-guard-census.py`, **exit 0**). Its
output is the most load-bearing single artefact in this leg:

```
  population                                        322  tools/*.{py,sh,mjs,js} on disk
  roots (hook, cron, tests/, agent, gap gauge)       98  NOT itself a tool
  live-callable (closure from roots)                110  of which 12 reached only via a live tool chain
  pending one-shot (ACTIVE task Verification only)    49  will run once, then join the set below
  NO live caller                                    163
    one-shot BY DESIGN (teeth/mutation-check/probe)   45  excused by naming convention
    FINDINGS — read as standing guards              118
      never referenced by ANY task at all             16
```

**118 instruments read as standing guards and nothing in the tree can re-run
them.** Named examples from its own output, with the last task that ran them:

| Instrument | Last ran at |
|---|---|
| `_cdp-attach.mjs` | **NO CALLER ANYWHERE** |
| `_autoload-verify-cdp.mjs` | **NO CALLER ANYWHERE** |
| `_autosave-verify-cdp.mjs` | **NO CALLER ANYWHERE** |
| `_edge-straighten-verify-cdp.mjs` | **NO CALLER ANYWHERE** |
| `_endpoint-overlap-verify-cdp.mjs` | **NO CALLER ANYWHERE** |
| `_horizontal-spacing-verify-cdp.mjs` | **NO CALLER ANYWHERE** |
| `_align-distribute-diag.mjs` | **NO CALLER ANYWHERE** |
| `_t263-save-target-cdp.mjs` | **NO CALLER ANYWHERE** |
| `_save-api-verify.mjs` | T-129 |
| `_saveproject-verify-cdp.mjs` | T-130 |
| `_endpoint-hover-verify-cdp.mjs` | T-133 |
| `_selection-align-verify-cdp.mjs` | T-134 |
| `_gallery-save-allowlist-verify.py` | T-138 … T-683 |
| `_serve-gallery-verify.py` | T-231, T-683 |

Compare this against §4.1: *Save to project*, *Open project browser*,
*Align / Distribute*, and *Autosave restore* show 0 or 1 hits in the gating set
— and here are the instruments that once verified exactly those features,
sitting in `tools/` with no caller. **The coverage for those features was
written, ran once at task completion, and was never wired to anything that
re-runs it.**

The census also documents its own limit, which bears directly on how much of
the "110 live-callable" number to trust:

> `THIS IS THE BIG ONE: 110 of the 237 referenced tools (46%) have NO`
> `executable-code edge anywhere. Their WIRED verdict rests entirely on`
> `prose — task files 214 refs, handovers 206, episodic 130. For those`
> `tools "wired" is a fact about what a handover once said, not what runs.`

---

## Section 5 — PL-178 class: tests that stay green if the feature is deleted

PL-178 is "an exit code that reports success for work never done". The repo uses
several neighbouring codes for the same family; all quotes below are from the
tree.

### 5.1 — The canonical documented instance, written by the repo about itself

`tests/test_editor_bridge_meta_parity.py`, lines 28–55. This is a suite that ran
green for 47 days while the thing it claimed to protect was broken. Quoted
verbatim:

> `THE REVERSE DIRECTION IS NOT CHECKED HERE, AND FOR 47 DAYS THIS DOCSTRING SAID`
> `IT DID NOT NEED TO BE — added 2026-07-04 (2baf13ce), corrected 2026-08-20`
> `(T-572). The sentence that stood here was:`
>
> > `"the bridge legitimately emits more keys than the editor authors, e.g.`
> > ` determinism/endpoint/sideEffect; those flow bridge→editor via the generic`
> > ` absorption, so the reverse direction is not a data-loss risk."`
>
> `"Not a data-loss risk" is a claim about a ROUND TRIP. It was checked against the`
> `READ side alone. Import is generic (src:10255) — that half is true and visible in`
> `the source. Export was not: it filtered through a 20-key whitelist, so a key was`
> `absorbed on load and DESTROYED on save. Nine bridge keys were outside that`
> `whitelist and the sentence above named three of them as its reassurance:`
> `determinism, endpoint, sideEffect.` **`check() returned [] the entire time, because`**
> **`check() was never looking (PL-034 — a guard that checks internal`**
> **`self-consistency cannot detect a broken promise).`**

And the file states its own current PL-178 status explicitly — *the assertion
still does not hold the feature*:

> `T-570 gave export generic carriage, which is what makes the claim true today, and`
> **`nothing about THIS file holds it that way: revert the carriage and the ⊆`**
> **`assertion below goes green again while nine keys die on every save.`**

That is a direct, in-tree, self-reported answer to the question this section
asks. The mitigation named is a *different* leg
(`tools/_t572-bridge-vocabulary-roundtrip-cdp.mjs`), and the file says so:
`"This file is the ⊆ half and is not sufficient alone."`

### 5.2 — The SOURCE-STATIC family (11 suites, §3.2)

By construction, every suite in the SOURCE-STATIC category asserts that a
**string literal appears in a source file**. The general failure mode: delete
the implementation but leave the identifier in the constant list, and the
assertion is still satisfied.

The clearest instance is `tests/test_mapping_standard_conformance.py`. Its whole
assertion is set membership over regex-extracted string literals
(`tests/test_mapping_standard_conformance.py:65-72`):

```python
def check(frozen, editor_keys, bridge_keys):
    """Return (missing_from_editor, missing_from_bridge)."""
    eset, bset = set(editor_keys), set(bridge_keys)
    return (
        [k for k in frozen if k not in eset],
        [k for k in frozen if k not in bset],
    )
```

`editor_keys` comes from `RE_EDITOR_METAKEYS = re.compile(r"const\s+metaKeys\s*=\s*\[([^\]]*)\]")`
(`tests/test_editor_bridge_meta_parity.py:73`). **The test never executes the
editor.** If `workflowType` were removed from every emit path but left in the
`metaKeys` array literal, this suite prints
`OK: all 4 frozen governance meta-keys ... present in both` and exits 0.

To the suite's credit, it *does* defend against the vacuous-pass variant
(`PL-022`): a missing or empty fence is a failure, not a skip
(`tests/test_mapping_standard_conformance.py:101-108`). That closes one hole in
this family and not the one above.

### 5.3 — PL-161: "a completion gate is not a guard" (the dominant class here)

The aggregator itself carries the most quotable statement of the class,
`tests/run-bridge-tests.sh:655-661`:

> `(parse→emit→parse→emit, asserting proj(m1)===proj(m2)), and until T-490 it ran in no`
> `suite at all. It was written for T-187, sharpened by T-480/T-482/T-483, rebuilt by`
> `T-488 and extended by T-489 — every one of those a hand-run invocation whose green`
> **`expired the moment the session ended. PL-161 names the shape: a probe that only ever`**
> **`runs when someone remembers it is a completion-gate artifact, not a guard.`** `The tell was`
> `that its own inbox entries (OBS on the break, on the divergent METAKEYS copies) were`
> `written by agents reading the file, never by the file failing.`

And, forty lines later, the admission that the same mistake recurred
(`tests/run-bridge-tests.sh:917-920`):

> `This runner already carries the identical lesson forty lines up for`
> `_roundtrip-serialization-cdp.mjs (T-490, PL-161) and the mistake was repeated anyway.`
> **`Two instances is a pattern: a completion gate is not a guard, and the only durable`**
> **`remedy is a caller that re-executes without a task completing.`**

§4.4's 118 instruments are the population this describes.

### 5.4 — PL-205/PL-178 named directly, on a framework tool

`tests/run-bridge-tests.sh:1733-1738`:

> ``fw fabric validate` was the natural detector and had been a stub since T-191: it printed`
> `"Deep validation not yet implemented" for every card and then `return 0`. The prose was honest,`
> `the exit code was not, so `fw fabric validate && echo ok` reported success for work never done`
> **`(PL-205, PL-178).`**

Note the target: this PL-178 instance is in the **agentic framework's** fabric
tooling, not in the designer. Consistent with §3.1 — the framework-tooling legs
outnumber the designer legs.

### 5.5 — Where the suite explicitly does NOT have this problem

Recorded for balance, because it is the same kind of fact. Fourteen suites
report a "teeth" / "bite" leg in their own summary line (§2), i.e. they
deliberately break the feature and assert the guard goes red. Verbatim
self-reports:

- `test_designer_export_contract.py` — "uid/authority checks **proven to have
  teeth**"
- `test_t259_eventdef_preservation.py` — "and **the guard bites**"
- `test_t264_save_target_guards.py` — "mismatch confirm + **BITE**"
- `test_t308_bare_catch_render.py` — "and **the guard bites**"
- `test_typed_events.py` — "the extension-driven typing **bites**"
- `test_promote_contract.py`, `test_two_lane_joint_contract.py`,
  `test_typed_event_fixture_contract.py` — "uid totality + byte-determinism +
  **teeth verified**"
- `test_corpus_fixture_pins.py` — "+ **teeth** for the pair-draft diagrams"
- `test_dead_leg_census.py` — "**raw-scan hazard demonstrated (9>4)**"

Plus 30 `tools/_tNNN-*-teeth.{py,sh}` legs whose entire purpose is mutation
testing of a guard. The mutation-testing discipline in this repo is unusually
strong; it is concentrated on the seam, and absent from the §4.1 list.

## Section 6 — Flaky / skipped / zero-assertion suites

### 6.1 — Flaky

**Zero flakes observed in this run.** Two independent executions of the 45
python legs (the `pytest`-misclassified first pass and the script re-run, plus
the aggregator) produced identical results.

One flake is **documented in the tree** rather than observed by me, in
`tests/run-bridge-tests.sh` (the `report_failed_leg` helper's comment block):

> `Observed 2026-08-01 when`
> `test_bridge_seam_roundtrip.py failed once inside this runner and passed twice`
> `immediately after (T-326).`

The same comment states why the flake was undiagnosable and what was changed:

> `That is survivable for a`
> `deterministic failure — re-run it and read the output. It is fatal for an`
> `intermittent one: the run that failed leaves no evidence of its own cause, so`
> `the flake is reproducible-only and never diagnosable.`

A follow-on note (T-527) records that the helper existed and was called by only
four legs while every other guarded leg still redirected to `/dev/null` — i.e.
the fix was partial for weeks. `test_bridge_seam_roundtrip.py` is a live CDP leg
and took 5.0s in this run; **it is the one suite with a recorded intermittency,
and it is a browser leg.**

### 6.2 — Skipped

No suite skipped at the *suite* level. Skips inside suites are **deliberate and
asserted-on**, which is unusual enough to record verbatim. From
`test_t312_lane_geometry.py` and `test_t313_lane_capacity.py` section banners:

| Skip construct | Suite |
|---|---|
| `SKIP, not PASS: unevaluable maps must not report clean` | `test_t312_lane_geometry.py` |
| `SKIP, not PASS, and the scope guard that keeps it quiet` | `test_t313_lane_capacity.py` |
| `SKIPS rather than guesses occupancy for a type it does not know` | `test_t313_lane_capacity.py` |
| `SKIP note is INFO and does not fail the map` | lane rules |
| `SKIP  PRESENTATIONAL` (×2) | `test_rule_dialect_axis.py` |
| `SKIPPED, not passed` (×2) | lane rules |

These are skips the suite **asserts must happen** — the opposite of a silenced
test. Counted here for completeness, not as a gap.

`test_harness_emitter_fidelity.py` reports `2 tolerated` element names out of 24
permitted — a narrow allowlist, self-reported in its own summary.

### 6.3 — Zero-assertion / no-count suites

Suites that print a green line but no number, so their coverage cannot be read
off the output:

| Suite | Final line |
|---|---|
| `test_rule_form_parity.py` | `rule-form parity: OK` |
| `test_harness_cross_form_agreement.py` | `cross-form agreement: OK` (counts appear one line earlier) |
| `test_t312_lane_geometry.py` | `== all lane-geometry assertions passed ==` |
| `test_t313_lane_capacity.py` | `== all lane-capacity assertions passed ==` |

None is zero-assertion — `test_rule_form_parity.py` is 577 lines and
`test_t312_lane_geometry.py` is 343 — but a reader of the *output* cannot
distinguish "all 40 assertions passed" from "all 0 assertions passed". Recorded
as an observability fact about the output, not a claim that they assert nothing.

The aggregator does report a number for itself
(`run-validator-tests.sh` prints `== summary: 54 passed, 0 failed ==`), so the
convention exists; four suites do not follow it.

### 6.4 — The `pytest` blind spot (repeat of §1, because it belongs here too)

`pytest` 9.0.2 is installed. `pytest tests/` collects **zero** tests. Four files
return exit 5 (`no tests ran`). No `conftest.py`, no `pytest.ini`, no
`[tool.pytest]` section — verified in §8. A reader who assumes the standard
Python convention gets a green-looking "no tests ran" and measures nothing.

---

## Section 7 — tests/ churn vs src/ churn

### 7.1 — The raw counts confirm the brief

| Path | Commits | Command |
|---|---|---|
| `tests/` | **161** | `git log --oneline -- tests/ \| wc -l` |
| `src/` | **144** | `git log --oneline -- src/ \| wc -l` |
| `tools/` | **369** | `git log --oneline -- tools/ \| wc -l` |

`tools/` — which §3.1 shows holds 71 of the 107 gating legs — churns **2.6× more
than `src/`**. Reading `tests/` alone understates the test-side churn
substantially.

### 7.2 — The answer: genuine growth by accretion. Not rework, not fixture drift.

Three independent measurements agree.

**(a) Deletion rate.** `git log --numstat --format=tformat:` summed:

| Path | Lines added | Lines deleted | Deletion rate |
|---|---|---|---|
| `tests/` (all) | **26,076** | **339** | **1.3 %** |
| `tests/run-bridge-tests.sh` | 2,252 | 41 | 1.8 % |
| `src/` | 11,957 | 709 | 5.6 % |

Rework rewrites lines. Test code here is written once and essentially never
removed — a 1.3 % deletion rate over 161 commits is accretion, not churn in the
rework sense. `src/`'s deletion rate is **4× higher** than the tests'.

**(b) Where the commits land.** Per-file commit counts for all 49 runners:

| Runner | Commits |
|---|---|
| `tests/run-bridge-tests.sh` | **104** |
| `test_rule_form_parity.py` | 7 |
| `test_corpus_fixture_pins.py` | 6 |
| `test_harness_cross_form_agreement.py` | 5 |
| `test_rule_dialect_axis.py` | 4 |
| `test_dead_leg_census.py` | 4 |
| `test_validate_iw9.py` | 3 |
| …the other 42 runners | 1–3 each |
| `test_editor_bridge_meta_parity.py` | 2 |
| `test_t316_runner_orphans.py` | 1 |

**104 of the 161 `tests/` commits (65 %) touch the single aggregator file.**
Every individual test file is written once and left alone. This is not fixture
drift and it is not test rework — it is 107 legs being wired into one runner,
one commit at a time.

**(c) Fixture churn is a minority.**

| Subpath | Commits |
|---|---|
| `tests/*.py` + `tests/*.sh` (runners) | 136 |
| `tests/fixtures/` | 53 |
| `tests/goldens/` | 1 |
| `tests/data/` | 1 |

Fixtures account for 53 of 161. And of the 154 file-creations under `tests/`,
**105 are new fixtures and 49 are new runners** — which is exactly the 49
runners that exist today, i.e. **no runner has ever been deleted.**

### 7.3 — What the aggregator's commits are actually doing

The commit subjects on `run-bridge-tests.sh` are not "fix flaky test". They are
new-coverage landings, each naming a defect the new leg was written to catch.
Latest fifteen, verbatim subjects:

- `T-690: extensionElements before conditionExpression — and the additive guard's own AC was the thing defending…`
- `T-621: an operator decision filed as an Agent AC is shown to nobody and blocks completion — guard + reclassif…`
- `T-586: we were never in a worktree, and nothing was preventing it — the second half is the part worth fixing.`
- `T-585: the queue that answers "does the operator owe a decision?" could not tell an empty answer from a blind o…`
- `T-581: the byte-identity gate now has teeth, a live caller, and a refusal that has been shown to refuse.`
- `T-578: the census that measures unwired tools shipped unwired, and the ratchet caught it…`
- `T-572: the guard named 'parity' did not merely check a subset — its docstring ARGUED the direction it does no…`
- `T-570: the editor has been destroying keys our own bridge emits, and the guard named 'parity' asserts a SUBSET,`
- `T-565`, `T-563`, `T-575`, `T-499`, `T-423` (×3)

Note T-586, T-585, T-621, T-581, T-578 — five of the most recent fifteen
coverage landings in the *designer's* test runner are about **framework
tooling** (worktrees, operator-decision queue, task ACs, unwired-tool census).
This is the §3.1 ratio showing up in the commit stream, not just the file list.

**1,065 of the aggregator's 2,211 lines are comments** (`grep -c '^#'`) — 48 %.
The file is roughly half prose. Much of the line growth in (a) is the rationale
block each new leg carries, which is why line counts and coverage do not move
together here.

### 7.4 — Test churn is largely decoupled from product change

Of the 161 commits touching `tests/`, **134 (83 %) do not touch `src/` in the
same commit**; only 27 do. Tests here are not predominantly written alongside a
product change — they are landed as separate governance/coverage work.

---

## Section 8 — Absences (things expected and not found)

Checked by direct existence test; every row verified.

| Expected | Status | Consequence |
|---|---|---|
| `conftest.py` (root or `tests/`) | **ABSENT** | nothing configures pytest |
| `pytest.ini` | **ABSENT** | |
| `pyproject.toml` | **ABSENT** | no `[tool.pytest]`, no declared deps |
| `setup.cfg`, `tox.ini` | **ABSENT** | |
| `package.json` | **ABSENT** | the 20 `tools/*.mjs` CDP drivers have no declared Node deps and no `npm test` |
| `Makefile` | **ABSENT** | no conventional `make test` entry point |
| `.github/workflows/` | **ABSENT** | |
| `.gitlab-ci.yml` | **ABSENT** | |
| Any coverage tooling (`coverage.py`, `c8`, `nyc`) | **ABSENT** | the word "coverage" appears only as a *concept* in test filenames (`test_editor_bridge_field_coverage.py`); no line-coverage instrument exists |
| `tests/*.mjs` | **ABSENT** | the brief's `.mjs` runners are all in `tools/` |
| A test-count or pass-count artefact anywhere in the tree | **ABSENT** | no `.last-test-run`, no results JSON — DG-8 was UNKNOWN because nothing records it |

### 8.1 — CI: verified, and it is what the brief said

`.onedev-buildspec.yml`, read in full. One job:

```yaml
jobs:
  - name: Push to GitHub Mirror
    steps:
      - !PushRepository
        remoteUrl: https://github.com/DimitriGeelen/workflow-designer.git
```

**Zero test invocations. No `!CommandStep`, no script step at all.** Triggers are
`BranchUpdateTrigger` on `'**'` and `TagCreateTrigger` on `'**'` — so every push
runs the mirror and nothing else.

The consequence for this leg: the 48 green results in §1 are a snapshot I took
by hand on 2026-09-21. Nothing in this repository has ever recorded them, and
nothing will notice when they stop being true. **The suite is not a regression
gate; it is a thing a person can choose to run.** That is the same shape the
suite itself names as PL-161 (§5.3) — applied one level up, to the whole suite.

### 8.2 — What I expected to find and did NOT

- **Unrunnable suites.** I expected browser- or server-dependent suites to be
  CANNOT-RUN in a headless sandbox. Zero were. The CDP infrastructure
  (`tools/_cdp-attach.mjs` and ~20 drivers) works, and `test_designer_render.py`
  stands up its own `http.server` in-process (`import http.server, socketserver,
  threading`) rather than needing an external one.
- **Failing suites.** I expected DG-8's UNKNOWN to be hiding red. It was not.
- **Repo mutation by tests.** I expected at least one suite to write into the
  tree. None did — `git status --porcelain` was byte-identical before and after
  (`NO_REPO_MUTATION`). The `tools/_tNNN-*-teeth.py` mutation scripts all
  operate on temp copies.
- **A `tests/README`** explaining how to run the suite. Absent. The only way to
  learn that `tests/run-bridge-tests.sh` is the entry point is to read it.

### 8.3 — A confound I introduced, and the correction

I must record this because it produced results that looked like findings.

At one point **two `run-bridge-tests.sh` processes were running concurrently**
(a 600s-bounded run and a 1500s-bounded run, both writing
`/tmp/tb/bridge-full.out`). That contaminated run reported three `[FAIL]` legs:

1. `T-566` — `_t566-note-field-teeth.py`: *"control: unmutated source passes all
   six legs — rc=2 failing=['disclosure', 'disclosure-readonly',
   'multiline-roundtrip', 'note-field', 'note-reads', 'note-writes']"*
2. `T-451` — *"the unwired-guard backlog MOVED"*
3. `T-508/G-015` — *"a NEW G-015 carrier appeared in a task's `## Verification`
   block"*

Run standalone immediately afterwards, on the same tree:

| Leg | Standalone command | Result |
|---|---|---|
| `_t566-note-field-teeth.py` | `timeout 90 python3 tools/_t566-note-field-teeth.py` | **rc=0, "4 passed, 0 failed", control PASSES all six legs** |
| `verification-hygiene.py` | `timeout 90 python3 tools/verification-hygiene.py` | **rc=0** ("RATCHET AVAILABLE" notice, not a failure) |
| `_t451-unwired-guard-census.py` | `timeout 90 python3 tools/_t451-unwired-guard-census.py` | **rc=0** |

The three `[FAIL]`s did not reproduce. **Both data points are recorded here side
by side rather than reconciled**, because what the artifact reveals is more
useful than the artifact:

I checked the obvious shared-state mechanisms and **ruled them out**:

- `tools/_t566-note-field-teeth.py:101` uses `tempfile.mkdtemp(prefix="t566-teeth-")`
  — unique per run, no shared scratch.
- `tests/run-bridge-tests.sh:18` uses `TMP="$(mktemp -d)"` — likewise.
- The CDP drivers launch Chrome with `--remote-debugging-port=0` and a private
  `--user-data-dir` (`tools/_t566-note-field-cdp.mjs:145`), explicitly to avoid
  the shared browser (`tools/_autoload-verify-cdp.mjs:4`: *"ISOLATED headless
  Chromium (own --user-data-dir) — never the shared browser (G-006)"*). No port
  or profile collision is possible.
- `grep -ciE 'flock|lockfile|pidfile' tests/run-bridge-tests.sh` → **0**. There
  is no lock, but per the above there is also nothing obvious for a lock to
  protect.

What is left is **resource contention**: the failing leg drives a real headless
Chrome, and it failed only while a second full suite (with its own Chrome) was
running. That is precisely the flake shape the tree already documents at
`tests/run-bridge-tests.sh` for `test_bridge_seam_roundtrip.py` (§6.1, T-326) —
a CDP leg that *"failed once inside this runner and passed twice immediately
after."*

**So: the CDP legs are load-sensitive, and I reproduced that accidentally.** I
do not claim to have established the mechanism — `run_probe` uses
`timeout=600` (`tools/_t566-note-field-teeth.py:48`), so a plain timeout is not
the explanation and the cause remains open. The load-sensitivity of the
browser-driven legs is the durable finding; the specific fault is not
diagnosed. A clean single run is recorded in §8.4.

### 8.4 — Single clean aggregator run

Command, run alone with nothing else executing:

```
timeout 1500 bash tests/run-bridge-tests.sh
```

| Field | Value |
|---|---|
| Exit code | **1** |
| Wall clock | **742 s** (12 min 22 s) |
| Final line | `bridge round-trip: 131 passed, 7 failed` |
| Sections emitted | 104 `== … ==` banners |

Full failure list and detail in §1. Comparing against the contaminated run of
§8.3:

| Leg | Contaminated run | Clean run |
|---|---|---|
| `_t566-note-field-teeth.py` (CDP) | **FAIL** | **PASS** |
| `_t451-unwired-guard-census.py` | FAIL | FAIL |
| `verification-hygiene.py` (G-015) | FAIL | FAIL |
| `_t358-byteid-thirdparty.mjs` | not reached | **FAIL** |
| `_t527-capture-invariant.sh` | not reached | **FAIL** |
| `_t509-instrument-sweep.sh` | not reached | **FAIL** |
| `_t525-fabric-coverage-teeth.py` | not reached | **FAIL** |
| `_t560-absence-census-teeth.py` | not reached | **FAIL** |

The one leg that differed between runs is the CDP leg — which is the evidence
behind §8.3's load-sensitivity reading. The non-browser failures reproduced
exactly.

### 8.4b — A pre-existing uncommitted fixture, and a shape it shares with failure #1

`git status --porcelain` at session start (before I ran anything) already showed:

```
 M tests/fixtures/exported/t423-carrier-witness.bpmn
```

**This was NOT caused by my run** — it is in my before-snapshot and byte-identical
in my after-snapshot. It is an uncommitted export fixture sitting in the tree.
Its diff is 9 insertions / 9 deletions, and every hunk is the same move:

```diff
     <bpmn:sequenceFlow id="flow_4" name="missing" …>
-      <bpmn:conditionExpression …>${!exists}</bpmn:conditionExpression>
       <bpmn:extensionElements>
         <aef:uid value="e_04"/>
       </bpmn:extensionElements>
+      <bpmn:conditionExpression …>${!exists}</bpmn:conditionExpression>
     </bpmn:sequenceFlow>
```

`extensionElements` now precedes `conditionExpression`. That is exactly the
change named by the most recent commit on the aggregator
(`66e04cff T-690: extensionElements before conditionExpression — …`).

**Observation, offered without a conclusion:** failure #1's second drifting
fixture, `i18n-documentation.bpmn`, drifts at `<bpmn:extensionElements>` on
line 41 — the same element, the same kind of ordering move. Whether the T-690
ordering change propagated to `tests/goldens/third-party/` is a question I did
not pursue, because re-pinning goldens is a write and this leg is read-only.

### 8.5 — What this means for DG-8

DG-8 asked for the suite's pass state. The answer has three parts and all three
are needed:

1. **`tests/` alone is green.** 48/49, one timeout, zero failures.
2. **The gating runner is red.** 131 passed / 7 failed, exit 1.
3. **Nothing observes either number.** CI runs no tests (§8.1). The 7 failures
   have been sitting in a runner that takes 12 minutes and is triggered by
   nothing.

There is no artefact in the tree recording when this suite last passed. I could
not establish how long these 7 have been red — `git log` on the failing tools
would date the *code*, not the last green run, and no run history exists to
consult. **UNMEASURED, not zero.**
