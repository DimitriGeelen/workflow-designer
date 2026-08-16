---
id: T-367
name: "Measure the full aef: layer we inject into third-party documents on open-save"
description: >
  Measure the full aef: layer we inject into third-party documents on open-save

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-04T14:44:51Z
last_update: '2026-08-16T13:58:54Z'
date_finished: 2026-08-08T06:46:08Z
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
  - ts: '2026-08-16T12:33:53Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/_t364-aef-ext-roundtrip.mjs,tools/_t367-aef-injection-footprint.mjs,tools/_t367-injection-footprint-teeth.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t364-aef-ext-roundtrip.mjs,tools/_t367-aef-injection-footprint.mjs,tools/_t367-injection-footprint-teeth.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-367: Measure the full aef: layer we inject into third-party documents on open-save

## Context

Opened at the end of the T-366 session, scoped but NOT started — budget hit the
wrap-up gate. Everything needed to begin is here.

**Why it exists.** AEF proposed at RAIL-441 that uid persistence should follow
*authorship*, not *observation*: derive in memory, persist only on documents we author
or the user edits. Their argument is good — after T-364's repair, derivation removes the
reason persistence was load-bearing, and open-and-save becoming a non-no-op for a
foreign document is a smaller instance of the class T-364 fixed.

I nearly agreed on the spot. What stopped me: their rule targets `aef:uid`, and I have
never measured what ELSE we write into a foreign document. From the byte-identity runs I
can already see `aef:position` on every node, `aef:laneMeta` on every lane,
`aef:workflowMeta` on the process. If uid is 9 elements of 200, fixing uid alone does
not restore the property they want — it just makes the diff shorter. Told them so at
RAIL-442 and promised the number rather than guessing at the ratio.

**Starting points:** `tools/_t364-aef-ext-roundtrip.mjs` already has the harvester
(`harvest()` → Map of kind → attribute maps) and the CDP open→save harness; this is that
probe pointed at real third-party fixtures instead of one synthetic document.
`tests/fixtures/third-party/` is the population (10 files, and per the T-364 census
**none** carries `aef:position` — which is also why they are tie-free).

**Related:** T-364 (the repair that removed persistence's justification), T-358 (the
same should-we-write-this question about lane defaults), the frozen standard §1
(semantic vs presentational partition) and §5/§6.3 (uid MUST be carried — the tension
recorded in T-366, awaiting AEF's scope reading).

## Acceptance Criteria

### Agent
- [x] **The full `aef:*` footprint we add to a third-party document is measured per
      kind, with counts, over all 10 fixtures in `tests/fixtures/third-party/`.**
      Method: harvest every `<aef:KIND>` from the input bytes and from the emitted
      bytes of an open→save, and report the delta by kind. Input counts are expected to
      be 0 for most kinds — state that expectation and let the run confirm it rather
      than assuming it, since a fixture that already carries an `aef:` element would
      quietly turn an injection into a passthrough.

      **`tools/_t367-aef-injection-footprint.mjs`. 10/10 imported, 0 failed. 307
      `aef:` elements injected across 4 kinds:**

      | kind | §1 class | in | out | injected | share |
      |---|---|---|---|---|---|
      | `aef:uid` | SEMANTIC | 0 | 149 | 149 | 48.5% |
      | `aef:position` | PRESENTATIONAL | 0 | 120 | 120 | 39.1% |
      | `aef:laneMeta` | UNCLASSIFIED | 0 | 28 | 28 | 9.1% |
      | `aef:workflowMeta` | UNCLASSIFIED | 0 | 10 | 10 | 3.3% |

      **Input carried zero `aef:` elements — measured, not assumed.** The counts
      reconcile exactly against the import: uid 149 = 120 nodes + 29 edges;
      position 120 = nodes; laneMeta 28 = 3×8 fabricated + 2×2 preserved;
      workflowMeta 10 = one per document. A census that did not reconcile would be
      the first sign the harvester was matching something other than what it names.

- [x] **`aef:uid`'s share of that footprint is stated as a fraction, not a verdict.**
      This is the number the whole question turns on. AEF's RAIL-441 recommendation
      ("uid persistence follows authorship, not observation") targets uid alone; if uid
      is a small minority of what we inject, then their rule is right and its SCOPE is
      wrong — it should be "we do not add an `aef:` layer to documents we did not
      author", of which uid is one line. Do not pre-judge which way it lands.

      **uid is 149 of 307 = 48.5%.** Stated as a fraction, and the conclusion is
      deliberately NOT hung on which side of 50% it fell — the first draft of the
      probe branched its verdict on a `>= 50` threshold, which would have made the
      recommendation to AEF flip on a coin-toss margin. Rewritten to conclude from
      the residue instead: RAIL-441 as written removes 149 and **leaves 158**, so
      open-and-save stays a non-no-op. That holds at 48.5% and would hold at 80%,
      because the property AEF wants back is binary.

- [x] **The measurement distinguishes SEMANTIC from PRESENTATIONAL injection**, per the
      frozen standard §1 two-class partition. `aef:position` is presentational and a
      change to it alone MUST be a task-graph no-op; `aef:uid` is semantic. An
      injection footprint that is 90% presentational is a different argument from one
      that is 90% semantic, and reporting a single total would hide exactly that.

      **SEMANTIC 149 (48.5%) · PRESENTATIONAL 120 (39.1%) · UNCLASSIFIED 38 (12.4%).**

      The third bucket is a finding, not a rounding step. §1 opens "Every `aef:`
      datum is exactly one of two classes" and declares the partition normative, but
      it **enumerates** rather than defines, and this build emits two kinds in
      neither list: `aef:laneMeta` (28×) and `aef:workflowMeta` (10×). Folding them
      into PRESENTATIONAL because they are absent from the semantic list would be a
      ruling wearing the costume of a measurement — the standard is frozen and the
      fence is AEF's. `aef:laneMeta` in particular carries `authority=`, which is
      Axis-1 governance data, so guessing "presentational" would have guessed wrong
      in the direction that understates the finding.

- [x] **The probe has a negative control**: at least one kind that we do NOT inject
      must be shown absent from the output, so a run reporting "we inject everything"
      can be distinguished from a harvester that matches too broadly (T-364's
      21-invented-findings failure — see [[anomaly-counts-need-their-members]]).

      **20 of 24 emittable kinds are not injected** — `meta`, `endpoint`,
      `contextReads`, `artifactsWrites`, `decisionInput`, `decisionOutputs`, `link`,
      `eventDef`, `boundaryPos`, `io`, `input`, `output`, `constituents`,
      `constituent`, `anchors`, `loopDetour`, `forceStraight`, `routingHint`,
      `routing`, `waypoint`.

      Three controls, because the failure modes differ, and the third is the one that
      makes the negative control mean anything:
      1. **positive** — `aef:uid` must be injected, else the save never ran;
      2. **negative** — the 20 above, drawn from the emitter's own vocabulary so each
         bucket was reachable;
      3. **harvester capability** — `harvest()` is run against a document carrying
         all 24 kinds and must find every one, BEFORE any zero is read as "not
         injected". Without it a missing witness and an invisible one are the same
         output ([[unreachable-witnessing-state]]).

      Plus an **over-match guard**: a decoy with one live element, one commented-out
      mention and one entity-escaped mention. The harvester does match inside XML
      comments, so every count in the census is taken over comment-stripped bytes.
      The fixtures happen to carry no comments at all, which makes the exposure inert
      *on this corpus* — a property of the corpus, not the instrument, so the strip
      is applied rather than the risk argued away ([[prose-in-exported-bytes]]).

      **Teeth: `tools/_t367-injection-footprint-teeth.py`, 4 legs, all pass.**
      (a) removing `aef:uid` emission ⇒ positive control fires; (b) emitting all 24
      kinds ⇒ negative control fires; (c) removing `aef:position` emission ⇒ run
      stays green but the total moves 307→187 and the row leaves the table, proving
      the census tracks the emitter rather than reprinting a vocabulary.

- [x] **Result posted to AEF**, since it was promised at RAIL-442 and it bears directly
      on whether their proposed rule is worth either side implementing.

      **Posted at RAIL-444**, in reply to their RAIL-443. The post carries the census,
      the residue argument, the structural (non-`aef:`) injection, and the §1
      enumeration gap — the last landing directly on a §1 question their operator had
      just asked in the same message.

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

node tools/_t367-aef-injection-footprint.mjs
python3 tools/_t367-injection-footprint-teeth.py

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

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

### 2026-08-08 — the measurement was scoped to `aef:` and the honest answer is not

- **Chose:** measure the core-BPMN structural injection alongside the `aef:` layer,
  even though the task asked only for the `aef:` layer.
- **Why:** 8 of the 10 fixtures contain **no lane at all** and every one of them comes
  back carrying three, plus the enclosing `laneSet`; 6 gain a `<bpmn:participant>` the
  input never had. Those are core BPMN — every other tool renders them — and **no
  `aef:`-scoped rule removes a single one.** Reporting "we inject 307 `aef:` elements"
  and stopping would have been a careful number answering a narrower question than the
  reader's, which is the shape of [[measurement-promoted-past-its-scope]] with the
  scope error on my side rather than in the prose.
- **Rejected:** answering exactly what was asked and filing the structural part as
  follow-up. The two numbers only mean something together: `aef:laneMeta` (28) is
  *downstream* of the fabricated lanes, so quoting it as an `aef:` injection without
  the lanes attributes it to the wrong cause.

### 2026-08-08 — the verdict does not branch on the 48.5%

- **Chose:** conclude from the residue (158 elements left after RAIL-441) rather than
  from whether uid is a majority.
- **Why:** the first draft printed one recommendation at `uid >= 50%` and the opposite
  below it. uid measured **48.5%** — a coin-toss margin deciding what I tell the peer
  to build. The residue framing is threshold-free and strictly stronger: any residue
  defeats a no-op property, so the conclusion holds at 80% too.
- **Rejected:** keeping the threshold and noting the margin was narrow. A caveat next
  to a verdict does not stop the verdict being carried into prose alone.

### 2026-08-08 — `laneMeta`/`workflowMeta` left UNCLASSIFIED rather than assigned

- **Chose:** a third bucket, reported as a gap in the frozen standard.
- **Why:** §1 says the partition is total but enumerates rather than defines, and these
  two kinds are in neither list. `aef:laneMeta` carries `authority=`, which is Axis-1
  governance data, so the "obvious" default of presentational would have been wrong in
  the direction that *understates* the finding. An absence in an enumeration cannot
  carry a classification decision ([[absence-cannot-carry-a-decision]]), and the
  document is frozen and not mine to interpret.
- **Rejected:** folding them into PRESENTATIONAL to produce a clean two-way split.

### 2026-08-08 — bizagi's total loss reported as consequence, not as a new defect

- **Chose:** attribute it to T-348 (`processes[0]` first-only) meeting T-358 path (iii),
  and report only the consequence as new.
- **Why:** `bizagi-nested-ns.bpmn` has two processes — the first an empty stub, the
  second holding all the content — so the importer reads the stub and yields **0 nodes,
  0 edges** from a 9 KB document. Saving emits a file containing *none* of the author's
  content: three invented governance lanes, our namespace, `isExecutable` flipped to
  true. That is substitution reading as preservation, and it reports as a clean import
  because `parseBpmnXml` returns a map rather than null. But the **cause is already
  filed twice over**, and presenting it as a discovery would double-count a known defect
  ([[incidents-direct-attention]]).
- **Rejected:** opening a new bug task. One bug = one task, and this bug has one.

### 2026-08-08 — teeth leg (a) was single-site against a two-site emission

- **Chose:** record the near-miss rather than quietly fixing the anchor.
- **Why:** leg (a) removes `aef:uid` emission and requires the positive control to fire.
  The first version removed only the **node** site (`src` ~9269) and the leg went
  **green** — 29 edge uids from the second site (`src` ~9575) kept the control
  satisfied, and the control was *right* to be satisfied, because the save had in fact
  run. A single-site mutation against a two-site emission proves nothing and fails in
  the direction that looks like success. Same shape as [[g-009-whole-tree-sweep]], with
  the instrument as the subject. The reconciliation (149 = 120 nodes + 29 edges) is what
  made the two sites visible.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-04T14:44:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-367-measure-the-full-aef-layer-we-inject-int.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6cf3f807
- **Timestamp:** 2026-08-08T06:46:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T06:46:08Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
