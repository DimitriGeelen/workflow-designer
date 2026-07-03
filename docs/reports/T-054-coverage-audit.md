# T-054 — Dogfooding Coverage Audit: Vendored AEF Processes vs. `examples/aef-processes/` Corpus

**Task:** T-054 · **Type:** build (analysis) · **Date:** 2026-07-03

## Purpose

Does the Workflow Designer corpus (16 diagrams) faithfully cover the vendored
Agentic Engineering Framework's canonical governance processes? This audit
inventories the framework's real processes, maps each to a corpus diagram or a
GAP, ranks the gaps by governance-centrality, and files follow-up mapping tasks
for the worth-mapping ones.

This is an **analysis deliverable** — it adds no diagrams. Each new map is its
own small build task (per Task Sizing Rules).

## Method

Swept the vendored framework (read-only, via an Explore sub-agent):
`.agentic-framework/FRAMEWORK.md`, project `CLAUDE.md` (lifecycle/protocol
sections), and all 20 `.agentic-framework/agents/*/` dirs (13 with `AGENT.md`,
7 script-only). Each distinct process/lifecycle/loop was classified **covered /
gap / not-diagrammable**. Processes with ≥3 sequential-or-branching steps (or a
state machine) count as diagrammable; single-shot utilities do not.

## Coverage Matrix — the 16 corpus maps are all accounted for

| Corpus map | Canonical process | Source |
|---|---|---|
| `task-lifecycle` | captured → started-work ↔ issues → work-completed (auto healing/episodic) | `CLAUDE.md` §Task Lifecycle; `FRAMEWORK.md` |
| `healing-loop` | classify → lookup pattern → suggest (A/B/C/D) → log resolution | `agents/healing/AGENT.md` |
| `arc-lifecycle` | draft → in-progress → closed/abandoned (terminal gated) | `FRAMEWORK.md` §Arc Lifecycle |
| `inception-lifecycle` | phase → template review → ≤2 explore commits → decide go/no-go → spawn build tasks | `CLAUDE.md` §Inception Discipline |
| `inception-review` | operator review surface for inception decisions | `CLAUDE.md`; `docs/reports/T-038` |
| `assumption-validation` | add → validate w/ evidence → list by status | `CLAUDE.md` Quick Ref (`fw assumption`) |
| `session-handover` | gather state → synthesize → write LATEST.md → feedback loop | `agents/handover/AGENT.md` |
| `tier0-escalation` | destructive cmd → hook block → human approve → execute | `CLAUDE.md` §Enforcement Tiers |
| `audit-process` | 6 check sections → pass/warn/fail → persist → trend/practice-candidate | `agents/audit/AGENT.md` |
| `promotion-pipeline` | candidate → suggest → promote learning → graduation status | `CLAUDE.md` (`fw promote`); `docs/reports/T-045` |
| `upgrade-process` | vendor copy → sync files → verify | `FRAMEWORK.md` §Upgrading (`fw upgrade`) |
| `cross-host-dispatch` | cross-host agent contact → dispatch → ack | `agents/termlink/AGENT.md`; `docs/reports/T-046` |
| `release-pipeline` | release process | `docs/reports/T-047-release-friction.md` |
| `harvest-pipeline` | harvest process | `docs/reports/T-048-harvest-friction.md` |
| `review-emission` | review emission process | `docs/reports/T-049-review-friction.md` |
| `revisit-due-scan` | G-053 daily revisit scan of deferred decisions | `CLAUDE.md` (revisit_at); `docs/reports/T-033` |

**Coverage of the framework's named *lifecycles*: complete.** Every state-machine
lifecycle (task, arc, inception, healing, handover, tier-0, audit, promotion,
upgrade, dispatch, release, harvest, review, revisit, assumption) has a diagram.
No orphan maps — all 16 correspond to a real framework process.

## Gap Analysis — diagrammable processes with no map

The gaps are **not lifecycles** — they are the framework's *enforcement gates*,
*memory architecture*, and *operational loops*. The corpus told the "happy-path
lifecycle" story; it does not yet show the **governance machinery** that the
Four Constitutional Directives actually run on.

### Tier 1 — Constitutional (FILED as backlog mapping tasks)

The core of "Nothing gets done without a task" and the completion/memory/
antifragility machinery. Highest representational value; each now has a task.

| Gap | Flow | Source | Disposition |
|---|---|---|---|
| task-gate (Tier-1 / P-002) | Write/Edit → active-task? → allow / block → create-task or Tier-2 bypass | `CLAUDE.md` §Enforcement Tiers, Core Principle | **FILED T-055** |
| verification-gate (P-011) | work-completed → extract `## Verification` → run each → pass / block(non-zero) / `--force` | `CLAUDE.md` §Verification Gate | **FILED T-056** |
| context-memory 3-tier | working (reset on init) / project (patterns+decisions+learnings) / episodic (gen on completion) | `agents/context/AGENT.md` | **FILED T-057** |
| error-escalation-ladder | A don't-repeat → B technique → C tooling → D ways-of-working; + proactive Level-D | `CLAUDE.md` §Error Escalation Ladder | **FILED T-058** |

### Tier 2 — Operational (DEFERRED; promote from this report on demand)

Genuinely diagrammable and useful, but deferred to avoid task sprawl — a
diagram of the four constitutional gates above proves the pattern first. Promote
any of these to a build task when a dogfooding need arises.

| Gap | Flow | Source |
|---|---|---|
| sub-agent-dispatch | classify agent → parallel(≤5, 40K headroom) vs sequential → result via bus | `CLAUDE.md` §Sub-Agent Dispatch |
| result-ledger-bus | post → size-gate (<2KB inline / ≥2KB blob) → manifest → read → clear | `CLAUDE.md` §Result Ledger |
| context-budget-escalation | 120K ok→warn · 150K→urgent · 170K→critical BLOCK → auto-handover → restart → reinject | `CLAUDE.md` §Context Budget Mgmt |
| fabric drift / blast-radius | changed files → component cards → transitive `depended_by`; drift = scan → classify unregistered/orphaned/stale | `CLAUDE.md` §Component Fabric |
| session-capture | scan categories → checklist → create tasks/updates/learnings/questions → report | `agents/session-capture/AGENT.md` |
| observation-inbox | capture → pending → triage → promote-to-task / dismiss(reason) | `agents/observe/observe.sh` |
| git-traceability-enforce | commit → validate `T-\d+` → block / commit+bump; bypass → log-bypass | `agents/git/AGENT.md` |
| onboarding-test | C1 scaffold → C2 hooks → … → C8 handover; cascade-failure diagnosis | `agents/onboarding-test/AGENT.md` |
| ux-review | drive page → screenshot per theme → 6 checks → PASS/CONCERN | `agents/ux-review/AGENT.md` |
| hypothesis-debug-loop | symptom → hypothesis → test → disproved? next (max 3) → escalate → record | `CLAUDE.md` §Hypothesis-Driven Debugging |
| root-cause-escalation (G-019) | fix symptom → "why did framework allow?" → blind >7d? → register gap → don't-close-until-prevention | `CLAUDE.md` §Post-Fix Root Cause |

### Tier 3 — Fold or skip (small reactive utilities)

`gpu-recover` (nvidia-smi → exclude ollama → heaviest → SIGTERM → wait → SIGKILL)
and `mcp-reaper` (detect PPID=1+age+PGID-dead → SIGTERM → 5s → SIGKILL) are
diagrammable but single-purpose reactive escalations; `pickup-message-handling`
(G-020) and `bug-fix-learning-checkpoint` are behavioral micro-rules better
folded into task-gate / error-ladder than mapped standalone. **Not filed.**

## Not Diagrammable — utilities / single-shot (excluded, with reason)

| Process | Why excluded |
|---|---|
| metrics / api-usage | one-shot analytical query (tally jsonl → % vs gate); no lifecycle |
| liveness-monitor | periodic cron sampler; linear collect-and-write, no decision flow |
| docgen | template-fill generator, one-shot input→output |
| capture (read-transcript) | one-shot reader utility |
| task-create/update CLI | thin CLI wrapper; the lifecycle it drives = `task-lifecycle` map |
| resume | synthesis query (handover+working+git+tasks → summary); recovery aid, folds into session flow |
| termlink tool suite | messaging/RPC primitives; governance use already = `cross-host-dispatch` |

**Session Start / End Protocols** are linear checklists whose every step already
maps to context-init, session-capture, and session-handover — an optional
umbrella, not a distinct gap.

## Conclusion

- **Lifecycle coverage: 16/16 — complete.** No named framework lifecycle lacks a
  diagram, and no corpus map is an orphan.
- **The real gap is a *category*, not a count:** the corpus shows lifecycles but
  not the **enforcement/memory/antifragility machinery** underneath them. The
  four constitutional gates (task-gate, verification-gate, context-memory,
  error-ladder) are the highest-value additions and are now filed as **T-055–T-058**.
- **11 Tier-2 operational processes** are catalogued and deferred (promote on
  demand); Tier-3 utilities and single-shot tools are excluded with reasons.
- **Recommended next map:** `task-gate` (**T-055**) — it visualises the Core
  Principle ("Nothing gets done without a task") that every other process
  presupposes, and exercises the exclusive-gateway + Sovereignty-lane parts of
  the editor that the lifecycle maps use lightly.

### Follow-up tasks filed
- **T-055** — Map task-gate enforcement flow (Tier-1 / P-002)
- **T-056** — Map verification-gate (P-011) completion flow
- **T-057** — Map context-memory three-tier fabric flow
- **T-058** — Map error-escalation-ladder (A/B/C/D + proactive Level-D)
