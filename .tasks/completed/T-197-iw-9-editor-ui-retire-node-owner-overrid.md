---
id: T-197
name: "IW-9 editor UI: retire node-owner override field, derive owner from lane"
description: >
  Sibling of T-196 (which did the validator enforcement). The IW-9 v1.1 graduation removed the node-level owner override. 832 editor still OFFERS it: src/aef-workflow-designer.html:1531 FIELD_META.owner (hint literally says 'overrides lane'), wired into AEF_FIELDS for serviceTask/userTask/scriptTask/subProcess (1500-1507). This task: (1) remove/neutralize the node-level owner SELECT so users can no longer author the now-invalid override; ideally show owner READ-ONLY derived from the node's lane authority via the collapse map (sovereignty->human, initiative/authority->agent). (2) KEEP owner in editor metaKeys (7761) + bridge META_KEYS per O-2 for reverse-render laning (no change). (3) Update tests/test_designer_render.py (64/158/183/191) which currently assert the owner input renders with options ['','human','agent']. REQUIRES Playwright visual verification per CLAUDE.md (property panel UI change): screenshot the node property panel in relevant modes, confirm the owner override input is gone / shown derived, no regression. Explore scope map in T-196 episodic.

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
created: 2026-07-12T21:08:47Z
last_update: 2026-07-29T15:42:35Z
date_finished: 2026-07-18T07:40:17Z
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

# T-197: IW-9 editor UI: retire node-owner override field, derive owner from lane

## Context

Editor half of the IW-9 v1.1 graduation (T-189). The standard removed the
node-level `owner` override (owner is DERIVED from lane authority). T-196
enforced this in the validator; this task retires the override from the
authoring surface so users can no longer author the now-invalid field.

**Scope boundary (dist immutability, G-007):** `tests/test_designer_render.py`
is the *release render gate* — it resolves `VERSION` → `dist/…-<version>.html`
and asserts the owner dropdown renders. The released 0.2.0 dist legitimately
still carries owner (it shipped before IW-9 graduated); flipping that test here
would assert a falsehood about immutable bytes and cannot go green without a
VERSION bump (a release = `owner: human`). So this task changes `src/` + adds a
`src`-served regression guard; the release-gate SIG flip is handed to the
release task (see Decisions).

## Acceptance Criteria

### Agent
- [x] `owner` removed from all four `AEF_FIELDS` lists (serviceTask, userTask, scriptTask, subProcess) in `src/aef-workflow-designer.html` — no editable owner `<select>` is offered.
- [x] A collapse-map helper derives owner from the node's lane authority (sovereignty→human, initiative→agent, authority→agent, external/none→— none —); the property panel shows owner **read-only, derived from the lane** for task-like nodes, with the source authority visible.
- [x] `owner` retained in the editor `metaKeys` writer (line ~7761) — O-2 reverse-render laning preserved; `tests/test_editor_bridge_meta_parity.py` exits 0.
- [x] New `tests/test_designer_owner_derived.py` (src-served, Playwright): asserts `AEF_FIELDS.serviceTask` lacks `owner`, no `['','human','agent']` owner dropdown renders on node select, derived readout present; exits 0.
- [x] Zero regression on the JS↔Py seam guards (meta parity, field coverage, namespace, extension shape, structured parity) — all exit 0.

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
- [x] [REVIEW] Derived-owner readout reads clearly and no dead affordance remains
  **Steps:**
  1. Serve the source: `cd /opt/832-Workflow-designer && python3 -m http.server 8199 --directory src`
  2. Open `http://127.0.0.1:8199/aef-workflow-designer.html`
  3. Click the seed "Decompose" service-task node; look at the Extensions panel
  4. Change the node's Lane (Human/Framework/Agent) and watch the Owner readout
  **Expected:** Owner shows as a read-only value derived from the lane (Human lane → human, Agent/Framework → agent), with no editable owner dropdown anywhere in the panel; the readout updates when the lane changes.
  **If not:** Screenshot the panel and note whether the dropdown persists or the readout is stale/confusing.

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
out=$(python3 tests/test_designer_owner_derived.py 2>&1); echo "$out" | grep -q "PASS"
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_editor_bridge_field_coverage.py
python3 tests/test_editor_namespace_consistency.py
python3 tests/test_editor_extension_shape_consistency.py
python3 tests/test_editor_bridge_structured_parity.py
# owner must be gone from AEF_FIELDS (no quoted 'owner' field entry) but retained
# in the metaKeys writer (O-2). Match the quoted token so the explanatory comment
# prose ("node-level `owner` is NOT authorable") does not trip the check.
af=$(sed -n '/const AEF_FIELDS = {/,/^};/p' src/aef-workflow-designer.html); ! echo "$af" | grep -q "'owner'"
mk=$(sed -n "/const metaKeys = \[/,/\];/p" src/aef-workflow-designer.html); echo "$mk" | grep -q "'owner'"

## Recommendation

**Recommendation:** GO

**Rationale:** The editor half of the IW-9 v1.1 graduation is complete and
verified. The now-invalid node-level `owner` override is retired from the
authoring surface and replaced by a read-only readout derived from lane
authority — exactly the mapping-v1 §3 collapse the validator (T-196) already
enforces. The one Human AC is a taste check on the readout's clarity; all
structural behaviour is already agent-verified (below). No release coupling is
triggered — the immutable 0.2.0 dist and its render gate are untouched (that
flip is T-200, human-owned).

**Evidence:**
- All 5 Agent ACs checked; Verification gate 8/8 PASS (owner-derived guard +
  5 JS↔Py seam guards + AEF_FIELDS/metaKeys greps).
- Live Playwright: Owner readout re-derives on Lane change — human/sovereignty→
  `human`, framework/authority→`agent`, agent/initiative→`agent`; all read-only,
  no editable owner `<select>` (`docs/screenshots/t197-panel-dark-owner.png`).
- `owner` kept in metaKeys + bridge META_KEYS (O-2) — meta-parity green.
- Release gate `tests/test_designer_render.py` still PASS against 0.2.0 (proves
  decoupling; no immutable-bytes contradiction).

**To finalize:** review `docs/screenshots/t197-panel-dark-owner.png` (or run the
Human AC steps), check the `[REVIEW]` box, then
`cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-197 --status work-completed`.

## Visual Verification

Property panel of a selected serviceTask node (seed "Decompose problem"),
served from `src/` and driven headless via Playwright MCP.

- `docs/screenshots/t197-panel-dark-owner.png` — Extensions section scrolled to
  the Owner readout. Shows **"Owner · derived from lane (initiative)" → `agent`**
  as a read-only value box (no dropdown chevron, unlike the IO-type `<select>`s
  directly below it). No editable owner dropdown anywhere in the panel.
- `docs/screenshots/t197-panel-light.png` — top of the same panel (BMPN section:
  Name/Slug/Display ID/UID/Lane=agent), confirming layout is intact.

Lane-change behaviour verified live (readout re-derives on Lane select change):
  human lane (sovereignty) → `human`; framework (authority) → `agent`;
  agent (initiative) → `agent` — exactly the mapping-v1 §3 collapse. All three
  render read-only (no `<select>`). The editor is dark-theme only (no
  `prefers-color-scheme` / theme toggle in source), so dark is the single mode.

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

### 2026-07-17 — render-gate test flip deferred to the release
- **Chose:** Change `src/` + add a `src`-served regression guard (`tests/test_designer_owner_derived.py`). Leave `tests/test_designer_render.py` (the dist/release gate) unchanged.
- **Why:** That test resolves `VERSION` → `dist/…-<version>.html` and correctly guards the *released* 0.2.0 bytes, which legitimately still carry owner (built before IW-9). Flipping its owner expectations here would (a) assert a falsehood about an immutable artifact and (b) be un-greenable — a same-version dist rebuild is refused by the G-007 immutability guard, and a VERSION bump is a release (`owner: human`). The render-gate SIG must flip atomically with the release that rebuilds dist from the retired-owner src.
- **Rejected:** Rebuild dist under a new VERSION now (crosses into human-owned release authority — the standing directive delegates initiative, not authority). Re-point the render gate at `src/` (silently changes what a release gate guards).
- **Follow-up:** File a release task (owner: human) to bump VERSION, rebuild dist from IW-9 src, and flip `test_designer_render.py` SIG (drop owner from lines 64/158/183/191) in the same commit.

### 2026-07-17 — owner kept in metaKeys, dropped from AEF_FIELDS
- **Chose:** Remove `owner` from `AEF_FIELDS` (no authoring) but keep it in the editor `metaKeys` writer and bridge `META_KEYS`.
- **Why:** O-2 (ratified) — reverse-render laning may carry an imported `owner` as a lane hint; keeping it in the scalar metaKeys channel round-trips it without offering it for authoring. Forward-compile still derives owner from lane (conformance-safe subset).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-12T21:08:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-197-iw-9-editor-ui-retire-node-owner-overrid.md
- **Context:** Initial task creation

### 2026-07-18T07:32:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-18T07:40:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-894e3cec
- **Timestamp:** 2026-07-29T13:13:42Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 40
     - evidence: `af=$(sed -n '/const AEF_FIELDS = {/,/^};/p' src/aef-workflow-designer.html); ! echo "$af" | grep -q "'owner'"`
