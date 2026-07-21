---
id: T-223
name: "Editor entry-point shadowing: B1 autosave-restore hides server-latest map, no 'open latest saved' action (AEF UX-defect input, operator recurrence)"
description: >
  Editor entry-point shadowing: B1 autosave-restore hides server-latest map, no 'open latest saved' action (AEF UX-defect input, operator recurrence)

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-21T12:49:17Z
last_update: 2026-07-21T13:25:04Z
date_finished: null
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

# T-223: Editor entry-point shadowing: B1 autosave-restore hides server-latest map, no 'open latest saved' action (AEF UX-defect input, operator recurrence)

## Context

AEF UX-defect input (rail offset 115, thread T-2586): the operator's recurring "off-page connectors
not working" report is NOT a seam/connector defect (AEF live-verified the 0.3.0 seam works) — it's
**entry-point shadowing** in the editor. B1 autosave-restore silently replaces the seed with the
operator's last localStorage draft on every `/designer` open (winning over a same-map `?load`
deep-link); an operator who opened a corpus map before new content shipped sees their STALE draft
(same title, no handoff nodes) and concludes "still broken." The "Restored your unsaved work" toast
is easy to miss and its only action is "Start fresh" (blank) — there is **no "open latest saved"**
path. Fix addresses the operator's ACTUAL complaint. Separate from the gated T-218 seam build.
See `[[aef-integration-rail]]`.

## WIP state (2026-07-21, hit 300K budget ceiling mid-fix)

**Done + committed (src/aef-workflow-designer.html):**
- `showToast` extended to support `opts.actions:[{label,onAction}]` (back-compat with legacy `actionLabel`/`onAction`) — for multi-button toasts.
- `showRestoredToast` rewritten: base toast (unchanged "Start fresh") + async `/api/list` check → when the same map id has a saved `latest.{v,ts}`, upgrade toast to offer **"Open latest saved (vN)"** + "Keep draft" + "Start fresh", flagging when server copy is NEWER (via `_tsToMs` normalize). `openProjectMap(m)` loads it. Helpers `_tsToMs`, `_startFresh` added.
- **Verified in Playwright:** page loads clean (only benign favicon 404); confirmed `/api/list` exposes `latest.{v,ts}` (15/25 corpus maps have saved versions); planted an arc-lifecycle draft with older ts.

**REMAINING (one-line fix — blocked by budget gate, apply next session FIRST):**
- **Ordering bug:** `autoLoadStored()` (line ~8785) runs BEFORE `detectSaveApi()` (~8786), so `_apiAvailable` is still false at restore time → my `if (!_apiAvailable || !s || !s.id) return;` bails and the server check never fires (Playwright-confirmed: toast never upgraded; `_apiAvailable` flipped true only after). **Fix:** change that guard to `if (!s || !s.id) return;` — the `fetch('/api/list')` is itself the availability probe (fails → caught → base toast stays). Edit was staged but blocked at 298K.
- Then re-verify: refresh `build/gallery/designer.html` from src, plant arc-lifecycle draft (ts < 1783344902118), reload :8834/designer.html, confirm enriched toast "NEWER saved version (v4)" with 3 buttons; element-screenshot light+dark; read them. Then check ACs + complete.
- **No regression risk in the committed WIP:** base toast + Start fresh behave exactly as before; enriched path is simply dormant until the guard fix.

## Acceptance Criteria

### Agent
- [ ] Verified the current B1 autosave-restore behavior in `src/aef-workflow-designer.html` (autoLoadStored + restore toast) against AEF's diagnosis, with file:line evidence
- [ ] On restore, when a write-capable server is present, the map's server latest version is checked and — if newer than / different from the restored draft — the operator is told a newer saved version exists
- [ ] The restore toast offers an "Open latest saved" action alongside "Start fresh" (not just discard-to-blank)
- [ ] `?load=<id>` / same-map deep-link is honored rather than silently shadowed by a stale autosave draft of a different map (or the shadowing is made visible + reversible)
- [ ] Visual-verified with element-level Playwright screenshots of the restore toast (both actions visible) in at least light+dark; screenshots read back

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

## Updates

### 2026-07-21T12:49:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-223-editor-entry-point-shadowing-b1-autosave.md
- **Context:** Initial task creation
