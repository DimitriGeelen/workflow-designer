---
id: T-308
name: "Bare catch-event neutral rendering when unbound (T-244 GO, path b)"
description: >
  Bare catch-event neutral rendering when unbound (T-244 GO, path b)

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
created: 2026-07-29T17:47:21Z
last_update: '2026-08-16T14:33:01Z'
date_finished: 2026-07-29T20:07:33Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:27Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 4
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=4 (body:cross-machine); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:01Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 4
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=4 (body:cross-machine); F-RECALL=2 (body:lightly-promoted); F2=0 
      (no-signal); F4=1 (prose:routing/geometry-incidental); F3=4 
      (prose:seam-fixture-or-pin); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:docs/reports/T-244-bare-catch-event-exploration.md,src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/bare-catch-event.bpmn,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-308: Bare catch-event neutral rendering when unbound (T-244 GO, path b)

## Context

Implements the **GO decision recorded on T-244** (operator, 2026-07-29T17:46:29Z), scoped to **path
(b)** — a rendering/property-panel branch, explicitly **NOT** a new node type. Full exploration and
pricing: `docs/reports/T-244-bare-catch-event-exploration.md`.

**What's wrong:** `REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch'`
(src/aef-workflow-designer.html:9347) is the fallback decode, so a bare `intermediateCatchEvent`
(no `aef:link`, no `aef:eventDef`) becomes a "← Handoff" node — label src:7783, link-catch glyph
src:5662, link property schema src:1784 — whose target fields can never bind. AEF's operator read
exactly this as a broken connector on a healthy map.

**Why path (b) is safe:** verified during exploration that `aefExtensionXml` emits `<aef:link>` only
when a binding field is non-empty, and `linkEventCatch` exports as `intermediateCatchEvent`
(src:8985) — so a bare catch event already round-trips byte-clean. This change must therefore alter
**zero exported bytes**: no schema change, no dialect change, nothing for AEF to ratify.

**The design constraint (IW-3, confidence 3):** a palette-created handoff node is *equally* unbound,
and the dialect has no carrier for authorial intent — "author placed a handoff, not yet bound" and
"bare imported catch event" serialize identically. So intent lives in **session state**: show the
handoff UI while the node is live in the editor this session, render neutral after a reload. A
persisted "intended handoff" marker is out of scope — it would be a dialect change, i.e. path (a).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] An unbound, non-session-authored catch event renders a neutral glyph and neutral type label (not "← Handoff"), and its property panel does not offer the dead link fields (workflowRef/name/targetWorkflow/linkId)
      — neutral BPMN double ring in `--text-faint` (src ~2969), panel type badge reads `intermediateEvent`, Extensions section replaced by an "Event kind" note + "← Make this a handoff" affordance. See **Decisions** for why the node's *own name* is not rewritten.
- [x] A palette-created `linkEventCatch` still shows the handoff UI for the duration of the authoring session, so binding stays discoverable; after reload it renders neutral (session-state intent, no persisted marker)
      — `sessionAuthoredLinks` Set, deliberately outside `state`; `createNodeAt` registers link-catch drops. Harness SESSION leg + screenshots `t308-palette-live.png` / `t308-palette-after-reload.png`.
- [x] A node that DOES carry a binding (`workflowRef`/`targetWorkflow`/`linkId`) is unaffected — glyph, label and property panel unchanged
      — uuid-bound and legacy-slug forms both verified; typed-catch (T-204 override) also unaffected. Screenshots `t308-node-bound-unchanged.png`, `t308-panel-bound-unchanged.png`.
- [x] Zero exported-byte change: for every corpus map, `buildBpmnXml(state)` is byte-identical before and after this change (no schema surface, nothing for AEF to ratify)
      — `tools/_t308-export-byte-identity-cdp.mjs fb4c21c` (the commit before T-308 touched `src/`): **24 maps, 24 identical, 0 drifted, 0 errors**. Also holds after using the "Make this a handoff" affordance (declaring intent writes nothing).
- [x] Regression test added that imports a bare `intermediateCatchEvent` fixture and asserts the neutral presentation plus the unchanged export bytes; wired into the bridge suite
      — `tests/fixtures/aef-bpmn/bare-catch-event.bpmn` (bare / uuid-bound / legacy-slug / typed-catch), `tools/_t308-bare-catch-render-cdp.mjs`, `tests/test_t308_bare_catch_render.py`, wired into `tests/run-bridge-tests.sh`. Six legs: MODEL/RENDER/PANEL/EXPORT/SESSION/BITE.
- [x] Bridge + validator + geometry suites green, failure-shape asserted not count-pinned (PL-061)

### Human
- [ ] [REVIEW] The neutral glyph reads as "an event of unspecified kind", not as a broken or missing node
  **Steps:**
  1. Open the designer at the Watchtower URL: `cd /opt/832-Workflow-designer && cat .context/working/watchtower.url` then browse to `<that URL>/designer/app`
  2. Import (or open) the bare-catch-event test fixture named in this task's Verification section
  3. Look at the bare catch event next to a real bound handoff node and a typed event
  **Expected:** the bare one reads as neutral/unspecified — clearly not an error state, clearly not a handoff
  **If not:** say which reading it gives instead (broken? missing? same as something else?) and the glyph will be revised
- [ ] [REVIEW] Placing a handoff from the palette still feels discoverable
  **Steps:**
  1. In the same designer, drag `← Handoff` from the palette onto the canvas
  2. Without binding it, check the node and its property panel
  3. Reload the page and look at the same node again
  **Expected:** while placing, the handoff affordance and target fields are present; after reload the *glyph* goes neutral **but the node keeps whatever name you gave it** — so a node you never renamed still reads "← Handoff" under a neutral ring. That is deliberate: the name is your text, and rewriting it would change exported bytes (see **Decisions**). Judge whether that combination reads as "meant to be a handoff, never bound" or just looks broken.
  **If not:** note which half feels wrong — the live affordance, the post-reload neutrality, or the neutral-ring/"← Handoff"-name combination


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
# --- T-308 checks ---
# The neutral-rendering branch and its session-intent carrier exist.
grep -q "function isBareCatchEvent" src/aef-workflow-designer.html
grep -q "const sessionAuthoredLinks = new Set()" src/aef-workflow-designer.html
# The intent Set must NEVER become document state — that would be path (a), a
# dialect change AEF has to ratify. Assert it is not written onto a node/state.
out=$(grep -c "aef\.sessionAuthored\|n\.sessionAuthored\|state\.sessionAuthoredLinks" src/aef-workflow-designer.html || true); test "$out" = "0"
# The bare branch is ordered BEFORE the link-event branch (else it never fires).
python3 -c "import sys; s=open('src/aef-workflow-designer.html').read(); a=s.index('} else if (isBareCatchEvent(n)) {'); b=s.index(\"} else if (n.type === 'linkEventThrow' || n.type === 'linkEventCatch') {\"); sys.exit(0 if a<b else 1)"
# Fixture + harness + suite wiring are present.
test -f tests/fixtures/aef-bpmn/bare-catch-event.bpmn
test -f tools/_t308-bare-catch-render-cdp.mjs
grep -q "test_t308_bare_catch_render.py" tests/run-bridge-tests.sh
# The behaviour leg itself (skips LOUDLY without chromium — never a silent green).
out=$(python3 tests/test_t308_bare_catch_render.py 2>&1); echo "$out" | grep -qE '"ok": true|^SKIP:'
# Zero export surface vs the PRE-CHANGE tree. The ref is pinned to fb4c21c (the
# commit before T-308 touched src/) on purpose: against HEAD this check compares
# the change with itself once committed and becomes a green that cannot go red —
# the PL-061 class defect found in T-307. Assert the SHAPE (no drift), not a map
# count, so a growing corpus does not break it.
out=$(node tools/_t308-export-byte-identity-cdp.mjs fb4c21c 2>&1); echo "$out" | grep -q '"drifted": 0'
# Suites green. Failure-SHAPE asserted, never a pinned total (PL-061) — both
# suites grow, and "44 passed" would go red on the next added leg.
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "0 failed"
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## Recommendation

**Recommendation:** GO

**Rationale:** Every agent-verifiable claim in this task was measured rather than asserted, and the
one property that would have made this a cross-project change — an export surface — was proven
absent across the whole corpus, not argued from the code. What remains for you is genuinely a taste
call the tooling cannot settle: whether the neutral ring *reads* as "unspecified kind" rather than
"broken", and whether a palette handoff still feels discoverable. Two things deserve your attention
rather than a rubber stamp: (1) an unbound node named "← Handoff" renders as a neutral ring **under
that name**, because rewriting authored text would change exported bytes — I judged that the honest
trade, but it is exactly the kind of call that should be yours; (2) the scope was held to the catch
side, so a bare `intermediateThrowEvent` still has the identical misread and is deliberately not
fixed here (see **Evolution**).

**Evidence:**
- Zero export surface: `tools/_t308-export-byte-identity-cdp.mjs fb4c21c` replays all corpus maps
  through the pre-change designer and the working tree — **24 maps, 24 byte-identical, 0 drifted,
  0 errors**. Using the "Make this a handoff" affordance also writes nothing (`<aef:link>` count
  unchanged, node still unbound).
- Regression leg wired into the bridge suite with six layers (MODEL/RENDER/PANEL/EXPORT/SESSION/
  BITE); the BITE leg gives the bare node a target and requires the handoff presentation to return,
  so the guard cannot pass on a hard-coded "always neutral".
- Suites: bridge **44 passed, 0 failed** (including the new leg), validator **34 passed, 0 failed**.
  P-011 gate: **11/11**.
- Node type is unchanged (`linkEventCatch`), so T-204/T-237 classification and the dialect are
  untouched — this is not the new-node-type path (a) that AEF would have to ratify.
- 8 element screenshots taken **and read** — `docs/screenshots/t308-*.png`, itemised under
  **Visual Verification**.

## Visual Verification

Playwright against an isolated sidecar (`tools/gallery-serve.py`, temp docroot) serving the
working-tree designer with `tests/fixtures/aef-bpmn/bare-catch-event.bpmn`. The designer has a
**single theme** and no density/contrast modes (one `:root` block, no `prefers-color-scheme`, no
`data-density`), so the mode matrix here is selection state and node class, not theme. Every file
below was READ, not merely captured:

- `t308-node-bare-neutral.png` — READ: the bare catch event draws BPMN's plain intermediate event
  (muted double ring, no chevron, `--text-faint`). Reads as "event of unspecified kind"; not an
  error state.
- `t308-node-bare-selected.png` — READ: same node selected — the selection glow lands correctly on
  the outer ring (the `.node-shape` class is on the outer circle), no double-halo artefact.
- `t308-node-bound-unchanged.png` — READ: uuid-bound handoff keeps the accent circle + inward
  chevron. Side-by-side with the neutral ring the two are unmistakably different objects.
- `t308-panel-bare-header.png` — READ: inspector header badge is the neutral double ring and the
  type name reads `intermediateEvent`; BPMN basics (Name/Slug/Display ID/UID/Lane) unchanged.
- `t308-panel-bare-eventkind.png` — READ: the "Event kind" note plus the "← Make this a handoff"
  affordance. No `AEF:` badge on this section — it is not an aef: field group, and the first cut
  wrongly badged it as one.
- `t308-panel-bound-unchanged.png` — READ: bound handoff still gets the full Extensions section —
  Workflow ref (uuid), Ref display name, target picker, "Open target workflow", Link ID.
- `t308-palette-live.png` — READ: a handoff dropped from the palette keeps the chevron and the
  "← Handoff" name while live in the session, so binding stays discoverable.
- `t308-palette-after-reload.png` — READ: the same node after the reload proxy
  (`sessionAuthoredLinks.clear()`) — glyph goes neutral while the authored name stays. This is the
  combination the second Human [REVIEW] AC asks about; see **Decisions**.

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

### 2026-07-29 — the throw side has the same defect and is deliberately out of scope

- **What changed:** `REVERSE_TYPE['intermediateThrowEvent'] = 'linkEventThrow'` sits one line above
  the catch fallback and has the identical shape — a bare `intermediateThrowEvent` becomes a
  "Handoff →" node with target fields that can never bind. T-244 explored and priced the catch case
  only, so the GO covers only that.
- **Plan impact:** none for this task. `isBareCatchEvent` is deliberately catch-only rather than a
  generic `isBareLinkEvent`, so widening later is an explicit change and not an accident.
- **Triggered:** not filed. Widening the GO's scope is the operator's call, not mine — flagged in
  **Recommendation** instead.

### 2026-07-29 — the panel needed an escape hatch the exploration had not anticipated

- **What changed:** hiding the dead link fields alone would have made an imported bare catch event
  impossible to turn *into* a handoff — the fix for a misread would have created a dead end. Not
  visible from the T-244 analysis, which reasoned about how the node reads, not how it is edited.
- **Plan impact:** added the "← Make this a handoff" affordance, and with it a second entry point
  into `sessionAuthoredLinks` beyond palette drops.
- **Triggered:** an extra EXPORT assertion — declaring intent through the affordance must still
  write nothing to the document, or the escape hatch would have quietly reintroduced path (a).

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

### 2026-07-29 — the node's own name is not rewritten

- **Chose:** neutralise the *glyph*, the *type badge* and the *property panel*, and leave `n.name`
  exactly as authored — so a node named "← Handoff" that is unbound renders as a neutral ring still
  labelled "← Handoff".
- **Why:** the name is authored content, and it is serialized. Rewriting it would change exported
  bytes, breaking the zero-export-surface constraint that is the entire reason path (b) needs no
  AEF ratification — and it would destroy the author's text to make a presentation point. The
  combination is also arguably the honest reading: someone meant this to be a handoff and never
  bound it, and the document says so in the only place it can. The original AC said "neutral
  label"; the deliverable is a neutral **type** label, and the second Human [REVIEW] AC was
  rewritten to describe what is actually on screen so the operator judges the real thing.
- **Rejected:** (a) substituting a display-only name when unbound — the canvas label would then
  disagree with the Name field in the inspector, trading one confusion for a worse one;
  (b) rewriting `n.name` on import — mutates exported bytes and is destructive.

### 2026-07-29 — session intent lives in a module Set, not on the node

- **Chose:** a module-level `sessionAuthoredLinks = new Set()` holding uids, populated by
  `createNodeAt` for palette drops and by the "← Make this a handoff" affordance.
- **Why:** IW-3 established the dialect has no carrier for authorial intent. A field on the node or
  on `state` would be reachable by every serializer and one future "persist the editor state"
  change away from becoming a dialect change (path (a)) by accident. A Set outside `state` cannot
  be serialized, and a reload empties it — which is exactly the intended lifetime. A Verification
  line asserts no `sessionAuthored*` key is ever written onto a node or `state`.
- **Rejected:** `node._sessionHandoff = true` — simpler to write, but it rides inside the object
  the exporter walks, so the invariant would depend on the exporter's key allowlist staying correct
  forever rather than on the data being unreachable.

### 2026-07-29 — an explicit affordance instead of silently hiding the fields

- **Chose:** hide the dead link fields but offer "← Make this a handoff", which reveals them for the
  session.
- **Why:** hiding alone would make an imported bare catch event impossible to *turn into* a handoff
  — the fix for a misread would have created a dead end. Clicking it writes nothing to the document
  (verified: `<aef:link>` count unchanged, node still unbound), so the zero-export-surface property
  survives the affordance.

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

### 2026-07-29T17:47:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-308-bare-catch-event-neutral-rendering-when-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5caa1c1e
- **Timestamp:** 2026-07-29T20:08:23Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T20:07:33Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
