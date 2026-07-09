---
id: T-168
name: "Connection-point anchoring: attach edges to a node's individual ports (default center)"
description: >
  Connect and edge-reconnect default to node center (as now) but allow attaching to a specific perimeter connection point (port).

status: captured
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
created: 2026-07-09T23:40:52Z
last_update: 2026-07-09T23:40:52Z
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

# T-168: Connection-point anchoring: attach edges to a node's individual ports (default center)

## Context

Operator (2026-07-10): "can we make the select/move drag & drop and the connect start in the
middle (as current) with the option to attach to the individual connection point, makes sense?"

**Interpretation (confirm with operator at build start):** keep the current default — an edge
attaches at a node's **center/middle** and auto-routes to the nearest face — but add the ability
to deliberately attach an edge END to a **specific perimeter connection point (port)** on a node.
Applies to (a) drawing a new connection in `connect` mode and (b) reconnecting an existing edge
endpoint by dragging it (the T-136/T-137 endpoint-drag path). Same "center by default, port on
demand" behaviour in both.

This is the classic diagram "ports/anchors" feature and is **multi-part** — not a quick edit:

### Design notes (for the next session)
- **Data model (biggest piece):** an edge END is currently center/auto-routed. Add an optional
  explicit anchor per end, e.g. `edge.sourceAnchor` / `edge.targetAnchor` as a normalized
  perimeter position (`{side:'n|e|s|w', t:0..1}` or a fixed port index like 8-point N/NE/E/…).
  Absent anchor = today's auto/center behaviour (backwards compatible). Must round-trip through
  the aef: serialization (parse + serialize) — mirror the T-137 `detourY` persistence pattern;
  add to the round-trip guard (G-002).
- **Interaction:** in `connect` mode (and when dragging an existing endpoint), when the pointer
  is near a node's perimeter, reveal the candidate connection points (small dots) and snap the
  end to the nearest one; releasing over the node body (not near a point) = center/auto (current).
  A modifier (e.g. hold Alt) could force center even near a point — decide during build.
- **Rendering/routing:** when an end has an explicit anchor, route from/to that exact point
  instead of the computed nearest-face attach; keep the existing router for anchorless ends.
  Watch the T-117/T-118 de-jog + endpoint-straight-snap passes — they must respect a fixed anchor.
- **Ports geometry:** define the port set per node shape (rect: 8 points N/NE/E/SE/S/SW/W/NW;
  gateway diamond: 4 vertices; event circle: 4/8 around the circle). One helper
  `nodePorts(n) -> [{id, x, y}]` reused by hit-testing and rendering.
- **Scope check at build start:** if this balloons (new subsystem-scale interaction + model +
  router changes), split into (1) data-model + serialization round-trip, (2) connect-mode port
  snapping, (3) endpoint-drag reconnect to port, (4) router honours anchors. Likely ≥2 tasks.

**Sizing note:** captured at session budget-ceiling; deferred deliberately so it isn't half-built.
Reassess whether this should be an inception (interaction design has real choices) vs a build.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these.
     PLACEHOLDER — the operator's interpretation must be confirmed and this likely decomposes
     into ≥2 tasks (see Design notes). Real ACs to be written at build start. Candidate ACs: -->
- [ ] Edge ends carry an optional explicit anchor (`sourceAnchor`/`targetAnchor`) that round-trips through parse→serialize; absent anchor = current center/auto behaviour (backwards compatible; round-trip guard updated).
- [ ] `connect` mode reveals a node's connection points on approach and snaps the new edge end to the nearest port; releasing over the body (not near a port) keeps today's center/auto attach.
- [ ] Dragging an existing edge endpoint can re-attach it to a specific port (reuses T-136/T-137 endpoint-drag path); the router honours a fixed anchor (de-jog/straight-snap passes respect it).
- [ ] src↔build mirror invariant holds: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`.

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

### 2026-07-09T23:40:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-168-connection-point-anchoring-attach-edges-.md
- **Context:** Initial task creation
