---
id: T-098
name: "Edge channel separation setting: corridor channel pitch off/4/8px in settings"
description: >
  T-092 Phase B option 2: expose the T-097 corridor channel pitch (anchor spread + stub-rank channels for fan/join siblings) as a routing setting — off/0px, tight/4px, roomy/8px (default 8 = T-097 behaviour). Editor-local pref like straightening/attach mode; never stored in the document.

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
created: 2026-07-05T10:00:02Z
last_update: 2026-07-05T10:05:58Z
date_finished: 2026-07-05T10:05:20Z
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

# T-098: Edge channel separation setting: corridor channel pitch off/4/8px in settings

## Context

T-092 Phase B option 2 (operator "go phase B"). T-097 built the corridor channel mechanism (ordered anchor spread + per-rank stub channels for fan/join siblings) with a hard-coded 8px pitch; this task exposes the pitch as the survey's "edge channel separation" routing setting — off (0px, pre-T-097 converging look), tight (4px), roomy (8px, default = T-097 behaviour). Editor-local `routingPrefs` (localStorage `aefRoutingPrefs`), same seam discipline as attach mode/straightening: render-only, never in the document.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `routingPrefs.channelSep` (validated 0/4/8, default 8) drives BOTH the middle-mode sibling anchor spread pitch and the `channelExtra` stub-rank pitch via `channelPitch()`; `setChannelSep()` persists to `aefRoutingPrefs` and re-renders edges. Evidence: src/aef-workflow-designer.html (`setChannelSep`, `channelPitch`, spreadOffset spacing, channelExtra)
- [x] Settings modal Routing section has the "Channel separation" select (off / tight 4px / roomy 8px) with hint; synced in `syncSettingsUI()` (`set-channel-sep`); Reset-to-defaults calls `setChannelSep(8)`
- [x] Live behaviour verified on audit-process, no reload between switches: sep 8 → 1 overlap pair (T-097 result), sep 0 → 22 pairs (exact pre-T-097 converging baseline), sep 4 → 0 pairs, back to 8 → 1; localStorage `aefRoutingPrefs.channelSep` persisted
- [x] PD-044 holds: `buildBpmnXml(state)` byte-identical across the 8→0→4→8 switch sequence on the loaded map (geomStable: true)
- [x] Suites pass: bridge 31/31, validator 34/34, corpus geometry 24 clean, parity OK; build/gallery/designer.html identical copy
- [x] Screenshots taken and READ: `.playwright-mcp/t098-settings-channel-sep.png` (control renders in Routing section, default roomy), `t098-audit-sep-off.png` (branches converge on one line), `t098-audit-sep-roomy.png` (parallel channel bundle) — both modes as described, no visual regression

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
- [ ] [REVIEW] Channel separation control feels right on real maps
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/audit-process.bpmn
  2. Open Settings (gear) -> Routing -> Channel separation; switch off -> tight -> roomy
  **Expected:** off = branch arrows converge/overlap on one line (old look); tight/roomy = parallel channels with growing gaps; change applies immediately
  **If not:** Note which value misbehaves; screenshot the fan block

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

out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305)
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "OK:"
diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "set-channel-sep" src/aef-workflow-designer.html
grep -q "function setChannelSep" src/aef-workflow-designer.html

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

## Visual Verification

Screenshots taken via Playwright and READ:
- `.playwright-mcp/t098-settings-channel-sep.png` — settings Routing section, "Channel separation" select present, default roomy (8px)
- `.playwright-mcp/t098-audit-sep-off.png` — audit-process at off: branch arrows converge on single lines (pre-T-097 look restored)
- `.playwright-mcp/t098-audit-sep-roomy.png` — audit-process at roomy: ordered parallel channel bundles at fork and join

## Recommendation

**Recommendation:** GO
**Rationale:** Small, seam-safe setting exposing the T-097 corridor mechanism with an off switch that byte-exactly restores the old converging look; default preserves T-097 behaviour so nothing changes for reviewers who liked Phase B option 10.
**Evidence:**
- Live sweep on audit-process: sep 8 → 1 overlap pair, sep 0 → 22 (pre-T-097 baseline), sep 4 → 0; instant apply, no reload
- PD-044: geometry byte-stable across all switches; pref is localStorage-only, never in the document
- Suites green: bridge 31/31, validator 34/34, corpus geometry 24 clean, parity OK; gallery copy identical
- Screenshots READ (3, listed under Visual Verification)

## Updates

### 2026-07-05T10:00:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-098-edge-channel-separation-setting-corridor.md
- **Context:** Initial task creation

### 2026-07-05T10:05:20Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-074e6c54
- **Timestamp:** 2026-07-29T13:13:34Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#6 (Agent)** — Screenshots taken and READ: `.playwright-mcp/t098-settings-channel-sep.png` (control renders in Routing section, default roomy), `t098-audit-sep-off.png` (branches converge on one line), `t098-audit-s
  - **AC-verify-mismatch** (narrow, heuristic) — `path=playwright-mcp/t098-settings-channel-sep.png in: Screenshots taken and READ: `.playwright-mcp/t098-settings-channel-sep.png` (control renders in Routing section, default roomy), `t098-audit-sep-off.p`
