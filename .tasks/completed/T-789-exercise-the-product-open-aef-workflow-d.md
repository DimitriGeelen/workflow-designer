---
id: T-789
name: "Exercise the product: open aef-workflow-designer.html and measure whether the workflow-to-application path works end to end"
description: >
  Exercise the product: open aef-workflow-designer.html and measure whether the workflow-to-application path works end to end

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T07:44:45Z
last_update: 2026-09-22T07:50:23Z
date_finished: 2026-09-22T07:50:23Z
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

# T-789: Exercise the product: open aef-workflow-designer.html and measure whether the workflow-to-application path works end to end

## Context

§11 of the Phase 5 value review records that `src/aef-workflow-designer.html` (997 KB) was
**never opened or exercised** — three review rounds judged this project without looking at the
thing it builds. Under the operator's confirmed yardstick that is the largest unexamined
surface in the repo. This task opens it.

Not a UI-change task: nothing here modifies the product. The deliverable is measurement —
what the editor does, what it does not do, and specifically whether any affordance exists for
the second half of the yardstick ("iterate from the workflow to actual working applications").

Served at `/designer` (corpus) and `/designer/app` (editor) by Watchtower; the `file:`
protocol is blocked to the browser tool, so all observation is through the running server.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the editor is opened, loaded with real saved content, and its console is
      clean.** Not "the page returns 200": a saved workflow is loaded from the corpus, the
      canvas renders it, and `browser_console_messages` reports zero errors and zero
      warnings. A blank editor proves nothing about the product.
      Evidence: `/designer/app?load=…id=audit-process&v=1` renders the workflow with both
      lanes, gateways and end events; console **0 errors, 0 warnings**. The palette encodes
      the authority model as its vocabulary — Service Task *agent · Initiative*, User Task
      *human · Sovereignty*, Script Task *fw · Authority*.
- [x] **AC2 — the corpus population is measured, not eyeballed.** How many saved workflows
      exist and how many are test fixtures rather than real content. This is the difference
      between "a product with users" and "a product with a test harness", and the yardstick
      cares which.
      Evidence: **6 saved workflows. 5 are fixtures** — 4 × `t101-review-*`, 1 ×
      `t293-retest-*`. **One** (`audit-process`) is real content. All saved 2026-07-29.
- [x] **AC3 — the yardstick question is answered against the product's own control surface.**
      Enumerate every button and link the editor exposes and state whether ANY of them
      advances a diagram toward executable work. Enumerated mechanically from the DOM, not
      from reading the source or the README — what ships is what the user can reach.
      Evidence: DOM enumeration gives Open project, Pending refs, zoom, Add Lane, Reset,
      Clean layout, View XML, Settings, Load, Versions, Save to project, Save — authoring and
      persistence only. **None advances a diagram toward executable work.** Corroborated at
      source: `bpmn_to_tasks`, `forward-compile`, `forwardCompile`, `task graph`, `compile`
      all return **0** occurrences in 997 KB; the only 2 hits for `execute` are inside a code
      comment. **Read as correct, not deficient** — the frozen standard says "No translator
      is built here", so this is the specified scope and the missing half is upstream (T-788).
- [x] **AC4 — every defect found is reproduced before it is reported.** Each claim is
      measured at least twice, or across two different inputs, so a one-off is not filed as
      a defect. Anything that fails to reproduce is reported as not reproduced.
      Evidence: the title defect reproduced across two different loads AND root-caused in
      source (hardcoded `<title>`, `document.title` assigned 0 times). A **second suspected
      defect was checked and dissolved** — `t293-retest-harvest` showing the ID
      `harvest-pipeline` looked like a load mismatch; fetching the stored bytes showed
      `<bpmn:process id="Process_harvest-pipeline">`, so the editor was right and the
      suspicion was mine. It is recorded here rather than dropped, because a review that
      only reports its confirmed hits is not reporting its hit rate.
- [x] **AC5 — findings are filed where they survive this session.** Product defects become
      observations or tasks; the Phase 5 report's §11 "not reviewed" claim is corrected in
      place, since it will otherwise keep being true-looking after it has stopped being true.
      Evidence: **OBS-371** (title defect). Phase 5 §11 carries a superseding block naming
      all three measurements, the defect, and the dissolved suspicion.

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
         1. Run `bin/fw reviewer T-789`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-789 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: the editor is actually served and carries the palette we observed ────
curl -sf "http://192.168.10.107:3013/designer/app" > /dev/null
# NOT the template's `echo "$out" | grep -q` form. Measured here: that pattern is
# documented in this very block as "SIGPIPE-safe", and at ~1 MB it is not — grep -q
# closes stdin on the first match and echo dies on SIGPIPE, so the gate reported
# "killed — signal 13, exit 141" rather than a pass or a fail. Case-match instead:
# no pipe, so no reader to close the writer's stdin. Filed as OBS-372.
out=$(curl -sf "http://192.168.10.107:3013/designer/app" 2>&1); case "$out" in *Sovereignty*) true;; *) false;; esac

# ── AC3: no execution affordance, with POSITIVE CONTROLS on the same patterns ──
# Legs (a) are the controls (T-560): each greps a string that IS present in the
# product, so the silences below are evidence about the product and not about a
# mistyped pattern or an unreadable file. Without them, a renamed/moved file would
# score every absence green.
grep -q 'Sub-process' src/aef-workflow-designer.html
grep -q 'Clean layout' src/aef-workflow-designer.html
! grep -q 'bpmn_to_tasks' src/aef-workflow-designer.html
! grep -q 'forward-compile' src/aef-workflow-designer.html
! grep -qi 'task graph' src/aef-workflow-designer.html

# ── AC4: the title defect, still exactly as reported ──────────────────────────
grep -q '<title>AEF Workflow Designer — investigate.bpmn</title>' src/aef-workflow-designer.html
# document.title is never assigned. Control: 'document.' IS present, so a zero here
# is the absence of the assignment and not the absence of the file.
grep -q 'document\.' src/aef-workflow-designer.html
! grep -q 'document\.title' src/aef-workflow-designer.html

# ── AC4: the dissolved suspicion stays dissolved ──────────────────────────────
# t293-retest-harvest genuinely carries harvest-pipeline internally. If this ever
# stops being true, the finding I withdrew needs re-opening.
out=$(curl -sf "http://192.168.10.107:3013/api/version?id=t293-retest-harvest&v=1" 2>&1); echo "$out" | grep -q 'Process_harvest-pipeline'

# ── AC5: the findings are published where they outlive this session ───────────
grep -q 'Superseded for the product, T-789' docs/reports/VALUE-REVIEW-repo-2026-09-21.md
grep -q 'OBS-371' .context/inbox.yaml

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
     fw inception decide T-789 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T07:44:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-789-exercise-the-product-open-aef-workflow-d.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-51970549
- **Timestamp:** 2026-09-22T07:50:24Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 49
     - evidence: `curl -sf "http://192.168.10.107:3013/designer/app" > /dev/null`

### 2026-09-22T07:50:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
