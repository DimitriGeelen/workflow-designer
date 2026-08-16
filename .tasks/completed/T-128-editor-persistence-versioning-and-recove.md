---
id: T-128
name: "Editor persistence, versioning and recovery subsystem"
description: >
  Inception: Editor persistence, versioning and recovery subsystem

status: work-completed
workflow_type: inception
owner: human
horizon:
tags: []
components: []
related_tasks: []
created: 2026-07-06T11:37:59Z
last_update: '2026-08-16T13:57:16Z'
date_finished: 2026-07-06T11:58:30Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:38Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 2
      F3: 2
      F1: 2
      F2: 2
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F-AUTONOMY=2 (no-signal); F3=2 
      (no-signal); F1=2 (no-signal); F2=2 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:16Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=4 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-128: Editor persistence, versioning and recovery subsystem

## Problem Statement

The BPMN workflow designer (`src/aef-workflow-designer.html`, served at :8834) has no durable
document persistence. Only *preferences* persist to localStorage; the *document* lives in an
in-memory `library` Map and "Save" merely downloads a `.bpmn` file. A reload, navigation, or
crash discards unsaved authoring work — this cost the operator real work (T-126). The T-126
autosave safety-net (localStorage snapshot + restore banner) is now verified, but the operator
wants a proper subsystem:

1. **Reload AUTO-LOADS** the stored version (not a dismissible banner — "i want reload to load
   the stored version").
2. **Manual Save into the git repo** (durable, not a download).
3. **Versioning** per map + **revert-to-previous-version**.
4. **Undo/redo** (generalize the editor's Tidy-only undo).
5. **Version thumbnails** in the restore/revert UI (visually pick which version to restore).

**Deeper why (strategic):** once layout corrections are versioned in the repo, each Save becomes
a concrete before/after geometry diff — the raw material to mechanically learn the operator's
routing/layout rules and codify them as engine heuristics. That is the operator's stated
long-term goal and the reason durable, *diffable* versioning (not just "don't lose work") matters.

## Assumptions

- A1: The operator edits the SAME maps that constitute the corpus (`examples/aef-processes/*.workflow.yaml`);
  Save-to-repo means writing those canonical files (+ re-rendering `rendered/*.bpmn`).
- A2: Maps are small (~14 nodes); full-state snapshots for undo/versioning are cheap.
- A3: The editor can render its own SVG to a PNG thumbnail client-side (to verify — IW-5).
- A4: A small write-capable server endpoint alongside the gallery is acceptable (the gallery is
  already served locally on :8834).

## Open Questions

- **IW-1: Version store model — git-log-of-file vs explicit snapshot files vs hybrid?**
  confidence: 2
  disposition: answered
  rationale: Choose **explicit snapshot store** `.editor-versions/<id>/` (vN.workflow.yaml +
  vN.png + index.json), committed to the repo. Self-contained (survives shallow clones),
  directly supports thumbnails, and needs no git plumbing in the browser. Git history of the
  canonical file still provides the learning diffs. Git-log-only rejected: can't hold thumbnails
  and forces server-side git shelling per version list. See ## Decisions.

- **IW-2: Save transport — extend the gallery server vs a dedicated sidecar?**
  confidence: 3
  disposition: answered
  rationale: S-2 confirmed :8834 is `python3 -m http.server` (static, read-only, serves
  build/gallery off-repo). Choose a **dedicated Python sidecar** run from repo root, localhost-bound,
  serving the designer AND `/api/*` from ONE origin (no CORS). Editor **progressively enhances**:
  repo-save/version UI appears only when `/api/*` is reachable; on the static gallery it degrades
  to autosave + download. Static gallery untouched. See ## Decisions.

- **IW-3: Reload auto-load precedence — localStorage autosave vs repo-latest vs seed?**
  confidence: 3
  disposition: answered
  rationale: Auto-adopt the **localStorage autosave** if present (it is always ≥ the last manual
  Save, since autosave fires on every edit), keyed by `workflowMeta.id` so reloads don't cross
  maps; fall back to repo-latest, then the seed. Provide non-modal "New / Start fresh" and
  "Discard local changes → load last saved" affordances. Replaces the banner. See ## Decisions.

- **IW-4: Undo/redo granularity, and where does the mutation hook live?**
  confidence: 2
  disposition: answered
  rationale: **Per-gesture** granularity (a drag = one entry, not per-mousemove); snapshot-BEFORE
  at explicit mutation commit points via `pushHistory(label)` (generalizes existing `lastTidy`).
  NOT in `renderAll()` — that fires on non-mutating re-renders and would create spurious entries
  (autosave-in-renderAll stays, being idempotent). Full-state snapshots (A2), stack capped ~50.
  See ## Decisions.

- **IW-5: Thumbnail generation — client SVG→PNG vs server CDP screenshot?**
  confidence: 3
  disposition: answered
  rationale: **Client-side** `SVG → Image(data-URL) → canvas → toDataURL('image/png')`. Spike S-3
  confirmed: the diagram is `<svg id="canvas">` with ZERO `foreignObject` and no external refs
  (self-contained, no CDN) → no canvas-taint source; a control render produced a valid
  `data:image/png;base64,iVBOR…` (no SecurityError). One round-trip with Save; no server render
  needed. Fallback (isolated-headless CDP) exists but is unnecessary. See ## Decisions.

- **IW-6: Sovereignty — does manual Save overwriting canonical corpus geometry respect PD-044?**
  confidence: 3
  disposition: answered
  rationale: Yes. PD-044 requires stored geometry be mutated only by **explicit user action**;
  clicking "Save to project" IS explicit. Hard separation: localStorage autosave is automatic and
  NEVER touches the repo; repo writes happen ONLY on manual Save. Post-save guard: node-cut census
  stays 0/24 and `diff -q src build/gallery` mirror stays clean. See ## Decisions.

## Exploration Plan

- **S-1 (research, done inline):** resolve the design questions above → `docs/reports/T-128-editor-persistence-inception.md`.
- **S-2 (spike, ~20min):** inspect what serves :8834; confirm write-endpoint approach (IW-2).
- **S-3 (spike, ~20min):** client-side SVG→PNG thumbnail from the editor; confirm no canvas taint (IW-5).
- On GO: decompose into build tasks (see ## Decisions → Decomposition) and build, starting with
  reload-auto-load (editor-only, operator's #1, lowest risk).

## Technical Constraints

- Single-file editor mirrored byte-identical to `build/gallery/designer.html` (`diff -q` invariant).
- No external network / CDN — editor is self-contained; thumbnail path must be dependency-free.
- Agent verification MUST use ISOLATED headless chromium (G-006), never the shared :8834 browser.
- Repo writes are localhost-only (the gallery server binds locally); no auth needed but the
  endpoint must reject path traversal in `id`.
- `rendered/*.bpmn` regenerated via existing `tools/yaml-to-bpmn.py` on each Save (keep in sync).

## Scope Fence

**IN:** reload auto-load; localStorage autosave (already shipped); Save-to-repo endpoint + editor
button; snapshot-based versioning; revert UI with thumbnails; general undo/redo.
**OUT (this arc):** multi-user/concurrent editing, cloud sync, conflict resolution, the actual
diff→rule-learning engine (that is a *separate* downstream arc this subsystem *enables*, not builds).

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

**GO if:**
- The five operator asks (auto-load, Save-to-repo, versioning, revert, undo/redo + thumbnails)
  decompose into bounded, independently-shippable build tasks (achieved — 5 tasks, see Decisions).
- Save-to-repo respects sovereignty (PD-044) via explicit-action + hard autosave/repo separation (IW-6, answered).
- A durable version store exists that also yields diffable geometry history for the learning goal (IW-1, answered).

**NO-GO if:**
- Persistence would require auto-writing corpus geometry (violates PD-044) — avoided by design.
- Scope is unbounded / needs multi-user or cloud infra — fenced OUT.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO

**Rationale:**

Operator repeatedly and emphatically requested durable editor persistence after a real work-loss incident (T-126). The autosave safety-net is now verified, but the operator's core asks — reload AUTO-LOADS the stored version, manual Save-to-repo, per-map versioning, revert-to-previous, undo/redo, and version thumbnails in the restore UI — form a coherent subsystem with genuine open design questions (version-store model, Save↔sovereignty interaction, undo granularity). This warrants scoping and decomposition via inception rather than ad-hoc build. Deeper strategic value: once corrections are versioned in the repo, each becomes a concrete before/after diff to mechanically learn the operator's routing/layout rules — the operator's stated long-term goal.

**Evidence:**

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

## Decisions

### 2026-07-06 — Version store model (IW-1)
- **Chose:** Explicit snapshot store `.editor-versions/<id>/` with `vN.workflow.yaml`, `vN.png`
  (thumbnail), and `index.json` (list of {v, ts, note, thumb}). Committed to the repo.
- **Why:** Self-contained (survives shallow clones), holds thumbnails natively, no browser-side
  git plumbing. Canonical `<id>.workflow.yaml` git history still gives the learning diffs.
- **Rejected:** git-log-of-file only (can't store thumbnails, forces server git-shelling); pure
  in-memory (not durable).

### 2026-07-06 — Reload precedence (IW-3)
- **Chose:** Auto-adopt localStorage autosave (keyed by map id) → repo-latest → seed. Replace the
  banner with silent auto-load + non-modal "New" / "Discard local → last saved" affordances.
- **Why:** Autosave is always ≥ last manual Save; the operator explicitly wants reload to just
  load their work, no prompt.
- **Rejected:** dismissible banner (operator rejected it); auto-load repo-latest over newer
  autosave (would lose recent edits).

### 2026-07-06 — Undo/redo (IW-4)
- **Chose:** `pushHistory(label)` snapshot-before at explicit mutation sites, per-gesture
  granularity, redo cleared on new mutation, stack capped ~50. Generalizes `lastTidy`/`undoTidy`.
- **Why:** renderAll() fires on non-mutating re-renders — hooking undo there creates spurious
  entries. Full-state snapshots are cheap for ~14-node maps.
- **Rejected:** undo-in-renderAll (spurious entries); per-mousemove granularity (unusable stack).

### 2026-07-06 — Sovereignty (IW-6)
- **Chose:** localStorage autosave = automatic, NEVER writes repo. Repo write ONLY on manual
  "Save to project". Post-save guard: node-cut census 0/24 + mirror `diff -q` clean.
- **Why:** PD-044 — stored geometry mutated only by explicit user action; manual Save is explicit.

### 2026-07-06 — Decomposition (build tasks authorised on GO)
1. **B1 — Reload auto-load** (editor-only): replace `offerAutosaveRestore()` banner with keyed
   auto-adopt + New/Discard affordances. Operator's #1; lowest risk; do FIRST.
2. **B2 — Save sidecar** (server): `/api/save`, `/api/versions`, `/api/version`, `/api/thumb`;
   snapshot store `.editor-versions/`; re-render bpmn + mirror on save.
3. **B3 — Save-to-project button** (editor): POST doc + thumbnail; confirm `git status` shows the file.
4. **B4 — Versioning + revert UI** (editor): version list modal with thumbnails; revert loads a version.
5. **B5 — General undo/redo** (editor): `pushHistory` stack per Decisions above.

## Decision

**Decision**: GO

**Rationale**: Operator repeatedly and emphatically requested durable editor persistence after a real work-loss incident (T-126). The autosave safety-net is now verified, but the operator's core asks — reload AUTO-LOADS the stored version, manual Save-to-repo, per-map versioning, revert-to-previous, undo/redo, and version thumbnails in the restore UI — form a coherent subsystem with genuine open design questions (version-store model, Save↔sovereignty interaction, undo granularity). This warrants scoping and decomposition via inception rather than ad-hoc build. Deeper strategic value: once corrections are versioned in the repo, each becomes a concrete before/after diff to mechanically learn the operator's routing/layout rules — the operator's stated long-term goal.

**Date**: 2026-07-06T11:58:30Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-07-06T11:39:13Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-06T11:58:30Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Operator repeatedly and emphatically requested durable editor persistence after a real work-loss incident (T-126). The autosave safety-net is now verified, but the operator's core asks — reload AUTO-LOADS the stored version, manual Save-to-repo, per-map versioning, revert-to-previous, undo/redo, and version thumbnails in the restore UI — form a coherent subsystem with genuine open design questions (version-store model, Save↔sovereignty interaction, undo granularity). This warrants scoping and decomposition via inception rather than ad-hoc build. Deeper strategic value: once corrections are versioned in the repo, each becomes a concrete before/after diff to mechanically learn the operator's routing/layout rules — the operator's stated long-term goal.

### 2026-07-06T11:58:30Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
