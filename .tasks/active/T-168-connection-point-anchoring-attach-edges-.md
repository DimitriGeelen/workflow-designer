---
id: T-168
name: "Connection-point anchoring: attach edges to a node's individual ports (default center)"
description: >
  Connect and edge-reconnect default to node center (as now) but allow attaching to a specific perimeter connection point (port).

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-09T23:40:52Z
last_update: 2026-07-10T00:02:35Z
date_finished: 2026-07-10T00:02:07Z
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

### Session findings (2026-07-10) — most of this feature already exists

Investigation (Explore agent + live Playwright against the running editor) found the ports/anchors
feature is **already substantially built and shipped** in `src/aef-workflow-designer.html`:

- **Data model:** edges carry optional `sourcePort`/`targetPort` (PORT_NAMES `N…NW` or `auto`);
  absent ⇒ today's auto/center. `PORT_NAMES`/`PORT_OFFSETS`/`portPointAt` (per-shape perimeter
  projection for rect/circle/diamond) at ~:2910.
- **Rendering:** `anchorPoint(node, port, toward)` (:2968) honours an explicit port *exactly* —
  verified live: a pinned E→W edge renders with `gapStart=0, gapEnd=0` from the exact port pixels.
- **Round-trip:** serialized as `<aef:anchors sourcePort=".." targetPort=".."/>` (:7797), parsed
  back (:8039). Verified: E/W round-trips; the seed corpus already contains port-pinned edges.
- **Interaction (existing):** endpoint-drag snap with aim-assist ghost dots + strong snap indicator
  (:5273–5368, commit :5449); clickable port-indicator dots on the selected edge incl. an "auto"
  clear dot (`renderPortIndicators` :2858); properties-panel **Source/Target port** dropdowns +
  **Clear ports** + **Reverse** + inline help (screenshot `.playwright-mcp/t168-existing-ports.png`).

**The one genuine gap** vs the operator's literal words ("make … the **connect** start in the middle
as current **with the option** to attach to the individual connection point"): `connect` mode is
pure node→node (`onNodeClick` :6304 → `addEdge` :6667) — a new edge is always `auto`; to pin a port
you must afterwards select the edge and use the (existing) UI. **This task's deliverable** is to add
port-awareness to the connect gesture: click a node's body ⇒ auto/middle (unchanged); click within
snap radius of a port ⇒ pin that port, with aim-assist dots during the preview for discoverability.
The remaining design-note items below were already implemented — kept for reference.

Original framing (mostly already built — see findings above):

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
     Scoped to the one genuine gap (connect-mode port targeting) after the 2026-07-10 finding
     that the rest of the ports feature already ships. AC1 verifies the pre-existing base; the
     rest deliver + verify the new connect-mode slice. -->
- [x] Verified the pre-existing ports base works end-to-end: `anchorPoint` honours an explicit port exactly (pinned E→W edge renders `gapStart=0, gapEnd=0`), `<aef:anchors>` round-trips (E/W survives parse→serialize), and the selected-edge UI (port dots, Source/Target dropdowns, Clear ports, Reverse) is present. *(evidence: live Playwright + `.playwright-mcp/t168-existing-ports.png`)*
- [x] `connect` mode: clicking a node's **body** attaches the new edge end as `auto`/middle (unchanged default); clicking within the port snap radius of a specific perimeter port **pins that port** — `sourcePort` from the first (source) click, `targetPort` from the second (target) click. New edge carries the expected ports.
- [x] During the connect gesture, **aim-assist port dots** appear on nodes near the cursor and the preview line snaps its end to the nearest in-radius port (discoverability), reusing the endpoint-drag affordance; when `routingPrefs.attach === 'middle'` a body click stays auto (only an explicit near-port click pins), matching the endpoint-drag rule.
- [x] Backwards compatible: a body→body connect still yields an `auto` edge that emits **no** `<aef:anchors>` in serialization; `addEdge(a,b)` with no port opts is unchanged.
- [x] src↔build mirror invariant holds: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`, and `python3 -c "import ast; ast.parse(open('tools/gallery-serve.py').read())"` parses (no server change expected — kept as guard).
- [x] Playwright (throwaway scratch): body→body connect ⇒ edge with no ports; connect clicking near source **E** then target **W** ⇒ `sourcePort='E'`, `targetPort='W'` and the rendered polyline attaches at those ports; element/viewport screenshot READ; 0 non-benign console errors.

### Human
- [ ] [REVIEW] Connect-to-port feels natural and the default is unchanged
  **Steps:**
  1. Open `http://localhost:8834/designer.html`, click **Connect →**.
  2. Draw an edge by clicking one node's body then another's body → it should attach in the middle (as before).
  3. Draw another edge, but this time click **near a specific connection point** (the small dots that light up as you approach a node) on each end.
  **Expected:** Body clicks still attach at the middle; clicking near a port pins the edge to that exact point. The port dots appear as you approach a node so the option is discoverable.
  **If not:** Note whether the default changed, the dots didn't appear, or the pin missed.

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

diff -q src/aef-workflow-designer.html build/gallery/designer.html
python3 -c "import ast; ast.parse(open('tools/gallery-serve.py').read())"

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

## Visual Verification

Connect-mode port targeting exercised live and screenshotted in every mode it affects:
- `.playwright-mcp/t168-connect-aim-assist.png` (READ) — connect gesture from source **E** port,
  cursor near target **W**: green dashed preview line E→W, aim-assist port dots lit on nearby
  nodes' perimeters, dashed snap-indicator on the target W port, no dots on the source node.
- `.playwright-mcp/t168-existing-ports.png` (READ) — pre-existing ports UI (ROUTING panel:
  Source/Target port dropdowns, Clear ports, Reverse) with a pinned E→W edge attaching exactly.

## Recommendation

**Recommendation:** GO
**Rationale:** Investigation found the ports/anchors feature already ships (data model, exact
rendering, `<aef:anchors>` round-trip, endpoint-drag snap, port-dot UI, properties dropdowns).
The one genuine gap — port targeting *during the connect gesture* — is now implemented, matching
the operator's literal ask ("connect start in the middle as current with the option to attach to
the individual connection point"). It is additive and backwards-compatible: a body→body connect is
unchanged (auto, no anchors). Remaining Human AC is a taste-check of the connect feel.
**Evidence:**
- Playwright: body→body connect ⇒ no ports; near-port connect (a.E→b.W) ⇒ `sourcePort='E'`,
  `targetPort='W'`, rendered polyline `gapStart=0/gapEnd=0`, serialized `<aef:anchors sourcePort="E"
  targetPort="W"/>`, `parseBpmnXml` round-trips true.
- Preview aim-assist: 32 port dots + 1 snap indicator + 1 preview line, `connectPreviewSnap={W}`.
- Screenshots read (see Visual Verification). Gates: `diff -q src build` MIRROR-OK; `ast.parse` PARSE-OK.

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

### 2026-07-09T23:46:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-10T00:02:07Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
