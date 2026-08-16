---
id: T-238
name: "G-010: standing shell-runnable editor behavior suite (deep-link/autosave/claim
  legs)"
description: >
  G-010: standing shell-runnable editor behavior suite (deep-link/autosave/claim legs)

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
created: 2026-07-22T18:17:35Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-22T18:26:25Z
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
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/project/concerns.yaml,src/aef-workflow-designer.html,tests/run-bridge-tests.sh,tests/test_editor_behavior.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-238: G-010: standing shell-runnable editor behavior suite (deep-link/autosave/claim legs)

## Context

Closes gap G-010 (concerns.yaml): editor load/persistence behavior paths (deep-link,
autosave restore, in-place map switch) and the T-237 import/re-export classification
paths had NO standing behavior tests — T-234 and T-237 are the two field-found 0.3.1
blockers that shipped through that blindness. Deliverable: a standing shell-runnable
suite `tools/_editor-behavior-verify-cdp.mjs` (isolated headless Chromium via CDP,
same G-006-safe pattern as tools/_autoload-verify-cdp.mjs), wired into
tests/run-bridge-tests.sh with a VISIBLE chromium-skip (never silently unguarded —
the T-212 convention). Legs encode the T-234 jump-poisoning matrix and the T-237
import/re-export contract. Read-only against the server (fetches only; never
/api/save — no registry/claim mutation; localStorage cleared between legs, PL lesson
from the T-237 verify).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/_editor-behavior-verify-cdp.mjs` exists and runs green: exit 0, JSON verdict all legs pass:true (hermetic design — temp --repo + temp docroot sidecar, isolated chromium; structurally cannot touch real state)
- [x] T-234 legs encoded and green: (1) jump-no-poison — ?load=arc-lifecycle → jumpToWorkflow(audit-process) → autosave record {id:audit-process, src:null} → revisit ?load ⇒ arc-lifecycle renders (14 nodes); (2) same-map edit-restore — mutation restored on reload via suppressed re-fetch path
- [x] T-237 legs encoded via in-page parse→serialize, all green: (3) throw+eventDef stays intermediateThrowEvent (exactly 1 throw tag on re-export; payload-drop decision locked in); (4) catch+link+eventDef → linkEventCatch, workflowRef preserved; (5) bare catch → linkEventCatch; (6) typed catch → eventMessage + busTopic, aef:eventDef re-emitted
- [x] READ-ONLY proven: 0 /api/save references in the suite source; real registry sha256 byte-identical across full runs (belt: the sidecar's --repo is a temp dir anyway)
- [x] Wired into tests/run-bridge-tests.sh (new section after corpus pins) via wrapper tests/test_editor_behavior.py with LOUD chromium/node SKIP (T-212 convention); full runner green, exit 0
- [x] G-010 updated in concerns.yaml: status → prevention-in-place with T-238 + suite path + TEETH evidence cited; TEETH proven — vs pre-fix editor (git show 7390131^) the suite fails BOTH legs with the exact field symptoms (src poisoned to rendered/arc-lifecycle.bpmn, wrong map on revisit; throw→eventMessage mutation, 0 throw tags)

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

# Suite green (hermetic — needs node + playwright chromium, both present here)
node tools/_editor-behavior-verify-cdp.mjs > /dev/null
# Wrapper green standalone (LOUD skip path exists but must not trigger in this env)
python3 tests/test_editor_behavior.py > /dev/null
# Runner wiring present
grep -q "test_editor_behavior.py" tests/run-bridge-tests.sh
# Suite is read-only by construction: zero /api/save references
test "$(grep -c "api/save" tools/_editor-behavior-verify-cdp.mjs)" -eq 0
# G-010 marked prevention-in-place
grep -q "prevention-in-place" .context/project/concerns.yaml
# concerns register still parses
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"

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

### 2026-07-22 — Hermetic sidecar over live-:8834 dependency
- **Chose:** the suite bootstraps its own throwaway gallery-serve.py (temp --repo, temp docroot with src/ editor + 2 rendered maps copied in) on a free port — the _typed-events-cdp.mjs architecture — instead of targeting the live :8834 server like _autoload-verify-cdp.mjs does.
- **Why:** (1) read-only by construction — even a bug in the suite cannot mutate the real registry/claims/versions store (the T-235 claim is one-way; a stray save against :8834 could consume a fixture ghost); (2) runs in cron/CI contexts where :8834 may be down; (3) tests the SOURCE editor (src/), catching regressions before deploy.
- **Rejected:** live-:8834 target — simpler but adds a server-up precondition and a real-state mutation risk; source-grep-only guard — G-010's whole point is that greps don't catch behavior.

### 2026-07-22 — Teeth via pre-fix editor replay (argv editor override)
- **Chose:** the harness accepts an editor path override; teeth are proven by running it against `git show 7390131^:src/aef-workflow-designer.html` and requiring BOTH legs to fail with the field symptoms.
- **Why:** an in-run BITE mutation (typed-events style) can't exercise cross-page persistence legs; replaying the actual pre-fix build proves the suite would have caught both shipped defects — the strongest possible non-vacuity evidence for a G-019 prevention claim.
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

### 2026-07-22T18:17:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-238-g-010-standing-shell-runnable-editor-beh.md
- **Context:** Initial task creation

### 2026-07-22T18:26:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
