---
id: T-261
name: "Annotate intake wire-shape reconciliation: accept AEF live overlay payload (nodes/severity/text) + cut 0.7.1"
description: >
  Contract-shape divergence caught via crossed rail messages (219/220) minutes after the 0.7.0 cut: AEF's live overlay stack (Slice A /api/overlay + Slice B wrapper, both LIVE on :3001) posts {type:'aef:annotate', map, generated, nodes:[{uid,badge,text,severity}]} verbatim (severity info|warn|alert) — 0.7.0's intake reads annotations:[{uid,badge,tone,title}], so their re-pin would silently no-op. Real payload curled and pinned from their invitation at 219. Fix: tolerant intake — accept nodes[] (wire-canonical, theirs) AND annotations[] (documented alias); map severity->tone (info->info, warn->warn, alert->err), text->title tooltip fallback; harness leg asserts against the REAL curled payload bytes; protocol doc updated to document the wire-canonical shape first. Then cut 0.7.1, tag, announce, so their re-pin lights badges first try. One bug = one task; RCA required (shape defined without re-verifying the 197 advisory bytes).

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
created: 2026-07-27T19:16:35Z
last_update: 2026-07-27T19:16:36Z
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

# T-261: Annotate intake wire-shape reconciliation: accept AEF live overlay payload (nodes/severity/text) + cut 0.7.1

## Context

AEF rail 219/220: their overlay stack is LIVE and posts
`{type:'aef:annotate', map, generated, nodes:[{uid,badge,text,severity}]}` verbatim;
0.7.0's intake reads `annotations[]/tone/title` → silent no-op on re-pin. Real
payload curled from their :3001 endpoint (their explicit invitation at 219).

## Acceptance Criteria

### Agent
- [x] Tolerant intake: aef:annotate handler accepts `nodes[]` (wire-canonical, AEF
      live shape) AND `annotations[]` (0.7.0 documented alias); per-entry fields
      unified — badge (required), severity info|warn|alert OR tone info|ok|warn|err
      (alert→err), text OR title → tooltip. All other 0.7.0 guards unchanged
      (parent-source, unknown-uid silent-ignore, clamps, text-node-only).
- [x] Harness extended with a leg that replays the REAL curled AEF payload bytes
      (tests/fixtures/aef-overlay/live-payload-2026-07-27.json) against a map whose
      nodes carry two of its uids — badges render with mapped tones; suite green.
- [x] Protocol doc §Annotation seam rewritten: wire-canonical shape (nodes/severity/
      text) documented FIRST as what AEF's wrapper posts; annotations/tone/title kept
      as accepted alias.
- [ ] Release 0.7.1 cut clean (immutability guard green, render gate PASS), tagged
      designer-v0.7.1, pushed with tag, announced on rail (markers + "re-pin 0.7.1
      not 0.7.0"), acked to frontier.

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

**Symptom:** 0.7.0's aef:annotate intake reads `annotations[]/tone/title`; AEF's
live overlay stack posts `nodes[]/severity/text` verbatim — on their re-pin the seam
would light up as a silent no-op (zero badges, no error).

**Root cause:** T-258 defined the payload field names from memory of the rail-197
advisory instead of re-reading the advisory bytes (or curling their then-already-live
Slice A endpoint). Both sides believed they implemented "the 197 shape".

**Why structurally allowed:** The T-258 harness validated the designer against the
designer's OWN payload definition — self-consistent, like a fixed-point test; nothing
validated against the peer's actual emission. The rail crossing (their 219/220 posted
while 0.7.0 was being cut) surfaced it within minutes, but only by luck of timing.

**Prevention:** The harness now replays the PINNED REAL peer payload
(tests/fixtures/aef-overlay/live-payload-2026-07-27.json) — the same class of guard
as the T-257 byte-pair fixtures: peer bytes, not self-authored bytes, are the
contract test input. Drift in their feed shape now fails the suite locally.


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

### 2026-07-27T19:16:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-261-annotate-intake-wire-shape-reconciliatio.md
- **Context:** Initial task creation

### 2026-07-27T19:16:36Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
