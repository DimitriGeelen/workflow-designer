---
id: T-319
name: "Rule: exclusiveGateway whose branches all reconverge immediately is a decision without consequence (T-309 IW-4)"
description: >
  The example that started T-309: an exclusiveGateway fanning six labelled branches - external, dependency, unknown, design, environment, code - into a single shared target. Exclusive is semantically correct there (a failure has one type; parallel would fire all six), but six branches that reconverge immediately with no intervening difference is a decision without consequence: a data field wearing a gateway's clothes. The operator spotted it by eye, which is the work the validator exists to stop doing by eye. Not covered by any current rule, including T-317's W-XML-GW-AMBIGUOUS - that fires on missing conditions, whereas this case can be fully conditioned and still pointless. NOT to be built unilaterally: unlike T-312 (predicate adopted verbatim from AEF) and T-317 (parity with an existing in-house rule), this is NEW intelligence with a taste component, and the motivating instance is AEF-authored content, so the rule would fire on peer maps. House pattern for a new cross-toolchain rule is to settle the predicate on the rail first. Open questions to pose: does 'no intervening difference' mean literally identical targetRef, or targets that converge within N nodes; is a labelled-but-conditionless fan-in already covered by W-XML-GW-AMBIGUOUS in practice; and is this a validator rule at all or an advisory the designer shows only while authoring.

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
created: 2026-07-31T11:41:47Z
last_update: 2026-07-31T12:27:53Z
date_finished: 2026-07-31T12:27:53Z
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

# T-319: Rule: exclusiveGateway whose branches all reconverge immediately is a decision without consequence (T-309 IW-4)

## Context

Filed deliberately unbuilt. Unlike T-312 (predicate adopted verbatim from AEF) and
T-317 (parity with an existing in-house rule), this was NEW intelligence with a
taste component whose motivating instance is AEF-authored content — so the rule
would fire on peer maps. The house pattern for a new cross-toolchain rule is to
settle the predicate on the rail first, not to ship and then discuss.

**That is what happened, and the predicate came back measured as worthless.**
Closed as DECLINED, not built. Full evidence in `## Decisions`.

## Acceptance Criteria

### Agent

The deliverable as filed was *settle the predicate before building* — not *build
the rule*. That deliverable is complete; its outcome is a decline.

- [x] The three open predicate questions posed to the peer BEFORE any source edit
      → rail 355, all three (identical-`targetRef` vs convergence-within-N;
      overlap with `W-XML-GW-AMBIGUOUS`; validator rule vs authoring advisory)
- [x] Q2 — the deciding question — answered by MEASUREMENT on a real corpus, not
      by taste
      → AEF rail 356: 2 strict-predicate hits, 2 already caught by
      `W-XML-GW-AMBIGUOUS`, **T-319-unique = 0**. Total subsumption
- [x] Decision recorded with the evidence and the rejected alternatives, so the
      question reads as answered rather than parked
      → `## Decisions`, including why DEFER was rejected
- [x] No source file edited under this task id
      → `git log --stat` for T-319 touches only this task file
- [x] The one durable part — that the smell, if ever surfaced, belongs on an
      authoring surface rather than the validator — carried to where it survives
      this task's closure
      → recorded against T-309 (`docs/reports/T-309-validator-surfacing.md`)

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

### 2026-07-31 — DECLINED on measurement (not deferred)

- **Chose:** do not build the reconvergence rule. Close as declined.
- **Why:** the predicate was posed to AEF at rail 355 before building, exactly
  because the motivating instance is peer content. Their measurement (rail 356)
  settles the question I had not measured — Q2, overlap:

  | | |
  |---|---|
  | reconverging exclusiveGateways (strict: identical `targetRef`) | 2 |
  | of those, already caught by `W-XML-GW-AMBIGUOUS` | 2 |
  | **T-319-unique** | **0** |

  Total subsumption. Every instance the strict predicate would catch is already
  caught by a rule shipped in T-317. The looser convergence-within-N variant is
  the only version that would earn anything, and it needs a bound neither side
  can justify. AEF's formulation, kept verbatim: *a predicate that only pays off
  in the form you cannot justify is a predicate to leave alone.*
- **Rejected:** (a) build the strict version anyway — earns zero by measurement;
  (b) build convergence-within-N — unjustifiable bound; (c) **defer** — a parked
  task carrying a measured zero is one nobody re-reads, and parking would leave
  the impression the question is open when it is answered.
- **Correction absorbed:** the motivating instance was not the map I had in mind.
  `draft-knowledge-leveling` is NOT a reconvergence case under the strict
  predicate (`fw_gw_ready` fans 4 edges to 2 distinct targets). The only strict
  hits anywhere are `draft-exception-handling` v2/v3, `fw_gw_type`, 6 outgoing
  onto ONE target. A rule built from the witness I was carrying in my head would
  have missed both real instances — a worse version of building from a single
  witness, since the single witness was also misremembered.
- **Salvaged, and it outlives the rule:** if the modelling smell is ever worth
  surfacing it belongs on an authoring surface, not the validator. Our other
  WARNs mean "a reader or runtime could reach the wrong answer here"; this one
  would mean "you wrote something you did not mean". Different surface. Recorded
  against T-309 rather than lost with this task.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-31T11:41:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-319-rule-exclusivegateway-whose-branches-all.md
- **Context:** Initial task creation

### 2026-07-31T12:27:27Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-353752f5
- **Timestamp:** 2026-07-31T12:27:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-31T12:27:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
