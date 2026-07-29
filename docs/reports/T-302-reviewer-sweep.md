# T-302 — Reviewer sweep of the verification queue (2026-07-29)

## Census correction

The filing-time premise ("53 [REVIEWER] ACs convertible") was a measurement defect: every task file embeds a `- [ ] [REVIEWER]` example inside an HTML template comment, and the raw grep counted those. Comment-stripped reality across `.tasks/active/`:

- **0** real `[REVIEWER]` ACs (checked or unchecked)
- **76** unchecked `[REVIEW]` Human ACs — exactly one per queue task
- Classification: **1** deterministic mis-prefix (PL-027 class) → converted (T-090); **10** inception decision gates → sovereignty, never automatable; **65** genuine taste → stay human

## Reviewer verdicts (fw reviewer, catalogue v1.3-seed, run on all 76)

**56 PASS / 20 CONCERN.** Every CONCERN is advisory hygiene (heuristic `AC-verify-mismatch`, `l387-sigpipe-risk` lint on Verification lines) — none contradicts the shipped work or blocks the human queue. Verdict sections are recorded in each task file by the tool.

CONCERN tasks: T-041 T-081 T-098 T-099 T-100 T-101 T-105 T-107 T-115 T-127 T-136 T-137 T-164 T-165 T-166 T-167 T-168 T-189 T-197 T-204

## Converted (1)

- **T-090** — `[RUBBER-STAMP]` "review queue loads, no 500": Expected is a curl check that already lived in its `## Verification`. Re-verified live (HTTP 200, `<title>Review T-089</title>`), moved to `### Agent` ticked. Human section now empty; owner is human, so the agent did not finalize. Close: `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-090 --status work-completed`

## Operator batch checklist

Grouped by surface so the queue clears in a few sittings, not 75 context switches. Each row: what to judge, where, and the one-line tick+close command to run **after** you're satisfied. Commands only appear where the taste AC is the sole unchecked box.

### Inception decisions (10) — `fw inception decide`, not tick-and-close

- **T-184** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-184 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-185** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-185 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-186** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-186 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-244** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-244 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-277** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-277 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-279** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-279 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-280** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-280 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-281** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-281 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-282** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-282 go --rationale "<why>"` (or `no-go`/`defer`)
- **T-301** (PASS) — Review exploration findings and approve go/no-go decision
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-301 go --rationale "<why>"` (or `no-go`/`defer`)

### Designer editor feel-checks

- **T-074** (PASS) — Snapping feels helpful, not sticky
  - http://192.168.10.107:8834/designer.html?load=rendered/healing-loop.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-074-magnetic-drag-snapping--lane-centre-neig.md && .agentic-framework/bin/fw task update T-074 --status work-completed`
- **T-075** (PASS) — Settings dialog is clear and the knobs do what they say
  - http://192.168.10.107:8834/designer.html?load=rendered/healing-loop.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-075-editor-settings-page--consolidate-routin.md && .agentic-framework/bin/fw task update T-075 --status work-completed`
- **T-079** (PASS) — Sub-row snapping and tidy-lane feel right in tall lanes
  - http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-079-adaptive-alignment-rows-sub-row-snap-lin.md && .agentic-framework/bin/fw task update T-079 --status work-completed`
- **T-081** (CONCERN) — Collapsed subProcess glyph reads clearly
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-081-subprocess-node-type-phase-1-collapsed-o.md && .agentic-framework/bin/fw task update T-081 --status work-completed`
- **T-084** (PASS) — Lane names read naturally in the header strip across the corpus
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-084-lane-header-ellipsis-truncate-vertical-l.md && .agentic-framework/bin/fw task update T-084 --status work-completed`
- **T-094** (PASS) — Aligned chains read straight, nothing looks displaced
  - http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-094-align-rows-one-shot-action-snap-lane-row.md && .agentic-framework/bin/fw task update T-094 --status work-completed`
- **T-095** (PASS) — One Clean click reads well end-to-end
  - http://192.168.10.107:8834/designer.html?load=rendered/audit-process.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-095-clean-layout-composite-action-tidy--bran.md && .agentic-framework/bin/fw task update T-095 --status work-completed`
- **T-096** (PASS) — Density now visibly does something
  - http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-096-density-setting-has-no-visible-effect---.md && .agentic-framework/bin/fw task update T-096 --status work-completed`
- **T-097** (PASS) — Fan/join corridors read cleanly — branch edges fan out in parallel channels instead of a crossing tangle
  - http://192.168.10.107:8834/designer.html?load=rendered/audit-process.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-097-crossing-aware-branch-ordering-order-fan.md && .agentic-framework/bin/fw task update T-097 --status work-completed`
- **T-098** (CONCERN) — Channel separation control feels right on real maps
  - http://192.168.10.107:8834/designer.html?load=rendered/audit-process.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-098-edge-channel-separation-setting-corridor.md && .agentic-framework/bin/fw task update T-098 --status work-completed`
- **T-099** (CONCERN) — Clean-on-import feels right
  - http://192.168.10.107:8834/designer.html
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-099-clean-layout-on-import-opt-in-setting-ap.md && .agentic-framework/bin/fw task update T-099 --status work-completed`
- **T-100** (CONCERN) — Nudge is helpful, not naggy
  - http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-100-clean-layout-nudge-offer-one-click-clean.md && .agentic-framework/bin/fw task update T-100 --status work-completed`
- **T-101** (CONCERN) — Shipped corpus maps open tidy in the served designer, and the Clean nudge no longer fires on them
  - http://192.168.10.107:3000/designer
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-101-bake-clean-layout-into-the-rendered-corp.md && .agentic-framework/bin/fw task update T-101 --status work-completed`
- **T-114** (PASS) — Rerouted fan/join edges look clean, not contorted
  - http://localhost:8834/designer.html?load=rendered/harvest-pipeline.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-114-obstacle-avoiding-orthogonal-edge-routin.md && .agentic-framework/bin/fw task update T-114 --status work-completed`
- **T-125** (PASS) — Compacted layouts match your correction taste (pairs 1–3)
  - http://192.168.10.107:8834/designer.html?load=rendered/task-lifecycle.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-125-vertical-lane-compaction-in-cleanlayout-.md && .agentic-framework/bin/fw task update T-125 --status work-completed`
- **T-134** (PASS) — This is the align/distribute behaviour you wanted. **Steps:** open the editor,
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-134-selection-scoped-align-and-distribute-fo.md && .agentic-framework/bin/fw task update T-134 --status work-completed`
- **T-137** (CONCERN) — At a gateway→node loop-back you couldn't straighten before, selecting the edge
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-137-loop-back-edges-with-persisted-detoury-c.md && .agentic-framework/bin/fw task update T-137 --status work-completed`
- **T-141** (PASS) — The guard feels right — an unedited starter map warns before saving, a real
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-141-guard-save-to-project-against-the-pristi.md && .agentic-framework/bin/fw task update T-141 --status work-completed`
- **T-144** (PASS) — The Open-project browser feels right
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-144-in-editor-open-from-project-modal-uses-a.md && .agentic-framework/bin/fw task update T-144 --status work-completed`
- **T-164** (CONCERN) — Version-browsing hover-zoom feels consistent with Open-project
  - http://localhost:8834/designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-164-consistent-tile-hover-zoom-in-the-versio.md && .agentic-framework/bin/fw task update T-164 --status work-completed`
- **T-165** (CONCERN) — Open vs Revert reads clearly
  - http://localhost:8834/designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-165-open-this-version-action-in-the-versions.md && .agentic-framework/bin/fw task update T-165 --status work-completed`
- **T-166** (CONCERN) — Deleting a workflow feels safe and clear
  - http://localhost:8834/designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-166-delete-a-workflow-from-the-project-archi.md && .agentic-framework/bin/fw task update T-166 --status work-completed`
- **T-167** (CONCERN) — Version-level delete + keep-only-latest read clearly
  - http://localhost:8834/designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-167-version-level-delete-and-keep-only-lates.md && .agentic-framework/bin/fw task update T-167 --status work-completed`
- **T-168** (CONCERN) — Connect-to-port feels natural and the default is unchanged
  - http://localhost:8834/designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-168-connection-point-anchoring-attach-edges-.md && .agentic-framework/bin/fw task update T-168 --status work-completed`
- **T-172** (PASS) — Drag-to-place feels natural
  - http://localhost:8834/designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-172-drag-to-place-nodes-from-the-palette-ont.md && .agentic-framework/bin/fw task update T-172 --status work-completed`
- **T-214** (PASS) — The session/handover diagram reads faithfully in the designer UI (the pair-draft review step)
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-214-pair-draft-sessionhandover-corpus-diagra.md && .agentic-framework/bin/fw task update T-214 --status work-completed`
- **T-215** (PASS) — The dispatch-loop diagram reads faithfully in the designer UI (the pair-draft review step)
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-215-pair-draft-dispatch-loop-corpus-diagram-.md && .agentic-framework/bin/fw task update T-215 --status work-completed`
- **T-228** (PASS) — The "create from pending ref" picker reads clearly and the suggest-only affordance is unambiguous
  - http://192.168.10.107:8834/designer.html
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-228-s4-off-page-claim-ux--create-from-pendin.md && .agentic-framework/bin/fw task update T-228 --status work-completed`
- **T-245** (PASS) — The view-chrome controls feel right
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-245-canvas-view-chrome-controls-paletteprope.md && .agentic-framework/bin/fw task update T-245 --status work-completed`
- **T-255** (PASS) — Dragging the page's right edge feels natural and useful
  - http://192.168.10.107:8834/designer.html?load=rendered%2Fharvest-pipeline.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-255-pool-right-edge-resize-handle-authored-p.md && .agentic-framework/bin/fw task update T-255 --status work-completed`
- **T-258** (PASS) — Badge look-and-feel reads right
  - http://192.168.10.107:8834/t258-annotation-badges.png
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-258-annotation-seam-v0-postmessage-aefreadya.md && .agentic-framework/bin/fw task update T-258 --status work-completed`
- **T-264** (PASS) — Guard prompts read right (wording + non-naggy feel)
  - http://192.168.10.107:8834/designer.html
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-264-save-target-guard-set-id-field-collision.md && .agentic-framework/bin/fw task update T-264 --status work-completed`
- **T-286** (PASS) — Arrow-over-badge default + selected-badge-forward feels right; endpoint drag handles now grabbable near badges
  - http://192.168.10.107:3000/designer
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-286-edge-arrowheads-render-above-node-id-bad.md && .agentic-framework/bin/fw task update T-286 --status work-completed`
- **T-293** (PASS) — Endpoint reconnect drag feels right at frw_11_harvest
  - http://192.168.10.107:3000/designer
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-293-endpoint-reconnect-drag-hand-often-fails.md && .agentic-framework/bin/fw task update T-293 --status work-completed`

### Served gallery reads

- **T-041** (CONCERN) — The rendered `inception-review` diagram faithfully matches the real flow you just experienced (A-4 fidelity pilot)
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-041-render-inception-review-and-run-operator.md && .agentic-framework/bin/fw task update T-041 --status work-completed`
- **T-073** (PASS) — Straightened routing reads calmer on the live gallery
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-073-router-straightening-tolerance--near-ali.md && .agentic-framework/bin/fw task update T-073 --status work-completed`
- **T-076** (PASS) — Loop-backs read as calm periphery detours on the live gallery
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-076-routing-survey-r-2-loop-back-edges-shoul.md && .agentic-framework/bin/fw task update T-076 --status work-completed`
- **T-077** (PASS) — Relocated labels read naturally on the live gallery
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-077-routing-survey-r-5-keep-badges-and-edge-.md && .agentic-framework/bin/fw task update T-077 --status work-completed`
- **T-082** (PASS) — Edge labels read cleanly on the live gallery — no label sitting on top of a line, badge, or another label at the hotspots from your 2026-07-04 evaluation
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-082-edge-label-placement-pass-measure-after-.md && .agentic-framework/bin/fw task update T-082 --status work-completed`
- **T-089** (PASS) — The 3 wrapped edge labels read cleanly on the live gallery and nothing else regressed
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-089-edge-label-wrap-multi-line-edge-labels-s.md && .agentic-framework/bin/fw task update T-089 --status work-completed`
- **T-102** (PASS) — Nudge stays quiet after Clean fully tidies a map, and still appears on a genuinely messy one
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-102-mapmessiness-false-positive-branch-stack.md && .agentic-framework/bin/fw task update T-102 --status work-completed`
- **T-104** (PASS) — Density / Branch pitch now visibly do something
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-104-density-and-branch-pitch-view-settings-a.md && .agentic-framework/bin/fw task update T-104 --status work-completed`
- **T-105** (CONCERN) — verification-gate (and neighbours) open with readable, non-overlapping
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-105-baked-verification-gate-gateway-label-collision.md && .agentic-framework/bin/fw task update T-105 --status work-completed`
- **T-106** (PASS) — Routing-margin setting visibly reserves a wider periphery band; loop-backs stop cutting through row-2 nodes at roomy, and non-loop edges are unaffected
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-106-routing-margin-setting-reserved-peripher.md && .agentic-framework/bin/fw task update T-106 --status work-completed`
- **T-107** (CONCERN) — Align columns straightens vertical connected runs without disturbing horizontal flow
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-107-align-columns-one-shot-action-snap-near-.md && .agentic-framework/bin/fw task update T-107 --status work-completed`
- **T-108** (PASS) — The vertical-spacing control visibly adjusts row spacing, and no ineffective control remains
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-108-vertical-spacing-control-and-density-bra.md && .agentic-framework/bin/fw task update T-108 --status work-completed`
- **T-109** (PASS) — The Distribute evenly button visibly evens out uneven horizontal spacing without breaking layout
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-109-distribute-evenly-action-equalise-horizo.md && .agentic-framework/bin/fw task update T-109 --status work-completed`
- **T-115** (CONCERN) — Horizontal spacing control feels right and produces tidy layouts
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-115-horizontal-spacing-control-mirror-of-ver.md && .agentic-framework/bin/fw task update T-115 --status work-completed`
- **T-116** (PASS) — Clean now aligns columns in the middle and drops connect at a clean 90°
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-116-align-in-middle-wire-align-columns-centr.md && .agentic-framework/bin/fw task update T-116 --status work-completed`
- **T-117** (PASS) — Branch edges read as clean 90° corners, not staircases
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-117-de-jog-routed-edges-collapse-tiny-interi.md && .agentic-framework/bin/fw task update T-117 --status work-completed`
- **T-118** (PASS) — Edges connect to node faces with a clean 90° corner, no tiny endpoint step
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-118-endpoint-straight-snap-collapse-endpoint.md && .agentic-framework/bin/fw task update T-118 --status work-completed`
- **T-119** (PASS) — Small node-offset connectors read as one clean Z, not a double staircase
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-119-consolidate-split-migrations-two-step-st.md && .agentic-framework/bin/fw task update T-119 --status work-completed`
- **T-139** (PASS) — Toolbar reads clean with only Clean layout remaining; Clean still tidies + aligns columns
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-139-retire-align-columns-and-distribute-even.md && .agentic-framework/bin/fw task update T-139 --status work-completed`
- **T-240** (PASS) — The auto-resolved readout reads clearly in the properties panel
  - http://192.168.10.107:8834/aef-workflow-designer.html?load=arc-lifecycle.bpmn
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-240-uuid-workflowref-auto-resolve-jump-targe.md && .agentic-framework/bin/fw task update T-240 --status work-completed`

### Watchtower pages

- **T-090** (PASS) — [RUBBER-STAMP] The review queue loads again in your browser — *already converted; nothing to tick, just close*
  - http://192.168.10.107:3005/review/T-089
  - `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-090 --status work-completed`
- **T-204** (CONCERN) — Typed-event nodes render correctly in the served designer across visual modes.
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-204-typed-bpmn-event-palette-errortimermessa.md && .agentic-framework/bin/fw task update T-204 --status work-completed`

### Other

- **T-083** (PASS) — Badges and edge labels stay legible where lines must pass under them
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-083-label-halo-theme-background-rect-behind-.md && .agentic-framework/bin/fw task update T-083 --status work-completed`
- **T-085** (PASS) — View controls feel right on real maps
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-085-view-density--label-visibilitysize-contr.md && .agentic-framework/bin/fw task update T-085 --status work-completed`
- **T-087** (PASS) — Long task names read well inside their boxes
  - http://192.168.10.107:8834/
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-087-node-label-fit-ladder-long-task-names-mu.md && .agentic-framework/bin/fw task update T-087 --status work-completed`
- **T-127** (CONCERN) — I edit a map, reload the page, and my work is just there — no banner to click.
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-127-editor-repo-save-versioning-revert-autoreload.md && .agentic-framework/bin/fw task update T-127 --status work-completed`
- **T-132** (PASS) — Undo/redo feels right in normal editing.
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-132-b5-general-undo-redo-history-stack.md && .agentic-framework/bin/fw task update T-132 --status work-completed`
- **T-136** (CONCERN) — At a fork/join, clicking between the converging lines now reliably selects the one
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-136-endpoint-overlap-selection-blocked-at-convergence.md && .agentic-framework/bin/fw task update T-136 --status work-completed`
- **T-176** (PASS) — Embedded fonts render identically to the CDN version, no visible regression
  - http://127.0.0.1:8199/aef-workflow-designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-176-offline-harden-the-designer-inline-or-se.md && .agentic-framework/bin/fw task update T-176 --status work-completed`
- **T-189** (CONCERN) — Operator sign-off to graduate the IW-9 delta into the FROZEN v1 standard (v1 → v1.1)
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-189-iw-9-v11-mapping-standard-delta--collaps.md && .agentic-framework/bin/fw task update T-189 --status work-completed`
- **T-195** (PASS) — Graduate (or rule on) the G-3 collapsed-inception v1.1 delta
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-195-draft-g-3-collapsed-inception-v11-delta-.md && .agentic-framework/bin/fw task update T-195 --status work-completed`
- **T-197** (CONCERN) — Derived-owner readout reads clearly and no dead affordance remains
  - http://127.0.0.1:8199/aef-workflow-designer.html`
  - `cd /opt/832-Workflow-designer && sed -i '0,/- \[ \] \[REVIEW\]/s//- [x] [REVIEW]/' .tasks/active/T-197-iw-9-editor-ui-retire-node-owner-overrid.md && .agentic-framework/bin/fw task update T-197 --status work-completed`


---

## Pre-flight stamp (T-305, 2026-07-29)

Every close command above runs the P-011 verification gate. T-305 pre-flighted the full gate surface **before** handing you this checklist:

- **Extracted:** 330 Verification lines across the 66 close-ready tasks (same comment-stripped parser as the gate), deduped to **213 unique commands**, each executed once.
- **Found rotted:** 10 failing lines, 6 root classes — count-pinned suite totals (`31 passed` vs today's 43), `grep -c` exiting 1 on zero matches under `set -e`, exact-count source greps outgrown by legitimate call sites, checks against the shim deleted at the T-276 re-vendor, the forbidden yaml-to-bpmn regen-diff (G-012 destructive path vs editor-saved dialect), and a curl at retired port :8834 (T-253 ufw RCA).
- **Fixed:** 26 task files, Verification sections only. No expectation was weakened beyond count-agnosticism — every suite check still requires `0 failed`.
- **Re-verified green:** one fresh bridge-suite run (43 passed, 0 failed) evaluates the shared count-agnostic pattern; every other fixed line re-executed standalone; the 7 structurally-edited tasks (T-075 T-090 T-095 T-096 T-101 T-195 T-293) passed full `fw task verify`.

The one-line closes above should now pass their gates without blocking in your face. Learning captured as PL-061: Verification lines assert failure-shape (`passed, 0 failed`), never pinned totals.
