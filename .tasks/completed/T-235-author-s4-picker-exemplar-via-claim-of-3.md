---
id: T-235
name: "Author S4 picker exemplar via claim of 3ceaf02d and deliver b64+sha to AEF
  T-2593 intake"
description: >
  Author the S4 picker exemplar for AEF T-2593 intake: via the RUNNING :8834 picker,
  claim ghost 3ceaf02d (claim-smoke-legacy, referrer claim-smoke-ref — 832-owned fixture);
  author 3 aef:link legs in the adopted map per AEF spec (rail 149): (a) RESOLVED
  workflowRef=1f9b5f0c (aef-task-lifecycle, now LIVE after AEF re-verify), (b) GHOST
  workflowRef=fresh uuid not in store (save-rescan mints it), (c) LEGACY targetWorkflow=review-map
  name-only. Save (claim fires via:ui). Deliver like pair-draft-3: b64 chunks on the
  DM + sha256 + version note; AEF drops at tests/fixtures/832/s4-exemplar.{bpmn,sha256}
  and flips 2 skips in test_s4_exemplar_intake.py. Do NOT touch remaining AEF fixture
  adb0e0f2.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-22T06:46:37Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-22T18:15:35Z
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
  - ts: '2026-08-16T12:33:45Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.context/designer/registry.yaml,.editor-versions/claim-smoke-legacy/v1.bpmn,tests/fixtures/aef-bpmn/s4-exemplar.bpmn,tests/test_corpus_fixture_pins.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-235: Author S4 picker exemplar via claim of 3ceaf02d and deliver b64+sha to AEF T-2593 intake

## Context

AEF-accepted delivery spec (rail offsets 149/152, their T-2593 intake): author the S4
picker-claim EXEMPLAR — the first real map born through the T-228 "create from pending
ref" picker — and deliver it byte-pinned so AEF drops it at
`tests/fixtures/832/s4-exemplar.{bpmn,sha256}` and flips the 2 skips in their
`test_s4_exemplar_intake.py`. Vehicle: pending ghost **3ceaf02d** (name
`claim-smoke-legacy`, referenced by claim-smoke-ref) — the fixture AEF reserved for this.
The map must exercise the 3 off-page legs in picker-authored form: **resolved** →
`1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7` (aef-task-lifecycle, NOW LIVE post-claim),
**ghost** → a fresh unresolved uuid, **legacy** → bare `targetWorkflow="review-map"`.
Save through /api/save so the claim fires server-side ({via:ui} — the picker path IS the
exemplar's provenance). Do NOT touch AEF's fixture ghost **adb0e0f2** (review-map,
stays untouched). Delivery: b64 chunks + sha256 pin, concat-verified BEFORE posting
(PL rail-delivery lesson, offsets 96-101), plus the saved version note.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The exemplar map is born via the REAL picker path on the served :8834 editor (open "create from pending ref" → click the 3ceaf02d card → map adopts uuid 3ceaf02d), not via hand-authored XML — the provenance IS the deliverable (Playwright: btn-pending-refs → 3ceaf02d card → state.workflowMeta.uuid = 3ceaf02d-07a7-49e2-ad15-63dfe68cf474, id claim-smoke-legacy)
- [x] The authored map carries the 3 off-page legs (resolved → 1f9b5f0c live uuid; ghost → fresh unresolved uuid 4300eae7; legacy → bare targetWorkflow="review-map") plus start→task spine + reachability edges — validate-workflow.py: VALID, no findings (pre-save AND on saved bytes)
- [x] Save-to-project fired the server claim: registry.claims gained {uuid: 3ceaf02d…, project: claim-smoke-legacy, via: ui}; ghost 3ceaf02d dropped from /api/list ghosts[]; the claim-smoke-ref referrer resolves (slug claim-smoke-legacy live); AEF's adb0e0f2 ghost UNTOUCHED (still pending, s4-e2e-probe referrer intact; gained the exemplar's legacy-leg referrer = designed rescan behavior)
- [x] Saved .bpmn bytes sha256-pinned (82b6ab78cd5f54b800b3c644b6f35eefbb169dc3ca6d05ce802807a3cec956b7) — byte-copy at tests/fixtures/aef-bpmn/s4-exemplar.bpmn, pin wired into tests/test_corpus_fixture_pins.py (green)
- [x] Delivery posted on the rail at offset 158: single message (4846 B → 6464 b64, under the 12KB chunk limit), concat-decode verified against the pin BEFORE posting, sha256 + version note + intended AEF path included
- [x] Registry + list verifiers green after the claim: _gallery-list-verify 22/22, _gallery-registry-verify 17/17, _gallery-claim-verify 11/11

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

# Fixture bytes match the pin (L-387/PL-051-safe: no pipes at all)
test "$(sha256sum tests/fixtures/aef-bpmn/s4-exemplar.bpmn | cut -d' ' -f1)" = "82b6ab78cd5f54b800b3c644b6f35eefbb169dc3ca6d05ce802807a3cec956b7"
# Fixture bytes == the saved editor version (provenance chain intact)
cmp tests/fixtures/aef-bpmn/s4-exemplar.bpmn .editor-versions/claim-smoke-legacy/v1.bpmn
# Exemplar validates clean
python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/s4-exemplar.bpmn
# Pins guard green (byte-determinism + validator-clean + teeth)
python3 tests/test_corpus_fixture_pins.py
# Claim recorded via:ui, ghost gone, adb0e0f2 still pending with its original referrer
python3 -c "import json; r=json.load(open('.context/designer/registry.yaml')); c=[x for x in r['claims'] if x['uuid'].startswith('3ceaf02d')]; assert c and c[0]['via']=='ui' and c[0]['project']=='claim-smoke-legacy', c; assert not any(g['uuid'].startswith('3ceaf02d') for g in r['ghosts']); a=[g for g in r['ghosts'] if g['uuid'].startswith('adb0e0f2')]; assert a and any(ref['id']=='s4-e2e-probe' for ref in a[0]['referenced_by'])"
# Standing gallery verifiers green after the claim
python3 tools/_gallery-list-verify.py > /dev/null
python3 tools/_gallery-registry-verify.py > /dev/null
python3 tools/_gallery-claim-verify.py > /dev/null

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

### 2026-07-22 — Keep the picker-default slug "claim-smoke-legacy" (no rename to s4-exemplar)
- **Chose:** the exemplar map keeps id/slug/title `claim-smoke-legacy` — the picker's default, slugified from the ghost name.
- **Why:** ghost 3ceaf02d is NAME-ONLY: its referrer (claim-smoke-ref/hum_1_legacy) points via legacy `targetWorkflow="claim-smoke-legacy"`, and legacy refs resolve by LIVE SLUG in the save-rescan. Renaming would leave the slug dead — the next save of claim-smoke-ref would re-mint a fresh "claim-smoke-legacy" ghost, undoing the claim's resolution. `s4-exemplar` is AEF's FILENAME at their drop path (tests/fixtures/832/), which is theirs to choose; the map's identity is the uuid.
- **Rejected:** rename to `s4-exemplar` for name symmetry with AEF's fixture path — breaks legacy-referrer resolution (above) and deviates from the pure picker path the provenance AC exists to demonstrate.

### 2026-07-22 — Reachability edges instead of claim-smoke-ref's floating-node shape
- **Chose:** a minimal spine (start → serviceTask) with sequence flows from the task to all 3 link connectors.
- **Why:** the validator's W-XML-UNREACHABLE fires for nodes unreachable from a startEvent once a startEvent exists; "validates clean" is an AC. claim-smoke-ref passed only because it has NO start event (reachability check vacuous) — an exemplar should model a real flow, not exploit that hole.
- **Rejected:** no-start floating-connectors shape (claim-smoke-ref precedent) — validates clean but is a degenerate map, wrong thing to hand a peer as the canonical picker exemplar.
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

### 2026-07-22T06:46:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-235-author-s4-picker-exemplar-via-claim-of-3.md
- **Context:** Initial task creation

### 2026-07-22T11:02:50Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-22T18:15:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
