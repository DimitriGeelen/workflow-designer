---
id: T-1127
name: "Element detail view: clicking an element opens a larger, zoomed view showing
  all its information, editable in place"
description: >
  Inception: Element detail view: clicking an element opens a larger, zoomed view
  showing all its information, editable in place

status: started-work
workflow_type: build
current_node: frw_3_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-11T17:06:05Z
last_update: 2026-10-11T17:40:35Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-11T17:34:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 0
      F1: 2
    rationale: 'D1=2 (body:learning-ref); D2=0 (no-signal); D3=0 (no-signal); D4=2
      (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=1 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L1:keyword=gateway);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=2 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L2:keyword=export)'
    rubric_sha: e4a00f38e801
---

# T-1127: Element detail view: clicking an element opens a larger, zoomed view showing all its information, editable in place

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1127 -->

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
- [x] Double-clicking a flow element (task, event, gateway, sub-process) opens a large details view of it; a handoff keeps its double-click jump (T-160) and, like every element, has an "All details" button in the properties panel header that opens the same view
- [x] The details view shows ALL of the element's configuration: BPMN basics, every Extensions field filled or empty (ignoring the panel's folding and any project/map hide), the read-only "Other extensions", Constituents and the I/O contract — everything editable that the side panel can edit
- [x] A field hidden in the panel by the project/map profile is marked in the details view ("hidden in the panel by this project/map"), so the operator sees why it is absent from the side panel
- [x] Edits in the details view change the same element as the side panel (one model, Ctrl+Z works as in the panel); after closing, the side panel shows the new values; nothing in the export changes merely by opening or closing it
- [x] Closes on Esc, the close button and a click on the backdrop; while open, canvas shortcuts (Delete, Ctrl+Z on the canvas) do not act behind it
- [x] Layout uses the larger space (two columns where it fits), legible at 1400×900 and at 1024×768
- [x] CDP test tools/_t1127-element-details-cdp.mjs covers the above (control: 0.17.0 has no details view); wired into tests/run-bridge-tests.sh; B1/B2/T-1128 tests unchanged
- [x] Screenshots of the details view (a service task with some fields filled, one hidden by the profile) read and recorded under ## Visual Verification

## Verification

# Shell commands that MUST pass before work-completed. One per line.
node tools/_t1127-element-details-cdp.mjs
node tools/_t1124-hide-empty-fields-cdp.mjs
node tools/_t308-bare-catch-render-cdp.mjs

## Visual Verification

- `docs/reports/T-1127-evidence/t1127-details-1400.png` — "Call the service — details": header, BPMN in two columns
  (Name | Slug, Display ID | UID, Lane), Extensions with every field in two columns, Horizon marked "hidden in the side
  panel by this project" in orange; side panel behind still folded ("+ 10 empty fields") with the "⤢ All details"
  button. First version used CSS columns per section and left a tall Extensions column beside an empty one — changed
  to a two-column grid of fields inside each section, read again: balanced, no clipping.
- `docs/reports/T-1127-evidence/t1127-details-1024.png` — fits the 1024×768 viewport; body scrolls; the edited Side
  effect ("writes the ledger") shows. Read: legible.
- Seen while reading: Agent type displays "primary" on a task that never set it — the select has no empty option
  (pre-existing, also in the side panel). Filed separately (one bug = one task), not fixed here.

## Decisions

### 2026-10-11 — converted from inception to build
- **Chose:** build directly, no go/no-go round.
- **Why:** the operator gave the design: "filtering plus details page, but all config with all options. Once I
  double click or whatever ... I get the option to get all options" and objected to shelving it ("build quality
  in here, not to can it and put it on the shelf"). The inception's exploration questions were answered by that.

### 2026-10-11 — how it opens
- **Chose:** double-click on any element except a handoff; an "⤢ All details" button in every element's panel.
- **Why:** a handoff's double-click already jumps to its target workflow (T-160) — keeping it avoids breaking a
  shipped behaviour; the button gives every element (handoffs included) the same way in.
- **Rejected:** double-click everywhere (breaks the handoff jump); button only (operator asked for double-click).

### 2026-10-11 — one renderer for panel and details
- **Chose:** the side panel's renderer draws both, with a `details` flag (all fields, no fold, no profile hide,
  hidden ones marked); no delete button inside the details view.
- **Why:** two renderers would drift in which fields they offer and how they write.

## Decision

<!-- Filled at completion via: fw inception decide T-1127 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-11T17:34:12Z — status-update [task-update-agent]
- **Change:** workflow_type: inception → build

### 2026-10-11T17:34:55Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
