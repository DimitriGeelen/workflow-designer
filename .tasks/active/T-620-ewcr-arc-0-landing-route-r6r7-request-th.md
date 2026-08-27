---
id: T-620
name: "EWCR Arc 0 landing: route R6/R7, request the two counterparty attestations, evidence the H-register"
description: >
  Landing pass on EWCR Arc 0 rather than another finding pass. Arc 0's exit gate has three clauses: clauses 1 and 2 are AEF-owned and need a counterparty attestation; clause 3 is a local register (operator-decisions.yaml H1-H6) that requires every blocking question to carry status=resolved plus an independently-agreeing source_of_truth, and stands at 2/6. This task discharges what the agent CAN discharge: routes R6 and R7 to AEF, requests both attestations with the clause text verbatim, produces the inspection evidence H5's own recommendation asked for, and supersedes H6's stale send-authorisation premise. It does NOT resolve any H-question or set any attestation - those are operator acts.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T18:51:51Z
last_update: 2026-08-27T18:51:51Z
date_finished: null
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

# T-620: EWCR Arc 0 landing: route R6/R7, request the two counterparty attestations, evidence the H-register

## Context

Landing pass, not another finding pass. EWCR Arc 0's exit gate
(`docs/research/executable-workflow/arc-0-exit-clauses.yaml`) has three clauses. Clauses 1 and 2
are counterparty-owned (roadmap §2.1 line 64: "AEF topology", "refusal matrix") and cannot be
closed by any amount of Designer-side work. Clause 3 is the local H-register
(`operator-decisions.yaml`) and stands at 2/6 — H1, H3, H5, H6 open, all four blocking.

This task discharges exactly what the agent may discharge and stops there.

## Acceptance Criteria

### Agent
- [x] R6 and R7 routed to 999-AEF with the ask text taken **verbatim** from
      `designer-contract-inventory.md:306-307`, not paraphrased — R6 (DeepSeek/Mistral
      dispositions absent; dossier carries Claude §17 and Z.ai §18 only) and R7
      (reconciliation with ratified SD-1, escalated because the inventory names AEF as owner)
- [x] Both counterparty attestations requested with each clause's `what_would_satisfy` text
      carried across, AND each clause's `why_not_local` reason stated — so the counterparty
      can see we declined to answer their clause locally rather than merely failed to
- [x] H5's own `agent_recommendation` ("the cheap check is whether T-587's hand-written file
      matches what `fw task create` would have produced") actually PERFORMED, with the result
      recorded as `agent_evidence` and the residue named — settles deviation 2 of 4, not H5
- [x] H6's superseded send-authorisation premise replaced, with the original text preserved
      under `operative_state_superseded` rather than deleted (the three-session stall is itself
      the evidence)
- [x] `attestation: null` still null on both clauses and `definition_ratified: false` still
      false on all three AFTER the send — §2.3: transport is not collaboration completion
- [x] No H-question status changed by the agent; the register still reads H1/H3/H5/H6 `open`
- [x] My own rail error corrected on the record: at offset 639 I told the coordinator "there
      is no H1..H6 series in this tree" when the register exists — corrected at offset 643
      with the cause named (searched for a prose shape, not the place the thing lives)

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

# The register must still parse after the edits
python3 -c "import yaml; yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml'))"
python3 -c "import yaml; yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml'))"
# The four blocking questions must STILL be open — the agent does not resolve operator decisions
python3 -c "import yaml,sys; qs=yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml'))['questions']; o=[q['id'] for q in qs if q['status']=='open']; sys.exit(0 if o==['H1','H3','H5','H6'] else 1)"
# §2.3: transport is not completion — attestations must still be null, definitions unratified
python3 -c "import yaml,sys; cs=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml'))['clauses']; sys.exit(0 if all(c.get('attestation') is None for c in cs) and not any(c.get('definition_ratified') for c in cs) else 1)"
# H6 must carry BOTH the new routed state and the preserved superseded one
grep -q 'operative_state_superseded:' docs/research/executable-workflow/operator-decisions.yaml
grep -q 'offset 643' docs/research/executable-workflow/operator-decisions.yaml
# H5's inspection evidence must be present and must name its own residue
grep -q 'agent_evidence:' docs/research/executable-workflow/operator-decisions.yaml
grep -q 'residue:' docs/research/executable-workflow/operator-decisions.yaml
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

### 2026-08-27T18:51:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-620-ewcr-arc-0-landing-route-r6r7-request-th.md
- **Context:** Initial task creation
