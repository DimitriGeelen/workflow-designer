# T-1147 — fabric edges the current enricher does not find

27 cards under `.fabric/components/` carried uncommitted edge rewrites from about 2026-10-01 (origin unknown;
a 2026-10-08 `git stash`/pop reset their mtimes). Compared with the committed cards and with a fresh
`fw fabric enrich --no-describe` of the same cards (2026-10-13):

- the old rewrites DROPPED edges the committed cards have and that are real (e.g. `tests/test_bridge_aef_passthrough.py`
  called by `tests/run-bridge-tests.sh`), so they were not committed;
- fresh enrich = committed edges + 34 new ones, nothing removed; that is what was committed;
- the old rewrites also held the edges below, which fresh enrich does not produce. A sample was checked against
  the source and is real (run-bridge-tests.sh names test_t962_findings_on_map.py 3x and
  _t634-guard-verdict-reaches-caller.sh; _t890-lanemeta-guard-teeth.sh reads the designer source 3x;
  test_designer_export_contract.py imports designer_console). So the enricher under-detects; these are kept
  here as evidence, not hand-written into cards.

Pattern in the misses: almost all are (a) `tests/run-bridge-tests.sh` running a script by path (`bash tools/_tNNN…`,
`python3 "$ROOT/tests/…"`, `node tools/…`), (b) teeth/CDP scripts that read `src/aef-workflow-designer.html`, and
(c) Python imports by module name (`designer_console`). Edge type names are already mixed in the committed cards
(`reads`/`read_by`, `calls`/`called_by`): a separate issue.

## 154 edges (card location, direction, target, type as the old rewrite named it)

| card | direction | target | type |
|---|---|---|---|
| `src/aef-workflow-designer.html` | depended_by | `tests/t884-instance-overlay-state.test.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tests/t893-authority-marker-state.test.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tests/test_t961_designer_validate_reach.py` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tests/test_t962_findings_on_map.py` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t573-emits-panel-shape-cdp.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t573-one-vocabulary-teeth.py` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t818-probe-controls.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t821-census-controls.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t821-fault-surface-cdp.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t821-swallowed-failure-census.py` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t826-kind-rule-axes-teeth.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t836-census-empty-split-controls.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t884-instance-overlay-cdp.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t886-writer-mutation.py` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t889-authority-first-class-cdp.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t889-authority-on-the-element-teeth.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t890-lanemeta-guard-teeth.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t892-lane-default-cdp.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t893-authority-marker-shots.mjs` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t904-denominator-comment-blindness-teeth.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t907-parity-comment-teeth.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t910-lanemeta-teeth.sh` | reads |
| `src/aef-workflow-designer.html` | depended_by | `tools/_t911-kind-badge-verify-cdp.mjs` | reads |
| `tests/run-bridge-tests.sh` | depended_by | `tools/_t813-suite-age.py` | calls |
| `tests/run-bridge-tests.sh` | depended_by | `tools/project-audit.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `scripts/session-start-alerts.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/.run-history.tsv` | reads |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_boundary_inventory_unclassified.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_gallery_instances_api.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_session_start_alerts.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t1006_ledger_quorum.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t1008_catch_no_deadend.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t1008_kit_calibration_gate.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t1050_runme_alerts.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t1055_runme_launcher.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t955_validate_endpoint.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t961_designer_validate_reach.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t962_findings_on_map.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t973_save_findings.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t974_authoring_kit.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t983_review_loop_kit.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tests/test_t984_learning_ledger.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_edge-straighten-verify-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_endpoint-overlap-verify-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_gallery-claim-verify.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_gallery-list-verify.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_gallery-registry-verify.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_horizontal-spacing-verify-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_saveproject-verify-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_selection-align-verify-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1005-drift-target-clause-scoped.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1017-uid-count-teeth.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1024-machine-id-not-tracked.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1025-fabric-impact-teeth.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1027-note-promote-teeth.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1028-note-resolve-teeth.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1047-session-start-alerts-gate.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t1048-gallery-thumbs.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t263-save-target-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t301-id-stem-invariant.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t301-known-divergences.txt` | reads |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t3746-allowlisted-writes-fixture.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t467-arc-tag-source-of-truth.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t573-emits-panel-shape-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t598-source-marker.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t602-documentation-roundtrip.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t603-multiprocess-import.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t604-cdp-attach-race.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t611-review-card-steps.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t614-budget-threshold-drift.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t618-determinism-roundtrip-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t628-g020-remedy-reachable.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t629-g067-remedy-reachable.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t630-p011-stdin-swallow.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t631-tier0-approval-reachable.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t632-read-only-misclassification.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t633-shared-tmp-sinks.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t634-guard-verdict-reaches-caller.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t636-prose-verbs-vetoed-by-their-own-text.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t637-inception-coverage.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t638-commit-exemption-is-clause-scoped.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t639-drift-gate-reads-fixtures.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t644-ask-imports-survive-a-wrong-project-root.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t646-timeline-prose-is-escaped-before-it-is-trusted.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t649-completing-with-uncommitted-work-warns.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t651-stray-root-files-are-caught.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t654-archiving-a-partial-complete-task-must-null-its-horizon.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t654-watchdog-detections-must-be-surfaced.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t656-review-queue-splits-judgement-from-the-status-flip.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t658-p011-must-distinguish-killed-from-failed.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t659-retention-sweep-must-not-be-agent-staged.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t661-mutation-count-is-a-floor.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t674-ctl012-comment-fence.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t675-budget-read-fence.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t682-boundary-inventory.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t683-save-containment-verify.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t684-mutation-control.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t687-hook-function-check.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t688-divergence-drain-baseline.txt` | reads |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t688-divergence-drain-ratchet.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t739-defer-is-not-a-decision.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t767-ownership-correspondence.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t806-corpus-sweep-guard-controls.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t808-version-parity.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t809-census-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t809-frozen-meta-census.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t810-unreachable-values-census.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t812-adoption-predicate-controls.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t813-history-trap-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t813-suite-age.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t815-witness-guard-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t815-witness-ordering-guard.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t816-abbr-dup-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t817-wiring-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t818-probe-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t821-census-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t821-fault-surface-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t821-swallowed-failure-census.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t830-correlation-gate-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t830-correlation-gate.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t833-ctl029-partial-complete-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t836-census-empty-split-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t841-scoring-spec-controls.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t842-commit-exemption-spelling-regression.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t843-absence-gate-integration.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t843-absence-gate-tests.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t845-control-recogniser-tests.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t848-realization-check-tests.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t849-budget-zero-token-tests.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t886-writer-mutation.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t892-lane-default-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t911-kind-badge-verify-cdp.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t931-delegate-owner-follows-criteria.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t936-bare-import-gate-teeth.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t943-heading-states.sh` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t949-backfill-related-tasks.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t949-triage-completeness.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/_t958-boundary-row-teeth.py` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/gen-rendered-thumbs.mjs` | calls |
| `tests/run-bridge-tests.sh` | depends_on | `tools/learning-ledger.py` | calls |
| `tests/test_designer_export_contract.py` | depends_on | `tests/designer_console.py` | calls |
| `tests/test_editor_bridge_meta_parity.py` | depended_by | `tools/_t907-parity-comment-teeth.sh` | calls |
| `tests/test_editor_bridge_structured_parity.py` | depended_by | `tools/_t573-one-vocabulary-teeth.py` | calls |
| `tests/test_finding_anchorability.py` | depended_by | `tools/_t820-axes-controls.sh` | calls |
| `tests/test_finding_anchorability.py` | depended_by | `tools/_t826-kind-rule-axes-teeth.sh` | calls |
| `tests/test_rule_dialect_axis.py` | depended_by | `tools/_t820-axes-controls.sh` | calls |
| `tests/test_rule_dialect_axis.py` | depended_by | `tools/build-authoring-kit.py` | calls |
| `tests/test_rule_form_parity.py` | depended_by | `tools/_t820-axes-controls.sh` | calls |
| `tools/validate-workflow.py` | depended_by | `tools/_t682-boundary-inventory.py` | calls |
| `tools/validate-workflow.py` | depended_by | `tools/_t826-kind-rule-axes-teeth.sh` | calls |
| `tools/validate-workflow.py` | depended_by | `tools/_t889-authority-on-the-element-teeth.sh` | calls |
| `tools/validate-workflow.py` | depended_by | `tools/_t902-yaml-meta-authority-teeth.sh` | calls |
| `tools/yaml-to-bpmn.py` | depended_by | `tools/_t826-kind-rule-axes-teeth.sh` | calls |
| `tools/yaml-to-bpmn.py` | depended_by | `tools/mcp-designer-server.py` | calls |
