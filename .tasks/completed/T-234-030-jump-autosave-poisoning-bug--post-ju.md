---
id: T-234
name: "0.3.0 jump-autosave poisoning bug — post-jump autosave records original deep-link
  src, wrong map renders on revisit (AEF T-2596 RCA, 0.3.1 root fix)"
description: >
  0.3.0 jump-autosave poisoning bug — post-jump autosave records original deep-link
  src, wrong map renders on revisit (AEF T-2596 RCA, 0.3.1 root fix)

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
created: 2026-07-22T06:45:31Z
last_update: '2026-08-16T12:33:45Z'
date_finished: 2026-07-22T10:50:52Z
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
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-234: 0.3.0 jump-autosave poisoning bug — post-jump autosave records original deep-link src, wrong map renders on revisit (AEF T-2596 RCA, 0.3.1 root fix)

## Context

**Peer-reported field bug (AEF T-2596, rail offset 149, operator-reported regression their
side): the 0.3.0 bundle self-poisons its own deep-links.** RCA is AEF's, confirmed against
current src: `jumpToWorkflow` (src/aef-workflow-designer.html:6760) switches maps IN-PLACE
without touching `location ?load`; `autosaveNow` (:8917) stamps `src: currentLoadSrc()`
unconditionally → every post-jump autosave persists `{content: JUMPED-TO map, src: ORIGINAL
deep-link}`; `autoLoadStored` (:8941) restores on `stored-src === ?load` with
`_suppressDeepLink` → the next entry via the SAME deep-link silently renders the WRONG map.
**Repro: open `?load=X` → jump to Y → revisit `?load=X` → renders Y.** The handoff jump
working once is what breaks the deep-link thereafter. AEF neutralized it THEIR side (landing
cards mint a click-time nonce in the load value + hx-boost=false, their 495b5a022) but the
ROOT fix is ours and is requested for the 0.3.1 tag. Affects ANY `?load` consumer of the
bundle. Candidate fixes (choose in-build, record in Decisions): (a) track the deep-link's
adopted map identity (`_loadSrcKey = activeKey` at ?load adoption) and stamp
`src: activeKey === _loadSrcKey ? currentLoadSrc() : null` in autosaveNow — minimal, kills
the cross-map association; (b) per-map autosave records keyed by active map id — bigger,
also fixes multi-map autosave loss. Side note from AEF (no action unless we embed behind
htmx): htmx-boosted anchors navigate off the cached href, discarding onclick href mutations.
See `[[aef-integration-rail]]` offset 149.

## Acceptance Criteria

### Agent
- [x] The poisoning repro is fixed at the ROOT: after `open ?load=X → jumpToWorkflow(Y) → autosave fires`, the persisted autosave record no longer associates Y's content with X's src (either src is nulled/updated on in-place switch, or records are keyed per map) — and revisiting `?load=X` renders X, not Y
- [x] The legitimate B1 restore path still works: no `?load` → last work restored; `?load` matching a stored autosave OF THAT MAP → in-progress edits restored with `_suppressDeepLink`; `?load` differing → deep-link wins untouched (existing behavior, no regression)
- [x] Playwright-verified on the RUNNING :8834 gallery (behavior, not source grep — PL-046): drive the actual repro sequence (open ?load=X, jump to Y, wait past the 700ms autosave debounce, re-enter ?load=X) and assert the rendered map is X; plus the no-regression restore legs
- [x] Redeployed (cp src → build/gallery/designer.html) and the fix verified against the served copy; deployed copy byte-identical to src
- [x] RCA section filled (peer-found field bug — G-019 escalation applies: why could a wrong-map render ship silently? capture prevention, e.g. a repro-sequence Playwright leg in the standing suite); learning recorded if this is a new failure class (bug-fix learning checkpoint — it is: state/url identity drift across in-place navigation)
- [x] Announce on the rail when landed (AEF holds 0.3.1 re-pin on it) — and note the fix commit for the operator's 0.3.1 tag decision (rail offset 155: commit 7390131, 4-leg matrix results, no-schema-change note, nonce-workaround release note)

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

# Fix present in src (behavioral proof was the in-build Playwright 4-leg matrix, PL-046)
grep -q "_loadSrcKey" src/aef-workflow-designer.html
# Deployed copy byte-identical to src
cmp src/aef-workflow-designer.html build/gallery/designer.html
# Served copy carries the fix. NB: the L-387 capture-then-`echo|grep -q` pattern is NOT
# safe at this size — the payload is ~860KB, grep -q exits on first match and echo takes
# SIGPIPE (141) on the still-in-flight write. grep -c consumes the whole stream instead.
test "$(curl -sf http://localhost:8834/designer.html | grep -c "_loadSrcKey")" -ge 1

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

**Symptom:** Opening the designer via a `?load=X` deep-link after having once jumped
(handoff double-click / jumpToWorkflow) to another map Y silently renders Y instead of X.
Field-found by the peer (AEF T-2596, rail offset 149) — their operator's landing-card
deep-links "broke" after the first successful handoff jump.

**Root cause:** `autosaveNow` stamped `src: currentLoadSrc()` UNCONDITIONALLY, while
`jumpToWorkflow` switches the active map in-place without touching `location`. Every
post-jump autosave therefore persisted `{content: Y, src: X's ?load value}` — a false
association between one map's content and another map's URL identity. On the next entry
via `?load=X`, `autoLoadStored` saw stored-src === load, set `_suppressDeepLink`, and
adopted Y's snapshot as if it were in-progress work on X.

**Why structurally allowed:** three individually-verified features (B1 autosave restore
T-127, `?load` deep-link, T-160 jump navigation) form a cross-feature state/url identity
contract that nothing verified end-to-end. All standing guards in tools/ are server-side;
editor behavior is only Playwright-verified ad-hoc inside the task that builds it, never
against feature interactions added later. The framework was blind from T-160's landing
until a peer operator tripped it in tagged 0.3.0 (>7 days) — G-019 applies.

**Prevention:** (1) gap **G-010** registered (concerns.yaml): standing browser-behavior
suite for editor load/persistence paths is the missing structural guard; close criterion
is a shell-runnable 4-leg matrix (this task's repro + the three B1 legs) wired into
Verification/cron. (2) Learning recorded (new failure class: state/URL identity drift
across in-place navigation — any feature that persists a URL-derived identity must
re-derive it at write time from the ACTIVE document, not the session). (3) The fix itself
is structural, not sited: `_loadSrcKey` makes the src-stamp condition explicit at the
single write point, so future in-place switch paths (new "open" affordances) inherit
correct behavior without needing to know about autosave.

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

### 2026-07-22 — Fix shape: candidate (a) `_loadSrcKey` tracking, not (b) per-map records
- **Chose:** Candidate (a): track the map identity adopted FROM the `?load` deep-link
  (`_loadSrcKey = activeKey` at the two adoption sites — deep-link fetch IIFE and the
  same-src autosave-restore branch) and stamp `src` only while `activeKey === _loadSrcKey`
  (else `null`). 4 small edits, single write-point condition.
- **Why:** Kills exactly the false association (content-of-Y ↔ src-of-X) with zero schema
  change: the autosave record shape, AUTOSAVE_KEY, and all three B1 restore branches are
  untouched — post-jump work still restores on a no-`?load` entry (src null = "last work"),
  which is the correct B1 semantic for it. Minimal risk for a 0.3.1 patch release AEF is
  holding on.
- **Rejected:** (b) per-map autosave records (keyed by map id). Bigger win (multi-map
  autosave loss also fixed) but a storage-schema change: migration of existing single-record
  autosaves, restore-priority policy (which map wins a no-?load entry), quota multiplication,
  and a re-verify of every restore/toast path — wrong size for the blocking patch. Filed
  direction stays available; G-010's standing suite is the prerequisite for doing it safely.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-22T06:45:31Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-234-030-jump-autosave-poisoning-bug--post-ju.md
- **Context:** Initial task creation

### 2026-07-22T10:50:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
