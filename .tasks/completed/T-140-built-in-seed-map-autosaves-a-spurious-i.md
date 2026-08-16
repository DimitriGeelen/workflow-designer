---
id: T-140
name: "Built-in seed map autosaves a spurious 'investigate' version entry at Init"
description: >
  INVESTIGATION OUTCOME: NOT-A-BUG (diagnosis invalidated 2026-07-07). The original
  premise — that the built-in seed (id 'investigate') is *autosaved* to the version
  store at Init — is false. Code trace proves the version store (.editor-versions/<id>/)
  is written ONLY by POST /api/save (gallery-serve.py do_POST), which on the client
  is
  called ONLY from saveToProject() (fetch('/api/save'), 1 call site), bound ONLY to
  btn-save-project.onclick (manual click) behind an _apiAvailable gate. The T-127
  autosave (autosaveNow) writes localStorage ONLY — it never touches the server. Opening
  designer.html, including with ?load=<map> (which calls adoptImportedXml → in-memory
  +
  localStorage, not saveToProject), creates ZERO version-store entries. The 'investigate'
  residue seen in the prior session was self-inflicted: my own Playwright automation
  clicked "Save to project" while the seed was the active document. Saving the active
  document on an explicit click is correct behaviour, not a defect. No code change
  is
  warranted; making one would modify working code on a false premise. T-138 already
  keeps
  such scratch saves out of the committed corpus. Optional UX hardening (warn/no-op
  when
  Save is clicked on the pristine, unedited seed) is a SEPARATE feature, not this
  bug —
  filed only if the operator asks.

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
created: 2026-07-07T17:01:43Z
last_update: '2026-08-16T12:33:39Z'
date_finished: 2026-07-07T17:22:44Z
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
  - ts: '2026-08-16T12:33:39Z'
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
---

# T-140: Built-in seed map autosaves a spurious 'investigate' version entry at Init

## Context

Investigation task (reclassified from bug). Verifies whether the built-in seed can
reach the server version store without an explicit operator save. Conclusion: it cannot.

## Acceptance Criteria

### Agent
- [x] Version store write path is server-side POST /api/save only
      (`grep "if parsed.path != '/api/save'" tools/gallery-serve.py` → 1)
- [x] Client has exactly ONE call site to /api/save, inside saveToProject()
      (`grep -c "fetch('/api/save'"` → 1)
- [x] saveToProject() is reachable ONLY via the manual Save button, not Init/load
      (`grep "btn-save-project').onclick = saveToProject"` → 1; no other caller)
- [x] Autosave (T-127) writes localStorage only, never the server
      (`grep "localStorage.setItem(AUTOSAVE_KEY"` → 1)
- [x] No source change made — mirror invariant holds byte-identical
      (`diff -q src/aef-workflow-designer.html build/gallery/designer.html`)

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
test "$(grep -c "if parsed.path != '/api/save'" tools/gallery-serve.py)" = "1"
test "$(grep -c "fetch('/api/save'" src/aef-workflow-designer.html)" = "1"
grep -q "btn-save-project').onclick = saveToProject" src/aef-workflow-designer.html
grep -q "localStorage.setItem(AUTOSAVE_KEY" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

**Symptom:** A stray `investigate` entry appeared in the editor's version library
(`.editor-versions/investigate/` with v1/v2) during the prior session; I attributed it
to the built-in seed being autosaved to the version store at Init.

**Root cause:** Mis-diagnosis, not a code defect. The version store is written ONLY by
`POST /api/save` (`tools/gallery-serve.py` `do_POST`). On the client that endpoint is hit
from a single call site — `saveToProject()` — which is bound ONLY to `btn-save-project`'s
click handler behind an `_apiAvailable` gate. The T-127 autosave (`autosaveNow`) persists
to `localStorage` exclusively and never contacts the server. `?load` and file-import both
route through `adoptImportedXml` (in-memory + localStorage), not `saveToProject`. Opening
the editor therefore produces zero version-store writes. The residue was self-inflicted:
Playwright automation in the prior session clicked "Save to project" with the seed active.

**Why structurally allowed:** The prior task was filed from an observed symptom without
tracing the write path — the STOP-and-investigate step (trace the actual writer before
asserting a cause) was skipped. The residue landed untracked, so no gate flagged the
false claim; only a fresh code trace this session surfaced it.

**Prevention:** Captured as a learning — a symptom seen under test automation must have
its write path traced to a call site before a root cause is asserted (see `## Decisions`).
No functional gate needed: T-138 already prevents such scratch saves from reaching the
committed corpus, and saving the active document on an explicit click is correct by design.

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

### 2026-07-07 — Close as not-a-bug rather than change code
- **Chose:** Reclassify T-140 as an investigation with a NOT-A-BUG outcome; make no code
  change; complete the task with the corrected RCA as the deliverable.
- **Why:** The version store is written only by an explicit "Save to project" click; there
  is no Init/load autosave-to-server path. Editing working code to "fix" a non-existent
  autosave would risk a regression on a false premise. The observed residue was test-
  automation self-inflicted and is already contained by T-138.
- **Rejected:** (a) Implement fix candidate "skip Init-time autosave of the seed" — there
  is no such autosave to skip. (b) Touch T-127's autosave seam — irrelevant; that seam is
  localStorage-only and not the writer. (c) Build the optional "warn on saving pristine
  seed" UX guard now — that is new, unrequested scope; offer it, don't build it unasked.

## Recommendation

**Recommendation:** NO-GO on a code change; GO on closing T-140 as NOT-A-BUG (agent-owned,
no human AC — completes cleanly).

**Rationale:** All 5 Agent ACs are verified against the actual code, proving the version
store is only reachable through a manual Save click. The filed bug describes a mechanism
(Init-time autosave to the server) that does not exist. The correct, integrity-preserving
outcome is to record the corrected RCA and close, not to modify working code.

**Evidence:**
- `grep -c "if parsed.path != '/api/save'" tools/gallery-serve.py` → 1 (server writes store only on POST /api/save)
- `grep -c "fetch('/api/save'" src/aef-workflow-designer.html` → 1 (single client call site, in saveToProject)
- `grep -q "btn-save-project').onclick = saveToProject"` → present (only manual-click reachable)
- `grep -q "localStorage.setItem(AUTOSAVE_KEY"` → present (autosave is localStorage-only)
- `diff -q src/aef-workflow-designer.html build/gallery/designer.html` → identical (no source change)

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-07T17:01:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-140-built-in-seed-map-autosaves-a-spurious-i.md
- **Context:** Initial task creation

### 2026-07-07T17:20:42Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-07T17:22:44Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
