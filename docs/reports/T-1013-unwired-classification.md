# T-1013: the 93 tools the unwired-guard ratchet reports as new

**Date:** 2026-10-04. **Input:** the `+` entries of `python3 tools/_t451-unwired-guard-census.py --ratchet`, which lists tools with no live caller that are not in `tools/unwired-guard-baseline.txt` (dated 2026-08-25). **Method:** read each header, grep the task files that name it, classify, and run every WIRE candidate once (`timeout 300`, stdin closed).

**Counts:** WIRE 60 · BASELINE 28 · DELETE 0 · UNSURE 5

No DELETE: every tool still names a live subject. Five were superseded in purpose, and those are noted in their rows.

## WIRE candidates that FAIL today (16 of 60)

Wiring these as-is turns the suite red. Each failure is its own bug, never a reason to baseline the tool.

| Tool | Exit | Last line |
|---|---|---|
| `_norec-verify.py` | 1 | examined 1031 task file(s) under .tasks/active + .tasks/completed  ·  75 with pending Human ACs  ·  0 agent ABSTAIN (declined to recommend, explicit |
| `_t628-g020-remedy-reachable.sh` | 1 | === 5 passed, 6 failed === |
| `_t629-g067-remedy-reachable.sh` | 1 | === 7 passed, 3 failed === |
| `_t631-tier0-approval-reachable.sh` | 1 | === 4 passed, 2 failed === |
| `_t632-read-only-misclassification.sh` | 3 | COULD-NOT-MEASURE: could not build the pre-fix copy — nothing below has teeth. |
| `_t633-shared-tmp-sinks.sh` | 1 | === 6 passed, 2 failed === |
| `_t634-guard-verdict-reaches-caller.sh` | 1 | === 4 passed, 3 failed === |
| `_t636-prose-verbs-vetoed-by-their-own-text.sh` | 1 | === 13 passed, 2 failed === |
| `_t637-inception-coverage.sh` | 1 | === 7 passed, 1 failed === |
| `_t638-commit-exemption-is-clause-scoped.sh` | 3 | COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source. |
| `_t639-drift-gate-reads-fixtures.sh` | 3 | COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source. |
| `_t650-an-alias-is-the-command-it-aliases.sh` | 1 | === 10 passed, 6 failed === |
| `_t654-watchdog-detections-must-be-surfaced.sh` | 3 | COULD-NOT-MEASURE: Check 1b block not found in audit.sh |
| `_t662-null-focus-commit-path-must-be-discoverable.sh` | 1 | === 4 passed, 5 failed === |
| `_t688-divergence-drain-ratchet.py` | 1 | [RED] DRAIN RATCHET BROKEN: 54 undrained upstream fixes, baseline 46. 8 divergence(s) were added without any being delivered. Mark deliveries with `de |
| `_t932-boundary-agreement.sh` | 1 | stating precisely: they agree on what to look at, and differ on a few verdicts. |

**The pattern: 12 of these are framework-hook teeth from T-628 to T-662** (`_t628`, 629, 631, 632, 633, 634, 636, 638, 639, 650, `_t654-watchdog`, 662). Each asserts a fix 832 made in its vendored hooks. Four exit 3 (COULD-NOT-MEASURE) because the code their mutation targets is gone, for example "T-628 exemption not found" and "Check 1b block not found in audit.sh". Most likely the 1.7.740 re-vendor erased those local fixes. That is T-1020's class of silent loss, which the T-1020 census missed because these teeth were never wired: a fix lost under an unwired guard leaves no red anywhere. It needs a census of its own, one per teeth script: is the fix (a) adopted upstream in another form, so retarget the teeth; (b) lost, so restore it under its own task; or (c) obsolete?

The other failures are findings about the live state, not tool breakage:
- `_norec-verify.py`: 8 tasks awaiting Human review carry no Recommendation verdict.
- `_t688`: the divergence register holds 54 undrained upstream fixes against a baseline of 46.
- `_t932`: the two encodings of the delegation boundary still disagree on some verdicts (G-052).

## UNSURE (5)

- `_t420-rail-attribution-gate.py`: NOT a bridge leg: a PreToolUse HOOK. It was registered in .claude/settings.json until the 1.7.740 settings rewrite committed in 6e0747c3 (T-1022) dropped it. Re-register as a hook, or record the retirement?
- `_t596_arc0_check.py`: reached at run time via tools/_t596-arc0-exit-gate.sh (CHECK="tools/_t596_arc0_check.py"); the census does not follow variable-held paths. Fix the census or baseline?
- `_t597_arc0_clauses.py`: reached via _t596-arc0-exit-gate.sh (CLAUSE_CHECK=...); same census blind spot as _t596
- `_t734_absence_guard.py`: library whose header says every absence claim goes through it, yet NOTHING imports it; --self-test is green (11/11 live, 6 red under poison). Wire the self-test, or find out why no caller adopted it?
- `_t770-delegation-boundary.py`: imported at run time by live tools (_t931-ownership.py, _t932, _t872); the census misses module-name imports. Fix the census or baseline?

## Other findings

- **The 1.7.740 settings rewrite dropped both project hooks.** `.claude/settings.json` before 6e0747c3 registered `tools/_t420-rail-attribution-gate.py` (PreToolUse) and `tools/hooks/warn-uncontrolled-absence.sh`. The current file registers neither. The copies survive only in `.claude/settings.json.bak` and `.pre-t857`.
- **A census blind spot.** Tools reached through `VAR="tools/x.py"` or a Python import by module name count as uncalled (`_t596`, `_t597`, `_t770`). Baselining them hides the blind spot; fixing the census closure removes these false findings.
- **Residue from running the tools.** `_t687` rewrites `.context/working/.t687-function-baseline.json`, which already had uncommitted changes before this run, so its prior content could not be restored. `_t911` overwrote `.playwright-mcp/t911-panel-kind-select.png`, which was restored with `git checkout`. If either is wired, it needs a redirect.

## All 93

| Tool | Class | Reason | Tasks referencing it | WIRE: exit today, last line |
|---|---|---|---|---|
| `_gallery-claim-verify.py` | WIRE | stdlib regression test of gallery-serve /api/save claim path (temp repo, ephemeral port) | T-228,T-230,T-235,T-327,T-492 | 0 · 11/11 checks passed |
| `_gallery-list-verify.py` | WIRE | regression test of /api/list (temp repo, real server) | T-143,T-226,T-227,T-228,T-229,T-230,T-232,T-235,T-327,T-683,T-806 | 0 · 22/22 checks passed |
| `_gallery-registry-verify.py` | WIRE | regression test of the ghost registry twin | T-227,T-228,T-229,T-230,T-232,T-235,T-327,T-366 | 0 · 17/17 checks passed |
| `_norec-verify.py` | WIRE | standing review-queue guard: every task with unchecked Human ACs carries a Recommendation verdict | T-209,T-228,T-236,T-341,T-345,T-440,T-450,T-451,T-454,T-455,T-470 | 1 · examined 1031 task file(s) under .tasks/active + .tasks/completed  ·  75 with pending Human ACs  ·  0 agent AB |
| `_procasfit-orchestrate.sh` | BASELINE | orchestration script for procAsFit rounds; not a check | - |  |
| `_t1000-install-hook.sh` | BASELINE | installer for the re-vendor pre-commit line; its --check is called by _t1000-revendor-gate.sh | T-1000,T-1009 |  |
| `_t1005-drift-target-clause-scoped.py` | WIRE | behavioural probe of the drift-gate target (T-639 re-applied, T-1023); named in the divergence register as the guard | T-1023 | 0 · drift target: 18/18 |
| `_t1006-lesson-evidence.sh` | BASELINE | per-lesson manual evidence re-run; needs build/ partner notes that are never committed | - |  |
| `_t420-rail-attribution-gate.py` | UNSURE | NOT a bridge leg: a PreToolUse HOOK. It was registered in .claude/settings.json until the 1.7.740 settings rewrite committed in 6e0747c3 (T-1022) dropped it. Re-register as a hook, or record the retirement? | T-420,T-426,T-492,T-493,T-494,T-495,T-496,T-773 |  |
| `_t440-drive-empty.sh` | BASELINE | execution half of a one-off zero-population census (T-440) | T-440,T-447,T-450,T-806 |  |
| `_t440-zero-population-census.py` | BASELINE | one-off census answering T-440 | T-440 |  |
| `_t467-arc-tag-source-of-truth.py` | WIRE | teeth for fw arc tag (T-467/T-679); named in the divergence register as the guard | T-467,T-670,T-679,T-1005 | 0 · is a no-op, reassignment (incl. legacy-tag-only and multi-tag) is refused, and task bodies are left alone. |
| `_t573-emits-panel-shape-cdp.mjs` | WIRE | CDP regression: the Emits panel authors the ratified structured shape | T-573 | 0 · 8/8 T-573 legs passed |
| `_t596_arc0_check.py` | UNSURE | reached at run time via tools/_t596-arc0-exit-gate.sh (CHECK="tools/_t596_arc0_check.py"); the census does not follow variable-held paths. Fix the census or baseline? | - |  |
| `_t597_arc0_clauses.py` | UNSURE | reached via _t596-arc0-exit-gate.sh (CLAUSE_CHECK=...); same census blind spot as _t596 | - |  |
| `_t598-source-marker.py` | WIRE | static assertion: the source-end marker points forward (orient="auto") | T-598 | 0 · 9/9 T-598 source-marker legs passed |
| `_t602-documentation-roundtrip.mjs` | WIRE | CDP regression: bpmn:documentation content survives open -> save | T-602,T-603,T-605 | 0 · PASS — 6 leg(s) |
| `_t603-multiprocess-import.mjs` | WIRE | CDP regression: multi-process documents keep content, loss is reported | T-603,T-604 | 0 · PASS — 6 leg(s) |
| `_t604-cdp-attach-race.mjs` | WIRE | scan: no CDP driver hand-rolls the page-target attach race | T-604 | 0 · PASS — 5 leg(s) |
| `_t611-review-card-steps.py` | WIRE | every unchecked [REVIEW] criterion renders its Steps block | T-611 | 0 ·   OK — every unchecked criterion renders its instructions. |
| `_t612-operator-review-reachable.py` | BASELINE | one-off reachability check of the T-589 review build | T-612 |  |
| `_t614-budget-threshold-drift.py` | WIRE | CLAUDE.md's budget ladder matches budget-gate.sh | T-614 | 0 ·   OK — every percentage and token figure in the rule text is one the gate computes |
| `_t618-determinism-census.py` | BASELINE | census that answered T-618 | T-618 |  |
| `_t618-determinism-roundtrip-cdp.mjs` | WIRE | CDP regression: an authored determinism value survives a real save | T-618 | 0 ·   OK — 9 authored value(s) across 1 fixture(s) round-trip unchanged. |
| `_t627-undecided-defer.py` | BASELINE | surfaces undecided inceptions for the operator (a report, exit code is not a verdict); its teeth _t637 are the guard | T-627,T-637 |  |
| `_t628-g020-remedy-reachable.sh` | WIRE | teeth: every remedy G-020 prints is reachable from the blocked state | T-628,T-629,T-630,T-631 | 1 · === 5 passed, 6 failed === |
| `_t629-g067-remedy-reachable.sh` | WIRE | teeth: G-067's printed remedies are reachable | T-629,T-630,T-631 | 1 · === 7 passed, 3 failed === |
| `_t630-p011-stdin-swallow.sh` | WIRE | teeth: P-011 does not count commands it never ran | T-630,T-631,T-635,T-1005 | 0 · === 11 passed, 0 failed === |
| `_t631-tier0-approval-reachable.sh` | WIRE | teeth: the Tier-0 approval route is reachable while Tier 0 blocks | T-631,T-633 | 1 · === 4 passed, 2 failed === |
| `_t632-read-only-misclassification.sh` | WIRE | teeth: read-only commands are not refused by the active-task gate | T-632,T-636 | 3 · COULD-NOT-MEASURE: could not build the pre-fix copy — nothing below has teeth. |
| `_t633-shared-tmp-sinks.sh` | WIRE | teeth: no shared /tmp sinks in verification paths | T-633 | 1 · === 6 passed, 2 failed === |
| `_t634-guard-verdict-reaches-caller.sh` | WIRE | teeth: P-011's guards actually stop a completion | T-634,T-635 | 1 · === 4 passed, 3 failed === |
| `_t636-prose-verbs-vetoed-by-their-own-text.sh` | WIRE | teeth: fw note/prose verbs are not vetoed by their own text | T-636 | 1 · === 13 passed, 2 failed === |
| `_t637-inception-coverage.sh` | WIRE | teeth: the undecided-inception population reaches a reader | T-637 | 1 · === 7 passed, 1 failed === |
| `_t638-commit-exemption-is-clause-scoped.sh` | WIRE | teeth: the commit exemption admits a commit, not a mention | T-638 | 3 · COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source. |
| `_t639-drift-gate-reads-fixtures.sh` | WIRE | teeth: the drift gate ignores task ids in quoted fixtures (pre-1.7.740 form; _t1005 is its 1.7.740 replacement) | T-639,T-641 | 3 · COULD-NOT-MEASURE: could not derive the pre-fix mutant from live source. |
| `_t644-ask-imports-survive-a-wrong-project-root.sh` | WIRE | teeth: lib/ask.py reaches its imports in a vendored install | T-644 | 0 · === 5/5 passed === |
| `_t646-timeline-prose-is-escaped-before-it-is-trusted.sh` | WIRE | teeth (security): linkify_tasks escapes prose before Markup() | T-646 | 0 · === 8 passed, 0 failed === |
| `_t649-completing-with-uncommitted-work-warns.sh` | WIRE | teeth: completing with uncommitted work warns | T-649 | 0 · === 8 passed, 0 failed === |
| `_t650-an-alias-is-the-command-it-aliases.sh` | WIRE | teeth: an alias is admitted exactly when its target is | T-650,T-652 | 1 · === 10 passed, 6 failed === |
| `_t651-stray-root-files-are-caught.sh` | WIRE | teeth: the audit catches zero-byte redirect debris at the root | T-651 | 0 · === 5 passed, 0 failed === |
| `_t654-archiving-a-partial-complete-task-must-null-its-horizon.sh` | WIRE | teeth: an archived task does not keep horizon: now | T-654,T-661,T-1005 | 0 · === 7 passed, 0 failed === |
| `_t654-watchdog-detections-must-be-surfaced.sh` | WIRE | teeth: the T-522 watchdog detection is surfaced by the audit | T-654 | 3 · COULD-NOT-MEASURE: Check 1b block not found in audit.sh |
| `_t655-review-queue-ac-counts.py` | BASELINE | asserts AC counts of specific tasks at one point in time (snapshot) | T-655 |  |
| `_t656-review-queue-splits-judgement-from-the-status-flip.sh` | WIRE | teeth: D2 splits judgement from the status flip | T-656,T-661 | 0 · === 8 passed, 0 failed === |
| `_t658-p011-must-distinguish-killed-from-failed.sh` | WIRE | teeth: the P-011 runner distinguishes killed from failed | T-658,T-661,T-1005 | 0 · === 11 passed, 0 failed === |
| `_t659-retention-sweep-must-not-be-agent-staged.sh` | WIRE | teeth: retention-sweep deletions are not swept into agent commits | T-659,T-661 | 0 · === 6 passed, 0 failed === |
| `_t661-mutation-count-is-a-floor.sh` | WIRE | teeth: the shared mutation-completeness assertion is a floor | T-661 | 0 · === 7 passed, 0 failed === |
| `_t662-null-focus-commit-path-must-be-discoverable.sh` | WIRE | teeth: the null-focus commit path is named in the block message | T-662 | 1 · === 4 passed, 5 failed === |
| `_t673-fabric-cards.py` | BASELINE | generator that carded the watch set (T-673); not a check | T-673 |  |
| `_t674-ctl012-comment-fence.py` | WIRE | fence: CTL-012 ignores ACs in HTML comments and still catches real ones | T-674,T-678 | 0 · and the Human / DEFERRED / missing-decide behaviours are intact. |
| `_t675-budget-read-fence.py` | WIRE | fence: every arm of the budget safe-read | T-675,T-1005 | 0 · fails open while recording that nobody measured it. |
| `_t680-aef-reachability.py` | BASELINE | probe of the AEF seam at one moment (T-680) | T-680 |  |
| `_t683-save-containment-verify.py` | WIRE | security regression: /api/save write containment | T-681,T-683,T-684,T-689 | 0 · 8/8 passed |
| `_t684-mutation-control.py` | WIRE | mutation control for the /api/save containment fence | T-681,T-684,T-689 | 0 ·   reported for completeness, excluded from this verdict.) |
| `_t687-hook-function-check.py` | WIRE | function check for stdin-consuming PostToolUse hooks (writes .context/working/.t687-function-baseline.json) | T-687 | 0 · [OK] only -4909 fires since baseline (< 20) — inconclusive, holding |
| `_t688-divergence-drain-ratchet.py` | WIRE | ratchet: undrained upstream fixes in the vendor-divergence register may not grow | T-688 | 1 · [RED] DRAIN RATCHET BROKEN: 54 undrained upstream fixes, baseline 46. 8 divergence(s) were added without any b |
| `_t694-bvp-distinguishability.py` | BASELINE | measurement behind docs/reports/T-694 (no pass/fail claim) | T-694,T-695 |  |
| `_t734_absence_guard.py` | UNSURE | library whose header says every absence claim goes through it, yet NOTHING imports it; --self-test is green (11/11 live, 6 red under poison). Wire the self-test, or find out why no caller adopted it? | T-734 |  |
| `_t738-unrankable-task-census.py` | BASELINE | census + proposal generator (T-738) | T-681,T-738 |  |
| `_t739-defer-is-not-a-decision.py` | WIRE | reproduces from the live tree that a DEFER keeps an inception on the decisions surface | T-681,T-739 | 0 · PASS — no active inception is hidden from DECISIONS by a recorded non-terminal decision. |
| `_t767-ownership-correspondence.sh` | WIRE | negative control + standing measurement: ownership follows a real Human AC | T-767 | 0 · legs: 4 passed, 0 failed |
| `_t770-delegation-boundary.py` | UNSURE | imported at run time by live tools (_t931-ownership.py, _t932, _t872); the census misses module-name imports. Fix the census or baseline? | T-669,T-747,T-748,T-770,T-828,T-829,T-833,T-931,T-932,T-933 |  |
| `_t777-selection-eligibility-census.py` | BASELINE | census (T-777) | T-777,T-778,T-779,T-780,T-781 |  |
| `_t781-bvp-calibration-census.py` | BASELINE | RCA measurement (T-781) | T-781 |  |
| `_t783-human-ac-queue-extract.py` | BASELINE | read-only extract of the Human-AC queue (report) | T-783,T-804 |  |
| `_t784-endpoint-resolution-census.py` | BASELINE | census (T-784) | - |  |
| `_t806-corpus-sweep-guard-controls.py` | WIRE | regression: bake-clean-layout.py refuses unknown flags rather than rewriting the corpus | T-806 | 0 · controls: 9 pass, 0 fail |
| `_t808-version-parity.sh` | WIRE | standing property: APP_VERSION in src/ equals ./VERSION | T-808,T-819,T-824,T-987,T-994 | 0 · ok: APP_VERSION and VERSION agree (0.15.3) |
| `_t833-ctl029-partial-complete-controls.sh` | WIRE | controls: CTL-029 still catches what it should | T-681 | 0 · PASS=4 FAIL=0 |
| `_t836-census-empty-split-controls.sh` | WIRE | controls: the carrier-shape split measures | T-836 | 0 · controls: 8 pass, 0 fail |
| `_t841-scoring-spec-controls.sh` | WIRE | controls: each T-841 verification leg can fail | T-841 | 0 · # passed 13, failed 0 |
| `_t842-commit-exemption-spelling-regression.sh` | WIRE | regression pin: the commit exemption's spelling coverage | T-669,T-842 | 0 · # passed 17, failed 0, known-defects 5 |
| `_t843-absence-gate-integration.sh` | WIRE | integration: the absence close-gate fires and its named remedy clears it | T-843,T-844,T-845 | 0 · # passed 16, failed 0 |
| `_t843-absence-gate-tests.sh` | WIRE | tests for the uncontrolled-absence close gate | T-843,T-844,T-845 | 0 · # passed 12, failed 0 |
| `_t845-control-recogniser-tests.sh` | WIRE | tests for _t560's control recogniser | T-785,T-845 | 0 · # passed 16, failed 0 |
| `_t848-realization-check-tests.sh` | WIRE | tests for the realization-ledger checker | T-848 | 0 · # passed 9, failed 0 |
| `_t848-realization-check.py` | BASELINE | report generator; its behaviour is guarded by _t848-realization-check-tests.sh | T-848 |  |
| `_t849-budget-zero-token-tests.sh` | WIRE | teeth: the zero-token hole in checkpoint.sh's budget reader | T-849 | 0 · PASS 14 / FAIL 0 |
| `_t872-decision-docket.py` | BASELINE | docket generator for the operator (report) | T-872,T-933,T-937 |  |
| `_t884-live-proof-cdp.mjs` | BASELINE | live proof needing a running server and five arguments (PL-285: not a P-011 leg) | T-884,T-885 |  |
| `_t886-writer-mutation.py` | WIRE | mutation teeth for the round-trip guard (suppresses each writer attribute, expects red) | T-875,T-885,T-886,T-890,T-899,T-900 | 0 · every mutant killed: the document-level seam has teeth for 5 attribute(s) |
| `_t892-lane-default-cdp.mjs` | WIRE | CDP regression: the lane Authoring default never re-stamps nodes | T-892 | 0 · 5/5 legs passed; screenshots: node-after.png, node-before.png, panel-field.png |
| `_t911-kind-badge-verify-cdp.mjs` | WIRE | CDP regression: workflowMeta/@kind settable and visible (writes .playwright-mcp/t911-panel-kind-select.png) | T-911 | 0 · } |
| `_t922-prompt-integrity.sh` | BASELINE | run-specific check of one procAsFit orchestration | - |  |
| `_t932-boundary-agreement.sh` | WIRE | G-052's close condition: the two encodings of the delegation boundary agree | T-932,T-933 | 1 · stating precisely: they agree on what to look at, and differ on a few verdicts. |
| `_t969-post-bytes.sh` | BASELINE | delivery helper (post a file to a topic in sha-verified parts) | - |  |
| `_t970-evergreen-intake.py` | BASELINE | data intake (Evergreen corpus, iteration 0) | T-971 |  |
| `_t989-intake-evergreen.py` | BASELINE | data intake (Evergreen deliveries) | - |  |
| `_t989-measure-evergreen.py` | BASELINE | trial measurement instrument (produces numbers, not a verdict) | T-989,T-993 |  |
| `kit-publish.py` | BASELINE | delivery helper (post a released kit to a partner topic) | - |  |
| `mcp-designer-server.py` | BASELINE | a server, not a check; probed by tools/_t792-mcp-server-probe.py | T-792,T-795,T-796,T-802,T-806 |  |
| `operator-actions.sh` | BASELINE | operator command script (runme-style); never run by the agent | T-800 |  |
