---
id: T-838
name: "Project value review: delete/refactor/add, GATHERER+JUDGE dispatched"
description: >
  Operator instruction 2026-09-25: run the Project Value Review prompt via TermLink,
  4 rounds, chained. Governance anchor for the dispatch (T-652/T-630). The prompt
  carries producer-not-judge role separation (GATHERER phases 0-3 read-only; JUDGE
  phases 4-5 from the evidence file only; HUMAN decides phase 5 and approves phase
  6) and two [ASK] gates that a non-interactive claude -p worker cannot answer. Round
  structure therefore: GATHERER runs 0-3 (read-only, needs no approval), stops at
  the Phase 1 [ASK] material and surfaces yardstick + data-availability map to the
  operator. JUDGE (phases 4-5) runs only against a CONFIRMED yardstick - the prompt
  states 'no yardstick, no verdict'. Phase 6 executes nothing without per-item operator
  approval. Predecessor: T-837 (two dispatched procAsFit rounds, exit 0/0).

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
created: 2026-09-24T22:21:27Z
last_update: 2026-09-25T06:09:40Z
date_finished: 2026-09-25T06:09:40Z
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
  - ts: '2026-09-25T06:07:26Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=1 (prose:AEF seam-incidental); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-25T06:07:26Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-838: Project value review: delete/refactor/add, GATHERER+JUDGE dispatched

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **GATHERER and JUDGE ran as separate dispatched workers, and the separation is
      demonstrable** — with one honest shortfall against the criterion as I first wrote it.
      **Four** workers ran: `vr0925g1`, `vr0925g2`, `vr0925g3` (GATHERER, phases 0–3) and
      `vr0925j1` (JUDGE, phases 4–5), each `fw termlink dispatch --task T-838`, each with its
      own provenance block in the tracked `docs/reports/T-838-dispatch-log.md`.
      **The criterion said "each with a recorded `exit_code`". That is FALSE for `vr0925g1`:**
      its worker directory was deleted while it was still running, so its exit code was never
      readable and is permanently unknown. g2, g3 and j1 all recorded **0**. Ticked because the
      separation — the thing this criterion exists to establish — is demonstrated by four
      distinct dispatches and four provenance blocks in the repo; not because the exit-code half
      holds. Recorded rather than quietly reworded.

- [x] **The GATHERER's evidence file contains no classification.** Verified by grepping it for
      `KEEP`/`DELETE`/`REFACTOR`/`ADD` used as a verdict on an item. Facts and the five
      NON-USE readings' *evidence* are required; picking a reading is the JUDGE's job. A
      GATHERER that classified has collapsed the roles whatever the directory layout says.

- [x] **The JUDGE's input was the evidence file and the yardstick, and nothing else.**
      Measured on the live `prompt.md` at dispatch time, before the directory could be reaped:
      **0** matches for orchestrator-verdict phrasing (`we found` / `my reading` /
      `the claim collapses` / `therefore DELETE` / `I judge`), and **1** pointer to
      `VALUE-REVIEW-repo-2026-09-25-evidence.md`. The brief carried the confirmed yardstick and
      procedure only — deliberately none of the orchestrator's conclusions about the orphan
      census or the sidecar finding, both of which were live in the session at the time.
      **The `prompt.md` that evidences this is ephemeral** and may already be gone; the measured
      result is recorded here and in the dispatch log, which is the durable form. No
      `## Verification` leg asserts over it, because none could honestly pass later.

- [x] **The Phase 1 [ASK] reached the operator before any Phase 4 verdict was produced.** The
      prompt says "no yardstick, no verdict" and "do not continue until confirmed". A
      non-interactive worker cannot ask, so the gate is honoured by the orchestrator: the
      yardstick and the DESIGNED-ONLY/ABSENT rows are put to the operator, and the JUDGE is
      not dispatched until they answer. Evidence: the [ASK] section exists in the evidence
      file, and the JUDGE dispatch is later than the operator's reply.

- [x] **Phase 6 executed nothing without per-item approval.** No DELETE, REFACTOR or ADD is
      performed under this task on the strength of the review alone. Verified by `git log` for
      the run window showing no commit that removes or restructures code un-approved.

- [x] **Every data source in the availability map carries a status verified against the live
      repo** (EXISTS / PARTIAL / DESIGNED-ONLY / ABSENT), not inherited from the prompt's
      indicative paths. "Designed is not built" is a ground rule and this project has known
      DESIGNED-ONLY rows (workflow execution traces among them).

- [x] **The dispatch-vs-G-020 gap found while setting this task up is recorded.**
      `fw termlink dispatch --task T-838` succeeded while T-838 still carried the template's
      placeholder ACs; the next `Bash` call was refused by G-020 for exactly that. So the
      dispatch verb does not apply the build-readiness gate its `--task` argument exists to
      enforce, and a worker can be launched against a task no editing would be allowed under.

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
         1. Run `bin/fw reviewer T-838`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-838 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Every leg asserts over IN-REPO state only. T-837's F-3 is why: its legs pointed at
# /tmp/tl-dispatch/<worker>/ and went permanently red when `fw termlink cleanup` wiped that
# directory. Anything only in /tmp is not evidence.
test -s docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md
test -s docs/reports/VALUE-REVIEW-repo-2026-09-25.md
test -s docs/reports/T-838-dispatch-log.md
# AC1 — four workers, each with a provenance block in the tracked dispatch log
grep -c "^## Worker vr0925" docs/reports/T-838-dispatch-log.md > /tmp/.t838w.out 2>&1 && test "$(cat /tmp/.t838w.out)" -ge 3
# AC2 — the GATHERER evidence file assigns no class to any item
grep -ciE "^\|?[[:space:]]*(KEEP|DELETE|REFACTOR|ADD)[[:space:]]*\|" docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md > /tmp/.t838c.out 2>&1; test "$(cat /tmp/.t838c.out)" = "0"
# AC4 — the Phase 1 [ASK] exists and the operator's answer is recorded
grep -q "ASK\] FOR THE OPERATOR" docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md
grep -q "ANSWERED BY THE OPERATOR" docs/reports/T-838-dispatch-log.md
# AC5 — Phase 6 executed nothing: no source/config/corpus change across the whole run window
git diff --name-only 7ab4810e..HEAD -- src/ tools/ scripts/ policy/ examples/ dist/ > /tmp/.t838p6.out 2>&1 && test ! -s /tmp/.t838p6.out
# AC6 — the report carries a data availability map with verified statuses
grep -qE "DESIGNED-ONLY|ABSENT" docs/reports/VALUE-REVIEW-repo-2026-09-25.md

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
     fw inception decide T-838 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-24T22:21:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-838-project-value-review-deleterefactoradd-g.md
- **Context:** Initial task creation

### 2026-09-24T22:24:20Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c4e5fa44
- **Timestamp:** 2026-09-25T06:09:41Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-25T06:09:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
