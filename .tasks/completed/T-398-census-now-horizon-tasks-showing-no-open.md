---
id: T-398
name: "Census: now-horizon tasks showing no open ACs yet still started-work"
description: >
  Census: now-horizon tasks showing no open ACs yet still started-work

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T20:53:45Z
last_update: '2026-08-16T12:33:55Z'
date_finished: 2026-08-08T21:03:45Z
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
  - ts: '2026-08-16T12:33:55Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-398: Census: now-horizon tasks showing no open ACs yet still started-work

## Context

Twelve now-horizon tasks showed every AC ticked — agent **and** human — while sitting in
`started-work`. This census establishes why, and what may be done about it.

## Findings

### 1. The ticks are legitimate, and they all come from ONE commit

All twelve trace to `ee2b902a` (T-306, 2026-07-29): an **operator-authorised batch close**
("close all, i checked", Tier-2 logged). 55 of 66 closed through P-011; **11 were left as
R-033 sovereignty blocks for the operator**. Those blocked tasks are what this census found,
ten days later.

Checked before treating it as an opportunity: if an *agent* had ticked those `[REVIEW]`
boxes it would be a governance violation, not a backlog. It is not — the ticks are the
operator's, in the operator's own commit.

### 2. Why they cannot be closed by an agent, and why that is correct

`update-task.sh:56` — **R-033 human sovereignty gate**: an agent cannot complete a task with
`owner: human`. The only bypass is `--skip-sovereignty`, which CLAUDE.md's autonomous-mode
boundaries explicitly withhold. So the correct terminal state for this census is a
**recommendation with evidence**, not a close. Nothing here was closed.

### 3. Gate ORDER means "all ACs ticked" does not imply "will close cleanly"

`check_human_sovereignty` (1517) runs **before** `check_acceptance_criteria` (1523) and
`run_verification_commands` (1528). A close attempt therefore exits at the sovereignty gate
and reveals nothing about P-010/P-011. Rather than assert these would close, each task's
`## Verification` block was **executed directly** — same execution model P-011 uses
(`eval` in a subshell under `-o pipefail`, no effective `-e`).

| task | P-011 | blocker |
|---|---|---|
| T-125 | **PASS** 4/4 | — |
| T-195 | **PASS** 7/7 | — |
| T-264 | **PASS** 5/5 | — |
| T-344 | **PASS** 2/2 | — |
| T-309 | **passes through** | no `## Verification` block |
| T-041 | FAIL 3/4 | bridge suite red |
| T-101 | FAIL 4/5 | bridge suite red |
| T-102 | FAIL 1/2 | `build/gallery/designer.html` stale vs `src/` |
| T-105 | FAIL 0/1 | `build/gallery/designer.html` stale vs `src/` |
| T-228 | FAIL 3/5 | `build/gallery/` stale (`openPendingRefModal` absent) |
| T-293 | FAIL 4/5 | `build/gallery/t293-handles-selected.png` missing |
| T-200 | FAIL 2/4 | verification pins `VERSION = 0.3.0`; VERSION is 0.9.0 |

**Five would close cleanly today. Seven would not**, and would have failed P-011 *after*
passing the sovereignty gate — i.e. an operator running the close would have hit a
verification failure with no warning. That is the concrete value of pre-running them.

### 4. Three distinct causes behind the seven, none of them "the task is unfinished"

- **Bridge red** (T-041, T-101) — one failing leg, filed separately. **One bug = one task.**
- **Stale `build/gallery/` snapshot** (T-102, T-105, T-228, T-293) — the T-252 mechanism:
  `serve-gallery.sh` snapshots `src/` at build time, and `src/` has moved since. Four tasks
  verify against the snapshot rather than the source.
- **Stale value pin** (T-200) — `test "$(tr -d '[:space:]' < VERSION)" = "0.3.0"` was true
  when written and is now permanently red at 0.9.0. This is the **G-015 shape inverted**:
  G-015 is a check pinned to a moving pointer so it can never fail; this is a check pinned
  to a moment so it can never pass again.

### 5. The blind spot, registered rather than only observed

Nothing detects **"all ACs ticked + owner human + still started-work"**. The audit's D2 check
watches the *review queue* — tasks whose human ACs are UNCHECKED — so these twelve are
invisible to it precisely *because the human already did the work*. The state that means
"verified, one command from done" is indistinguishable to every instrument from "in
progress". Ten days, twelve tasks, no signal.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The census distinguishes **three** states, not two: (i) genuinely nothing open —
      candidate for completion, (ii) agent done / human pending — correctly parked as
      partial-complete, (iii) **no parseable AC section at all** — which reads identically to
      (i) under any naive counter and is the failure mode this census exists to separate. A
      task with zero ACs is not a task with all ACs met.
- [x] The counter excludes HTML comment blocks before counting. The task template ships two
      worked `- [ ]` examples inside `<!-- -->`, so any counter that does not strip comments
      reports phantom open ACs on every task in the tree.
- [x] For every task landing in state (i), a per-task verdict is recorded with evidence —
      either "completable, here is why" or "not completable, here is what is actually
      outstanding". No batch-close, no aggregate claim standing in for per-task evidence
      (CLAUDE.md §Human Task Completion Rule).
- [x] Nothing is closed by this task. The census REPORTS; any task owned by `human` stays
      that way and closure is recommended with evidence, never performed.
- [x] If the census finds a structural cause (state machine allows started-work with zero
      ACs, or completion never fires), it is registered in the gaps/concerns register rather
      than only fixed in place — completed tasks archive and become invisible.

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

# --- T-398 commands ---
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
out=$(cat .context/project/concerns.yaml); echo "$out" | grep -q "id: G-027"
# The gate-ORDER claim the census rests on: sovereignty runs BEFORE P-010/P-011, which is
# why "all ACs ticked" cannot imply "closes cleanly". Re-derived from the file, not quoted —
# if a future edit reorders these, the census's central caveat stops being true and this
# goes red rather than sitting stale in a task nobody rereads.
sov=$(grep -n "^            check_human_sovereignty" .agentic-framework/agents/task-create/update-task.sh | head -1 | cut -d: -f1); ac=$(grep -n "^            check_acceptance_criteria" .agentic-framework/agents/task-create/update-task.sh | head -1 | cut -d: -f1); [ -n "$sov" ] && [ -n "$ac" ] && [ "$sov" -lt "$ac" ]
# R-033 itself must still exist and still refuse. If the gate were removed, this census's
# conclusion ("agent must not close these") would be silently wrong.
out=$(grep -c "Sovereignty gate (R-033)" .agentic-framework/agents/task-create/update-task.sh); [ "$out" -ge 1 ]

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

### 2026-08-08T20:53:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-398-census-now-horizon-tasks-showing-no-open.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d0cbec58
- **Timestamp:** 2026-08-08T21:03:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T21:03:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
