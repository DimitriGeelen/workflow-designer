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
