---
id: T-889
name: "aef:meta authority on the element — the single semantic fact, with the vocabulary
  read from one place"
description: >
  T-888 ruling clause 2. Add 'authority' to the semantic governance meta-keys carried
  on aef:meta, values sovereignty|authority|initiative|external, read by the compiler
  directly and never resolved by lane membership or document order. AUTHORITIES is
  already a module-scope set in tools/validate-workflow.py read by both forms (T-322)
  — reuse it, do not re-list it. Ruling: docs/reports/T-888-authority-ruling.md. Evidence:
  four external consults in .context/consults/.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [arc:designer-authoring-surface]
components: []
related_tasks: []
arc_id: designer-authoring-surface
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T10:41:17Z
last_update: 2026-09-27T14:14:49Z
date_finished:
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
bvp_scores_proposed:
  - ts: '2026-09-27T13:01:52Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 0
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=3 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-889: aef:meta authority on the element — the single semantic fact, with the vocabulary read from one place

## Context

Clause 2 of the T-888 ruling (`docs/reports/T-888-authority-ruling.md`): the element carries its
authority, as one field with one home, read by the compiler **directly** — never by scanning lane
membership, never resolved by document order.

**The seam as measured at the start of this task (2026-09-27), which is not what the task
description assumed.** `authority` is *already* in the bridge's `META_KEYS`
(`tools/yaml-to-bpmn.py:55`), so the bridge has been emitting element-level
`aef:meta authority=` all along. The editor's `metaKeys` (`src/aef-workflow-designer.html:10028`,
20 keys) does **not** carry it, so on the editor side the attribute survives only by T-570
*carriage* — read into `node.aef`, rendered nowhere, re-emitted only because the source document
happened to carry it. And `tools/validate-workflow.py` reads `authority` only off `laneMeta`
(:1643), then derives node authority by walking `flowNodeRef` into `node_authority[ref]` (:1676)
— the exact lane-membership resolution the ruling retires.

So the element-level attribute is today **emitted by the bridge, carried by the editor, and
validated by nothing.** That is the T-329 disease one level down: T-329's finding was that
`authority="overlord"` was carried faithfully into `<aef:laneMeta>` and read by nothing; the same
sentence is true of `<aef:meta>` right now.

Corpus census (all `*.bpmn`): 155 `initiative`, 132 `authority`, 112 `sovereignty`, 15 `external`,
15 `none`.

## Acceptance Criteria

### Agent
- [ ] **`authority` is a first-class editor meta-key, not T-570 carriage.** `metaKeys` goes 20 → 21.
      The discriminator matters: carriage can only re-emit a key the *source document* already
      carried, so subset-parity with the bridge would pass either way. The proof is therefore an
      export that emits `aef:meta authority=` for a node whose source document carried **no**
      authority attribute at all — an outcome carriage cannot produce.
      **NOT TICKED — and the half that is done is not the half this AC asks for.** Both
      static halves hold and are checked by the teeth script: `metaKeys` is 20 → 21 (leg C5)
      and the panel now offers the writer via `AEF_FIELDS` on the four task-like types
      (leg C6). What is NOT done is the AC's actual proof: driving the editor in a browser
      to set authority on a node loaded from an authority-free document, exporting, and
      observing the attribute. That needs CDP plumbing (the harness's `SRC_HTML` is not
      overridable and its sidecar must be up) which this round did not have budget to
      build. Per the run's auditability rule, an assertion without the check that
      demonstrates it is an open criterion, so this box stays empty rather than being
      argued closed from the two static halves.
- [x] **The element value is validated against the module-scope `AUTHORITIES`, listed exactly
      once.** A node carrying `<aef:meta authority="overlord">` becomes a validation error naming
      the allowed set. `AUTHORITIES` is reused from module scope, not re-listed — a second copy of
      the vocabulary is how the one-form-only family reproduces itself one level down (T-322/T-329
      reasoning, quoted in the code at :1664).
- [x] **The read is direct, and both halves of "direct" are proven separately.**
      (a) *Not lane membership:* a node whose own `aef:meta authority` differs from its lane's
      `laneMeta authority` reads as its OWN value.
      (b) *Not document order:* the same document with the `laneSet` moved to a different position
      yields the same answer. Clause 2 names both prohibitions, so one control cannot cover it —
      (a) alone would still pass an implementation that read the element but tie-broke on order.
- [x] **The round-trip guard covers it BY DERIVATION, and the red is observed rather than
      asserted.** `checkDenominator()` reads the `metaKeys` literal out of the emitter source
      (`tools/_roundtrip-serialization-cdp.mjs:250`), so adding `authority` must make the guard go
      red on its own — `emitter-projected key(s) in NEITHER KEYSPEC nor EXCLUDED: authority` —
      before KEYSPEC classifies it. Record the observed red output and then the green, not a claim
      that it would have gone red. This is the T-886 payoff and the sequencing the ruling's cost
      section demanded.
- [x] **Mutation-killed.** `tools/_t889-authority-on-the-element-teeth.sh --mutation` deletes the
      editor's authority writer and, separately, the validator's element-level read, and each
      mutant is killed by a named check. Its CONTROL SET reports `MUTATION SETUP BROKEN` rather
      than reading a broken harness as a clean kill (T-866 pattern).
- [x] **The `none` tension is filed, not silently resolved.** `AUTHORITIES` holds five values;
      the ruling retires `authority="none"`; the corpus carries 15 of them. This task introduces
      `none` on no element and does not remove it from `AUTHORITIES` either — the retirement is a
      distinct deliverable with its own blast radius across both forms, and is filed as its own
      task rather than smuggled in here (one task = one deliverable).

### Human

_None, deliberately._ Every criterion above is a deterministic shell check, so per the T-1811
prefix-routing rule they belong here as Agent ACs with commands in `## Verification`,
not as [REVIEWER] Human ACs. The one genuinely sovereign question this change sits next
to — the counterparty's agreement to a schema addition on a seam AEF byte-pins — is
**T-896's** deliverable, not a review step on this one.

<!-- NOTE (T-889): the tail of this section, and the original `## Verification` template
     comment, were destroyed by my own edit: I sliced the file on `s.index('## Verification')`
     and that matched the PROSE MENTION on the line above rather than the heading, cutting
     everything between. Restored by hand; the lost content was the boilerplate template
     comment. Recorded here rather than quietly repaired. -->

## Verification

# The teeth script: 6 controls + 3 mutation kills, with a setup control that fails loudly
# rather than reading a broken mutant tree as a clean kill.
timeout 900 bash tools/_t889-authority-on-the-element-teeth.sh --mutation > /tmp/.t889teeth.out 2>&1 && grep -q "all legs passed" /tmp/.t889teeth.out
# The round-trip guard is green on the real tree (denominator clean, all fixtures ok).
timeout 300 node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t889rt.out 2>&1 && python3 -c "import json,sys; d=json.load(open('/tmp/.t889rt.out')); sys.exit(0 if d.get('pass') else 1)"
# The new rule is registered in BOTH parity registries. Scoped to this rule deliberately:
# the suites themselves are red for E-WORKFLOW-KIND / E-XML-WORKFLOW-KIND, which are
# T-875's and are filed as T-903 — pinning the whole suite here would block on another
# task's debt and would rot the moment that debt is paid.
grep -q '"E-XML-META-AUTHORITY":     (("aef:meta/@authority",), CONSTRAINS)' tests/test_rule_dialect_axis.py
grep -q '"aef:meta/@authority":      SEMANTIC_MUST' tests/test_rule_dialect_axis.py
grep -q '"E-XML-META-AUTHORITY": (GAP,' tests/test_rule_form_parity.py
# The vocabulary is reused, not re-listed: exactly one AUTHORITIES literal in each form.
test "$(grep -c "^AUTHORITIES = {" tools/validate-workflow.py)" = "1"
test "$(grep -c "^const AUTHORITIES = \[" src/aef-workflow-designer.html)" = "1"

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

### 2026-09-27 — the premise was capability, not behaviour

- **What changed:** The task body states the bridge "has been emitting element-level
  `aef:meta authority=` all along", and gives a corpus census of 155/132/112/15/15.
  Measured across all **201** `*.bpmn` in the repo, **4892** nodes: element-level
  `<aef:meta authority=>` occurs **ZERO** times. All **500** `authority=` attributes in
  the corpus sit on `<aef:laneMeta>`, distributed 179 initiative / 156 authority /
  128 sovereignty / 19 external / 18 none.
  (First pass of this census used the wrong AEF namespace — `http://aef.dev/schema/1.0`
  rather than the real `http://anchorpoint.framework/aef/extensions` — and reported
  94 files / 2130 nodes. The ZERO held under the corrected namespace, and independently
  under a namespace-agnostic text grep, which is why the conclusion survived the error.) So the census in the body was
  counting LANE values, and under-counting them.
  `authority` *is* in the bridge's `META_KEYS` (`tools/yaml-to-bpmn.py:56`), so the bridge
  **can** emit an element-level value — but no source step carries the key in its aef bag,
  so it never has. Capability, not behaviour.
- **Plan impact:** Makes "the element wins" strictly safer than the task assumed. With no
  element carrying the attribute, demoting the lane walk to a fallback cannot change any
  current verdict — confirmed by running the pre-change and post-change validator over all
  201 files: **0 behavioural differences** (exit code and stdout identical on every file).
  Re-run after the O-3 message was reworded to name its source: **0 exit-code differences
  and 0 rule-id-set differences** over the same 201 files.
  The switch only takes effect as T-895 migrates lane values onto elements. The task's
  framing of this as an urgent live defect ("emitted by the bridge, carried by the editor,
  validated by nothing") overstates it: the third clause was true, the first was not.
- **Triggered:** T-901 (retire `authority="none"` across both forms) — filed rather than
  smuggled in, per AC 6. Its blast radius is larger than a delete: T-331 made
  `AUTHORITY_OWNER` / `AUTHORITY_NO_OWNER_DERIVABLE` a TOTAL partition of `AUTHORITIES`
  (`:100-108`), so removing a value breaks a totality invariant.

### 2026-09-27 — the guard derivation paid off, observed not asserted

- **What changed:** Adding `authority` to `metaKeys` made the round-trip guard fail on its
  own, before any KEYSPEC edit: `1 emitter-projected key(s) in NEITHER KEYSPEC nor
  EXCLUDED: authority`, `denominator_failed: true`, exit 2. Then green at 20/20 fixtures
  once classified. This is the T-886 payoff working exactly as its author predicted.
- **Plan impact:** None — this is the sequencing the ruling's cost section demanded, and it
  held.
- **Triggered:** Nothing new.

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-27T10:41:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-889-aefmeta-authority-on-the-element--the-si.md
- **Context:** Initial task creation

### 2026-09-27T13:01:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
