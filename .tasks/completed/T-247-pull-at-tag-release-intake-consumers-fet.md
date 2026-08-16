---
id: T-247
name: "Pull-at-tag release intake: consumers fetch designer releases by version tag
  (seam-contract proposal)"
description: >
  Proposal (operator-directed 2026-07-23): switch consumer intake from per-peer file_send
  to pull-at-tag — consumer fetches dist artifact + MANIFEST.yaml at annotated tag
  designer-vX.Y.Z (frozen bytes, already committed at every release tag), sha-verifies
  against the MANIFEST at the same tag, re-pins. Preserves T-559 spirit (pin on frozen
  published bytes, never our working tree) and keeps the rail announce as new-version
  trigger + verdict handshake; drops only the delivery step. Scales 1:N, gives late
  joiners full history; with T-246 capabilities metadata the pull becomes self-describing.
  One question, one go/no-go: adopt pull-at-tag for the next release? Gates: AEF's
  read on the rail (proposed at offset 177), operator ruling on pull source (GitHub
  mirror vs LAN git server origin — reachability/credentials unverified), fallback
  = file_send stays available. Related: T-246.

status: work-completed
workflow_type: inception
owner: agent
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-23T10:06:24Z
last_update: '2026-08-16T12:33:45Z'
date_finished: 2026-07-23T11:10:36Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:45Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-247: Pull-at-tag release intake: consumers fetch designer releases by version tag (seam-contract proposal)

## Problem Statement

Consumers of designer releases (today: AEF; tomorrow: possibly more) have no self-serve way to learn a new version exists or to obtain it — discovery is a 1:1 rail announce and delivery is a per-peer file_send. The gap became operator-visible twice in one day (2026-07-23): AEF's operator heard of unreleased master work and sent their agent on a fruitless release hunt (their T-2556, rail 177), and our operator asked "how do subscribers know / how do they get the changes?". Explored: pull-at-tag intake — the release tag already carries the frozen artifact + MANIFEST, so consumers could fetch and sha-verify by version number, scaling discovery and delivery 1:N with zero new release machinery.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

## Open Questions

- **IW-1: Does pull-at-tag preserve the T-559 seam invariant ("AEF pins only delivered bytes, never reads our tree")?**
  confidence: 3
  disposition: answered
  rationale: AEF operator ruling at rail 182 (their D-335): "frozen annotated tag = published frozen bytes — invariant satisfied; your working tree remains off-limits as before." Both operators now on record.

- **IW-2: Which pull source — GitHub mirror or LAN git server?**
  confidence: 3
  disposition: answered
  rationale: AEF answer at rail 182: read-only LAN origin 192.168.10.201:6611/workflow-designer, preferred over the github mirror (same LAN, no external dependency). Matches our lean at rail 178.

- **IW-3: Are the existing tags sound dry-run targets (artifact + MANIFEST frozen at-tag, shas matching the pins)?**
  confidence: 3
  disposition: answered
  rationale: Verified 832-side 2026-07-23: annotated tags designer-v0.3.0/0.3.1/0.3.2 on origin (deref ^{} present); `git show <tag>:dist/aef-workflow-designer-<v>.html | sha256sum` = 36be033d… / d99a42da… / 983e0e30… — exact match to release pins; MANIFEST.yaml present at every tag.

- **IW-4: Can the AEF host actually read origin (network + git-server authorization)?**
  confidence: 1
  disposition: deferred
  rationale: Registered as the task's assumption; only validatable from THEIR host (one `git ls-remote` — test posted at rail 183). Server-side authorization is operator-owned infra on our side. This is the single remaining gate before their T-2616 dry-run.

## Exploration Plan

No spikes needed — the mechanism already exists (release tags carry frozen artifact + MANIFEST since 0.3.0). Validation = (a) 832-side at-tag sha verification (done, IW-3), (b) AEF-side ls-remote reachability test (deferred to their host, IW-4), (c) contract agreement on the rail (done, rail 182).

## Technical Constraints

- Origin is ssh-only (`ssh://git@192.168.10.201:6611`) — read access requires the git server to authorize AEF's host key (or an anonymous-read transport being enabled). Server config is operator-owned; NOT agent-reachable from 832.
- Standing security constraint unchanged: no push token in termlink; the github remote stays mirror-only (PushRepository) and is NOT the pull source.
- Release artifacts must remain committed at their tags (already release-designer.sh behavior; the immutability guard protects released bytes).

## Scope Fence

**IN:** the intake-contract decision (pull-at-tag vs file_send), 832-side dry-run-target verification, rail agreement.
**OUT:** AEF's intake tooling (`--from-tag` = their T-2616); MANIFEST changelog/capabilities enrichment (T-246, parked); git-server access provisioning (operator infra); any change to release-designer.sh (nothing needed — tags already carry everything).

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

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Both operators ratify the contract change (T-559 spirit preserved on record)
- Existing tags verify as sound pull targets (artifact+MANIFEST at-tag, shas == pins)
- Verification anchor unchanged (independent sha256 vs MANIFEST at the same tag)
- file_send remains available as fallback (reversible at any release)

**NO-GO if:**
- Either operator rules pull violates T-559
- Tags turn out not to carry frozen artifact/MANIFEST (would need release-pipeline rework)
- AEF host demonstrably cannot be granted read access to any agreed source

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

<!-- REQUIRED before fw inception decide. Write your recommendation here (T-974).
     Watchtower reads this section — if it's empty, the human sees nothing.
     Format:
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence from exploration)
     **Evidence:**
     - Finding 1
     - Finding 2
-->

**Recommendation:** GO
**Rationale:** Every GO criterion is met with evidence; the single deferred item (AEF-host reachability, IW-4) is a 10-second `git ls-remote` on their side with file_send as standing fallback if it fails — it cannot strand a release. The contract change was accepted operator-ratified on the consumer side (their D-335), the mechanism requires zero 832-side build (tags already carry frozen artifact + MANIFEST), and the verification anchor (independent sha256 vs MANIFEST at the same tag) is byte-for-byte identical to today's flow.
**Evidence:**
- Rail 182: AEF acceptance, operator-ratified — pull source = read-only LAN origin; their T-2616 ships `fw designer sync --from-tag`; file_send kept as fallback; T-559 ruling "frozen annotated tag = published frozen bytes"
- 832-side dry-run-target verification (2026-07-23): annotated tags designer-v0.3.0/1/2 on origin; at-tag artifact sha256 = 36be033d… / d99a42da… / 983e0e30… (exact pin matches); MANIFEST.yaml present at every tag
- Reversibility: rail announce stays the trigger + verdict handshake; any release can fall back to file_send with no contract renegotiation

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
Rationale: Every GO criterion is met with evidence; the single deferred item (AEF-host reachability, IW-4) is a 10-second `git ls-remote` on their side with file_send as standing fallback if it fails — it cannot strand a release. The contract change was accepted operator-ratified on the consumer side (their D-335), the mechanism requires zero 832-side build (tags already carry frozen artifact + MANIFEST), and the verification anchor (independent sha256 vs MANIFEST at the same tag) is byte-for-byte identical to today's flow.
Evidence:
- Rail 182: AEF acceptance, operator-ratified — pull source = read-only LAN origin; their T-2616 ships `fw designer sync --from-tag`; file_send kept as fallback; T-559 ruling "frozen annotated tag = published frozen bytes"
- 832-side dry-run-target verification (2026-07-23): annotated tags designer-v0.3.0/1/2 on origin; at-tag artifact sha256 = 36be033d… / d99a42da… / 983e0e30… (exact pin matches); MANIFEST.yaml present at every tag
- Reversibility: rail announce stays the trigger + verdict handshake; any release can fall back to file_send with no contract renegotiation

**Date**: 2026-07-23T11:10:36Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-23T10:48:25Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-23T11:10:36Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Recommendation: GO
Rationale: Every GO criterion is met with evidence; the single deferred item (AEF-host reachability, IW-4) is a 10-second `git ls-remote` on their side with file_send as standing fallback if it fails — it cannot strand a release. The contract change was accepted operator-ratified on the consumer side (their D-335), the mechanism requires zero 832-side build (tags already carry frozen artifact + MANIFEST), and the verification anchor (independent sha256 vs MANIFEST at the same tag) is byte-for-byte identical to today's flow.
Evidence:
- Rail 182: AEF acceptance, operator-ratified — pull source = read-only LAN origin; their T-2616 ships `fw designer sync --from-tag`; file_send kept as fallback; T-559 ruling "frozen annotated tag = published frozen bytes"
- 832-side dry-run-target verification (2026-07-23): annotated tags designer-v0.3.0/1/2 on origin; at-tag artifact sha256 = 36be033d… / d99a42da… / 983e0e30… (exact pin matches); MANIFEST.yaml present at every tag
- Reversibility: rail announce stays the trigger + verdict handshake; any release can fall back to file_send with no contract renegotiation

### 2026-07-23T11:10:36Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
