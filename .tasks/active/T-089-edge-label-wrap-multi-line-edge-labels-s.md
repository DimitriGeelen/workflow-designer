---
id: T-089
name: "Edge-label wrap: multi-line edge labels shrink collision footprint"
description: >
  Long edge labels (31 of 136 corpus labels exceed 18 chars, max 48) render single-line at full width and dominate T-082's 28 residual collisions in dense corridors. Wrap long names to 2 lines via tspans; placement pass syncs tspan x and measures the multi-line bbox.

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
created: 2026-07-04T22:19:37Z
last_update: 2026-07-04T22:29:35Z
date_finished: 2026-07-04T22:28:59Z
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

# T-089: Edge-label wrap: multi-line edge labels shrink collision footprint

## Context

Edge labels are the last label class rendered single-line at full width (lane labels got a fit ladder in T-084, node labels in T-087). Corpus survey: 136 edge labels, 31 exceed 18 chars, longest 48 chars (~290px at 10px mono). T-082's measured placement pass cut collisions 141→28 but its own decision notes say the residue sits in "intrinsically over-dense corridors" where drift can't help — the label is simply too wide for the corridor. Wrapping long names to 2 lines roughly halves the footprint of the worst offenders. Design: render names over a threshold as `<text>` + 2 `<tspan>`s (word-wrapped, balanced); `adjustEdgeLabelPlacements()` (src line ~2314) already measures via `getBBox` on the text element, which covers tspans — it only needs to sync each tspan's `x` when it moves the text. Halo rect already follows the measured bbox. Render-only: serialization untouched.

## Acceptance Criteria

### Agent
- [x] Wrap-on-contest: labels render single-line by default; only when the placement pass finds no clean spot AND the name is long (>20 chars) and breakable does it retry with a 2-balanced-line wrap (tspans under one `text[data-el]`), keeping the wrap only when it scores STRICTLY better
      Evidence: wrap block inside `adjustEdgeLabelPlacements()` after the single-line candidate search; renderEdges untouched except comment. Design evolved from AC-as-filed (global wrap at threshold): global wrap MEASURED WORSE — 28 -> 32 corpus collisions (verification-gate 9 -> 14) because the taller block crosses more segments in tight corridors than its halved width saves. Recorded in Decisions.
- [x] `adjustEdgeLabelPlacements()` moves multi-line labels as a unit: tspan `x` synced with the text `x` on every candidate application and final placement; measured bbox covers both lines (halo hugs the full 2-line block)
      Evidence: `apply()` helper sets text x/y/anchor + every tspan x; sweep: 0 x-shear across corpus, 0 halo misses (halo contains measured bbox for all labels incl. 3 wrapped).
- [x] Corpus collision sweep (same browser-side measure as T-082) run before and after: total corpus-wide edge-label collisions strictly decreases from the re-measured baseline
      Evidence: baseline re-measured 28 (matches T-082 record); after wrap-on-contest 25. Per-map: verification-gate 9->8, error-escalation-ladder 8->7, task-gate 5->4, others unchanged. 3 labels wrapped (e_10 verification-gate "all verify/cmds exit 0", e_15 error-escalation-ladder "worth codifying/-> Level D", e_09 task-gate "started-work +/real ACs").
- [x] No wrapped label overflows: sweep confirms every wrapped edge label's lines are non-empty and no phantom empty tspans exist (T-087's empty-line bug class)
      Evidence: sweep counters emptySpans=0, shear=0 across all 24 maps.
- [x] Serialization untouched: editor XML round-trip STABLE on context-memory + control maps; `git diff src/` touches no buildBpmnXml/parseBpmnXml/aefExtensionXml paths
      Evidence: parse->render->build STABLE x2 cycles on 6 maps (context-memory, verification-gate, error-escalation-ladder, task-gate, task-lifecycle, tier0-escalation); git diff src/ has 0 lines matching those symbols.
- [x] All suites green: bridge tests, validator tests, editor-bridge parity, corpus geometry sweep; gallery copy synced (`diff -q` clean)
      Evidence: bridge 31/31, validator 34/34, structured parity OK, geometry sweep 24 clean, diff -q clean.

### Human
- [ ] [REVIEW] The 3 wrapped edge labels read cleanly on the live gallery and nothing else regressed
  **Steps:**
  1. Open http://192.168.10.107:8834/ and view the task-gate map — "started-work + / real ACs" should be 2 centered lines with a halo covering both, clear of its line
  2. View error-escalation-ladder — "worth codifying / -> Level D" likewise
  3. View verification-gate — "all verify / cmds exit 0" sits in the known over-dense mid-chain; judge whether the 2-line form reads better than the old single line did (both collide there; the corridor itself is documented T-082 residue)
  4. Skim context-memory for regressions — its labels are intentionally NOT wrapped (wrap only fires where it measures strictly better)
  **Expected:** Wrapped labels are 2 compact lines, halo hugs both; no previously-clean label moved or now collides
  **If not:** Note which map + which label; screenshot the spot

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

out=$(grep -c 'data-el' src/aef-workflow-designer.html); test "$out" -ge 3
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "OK:"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24"
diff -q src/aef-workflow-designer.html build/gallery/designer.html

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

## Recommendation

**Recommendation:** GO
**Rationale:** Corpus edge-label collisions strictly decreased 28 -> 25 with only 3 labels wrapped and zero movement of previously-clean labels — the wrap fires only where it measures strictly better. The rejected global-wrap variant was caught by the same sweep before shipping (28 -> 32), so the shipped design is the evidence-backed one.
**Evidence:**
- Collision sweep (T-082 measure, all 24 maps): baseline 28 -> 25; verification-gate 9->8, error-escalation-ladder 8->7, task-gate 5->4
- Wrap integrity: 0 empty tspans, 0 x-shear, 0 halo misses corpus-wide
- XML round-trip STABLE x2 cycles on 6 maps; git diff src/ touches no serialization paths
- Suites: bridge 31/31, validator 34/34, parity OK, geometry 24 clean, gallery synced
- Screenshots read: .playwright-mcp/t089-taskgate-wrap.png, t089-verifgate-wrap.png

## Decisions

### 2026-07-05 — Wrap-on-contest, not global wrap-at-threshold
- **Chose:** Wrap an edge label to 2 lines only inside the placement pass, only when the single-line candidate search still has collisions, and keep the wrap only when it scores strictly better. Ties and losses undo the wrap.
- **Why:** Measured, not assumed: a global wrap of all 24 labels >20 chars moved corpus collisions 28 -> 32 (verification-gate 9 -> 14) — the 2-line block's extra 11px height crosses more segments/labels in tight corridors than its halved width saves. Wrap-on-contest wraps only 3 labels and lands 28 -> 25 with zero regressions on previously-clean labels.
- **Rejected:** (a) Global wrap at threshold — measured worse, above. (b) Wrapping in renderEdges with the pass just measuring — same thing structurally; the decision belongs where the contest evidence lives. (c) 3-line wraps — no remaining hit would benefit; the residue is short labels ("defer", "1st occurrence") in intrinsically dense corridors.

## Visual Verification

Screenshots in .playwright-mcp/ (element capture via viewBox framing, read and inspected):
- t089-taskgate-wrap.png — "started-work + / real ACs" as 2 centered lines above its run, halo covering both, clear of line and corner
- t089-verifgate-wrap.png — "all verify / cmds exit 0" in the documented over-dense mid-chain: strictly better score than its single-line baseline (which also collided, sc=2), corridor itself remains T-082-documented residue (gateway node-labels overlap there pre-existing)

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T22:19:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-089-edge-label-wrap-multi-line-edge-labels-s.md
- **Context:** Initial task creation

### 2026-07-04T22:28:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
