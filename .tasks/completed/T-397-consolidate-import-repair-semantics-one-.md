---
id: T-397
name: "Consolidate import-repair-semantics: one operator ruling, not four"
description: >
  Consolidate import-repair-semantics: one operator ruling, not four

status: work-completed
workflow_type: design
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T20:46:16Z
last_update: 2026-08-08T20:52:23Z
date_finished: 2026-08-08T20:52:23Z
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

# T-397: Consolidate import-repair-semantics: one operator ruling, not four

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
> **Which verification legs actually have teeth, stated so nobody over-reads the green.**
> Five of the seven grep a file this task wrote — they are regression guards (they go red if
> a later edit strips the content), not discovery instruments, and they cannot fail on the
> day they are written. Two are independent of this task's output and can genuinely surprise:
> the `BOTH = 0` disjointness re-measurement (walks the real corpus; goes red the day an
> intake lands a file carrying both carriers, which would invalidate T-340's "zero bytes
> change" argument) and the `never silently migrated` source count (goes red if the ratified
> principle the Q1 recommendation leans on is edited out from under it). Recording the split
> because "7/7 green" over five self-referential legs is exactly the reading this arc keeps
> having to correct.

- [x] Brief exists at `docs/reports/T-397-import-repair-semantics-brief.md` and states, for
      each of the four open rulings, its question, its current recommendation (or an explicit
      refusal to recommend), what it costs, and what it unblocks — recoverable without opening
      any task file.
- [x] The starting hypothesis ("one ruling, not four") is recorded as **tested and false**,
      with the mechanism that falsifies it. A brief that quietly drops its own disproved
      premise teaches the next reader to re-derive it.
- [x] Every empirical claim the recommendations rest on is either re-measured this session or
      attributed to its source — no number inherited from a task file without provenance. The
      `aef:position`/DI disjointness claim specifically is RE-MEASURED, since T-340 established
      it on a smaller population and a later intake could have broken it.
- [x] No Q2 (fabrication) recommendation is offered. Q2 decides which authority acquires a
      step; the Authority Model reserves that to the human, so a recommendation here would be
      an agent pre-empting a sovereignty call.
- [x] The four blocked tasks link to the brief from their Human `[REVIEW]` ACs, so the
      consolidated view is reachable from where the operator actually lands.

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

# --- T-397 commands ---
# The brief exists and covers all four rulings by id.
test -f docs/reports/T-397-import-repair-semantics-brief.md
out=$(cat docs/reports/T-397-import-repair-semantics-brief.md); echo "$out" | grep -q "T-340" && echo "$out" | grep -q "T-341" && echo "$out" | grep -q "T-347" && echo "$out" | grep -q "T-358"
# The disproved starting hypothesis is recorded as disproved, not quietly dropped.
out=$(cat docs/reports/T-397-import-repair-semantics-brief.md); echo "$out" | grep -q "why it is false"
# No Q2 recommendation. The brief must SAY it is refusing, so the refusal is auditable
# rather than looking like an omission someone should helpfully fill in later.
out=$(cat docs/reports/T-397-import-repair-semantics-brief.md); echo "$out" | grep -q "No agent recommendation"
# The load-bearing disjointness claim, re-measured on every run rather than quoted.
# T-340 established BOTH=0 over 126 files; the third-party intake has since grown the
# population to 142. If a future intake ever lands a file carrying BOTH aef:position and
# BPMN DI, T-340's "zero bytes change" argument stops holding and this line goes red —
# which is the whole point of checking it instead of citing it.
# The population size is asserted TOO. `both=0` over an EMPTY corpus is green and means
# nothing — if git ls-files ever returns nothing (wrong cwd, broken index), the check
# would report "no file carries both" about zero files. That is the vacuity the T-352
# warning above describes, in the one line here that could actually exhibit it.
tot=0; both=0; while IFS= read -r f; do tot=$((tot+1)); if grep -q 'aef:position' "$f" && grep -qE '<[a-zA-Z0-9]*:?BPMNDiagram' "$f"; then both=$((both+1)); fi; done < <(git ls-files '*.bpmn'); [ "$tot" -ge 100 ] && [ "$both" -eq 0 ]
# The ratified principle the Q1 recommendation leans on must still exist in source.
out=$(grep -c "never silently migrated" src/aef-workflow-designer.html); [ "$out" -ge 3 ]
# Each blocked task reaches the brief from where the operator actually lands.
for t in 340 341 347 358; do out=$(cat .tasks/active/T-$t-*.md); echo "$out" | grep -q "T-397-import-repair-semantics-brief" || exit 1; done

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

### 2026-08-08T20:46:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-397-consolidate-import-repair-semantics-one-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a924b7ff
- **Timestamp:** 2026-08-08T20:52:24Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T20:52:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
