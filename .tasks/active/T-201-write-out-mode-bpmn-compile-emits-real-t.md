---
id: T-201
name: "Write-out mode: BPMN compile emits real .tasks/ files (guardrail design + go/no-go)"
description: >
  Inception: Write-out mode: BPMN compile emits real .tasks/ files (guardrail design + go/no-go)

status: started-work
workflow_type: inception
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-07-18T08:04:17Z
last_update: 2026-07-18T08:33:28Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
---

# T-201: Write-out mode: BPMN compile emits real .tasks/ files (guardrail design + go/no-go)

## Problem Statement

Should the BPMN compiler promote proposals into real `.tasks/*.md` files
(write-out mode), closing the arc's author→compile→execute loop? The capability
is useful but sovereignty-sensitive: a compiler emitting `.tasks/` authors the
exact governance artifact the task-gate + Authority Model protect (IW-1/IW-3).
The question is whether the guardrails can be made mechanical enough that
write-out never authors active governance work without human authority.
**Full framing, guardrail table (G1–G6), seam analysis, spikes, and go/no-go
criteria: `docs/reports/T-201-writeout-mode-inception.md`.**

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->
- **IW-1: Can the write-out guardrails (dry-run default + explicit `--write`; emitted tasks land `owner:human` + `status:captured`) be made MECHANICALLY enforceable — a gate/hook, not a convention — so write-out can never author active governance work without human authority?**
  confidence: 1
  disposition: <deferred — Spike-1>
  rationale: The whole GO hinges on this (A1/A2). Not yet spiked.
- **IW-2: Where does the write seam live — 832 emits a portable task-bundle that AEF ingests, vs AEF's `fw bpmn compile --write` writes its own `.tasks/` directly?**
  confidence: 3
  disposition: answered
  rationale: Resolved via rail dialogue (AEF T-2541, 2026-07-18 08:20Z) — false binary; manifest-as-seam. Content authority=832, gated-write=AEF via `fw bpmn promote`→`fw task create`. G3 becomes mechanical because the write stays inside the task-gate perimeter. Both peers concur. See docs/reports/T-201-writeout-mode-inception.md §3a.
- **IW-3: What is the idempotent re-compile reconciliation rule (uid-keyed add/edit/delete) so re-compiling an edited diagram reconciles rather than clobbers or duplicates — and what happens to a task whose node was deleted?**
  confidence: 2
  disposition: <deferred — Spike-3 test; rule drafted>
  rationale: Rule drafted (§3b) — task frontmatter `aef_provenance` authoritative, reconcile keyed on (uid, source_bpmn_sha): new→create / unchanged→no-op / changed→propose-not-clobber / deleted→orphan-and-flag. Bounded, so the NO-GO "unbounded reconciliation" trigger is excluded. Remaining: test against a 2-revision diagram.

See `docs/reports/T-201-writeout-mode-inception.md` for full framing, guardrail table, and go/no-go criteria.

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Full criteria in docs/reports/T-201-writeout-mode-inception.md §6. -->
**GO if:**
- Guardrails G1–G6 each reduce to a mechanical check (gate/hook/flag) and A1+A2 hold — write-out provably cannot author active governance work without human authority.
- The write seam (G3, IW-2) resolves to one option with AEF concurrence.
- Re-compile reconciliation (G4, IW-3) has a predictable, documented rule.

**NO-GO if:**
- Any guardrail can only be a convention, not a gate — the sovereignty boundary would depend on agent discipline, which the framework rejects.
- The seam stays genuinely ambiguous / both sides push authority to the other.
- Reconciliation is unbounded (re-compile risks clobbering human edits to emitted tasks).

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO

**Rationale:**

Going-in advisory, to be validated by exploration. Write-out closes the arc's author->compile->execute loop and Dimitri steered inception-first/next; AEF's compiler (T-2531) already exists to build on. The OPEN question the inception must resolve is whether the sovereignty guardrails can be made safe and mechanical: dry-run default, explicit --write, emitted .tasks/ landing owner:human + status:captured so nothing auto-activates, and where the write seam lives (832-emits-bundle vs AEF-compiler-writes). GO only holds if exploration shows those guardrails are enforceable without weakening the task-gate / Authority Model (IW-1/IW-3); if they can't be, this flips to NO-GO.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

**Decision**: GO

**Rationale**: Recommendation: GO

Rationale:

Going-in advisory, to be validated by exploration. Write-out closes the arc's author->compile->execute loop and Dimitri steered inception-first/next; AEF's compiler (T-2531) already exists to build on. The OPEN question the inception must resolve is whether the sovereignty guardrails can be made safe and mechanical: dry-run default, explicit --write, emitted .tasks/ landing owner:human + status:captured so nothing auto-activates, and where the write seam lives (832-emits-bundle vs AEF-compiler-writes). GO only holds if exploration shows those guardrails are enforceable without weakening the task-gate / Authority Model (IW-1/IW-3); if they can't be, this flips to NO-GO.

Evidence:

**Date**: 2026-07-18T08:41:24Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-18T08:05:29Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-18T08:41:24Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO

Rationale:

Going-in advisory, to be validated by exploration. Write-out closes the arc's author->compile->execute loop and Dimitri steered inception-first/next; AEF's compiler (T-2531) already exists to build on. The OPEN question the inception must resolve is whether the sovereignty guardrails can be made safe and mechanical: dry-run default, explicit --write, emitted .tasks/ landing owner:human + status:captured so nothing auto-activates, and where the write seam lives (832-emits-bundle vs AEF-compiler-writes). GO only holds if exploration shows those guardrails are enforceable without weakening the task-gate / Authority Model (IW-1/IW-3); if they can't be, this flips to NO-GO.

Evidence:
