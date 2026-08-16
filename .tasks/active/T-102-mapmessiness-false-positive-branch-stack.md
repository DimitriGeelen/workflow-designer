---
id: T-102
name: "mapMessiness false-positive: branch-stack pitch offsets fire Clean nudge spuriously"
description: >
  mapMessiness (T-100) counts the by-design centre offset between a branch-stack member
  (held at T-093 pitch by align-rows) and an aligned neighbour as a wave, firing the
  Clean nudge on maps Clean has already fully tidied. Fix: exclude waves where either
  endpoint is a branch-stack member (only nudge about mess Clean can fix).

status: started-work
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, bug]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T16:49:08Z
last_update: '2026-08-16T13:57:12Z'
date_finished:
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
  - ts: '2026-08-16T12:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:build/gallery/designer.html,src/aef-workflow-designer.html,tools/_clean-layout-cdp.mjs,tools/serve-gallery.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-102: mapMessiness false-positive: branch-stack pitch offsets fire Clean nudge spuriously

## Context

Discovered during T-101 (bake Clean into corpus). `mapMessiness()` (T-100, the
signal behind the Clean nudge) counts a "wave" — two side-by-side same-lane nodes
whose centres are 1–14px apart — as mess. But `alignRowsLane()` (T-094)
*intentionally* excludes branch-stack members (they hold their T-093 pitch
positions), so a small centre offset between a pitch-held stack node and an
aligned non-stack neighbour is **by-design geometry that Clean can never remove**.
`mapMessiness` still counts it, so after Clean has fully tidied a map the nudge
keeps firing. Latent on the raw corpus (real waves dominate); surfaces once Clean
removes the real mess. Evidence (T-101): post-Clean, 6 corpus maps score ≥3 and
**every** residual pair is a wave involving a branch-stack member (0 real overlaps).

**Fix:** in `mapMessiness`, skip a wave when either endpoint is a branch-stack
member — only nudge about mess Clean can actually fix. Overlaps still always count.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `mapMessiness()` excludes waves where either endpoint is a branch-stack member (uses the same `branchStacksInLane` set align-rows excludes); overlaps still count
- [x] Change made in `src/aef-workflow-designer.html` AND synced byte-identical to `build/gallery/designer.html` (`diff -q` clean)
- [x] After a Clean fixpoint, all 6 previously-residual maps (assumption-validation, audit-process, error-escalation-ladder, harvest-pipeline, inception-review, upgrade-process) score `mapMessiness() < 3` — verified headless (all → 0)
- [x] No regression on real mess: a map with genuine non-stack waves/overlaps still scores ≥3 (nudge still fires when Clean would help) — task-lifecycle 9, verification-gate 11, session-handover 8 still fire

### Human
- [x] [REVIEW] Nudge stays quiet after Clean fully tidies a map, and still appears on a genuinely messy one
  **Steps:**
  1. `cd /opt/832-Workflow-designer && bin/fw run tools/serve-gallery.sh 8834` (or `python3 -m http.server` per the script) — note the URL
  2. Open a genuinely messy map (e.g. `designer.html?load=rendered/task-lifecycle.bpmn`) → the "✨ This map could use Clean layout" nudge should appear
  3. Click **Clean layout** (or the nudge's button) → map tidies AND the nudge disappears
  4. Open a map with only branch-stack pitch offsets (e.g. `harvest-pipeline`, `inception-review`) → nudge should NOT appear on load
  **Expected:** Nudge fires on messy maps, disappears once Clean is applied, and never fires on maps whose only "offset" is intentional branch-pitch geometry
  **If not:** Note which map and whether it over-fires (still shows after Clean) or under-fires (never shows on a clearly messy map)

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
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(node tools/_clean-layout-cdp.mjs assumption-validation audit-process error-escalation-ladder harvest-pipeline inception-review upgrade-process 2>&1); echo "$out" | python3 -c "import sys,json; d=json.load(sys.stdin); bad=[k for k,v in d.items() if v.get('messinessAfter',99)>=3]; print('residual-messy after Clean:', bad); sys.exit(1 if bad else 0)"

## Visual Verification

Not a visual/layout change — this edits a JS metric, not CSS/HTML/font/density.
Nudge visibility is a pure function of the metric:
`maybeShowCleanNudge` sets `display:none` iff `mapMessiness() < CLEAN_NUDGE_MIN(3)`.
Verified headless that all 6 formerly-residual maps now score `mapMessiness == 0`
after a Clean fixpoint (→ nudge hidden), and that genuinely-messy raw maps
(task-lifecycle 9, verification-gate 11, session-handover 8) still score ≥3
(→ nudge still fires). DOM-rect/logic verification is sufficient here per
CLAUDE.md §Visual Verification (scoped to CSS/layout/font/density/theme changes).

## RCA

**Symptom:** After clicking Clean (or clean-on-import) fully tidies a map, the
Clean nudge keeps showing on 6 corpus maps — offering a fix for a map Clean has
already finished.

**Root cause:** `mapMessiness()` and `alignRowsLane()` disagree on what "tidy"
means. align-rows excludes branch-stack members from row-snapping (by design —
they hold T-093 pitch), but mapMessiness has no such exclusion, so it counts the
resulting pitch-vs-aligned centre offset (1–14px) as a wave. The metric flags
geometry the very same Clean action deliberately produced and will never change.

**Why structurally allowed:** T-100 built mapMessiness as an independent heuristic
without asserting the invariant "Clean output ⇒ mapMessiness == 0". No test pinned
Clean's fixpoint to the nudge's zero, so the two drifted. The raw corpus masked it
(real waves dominated), so it shipped undetected.

**Prevention:** T-101's `bake-clean-layout.py --check` now asserts, headless, that
a Clean fixpoint scores `mapMessiness < 3` on every map — a standing regression
gate on exactly this Clean-vs-metric invariant.

## Recommendation

**Recommendation:** GO (agent work complete; ready for operator review)

**Rationale:** One-line exclusion mirroring align-rows' own `inStack` set, so the
nudge metric and Clean agree on what "tidy" means. All 4 Agent ACs verified
headless: the 6 formerly-residual maps now score 0 after Clean; genuinely-messy
raw maps still fire (task-lifecycle 9, verification-gate 11, session-handover 8),
so no under-firing regression. Pure JS-metric change — no visual/layout risk.

**Evidence:** Commit e099ce8; headless driver confirms 6/6 residual maps → 0 and
3/3 messy maps still ≥3; `diff -q` gallery designer.html clean.

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

## Updates

### 2026-07-05T16:49:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-102-mapmessiness-false-positive-branch-stack.md
- **Context:** Initial task creation

### 2026-07-05T16:49:20Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4fbb7ce4
- **Timestamp:** 2026-07-29T13:13:35Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
