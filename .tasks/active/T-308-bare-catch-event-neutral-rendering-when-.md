---
id: T-308
name: "Bare catch-event neutral rendering when unbound (T-244 GO, path b)"
description: >
  Bare catch-event neutral rendering when unbound (T-244 GO, path b)

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
created: 2026-07-29T17:47:21Z
last_update: 2026-07-29T17:47:21Z
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

# T-308: Bare catch-event neutral rendering when unbound (T-244 GO, path b)

## Context

Implements the **GO decision recorded on T-244** (operator, 2026-07-29T17:46:29Z), scoped to **path
(b)** — a rendering/property-panel branch, explicitly **NOT** a new node type. Full exploration and
pricing: `docs/reports/T-244-bare-catch-event-exploration.md`.

**What's wrong:** `REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch'`
(src/aef-workflow-designer.html:9347) is the fallback decode, so a bare `intermediateCatchEvent`
(no `aef:link`, no `aef:eventDef`) becomes a "← Handoff" node — label src:7783, link-catch glyph
src:5662, link property schema src:1784 — whose target fields can never bind. AEF's operator read
exactly this as a broken connector on a healthy map.

**Why path (b) is safe:** verified during exploration that `aefExtensionXml` emits `<aef:link>` only
when a binding field is non-empty, and `linkEventCatch` exports as `intermediateCatchEvent`
(src:8985) — so a bare catch event already round-trips byte-clean. This change must therefore alter
**zero exported bytes**: no schema change, no dialect change, nothing for AEF to ratify.

**The design constraint (IW-3, confidence 3):** a palette-created handoff node is *equally* unbound,
and the dialect has no carrier for authorial intent — "author placed a handoff, not yet bound" and
"bare imported catch event" serialize identically. So intent lives in **session state**: show the
handoff UI while the node is live in the editor this session, render neutral after a reload. A
persisted "intended handoff" marker is out of scope — it would be a dialect change, i.e. path (a).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] An unbound, non-session-authored catch event renders a neutral glyph and neutral label (not "← Handoff"), and its property panel does not offer the dead link fields (workflowRef/name/targetWorkflow/linkId)
- [ ] A palette-created `linkEventCatch` still shows the handoff UI for the duration of the authoring session, so binding stays discoverable; after reload it renders neutral (session-state intent, no persisted marker)
- [ ] A node that DOES carry a binding (`workflowRef`/`targetWorkflow`/`linkId`) is unaffected — glyph, label and property panel unchanged
- [ ] Zero exported-byte change: for every corpus map, `buildBpmnXml(state)` is byte-identical before and after this change (no schema surface, nothing for AEF to ratify)
- [ ] Regression test added that imports a bare `intermediateCatchEvent` fixture and asserts the neutral presentation plus the unchanged export bytes; wired into the bridge suite
- [ ] Bridge + validator + geometry suites green, failure-shape asserted not count-pinned (PL-061)

### Human
- [ ] [REVIEW] The neutral glyph reads as "an event of unspecified kind", not as a broken or missing node
  **Steps:**
  1. Open the designer at the Watchtower URL: `cd /opt/832-Workflow-designer && cat .context/working/watchtower.url` then browse to `<that URL>/designer/app`
  2. Import (or open) the bare-catch-event test fixture named in this task's Verification section
  3. Look at the bare catch event next to a real bound handoff node and a typed event
  **Expected:** the bare one reads as neutral/unspecified — clearly not an error state, clearly not a handoff
  **If not:** say which reading it gives instead (broken? missing? same as something else?) and the glyph will be revised
- [ ] [REVIEW] Placing a handoff from the palette still feels discoverable
  **Steps:**
  1. In the same designer, drag `← Handoff` from the palette onto the canvas
  2. Without binding it, check the node and its property panel
  3. Reload the page and look at the same node again
  **Expected:** while placing, the handoff affordance and target fields are present; after reload it renders neutral
  **If not:** note which half feels wrong — the live affordance or the post-reload neutrality

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-29T17:47:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-308-bare-catch-event-neutral-rendering-when-.md
- **Context:** Initial task creation
