---
id: T-230
name: "S4b: fw bpmn claim CLI — add bpmn subcommand to vendored fw (headless ghost
  claim, via:cli)"
description: >
  S4b of the off-page seam: headless 'fw bpmn claim <uuid> <project>' added as a real
  bpmn subcommand to the vendored .agentic-framework/bin/fw (operator-decided home).
  Resolves a ghost by uuid in .context/designer/registry.yaml, removes it from ghosts,
  appends {uuid,project,ts,via:cli} to claims, writes the uuid into the target map's
  workflowMeta. Operates only on 832's own store (T-559 boundary). Depends on S4a/T-228
  claim-recording path. Split from T-228 per operator decision 2026-07-22.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_bpmn-claim-cli-verify.py, tools/bpmn-cli.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-21T22:42:51Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-22T05:59:51Z
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
  - ts: '2026-08-16T12:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-230: S4b: fw bpmn claim CLI — add bpmn subcommand to vendored fw (headless ghost claim, via:cli)

## Context

**S4b** of the off-page connector seam — the headless counterpart to S4a/T-228's editor picker.
Adds `fw bpmn claim <uuid> <project>` as a real `bpmn` subcommand to the vendored
`.agentic-framework/bin/fw` (operator-decided home; the dispatcher hard-fails unknown commands at
`bin/fw:6622`, so a project-local tool wouldn't be `fw bpmn`). Claims a pending ghost **without the
editor**: resolves the uuid in `.context/designer/registry.yaml ghosts[]`, drops it, appends
`{uuid,project,ts,via:"cli"}` to `claims[]`, and writes the uuid into the target map's stored
`<aef:workflowMeta uuid=…>` so `/api/list` derives it as a live map and every referrer resolves
(zero referrer-XML edit) — the SAME outcome as S4a's `via:"ui"`, different surface. Operates ONLY
on 832's own store (T-559 boundary — never invokes AEF tooling). Reuses the S4a claim semantics
(`claim_ghost_after_save`, T-228). Ratified command shape matches AEF's contract verbatim.
See `[[aef-integration-rail]]` and T-228 Decisions (split + CLI-home).

## Acceptance Criteria

### Agent
- [x] `fw bpmn claim <uuid> <project>` exists as a real `bpmn` subcommand in the vendored `.agentic-framework/bin/fw` (routed through the dispatcher → `exec python3 $PROJECT_ROOT/tools/bpmn-cli.py`); `fw bpmn` with no/invalid args prints usage and exits non-zero (G-008 upstream path applies to the vendored edit — noted in the route comment + Evolution)
- [x] **Claim mutation:** resolves `<uuid>` in `.context/designer/registry.yaml ghosts[]`; on match removes it from `ghosts[]` and appends `{uuid, project, ts, via:"cli"}` to `claims[]` (append-only; re-claiming an already-claimed uuid is an idempotent no-op success — no duplicate entry, ghost stays gone). Reuses gallery-serve.py's `claim_ghost_after_save(via='cli')` — the exact fn the server calls on save (single source of truth)
- [x] **Map carries the uuid:** the target `<project>`'s stored BPMN gains `<aef:workflowMeta uuid=<uuid>>` (uuid attr spliced into the existing workflowMeta open tag, all other content untouched; written as a new version so it becomes the authoritative + served + corpus-if-existing copy), so `/api/list` lists it as a live `maps[].uuid` and referrers whose `workflowRef==<uuid>` resolve — matching the S4a `via:"ui"` result exactly (same registry shape + same resolution, only `via` differs)
- [x] **Guardrails:** an unknown uuid (not a pending ghost) → clear error + non-zero exit + NO registry mutation; an unknown/absent `<project>` in the store → clear error + non-zero exit; a target with a *different* existing uuid or no workflowMeta → clear error + NO mutation (avoids orphaning identity — see Decisions); the command touches only 832's `.context/designer/registry.yaml` + gallery store (T-559 — no AEF tooling invoked)
- [x] A verify tool (`tools/_bpmn-claim-cli-verify.py`, stdlib-only, isolated temp repo) exercises the cli path end-to-end (seed ghost + referrer → `fw bpmn claim` → ghost dropped + `claims[]` records `via:"cli"` + map carries the uuid + referrer resolves; idempotent re-claim; unknown-uuid/unknown-project rejected). **Passes 15/15**; existing verifiers still green (list 22/22, registry 17/17, claim 11/11, save-allowlist 6/6, serve-gallery 9/9, corpus-adopt OK)

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
bash -n .agentic-framework/bin/fw
python3 -m py_compile tools/bpmn-cli.py
python3 tools/_bpmn-claim-cli-verify.py
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-registry-verify.py
python3 tools/_gallery-claim-verify.py
.agentic-framework/bin/fw bpmn; test $? -ne 0

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

### 2026-07-22 — the claim TARGET shape wasn't as assumed at filing
- **What changed:** Filing assumed "splice the uuid into the target map's stored
  workflowMeta" was uniform. Inspecting the corpus showed 15/24 rendered maps carry
  `<aef:workflowMeta …>` with **no uuid attr**, 9 carry no workflowMeta at all, and
  editor-authored maps already carry a *live* uuid. So the real operation is
  attr-injection into an existing tag (primary path), not element creation — and an
  existing-uuid target raises an orphaning hazard the filing never considered.
- **Plan impact:** Added two guardrails beyond the filed unknown-uuid / unknown-project
  pair: no-workflowMeta → error; different-existing-uuid → error (see Decisions). The
  "map gains the uuid" AC is satisfied by injection; element-creation was dropped as
  out of scope + fragile.
- **Triggered:** No new task. Recorded the G-008 obligation (the vendored `.agentic-framework/bin/fw`
  `bpmn` route must be mirrored upstream on next framework sync) inline in the route comment.

## Decisions

### 2026-07-22 — CLI home + logic split (dispatcher route → project-owned Python)
- **Chose:** A thin `bpmn)` route in the vendored `.agentic-framework/bin/fw` that
  `exec python3 $PROJECT_ROOT/tools/bpmn-cli.py "$@"`; all claim logic lives in the
  project's `tools/bpmn-cli.py`, which imports `gallery-serve.py` and reuses its
  `sync_registry_after_save` + `claim_ghost_after_save(via='cli')` (the same two fns
  the /api/save handler calls) plus a version-write that mirrors the save handler.
- **Why:** Operator decided `fw bpmn` is the home (the dispatcher hard-fails unknown
  commands, so a project-local tool can't be `fw bpmn`). Keeping semantics in one place
  (gallery-serve.py) makes the CLI outcome byte-identical to S4a apart from `via` —
  antifragile: a future change to claim rules can't drift the two surfaces apart.
- **Rejected:** Re-implementing registry/version logic in bash (drift risk, no reuse);
  adding a `GALLERY_REPO` env override *inside* gallery-serve.py (widens the serving
  file's blast radius) — instead the CLI reassigns `gs.REPO`/`gs.DOCROOT` post-import,
  so the serving file is untouched and tests stay isolated via `--repo`.

### 2026-07-22 — orphan guard: refuse to claim onto a map with a different live uuid
- **Chose:** If the target already carries a *different* `workflowMeta uuid`, error with
  no mutation (claim onto a uuid-less map, or use the S4a editor picker for a fresh map).
  Target already carrying *this* uuid → idempotent success. No workflowMeta → error.
- **Why:** S4a's picker seeds a *fresh* map (no prior identity) adopting the ghost uuid,
  so nothing is orphaned. A CLI claim onto an existing map with its own uuid would
  silently abandon that identity (and potentially strand *its* referrers). Fail-loud
  preserves the fresh-adoption invariant across both surfaces.
- **Rejected:** Silently overwriting the existing uuid (data-loss hazard); auto-creating
  a workflowMeta element when absent (fragile placement into arbitrary BPMN — deferred;
  the editor mints identity cleanly on first save).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-21T22:42:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-230-s4b-fw-bpmn-claim-cli--add-bpmn-subcomma.md
- **Context:** Initial task creation

### 2026-07-22T05:40:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-22T05:59:51Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
