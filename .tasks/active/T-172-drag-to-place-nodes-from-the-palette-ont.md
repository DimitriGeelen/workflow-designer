---
id: T-172
name: "Drag-to-place nodes from the palette onto the canvas"
description: >
  Drag-to-place nodes from the palette onto the canvas

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
created: 2026-07-10T05:19:47Z
last_update: 2026-07-10T05:25:59Z
date_finished: 2026-07-10T05:25:59Z
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

# T-172: Drag-to-place nodes from the palette onto the canvas

## Context

Today the palette is **click-to-place**: click a `.palette-item` (`data-create="<type>"`), then click
the canvas to drop a node (hint at `src/aef-workflow-designer.html:1110`). The operator asked to add
**drag-to-place**: press on a palette item and drag it onto the canvas, dropping a node at the cursor.

Design (sensible defaults, no operator decision needed):
- **Complement, not replace** — keep click-to-place working; add drag as a second path.
- Use HTML5 drag-and-drop: `.palette-item` gets `draggable="true"` + `dragstart` storing the
  `data-create` type in `dataTransfer`; the canvas handles `dragover` (preventDefault + `dropEffect
  = 'copy'`) and `drop` (preventDefault, read type, convert client→world coords, create the node).
- Reuse the existing node-creation path (`createNodeAt`/equivalent) and coordinate transform so the
  node lands under the cursor and inherits the same lane assignment as a click-placed node.
- Undoable (one history entry per drop) and selected after drop, matching click-to-place.

## Acceptance Criteria

### Agent
- [x] `.palette-item` elements are `draggable` and a `dragstart` handler puts the node type (`data-create`) into `dataTransfer` (verified: `dt.types` = `['application/x-aef-node','text/plain']`; add-lane item `draggable=false`).
- [x] The canvas has `dragover` (calls `preventDefault`, sets `dropEffect='copy'`) and `drop` handlers; `drop` calls `preventDefault` and creates a node of the dragged type (verified: `dragoverPrevented=true`, `dropPrevented=true`, `added=1`, `newType=serviceTask`).
- [x] The dropped node is created at the cursor position (world coords via the existing client→SVG transform), with the same lane assignment logic as click-to-place (verified: drop world `968,392` vs node center `965,394`; `lane=framework` by y).
- [x] Drop pushes exactly one undo-history entry and leaves the new node selected (verified: `undoRemovedOne=true`, `selectedIsNew=true`, redo restores).
- [x] Existing click-to-place still works (verified: palette click → `create:userTask`, canvas click adds userTask, mode → select).
- [x] `src/aef-workflow-designer.html` is mirrored to `build/gallery/designer.html` (`diff -q` clean).
- [x] Playwright: a synthetic drag of a palette item onto the canvas adds a node of the expected type at ~the drop point; screenshot READ confirms it rendered.

### Human
- [ ] [REVIEW] Drag-to-place feels natural
  **Steps:**
  1. Open the designer (gallery: `http://localhost:8834/designer.html`).
  2. Press and hold a palette item (e.g. Service Task) and drag it onto the canvas; release over a lane.
  3. Try it for a few node types and a few drop positions; also confirm the old click-to-place still works.
  **Expected:** A node of the dragged type appears where you dropped it, in the lane under the cursor; the drag has a copy cursor; one Ctrl+Z removes it. Click-to-place unchanged.
  **If not:** Note which type/position misbehaved (wrong lane, offset from cursor, no node, or click-to-place broken) and screenshot.

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

# T-172 — handlers wired + mirror in sync:
grep -q "dragstart" src/aef-workflow-designer.html
grep -qE "dragover|ondragover" src/aef-workflow-designer.html
grep -qE "'drop'|\"drop\"|ondrop" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html

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

### 2026-07-10T05:19:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-172-drag-to-place-nodes-from-the-palette-ont.md
- **Context:** Initial task creation

## Visual Verification

- **Screenshot:** `.playwright-mcp/t172-drop-serviceTask.png` (READ) — after a synthetic drag of the
  Service Task palette item onto the framework lane, a blue "Task" node is rendered and selected at
  the drop point; the palette hint now reads "…click the canvas to place — or **drag** it straight
  onto the canvas." No visual regression to existing nodes/lanes.
- Change is behavioral (HTML5 DnD wiring) + a one-line hint tweak; the dropped node reuses the
  existing node renderer, so no theme/density/font-mode-specific rendering is introduced.

### Implementation evidence [agent]
- Palette items with `data-create` get `draggable=true` + a `dragstart` that sets
  `application/x-aef-node` (and `text/plain` fallback) to the node type; add-lane item excluded.
- Canvas `dragover` gates on `dataTransfer.types` (getData is unreadable during dragover),
  `preventDefault`s and sets `dropEffect='copy'`; `drop` reads the type, validates against
  `NODE_DEFAULTS`, converts client→world via `clientToSvg`, and calls `createNodeAt` (which already
  handles one undo entry, lane-by-y, and selection). Click-to-place path untouched.

## Recommendation

**Recommendation:** GO

**Rationale:** Drag-to-place is implemented as a purely additive second path — click-to-place is
untouched and verified unregressed. The drop reuses the existing `createNodeAt`, so it inherits the
same lane assignment, single-undo entry, and post-create selection as a click placement; there is no
new node-model or serialization surface. All seven agent ACs verified end-to-end via a synthetic
Playwright drag. Only the subjective "feels natural" judgment remains — genuinely yours (native drag
cursor/feel is best judged with a real pointer, which synthetic events can't capture).

**Evidence:**
- Synthetic drag: `added=1`, `newType=serviceTask`, drop world `968,392` vs node center `965,394`
  (~3px), `lane=framework` (by y), `selectedIsNew=true`, `undoRemovedOne=true`, redo restores.
- Regression: click-to-place still adds a node and returns to `select` mode.
- Screenshot READ: `.playwright-mcp/t172-drop-serviceTask.png` — dropped node rendered + selected;
  palette hint updated; no visual regression.
- Verification gate: 4/4 (dragstart / dragover / drop handlers present; mirror `diff -q` clean).
- `src/aef-workflow-designer.html:5079+` (palette dragstart + canvas dragover/drop), hint at `:1110`.

### 2026-07-10T05:25:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
