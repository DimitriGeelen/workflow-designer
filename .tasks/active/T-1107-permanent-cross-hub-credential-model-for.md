---
id: T-1107
name: "Permanent cross-hub credential model for peer agents (field survey)"
description: >
  Inception: Permanent cross-hub credential model for peer agents (field survey)

status: started-work
workflow_type: inception
current_node: frw_3_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-09T05:36:53Z
last_update: 2026-10-09T05:42:50Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-09T05:37:38Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (voi:open-question~'assumption'); D2=2 
      (voi:open-question~'assumption'); D3=2 (voi:open-question~'assumption'); 
      D4=2 (voi:open-question~'assumption'); F-RECALL=2 
      (voi:open-question~'assumption'); F2=2 (voi:open-question~'assumption'); 
      F4=2 (voi:open-question~'assumption'); F3=2 
      (voi:open-question~'assumption'); F1=2 (voi:open-question~'assumption')
    rubric_sha: e4a00f38e801
---

# T-1107: Permanent cross-hub credential model for peer agents (field survey)

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Hypothesis

<!-- DRAFTED by the estimator from this task's own text. Correct it, then set `hypothesis_source: human` in the frontmatter to make your wording permanent. Until then a later pass may redraft it. -->

We believe that permanent cross-hub credential model for peer agents (field survey),
we will achieve Inception: Permanent cross-hub credential model for peer agents (field survey).
We will know that we are successful when we see [NEEDS YOU: name something a person could go and look at — a count, a threshold, a named check, or a state that would visibly change].

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1107 -->

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

- **IW-1: How do comparable federated systems let independently operated nodes trust each other (enrolment, credential form, scope, rotation, revocation)?**
  confidence: 0
  disposition:
  rationale:
- **IW-2: Which of those patterns fits TermLink's hub model with least privilege (a peer may message our agents, nothing more) and LAN-only operation?**
  confidence: 0
  disposition:
  rationale:
- **IW-3: What would 832 ask TermLink/AEF for (a capability, a scope, a peering verb), and what can 832 do alone meanwhile?**
  confidence: 0
  disposition:
  rationale:

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->
1. Field survey (research worker, web, ~45 min): Matrix federation, XMPP s2s, ActivityPub, SMTP (DKIM/MTA-STS),
   WireGuard/Tailscale/Headscale/Nebula, mTLS service meshes + SPIFFE/SPIRE, NATS accounts/leafnodes,
   SSH certificates, OAuth client credentials / mTLS-bound tokens, Kubernetes cross-cluster, A2A/MCP agent auth.
   Output: docs/reports/T-1107-cross-hub-credential-model.md §Survey.
2. Map TermLink today (hub secret, capability tokens, TOFU pins, profile bootstrap_from) against the patterns (IW-2).
3. Options + recommendation for the operator (IW-3).

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
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-1107` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

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

**Recommendation:** DEFER

**Rationale:**

No evidence yet: the field survey (how federated peer systems exchange and scope credentials between independently operated nodes) has not been done. Stopgap T-1106 gives two-way sidecar with Greenfield meanwhile via a full hub secret delivered out of band.

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

<!-- Filled at completion via: fw inception decide T-1107 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-09T05:37:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
