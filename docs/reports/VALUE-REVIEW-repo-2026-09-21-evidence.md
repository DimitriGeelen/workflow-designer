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

`tests/run-bridge-tests.sh` was started at 22:03Z and had not completed when this file was
written; `tests/run-validator-tests.sh` not yet run. **Baseline is INCOMPLETE** and is
recorded as such rather than omitted. A full `fw audit` is deliberately not run here: prompt 2
of this sequence runs audit and housekeeping in full, and the last measured full run took 687s
against a 600s self-kill (T-755).
