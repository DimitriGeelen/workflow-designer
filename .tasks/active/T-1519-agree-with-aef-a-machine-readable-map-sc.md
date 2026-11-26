---
id: T-1519
name: "Agree with AEF a machine-readable map scope attribute (framework | project)
  on aef:workflowMeta, so vendoring can ship only framework maps"
description: >
  Inception: Agree with AEF a machine-readable map scope attribute (framework | project)
  on aef:workflowMeta, so vendoring can ship only framework maps

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
waiting_on: agent
revisit_at: 2026-12-02
created: 2026-11-25T09:24:41Z
last_update: 2026-11-26T09:42:03Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): the two values below are PLACEHOLDERS, not an assessment. The BVP
# estimator ignores any value without `<field>_source: human` and estimates it from this task's own text, so a
# 0.5 nobody chose no longer ranks as "judged middling". They stay filled because AEF's T-2188 schema hook
# refuses an edit to an inception without them (T-1178; T-865 had deleted them before that hook arrived here).
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-11-26T09:39:37Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 1
      D2: 1
      D3: 1
      D4: 1
      F-RECALL: 1
      F2: 1
      F4: 1
      F3: 1
      F1: 1
    rationale: D1=1 (voi:no-leverage-signal (measured low, not unassessed)); 
      D2=1 (voi:no-leverage-signal (measured low, not unassessed)); D3=1 
      (voi:no-leverage-signal (measured low, not unassessed)); D4=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F-RECALL=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F2=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F4=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F3=1 
      (voi:no-leverage-signal (measured low, not unassessed)); F1=1 
      (voi:no-leverage-signal (measured low, not unassessed))
    rubric_sha: e4a00f38e801
---

# T-1519: Agree with AEF a machine-readable map scope attribute (framework | project) on aef:workflowMeta, so vendoring can ship only framework maps

## Problem Statement

AEF's review of the T-1516 skill (msg b5d90d48): an AEF-development map shipped to every consuming project because
nothing in a map says whether it is a framework process (ships to every project) or one project's own (must not ship).
AEF wants a machine-readable mark so a vendoring step can ship only framework maps (their T-5393), and asked to agree
the attribute with 832 before either side uses it. It is a change to the two-party map contract (mapping v1/v1.1), so it
is agreed first and decided by the operator. Research and dialogue: `docs/reports/T-1519-map-scope-attribute.md`.

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

We believe that a `scope` attribute on `aef:workflowMeta` (`framework` | `project`, absent read as `project`),
checked by the validator and editable in the designer,
we will achieve that only framework maps ship to consuming projects.
We will know that we are successful when we see AEF's vendoring step ship 0 maps whose `scope` is not `framework`, and
the map that shipped by mistake (their T-5393) no longer ships.

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

- **IW-1: What is the attribute called, and which values does it take?**
  confidence: 3
  disposition: answered
  rationale: `aef:workflowMeta/@scope` = `framework` | `project`, agreed by AEF (msg ab4c1d03, their T-5415; their operator to confirm); no third value needed, a later one would be a new value, not a list (report §2, §6)
- **IW-2: What does a map with no attribute mean?**
  confidence: 3
  disposition: answered
  rationale: `project` (fail safe), agreed by AEF (msg ab4c1d03); AEF marks its framework maps and ships its filter in one release so nothing silently stops shipping (report §3)
- **IW-3: Where does it live: a new attribute, or a new value of `kind`?**
  confidence: 3
  disposition: answered
  rationale: a separate attribute, agreed by AEF (msg ab4c1d03): kind = what sort of map, scope = whose (report §4)
- **IW-4: What do the validator, the designer and the kit do with it?**
  confidence: 3
  disposition: answered
  rationale: agreed split (msg ab4c1d03): 832 validator checks the value, designer Scope select, AUTHORING 6 and the skill document it; AEF's fw vendor filter and its test are AEF's (report §5)

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
  **Why you:** direction — a new attribute in the two-party map contract with AEF is a contract change, and `fw inception decide` is the operator's
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

**Recommendation:** GO

**Rationale:** both sides agree the whole proposal (report `docs/reports/T-1519-map-scope-attribute.md`; AEF msg
ab4c1d03, their T-5415): `aef:workflowMeta/@scope` = `framework` | `project`, absent read as `project`, separate from
`kind`, 832 builds the validator check, the designer's Scope select and the docs; AEF builds the vendoring filter. It is
additive and optional, so no stored map changes or becomes invalid. Building waits for both operators: AEF's operator
confirms on their side; ours decides here.

**Evidence:**
- An AEF-development map shipped to every consumer because nothing marks scope (AEF T-5393, msg b5d90d48).
- AEF agreed all four questions and needs no third value (msg ab4c1d03).
- No `workflowMeta` attribute is called `scope` today (validator and designer checked); `kind` stays as it is.

**If GO:** one 832 build task (validator value check + designer Scope select + AUTHORING 6 + skill rule 1), released
with AEF's filter release in mind (AEF ships marks and filter together).

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

<!-- Filled at completion via: fw inception decide T-XXX go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-26T09:39:36Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
