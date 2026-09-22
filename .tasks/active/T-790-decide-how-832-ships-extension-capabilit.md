---
id: T-790
name: "Decide how 832 ships extension capability: Claude Code plugin, MCP server, or both — and what that costs in portability"
description: >
  Decide how 832 ships extension capability: Claude Code plugin, MCP server, or both — and what that costs in portability

status: started-work
workflow_type: design
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T07:57:25Z
last_update: 2026-09-22T07:57:25Z
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

# T-790: Decide how 832 ships extension capability: Claude Code plugin, MCP server, or both — and what that costs in portability

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

The operator installed `plugin-dev` and `mcp-server-dev` and asked for the difference,
stating a hypothesis: *"I think I actually want to go the route of mcp because that makes it
more vendor agnostic and it will also work for other harnesses besides Anthropic or Claude
Code."* This task answers that from the installed sources rather than from priors.

Directly engages **D4 Portability** ("no provider/language/environment lock-in; prefer
standards — MCP, LSP, OpenAPI") and the operator's standing plugin-independence constraint
("independent, can run standalone, no dependency on a service commercial or non-commercial",
refined to load-bearing vs optional).

Research artifact: `docs/reports/T-790-plugin-vs-mcp.md`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the comparison is grounded in the installed sources, not in priors.** Every
      structural claim about what a plugin or an MCP server can contain is traced to a file
      in the two installed plugin trees, cited by path. A confident answer from memory about
      a fast-moving surface is the failure mode this AC exists to prevent.
      Evidence: §6 of the report — 8 citation checks, all green, including a positive control
      on the absence claim. Cited paths: `plugin-dev/skills/{mcp-integration,plugin-structure,
      hook-development}/SKILL.md`, `mcp-server-dev/skills/build-mcp-server/SKILL.md` and its
      `references/server-capabilities.md`, `mcp-server-dev/README.md`.
- [x] **AC2 — the operator's hypothesis is answered on its merits, including where it is
      incomplete.** Not "yes, MCP is more portable" — the specific capability that does NOT
      travel over MCP is named, with the evidence that it has no MCP equivalent. Agreeing
      with a correct-but-partial premise and stopping there would leave a gap they would
      discover later, in code.
      Evidence: §3. The hypothesis is CORRECT for capability and INCOMPLETE for governance —
      MCP has no lifecycle interception, so the nine plugin hook events have no MCP
      equivalent. Grounded in this session's own four gate firings (P-002, G-020, G-067,
      T-638) rather than in theory, and verified as an absence with a positive control.
- [x] **AC3 — the collision with this project's own standalone constraint is surfaced.**
      `build-mcp-server`'s default recommendation is measured against the operator's ruling
      and the conflict stated plainly, with the MCP shape that does satisfy the constraint.
      Evidence: §4. The skill's ⭐ default (remote streamable-HTTP) is a load-bearing service
      dependency by construction and therefore fails the operator's constraint. Local stdio
      and MCPB — both ranked lower by the skill — pass, and MCPB passes best.
- [x] **AC4 — a recommendation is made, not a survey.** One recommended arrangement, with
      what it costs and what it gives up. The decision itself remains the operator's.
      Evidence: §5 — logic in an MCPB-packaged local stdio MCP server, thin Claude Code
      plugin wrapping it for ergonomics, governance explicitly NOT made portable. What it
      gives up is stated in the same section: outside Claude Code the capability travels with
      none of the enforcement.

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
         1. Run `bin/fw reviewer T-790`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-790 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# These legs assert REPO facts only. The citation checks against the installed plugin
# trees are dated in §6 of the report instead, because that cache lives outside the
# repository under a content hash that changes on reinstall — T-787, this session, was
# exactly the cost of pinning a durable claim to an ephemeral external path.
test -f docs/reports/T-790-plugin-vs-mcp.md
grep -q 'they are not alternatives' docs/reports/T-790-plugin-vs-mcp.md
# AC2: the incompleteness in the hypothesis is named, not softened.
grep -q 'MCP has no equivalent' docs/reports/T-790-plugin-vs-mcp.md
# AC3: the constraint collision is stated.
grep -q 'load-bearing service dependency by construction' docs/reports/T-790-plugin-vs-mcp.md
# AC4: one recommendation, and its cost.
grep -q 'What this gives up, stated plainly' docs/reports/T-790-plugin-vs-mcp.md

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
     fw inception decide T-790 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T07:57:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-790-decide-how-832-ships-extension-capabilit.md
- **Context:** Initial task creation
