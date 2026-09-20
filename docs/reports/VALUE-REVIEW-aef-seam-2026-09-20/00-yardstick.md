# Value review — yardstick (Phase 1)

**Scope (operator, 2026-09-20, verbatim):** *"the integration with AEF and operator AEF, agent
collaboration where we go from a workflow to a program to incomplete execution and that handoff in
between that and what we need for that."*

Read as: the AEF integration seam — operator↔AEF and agent↔agent collaboration — along the chain
**workflow → program → execution**, the handoffs between those stages, and what is missing to make
the chain work. Budget: unbounded ("as many as you need").

## Purpose (confirmed from README.md + .context/arcs/ + policy/value-drivers.yaml)

**One sentence:** 832-Workflow-designer is the source of truth for a dual-audience, single-file
BPMN-subset editor that lets a human draw an AEF process on a swimlane canvas and lets agents read
the same file as typed, schema-validated YAML — so that an authored diagram can become governed
AEF work and, eventually, be executed.

**Users/consumers:**
- the **operator** (draws processes, rules on decisions, holds sovereignty)
- **999-AEF** — vendors a *pinned build artifact*, never a fork; serves it via `fw designer`
- **agents** in both repos, collaborating across the T-559 project boundary via TermLink

**Core capabilities**, as the arcs themselves declare them:

| Arc | Status | Headline mechanic (verbatim) | Chain stage |
|---|---|---|---|
| arc-001 `designer-authoring-surface` (T-175) | in-progress | "A human draws a process in the browser designer and the AEF agent turns it into an approved governed task/inception graph; conversely existing AEF work is rendered back as an editable process map — over a portable BPMN<->task-YAML standard." | **workflow → program** |
| arc-002 `ewcr-governed-delivery` (T-590) | in-progress | "An operator opens a workflow authored in the Designer, exports it as an executable contract, and a runtime executes it — where every step is traceable to the evidence that justified it and to the operator decision that authorised it, and any step lacking either is refused rather than run." | **program → execution** |
| arc-003 audit remediation | in-progress | — | OUT OF SCOPE |

**Non-goals (stated):** AEF never edits its vendored copy; the dependency topology stays acyclic
(832 vendors AEF at `.agentic-framework/`, AEF references only a *build artifact* of 832); the
frozen standard `docs/standards/aef-bpmn-mapping-v1.md` Part I is not edited under agent control;
`examples/aef-processes/rendered/` is a seam artefact AEF pins against and is not regenerated on
agent initiative.

**Value drivers (yardstick weights, `policy/value-drivers.yaml` v3):**
D1 Antifragility 9 · D2 Reliability 7 · F-RECALL Recall Leverage 6 · D3 Usability 5 ·
D4 Portability 3. F-ORCH retired 2026-07-07. F-AUTONOMY activated 2026-06-13.
These are AEF's drivers, vendored; they are the scoring axis already in use by `fw bvp`.

## Contradiction flagged at Phase 1

README §Status says *"Next planned slice: schema validation tooling for produced workflow files."*
That names a slice that both arcs have long since overtaken — arc-002 is at contract-seam
ratification, not at validation tooling. The README's forward-looking statement is stale relative
to the arcs. Recorded as a docs-vs-reality contradiction, not classified here.

README also states the editor "occupies the **Stabilization** tier of AEF's manifest-maturity
ladder: richer than markdown dispatch templates, but usable today **without the planned
`fw workflow run` executor**." That sentence is the review's central question in the project's own
words: the executor is *planned*, and the chain's third stage therefore has no runtime.

## Data availability map (Phase 0, verified against the live tree)

| Source | Status | Location | Notes |
|---|---|---|---|
| Task ledger | EXISTS | `.tasks/` | 127 active, 611 completed |
| Arcs | EXISTS | `.context/arcs/` | 3 files; 2 in scope |
| Component fabric | EXISTS | `.fabric/components/` | 378 cards; 0 cover vendored `.agentic-framework/` |
| Audit records | EXISTS | `.context/audits/` | 78 entries; "last run of each date per scope" (T-677) |
| Gate bypass log | EXISTS | `.context/working/.gate-bypass-log.yaml` | 1,011 lines |
| Episodic memory | EXISTS | `.context/episodic/` | 611 entries |
| Handovers | EXISTS | `.context/handovers/` | 641 entries |
| Observation inbox | EXISTS | `.context/inbox.yaml` | 1,682 lines; 125 pending / 3 urgent |
| Concerns register | EXISTS | `.context/project/concerns.yaml` | 3,338 lines; 43 watching |
| Patterns | EXISTS | `.context/project/patterns.yaml` | 241 lines |
| Value drivers | EXISTS | `policy/value-drivers.yaml` | v3, 288 lines |
| BVP scores per task | EXISTS | task frontmatter + `fw bvp` | mostly `_proposed`, few confirmed |
| **BVP realization log** | **ABSENT** | `.context/audits/bvp-realization.jsonl` | **no "did it deliver?" data exists** |
| **Capability registry** | **ABSENT** | `policy/capabilities.yaml` | Data Layer B assumes it; not present |
| Integration protocol | EXISTS | `docs/aef-designer-integration-protocol.md` | T-173 GO authority |
| Frozen standard | EXISTS | `docs/standards/aef-bpmn-mapping-v1.md` | Part I not agent-editable |
| Arc-0 exit gate | EXISTS | `docs/research/executable-workflow/arc-0-exit-clauses.yaml` | 3 clauses, unratified |
| Seam corpus | EXISTS | `examples/aef-processes/rendered/` | 24 `.bpmn`; AEF pins against it |
| Release manifest | EXISTS | `dist/MANIFEST.yaml` | pinned-version seam |
| TermLink rail history | **EXISTS — earlier "LOST" claim retracted** | shared hub | T-733 recorded the hub restarting with an empty topic store and declared every cited offset dangling. G1 re-read offsets 602/643/650/734/737/741/742 live on 2026-09-20: **all return their full payload**. The agent's own retraction already exists (OBS-354, `.context/inbox.yaml:1632`; rail @1536 "That conclusion was wrong") but `arc-0-exit-clauses.yaml:45-78` still carries the false block, and commit `116cc3b4` edited that file today without removing it. The counterparty reads that file. |
| **Execution traces per node** | **expected ABSENT** | would need `fw workflow run` | to be verified by GATHERER G3 |
| CI | EXISTS | `.onedev-buildspec.yml` | no package.json/Makefile |

**A channel cannot report its own failures:** the TermLink rail is both the collaboration medium
and the only record of collaboration, and there is no out-of-band observer of the 832↔AEF seam.
That remains a standing data gap — but note the direction of the error it produced here. The rail
did *not* lose its history; a session concluded it had, wrote that conclusion into the seam
register the counterparty reads, retracted it in an observation, and left the register uncorrected.
The medium was fine; the record about the medium was wrong for four days.

**Pollution disclosure:** this session ran `fw review-queue`, a pre-push `fw audit --section
structure`, `fw bvp estimate`, and four commits before the snapshot. Counters are read after that
activity, not from a clean baseline.

## Role separation

GATHERER: this session plus five dispatched read-only workers (Phases 0–3), each writing evidence
to `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/` and returning summaries only.
JUDGE: a separate agent whose only inputs are the evidence files and this yardstick (Phase 4–5).
HUMAN: decides (Phase 5) and authorises execution (Phase 6). Nothing is executed under T-740.
