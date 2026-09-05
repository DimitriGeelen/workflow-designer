---
id: T-467
name: "fw arc tag writes the deprecated tags: form, not the source-of-truth arc_id:"
description: >
  Found in T-466. 'fw arc tag <arc> T-XXX' reports success and sets tags: [arc:<slug>],
  leaving arc_id: commented out. fw arc's own help states the opposite: 'Source-of-truth
  is task-side arc_id: (T-1849)', with the tag/constituent_tasks path marked as the
  T-1851 deprecation. So the documented command writes the deprecated form. Consequence
  is silent: fw arc show renders EITHER form, so an arc whose members are recorded
  inconsistently looks correct in every view. T-466 caught it only because a verification
  leg asserted the source-of-truth field by name instead of asserting the rendered
  output looked right - an instrument checking the render would have passed it. Existing
  arc members T-423/T-424 carry arc_id: with empty tags:, so following the documented
  command splits an arc's membership across two representations, one of them deprecated.
  Vendored framework code, so upstream candidate under G-008. Register-first per CLAUDE.md;
  fix not attempted in T-466 (one bug, one task).

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
created: 2026-08-12T19:44:27Z
last_update: 2026-09-05T10:47:35Z
date_finished: 2026-09-05T10:47:35Z
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
  - ts: '2026-08-16T12:33:30Z'
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
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py); 
      tier=2 (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-467: fw arc tag writes the deprecated tags: form, not the source-of-truth arc_id:

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `fw arc tag <arc> T-XXX` writes a live `arc_id: <slug>` line into the task's
      **frontmatter** — the T-1849 source-of-truth field. Verified by tagging a task in a
      throwaway tree and reading the frontmatter back, not by reading `fw arc show`, whose
      union-of-both-forms render is exactly what hid this for the life of the defect.
- [x] The deprecated `tags: [arc:<slug>]` form is **no longer written** by this path. T-1850
      migrated 162 tasks off it; a command that re-creates it re-opens the migration one
      task at a time. Legacy tags already present on a task are left untouched — readers
      union both forms, so removing them is a separate act and not this fix.
- [x] Idempotent, and refuses reassignment: re-tagging a task to the arc it already carries
      is a no-op that reports so; tagging a task that already carries a **different**
      `arc_id:` exits non-zero and changes nothing. Moving a task between arcs is a scope
      decision — silently overwriting the field would be the same silent-reassignment class
      as T-341's flowNodeRef defect, one level up.
- [x] The write is **bounded to the frontmatter region**. The tag-writer being replaced ran
      `^tags:` over the whole document; task bodies quote these field names when they
      discuss arc membership (this task's own file does), so a document-wide regex can
      rewrite the prose describing a field instead of the field. Proven by a fixture whose
      body contains a line that would match.
- [x] `fw arc --help` no longer tells the reader this verb writes a tag. The help was half
      the defect: it named `arc_id:` as source-of-truth and named this verb as the way to
      set it, while the verb set the other thing.
- [x] A fence (`tools/_t467-arc-tag-source-of-truth.py`) drives **both arms** — it fails
      against HEAD's pre-fix copy of `arc.sh` and passes against the fixed one, so it
      cannot be satisfied by a verb that simply stops writing anything.

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
         1. Run `bin/fw reviewer T-467`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-467 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
python3 tools/_t467-arc-tag-source-of-truth.py
python3 tools/_t517-vendor-divergence.py

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

**Symptom.** `fw arc tag <arc> T-XXX` reported success and left `arc_id:` unset, writing
`tags: [arc:<slug>]` instead. Since T-1850 had migrated 162 tasks off that tag form, the
documented command was re-creating the migration's own cleanup one task at a time.

**Root cause.** `arc_tag()` was written before T-1849 introduced `arc_id:` and was never
updated when the source of truth moved. The rest of the system moved: readers gained a
union scan (`lib/arc_membership.py`), the help text was rewritten to name `arc_id:` as
canonical, and the migration ran. The *writer* stayed where it was. Nothing in the entire
framework wrote `arc_id:` — `arc_show` told the user to set it by hand, which is what a
system does when its writer has quietly become a reader-only.

**Why structurally allowed.** *The union reader made the defect invisible by design.*
Every consumer merges `arc_id:` with the legacy tag, so an arc whose membership is split
across two representations — one of them deprecated — renders **identically** to one
recorded canonically. Every view was correct. `fw arc show` was correct. The audit's
arc checks were correct. A defect that cannot change any output cannot be found by
checking outputs, and checking outputs is what verification normally does.

This is the same shape as the four defects landed on 2026-09-04/05 (T-674/675/677/678):
a value that is *tolerated* by its consumer is indistinguishable from a value that is
*right*. Compatibility shims are load-bearing and correct; the cost is that they also
suppress the signal that the producer needs fixing. Nothing here argues for removing the
union — it argues that a compatibility path needs its own assertion on the producer,
because the consumer will never complain.

T-466 caught it only because one verification leg asserted the **field by name** rather
than asserting that the rendered output looked right. An instrument checking the render
passes this every time — which is the transferable lesson, and it is already recorded as
this task's own origin note.

**Prevention.** `tools/_t467-arc-tag-source-of-truth.py` — six arms, run against a
throwaway project root, **all six failing against HEAD's pre-fix `arc.sh`**. The arms are
deliberately two-sided: "writes `arc_id:`" sits next to "does not write the tag", because
the cheapest way to stop a writer emitting the wrong field is to stop it emitting anything,
and a gutted verb passes the negative arm perfectly.

Two defects the fence found that the bug report never named, both consequences of the same
staleness: the old verb re-added the tag to a task that **already** carried the right
`arc_id:` (so a no-op was not a no-op), and it accepted a **cross-arc reassignment**
silently, producing dual membership. The new verb refuses that — moving a task between arcs
is a scope decision, and silently overwriting the field would be T-341's silent-reassignment
class one level up.

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

### 2026-08-12T19:44:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-467-fw-arc-tag-writes-the-deprecated-tags-fo.md
- **Context:** Initial task creation

### 2026-09-05T10:41:45Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8f99b194
- **Timestamp:** 2026-09-05T10:47:37Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-05T10:47:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
