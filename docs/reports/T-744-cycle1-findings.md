# T-744 — Audit remediation, cycle 1: findings table and reconciliation

**Run date:** 2026-09-21
**Arc:** `arc-003` — "Audit remediation: every audit and doctor finding is an owned, scored task"
**Cycle:** N+1. `arc-003` already held RA-001…RA-035 from a previous run of the same
mandate, so cycle 1 diffs against that baseline rather than opening from cold.

---

## 0. Verb-surface findings (recorded, not routed around)

The mandate requires confirming the verb surface before use and forbids inventing verbs.
Two of the verbs it names do not exist in this build.

| # | Mandate says | This build has | Resolution |
|---|---|---|---|
| VS-1 | "Run the housekeeping verb" | `fw housekeeping` → `Unknown command: housekeeping` | Used `fw doctor`. arc-003's own name says "every audit and **doctor** finding", so `doctor` is the housekeeping surface this project already treats as such. Substitution recorded rather than the verb invented. |
| VS-2 | "Dispatch BVP estimation to the bvp-estimator worker" | No `bvp-estimator` agent in `.agentic-framework/agents/` (24 agents, none of them it) | Scored with `fw bvp estimate`, which is the scorer (heuristic v1, writes `bvp_scores_proposed:`, explicitly *not* sovereignty-bearing). The estimator identifies itself in the written record as `bvp-estimator-v1-heuristic` — the worker name refers to an in-process estimator, not a dispatchable TermLink worker. |

## 1. Coverage of this cycle's baseline

`fw audit` cannot be run whole — a full run does not terminate (OBS-358) — so sections
were run in timeout-boxed batches. **A pass-set baseline that does not state its own
coverage overclaims**, so coverage is stated here.

| Section | Exit | PASS | WARN | FAIL | Note |
|---|---|---|---|---|---|
| structure, compliance, quality, traceability, enforcement | 0 | 36 | 21 | 0 | batch A |
| learning, episodic, observations, gaps, handover, graduation | 0 | 9 | 2 | 0 | batch B |
| discovery | 2 | 5 | 0 | 1 | |
| discovery-trends | 1 | 8 | 2 | 0 | |
| deployment | 2 | 3 | 0 | 4 | |
| oe-fast | 0 | 4 | 0 | 0 | clean |
| oe-hourly | 0 | 2 | 0 | 0 | clean |
| oe-weekly | 0 | 1 | 0 | 0 | clean |
| oe-research | 0 | 5 | 0 | 0 | clean |
| **oe-daily** | **124** | 58 | 0 | 0 | **TIMED OUT at 300s — coverage incomplete.** Any finding oe-daily would have reported after its 58th check is *not* in this baseline. Recorded as finding RA-046. |
| `fw doctor` | 0 | — | 2 | 0 | housekeeping surface (VS-1) |

**Baseline totals across completed sections: 131 PASS, 25 WARN, 5 FAIL.**
Coverage is 18 of 19 sections complete; `oe-daily` partial.

## 2. Findings table

Severity is carried through exactly as the tool reported it. One row = one finding =
one task. Root-cause siblings are linked, not merged.

| ID | Source | Sev | Check that fired | Artifact | Observed vs expected | Task | New? |
|---|---|---|---|---|---|---|---|
| RA-036 | audit/structure | WARN | Fabric edge coverage | `.fabric/components/` | 78 of 379 cards carry 0 edges; expected coverage above target | **T-745** | **REGRESSION** of RA-002/T-698 (closed) |
| RA-037 | audit/compliance | WARN | Task missing Updates section | `.tasks/active/T-741-…md` | no `## Updates`; template guarantees one | **T-746** | NEW |
| RA-038 | audit/quality | WARN | CTL-029 completable-not-closed | task T-702 | all Agent ACs ticked, `status: started-work` | **T-747** | NEW |
| RA-039 | audit/quality | WARN | CTL-029 completable-not-closed | task T-703 | all Agent ACs ticked, `status: started-work` | **T-748** | NEW |
| RA-040 | audit/quality | WARN | CTL-029 completable-not-closed | task T-708 | all Agent ACs ticked, `status: started-work` | **T-749** | NEW |
| RA-041 | audit/quality | WARN | CTL-029 completable-not-closed | task T-723 | all Agent ACs ticked, `status: started-work` | **T-750** | NEW |
| RA-042 | audit/deployment | FAIL | Deploy gate uncommitted count | working tree | 746 uncommitted source files; gate expects 0 | **T-751** | NEW |
| RA-043 | audit/deployment | FAIL | Deploy gate scaffold | `Dockerfile` | absent; gate expects present | **T-752** | NEW |
| RA-044 | audit/deployment | FAIL | Deploy gate scaffold | `deploy/docker-compose.swarm.yml` | absent; gate expects present | **T-753** | NEW |
| RA-045 | audit/deployment | FAIL | Deploy gate scaffold | `deploy/traefik-routes.yml` | absent; gate expects present | **T-754** | NEW |
| RA-046 | audit/oe-daily | — | section does not terminate | `agents/audit/` oe-daily | exit 124 at 300s after 58 PASS; expected termination | **T-755** | NEW (localises OBS-358) |
| — | audit/structure | WARN | Uncommitted changes present | working tree | — | T-701 (RA-005) | already owned |
| — | audit/observations | WARN | urgent observations pending | `.context/inbox.yaml` | **36** pending; was 34 at RA-006 | T-702 (RA-006) | already owned, **worsened** |
| — | audit/observations | WARN | observations pending >7d | `.context/inbox.yaml` | **107** pending; was 101 at RA-007 | T-703 (RA-007) | already owned, **worsened** |
| — | audit/discovery | FAIL | D2 human review queue >30d | review queue | 10 tasks >30d (oldest 53d) + 23 more >14d | T-723 (RA-027) | already owned |
| — | audit/discovery-trends | WARN | D5 task lifecycle anomalies | task ledger | **12** anomalies; was 10 at RA-028 | T-724 (RA-028) | already owned, **worsened** |
| — | audit/discovery-trends | WARN | D13 inception limbo | T-309, T-357, T-681 | 3 tasks decided but stuck in `active/` | T-725 (RA-029) | already owned |
| — | audit/quality ×14 | WARN | CTL-029 completable-not-closed | T-041,101,102,105,189,209,286,293,309,344,345,357,402,681 | all Agent ACs ticked, `started-work` | T-709…T-722 | already owned |
| — | doctor | WARN | claude-fw drift | `/root/.local/bin/claude-fw` | drifted from repo source | T-729 (RA-033) | already owned |
| — | doctor | WARN | task debt | task ledger | 52 tasks with no update in 7+ days | T-731 (RA-035) | already owned |

## 3. Reconciliation — findings in = tasks out

```
Individual findings observed this cycle .................. 30
  reconciled to a task created THIS cycle ................ 11   (RA-036 … RA-046 → T-745 … T-755)
  reconciled to an existing arc-003 task ................. 19   (RA-005, RA-006, RA-007, RA-027,
                                                                 RA-028, RA-029, RA-033, RA-035,
                                                                 and the 14 already-owned CTL-029
                                                                 instances, less overlap)
  unreconciled ........................................... 0
```

**Zero findings remain outside the arc.** All 11 new tasks carry `arc_id: arc-003`, set
through `fw arc tag`, never by hand.

## 4. Scores and quadrant placement

Rationale precedes score in every case — the estimator writes its own rationale string
into `bvp_scores_proposed:` before the composite is derived. No score was adjusted upward
by the producer.

| Task | BVP | Cost | Quadrant | Disposition |
|---|---|---|---|---|
| T-755 (RA-046) | **101** | undefined | **high value**, cost undefined | **Q1 — worked this cycle** |
| T-745 (RA-036) | 94 | undefined | low value | parked |
| T-747 (RA-038) | 91 | undefined | low value | parked |
| T-748 (RA-039) | 91 | undefined | low value | parked |
| T-746 (RA-037) | 79 | undefined | low value | parked |
| T-749 (RA-040) | 79 | undefined | low value | parked |
| T-750 (RA-041) | 79 | undefined | low value | parked |
| T-752 (RA-043) | 69 | undefined | low value | parked + Sovereign question |
| T-753 (RA-044) | 69 | undefined | low value | parked + Sovereign question |
| T-754 (RA-045) | 69 | undefined | low value | parked + Sovereign question |
| T-751 (RA-042) | 51 | 2.9 | `lv-lc` | parked |

The value boundary in this build is **hv ≥ 100, lv ≤ 94**. Ten of the eleven new findings
score below it. Per the mandate — *"Low-value tasks stay in the arc, scored and parked.
Do not pick up a low-value task because it is quick"* — they were not worked.

**Cost is undefined for 10 of 11.** The F8 composite is
`0.6×blast_radius + 0.3×tier + 0.1×effort`, and `blast_radius` is only computable once a
task has changed files. A freshly created task therefore *cannot* be placed on the cost
axis at all. This is not a defect of this cycle; it is already owned as T-738
("46 of 128 tasks carry no BVP quadrant"), itself scored `lv-lc` 61 — i.e. the defect
that prevents quadrant placement is parked by the quadrant rule it breaks.

## 5. Sovereign questions raised by this cycle

**SQ-1 — Does 832-Workflow-designer deploy as a Ring20 swarm service?**
Three FAILs (RA-043/044/045) say scaffolding is missing. The mitigation the audit offers
is `fw deploy scaffold`. Running it would decide that this project is a containerised
deployed service — an architectural decision. This project is served by Watchtower on a
LAN port and ships its product as a single-file HTML artifact vendored by a consumer; it
has never been a deployed service. If the answer is no, the correct fix is to scope the
deployment section out for this project, **not** to scaffold three files to silence three
FAILs. Parked, not decided.

**SQ-2 — Should an agent-produced task ever be born `owner: human` with zero Human ACs?**
All four new CTL-029 findings (RA-038…041) are arc-003's *own* remediation tasks. Each has
every Agent AC ticked, no Human AC outstanding on two of them, and `owner: human` —
so the agent cannot close them (completing `owner: human` is not delegated) and the
audit will keep reporting them every cycle. This is the mechanism by which the remediation
arc generates the findings it exists to remediate.

**SQ-3 — The review queue is the binding constraint, and remediation cannot touch it.**
The single FAIL in `discovery` is the human review queue: 10 tasks waiting >30 days,
23 more >14 days, 67 tasks with unchecked Human ACs, 10 inception decisions pending
(oldest 72 days). Every Q1 item in the whole project is blocked behind it (§6). No
agent-side remediation can drain it.

## 6. Q1/Q2 state at cycle close

Q1 (`hv-lc`) across the project, and why each is not agent-actionable:

| Task | BVP | Blocked on |
|---|---|---|
| T-155 | 126 | operator `fw inception decide` — agents must never invoke it |
| T-184, T-185, T-186 | 126 | inception DEFER decisions, operator-only, 72d old |
| T-279, T-280, T-281, T-282 | 126 | inception DEFER decisions, operator-only, 54d old |
| T-700 (RA-004) | 125 | last Agent AC is *deliberately* reserved to the operator (G-007 release decision), left unticked so P-010 keeps blocking |
| T-345 | 112 | `owner: human`, 0 unticked Agent ACs, 1 Human AC |
| T-422 | 112 | first AC reads "whichever remedy **the operator picks**"; AEF instructed the seven missing hooks not be hand-added |
| T-443 | 106 | `owner: human`; ACs are still template placeholders, so its BVP 106 was scored against placeholder text |
| T-702, T-703 | 101 | `owner: human`, 0 unticked Agent ACs — completion not delegated |
| T-696 | 100 | every open Agent AC blocked on a Human ruling |

**Agent-actionable Q1 work in this cycle: T-755 only.**

## 7. Delta against the previous cycle's baseline

- Findings **closed** by the previous cycle that have **returned**: 1 (RA-002 → RA-036).
- Findings **worsened** while owned: 3 (urgent observations 34→36; pending >7d 101→107;
  lifecycle anomalies 10→12).
- New finding classes: 3 (deployment scaffold absence, CTL-029 on arc-003's own tasks,
  oe-daily non-termination).
- arc-003 size: 35 tasks → 46 tasks.
- arc-003 tasks closed this cycle: 0 — no agent-actionable task in the arc was unblocked.
