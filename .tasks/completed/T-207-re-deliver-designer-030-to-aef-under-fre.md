---
id: T-207
name: "Re-deliver designer 0.3.0 to AEF under fresh transfer-id"
description: >
  Re-deliver designer 0.3.0 to AEF under fresh transfer-id

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
created: 2026-07-19T08:51:08Z
last_update: '2026-08-16T13:57:18Z'
date_finished: 2026-07-19T12:57:48Z
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
  - ts: '2026-08-16T12:33:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 3
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=3 (body:portability-abstraction); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:dist/MANIFEST.yaml,dist/aef-workflow-designer-0.3.0.html); tier=2 
      (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-207: Re-deliver designer 0.3.0 to AEF under fresh transfer-id

## Context

The T-205 delivery of designer 0.3.0 to AEF was hub-accepted (`ok:true`) but never
reassembled on AEF's end — AEF (the recipient) discovered it: `file_receive` on target
`aef` returned "incomplete transfer — got 17/1 chunks for xfer-mcp-3273116" (rail offset
68). Root cause (AEF offset 69): **transfer-id collision** — the two back-to-back
`file_send` calls in the T-205/T-206 session (0.3.0 html @ 17 chunks, then the fixture @
1 chunk) both auto-minted the SAME `transfer_id xfer-mcp-3273116`; `file_receive`
reassembles keyed by that id, blending the two → "17/1 chunks." This task re-delivers
0.3.0 alone, from a fresh session, so the auto-minted id is distinct. Arc:
designer-authoring-surface. Blocks AEF's T-2546 re-pin.

## Acceptance Criteria

### Agent
- [x] `dist/aef-workflow-designer-0.3.0.html` sha256 re-verified == `dist/MANIFEST.yaml` pin (`36be033d…`) before send
- [x] `file_send` hub-accepted under a FRESH `transfer_id` (`xfer-mcp-3313260`), distinct from the collided `xfer-mcp-3273116`
- [x] rail notice posted (offset 70) with the fresh id + pin + explicit reassembly-verify request (hub-accepted ≠ delivered)
- [x] transfer-id-reuse failure class captured as a learning

<!-- External gate SATISFIED (2026-07-19, rail offsets 71 + 72): AEF file_receive'd
     the 0.3.0 under xfer-mcp-3313260, independently sha256'd the landed bytes
     (36be033d…, 826643 bytes) == pin → MATCH; then `fw designer sync` installed it
     read-only, Watchtower /designer serves it byte-exact (served sha == pin), offline-
     hardening reconfirmed on served bytes, pin bumped to 0.3.0, AEF T-2546 CLOSED. The
     recipient-confirmed-before-done bar (T-205 lesson) is met — safe to complete.
     Note: the feared session-constant-id collision did NOT bite here — AEF drained the
     0.3.0 before the later fixture send reused the id (see PL-039 correction). -->

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

# The delivered bytes must still equal the pin the recipient checks against.
test "$(sha256sum dist/aef-workflow-designer-0.3.0.html | cut -d' ' -f1)" = "36be033d66aa1c159a9e75df674f02032eb9f308882af288fad909e6d754a4bb"

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

**Symptom:** designer 0.3.0 was reported delivered to AEF (T-205, `ok:true`), but AEF's
`file_receive` on target `aef` returned "incomplete transfer — got 17/1 chunks for
xfer-mcp-3273116"; AEF's vendored path stayed 0.2.0. The delivery silently never landed.

**Root cause:** **transfer-id collision.** The MCP `file_send` gives the caller no
control over `transfer_id` and auto-mints it from a per-process counter. Two back-to-back
sends in the T-205/T-206 session — 0.3.0 html (17 chunks) then the shared fixture (1
chunk) — drew the SAME id `xfer-mcp-3273116`. `file_receive` reassembles the most recent
file keyed by transfer_id, so it blended the 17-chunk and 1-chunk streams under one id →
integrity check saw "17/1 chunks" and rejected. Content was never at fault (local sha
matched the pin before both sends).

**Why structurally allowed:** (1) `file_send` returns `ok:true` on hub-acceptance, which
is NOT delivery — the T-205 ACs treated hub-acceptance as the terminal state (with a
caveat), so nothing on the 832 side would ever notice a reassembly failure; only the
recipient can. (2) The transfer protocol reuses ids within a session and exposes no knob
to force a fresh one, so a caller doing legitimate back-to-back sends has no way to avoid
the collision. This is termlink territory (T-2363) — flagged upstream, not fixable here.

**Prevention:** (a) captured as learning [[filesend-transfer-id-reuse]] — never do two
`file_send` calls back-to-back in one session against the same target; space them across
sessions or interleave a rail round-trip so the counter advances. (b) The delivery is not
considered done until the RECIPIENT sha-verifies the reassembled bytes on the rail — this
task deliberately stays open on that external confirmation rather than completing on
`ok:true`, closing the T-205 over-claim gap.

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

### 2026-07-19T08:51:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-207-re-deliver-designer-030-to-aef-under-fre.md
- **Context:** Initial task creation

### 2026-07-19T12:57:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
