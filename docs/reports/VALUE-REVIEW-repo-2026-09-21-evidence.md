# Value review — evidence file (GATHERER, Phases 0–1)

**Snapshot taken:** 2026-09-21T22:01:46Z, **before** the review generated any usage data.
**Platform:** `fw` v1.6.354 (vendored), TermLink 0.11.1766.
**Role:** GATHERER only. No classification below — facts and source status.

---

## Phase 0 — snapshot (judged from these values, not from live counters)

| measure | value at snapshot |
|---|---|
| tasks active / completed | **149 / 634** |
| audit records | 77 top-level + 741 cron |
| handovers / episodic | 654 / 634 |
| observation inbox | 134 pending (46 urgent) |
| tool-counter | 5 |
| fabric cards | 394 |

## Project shape (verified)

| aspect | finding |
|---|---|
| tracked files by type | md 3207 · yaml 1915 · py 350 · sh 284 · bpmn 147 · html 98 · mjs 80 |
| build system | **none** — no package.json, Makefile, Dockerfile, pyproject, Cargo |
| CI | `.onedev-buildspec.yml` present |
| tests | `tests/run-bridge-tests.sh`, `tests/run-validator-tests.sh` |
| workflows | 147 `.bpmn` tracked, **133 carry the `aef:` namespace** |
| arcs | 3, all `in-progress`: arc-001 authoring-surface, arc-002 ewcr, arc-003 audit-remediation |

## Draft yardstick (Phase 1 — FOR CONFIRMATION, not confirmed)

Source: `README.md`, `policy/value-drivers.yaml`, `.context/arcs/*.yaml`.

1. **Purpose** — a visual BPMN-subset editor for authoring AEF workflows: humans drag and drop
   on a swimlane canvas, agents read the same file as typed, schema-validated YAML.
2. **Canonical form** — YAML is canonical; BPMN XML is a derived import/export format.
3. **Shape** — dual-audience, single-file: a self-contained HTML artifact, any modern browser,
   **no server**.
4. **Authority model** — swimlanes map to Human·Sovereignty, Framework·Authority,
   Agent·Initiative.
5. **Maturity tier** — "Stabilization" on AEF's manifest-maturity ladder.
6. **Explicit non-goal** — it is "usable today **without** the planned `fw workflow run`
   executor". Verified: `fw workflow` does not exist in this build.
7. **Consumers** — the operator; 999-AEF as seam counterparty; agents reading workflow files.
8. **Protected drivers** — D1 Antifragility 9 · D2 Reliability 7 · D3 Usability 5 ·
   D4 Portability 3.
9. **Free drivers** — F1 V_SDLC_ENABLEMENT 9 · F3 V_AEF_INTEGRATION 9 ·
   F4 V_WORKFLOW_ROUTING 9 · F-RECALL 6 · F2 V_COMPONENT_FABRIC 6.
10. **Contradiction to flag** — see below.

### Contradiction: stated purpose vs where the work actually goes

The README describes an **editor**. The repository is 3207 markdown and 1915 YAML files
against 98 HTML and 80 mjs, and two of the three in-progress arcs (arc-002 EWCR, arc-003 audit
remediation) are governance/framework work rather than the authoring surface. This is recorded
as an observation for the operator to confirm or correct, **not** as a judgement — the
yardstick is theirs to set, and "the project is now mostly governance" is a legitimate answer.

---

## Data availability map (verified against the live repo)

### EXISTS

| source | location | window / note |
|---|---|---|
| Task ledger | `.tasks/active`, `.tasks/completed` | 149 / 634 |
| Arcs | `.context/arcs/*.yaml` | 3, all in-progress |
| Handovers | `.context/handovers` | 654 |
| Episodic memory | `.context/episodic` | 634 |
| Audit history | `.context/audits` | 77 + 741 cron |
| Gate bypass log | `.context/working/.gate-bypass-log.yaml` | present |
| Component fabric | `.fabric/` | 394 cards |
| Patterns / learnings / concerns | `.context/project/*.yaml` | present |
| Value drivers | `policy/value-drivers.yaml` | 4 protected + 5 free |
| Human-AC evidence verb | `fw verify-acs` | see finding F-2 |

### ABSENT — verified, not assumed

| source the prompt expects | status | consequence |
|---|---|---|
| `policy/capabilities.yaml` (capability registry) | **ABSENT** | no systematic enumeration of verbs/skills/prompts; drift between facades cannot be measured |
| `.context/audits/bvp-realization.jsonl` (realization log) | **ABSENT** | **"did shipped arcs deliver?" is unanswerable.** Value realization is not measurable at all |
| `fw workflow` verb → execution traces by node uid | **ABSENT** | the strongest process data does not exist; confirms the prompt's own guess |
| `docs/dispatch-templates`, `agents/dispatch` | ABSENT | dispatch-template drift not measurable |
| `policy/prompts` | ABSENT | prompt-vs-declared-verb drift not measurable |
| `.context/bus` | ABSENT | result-ledger traffic not measurable |

### PARTIAL / untrustworthy

| source | status | why |
|---|---|---|
| BVP scores | **PARTIAL** | 119 of 149 active tasks carry a *proposed* score; **0 carry a confirmed `bvp_scores:`**. The value axis is agent self-estimate (G-076) |
| TermLink traffic | **PARTIAL** | a fleet read returned `read_complete: false` — 1 hub unreachable (laptop-141), 3 hubs with unknown tail. Absence in that view is **not** evidence of absence |
| TermLink delivery/read receipts | **UNTRUSTWORTHY** | one ack, `up_to: 923`, ~3 weeks old. "Not replied" and "not seen" are indistinguishable. A channel cannot report its own failures — no out-of-band observer exists |

---

## Findings already in hand (facts, unclassified)

**F-1 — two working verbs are absent from `fw help`.** Measured: `fw bvp` and `fw arc` each
appear **0 times** in `fw help` output and both execute successfully. `fw metrics` (2) and
`fw note` (1) do appear. Non-use reading **C (undiscoverable)** in the prompt's taxonomy.

**F-2 — a capability was rebuilt by hand because it was not found.** `fw verify-acs` exists
("Automated Human AC evidence collection", with `--auto-check`). Earlier this same session,
T-783 hand-built `tools/_t783-human-ac-queue-extract.py` for that job without checking for a
verb. Both were run; they are **complementary, not redundant**:

| | `fw verify-acs --auto-check` | T-783 tool |
|---|---|---|
| population | 52 ACs (work-completed only) | **77 ACs / 62 tasks** (all active) |
| auto-pass found | **0 PASS**, 0 FAIL, 3 SKIP, 49 REVIEW | **2 evidenced** (T-580, T-586) by executing their checks |
| unique output | **20 NUDGEs**: reviewer PASS + no human AC → candidates for `[REVIEW]`→`[REVIEWER]` reclassification (T-1811) | executed the Expected clauses; found T-596 stale |

The verb's 20 NUDGEs are actionable and T-783 did **not** surface them. The verb found 0 of
the 2 items that demonstrably pass, because its population excludes non-`work-completed` tasks
and it skips checks it cannot automate.

**F-3 — second instance of the same shape in one session.** T-738 (filed 2026-09-20) already
contained the core finding that T-778 re-derived a day later. With F-2 that is two instances
of *agent builds what already exists* inside one session. Recorded as a fact; the pattern
claim is the JUDGE's to make.

---

## Baseline

**Baseline is RED, and it was red before this review touched anything.**

| suite | result |
|---|---|
| `tests/run-validator-tests.sh` | **54 passed, 0 failed** |
| `tests/run-bridge-tests.sh` | **FAIL** — `TEETH FAIL — 1 leg(s) failed` |

The bridge failure reports: *"an instrument that passed on 2026-08-15 no longer does, or an
exclusion went stale … these are hermetic and leave the repo untouched, so this one IS a real
regression in whatever that teeth script guards, not harness noise."* The precise failing
instrument was not isolated — `tools/_t509-instrument-sweep.sh` exceeded a 280s bound. That
isolation is itself an open item.

**This matters for Phase 6.** The execution rule is "re-run baseline after every slice; green →
red: revert". The baseline is *already* red, so a red after a slice must be compared against
this recorded state and not misattributed to the slice. A full `fw audit` is deliberately not run here: prompt 2
of this sequence runs audit and housekeeping in full, and the last measured full run took 687s
against a 600s self-kill (T-755).

---

# YARDSTICK CONFIRMED BY OPERATOR (2026-09-21)

> "Focus everything on the workflow designer and its integration with AEF and our ability to
> facilitate the agent and human collaboration to iterate from the workflow to actual working
> applications."

This **resolves the contradiction flagged above in the opposite direction to the repo's
centre of mass**. The purpose is the product — Designer, AEF seam, and the workflow →
working-application path. Governance/meta work is not the yardstick and is judged only by
whether it serves that path.

**It also reclassifies a stated non-goal.** `README.md` records "usable today without the
planned `fw workflow run` executor" as acceptable. Under the confirmed yardstick, iterating
from workflow to working application *is* the purpose, so the executor gap is no longer an
accepted non-goal — it is a candidate central ADD.

Load-bearing drivers under this yardstick: **F3** V_AEF_INTEGRATION (9), **F4**
V_WORKFLOW_ROUTING (9), **F1** V_SDLC_ENABLEMENT (9), **D3** Usability (5).

---

## F-4 — the workflow→application path has no mechanical link at any point

**Measured** by `tools/_t784-endpoint-resolution-census.py` over 93 `.bpmn` files.
`aef:endpoint` is the field that would bind a workflow node to code that runs.

| resolution of the 264 endpoint references | refs | share |
|---|---|---|
| **MISSING** — path exists in neither the project nor `.agentic-framework/` | **120** | **45%** |
| opaque — a command template, not a file (`fw work-on ${task_id}`, `fw arc rescore ${arc_id}`) | 115 | 44% |
| resolves in `.agentic-framework/` | 25 | 9% |
| resolves in the project | 4 | 2% |

**Only 29 of 264 references (11%) name a file that exists.**

### Where the broken ones live — not scratch work

| directory | refs | MISSING | |
|---|---|---|---|
| `examples/aef-processes` | 108 | **53** | **49%** |
| `build/gallery` | 108 | 53 | 49% (derived mirror) |
| `tests/fixtures` | 48 | 14 | 29% |

`examples/aef-processes/` is the seam artefact **AEF pins against**. Half its endpoint
references do not resolve.

### The sharper reading: the field holds three incompatible kinds of value

Inspecting the MISSING values shows most were never intended as executable bindings:

- **prose source-citations with line numbers and commentary** —
  `resume.sh:95-99 (get_session:81, get_focus:72)`,
  `type-specific suggestions (diagnose.sh:164-195)`,
  `add automated check; update audit agent (diagnose.sh:197-199)`
- **command templates with unexpanded placeholders** — `fw work-on ${task_id}`,
  `fw arc tag ${arc_id} T-XXXX`, `watchtower:/arcs/${arc_id}/close | fw arc close --i-am-human`
- **genuine `path:function` bindings** — `lib/notify.sh:fw_notify` (resolves in the framework)

So `aef:endpoint` is simultaneously a citation, a template and a binding. **A consumer cannot
dereference it mechanically**, because there is no rule that says which kind any given value is.

### Consequence for the confirmed yardstick — stated as fact, not verdict

Two independent breaks sit on the path from an authored workflow to a working application:

1. **No executor.** `fw workflow` does not exist in this build (verified).
2. **No binding to execute even if one existed.** The field that would carry it holds mixed
   content, 89% of which is not a resolvable file reference.

Classification of these facts is the JUDGE's role and is not performed here. Recorded as
evidence under Phase 3.

---

## F-5 — CORRECTION TO F-4: two standards in this tree disagree on `aef:endpoint`'s class

F-4 above reported `aef:endpoint` as a field whose semantics "were never fixed". **That is
wrong, and the correction matters more than the original finding.** The semantics were fixed
twice, differently, in two documents in this repository.

`docs/standards/aef-bpmn-mapping-v1.md`, **Part I — Frozen (v1)**, §1, verbatim:

> **Presentational (diagram cosmetics):** `aef:position`, `aef:anchors`, **`aef:endpoint`**,
> `aef:waypoint`, … The reverse compile MAY write these (layout) but MUST treat them as
> derived, never authoritative. **A change to a presentational attribute alone MUST be a
> no-op for the task graph.**

`docs/standards/aef-bpmn-forward-compile-v1.md` §2, verbatim:

> **Structured semantic elements** (v1 §1, semantic class): `aef:io`/`aef:input`/`aef:output`,
> **`aef:endpoint`**, `aef:artifactsWrites`, `aef:contextReads`, …

The forward-compile document states it *"adds no new contract"* and *"Derives from …
mapping-v1 (child-1, frozen v1)"*. So a derived document places a field in the semantic class
that its **frozen parent** places in the presentational class.

**Consequence for the 264 references measured in F-4.** The same data supports two opposite
readings, and which one holds is not ours to decide:

- **presentational** → all 264 are cosmetic, a compiler must ignore them, the 45% unresolved
  is harmless, and the content is misfiled documentation;
- **semantic** → the reference corpus at `tests/fixtures/aef-bpmn/` (named by forward-compile
  §5 as the translator's test input) feeds a compiler a field where 29–49% of values do not
  resolve and most are not file references at all.

**A reasoning error of this agent's, recorded rather than quietly dropped.** Before reading
the frozen standard, this review was reasoning toward "give `aef:endpoint` a declared kind
(`cites`/`invokes`/`binds`) so a step can state how mechanized it is." Under the frozen
partition that proposal is backwards: it would push execution semantics into the class whose
changes are *required to be a no-op*. PL-233 — grep the shared framework's source before
escalating a cross-project anomaly — is what caught it, one step before it became a proposal
to the operator.

## F-6 — the execution engine is already specified, and is not ours to build

`aef-bpmn-forward-compile-v1.md` §1, verbatim:

> Child-2 (the forward bridge: **diagram → agent-enriched *proposed* task graph → one
> sovereignty approval → governed work**) is **AEF-led**. AEF owns the translator, the
> enrichment pass, and the sovereignty gate. … **No translator is built here.**

This answers the operator's open question about the shape of an execution engine, and it
answers it in the architecture's own terms: the engine is a **compiler to a proposed task
graph**, not a process VM that dereferences endpoints. Drawing produces *proposals*; one
sovereignty approval ratifies; governed work then runs through the task/AC/verification
apparatus that already exists.

The "ratification gate" this review reasoned was missing is therefore **specified** — it is
the *"one sovereignty approval"* — and the authority concern (that an executable binding would
let authority be acquired by drawing) is already answered by design rather than by this
review's argument.

**Open, and the only part that is ours:** whether AEF's Child-2 translator is built, and
whether it reads `aef:endpoint`. Asked on `agent-chat-arc` **@1613**, correlation
`AEF-ENDPOINT-CLASS-832`, as two questions — which class governs, and does the translator read
the field. The second settles the first empirically.

---

# PHASE 3 ADDENDUM — facts established after the yardstick was confirmed

## F-7 — the `aef:endpoint` class conflict is RULED, and the 264 values are NOT a defect

Asked 999-AEF at `agent-chat-arc` @1613; answered @1616 (their T-3409), from code:

- **Their Child-2 translator `tools/bpmn_to_tasks.py` does NOT read `aef:endpoint`.** They
  grepped it: it reads `aef:boundaryPos, aef:constituent(s), aef:eventDef, aef:laneMeta,
  aef:link, aef:meta, aef:uid`. *"There is no occurrence of the string 'endpoint' anywhere in
  the translator."*
- **The frozen parent governs: presentational.**
- **`aef-bpmn-forward-compile-v1.md` does not exist in their tree.** They hold only the frozen
  Part I. The conflict was between our derived document and their frozen one; the drift was
  ours.
- Their verdict on the census: *"11% of 264 refs resolving is consistent with the field being
  cosmetic annotation that accreted prose, commands and citations because nothing ever read it
  back. **That is the presentational reading behaving exactly as documented, not a defect in
  it.**"*

**Corrected under T-786** (commit `89904b22`): `aef:endpoint` moved to §2's presentational
list, §3.3 carry-over claim removed, v1.1 → v1.2 with provenance inline. Frozen Part I
byte-identical (empty `git diff --stat`). Fixtures 19/19.

## F-8 — the driver blindness is confirmed upstream by a second corpus

AEF ran our script over **3,350 scored tasks** (their T-3408): **D2 83%, F2 91%** against our
84% / 92% — two corpora, different authors and domains, within one point. Cause (a) supported;
defect is upstream in `estimator.py`, AEF-owned, filed their **T-3410**.

Their wider table: **every free driver is dark** — F1 93%, F3 93%, F-AUTONOMY 99%, F-RECALL
68%. *"The ranking is being carried almost entirely by D1… Anyone reading a BVP total as a
five-plus-driver composite is reading one-and-a-half drivers."*

Method note (theirs): D1 is where the corpora *diverge* (ours 7%, theirs 35%) — *"where a
detector works, corpora diverge; where it does not, they agree."*

## F-9 — baseline: two regressed instruments, one fixed, one blocked

The full sweep (not the bridge suite's truncated tail) names **two**, not one:

| instrument | state |
|---|---|
| `_t400-schema-teeth.sh` | **FIXED** — was rc=1 on the G-027 shape (7 unaccounted `concerns.yaml` field names, **2 of them added by this agent today**). Now TEETH PASS 10/10. Leg (b) still reds on a newly invented field, so the check kept its teeth |
| `_t560-absence-census-teeth.py` | **RED, BLOCKED** — ratchet baseline 78, current **112**. 3 of the excess are this agent's legs from today |

`_t560`'s repair requires adding sibling control legs to `T-778`'s Verification block. T-778 is
in `.tasks/completed/`, and whether an agent may edit Verification blocks there is the exact
open `[REVIEW]` criterion on **T-353** (`owner: human`, unchecked). T-353 records that *"the
patch set is already built and proven, and no part of it has been applied"*
(`tools/_t353-repair-probe.sh`, **23/23 as of T-787** — recorded here as 16/16, which was the
count before that repair; the probe's fourth target was an ephemeral scratchpad path and it
gained 7 legs when that was fixed. See the correction block in the Phase 5 report §12 SQ-2.)

## F-10 — 832's contractual deliverables to the AEF bridge are intact

`forward-compile-v1` §1 names four things 832 owes. Verified:

| deliverable | state |
|---|---|
| input contract, guarded by `tests/test_forward_fixtures.py` | **PASSES**, 19 fixtures, exit 0 |
| reference corpus `tests/fixtures/aef-bpmn/` | 19 conformant — `aef:uid` on every flow node and sequence flow, all 20 meta keys within the bridge whitelist, governance exercised via lanes |
| forward-compile mapping §3 / modify-vs-create §4 | specified; §2 corrected today |

## F-11 — the engine question is answered in the spec, and is not 832's to build

`forward-compile-v1` §1, verbatim: *"Child-2 (the forward bridge: diagram → agent-enriched
**proposed** task graph → one sovereignty approval → governed work) is **AEF-led**. AEF owns
the translator, the enrichment pass, and the sovereignty gate. … **No translator is built
here.**"*
