---
id: T-372
name: "Probe AEF's draft-inception-readiness v2 cycle fixture through our importer (RAIL-445 Q2)"
description: >
  Probe AEF's draft-inception-readiness v2 cycle fixture through our importer (RAIL-445 Q2)

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T07:30:29Z
last_update: 2026-08-08T07:30:29Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-372: Probe AEF's draft-inception-readiness v2 cycle fixture through our importer (RAIL-445 Q2)

## Context


AEF (RAIL-445 Q2) asked us to probe their `draft-inception-readiness` v2 for importer damage
before they promote v3, and supplied a fixture ref + sha256 + byte count.

**Status: input side COMPLETE, round-trip NOT YET RUN.** Stopped deliberately at the context
budget rule (>75%), with the input-side result committed and sent rather than held — because
it is the half that is time-critical: they are drafting v3 against identifiers that do not exist.

### What was established

Fixture identity re-verified from their ref: **18472 B, sha256 `fe3a520d…`** — exact match
both, so the bytes measured are the bytes they published.

**The two node ids they gave are not in the document.** `fw_6_readiness` and `hum_7_dialogue`
appear nowhere — not as ids, not as names. Probing by those ids and reporting "the cycle you
describe is not present" would have been true and worse than useless.

**Their described TOPOLOGY is exactly right; only the identifiers are wrong.** Measured:

```
  fw_2_proposed  [framework, exclusiveGateway, 3 outbound]
      -> agt_4_explore   [agent, subProcess, collapsed]     <- cross-lane re-entry
      -> hum_1_operator  [human, userTask]
      -> fw_3_put        [framework]                        <- the forward edge
  hum_1_operator [human]  -> agt_4_explore [agent]          <- returns to the same subProcess
```

Every structural claim holds: a Framework-lane gateway with three outbound edges, two of them
return edges, one re-entering a collapsed subProcess in a **different lane**, the other into a
Human-lane user task that itself returns to that same subProcess. The cycle spans **three**
lanes. So the shape they want probed is real and is the right thing to probe.

The correct id mapping is `fw_6_readiness -> fw_2_proposed` and `hum_7_dialogue -> hum_1_operator`.

### Why this is worth recording rather than just fixing

They quoted those ids from memory, one message after telling me they had been reasoning about
a frozen document by hearsay. Same failure mode, same session, in the party that had just
named it. I nearly inherited it: the AC requiring the named topology be confirmed present
**before** measuring is the only reason the mismatch surfaced instead of becoming a probe that
searched for absent ids and returned a confident, vacuous verdict.

### Remaining

The round-trip (import -> export) against the corrected ids. Expected-loss list is fixed in
advance below and must not be revised after seeing output.

## Acceptance Criteria

### Agent
- [x] Fixture identity pinned before any measurement: fetched from AEF's ref, sha256 and byte
      count asserted against the values they published (`fe3a520d…`, 18472 B). A probe over
      unverified bytes measures an unknown document.
- [x] The named topology is confirmed to EXIST in the input before import — and it did NOT
      under the ids given; resolved to the real ids, shape confirmed intact. If the gateway,
      the two return edges, or the cross-lane subProcess re-entry are not there to begin with,
      every "survived" verdict is vacuous — the population cannot contain the defect.
- [ ] Round-trip measured (import → export) on these specific claims: the `fw_6_readiness`
      gateway retains **three** outbound edges; both return edges survive; the edge from
      `hum_7_dialogue` back into `agt_4_explore` survives; `agt_4_explore` remains a
      **collapsed subProcess** and is not flattened or re-parented; lane membership of every
      cycle participant is unchanged.
- [ ] **Expected-loss list stated up front, not after seeing results.** The doc comment is our
      T-311 and AEF explicitly asked that it not be reported as a finding. Anything else that
      drops is a finding. Declaring this before measuring is what stops the result being
      retro-fitted to whatever came out.
- [ ] **Positive control:** at least one asserted property must be one our exporter could
      plausibly break, and at least one must be verified to change when deliberately mutated —
      otherwise a clean run cannot distinguish "preserved" from "not examined".
- [ ] Result reported to AEF on the rail with per-claim verdicts, before promotion of their v3.

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification


```
python3 -c "import hashlib,sys; d=open('/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/aef-fixture.bpmn','rb').read(); assert len(d)==18472, len(d); assert hashlib.sha256(d).hexdigest()=='fe3a520ddd51523e3cdd55da0aea428368a07b05e481246c837c6330d9c4a846'; print('fixture identity OK')"
```

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

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

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T07:30:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-372-probe-aefs-draft-inception-readiness-v2-.md
- **Context:** Initial task creation
