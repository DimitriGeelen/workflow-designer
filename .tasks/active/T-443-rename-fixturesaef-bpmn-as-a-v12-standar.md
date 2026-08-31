---
id: T-443
name: "Rename fixtures/aef-bpmn as a v1.2 standard delta - PENDING AEF ruling (T-365
  option D)"
description: >
  T-365 measured that tests/fixtures/aef-bpmn is normative in a FROZEN two-party standard:
  aef-bpmn-mapping-v1.md:142 names inception-gonogo.bpmn as a Reference fixture inside
  Part I (Part II begins at 146), and aef-bpmn-forward-compile-v1.md:21 names the
  corpus with section 5 titled after the path. So the rename is a standard delta,
  not a refactor, and is not the agent's to make. T-365 shipped option C (claim fixed
  at source in PROVENANCE.md + tools/_t365-normative-fixture-guard.py). This task
  carries option D. TRIGGER (FIRED — superseded, read ## Context): AEF answers DM
  548 section 5. If they want the delta it queues with the v1.1 deltas T-189/T-195
  are drafting; if the path stays, close this with that as the reason. Also open at
  DM 548 section 6 (ALSO ANSWERED — DM 556, landed by T-449): confirmation that the
  three pair-drafts (session-handover, dispatch-loop, offpage-seam) are considered
  co-authored on their side - PROVENANCE.md currently asserts it on our evidence alone.
  || STALE-FIELD MARKER 2026-08-12 (T-472) — both triggers fired. AEF ruled KEEP THE
  PATH at DM 549 section 5; section 6 was answered from records at DM 556. The body's
  ## Context has carried the ruling since DM 550. This field was read as current state
  32 rails later and reported to AEF as an outstanding question they had already answered.
  Read the Context, not this field. Disposition by this field's own instruction —
  "if the path stays, close this with that as the reason" — is CLOSE, pending operator
  ratification only.

status: captured
workflow_type: refactor
owner: human
horizon: later
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-11T22:28:50Z
last_update: 2026-08-23T10:24:11Z
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
  - ts: '2026-08-16T12:33:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 5
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=5 
      (prose:seam-contract); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 7
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/fixtures/aef-bpmn/PROVENANCE.md,tests/fixtures/aef-bpmn/inception-gonogo.bpmn,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=3 (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:45Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/fixtures/aef-bpmn/PROVENANCE.md,tests/fixtures/aef-bpmn/inception-gonogo.bpmn);
      tier=3 (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-443: Rename fixtures/aef-bpmn as a v1.2 standard delta - PENDING AEF ruling (T-365 option D)

## Context

**AEF HAS RULED: KEEP THE PATH (DM 549 §5, 2026-08-12). This task's trigger has fired
and the answer is "do not rename" — it is parked on the operator's ratification, not on
AEF any more.**

Their words: *"Recommendation: keep the path. Your reasoning is better than mine would
have been — the failure mode was a reader treating a name as provenance; a new name is
also a name. Renaming moves the ambiguity. PROVENANCE.md fixes the claim at the source,
which protects both trees including the readers who never see the rename."*

So both sides independently reached the same conclusion, from the same argument. The
v1.2 delta this task exists to draft is **not needed** unless the operator overrules it.

What the exchange raised INSTEAD, and it is bigger than the rename (recorded in
`tests/fixtures/aef-bpmn/PROVENANCE.md` under "a reference that crosses the seam"):
AEF's frozen Part I names `tests/fixtures/aef-bpmn/inception-gonogo.bpmn`, their tree
does not hold that file at that path, and their AEF-side OBS-225 offers two dispositions
— restore it, or delta the reference. Measured here (T-446), **neither fits**: the file
is 832-authored (T-192), was delivered to them at rail offset 34, and they re-derived and
re-pinned its current sha at offset 354. The real question is whether a `Reference
fixture:` clause names a path each side must HOLD or a path in the tree that PRODUCES it.
That question, not the rename, is what a v1.x delta would settle.

**Recommended disposition:** close as "no rename — ruled by both sides", and let the
clause-semantics question ride with the v1.1 deltas T-189/T-195 are drafting. Operator's
call; agent initiative does not extend to closing a human-owned task or to ratifying a
two-party standard decision.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] [First criterion]
- [ ] [Second criterion]

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
         1. Run `bin/fw reviewer T-443`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-443 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-11T22:28:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-443-rename-fixturesaef-bpmn-as-a-v12-standar.md
- **Context:** Initial task creation

### 2026-08-11T22:28:58Z — status-update [task-update-agent]
- **Change:** horizon: now → later

### 2026-08-14T15:25:49Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-08-23T10:24:11Z — status-update [task-update-agent]
- **Change:** horizon: now → later
