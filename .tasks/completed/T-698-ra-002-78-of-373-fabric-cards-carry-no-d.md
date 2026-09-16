---
id: T-698
name: "RA-002: 78 of 373 fabric cards carry no dependency edges"
description: >
  Audit WARN cycle 1 2026-09-16: fabric graph coverage below target. A card with no
  edges registers a file without stating what it depends on, so blast-radius returns
  an understated answer for it.

status: work-completed
workflow_type: build
owner: claude
horizon: null
tags: [arc-003, audit-remediation, RA-002]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T13:24:57Z
last_update: 2026-09-16T13:40:42Z
date_finished: 2026-09-16T13:40:42Z
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
  - ts: '2026-09-16T13:30:32Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-16T13:30:49Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-698: RA-002: 78 of 373 fabric cards carry no dependency edges

## Context

**Finding RA-002** - cycle 1, 2026-09-16. Source: fw audit. Severity: WARN.

Cycle-1 baseline for regression detection: audit Pass 166 / Warn 31 / Fail 1; doctor 3 warn / 0 fail.

**Verbatim tool output:**

```
[WARN] Fabric: 78/373 cards have no edges
       Evidence: Graph coverage below target
       Mitigation: Run: fw fabric enrich
```

**The invariant that is not held:**

A component card with no depends_on and no depended_by asserts that a file exists but says nothing about what it is connected to. The invariant the fabric claims to hold - that `fw fabric blast-radius` returns the true downstream set - is not held for those 78 cards: they return an empty impact set, which reads identically to a genuine leaf. 21% of the graph is silently unanswerable.

**Verification is the next cycle's re-run of the originating check, not this task's own assertion that it is fixed.**

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The count of edgeless cards is strictly below the cycle-1 baseline of 78, and the new count is recorded in this task — **78 → 73**, measured by `fw audit --section structure`
- [x] `fw fabric enrich` has been run and its output recorded here — 374 processed, 213 enriched, 601 edges added (61 forward, 540 reverse), 161 discarded against 77 unregistered targets
- [x] Any card still edgeless after enrich is either a genuine leaf or is listed by name, so the residue is enumerated rather than aggregated — all 73 named in `docs/reports/T-698-edgeless-cards-2026-09-16.txt`, and classified below

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
         1. Run `bin/fw reviewer T-698`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-698 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# Asserts the actual AC condition: edgeless-card count strictly below the cycle-1 baseline of 78.
# Single command, its own exit code is the verdict (T-352 errexit note). Agrees with the audit's
# independent count; the earlier regex-based counter disagreed and was wrong — see ## Evolution.
python3 -c 'import yaml,glob;n=sum(1 for p in glob.glob(".fabric/components/*.yaml") for d in [yaml.safe_load(open(p)) or {}] if not (d.get("depends_on") or d.get("depended_by")));print("edgeless:",n);exit(0 if n<78 else 1)'
test -s docs/reports/T-698-edgeless-cards-2026-09-16.txt

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

### 2026-09-16 — the residue is not a carding failure, it is a missing node type
- **What changed:** The filing assumed 78 edgeless cards meant 78 under-described
  components. After enrich the residue is 73, and it has a shape the aggregate number
  hid: **72 of 73 live in `tools/`** and one in `scripts/`. Spot-checking three of them
  through `fw fabric deps` confirms they are genuinely disconnected in the graph, not
  merely under-declared on the card. Then grepping for their filenames showed why:
  `_t342-fabric-edge-drop-probe.py`, `_t345-fabric-check-agreement.sh` and
  `_autoload-verify-cdp.mjs` are each referenced from 2-3 task files. Their only caller
  is a task's `## Verification` block — **and a task is not a fabric component, so there
  is no node for that edge to attach to.** The fabric has no node type for the
  verification surface, so every one-shot instrument invoked only from P-011 is edgeless
  by construction and always will be.
- **Plan impact:** "Run enrich until the number reaches zero" was the wrong target. Enrich
  can only find edges between things that are both components. The reachable floor for this
  check is roughly the count of P-011-only instruments, which is most of the 73. Driving it
  lower would require either registering task Verification blocks as components or excluding
  P-011-only instruments from the check — both are design decisions, not remediation.
- **Triggered:** No new task filed; the choice above is a Sovereign question and is recorded
  as such rather than decided here. Two sub-findings from T-697's RCA also land on this task
  and remain open: `fw fabric register` mints cards with zero edges (so the registration verb
  is a *source* of this population), and a `depended_by:` written on a card is inert because
  the reverse index is built from other cards' `depends_on:`.

### 2026-09-16 — I built a broken counter and the cross-check caught it
- **What changed:** My first enumeration used a line-scanning regex and reported 287 edgeless
  cards against the audit's 78. It listed `tests-run-bridge-tests` as edgeless — a card with
  over 130 `depends_on` entries. `fw fabric enrich` had rewritten the cards with list items at
  column 0, and the regex's `(?!^\S)` continuation test terminated on the first `-`. Replacing
  it with `yaml.safe_load` produced **73, exactly matching the audit's independent count.**
- **Plan impact:** The enumeration in `docs/reports/T-698-edgeless-cards-2026-09-16.txt` is the
  YAML-parse output, not the regex output. Two independently-implemented counts agreeing on 73
  is the only reason the number in this task is stated without hedging.
- **Triggered:** Nothing filed. Recorded because the failure mode is the one T-694 exists to
  catch — an instrument that has only ever printed one answer has not been shown to have two —
  and it recurred here within the same run, on a counter I wrote myself.

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
     fw inception decide T-698 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T13:24:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-698-ra-002-78-of-373-fabric-cards-carry-no-d.md
- **Context:** Initial task creation

### 2026-09-16T13:37:16Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-193fe639
- **Timestamp:** 2026-09-16T13:40:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-16T13:40:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
