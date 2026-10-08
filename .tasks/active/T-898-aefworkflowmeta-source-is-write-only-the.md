---
id: T-898
name: "aef:workflowMeta source= is WRITE-ONLY: the emitter writes it and no reader ever reads it back"
description: >
  T-885's census found source= write-only. T-886 excluded it from the document-level round-trip comparison with that reason -- a value the parser never reads cannot round-trip by construction -- and deliberately did not decide the product question: stop emitting it, or read it back.

status: captured
workflow_type: inception
target_blast_radius: 3
voi_score: 0.5
owner: agent
horizon: later
tags: [designer, seam]
components: []
related_tasks: []
created: 2026-09-27T11:52:13Z
last_update: 2026-09-27T11:52:13Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): BOTH fields below are now ESTIMATED
# automatically from this task's own text. Do not pre-fill them.
#
# They used to ship with `target_blast_radius: 3` and `voi_score: 0.5` already
# filled in, and that default was doing real damage: int(round(0.5*5)) == 2, and
# an ABSENT voi_score also scored 2, so "nobody assessed this" and "someone
# judged it middling" were the same number. 42 of 45 inceptions ranked on a
# value no person had chosen, and because 2 is mid-range they sorted ahead of
# measured work. T-624 tried to fix it with a warning printed right here; 28
# days later the figure had not moved by one, because a comment is not a gate.
# Deleting the default IS the gate.
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no
# automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
# Anything without `_source: human` is treated as the estimator's own and is
# freely recomputed. There is no third state, deliberately: an "unknown
# provenance" value is exactly the ambiguity this replaced.
#
# target_blast_radius — int 0..9. Anticipated component count of the build work
#   this inception would authorise on GO; substitutes for the absent
#   components: list in the F8 cost formula (040).
#   Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem
#   (M), 7=multi-arc (L), 9=framework-wide (XL).
# voi_score — float 0..1. Value of Information: expected value of RESOLVING
#   this question, independent of build cost. Higher when the answer affects
#   many tasks or unblocks a strategic decision.
---

# T-898: aef:workflowMeta source= is WRITE-ONLY: the emitter writes it and no reader ever reads it back

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Hypothesis

<!-- REQUIRED before a GO decision (T-866, arc-004). Fill the three blanks below and
     delete this comment. Keep the three phrases — the gate looks for them.

     NOT EVERY INCEPTION HAS ONE, and that is fine. "Research how X works" produces
     understanding, not a delivered outcome, and forcing it into "we will achieve
     <outcome>" would manufacture a fake claim to satisfy a gate — which teaches
     authors to write fiction and is worse than no gate at all.

     If this is that kind of inception, set in the frontmatter:

         inception_kind: research

     and delete this section. The gate then passes. Declare it NOW, while framing the
     work — not later at the decision, when you know whether the hypothesis would have
     been inconvenient. The count of research inceptions is reported, so if the
     exemption quietly becomes the default that is visible rather than silent.

     This is the form the BVP scoring method expects. Every support score in this
     task's value-driver table is an ARGUMENT ABOUT THIS SENTENCE: "support 5 on
     Reliability" means something only once the sentence says what success looks
     like. Without it a score can rank but cannot be wrong, because there is no
     claim for it to be wrong about.

     THE THIRD CLAUSE IS THE ONE THAT BITES. It has to be checkable by someone who
     was not in the room and who reads this in three months. A number, a count, a
     threshold, a named state.

       no  — "...when the system is better"
       no  — "...when the team is more productive"
       yes — "...when 5 consecutive fire-suppression tests pass at every equipped site"
       yes — "...when fw audit reports 0 failures for 3 consecutive nightly runs"
       yes — "...when the importer no longer fabricates a lane for input that has none"

     Writing it is genuinely hard. You are not expected to start from blank: the
     estimator drafts one from this task's own text, and you correct it. Your
     correction is sticky — set `hypothesis_source: human` in the frontmatter and no
     automatic pass will ever overwrite it. -->

We believe that <change>,
we will achieve <outcome>.
We will know that we are successful when we see <measurable signal>.

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
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
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

**Rationale:** DEFER because the defect is latent and the cheap direction is unknowable until something authors the attribute. Measured under T-885 and confirmed under T-886: src/aef-workflow-designer.html:10441 emits source=, no reader anywhere parses it back (the only getAttribute calls on workflowMeta cover uuid/schemaVersion/title/description/tier_default/pageWidth/kind), and zero of the 24 corpus maps and 20 round-trip fixtures carry it. So it cannot currently lose data: there is nothing to lose. Both remedies -- stop emitting it, or read it back -- change a serialisation seam AEF byte-pins, which makes this the operator's and the counterparty's call rather than a test harness's. T-886 handled it honestly in the meantime by excluding it from the round-trip comparison WITH that reason, so it is classified rather than forgotten and the derived denominator will not let it drift. Revisit trigger: the first map or exporter that actually sets source=, at which point it becomes a live silent-drop.

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->
