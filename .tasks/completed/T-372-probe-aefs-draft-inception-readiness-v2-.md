---
id: T-372
name: "Probe AEF's draft-inception-readiness v2 cycle fixture through our importer (RAIL-445 Q2)"
description: >
  Probe AEF's draft-inception-readiness v2 cycle fixture through our importer (RAIL-445 Q2)

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T07:30:29Z
last_update: 2026-08-08T07:50:00Z
date_finished: 2026-08-08T07:50:00Z
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

**Status: COMPLETE — input side and round-trip both measured.** The input side was committed
and sent first, in a prior session that stopped at the context budget rule (>75%), because it
was the time-critical half: they were drafting v3 against identifiers that do not exist. The
round-trip followed here.

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

### Round-trip result: 7/7 survive

Measured 2026-08-08 by `tools/_t372-aef-cycle-roundtrip.mjs`. 17 nodes / 18 edges / 3 lanes
in, same out. Every claim also proven to go **red** under a mutation targeted at it.

```
C1  fw_2_proposed keeps exactly 3 outbound edges     PASS  -> agt_4_explore, fw_3_put, hum_1_operator
C2  return edge fw_2_proposed -> agt_4_explore       PASS  flow_7   (cross-lane framework -> agent)
C3  return edge hum_1_operator -> agt_4_explore      PASS  flow_10  (cross-lane human -> agent)
C4  forward edge fw_2_proposed -> fw_3_put           PASS  flow_9
C5  agt_4_explore still a COLLAPSED subProcess       PASS  bpmn:subProcess, 0 child flow elements
C6  lane membership of all cycle participants        PASS  framework/agent/human intact
C7  agt_4_explore keeps all 3 inbound edges          PASS  agt_3_create, fw_2_proposed, hum_1_operator
```

### What the run corrected — my own probe had the defect it was written to catch

The expected-loss line said the doc comment would be lost because "comments are not retained
through parse→emit". **The prediction was right and the reason was wrong**, and the first
version of the check could not tell the difference.

It counted comments: `1 in, 1 out`, and reported that as the expected loss NOT occurring —
i.e. it would have told AEF their comment survives. It does not. It is **replaced**:

```
LOST : <!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->
NEW  : <!-- BPMN DI (visual layout) omitted; node geometry travels as aef:position -->
```

A total cannot tell *kept* from *replaced* — `substitution-reading-as-preservation`, in a
probe written while holding that exact memory. Fixed to compare comment **text**.

The real mechanism is finer than "comments are dropped", and it is not damage: AEF's comment
is a **trailer** (char 18290 of 18403, after `</bpmn:process>`). T-311 retains the *leading*
comment child of `<bpmn:definitions>` and refuses trailers deliberately — promoting our own DI
trailer to rationale is the defect that poisoned 5 of AEF's 11 maps. The consequence for them
is that a re-pin diff shows a **changed** line carrying text they did not write, not a removed
one.

### The advice I nearly gave was wrong, and a control caught it

The obvious next sentence to AEF is "put rationale in the leading slot and it survives". I was
about to send that on the strength of reading T-311's header. T-311 point 5 says a **hoisted**
trailer is refused by *content*, not position — so for this exact string the advice could be
false. Measured both, on their document:

```
their trailer text HOISTED to leading position  : REFUSED
a distinct authored rationale, leading position : KEPT
```

Position alone is not enough; the guard reads content. The advice is therefore "author
rationale in the leading slot" — **not** "move the DI boilerplate up", which would have been a
confident instruction that silently does nothing.

## Acceptance Criteria

### Agent
- [x] Fixture identity pinned before any measurement: fetched from AEF's ref, sha256 and byte
      count asserted against the values they published (`fe3a520d…`, 18472 B). A probe over
      unverified bytes measures an unknown document.
- [x] The named topology is confirmed to EXIST in the input before import — and it did NOT
      under the ids given; resolved to the real ids, shape confirmed intact. If the gateway,
      the two return edges, or the cross-lane subProcess re-entry are not there to begin with,
      every "survived" verdict is vacuous — the population cannot contain the defect.
- [x] Round-trip measured (import → export) on these specific claims: the `fw_6_readiness`
      gateway retains **three** outbound edges; both return edges survive; the edge from
      `hum_7_dialogue` back into `agt_4_explore` survives; `agt_4_explore` remains a
      **collapsed subProcess** and is not flattened or re-parented; lane membership of every
      cycle participant is unchanged.
      → `tools/_t372-aef-cycle-roundtrip.mjs`, **7/7 PASS** against the corrected ids.
        17 nodes / 18 edges / 3 lanes in, same out.
- [x] **Expected-loss list stated up front, not after seeing results.** The doc comment is our
      T-311 and AEF explicitly asked that it not be reported as a finding. Anything else that
      drops is a finding. Declaring this before measuring is what stops the result being
      retro-fitted to whatever came out.
      → declared in code before the run and **left unedited afterwards**. The prediction held
        (the comment does not survive); the *reason* I gave for it was wrong, and the run is
        what corrected it — see "What the run corrected" below. The correction is recorded as
        a post-run annotation, not as a rewrite of the declaration.
- [x] **Positive control:** at least one asserted property must be one our exporter could
      plausibly break, and at least one must be verified to change when deliberately mutated —
      otherwise a clean run cannot distinguish "preserved" from "not examined".
      → stronger than asked: **all 7** claims are re-checked against output mutated to break
        exactly that claim, and **all 7 go red**. A claim that cannot go red exits the harness
        non-zero and the verdicts are declared unreadable. Plausibility is on the record too:
        `PROVENANCE.md` already documents that this importer flattens nested subProcesses, so
        C5 (collapsed subProcess) is a claim about a failure mode this build has exhibited.
- [x] Result reported to AEF on the rail with per-claim verdicts, before promotion of their v3.
      → RAIL-449. All 7 verdicts, the teeth pass, the comment substitution (incl. that my own
        first check would have told them the opposite), and the corrected leading-slot advice
        with the measurement behind it. Scope limits stated so a 7/7 is not read as clearance
        of the whole fixture; T-347 named as a separate open class this probe did not measure.

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
python3 -c "import hashlib; d=open('tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn','rb').read(); assert len(d)==18472, len(d); assert hashlib.sha256(d).hexdigest()=='fe3a520ddd51523e3cdd55da0aea428368a07b05e481246c837c6330d9c4a846'; print('fixture identity OK')"
node tools/_t372-aef-cycle-roundtrip.mjs
```

<!-- The fixture path was a session-scoped scratchpad path when this task was filed. That
     is a moving reference: the probe would have gone unrunnable the moment the session
     ended, and a verification line that cannot run is not a gate. Vendored into
     tests/fixtures/third-party/ with the digest pinned in both the probe and PROVENANCE.md. -->


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

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ef43af9f
- **Timestamp:** 2026-08-08T07:50:02Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T07:50:00Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
