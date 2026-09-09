---
id: T-692
name: "Pickup findings for the AEF agent: three P-002/check-active-task defects measured in generic framework code"
description: >
  Pickup findings for the AEF agent: three P-002/check-active-task defects measured in generic framework code

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
created: 2026-09-09T08:27:22Z
last_update: 2026-09-09T08:30:31Z
date_finished: 2026-09-09T08:30:31Z
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

# T-692: Pickup findings for the AEF agent: three P-002/check-active-task defects measured in generic framework code

## Context

The operator asked, at the end of the 2026-09-09 run, whether the session's structural
findings had been sent to AEF for remediation. They had not — and the honest answer was that
nothing had gone upstream at all. Three of the run's findings live in **generic framework
code**, not in 832's product:

1. A task cannot commit its own completion under its own id (partial-complete path), and every
   escape either trips a second gate or regenerates the same state. No terminating non-bypass
   remedy — this is why the report was written now rather than after our own operator rules.
2. P-002 blocks read-only commands in four trigger states, including `/resume`'s own Step 1 and
   `checkpoint.sh status`, the read CLAUDE.md's budget rule names as the safe one. Nine
   instances across four sessions.
3. `fw work-on T-XXX | head -N` reports success and silently does not write the status — L-387's
   SIGPIPE class arriving on a state-changing command, where the cost is a silent no-op rather
   than a loud false red.

Deliverable: `docs/reports/framework-agent-pickup-2026-09-09.md`, following the convention set
by `framework-agent-pickup-2026-06-05.md` and `-2026-08-16.md`.

**The document also carries a correction against our own argument.** T-676 justified a fix by
claiming the framework already has a read-only classifier to reuse. Quoting the line rather
than restating it showed it is a *wrap-up allow-list* containing `git commit`, `git add`,
`git push` and `update-task.sh` — reusing it would ship a gate admitting the writes P-002
exists to refuse. Sending the cheap story and letting AEF discover the cost themselves was the
available shortcut; the correction is in the report instead.

**Not transmitted.** The shared TermLink hub is `not_running` and starting it is the operator's
call (it affects every consumer on their mesh), so the document is on disk and has reached
nobody. Recorded as such in the document's own Delivery status section and pinned by
Verification leg 4, because roadmap §2.3 is explicit that transport is not collaboration
completion — and a document that never moved is not even transport.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Every finding in the document reproduces in a **stock AEF checkout**, and each one says
      so with the file and line it lives in. A pickup that mixes 832-specific defects into
      generic ones wastes the receiving agent's scoping and teaches them to discount the next
      one.
- [x] Findings excluded as 832-specific are **listed by name with the reason**, not silently
      dropped. An absence the reader cannot see is indistinguishable from an omission.
- [x] The document states plainly that **we have changed nothing in our vendored copy**, and
      why (all three live in a Tier-1 enforcement hook; loosening one is a sovereignty call).
      A pickup that implies a fix exists invites the reader to diff against something that
      isn't there.
- [x] Every quoted framework line is **quoted verbatim with its file and line number**, never
      paraphrased (PL-323). This document's central correction exists *because* a paraphrase
      drifted; repeating the defect inside the report of it would be self-refuting.
- [x] The document carries our own **overstatement against ourselves** — the false "the
      read-only classification already exists" argument — so the receiving agent inherits the
      corrected cost rather than the cheap story.
- [x] Framed as findings, **not** as a build spec, per G-020 applied in the outbound
      direction. No item asks for an implementation.
- [x] Transport is recorded honestly: whether it was actually delivered to 999-AEF or only
      written to disk. Per roadmap §2.3, transport evidence is not collaboration completion,
      and an undelivered document must not be reported as a sent pickup.

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
         1. Run `bin/fw reviewer T-692`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-692 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# 1. The document exists where the pickup convention puts it.
test -f docs/reports/framework-agent-pickup-2026-09-09.md

# 2. Every quoted framework line is the line that is actually in the framework. This is the
#    pin that matters: the document's central correction exists BECAUSE a paraphrase drifted,
#    so a stale quote inside it would refute the report in the reader's hands.
python3 -c 'import sys;g=open(".agentic-framework/agents/context/budget-gate.sh").read().split(chr(10))[151];d=open("docs/reports/framework-agent-pickup-2026-09-09.md").read();sys.exit(0 if g.strip() in d else 1)'

# 3. The exclusions are named, not dropped. Checked by requiring both excluded finding ids to
#    appear in the document.
python3 -c 'import sys;d=open("docs/reports/framework-agent-pickup-2026-09-09.md").read();sys.exit(0 if ("OBS-338" in d and "T-690" in d) else 1)'

# 4. The document does not claim delivery. Guards against the exact failure roadmap 2.3 names:
#    reporting transport that did not happen, or counting transport as collaboration.
python3 -c 'import sys;d=open("docs/reports/framework-agent-pickup-2026-09-09.md").read();sys.exit(0 if "NOT transmitted" in d else 1)'

# 5. We really did change nothing in the vendored hooks this document reports on — the claim
#    "there is no diff of ours to take" must be true in the tree, not just in the prose.
git diff --quiet HEAD -- .agentic-framework/agents/context/check-active-task.sh .agentic-framework/agents/context/budget-gate.sh .agentic-framework/agents/task-create/update-task.sh

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
     fw inception decide T-692 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-09T08:27:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-692-pickup-findings-for-the-aef-agent-three-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-71602412
- **Timestamp:** 2026-09-09T08:30:32Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-09T08:30:31Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
