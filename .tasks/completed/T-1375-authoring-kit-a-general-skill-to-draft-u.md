---
id: T-1375
name: "Authoring kit: a general skill to draft, update and check a workflow map, and
  which of greenfield W-rules become validator checks (greenfield T-390/T-393)"
description: >
  Inception: Authoring kit: a general skill to draft, update and check a workflow
  map, and which of greenfield W-rules become validator checks (greenfield T-390/T-393)

status: work-completed
workflow_type: inception
current_node: frw_end_task
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-11-02T22:00:01Z
last_update: 2026-11-03T07:38:55Z
date_finished: 2026-11-03T07:38:55Z
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
  - ts: '2026-11-02T22:01:03Z'
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

# T-1375: Authoring kit: a general skill to draft, update and check a workflow map, and which of greenfield W-rules become validator checks (greenfield T-390/T-393)

## Problem Statement

Rules that 832 and a consumer agree on (io per object, conditions on decision branches, documents as data objects,
`aef:position` = DI) get lost when an agent drafts, updates or checks a map. They live in sidecar threads, mapping v1.1
and agent memory, and nothing refuses a map that breaks them. greenfield's own maps showed it: detail maps with no io,
10 decisions without conditions, 31 of 46 nodes with a stale `aef:position`. The kit's AUTHORING.md mentions io once.
Research: `docs/reports/T-1375-authoring-kit-map-skill-and-checks.md`.

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

We believe that adding io-and-data sections to AUTHORING.md, a `SKILL.md` entry point in the authoring kit, and six new `validate-workflow.py` warnings with a `--strict` switch,
we will achieve agreed general map rules that refuse a map instead of living in threads and agent memory.
We will know that we are successful when we see `validate-workflow.py --strict --field-catalog` report, on greenfield's maps TRB-T1 and KLS-T1, every finding their check-map.py reports under W-02, W-03, W-07, W-10, W-11 and W-14, so greenfield removes those checks from check-map.py and keeps only W-05 and its project rules.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1375 -->

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

- **IW-1: Should the authoring kit carry a general skill (SKILL.md + references) for drafting, updating and checking a workflow map, and in which form?**
  confidence: 2
  disposition: answered
  rationale: Yes. Add the io and data sections to AUTHORING.md (which mentions io once today), plus a SKILL.md at the kit root that gives the order of work and points to AUTHORING/GENERATE/REVIEW/CORRECT instead of repeating them. The README points to SKILL.md first. Project rules stay in each project. Report section IW-1.
- **IW-2: Which of greenfield's W-rules (W-03, W-05, W-07, W-08, W-10, W-11, W-14) are general enough to become validate-workflow.py checks, and at what severity?**
  confidence: 2
  disposition: answered
  rationale: W-01, W-04 and W-08 are already covered (T-1370 field checks; W-XML-LANE-NO-AUTHORITY). New WARNs: IO-INCOMPLETE (W-02), IO-MISSING (W-03, only when the map carries io somewhere; 13 of 77 tracked maps carry io), GW-BRANCH-UNCONDITIONED (W-07), DOC-PREFIX (W-10, our own rule C), DATA-UNLINKED (W-11), POSITION-DI (W-14). --strict raises them to ERROR. W-05 waits on AEF T-4991. Report section IW-2.

## Exploration Plan

Desk research, one session (done 2026-11-02):
1. Read greenfield's rules file and check script, received whole with matching hashes, stored only in git-ignored
   `build/peer-data/greenfield/` and never run.
2. Compare each checked rule with `tools/validate-workflow.py` 0.37.0.
3. Survey the kit's text (`dist/aef-authoring-kit-0.37.0/`).
4. Count the tracked maps that carry io.

The hypothesis is tested in the build tasks: greenfield runs the new validator on TRB-T1 and KLS-T1 and compares the
findings with its script's.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

**IN:** the kit text (AUTHORING.md, SKILL.md, README pointer) and the general rules as validator warnings with `--strict`.

**OUT:**
- W-05 (Mapping lines; waits on AEF T-4991);
- judgement rules (W-06, W-09, W-12, W-13, W-16), which go into the skill's text only;
- greenfield's project rules (W-17, W-18);
- any change to the designer's drawing.

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated *(the consumer's maps and its rules file; AUTHORING.md mentions io once)*
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested *(each rule checked against validate-workflow.py 0.37.0: three covered, six new, W-05 deferred; the W-03 noise risk measured as 13 of 77 maps carrying io)*
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale *(GO: two builds, kit text and validator warnings with --strict)*

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-1375` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- each proposed check is general: it follows from mapping v1.1, BPMN or a rule 832 itself gave, not from one project;
- each check can be a WARN that leaves today's conforming corpus quiet, with ERROR only under `--strict`;
- the kit text fits two bounded build tasks.

**NO-GO if:**
- the rules turn out to be one consumer's conventions, in which case they stay in its own script;
- the checks would fire on maps that conform today (the T-312 noise).

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

Greenfield's own maps show rules agreed with 832 being lost when an agent drafts or checks a map: detail maps with no io, 10 decisions without conditions, 31 nodes with a stale aef:position. Those rules live in sidecar threads, mapping v1.1 and agent memory. T-1370 has already shown the pattern works: a rule moved into validate-workflow.py and was then caught every time. Revised after the reading. Two build tasks follow:
1. Kit text: AUTHORING.md io/data sections, SKILL.md, README pointer.
2. Validator: six new WARNs (W-02, W-03 partial-io, W-07, W-10, W-11, W-14) plus `--strict`.

W-01, W-04 and W-08 are already covered. W-05 waits on AEF T-4991. W-10 becomes general, because its prefixes are 832's
own rule C. Evidence: their check-map.py found 15 and 17 findings on TRB-T1 and KLS-T1.

**Evidence:**
- `docs/reports/T-1375-authoring-kit-map-skill-and-checks.md`: rule-by-rule comparison, with the validator codes that
  exist today.
- `dist/aef-authoring-kit-0.37.0/AUTHORING.md`: one mention of io in 293 lines.
- `tools/validate-workflow.py`: W-XML-GW-AMBIGUOUS fires only at two or more unconditioned branches;
  W-XML-LANE-NO-AUTHORITY covers W-08.
- 13 of 77 tracked .bpmn files carry io, so W-03 can't fire on maps that have no io at all.

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

**Rationale**: Operator (2026-11-02, recorded by job 121): GO on greenfield's proposal (their T-390/T-393). Agreed general map rules move from threads and memory into the kit. Build 1: AUTHORING.md gets io-and-data sections (io per object with system and operation; fields with fieldRef and role; expect only for this step; Mapping lines; conditions on every branch; documents as data objects; aef:position = DI; documentation prefixes, 832's rule C), a SKILL.md entry point at the kit root, and the README points to it. Build 2: validate-workflow.py gets six WARNs (IO-INCOMPLETE, IO-MISSING only when the map carries io, GW-BRANCH-UNCONDITIONED, DOC-PREFIX, DATA-UNLINKED, POSITION-DI) and --strict to raise them to ERROR, each with fixtures and registry entries. W-05 waits on AEF T-4991; project rules stay in each project. Success: validate-workflow.py --strict --field-catalog reports on TRB-T1 and KLS-T1 every finding check-map.py reports under W-02/03/07/10/11/14. Evidence: docs/reports/T-1375-authoring-kit-map-skill-and-checks.md.

**Date**: 2026-11-03T07:38:55Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-02T22:01:02Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-03T07:38:55Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator (2026-11-02, recorded by job 121): GO on greenfield's proposal (their T-390/T-393). Agreed general map rules move from threads and memory into the kit. Build 1: AUTHORING.md gets io-and-data sections (io per object with system and operation; fields with fieldRef and role; expect only for this step; Mapping lines; conditions on every branch; documents as data objects; aef:position = DI; documentation prefixes, 832's rule C), a SKILL.md entry point at the kit root, and the README points to it. Build 2: validate-workflow.py gets six WARNs (IO-INCOMPLETE, IO-MISSING only when the map carries io, GW-BRANCH-UNCONDITIONED, DOC-PREFIX, DATA-UNLINKED, POSITION-DI) and --strict to raise them to ERROR, each with fixtures and registry entries. W-05 waits on AEF T-4991; project rules stay in each project. Success: validate-workflow.py --strict --field-catalog reports on TRB-T1 and KLS-T1 every finding check-map.py reports under W-02/03/07/10/11/14. Evidence: docs/reports/T-1375-authoring-kit-map-skill-and-checks.md.

### 2026-11-03T07:38:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1165dd1e
- **Timestamp:** 2026-11-03T07:38:57Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-1
     - evidence: `IW-1 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-478299e9
- **Timestamp:** 2026-11-03T07:38:57Z
- **Overall:** CONTRADICTED
- **Claims:** 5

| Claim | Type | Status |
|-------|------|--------|
| `docs/reports/T-1375-authoring-kit-map-skill-and-checks.md` | file | ✓ pass |
| `dist/aef-authoring-kit-0.37.0/AUTHORING.md` | file | ✓ pass |
| `tools/validate-workflow.py` | file | ✓ pass |
| `T-1370` | task | ✓ pass |
| `T-4991` | task | ✗ fail — no task file in .tasks/{active,completed}/ |
