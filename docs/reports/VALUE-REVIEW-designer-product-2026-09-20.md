# Value review — the Workflow Designer product (JUDGE report)

**Carrying task:** T-742 · **Scope:** option 3, the product itself (`src/`, the editor,
chain stage 1) · **Date:** 2026-09-21 · **Role:** JUDGE (classification only).

**Nothing in this report is executed or authorised.** Phase 6 requires the human to
approve item by item. RESEARCH IS NOT AUTHORIZATION.

**Inputs (closed set):** the six evidence files under
`docs/reports/VALUE-REVIEW-designer-product-2026-09-20/`. No new evidence was gathered;
no file other than this one was written.

---

## 1. Yardstick (confirmed)

Carried forward from `00-yardstick.md` and confirmed against the five evidence legs. I
did not re-derive it; I checked that nothing in 01–05 contradicts it, and one thing does
(recorded below).

**Purpose (one sentence).** `832-Workflow-designer` is the source of truth for a
dual-audience, single-file BPMN-subset editor that lets a human draw an AEF process on a
swimlane canvas and lets agents read the same file as typed, schema-validated YAML.

**Consumers.** The operator (draws processes, holds sovereignty); 999-AEF (vendors a
pinned build artefact, never a fork); agents in both repos.

**Capabilities in scope.** Authoring surface · import/export fidelity · the BPMN-subset
schema · the render/round-trip contract · the release path. Chain stage 1 only.

**Non-goals (stated, and honoured by this report).** AEF never edits its vendored copy;
`docs/standards/aef-bpmn-mapping-v1.md` Part I is frozen and not agent-editable;
`examples/aef-processes/rendered/` is a seam artefact not regenerated on agent
initiative; `build/gallery/` is never rebuilt.

**Value drivers (`policy/value-drivers.yaml` v3), used as the scoring axis in §6:**
D1 Antifragility 9 · D2 Reliability 7 · F-RECALL 6 · D3 Usability 5 · D4 Portability 3.

**One confirmed tension inside the yardstick itself, recorded not resolved.** The purpose
sentence promises agents *"schema-validated YAML."* `01 §A10` measures that the product
reads and writes **BPMN XML only** (14 `yaml` hits, all comments or path strings in demo
data) and that **no schema-validation surface exists inside the product** (11
`valid(ate|ation|ator)` hits, every one a comment or an id-validator reference).
`README.md:4` independently claims *"YAML is canonical; BPMN XML is a derived
import/export format."* So two of the yardstick's own nouns — *YAML* and
*schema-validated* — have no live surface in the thing being reviewed. This is not a
finding against the gatherers; it is the yardstick describing an intent the product has
not yet reached, and it drives findings **F-04** and **F-15**.

## 2. Data availability map (confirmed) + snapshot windows

Confirmed as stated in `00-yardstick.md`, with the corrections and additions the later
legs measured.

| Source | Status | Confirmed by | Note |
|---|---|---|---|
| Product source | **EXISTS** | 01 §top, 03 row 1 | `src/aef-workflow-designer.html`, 997,254 bytes, sha `2b448b61…`, one file |
| Test corpus | **EXISTS** | 02 §0 | 49 runners under `tests/`; the real gating set is **107 executables** (36 `tests/`, 71 `tools/`) |
| **Test pass state (DG-8)** | **NOW KNOWN — and it is two answers** | 02 §1, §8.5 | `tests/` alone: 48 PASS / 0 FAIL / 1 TIMEOUT. The gating aggregator: **131 passed / 7 failed, exit 1, 742 s.** DG-8 is closed; the answer is RED |
| CI | **EXISTS, runs zero tests** | 02 §8.1 | `.onedev-buildspec.yml`: one `!PushRepository` mirror job, no `!CommandStep` at all |
| Component fabric | **EXISTS** | 01 §D | 118 cards reference the product file; the anchor card's own `purpose` says 112 (§10) |
| Task ledger, scoped | **EXISTS** | 04 §0 | **24** active (not 23) + 173 completed = 197. Filter over-includes 39 %, under-includes 8 % — both measured |
| Git churn / authorship | **EXISTS** | 04 §1 | 144 src commits, **144/144 one author**, +11,957 / −709 |
| Ghost registry | **EXISTS** | 01 §D | 2 ghosts, 4 claims, **3 of 4 smoke-test-named**, mtime 2026-08-02 |
| Release manifest + tag chain | **EXISTS** | 03 | `dist/MANIFEST.yaml` 0.12.0; 15 annotated tags `0.1.0…0.12.0`, unbroken; tag pushed and peels correctly |
| **Product usage telemetry** | **ABSENT** | 01 §E1, 03, 04 §1, 05 §end | Re-confirmed independently by four legs. No counter, no log, no access log. **This is the binding constraint on this review** |
| Per-item coverage | **ABSENT** | 01 §F, 02 §8 | No `.coveragerc`/`.nycrc`/`coverage.py`/`c8`/`nyc`. The word "coverage" in filenames means *fabric-card* or *field-vocabulary* coverage |
| Execution traces per node | **ABSENT** | 00, 01 gap 3 | No `fw workflow run` |
| BVP realization log | **ABSENT** | 00 | `.context/audits/bvp-realization.jsonl` has never existed |
| Watchtower / served app | **EXISTS, serving 0.8.0** | 01 §top, 03 | `GET /designer/app` → 903,600 bytes, sha `cab3c751…` — byte-identical to `vendor/designer/…-0.8.0.html` |
| Gallery server (`/api/*`) | **EXISTS, not running** | 01 §top, §A6 | `pgrep -af gallery-serve` no match. Five server-backed features are hidden by their own progressive-enhancement gate on this host |
| Test-run history | **ABSENT** | 02 §8 | No `.last-test-run`, no results JSON. The age of the 7 failures is therefore **unknowable**, not zero |
| Error/telemetry surface in-product | **ABSENT** | 01 gap 5 | Parse failure is `alert()`; clipboard, autosave-quota and seam failures are bare `catch (_)` |

**Snapshot windows.** All legs sit within a 36-hour window, which is tight enough that I
treat them as one snapshot, with two exceptions noted.

| Leg | Measured | Tree state |
|---|---|---|
| 00 yardstick | 2026-09-20 | after that session's own `fw` calls and 3 commits (**pollution disclosed by the gatherer**) |
| 01 feature inventory | 2026-09-20 | `12ad8f9f` |
| 02 test baseline | **2026-09-21** | `12ad8f9f`, working tree dirty in `.context/`, `.tasks/`, plus one uncommitted `tests/fixtures/exported/t423-carrier-witness.bpmn` |
| 03 release path | 2026-09-20, **after the 0.12.0 cut at 19:00:28** | `12ad8f9f` |
| 04 ledger history | 2026-09-20/21 | `12ad8f9f`, 2265 commits |
| 05 schema fidelity | 2026-09-20 | `12ad8f9f`, `VERSION` 0.12.0 |

Two window effects that change how numbers must be read:

1. **03 measured on cut day.** `designer-v0.12.0` was tagged that afternoon, so
   `adopt_days = 0`. Had the cut not happened that day, the release-lag gate would have
   read `28 >= FAIL_DAYS` → **fail**. The green in the record is a function of *when* the
   snapshot was taken (F-02).
2. **02 measured on a dirty tree.** Three of the seven failures (`_t451`,
   `verification-hygiene`, `_t560`) assert over exactly the uncommitted `.tasks/` /
   `.context/` population. The gatherer flagged them as possibly tree-artifacts. The other
   four (`_t358`, `_t527`, `_t509`, `_t525`) do not depend on that state.

## 3. Role setup

**Separation achieved.** GATHERER and JUDGE ran as **separate sessions** with separate
contexts. The gatherers collected read-only and wrote evidence files; this JUDGE session's
inputs were closed to those six files and it gathered nothing. Per the review's ground
rules, **no separation penalty applies** to the confidence ratings in §6.

**The limitation I could not remove: both roles ran on the same model family.** Gatherer
and judge are different sessions of the same kind of system. A systematic blind spot in
how this model family reads a repository — a construct it does not think to grep for, a
class of evidence it does not think to want — is present on both sides of the separation
and is invisible to it. Session separation defends against *context contamination*; it
does not defend against *correlated method*. I state this as a standing limitation of the
review, not as a hedge on any particular finding.

**Two further constraints on what my verdicts can mean:**

- **I could not replicate a single measurement.** My inputs are closed by design, so every
  finding below inherits its gatherer's command, its parse, and its arithmetic. Where a
  gatherer recorded a self-correction (02 §8.3's contaminated run, 04 §7's two corrected
  errors, 01's `renderEdges` matcher discrepancy), I took the correction at face value
  because I had no way to test it. That is the intended cost of the role, and it caps
  nothing below HIGH — measured-by-someone-else is still the `measured` rung — but it
  means a gatherer error would propagate here undetected.
- **Nothing here is executed or authorised.** Phase 6 is item-by-item human approval. No
  finding in §6 is a licence to act, and §12 items are not findings at all.

**The human decides Phase 5.** This report classifies; it does not rule.

## 4. Baseline

What the thing *is*, as of 2026-09-21, before any judgement.

**Shape.** One HTML file, 997,254 bytes, 11,248 lines, 247 unique functions, no
`package.json`, no `Makefile`, no bundler, no external `<script src>`. Two `<style>`
blocks and one `<script>` block that runs to EOF. The single-file shape is not an
accident of convenience — it is the premise of the release path (`cp src → dist`,
determinism by construction) and of D4 Portability.

**Scale of the surface.** 93 inventoried items across 10 groups: 13 creatable node types,
13 properties sections, 19 settings controls, 9 keyboard bindings, 5 `localStorage` keys,
7 `/api/*` endpoints consumed, 7 SVG layers. 88 of 247 functions are named by something
outside the file; 159 are named by nothing outside it. Heaviest external dependence:
`buildBpmnXml` (64 files), `parseBpmnXml` (62), `refreshDisplayIds` (33).

**History.** 144 src commits over 96 days, 2026-06-05 → 2026-09-09. Monthly:
Jun 1 · **Jul 118** · Aug 24 · Sep 1. Twelve days with no src commit as of measurement.
**144/144 commits by one author.** Deletion rate 5.9 %. Zero git reverts. Zero reopened
tasks, by two independent methods. 197 tasks name the file; 183 completed, 14 in flight.

**What works, measured.** The editor is a **semantic and byte-level fixed point** on all
24 committed corpus maps — `pass: true`, every map `ok / deterministic / projEqual /
byteIdempotent`, `drift` empty (05 C1). The release script is **deterministic across a
2-second wall-clock separation**, verified in a throwaway tree (03). The tag chain is
unbroken and the tag resolves correctly. In 148 gate-bypass entries there are **zero**
`--force`, **zero** AC-gate and **zero** P-011 bypasses — every bypass is focus-drift or
inception sovereignty (04). The mutation-testing discipline is unusually strong: 14 suites
plus ~30 dedicated `teeth` legs deliberately break a feature and assert the guard goes red.

**What does not work, measured.** The gating suite exits **1** with 7 failures and takes
**742 seconds**, and **nothing runs it** — CI invokes zero tests. The bytes an operator can
actually open at `/designer/app` are **0.8.0**, four releases and ten consumer-visible
changes behind `src/`, and the one mechanical check that reads release alignment grades
that **PASS**. Two of eleven third-party byte-identity goldens **DRIFTED**. 118 instruments
read as standing guards and nothing in the tree can re-run them. Ten functions in the
product have zero references. One function (`refreshLibraryUI`) is called eight times and
returns immediately on every call.

**The measurement that is not available, and governs everything below.** There is **no
product usage telemetry of any kind**, re-confirmed independently by four legs. The only
use-shaped record found anywhere for any feature is a 4-entry ghost registry, three of
whose entries are smoke-test names, last written 2026-08-02. Consequently *every one of
the ~93 inventoried items is UNMEASURED for actual operator use*. Corpus counts (0 of 306
nodes, 0 of 24 maps) are statements about 24 files, never about users.

## 5. Summary

**22 findings: 1 DELETE · 4 REFACTOR · 14 ADD · 3 carrying no axis until measured**
(F-18, F-20, F-21 are INVESTIGATE-only; F-09 is counted in ADD as INVESTIGATE→ADD).

The shape of that split is itself the headline, and it is a consequence of the evidence
rule rather than of taste. DELETE requires positive evidence — broken when exercised, or a
recorded reason the need is gone. Across 93 inventoried items, five zero-use schema
constructs, four zero-use io types, five never-instantiated node types and ten
zero-reference functions, exactly **one** item cleared that bar. Everything else that looks
deletable is **D UNMEASURED**, and D means INVESTIGATE. Fifteen items are on the
INVESTIGATE list for that reason. If the operator wants a usable DELETE axis at the next
review, the single highest-leverage act is to install any usage instrument at all (§9).

**The product is in better shape than its surroundings.** The editor round-trips all 24
corpus maps byte-identically, the release cut is deterministic, the emitters are a
cross-repo contract with 62–64 external dependents, the in-code rationale density is high,
and the completion gates have never been bypassed. The authoring core is not the problem.

**Three systems around it are failing, and each of them fails silently.**

1. **Delivery.** The operator cannot reach the product. `/designer/app` serves 0.8.0;
   ten consecutive shipped changes are absent from those bytes (marker census, 0 hits
   each). This has cashed out before: T-293's field-failure report was *"a faithful test of
   old code"* (FP-009). The product has no version string anywhere in its UI, so the
   condition is invisible from inside; and the only mechanical reader of release alignment
   grades a four-release gap **PASS**, because its predicate discriminates on the age of
   *our own tag* rather than on the distance it prints. Cutting a release resets the
   adoption clock to zero — the act that widened the gap is the act that turned the gauge
   green.

2. **Verification.** The gating suite is red, slow, and unscheduled. Its 7 failures have no
   knowable age because no run history exists. A plurality of its legs assert on the
   agentic framework's tooling rather than on the designer (33 framework-only vs 26
   designer-only of the 71 `tools/` legs), which is also where 5 of the 7 failures live.
   The coverage that does exist is concentrated on the *seam* — parse, emit, validate,
   round-trip — and the *direct-manipulation* surface is named by nothing: click-to-place,
   node drag, connect mode, lane resize and the entire 9-binding keyboard surface have zero
   mentions across all 107 gating legs. Meanwhile 118 instruments that once verified
   exactly those features sit in `tools/` with no caller.

3. **Contract fidelity.** The frozen standard says a conformant editor MUST emit four
   governance meta-keys; two of them (`horizon`, `workflowType`) appear on **0 of 306**
   corpus nodes — and the conformance test passes, because it compares *key lists* and
   never opens a document. `docs/designer/schema.md` is stale by nine shipped feature
   tasks, declares a ten-element subset against a twelve-entry palette, and contradicts the
   frozen standard on whether `aef:endpoint` is semantic or presentational. Twenty-three
   authored `decisionOutputs` values ride in the corpus of which 17 can be neither seen nor
   edited in the panel — the third recorded instance of "authored values the panel could
   not show" after T-566 (305 values) and T-618 (215 values).

**The common mechanism across all three.** In every case the instrument that should have
reported the condition is either absent, unscheduled, or itself the broken thing. A green
check over a false condition appears three times independently — the release-lag PASS
(F-02), the conformance test's list-membership assertion (F-06), and the meta-parity
suite's own documented 47-day false green (02 §5.1). The repo names this class itself
(PL-034, PL-161, PL-178, PL-205) and names it accurately. **The remedy in every case is a
truer check, never a weaker one**, and no finding below recommends relaxing any gate.

**What I am not saying.** Nothing here says the unused schema constructs are unwanted, that
the quiet layout engine is finished, or that the parked tasks are abandoned. With zero
telemetry, silence is not evidence. Fifteen items go to §8 with a named instrument
attached, because the honest output of this review is a measurement plan, not a cull.

## 6. Findings table

**Ranked by consequence, not by ease of action.** Consequence = what it costs the
yardstick's drivers if left as-is, weighted D1 9 · D2 7 · F-RECALL 6 · D3 5 · D4 3.

Non-use readings: **A** BROKEN · **B** NEVER WIRED · **C** UNDISCOVERABLE ·
**D** UNMEASURED · **E** NOT WANTED. A, B and C mean the thing was never given a fair
trial. **D never justifies DELETE.**

### Index

| id | item | axis | reading | confidence |
|---|---|---|---|---|
| F-01 | Served bytes are four releases behind src (SERVED-GAP) | ADD | C | HIGH (measured) |
| F-02 | Release-lag gate leg 2 grades a four-release gap PASS | ADD | A | HIGH (measured) |
| F-03 | The gating suite is RED, 742 s, and nothing schedules it | ADD | — | HIGH (measured) |
| F-04 | In-editor schema validation is ABSENT; T-309 fully ticked, parked | ADD | B | HIGH (measured) |
| F-05 | No error or telemetry surface anywhere in the product | ADD | — | HIGH (measured) |
| F-06 | Corpus emits 0/306 on two frozen MUST keys; the conformance test cannot see it | ADD | — | HIGH (measured) |
| F-07 | The direct-manipulation surface is named by no gating leg | ADD | — | HIGH fact / MEDIUM inference |
| F-08 | 118 instruments read as standing guards with no live caller | ADD | B | HIGH (measured) |
| F-09 | Third-party byte-identity: 2 of 11 goldens DRIFTED | INVESTIGATE→ADD | A (unresolved) | HIGH fact / LOW cause |
| F-10 | No product version string renders anywhere in the UI | ADD | — | HIGH (measured) |
| F-11 | 23 authored `decisionOutputs` in the corpus, 17 unreachable in the panel | ADD | C | HIGH (measured) |
| F-12 | The designer's gate spends a plurality of legs on framework tooling | REFACTOR | — | HIGH (measured) |
| F-13 | Waypoint authoring is half-built and unwired while T-599 asks for it | ADD | B | HIGH fact / MEDIUM link |
| F-14 | `docs/designer/` frozen 2026-07-04; README promises two absent surfaces | REFACTOR | C | HIGH absence / MEDIUM reading |
| F-15 | `docs/designer/schema.md` contradicts the implementation in four places | REFACTOR | — | HIGH (measured) |
| F-16 | `bin/fw:1467` pin↔vendored drift check never fires and says nothing | ADD | B | HIGH (measured) |
| F-17 | `refreshLibraryUI`: inert body, 8 live callers, element retired on purpose | DELETE | E + B | HIGH (measured) |
| F-18 | Five palette types and 15 keys are never present in the corpus | INVESTIGATE | D | HIGH fact / D caps verdict |
| F-19 | `embed-fonts.py` output parity with `src/` is asserted by nothing | ADD | B (by design) | MEDIUM (measured absence) |
| F-20 | The release rail's own history does not persist | INVESTIGATE | — | MEDIUM (observed) |
| F-21 | Nine orphan functions: zero refs, no gating leg, no recorded reason | INVESTIGATE | B | HIGH fact / D caps verdict |
| F-22 | `rendered/README.md` asserts a provenance the tree contradicts | REFACTOR | — | HIGH (measured) |

---

### F-01 · Served bytes are four releases behind src · **ADD** · consequence 1

- **Evidence.** `01 §top` (SERVED-GAP), independently re-measured from `00 §Contradiction`
  and again in `03`. `GET /designer/app` → 903,600 bytes, sha `cab3c751…`, byte-identical
  to `vendor/designer/aef-workflow-designer-0.8.0.html`; `src/` and
  `dist/aef-workflow-designer-0.12.0.html` are both 997,254 bytes, sha `2b448b61…`. Marker
  census on the served bytes: `T-618` 0/2, `T-600` 0/3, `T-602` 0/2, `T-603` 0/3,
  `T-589` 0/5, `T-566` 0/6, `T-570` 0/8, `T-423` 0/5, `T-598` 0/1, `T-690` 0/2 —
  **ten consecutive shipped changes absent.** `03` dates it: the pin has 2 commits total,
  last `405a39d9` 2026-07-29 — **53 days, 4 releases, no re-pin.**
- **Reading: C UNDISCOVERABLE**, on the strongest evidence in the review (`01 §E5`). The
  ten features cannot be discovered by an operator on the served surface **because they
  are not there.** Not A: each shipped with a probe. Not B: all are wired in `src/`.
  Not E: `designer-pin.yaml:1-20` describes re-pin as the standing contract.
- **Value.** D2 Reliability 7 — this has already produced a false defect report:
  `T-293:349-355` records *"The 'field failure' was a faithful test of old code"*, and
  FP-009 is the healing pattern that came out of it. D1 Antifragility 9 — a failure the
  system cannot learn from because the report is about bytes nobody ships. F-RECALL 6 —
  every server-backed recall feature the operator could reach is the 0.8.0 version of it.
- **Cost of keeping.** Every field report against `/designer/app` is untrustworthy until
  the build is identified. Ten shipped fixes deliver zero operator value. The cost is not
  the re-pin — `fw designer sync --from-tag` exists, is routed at `bin/fw:4258`, and ran
  cleanly once. The cost is that nothing tells anyone the gap is open.
- **What I recommend (ADD, not the re-pin).** There is **no check anywhere that joins the
  served bytes to `dist/MANIFEST.yaml latest`** (`03 §ABSENT`, verified across `audit.sh`,
  `bin/fw doctor`, `tools/`). The release-lag probe joins src↔dist↔pin and never pin↔served.
  Add that join. **The re-pin decision itself is sovereign (peer-pinned artefact) → §12 Q1.**
- **Confidence: HIGH · rung `measured`.** Three independent legs, sha256 on both sides.
- **What would change the call.** A recorded decision that the local serve is *deliberately*
  held at 0.8.0 (e.g. pinned for consumer-parity testing). None was found by any leg.

### F-02 · The release-lag gate grades a four-release gap PASS · **ADD** · consequence 2

- **Evidence.** `03 §The PASS`, which reads the predicate and then drives it. `verdict()`
  in `tools/_t382-release-lag.py` escalates on `adopt_days` — **the age of our own latest
  release tag** — while `adopt_behind` (`"0.8.0 -> 0.12.0"`, the only value carrying the
  distance) is used **exclusively to build a message string and never enters a
  comparison.** Driven on constructed inputs: peer 4 behind + our tag 0d → **ok**; peer 3
  behind + tag 28d → **fail**; peer **11** behind + tag 0d → **ok**. `WARN_DAYS 7`,
  `FAIL_DAYS 14`; `designer-v0.12.0` was tagged that day, so `adopt_days = 0`. The probe
  prints `peer pin behind (0.8.0 -> 0.12.0)` and grades it `OK`. `audit.sh:2251-2268`'s
  exit-0 arm then prints a **hardcoded** "in step" and discards the probe's reasons; the
  peer-pin line `_l2` is shadowed by `_l1` in every warn arm.
- **Reading: A BROKEN**, evidenced at the predicate level, not inferred from silence. Also
  C: the fact is printed by the probe and invisible in the saved audit record.
- **The compounding defect.** `teeth()` leg 5 sets `adopt_behind` **only** with
  `adopt_days: 99`. **No teeth leg constructs the live shape** (`adopt_behind` set, small
  `adopt_days`). The self-test passes over exactly the configuration production reports.
- **The channel cannot report its own failure.** The audit is the only mechanical reader of
  release alignment in this repo, and it is the thing that is wrong. Its 11 consecutive
  cron records that morning read `EXCEEDED`; the record flipped to PASS **at the cut**.
  There is no out-of-band observer, so its silence is not evidence of health.
- **Value.** D1 Antifragility 9 — a green check over a false condition actively suppresses
  the signal; it is worse than no check. D2 Reliability 7. G-024 (`watching`, high) already
  names the need for a *standing, visible* delta.
- **Cost of keeping.** The gauge cannot report an adoption problem for 7 days after any cut,
  and any new cut restarts that window — so the condition can be held green indefinitely by
  the ordinary act of releasing.
- **What I recommend.** Make leg 2 discriminate on the distance it already computes, and add
  the missing teeth leg. **Never remove or relax the check** — the remedy for a false green
  is a truer predicate.
- **Confidence: HIGH · rung `measured`** (source read + predicate driven on inputs).
- **What would change the call.** A recorded ruling that adoption lag is deliberately
  measured from our own tag age. `03` found none; G-024's trigger text names three
  quantities for leg 1 and gives the adoption leg no equivalent standing.

### F-03 · The gating suite is RED, takes 742 s, and nothing schedules it · **ADD** · consequence 3

- **Evidence.** `02 §1`, `§8.4`, `§8.1`. One clean end-to-end run: `bridge round-trip:
  131 passed, 7 failed`, **exit 1**, **742 s**, 104 section banners. Under the brief's
  `timeout 90` it cannot complete at all (exit 124, 35 banners). CI is
  `.onedev-buildspec.yml` with **one `!PushRepository` job and no command step of any
  kind.** No `.github/workflows/`, no `Makefile`, no `package.json`, no `tests/README`.
  **No test-run artefact exists anywhere in the tree**, so the age of the 7 failures is
  unknowable — `02 §8.5`: *"UNMEASURED, not zero."*
- **Reading: n/a** (this is a condition, not a low-use item). The suite is not unused; it is
  unrunnable-by-anything-but-a-person.
- **Value.** D1 Antifragility 9 — this is the mechanism by which every other finding stays
  undetected. D2 Reliability 7. G-044 (`watching`, high) states it independently: *"The only
  place 5 gating guards are evaluated is a 13-minute suite nothing schedules."*
- **Cost of keeping.** 742 s × manual invocation = effectively never. The repo's own name
  for the class is PL-161, quoted from its own runner: *"a completion gate is not a guard,
  and the only durable remedy is a caller that re-executes without a task completing"* —
  and the runner records that the same mistake was made twice.
- **What I recommend.** A caller that re-executes on a schedule, plus an exit-trap that
  appends the summary line and exit code to a run-history file (that file's absence is why
  F-09's age is unknowable). Splitting the runtime is **F-12**, and is a prerequisite for a
  schedule anyone will tolerate. **Do not shorten the suite by removing legs.**
- **Confidence: HIGH · rung `measured`** (exit codes, wall clock, buildspec read in full).
- **What would change the call.** An external scheduler outside this repo that runs it. `02`
  looked for one and the buildspec is the only CI artefact present.

### F-04 · In-editor schema validation is ABSENT; T-309 is fully ticked and parked · **ADD** · consequence 4

- **Evidence.** `01 §A10`: `grep -icE "valid(ate|ation|ator)"` over the product → 11 hits,
  **every one a comment or an id-validator reference.** No `btn-validate`, no error list,
  no per-node error decoration. The validator exists only as `tools/validate-workflow.py`,
  outside the product. `01 gap 1`: `README.md §Status` names *"schema validation tooling for
  produced workflow files"* as the next planned slice — README last touched 2026-06-05,
  **107 days.** `04 §3`: the `validator surfacing` area has **5 tasks, 0 src commits, 0
  churn, last src commit "never."** `04 §5.1`: T-309 *"Surface workflow validator findings
  in the designer"* is `started-work`, `horizon: later`, open since 2026-07-29 — with
  **agent 3/3 and human 1/1 ACs ticked**.
- **Reading: B NEVER WIRED**, positive: zero src commits were ever attributed to this area,
  so the surface was never built into the product file. **E is ruled out positively** — no
  DEFER, no NO-GO, no concern saying the need is gone, and T-309 is referenced by **6 later
  corpus tasks** (T-310, T-317, T-337, T-341, T-349, T-350): continued demand, not withdrawal.
  Carried in 396/640 handovers (61 %).
- **Value.** This is the yardstick's own agent-side promise (*"schema-validated"*, §1) and a
  documented README commitment. D2 Reliability 7, D3 Usability 5, D1 9 (a human drawing in
  the editor currently gets **no schema verdict at all** — the only hard rejection in the
  entire product is the workflow-id regex).
- **Cost of keeping (the absence).** Every schema defect is found downstream by a CLI, by a
  consumer, or not at all. It is the largest capability gap against the stated purpose.
- **What I recommend.** ADD the surface. **Never REFACTOR** — there is nothing there.
  T-309's own state (all ACs ticked, still open) is a task-system question → §12 Q10.
- **Confidence: HIGH · rung `measured`** (grep census + 0 src commits + AC parse).
- **What would change the call.** A recorded decision that validation belongs only in CI.
  Two legs searched for one and found none.

### F-05 · No error or telemetry surface anywhere in the product · **ADD** · consequence 5

- **Evidence.** `01 gap 5` and `§F`: parse failure is
  `alert('Failed to parse workflow file:…')` — a modal with no structured error surface.
  Clipboard failure is a swallowed `try/catch` — **silent**. Autosave quota/serialization
  errors are *"swallowed by design."* Annotation-seam failures are bare
  `catch (_) { /* seam must never break the editor */ }`. `grep` for any telemetry emission
  returns nothing beyond the `postMessage` seam, which reports *structure* (a uid list), not
  use. Re-confirmed independently by `03`, `04 §1` and `05 §end`.
- **Reading: n/a** — this is the *cause* of every other item's D reading. `01 §E1` states it:
  *"This is the structural reason every item here is UNMEASURED."*
- **Value.** D1 Antifragility 9 is the highest-weighted driver, and its definition is
  *"failures are learning events."* A bare `catch (_)` is the precise inverse: a failure
  that cannot become a learning event because nothing records it happened. D2 Reliability 7
  requires *"no silent failures"* by name.
- **Cost of keeping.** It caps this entire review. Fifteen items go to INVESTIGATE rather
  than to a verdict solely because no instrument exists, and the DELETE axis has one entry
  instead of a considered set. It also means an operator hitting a clipboard or quota
  failure sees nothing at all.
- **What I recommend.** ADD the smallest honest instrument: turn the bare catches into a
  recorded, operator-visible condition, and add a use counter. §8 item 3 names a concrete
  minimal shape. **This is the single highest-leverage ADD in the report** because it
  unlocks the axis the review could not use.
- **Confidence: HIGH · rung `measured`** (four independent legs, grep + source read).
- **What would change the call.** Nothing in-repo; the operator may hold that an editor
  should stay silent. That is a legitimate ruling, and it would mean accepting that
  non-use can never be distinguished from non-discovery here.

### F-06 · The corpus emits 0/306 on two frozen MUST keys, and the conformance test cannot see it · **ADD** · consequence 6

- **Evidence.** `05 D1`: `docs/standards/aef-bpmn-mapping-v1.md:55` — *"A conformant editor
  MUST emit each on task-like nodes, and the bridge MUST round-trip each."* Corpus totals by
  independent grep: `tier` 74 occ / 14 files ✓, `agentType` 17 / 7 ✓, **`horizon` 0 / 0 ✗,
  `workflowType` 0 / 0 ✗.** Zero of 306 nodes.

  > **CORRECTION (T-809, 2026-09-22) — this finding UNDERSTATED the gap, and the two ✓s
  > above are wrong.** Those are *occurrence* and *file* counts, and the MUST is
  > *per task-like node*, so they cannot answer it. Re-measured by parsing the XML
  > (`tools/_t809-frozen-meta-census.py`) rather than grepping — `tier` appears in prose and
  > in unrelated attribute values, which is what inflated it:
  >
  > | key | nodes carrying it | |
  > |---|---|---|
  > | `horizon` | 0/165 | ✗ |
  > | `workflowType` | 0/165 | ✗ |
  > | `tier` | 74/165 (44.8%) | **✗ — marked ✓ above** |
  > | `agentType` | 17/165 (10.3%) | **✗ — marked ✓ above** |
  >
  > **All four are short, not two.** The "306 nodes" figure was also the count of
  > `aef:position` elements, not of task-like nodes; there are **165**. The finding's
  > conclusion is unchanged and its recommendation stands — the check is the finding — but
  > the corpus is further from §2 than this paragraph said. `05 D2`: `tests/test_mapping_standard_
  conformance.py` prints *"OK: all 4 frozen governance meta-keys … present in both editor
  metaKeys and bridge META_KEYS"*, **exit 0** — it compares **key lists**, not emitted
  documents; **neither it nor `test_editor_bridge_meta_parity.py` opens a corpus map.**
  `05 §ABSENT`: no test in `tests/` opens `examples/aef-processes/rendered/` to assert the
  frozen keys are emitted. `05 §1` confirms the absence is at the **source** — a *fresh*
  bridge render of the canonical YAMLs also emits zero.
- **Reading: n/a for the keys** (they are standard-mandated, not candidate features);
  the *check* is the finding.
- **Value.** D2 Reliability 7 and D1 9. This is the second independent instance of a green
  check over a false condition, and the repo has already documented the first at length:
  `test_editor_bridge_meta_parity.py` ran green for **47 days** while nine keys were
  destroyed on every save, and its own docstring now says *"check() returned [] the entire
  time, because check() was never looking (PL-034)."* The same file warns that **today's**
  claim is not held by its own assertion: *"revert the carriage and the ⊆ assertion below
  goes green again while nine keys die on every save."*
- **Cost of keeping.** The frozen standard's §2 MUST is unenforced by anything mechanical.
- **What I recommend.** ADD a corpus-level conformance check that opens the documents and
  asserts the frozen keys on task-like nodes, with a teeth leg. **Do not weaken §2 to make
  the corpus conformant** — whether the corpus must comply or the standard should change is
  **sovereign → §12 Q3.** The check is mine to recommend; the ruling is not.
- **Confidence: HIGH · rung `measured`** (grep census + test executed, exit 0 observed).
- **What would change the call.** A ruling that §2's MUST binds the *editor's capability*
  rather than the *emitted document*. The standard's wording (*"MUST emit … on task-like
  nodes"*) reads against that, but it is the operator's text to interpret.

### F-07 · The direct-manipulation surface is named by no gating leg · **ADD** · consequence 7

- **Evidence.** `02 §4.1`: 18 inventoried items have **zero mentions across all 107 gating
  executables**, including **click-to-place**, **node drag/move**, **connect mode**,
  **lane add/delete/reorder/resize**, **pool resize**, **per-segment routing nudge**,
  **snap guides**, **label fitting**, the **orthogonal routing engine**, **file-picker
  import**, **save→download**, **XML view/copy**, the **settings dialog**, and **the entire
  9-binding keyboard surface**. `02` states the shape precisely: *"The covered set is
  overwhelmingly seam behaviour… The uncovered set is overwhelmingly direct manipulation…
  The suite tests the file format far more than it tests the editor."* Ten more items are
  covered by exactly one leg (`02 §4.2`). Corroborated independently by `04`: G-003
  (`watching`) — *"Editor pointer-interaction paths have zero trusted-input test coverage —
  2 field-found bugs in one day"* — and by the coupling gradient, `100 %` of import/parse
  src commits carried a test change against **`0 %`** for labels & text fit and **18 %** for
  layout/routing.
- **Reading: n/a** — a coverage gap, not a use question.
- **Value.** D2 Reliability 7, D3 Usability 5. These are the gestures that *are* the editor;
  a regression in click-to-place is invisible to 138 green legs.
- **Cost of keeping.** Two field-found pointer bugs in one day is the recorded price
  already paid. The suite's 131 passes create confidence the coverage does not support.
- **What I recommend.** ADD manipulation legs. The infrastructure is not the obstacle: `02
  §2` measured that **at least 14 legs already drive real headless Chrome over CDP and every
  one passed**, and `check-corpus-node-cuts.sh` drives the editor's own
  `polylineCrossesNodes` rather than re-implementing geometry.
- **Confidence: HIGH on the fact · rung `measured`** (grep over the full 107-leg set).
  **MEDIUM on the inference** that these paths are untested — the gatherer is explicit that
  *"no leg names it"* is strictly weaker than *"untested."*
- **What would change the call.** A leg that exercises these gestures without naming them by
  the greppable identifiers used. `02` chose per-item identifiers precisely to bound this,
  and §8 item 6 names the mutation run that would settle it.

### F-08 · 118 instruments read as standing guards and nothing can re-run them · **ADD** · consequence 8

- **Evidence.** `02 §4.4`, from `tools/_t451-unwired-guard-census.py` — itself a gating leg,
  run at exit 0. Population 322 tools; live-callable 110; **NO live caller 163**, of which
  45 are one-shot by naming convention and **118 read as standing guards**; **16 are never
  referenced by any task at all.** Named, with the last task that ran them:
  `_cdp-attach.mjs`, `_autoload-verify-cdp.mjs`, `_autosave-verify-cdp.mjs`,
  `_edge-straighten-verify-cdp.mjs`, `_endpoint-overlap-verify-cdp.mjs`,
  `_horizontal-spacing-verify-cdp.mjs`, `_align-distribute-diag.mjs`,
  `_t263-save-target-cdp.mjs` — all **NO CALLER ANYWHERE**; `_save-api-verify.mjs` (T-129),
  `_saveproject-verify-cdp.mjs` (T-130), `_selection-align-verify-cdp.mjs` (T-134).
  The census states its own limit: **110 of 237 referenced tools (46 %) have no
  executable-code edge at all** — *"their WIRED verdict rests entirely on prose."*
- **Reading: B NEVER WIRED** for the guard *function*, with positive evidence and a
  recorded mechanism. These are not abandoned probes — they are coverage that **was
  written, ran once at task completion, and was never wired to anything that re-runs it.**
- **The join that makes this consequential.** Cross-referenced against F-07: *Save to
  project*, *Open project browser*, *Align/Distribute* and *Autosave restore* show 0–1 hits
  in the gating set — **and the instruments that once verified exactly those features are in
  this list.** The coverage exists. It is disconnected.
- **Value.** D1 Antifragility 9. `04 §1` G-044 (high, `watching`) names the same shape.
- **Cost of keeping.** 215 of 331 files in `tools/` are `_`-prefixed one-offs (`04 §1`) —
  65 % of the directory is probe-per-task residue whose state is unknown. That is a real
  carrying cost in reading, searching and onboarding.
- **What I recommend.** ADD callers for the guards worth keeping — and **first run all eight
  no-caller CDP probes once** (§8 item 10), which converts "118 unknown" into a number at
  zero build cost. Retiring genuinely spent one-shots is a follow-on the operator can take
  *after* that measurement, not before it.
- **Confidence: HIGH · rung `measured`** (the census is executable and was executed).
- **What would change the call.** If the eight no-caller probes fail on today's `src/`, the
  reading on their subjects shifts from B toward **A BROKEN**, which raises F-07's priority
  sharply and changes what "wire it" means.

### F-09 · Third-party byte-identity: 2 of 11 goldens DRIFTED · **INVESTIGATE → ADD** · consequence 9

- **Evidence.** `02 §1`, failure #1 — **the only one of the seven that is about the designer
  product.** `tools/_t358-byteid-thirdparty.mjs`: *"9 identical, 2 drifted, 0 without a
  golden, 0 unusable, over 11 third-party fixtures."* The two drift **differently**:
  `bizagi-nested-ns.bpmn` on a generated `Definitions_id_…` (identity/uid derivation);
  `i18n-documentation.bpmn` at `<bpmn:extensionElements>`, line 41 (element ordering or
  emission). The tool's own header states it is designed not to false-negative on ordering.
  Independent of the dirty tree (`02 §1 caveat`).
- **The lead, recorded without a conclusion.** `02 §8.4b`: an uncommitted
  `tests/fixtures/exported/t423-carrier-witness.bpmn` — present *before* the gatherer ran
  anything — has 9 hunks, every one moving `extensionElements` **before**
  `conditionExpression`. That is verbatim the change named by the most recent src commit,
  `66e04cff T-690: extensionElements before conditionExpression`. The second drifting
  golden drifts on the same element, the same kind of move.
- **Reading: A BROKEN is live but UNRESOLVED.** Two candidate causes are equally consistent
  with the evidence: (i) the goldens are stale-by-intent and T-690's ordering change simply
  has not been propagated; (ii) the build regressed. The gatherer deliberately did not
  resolve it, because resolving it means writing.
- **Value.** D2 Reliability 7, D4 Portability 3 — third-party BPMN interop is exactly the
  portability claim. D1 9 if it is a regression.
- **Cost of keeping.** Unknown until resolved, which is why it is INVESTIGATE at consequence
  9 rather than higher or lower.
- **What I recommend.** The measurement in §8 item 1 first. **Under no circumstances re-pin
  the goldens to make the leg green** — a re-pin is only legitimate as the *recorded
  consequence of a demonstrated intended change*, and that makes it a sovereign act → §12 Q9.
- **Confidence: HIGH on the drift · rung `measured`** (tool output quoted in full).
  **LOW on the cause · rung `inferred`** — the T-690 link is a shape match, not a test.
- **What would change the call.** §8 item 1 settles it in one read-only run.

### F-10 · No product version string renders anywhere in the UI · **ADD** · consequence 10

- **Evidence.** `01 gap 4`: `VERSION` is 0.12.0 but **no version string renders anywhere in
  the product**. The T-158 comment records that the *"bare `v1` contract-version badge"* was
  **deliberately removed**; the `map-saved-version` badge that replaced it shows the **map's**
  snapshot, not the **build's** version. `01` draws the consequence itself: *"an operator on
  `/designer/app` has no in-product signal that they are on 0.8.0. This is the item that
  makes SERVED-GAP invisible from inside the product."*
- **Reading: E NOT WANTED applies to the *old* badge** (a recorded removal decision, T-158),
  and **nothing** covers the absence of a *build* version. The removal decision was about a
  contract-version badge; it did not rule on build identity. Both recorded, not merged.
- **Value.** D2 Reliability 7 — a defect report that cannot name the build is nearly
  worthless, and F-01 shows this has already happened once (FP-009). D3 Usability 5.
- **Cost of keeping.** Low in isolation; high in combination with F-01 and F-02. Three
  independent instruments for "which build am I on?" are absent, broken, or mute.
- **What I recommend.** ADD a build-version readout. Cheapest genuine fix in the top ten.
  Note the interaction: the fix must land in `src/`, which the operator will not see until
  the re-pin in §12 Q1 — the first change this fix makes visible is its own absence.
- **Confidence: HIGH · rung `measured`.**
- **What would change the call.** A recorded ruling that build identity must stay out of the
  UI. T-158's comment covers a different badge.

### F-11 · 23 authored `decisionOutputs` in the corpus, 17 unreachable in the panel · **ADD** · consequence 11

- **Evidence.** `05 C2`: the corpus hosts `<aef:decisionOutputs>` on **`exclusiveGateway`
  17× and `userTask` 6×**; the editor offers the field on `userTask` only, and
  `exclusiveGateway`'s list is `['determinism','decisionInput','decisionOwner','note']`. The
  exporter is type-agnostic so the values survive — *"but 17 of 23 corpus values can be
  neither seen nor edited."* `05 C4` adds the same shape for `aef:multiInstance` (3),
  `aggregation` (2), `compensates` (1), `timer` (1): read, re-emitted, byte-idempotent,
  **absent from `AEF_FIELDS` and `FIELD_META` entirely.** `05 C5`: io types `enum` (4) and
  `computed-set` (1) round-trip but the picker cannot re-select them after an edit.
- **Reading: C UNDISCOVERABLE**, and uniquely well-evidenced: these are not hypothetical
  features nobody used — they are **values a human already authored** that the surface
  cannot show. Not D: the authored values are the measurement.
- **Value.** D3 Usability 5, D2 Reliability 7 (a value you cannot see is a value you can
  destroy by accident — and this exact class already destroyed data twice). **This is the
  third recorded instance of the class**: T-566 found *305 of 714 `aef:meta` values (42.7 %)
  across 14 keys* outside `AEF_FIELDS`; T-618 found *215 authored values across 7 node types
  the panel could not show*; this is the next 23 + 7. Three instances is a pattern, and the
  pattern is that the panel's field vocabulary drifts behind the documents it edits.
- **Cost of keeping.** An operator editing `context-memory.bpmn` or `audit-process.bpmn`
  cannot review the decision semantics those maps actually carry.
- **What I recommend.** ADD panel exposure, following the T-618 precedent. More durably:
  add the *detector* — a check that every `<aef:*>` name present in the corpus appears in
  `AEF_FIELDS` or is explicitly excused. That closes the class rather than the instance.
- **Confidence: HIGH · rung `measured`** (P5 structural parse + source line cites).
- **What would change the call.** A recorded decision that gateway-hosted `decisionOutputs`
  is a bridge-only construct the editor should not expose. None found.

### F-12 · The designer's gate spends a plurality of its legs on framework tooling · **REFACTOR** · consequence 12

- **Evidence.** `02 §3.1`, classified by what each file references: of the 71 `tools/` legs
  in the gating runner — **designer-only 26, agentic-framework-only 33, both 8, neither 4.**
  `02` calls this *"the single most consequential structural fact in this leg."* Named
  examples all invoked by `run-bridge-tests.sh`: fabric-card validation, episodic-memory
  parsing, Watchtower queue tiers, BVP driver handlers, task-system governance guards —
  *"None of those exercise BPMN authoring, rendering, validation, or export. They are in
  this runner because this runner is the only thing that runs anything."* Corroborated in
  the failure list (**5 of the 7 failures are framework tooling**), in the runtime (~64 s
  for all 48 `tests/` legs vs **742 s** total), and in the commit stream (`02 §7.3`: five of
  the most recent fifteen coverage landings in the designer's runner are about worktrees,
  operator-decision queues, task ACs and tool censuses).
- **Reading: n/a** — a structural cost, not a use question.
- **Value.** D3 Usability 5, D1 9 indirectly: a 12-minute runner is a runner nobody
  schedules (F-03), and a red result that is red for framework reasons trains its reader to
  ignore it.
- **Cost of keeping.** ~11 of the 12 minutes. Plus the interpretive cost: today, "the
  designer suite is red" is true and misleading.
- **What I recommend: split, do not delete.** A designer gate that runs the 36 `tests/` legs
  plus the 26+8 designer `tools/` legs, and a framework gate that runs the rest — **every
  leg keeps running.** This is the axis-definition of REFACTOR: identical behaviour per leg,
  lower cost of ownership, and it makes F-03's schedule affordable.
- **Confidence: HIGH · rung `measured`** (per-file classification, counts, runtimes).
- **What would change the call.** If the framework legs have no other home, "move" becomes
  "create a second runner," which is more work but the same recommendation. `02` did not
  look for another home; that is a scope limit, not a contradiction.

### F-13 · Waypoint authoring is half-built and unwired while an open task asks for it · **ADD** · consequence 13

- **Evidence.** `01 §A2` and `§C`: `onAddWaypointMouseDown` has **0 call-sites and 0 bare
  references** in a 997 KB file that otherwise wires every handler explicitly, and so does
  `clearWaypoints` — while the sibling handlers `onWaypointMouseDown`, `onSegmentMouseDown`,
  `onLoopDetourMouseDown` and `onEndpointMouseDown` **are all wired**, and `e.waypoints` is
  read and written at four sites. The waypoint *model* is live; the *creation affordance* is
  not. `02 §4.3` confirms no gating leg names either function.
- **The join.** `04 §3a` records, as a conflicting signal it deliberately did not resolve:
  `.context/handovers/LATEST.md:105` currently carries **T-599 — *"Manual connector routing:
  add/remove waypoints and give the operator real control over the path"*** — at agent 0/5,
  human 0/2, and **invisible to every per-area count** because its task file does not name
  the product file. An open request for add/remove waypoints, and an unwired add-waypoint
  handler plus an unreferenced clear-waypoints function, in the same tree.
- **Reading: B NEVER WIRED**, positive evidence. **B means WIRE, not DELETE** — and here the
  demand for the wiring is on record.
- **Value.** D3 Usability 5; F-07/G-003 context (routing control is exactly the
  direct-manipulation surface nothing tests). The layout/routing area has had **zero src
  commits in 75 days** (`04 §3a`) — which reads as "settled" until T-599 is placed beside it.
- **Cost of keeping.** Two dead functions is trivial. The real cost is that T-599 will be
  scoped as new work when part of it is already written.
- **What I recommend.** ADD the wiring, scoped under T-599, **not** a deletion of the
  handlers. Note that `01 §C` measured both functions are already unreferenced in the
  **0.8.0** vendored build, so this predates the current cut.
- **Confidence: HIGH on the two facts · rung `measured`. MEDIUM on the link · rung
  `inferred`** — nothing states that T-599 intends to use these specific handlers.
- **What would change the call.** T-599's own design settling on a different mechanism.

### F-14 · `docs/designer/` is frozen and the README promises two absent surfaces · **REFACTOR** · consequence 14

- **Evidence.** `01 §E6`: `docs/designer/` last commit `fd6f26a5`, **2026-07-04**;
  `README.md` last commit **2026-06-05**; `src/` has taken **25 commits since 2026-08-02**
  and 144 in total. `grep -ci` over the user-guide and README returns **0 hits** for: Open
  project, Versions, Save to project, Pending refs, Settings, focus mode, zoom, Clean
  layout, annotation seam, autosave, determinism, note field, subProcess, Timer. `Undo` and
  `boundary` get 1 each. The user-guide's §8.3 documents *"The library"* — the surface whose
  renderer is inert (F-17). `README.md §Using it` reads in full: *"State is in-memory; Save
  downloads a `.bpmn` file."* It also promises YAML-canonical form and schema-validation-next,
  **both absent from the product** (§1, F-04).
- **Reading: C UNDISCOVERABLE for roughly everything in A6, A7, A8 and half of A3** — with
  **counter-evidence recorded side by side and not reconciled**: in-product discoverability
  is high. Every toolbar button carries a `title=`, several multi-clause; the palette has a
  `palette-hint` block; the properties empty-state and a `Tips` section restate the core
  interactions; settings rows carry hint spans. *A feature absent from the docs is not
  necessarily absent from the UI.*
- **Value.** D3 Usability 5, F-RECALL 6, and a real D2 7 component: a README that promises
  YAML canonicality and validation tooling is not stale, it is **wrong**, and it is the
  first thing a new consumer reads.
- **Cost of keeping.** Compounded by `04`'s 144/144 single-author finding: with the docs
  frozen and one committer, the only durable knowledge path is the source file's in-code
  rationale (which is genuinely dense and good — see §7).
- **What I recommend.** REFACTOR the docs to describe what exists, and **correct the two
  README claims to statements of intent** rather than of fact. No behaviour changes.
- **Confidence: HIGH on the absence · rung `measured`. MEDIUM on the C reading · rung
  `inferred`**, because of the tooltip counter-evidence.
- **What would change the call.** Any usage instrument (F-05) would separate "not documented"
  from "not found" directly.

### F-15 · `docs/designer/schema.md` contradicts the implementation in four places · **REFACTOR** · consequence 15

- **Evidence.** `05 §E`, all re-verified at HEAD: **E2** — schema.md:580 says
  `aef:decisionOutputs` is a `values="…"` **attribute** scoped to userTask; the emitter
  writes **element text** and the corpus agrees (23 element pairs, **zero** `values="`
  attributes anywhere), and 17 of 23 instances are on `exclusiveGateway`. **E3** — stale by
  **9 shipped feature tasks**: `eventError`, `eventTimer`, `eventMessage`, `eventDef`,
  `boundaryEvent`, `hostRef`, `fabricRef`, `determinism`, `sideEffect`, `horizon`,
  `workflowType` all return **0 hits**. **E4** — describes `aef:meta` as carrying **5** keys;
  the editor's `metaKeys` is **20** and the bridge's is **29**. **E5** — the `aef:link` row
  predates `workflowRef` (T-225) by two contract revisions. **E6** — declares a
  *"ten-element BPMN subset"* against a **12-entry palette**.
- **Reading: n/a** — documentation drift, measured.
- **Value.** F-RECALL 6, D3 5, D4 3. schema.md is the artefact a second engineer or a peer
  repo would read to understand the dialect; four of its statements are false at HEAD.
- **Cost of keeping.** It actively misleads. E2 in particular would cause a consumer to
  parse for an attribute that has never existed in any emitted document.
- **What I recommend.** REFACTOR: correct E2–E6 against the measured implementation. **E1 is
  excluded from this recommendation** — the `aef:endpoint` semantic-vs-presentational
  contradiction is against the **frozen standard**, and which side is right is not mine to
  decide → **§12 Q2**.
- **Confidence: HIGH · rung `measured`** (line-cited on both sides, plus corpus counts).
- **What would change the call.** Nothing for E2–E6; they are arithmetic.

### F-16 · The pin↔vendored drift check never fires, and says nothing when it doesn't · **ADD** · consequence 16

- **Evidence.** `03`: `.agentic-framework/bin/fw:1467` guards on
  `${FW_DESIGNER_PIN_FILE:-$PROJECT_ROOT/policy/designer-pin.yaml}` and `[ -f "$_dz_pin" ]`.
  In this repo `PROJECT_ROOT=/opt/832-Workflow-designer` and `policy/designer-pin.yaml` does
  **not exist** — the pin lives at `.agentic-framework/policy/`. Result:
  `bin/fw doctor 2>&1 | grep -i designer` → **no output at all, not even a SKIP.**
- **Reading: B NEVER WIRED** (in this repo), positive: the predicate is a path test against a
  path that does not exist here.
- **Value.** D1 Antifragility 9 — this is a third independent instance of *a channel that
  cannot report its own failure*, and the most literal one: a guard whose entire absence is
  indistinguishable from a pass. D2 7.
- **Cost of keeping.** It is one of the two instruments that could have caught F-01
  mechanically. Both are mute; the other (F-02) is green.
- **What I recommend.** ADD: resolve the path correctly **and make the not-applicable branch
  loud** — a silent skip is the defect, not the missing check. **Scope caveat:** `bin/fw`
  lives under `.agentic-framework/`, which the yardstick puts outside this review's scope
  (T-740's). Acting on it may belong to 999-AEF → noted in §11 and §12 Q1.
- **Confidence: HIGH · rung `measured`** (predicate read, command run, empty output observed).
- **What would change the call.** If `FW_DESIGNER_PIN_FILE` is set in some environment not
  visible to the gatherer, the check fires there. It does not fire here, which is where the
  operator works.

### F-17 · `refreshLibraryUI`: inert body, eight live callers · **DELETE** · consequence 17

- **Evidence.** `01 §A6` and `§C`: the function's first statement is
  `const picker = $('workflow-picker'); if (!picker) return;`. **No element with
  `id="workflow-picker"` exists in the file.** The function is **called 8 times and returns
  immediately every time.** The T-154 in-code comment records that the `<select>` was
  deliberately replaced by `id="btn-open-project"` as *"one unified full-corpus entry point,
  no half-populated dropdown."*
- **Reading: E NOT WANTED for the dropdown — positive, recorded, with a stated rationale —
  and B for the residue.** `01 §E3` records both separately and does not merge them: the
  *element* removal is intentional; **the eight surviving no-op call-sites are not addressed
  by that comment.**
- **Why this clears the DELETE bar when nothing else does.** The rule requires positive
  evidence: either broken-when-exercised, or *a recorded reason the need is gone*. T-154 is
  exactly that recorded reason, in the product's own source, naming the replacement. This is
  the **only** item in 93 where I found one.
- **Value of keeping: none identified.** The function cannot render anything.
- **Cost of keeping.** Small but real and specifically misleading: `docs/designer/
  user-guide.md §8.3` documents *"The library"* as a working surface, so a reader of the
  docs, a reader of the source, and the running program disagree about whether it exists.
- **What I recommend.** DELETE the inert function and its eight no-op call-sites — **after**
  the measurement in §8 item 8 confirms the call-sites carry no other intent, and together
  with the F-14 doc correction so the user-guide stops describing it.
- **Confidence: HIGH · rung `measured`** (source read, call-site count, element absence).
- **What would change the call.** If any of the eight call-sites is positioned where a
  *replacement* renderer is intended to go (e.g. the "Recently opened" section, which does
  render and is a different code path), then the correct act is to finish it, not remove it.
  §8 item 8 is written to distinguish those two.

### F-18 · Five palette types and 15 schema keys are never present in the corpus · **INVESTIGATE** · consequence 18

- **Evidence.** `05 §three-way diff`, measured two independent ways that agree. Harness
  verdict: *"36 keys / 21 LIVE / 0 BLIND / 0 DRIFT-ELSEWHERE / 0 NOT-EXERCISABLE / **15
  NEVER-PRESENT** over 24 fixtures."* The 15: `scopeOf`, `horizon`, `workflowType`, `owner`,
  `errorStatus`, `timerSpec`, `busTopic`, `workflowRef`, `targetWorkflow`, `linkId`,
  `hostRef`, `interrupting`, `eventDefKind`, `eventDefBinding`, `name`. Plus `fabricRef`,
  `links`, and four `IO_TYPES` (`number`, `ref`, `arc_id`, `object`). **5 of the editor's 12
  palette types** (`linkEventThrow`, `linkEventCatch`, `eventError`, `eventTimer`,
  `eventMessage`) instantiate **zero times across 306 corpus nodes**; the corpus uses 8 of
  ~20 BPMN element kinds.
- **Reading: D UNMEASURED, and the verdict is therefore INVESTIGATE, never DELETE.** The
  gatherer states the bound in its own words: *"0 corpus occurrences is a statement about 24
  files, not about users."* Checking the other readings on the evidence available:
  **A is ruled out** for every one — dedicated fixtures and guards exist and pass
  (`typed-events.bpmn`, `boundary-events.bpmn`, `offpage-seam.bpmn`, `bare-catch-event.bpmn`,
  `governance-key-coverage.bpmn`, and five named test files). **B is partly supported** —
  T-177's own ACs required no corpus document or consumer, by design. **C is supported for
  most** — 0 hits in schema.md / user-guide / README for the typed events, `hostRef`,
  `fabricRef`, `determinism`, `sideEffect`; the off-page connectors are the exception, with
  18 user-guide hits. **E: no positive recorded reason found for any of them**, and `05`'s
  E-search was run against `.context/gaps.yaml` / `.context/concerns.yaml`, **neither of
  which exists** — the real register is `.context/project/concerns.yaml`, which `04` did
  read (48 concerns) and also found no withdrawal. Recorded in §10.
- **Value.** Several are **named in the frozen standard as MUST or as §3 rows** (`horizon`,
  `workflowType`, the link events, the typed events) — that is the strongest intent evidence
  in the review, and it is on the seam contract. `owner` is different: its absence is the
  standard's own instruction (v1.1 removed the node-level carrier) — that one is **E with
  positive evidence** and belongs in KEEP, not here.
- **Cost of keeping.** Real but modest: panel fields, palette tiles, emitter branches and
  parse paths that no committed document exercises.
- **What I recommend.** INVESTIGATE with the instrument in §8 item 3. **Do not delete any of
  them**, and note that the standard-named ones are seam-contract items → §12 Q3/Q5.
- **Confidence: HIGH on the counts · rung `measured`.** The *verdict* is capped at
  INVESTIGATE by the D reading, not by the evidence quality.
- **What would change the call.** A usage instrument, or a consumer-side census. Either
  converts D into A/B/C/E and makes a real verdict possible.

### F-19 · `embed-fonts.py` output parity with `src/` is asserted by nothing · **ADD** · consequence 19

- **Evidence.** `03`: `scripts/embed-fonts.py` is **not called by `release-designer.sh`**
  (grep returns nothing); its only live-tree references are its own docstring and a completed
  task file. It requires a live fetch to `fonts.googleapis.com` / `fonts.gstatic.com` at
  build time. **No test asserts its output still matches the base64 block inside `src/`** —
  `03 §ABSENT` confirms the absence explicitly, and whether re-running it reproduces today's
  bytes is **UNVERIFIED** (it would need the network).
- **Reading: B NEVER WIRED — but with positive intent evidence that B is the *design*, not a
  defect.** T-176's AC reads: *"Generator committed — reproducibly re-fetches + re-embeds …
  so a future weight change is one command, not hand-edited base64."* It was never meant to
  be a build step. So the finding is **not** "wire it into the release path"; it is "the
  property it produced is unasserted."
- **Value.** D4 Portability 3 and D2 Reliability 7. `designer-pin.yaml` **advertises the
  property to consumers**: `cdn_fonts: false`, *"ZERO network on load … fully self-contained
  for air-gapped deployments. This is why bytes jumped 395178 → 826643."* That is a claim
  made to a peer repo, resting on an artefact nothing can reproduce or check.
- **Cost of keeping.** Low in bytes; the cost is that the air-gap claim is unfalsifiable
  in-repo.
- **What I recommend.** ADD a parity fixture — run the generator once with network, pin its
  output block, and assert `src/` still contains it. That converts an advertised property
  into a checked one. **Not DELETE**: a recorded design reason exists for its unwired shape.
- **Confidence: MEDIUM · rung `measured`** for the absence of the test and of the call;
  the parity itself is `UNMEASURED` by the gatherer's own statement, so no higher.
- **What would change the call.** Running it once (§8 item 7). If output already diverges,
  this rises sharply — the shipped `src/` would contain fonts the generator no longer makes.

### F-20 · The release rail's own history does not persist · **INVESTIGATE** · consequence 20

- **Evidence.** `03`: the hub topic's `cv-keys` reads `{"count":1,"entries":[{"cv_key":
  "designer-release","offset":0}]}` and decodes to the current 0.12.0 release — **the rail
  does advertise the right thing right now.** But commit `2824e6b4` (T-512) records
  announcing *"at offset 631"* and `8cd0c5d3` (T-393) *"at offset 480."* Offset 0, count 1.
  **Cause UNVERIFIED** — either the topic was reset/replaced, or the hub's log does not
  persist. Recorded side by side, not averaged.
- **Why it matters more than it looks.** `03` also records that `dist/LATEST.yaml` — the
  obvious fetchable pointer — is **ABSENT by recorded decision**, *"proposed and REFUSED by
  both sides (rail 469/471 §2)."* The rail is therefore the **sole** release-notification
  channel to the peer, by design. A sole channel whose history does not survive is a channel
  that cannot show a consumer what it missed.
- **Reading: n/a for the rail** (it is live and correct); the *history* is the open question.
- **Value.** D2 Reliability 7, F-RECALL 6, D1 9.
- **Cost of keeping.** Unknown pending the measurement; potentially "a consumer cannot
  reconstruct which releases were announced."
- **What I recommend.** INVESTIGATE via §8 item 5 before proposing anything. **Do not
  propose reinstating `dist/LATEST.yaml`** — that has a recorded two-sided refusal, which is
  precisely reading E honoured.
- **Confidence: MEDIUM · rung `observed`** (live read vs two commit-body claims; no
  mechanism established).
- **What would change the call.** The measurement. If the topic was simply replaced, this
  drops to a note.

### F-21 · Nine orphan functions: zero refs, no gating leg, no recorded reason · **INVESTIGATE** · consequence 21

- **Evidence.** `01 §C`, mechanically derived: **10 functions have zero call-sites and zero
  bare references** in the 997 KB file — `clearWaypoints`, `onAddWaypointMouseDown`,
  `currentRenderedMiddleCorners`, `findNodeByUid`, `findNodeByDisplayId`, `generateNodeId`,
  `midOfPath`, `midOfPolyline`, `nodeSideForExitDir`, `portPoint`. For several, a live
  sibling is the real path (`generateUid`; `portPointAt`/`portPointTowards`;
  `nodeSideLength`/`exitDirection`). All ten are **already unreferenced in the vendored
  0.8.0 build**. `02 §4.3`: no gating leg names nine of them; `portPoint` is named by
  `tools/_typed-events-cdp.mjs`, which **is** a gating leg — *"a dead product function is
  reachable from a green test."* `02` states plainly that **deleting them would not turn the
  suite red.** Two of the ten (`clearWaypoints`, `onAddWaypointMouseDown`) are split out as
  **F-13** because live demand exists for them.
- **Reading: B NEVER WIRED**, positive: zero references in a file that otherwise wires every
  handler explicitly. `01 §E2` checked the alternatives — **A**: no evidence (never
  exercised, so nothing can fail); **E**: *no positive recorded reason found for any of the
  ten*; **D**: applies. Origin-task intent exists for three (`portPoint` in
  `.context/episodic/T-070.yaml` and T-168; `currentRenderedMiddleCorners` in T-477 and
  `docs/reports/T-357-di-adoption.md`; `findNodeByUid` in T-364).
- **Why not DELETE, even though it is tempting and cheap.** The rule is explicit: **B means
  the thing was never given a fair trial, and points to WIRE, not DELETE.** And "the suite
  stays green" is a fact about the *coverage* (F-07 measures how thin it is), not a licence.
  Deleting on the strength of a suite that does not name click-to-place would be treating
  the absence of an instrument as the presence of a verdict.
- **Value of keeping: near zero.** **Cost of keeping: low** — a few hundred bytes and some
  reader confusion, in a file whose size is dominated by other things.
- **What I recommend.** INVESTIGATE via the mutation run in §8 item 2, and hand the result
  to the operator. My honest position: this is very likely dead code, and it is still not my
  call on this evidence.
- **Confidence: HIGH on the fact · rung `measured`.** Verdict capped at INVESTIGATE by rule.
- **What would change the call.** The mutation run plus a recorded operator intent for each.

### F-22 · `rendered/README.md` asserts a provenance the tree contradicts · **REFACTOR** · consequence 22

- **Evidence.** `05 C8`, `C9` and `§Conflicts 2`. The README says *"These files are
  generated, not hand-authored … produced from the canonical `../*.workflow.yaml`"* and *"Do
  not edit these `.bpmn` files by hand."* Against it: `bdcfbc86` (T-300) baked them **from
  editor-saved bytes**, *"regen forbidden"*; `2d33b2b0` (T-145) *"Adopt 11 editor-saved
  layouts as canonical corpus"*; `4dc64858` (T-288) and `30aeff5e` (T-298) record a
  *"rendered twin hand-edited in-dialect."* And `05 C9` measures drift running **both** ways
  — three maps carry `note=` values a fresh bridge render does not produce.
- **Reading: n/a** — a documentation statement measured false.
- **Value.** F-RECALL 6, D2 7. This README is what tells the next agent whether the files may
  be regenerated, and the yardstick's non-goals depend on getting that answer right.
- **Cost of keeping.** An agent following the README would regenerate a seam artefact the
  yardstick forbids regenerating on agent initiative — the documentation and the governance
  point in opposite directions.
- **What I recommend.** REFACTOR the README to state the actual provenance and the actual
  rule. **The underlying question — whether to regenerate and restore the 262 lost values,
  or ratify the editor-saved bytes as canonical — is sovereign → §12 Q6.** The README
  correction is independent of that ruling and should say what is true today either way.
- **Confidence: HIGH · rung `measured`** (README text vs four commit records vs a fresh-render
  diff).
- **What would change the call.** The §12 Q6 ruling changes *what the README should say*, not
  whether it is currently wrong.

## 7. KEEP list (names only)

Named, not argued. These carry no finding and should be left alone.

**Product core** — single-file, no-build delivery · `defaultLanes` (the authority model made
structural) · `buildBpmnXml` · `parseBpmnXml` · `aefExtensionXml` · `adoptImportedXml` ·
`computeEdgeGeometry` (exporter never reads render state) · `escAttr` / `escText` whitespace
escaping · T-570 generic scalar carriage · the two-identifier model (`generateUid` /
`computeDisplayId` / `refreshDisplayIds` / `displayIdOf`) · `sanitizeWorkflowId` with
fallback-as-parameter · `ownerFromAuthority` read-only derivation · the 24-map byte-level
round-trip fixed point.

**Restraint mechanisms (D1's real surface)** — `laneProvenance` (records without deciding) ·
`sessionAuthoredLinks` (refuses to invent a carrier) · `foreignTag` unknown-input survival ·
unlisted-key carriage · `_suppressDeepLink` precedence rule · the pan-reset on `window blur`
· the annotation seam's `catch (_)` isolation · the seam's `window.parent`-only origin policy
with its tightening condition recorded · `readDocComment` / `safeCommentData` producer-identity
gating.

**Deliberate absences and retirements with recorded reasons** — the `DI_TRAILER` else arm
(unreachable, AEF's ruling behind it) · the retired `⁙ Align columns` / `↔ Distribute evenly`
buttons with their functions retained for Clean/import/bake · node-level `owner` as an emitted
attribute (removed by the standard at v1.1, sovereign GO `2aadc1e2`) · `dist/LATEST.yaml`
absence (refused by both sides, rail 469/471 §2) · `examples/aef-processes/rendered/` not
regenerated on agent initiative · `build/gallery/` not rebuilt.

**Verification discipline** — the "teeth" convention (14 suites + ~30 dedicated mutation legs)
· SKIP-not-PASS assertions in `test_t312` / `test_t313` / `test_rule_dialect_axis` ·
`test_t316_runner_orphans.py` · `test_dead_leg_census.py`'s raw-scan hazard demonstration ·
`report_failed_leg`'s evidence-preservation rule · isolated Chrome per CDP probe (G-006) ·
`NO_REPO_MUTATION` (no suite writes into the tree).

**Release path** — `release-designer.sh` determinism (verified across a wall-clock gap) · the
G-007 immutability guard · the render gate's position before the manifest write ·
`RELEASE_SKIP_RENDER_CHECK` being stderr-loud · the annotated 15-tag chain · the rail cv-key
announcement · `fw designer sync --from-tag` (implemented, routed, proven once).

**Process facts worth protecting** — zero `--force`, zero AC-gate and zero P-011 bypasses in
148 entries · zero reopens and zero git reverts · the in-code rationale density (the commit
messages and comments are doing the work the frozen docs are not) · tooltips, `palette-hint`,
`Tips` and `settings-hint` in-product discoverability.

## 8. INVESTIGATE list + the data needed

Fifteen items. Each names a **specific instrument**, not a wish. Read-only unless stated;
none is authorised by this report.

| # | Question | The measurement that settles it |
|---|---|---|
| 1 | **F-09** — are the 2 drifted third-party goldens stale-by-intent (T-690 ordering) or a regression? | Check out `src/aef-workflow-designer.html` at the commit **before** `66e04cff` into a throwaway tree; run `tools/_t358-byteid-thirdparty.mjs` against the **unchanged** `tests/goldens/third-party`. If `i18n-documentation.bpmn` goes identical, the drift is T-690's intended ordering move; if it still drifts, it is a separate fault. Repeat for `bizagi-nested-ns.bpmn` — a `Definitions_id_…` difference points at uid derivation, not ordering, and would need a second bisect. **No golden is written.** |
| 2 | **F-21** — are the nine orphan functions genuinely dead? | In a throwaway copy of `src/`, remove each individually; run the full gating runner **plus** `tools/_roundtrip-serialization-cdp.mjs` over the 24 corpus maps **plus** the release render gate. Record which turn anything red. Green licenses nothing by itself (F-07 measures how thin the suite is) — it is input to an operator decision. |
| 3 | **F-18, F-05** — which editor capabilities are actually used? | The minimal honest instrument: a `localStorage['aefUsage']` histogram keyed by `data-create` type placed, by `AEF_FIELDS` field edited, and by toolbar button pressed, with a one-line dump in the XML panel. One operator-week converts **D UNMEASURED** into a real reading for all 93 items. Server-side alternative that does not touch the product: log one line per `/api/save` in `tools/gallery-serve.py` and diff successive versions to attribute which constructs were authored. |
| 4 | **F-03, F-09** — how long have the 7 failures been red? | Append `summary-line + exit-code + timestamp + HEAD` to `.context/audits/test-runs.jsonl` from `run-bridge-tests.sh`'s exit trap, and schedule the runner. The age is unknowable **today** precisely because this file has never existed; one week of it gives the first true date and every week after gives a trend. |
| 5 | **F-20** — was the rail topic reset, or does the hub not persist? | `termlink channel_state_since` / `channel_snapshot` on the DM topic at two timestamps ~24 h apart, plus a re-read of the topic id recorded in `2824e6b4`'s commit body against the topic id live today. Two topic ids ⇒ replaced; one id with a moving-then-truncated offset ⇒ non-persistence. |
| 6 | **F-07** — is the direct-manipulation surface actually covered by anything? | Write one `tools/_manipulation-teeth.mjs` driving the real editor over CDP: click-to-place, node drag, connect, lane resize, and each of the 9 keyboard bindings, asserting state deltas. Then **mutate**: break each gesture in a temp copy and confirm the leg goes red. The mutation run — not the pass — is the measurement. |
| 7 | **F-19** — does `embed-fonts.py` still reproduce the base64 block in `src/`? | Run it once in a throwaway tree with network; diff its output block against `src/`. Identical ⇒ pin as a fixture and assert it. Divergent ⇒ the shipped bytes contain fonts the generator no longer produces, and the `cdn_fonts: false` claim to the peer needs restating. |
| 8 | **F-17** — do `refreshLibraryUI`'s 8 call-sites carry any intent beyond the early return? | In a temp copy, replace the body with a counter increment + early return; drive `tools/_editor-behavior-verify-cdp.mjs` and a manual session; read the counter. Zero ⇒ the call-sites are unreachable too and both go. Non-zero ⇒ read each firing site and decide **per site** whether a replacement renderer belongs there (e.g. next to "Recently opened", which does render). |
| 9 | **F-08** — what is the true state of the 118 uncalled guards? | Run the eight **NO CALLER ANYWHERE** CDP probes once against today's `src/`: `_cdp-attach.mjs`, `_autoload-verify-cdp.mjs`, `_autosave-verify-cdp.mjs`, `_edge-straighten-verify-cdp.mjs`, `_endpoint-overlap-verify-cdp.mjs`, `_horizontal-spacing-verify-cdp.mjs`, `_align-distribute-diag.mjs`, `_t263-save-target-cdp.mjs`. Zero build cost. Converts "118 unknown" into pass/fail, and any failure flips its subject's reading from **B** to **A**. |
| 10 | **F-01** — is the vendored 0.8.0 actually hurting the peers? | A consumer-side defect census in 999-AEF and 001-CashWeb, filtered to the ten marker tasks absent from the served bytes (T-566, T-570, T-589, T-598, T-600, T-602, T-603, T-618, T-423, T-690). **Currently blocked** — T-559 blocks 999-AEF and T-740 §11 records the peer side as unreviewed by construction. The instrument is cross-repo access the operator controls, not a command I can name here. |
| 11 | **F-11** — how many authored corpus values does the panel still fail to show? | A standing check: enumerate every `<aef:*>` element and `<aef:meta>` attribute name across `examples/aef-processes/rendered/` **and** `tests/fixtures/`, subtract `AEF_FIELDS` ∪ `FIELD_META` ∪ an explicit excuse-list, and fail on a non-empty remainder. Run it once now for the number; wire it to stop the class recurring a fourth time. |
| 12 | **F-13** — does T-599 intend to use the existing waypoint handlers? | Read T-599's ACs and design notes against `onAddWaypointMouseDown` / `clearWaypoints` / the live `e.waypoints` model. This is a scoping read, not a probe, and it costs minutes — but it decides whether T-599 is new work or wiring. |
| 13 | **F-12** — does splitting the runner actually buy the runtime? | Instrument `run-bridge-tests.sh` to time each of the 107 legs (one `date +%s%N` pair per leg, appended to the run-history file from item 4). The 742 s / ~64 s split is currently inferred from two separate measurements; a per-leg profile turns the split's payoff from an estimate into a number **before** anyone restructures the runner. |
| 14 | **F-02** — has the release-lag gate been false-green before, and how often? | Replay `verdict()` over the saved `.context/audits/cron/*.yaml` history: for each record, reconstruct `adopt_behind` and `adopt_days` from the tags that existed at that time and recompute. That yields a false-green rate for a gauge that currently has no record of its own failures. Read-only over committed audit history. |
| 15 | **F-16** — does the pin↔vendored check fire anywhere? | `FW_DESIGNER_PIN_FILE=.agentic-framework/policy/designer-pin.yaml bin/fw doctor` and observe whether the branch produces output. If it does, the defect is purely path resolution; if it still says nothing, the check body is mute as well as unreachable. |

## 9. Data gaps that capped confidence — and what closing them unlocks

Ranked by how much confidence each one cost.

1. **No product usage telemetry of any kind.** *(Cost: the most, by a wide margin.)*
   Re-confirmed independently by four legs. Because of it, **every** one of ~93 inventoried
   items carries reading **D**, and D can never reach DELETE. This gap alone is why §6 has
   **one** DELETE and §8 has **fifteen** INVESTIGATE items. **Closing it unlocks the DELETE
   axis** — and it is cheap: §8 item 3 is a histogram in `localStorage` plus a dump line.
   Until then, "nobody used it" is unsayable here, and this review refuses to say it.

2. **No error surface — the cause of gap 1.** Parse failure is an `alert()`; clipboard,
   autosave-quota and seam failures are bare `catch (_)`. Nothing records that a failure
   occurred, so there is no channel that could carry usage data even incidentally. Closing
   it turns operator-visible breakage into evidence, which is the D1 definition the drivers
   weight at 9.

3. **No test-run history.** No `.last-test-run`, no results JSON, nothing. Consequence:
   **the age of the 7 failures is unknowable**, not zero — so I cannot tell a fresh
   regression from a months-old one, and F-09's severity is genuinely undetermined rather
   than merely unresolved. Closing it (§8 item 4) also gives F-03 the trend line that would
   make "the suite is red" an actionable statement.

4. **No line or branch coverage instrument.** Confirmed absent by two legs. The strongest
   claim available anywhere in this review about product coverage is **"no gating leg names
   it"** — which the gatherer correctly flags as strictly weaker than "untested." That
   single word caps F-07's inference at MEDIUM while its fact stays HIGH. Closing it turns
   F-07 from a naming census into a measurement.

5. **The consumer side is out of reach.** T-559 blocks 999-AEF; T-740 §11 records the peer
   side as unreviewed by construction. So the most important question about F-01 — *is the
   four-release gap actually costing anyone anything?* — has no in-repo answer. Closing it
   is the difference between "the served build is stale" (measured) and "the served build is
   harming delivery" (unmeasured).

6. **No out-of-band observer of release alignment.** The audit is the only mechanical reader
   and it is the broken thing (F-02); the second instrument is mute (F-16); the product
   shows no version (F-10). Three instruments, zero signal. **Its silence is not evidence of
   health**, and I have not treated it as such anywhere in §6. Closing it means one observer
   that is not the audit.

7. **`duration_days` is corrupt.** 135 of 173 episodic records say `0`, two are negative,
   one says **−20637** (≈ −56 years). So effort, cycle time and "how long did this take"
   are unavailable for the whole corpus, and I made no cost-in-time claim anywhere. G-040
   (`watching`) records the mechanism: episodic memory is written and never read again, so a
   corrupt record is invisible from the moment it is written.

8. **The corpus is 24 files, and I kept saying so.** Every "0 of 306 nodes" and "0 of 24
   maps" in §6 is a statement about a small committed sample, not about authored reality —
   and `05` proves the sample is unrepresentative in at least one direction: the canonical
   YAMLs carry 199 `determinism` values that the rendered corpus has zero of. Closing this
   means agreeing which artefact *is* the corpus (§12 Q6).

9. **I could not replicate anything.** Stated in §3 and repeated here because it is a data
   gap, not a disclaimer: a gatherer arithmetic error would reach this report undetected.
   The three self-corrections the gatherers recorded (02 §8.3, 04 §7, 01's matcher
   discrepancy) are evidence the risk is live and evidence it is being caught.

## 10. Contradictions

Recorded side by side. **Nothing here is averaged.**

1. **Function count: 254 vs 247/248.** `00` counted 254 `function` declarations; `01`
   counted 248 declarations / 247 unique and identified `renderEdges` appearing once as a
   declaration and once inside a comment. `01` states plainly it *cannot* resolve the
   difference — *"a different matcher, not a conflict I can resolve."* Both recorded.

2. **Active corpus tasks: 23 vs 24.** The brief said 23; `04` measured 24 and identified the
   extra file as **T-742, this review's own task**, created after the brief's count. Both
   true at their own timestamps.

3. **Fabric references: 118 vs 112.** Live grep gives **118 cards**; the anchor card
   `src-aef-workflow-designer.yaml`'s own `purpose` field says *"112 tracked files reference
   it."* `01` notes they may count different denominators (cards vs tracked files) and does
   not reconcile them. Neither number is used as load-bearing in §6.

4. **The suite is green / the suite is red.** `tests/` run individually: **48 PASS, 0 FAIL,
   1 TIMEOUT.** The gating aggregator: **131 passed, 7 failed, exit 1.** Both are correct
   measurements of different populations, and `02` names the gap between them as the finding
   — seven failures are invisible to anyone who only runs `tests/`, because all seven live
   in `tools/`.

5. **`_t566-note-field-teeth.py` FAILs / PASSes.** It failed inside a contaminated run (two
   concurrent aggregators) and passed standalone immediately after on the same tree, rc=0,
   *"control PASSES all six legs."* `02` ruled out temp-dir, port and profile collisions
   explicitly and left the mechanism open, concluding only that **the CDP legs are
   load-sensitive** — a shape the tree already documents for `test_bridge_seam_roundtrip.py`
   (T-326). Both runs recorded; neither discarded.

6. **`determinism`: 199 values / 23 files, or 0 / 0.** The canonical `*.workflow.yaml`
   corpus carries 199; the rendered `*.bpmn` corpus carries zero. Both measured at HEAD.
   `05` states the unresolved question explicitly: *"Which one is 'the corpus' is a question
   this leg does not answer."* Neither is.

7. **`rendered/` is generated / `rendered/` is hand-edited.** `rendered/README.md`: *"These
   files are generated, not hand-authored … Do not edit these `.bpmn` files by hand."*
   Against: `bdcfbc86` baked them from editor saves with *"regen forbidden"*; `4dc64858` and
   `30aeff5e` record a *"rendered twin hand-edited in-dialect"*; and three maps carry `note=`
   values a fresh render does not produce. See F-22 and §12 Q6.

8. **`aef:endpoint` is semantic / presentational.** `docs/designer/schema.md:239` — *"what
   executes this step."* `docs/standards/aef-bpmn-mapping-v1.md:42-45` — Presentational, and
   the forward compile **MUST NOT** read it, and a change to it alone **MUST** be a no-op for
   the task graph. Re-verified unchanged at HEAD. Sovereign → §12 Q2.

9. **The conformance test is green / the corpus is non-conformant.** `test_mapping_standard_
   conformance.py` exits 0; `horizon` and `workflowType` appear on 0 of 306 corpus nodes.
   `05` puts it exactly: *"The test and the corpus measure different things and both are
   green/red on their own terms."* See F-06.

10. **Four numbers for one key surface.** `metaKeys` **20** · bridge `META_KEYS` **29** ·
    harness spec **36** · `schema.md`'s `aef:meta` row **5**. All four are current. See F-15.

11. **Layout/routing is settled / layout/routing has live demand.** Zero new layout tasks and
    zero src commits in that area for **75 days** (29 of 30 tasks closed). Against: T-599
    *"Manual connector routing… give the operator real control over the path"* sits in the
    current handover WIP at agent 0/5 — and is **invisible to every per-area count** because
    its task file does not name the product file. See F-13.

12. **The product is undocumented / the product is self-documenting.** Docs `grep` returns 0
    hits for 14 major features. Against, recorded by the same leg: every toolbar button has a
    `title=`, the palette carries a hint block, the properties empty-state and a `Tips`
    section restate the core interactions, settings rows carry hints. `01`: *"A feature absent
    from the docs is not necessarily absent from the UI. Both recorded; not reconciled."*

13. **The rail has one entry at offset 0 / the rail was written at offsets 631 and 480.**
    Live read vs two commit-body records. Cause **UNVERIFIED**. See F-20.

14. **The concern register exists / does not exist.** `05` searched `.context/gaps.yaml` and
    `.context/concerns.yaml`, found **neither**, and concluded its **E**-readings were
    *"under-evidenced across the board."* `04` read `.context/project/concerns.yaml` — **48
    concerns, 3413 lines** — and searched it, also finding no withdrawal reason for any
    zero-use item. **Recorded together because it changes how to read `05`:** its
    E-absences rest on a search at the wrong path, and `04`'s independent search at the right
    path reaches the same absence. The conclusion survives; the evidence for it is `04`'s,
    not `05`'s.

15. **`tools/` population: 331 vs 322; `tests/` files: 51 vs 49.** `04` counted 331 files in
    `tools/` and 51 in `tests/`; `02`'s census population is 322 `tools/*.{py,sh,mjs,js}` and
    49 runners. Different filters (all files vs executable extensions; runners vs runners
    plus other files). Recorded; neither is load-bearing.

## 11. Not reviewed

What the six evidence files could not see. This is a statement of blindness, not of absence.

**Nobody used the product during this review.** No operator session was observed, no
screenshot of the rendered editor was taken, no gesture was performed by a human. The entire
review is a reading of source, history, tests and artefacts. For a product whose primary
value claim is an *authoring surface*, that is the largest single blind spot, and it is not
closable by any amount of further reading.

**Visual and rendered correctness.** No element-level screenshot of any UI state, in any
theme, density, font or language mode, appears anywhere in the evidence. Label fitting,
de-collision, snap guides, edge routing aesthetics, focus mode and the properties panel were
reviewed as *code and call-graphs*. DOM and source measurements confirm structure; they do
not confirm what renders.

**The consumer side of the seam.** 999-AEF and 001-CashWeb were not read — T-559 blocks the
first and T-740 §11 records the peer side as unreviewed by construction. Every statement
about what the peers experience (F-01 especially) is inference from *our* bytes and *our*
commit messages, including the T-566 record that 001-CashWeb *"stopped waiting and built a
parallel read surface."* That is our account of their action, not theirs.

**Chain stages 2 and 3.** Out of scope by the operator's own selection; T-740 covered them and
is **parked unruled** at `/review/T-740`. Whatever that review concluded is not incorporated
here, and findings that touch the seam may look different beside it.

**The AEF framework itself.** `.agentic-framework/` was explicitly excluded, which makes F-16
(`bin/fw:1467`) a partial exception I flagged in-place: the evidence was gathered, the fix may
not be ours to make.

**Performance, accessibility, browser compatibility, security.** Nothing in six files touches
any of them. A 997 KB single-file app with ~250 functions and a live `postMessage` seam has an
obvious performance profile and an obvious attack surface, and neither was measured. The seam's
spoof rejection is tested (T-258) — that is one adversarial case, not a review.

**The 118 fabric cards.** Counted, never read. Their `depends_on: []` and ~190-entry
`depended_by` list with three substantially duplicating relation types were noted as a shape
and not evaluated.

**The gallery server.** `tools/gallery-serve.py` (839 lines) exposing 7 endpoints was not
running on the host and was not read. Five product features gate on it. Everything said about
them is about their *client-side* wiring.

**`build/gallery/`.** Never rebuilt by design; T-102/T-105 are blocked on mirror drift by
design. Not examined.

**The release render gate.** `release-designer.sh`'s gate did not run in the determinism probe
(the temp tree had no `tests/`, and the script said so). **Whether the render gate passes on
today's `src/` is UNMEASURED by this review** — the only evidence is T-700's own record of a
prior cut.

**Whether `embed-fonts.py` still reproduces the embedded fonts.** Requires network; not
attempted (F-19, §8 item 7).

**How long the 7 test failures have been red.** No run history exists. Stated as UNMEASURED
everywhere it matters, never as "recent."

**`docs/designer/user-guide.md` in full.** Greps only. Two hits (`boundary`, `horizon`) were
explicitly flagged by the gatherer as needing a read to know whether they refer to the feature
at all. They were not read.

**The ghost / pending-refs feature.** Four registry entries, three of them smoke-test names,
last written 2026-08-02. Counted as the *only* use-shaped record in the repo; the feature
itself was not exercised.

**`fw audit` live.** Not run — it hangs by known defect (OBS-332/OBS-358). Saved records under
`.context/audits/` were read instead, which is why F-02 rests on the probe's source and a
direct predicate drive rather than on a live audit.

## 12. Sovereign questions

Not findings, not recommendations. These touch release bytes, the frozen standard, peer-pinned
artefacts, the seam contract, value-driver calibration, or the operator's own fields — so they
are **questions, and the answers are the operator's.**

**Q1 — The pin.** `/designer/app` serves **0.8.0**; `src/` and `dist/` are **0.12.0**; ten
consumer-visible changes are absent from the served bytes; the re-pin mechanism exists, is
routed, and ran cleanly once 53 days ago. **Should the local serve be moved to 0.12.0, and if
not, what is the recorded reason to hold it?** (Related: F-16's `bin/fw` fix lives in the
vendored framework — **is that ours to change, or 999-AEF's?**)

**Q2 — `aef:endpoint`.** `docs/designer/schema.md:239` calls it *"what executes this step"*;
the frozen standard `:42-45` classes it **Presentational**, says the forward compile MUST NOT
read it, and says a change to it alone MUST be a no-op for the task graph. The corpus carries
**108 `<aef:endpoint>` elements**. **Which is correct — and does the standard change, or does
schema.md?** I corrected the other four schema.md defects in F-15 and deliberately left this one.

**Q3 — The §2 MUST.** `horizon` and `workflowType` are frozen-standard MUSTs that appear on
**0 of 306** corpus nodes, and the conformance test cannot see it. **Must the corpus comply, or
does §2's MUST bind the editor's capability rather than the emitted document?** Either answer
makes F-06's check buildable; without an answer I cannot say what it should assert.

**Q4 — Lane authority `none`.** The editor's `AUTHORITIES` has **five** values; the standard's
collapse map has **four**; the corpus uses `none` **3×** in `context-memory.bpmn`; and
`ownerFromAuthority('none')` silently returns `''` — the same as `external` — with nothing in
the standard saying so. **Add `none` to the standard, or remove it from the editor and re-lane
those three lanes?**

**Q5 — `aef:arc`.** Declared in frozen Part I `:83` and in the forward-compile standard, traced
to the T-175 strawman, mirrored by AEF-side reports — and **implemented nowhere**: zero hits in
`src/`, in `tools/yaml-to-bpmn.py`, and in the corpus. The intent is documented on **both sides
of the seam**; the implementation is on neither. **Build it, or retire it from Part I?**

**Q6 — What is the corpus?** A fresh bridge render of the same 24 canonical YAMLs carries **262
values across 8 keys** that the committed `rendered/` maps do not (`determinism` 199,
`sideEffect` 38, `advisory` 9, …). The loss is committed history caused by the pre-T-570
destroy-on-save defect plus a re-bake from editor saves; T-570 fixed the editor and cannot
restore the bytes. Drift now runs **both** ways. **Regenerate and restore, or ratify the
editor-saved bytes as canonical?** `rendered/` is a seam artefact the yardstick forbids
regenerating on agent initiative, so this is yours alone. (F-22's README correction is
independent of the answer.)

**Q7 — The `tier` default.** Part II records the canonical default as **unratified** since
2026-07-11; the corpus works around it with `<aef:workflowMeta tier_default="2"/>` on **24 of
24** processes. **Ratify the workaround, or set a different default?**

**Q8 — The AC-seed field.** Part II `:153-155` says node documentation seeds acceptance
criteria but *"the exact seed field/format is unratified."* The editor now preserves
`<bpmn:documentation>` round-trip (T-602, described in its own commit as *"a field-reported
data loss that never worked"*) but offers **no panel field**, and the corpus contains **zero**
`<bpmn:documentation>` elements. **Ratify a format, or record that the row is dormant?**

**Q9 — The third-party goldens.** If §8 item 1 shows the drift is T-690's intended ordering
change, re-pinning `tests/goldens/third-party` becomes the correct act — **and it is a write to
recorded release-adjacent evidence.** Confirming it as a value review recommendation would be
gaming the outcome, so I have not. **Will you authorise the re-pin, on the evidence, if it
comes back that way?** If it comes back the other way, the finding is a regression and the
remedy is a fix, not a re-pin.

**Q10 — The parked tasks.** **T-105** (agent 6/6, human 1/1) and **T-309** (agent 3/3, human
1/1) are **fully ticked and still in `active/`**. Ten more sit in `active/` with
`status: work-completed`, `owner: human`, **agent ACs 69/69 and human ACs 0/32**, none with an
episodic record — so `fw recall` cannot surface them, and four appear in 0–6 of 640 handovers.
Separately, T-041 has been carried in **625 of 640 handovers (97 %)** and accounts for **28 of
148 gate bypasses**, with a recorded `**Recommendation:** GO` and a single outstanding fidelity
judgement that is *"genuinely yours."* Completing human-owned tasks is not delegated, so I am
only reporting the state: **for T-105 and T-309 the cited evidence is that every AC including
the human ones is ticked; for the other ten the human ACs are genuinely unexecuted.** Which do
you want to close, and which are real outstanding verification?

**Q11 — Driver calibration.** **D4 Portability is weighted 3, the lowest** — yet it is the
premise of the single-file no-build shape, of the zero-network font embedding advertised to the
peer, and of the BPMN 2.0 output that makes the files readable by anyone. Meanwhile the corpus
ships **no `<bpmndi:BPMNDiagram>` at all** (0/24), so a stock BPMN tool opening these files gets
no diagram interchange — layout rides entirely on the `aef:` presentational class. **Is 3 the
right weight for Portability, and is DI-less output the intended trade?**

**Q12 — The operator's own field.** `laneProvenance` assigns one of four disjoint values on
every import path and is **deliberately not emitted** (T-358), recorded so that a default can be
chosen later **by you**. It has been waiting since. **Do you want to choose the default, or
should it keep recording without deciding?** I note it because "waiting for the operator" and
"forgotten" look identical from here, and only you can tell them apart.
