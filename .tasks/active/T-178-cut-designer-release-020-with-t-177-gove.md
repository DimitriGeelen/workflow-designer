---
id: T-178
name: "Cut designer release 0.2.0 with T-177 governance fields and deliver to AEF"
description: >
  Cut designer release 0.2.0 with T-177 governance fields and deliver to AEF

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-10T20:58:44Z
last_update: 2026-07-10T21:33:21Z
date_finished: 2026-07-10T21:01:10Z
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

# T-178: Cut designer release 0.2.0 with T-177 governance fields and deliver to AEF

## Context

T-177 added `horizon`/`workflowType`/`owner` emission to `src/`, but the live AEF-served designer at
`:3001/designer` is the pinned `0.1.0` build and does NOT have them (verified live 2026-07-10: src sha
`e301986b…` ≠ pinned `d0e0177c…`). This task cuts release `0.2.0` (deterministic build of current src),
delivers it to AEF via the proven `file_send` channel, so AEF can re-pin and the capability goes live.
Release-then-repin cycle per `docs/aef-designer-integration-protocol.md`.

## Acceptance Criteria

### Agent
- [x] `VERSION` bumped to `0.2.0`.
- [x] `scripts/release-designer.sh` run: `dist/aef-workflow-designer-0.2.0.html` produced, byte-identical to `src/`.
- [x] `dist/MANIFEST.yaml` updated: `latest: "0.2.0"`, `sha256` matches the artifact, matches current `src` sha (`e301986b…`).
- [x] Deterministic: re-running the release script yields an identical artifact sha256 (`e301986b…`).
- [x] `0.2.0` artifact delivered to the AEF session via `termlink file_send`; returned sha256 == manifest sha256 (`e301986b…`, 395178 bytes, xfer-mcp-3173253).

### Human
- [x] [REVIEW] T-177 governance fields live on `:3001/designer` after AEF re-pins
      **Steps:**
      1. Advance the AEF session to re-pin: it runs `fw designer sync` against the delivered `0.2.0` (sha256-verifies).
      2. Signal 832 when re-pin is done — the agent will run a Playwright check on `http://192.168.10.107:3001/designer`.
      3. (Or check yourself:) open a task node's inspector → EXTENSIONS shows Horizon / Workflow type / Owner dropdowns.
      **Expected:** the three dropdowns appear on task-like nodes; `AEF_FIELDS.scriptTask` includes `horizon`.
      **If not:** the re-pin didn't take — confirm AEF's pin sha256 == `dist/MANIFEST.yaml` sha256 for 0.2.0.

## Recommendation

**Recommendation:** GO (advance AEF to re-pin 0.2.0)
**Rationale:** The 832 half is verified complete — deterministic release cut, delivered to AEF with sha256
matching the manifest byte-for-byte. The only remaining step is mechanical: AEF runs `fw designer sync`
against the delivered artifact (sha256-gated, rejects on mismatch). No judgment call in the re-pin itself;
the one genuine human action is deciding *when* to advance the AEF session. Once re-pinned, T-177's
governance dropdowns go live on `:3001/designer`.
**Evidence:**
- `dist/MANIFEST.yaml` sha256 `e301986b…` == artifact == delivered `file_send` sha256 (xfer-mcp-3173253, 395178 bytes)
- Deterministic build confirmed (re-run identical sha256)
- T-177 fields verified in-source (round-trip + parity + inspector screenshot, commit 0ebb8f7/71ce0e4)

**LIVE VERIFICATION — 2026-07-10T21:29Z (re-pin confirmed):**
AEF re-pinned 0.2.0; the live capability is now Playwright-verified end-to-end. The Human [REVIEW] AC
above is satisfied by this evidence (operator checks the box + runs `work-completed` to finalize):
- `curl :3001/designer` → sha256 `e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a`,
  395178 bytes — **byte-identical** to the delivered 0.2.0 (was `d0e0177c…` 0.1.0 before re-pin).
- Playwright render (not curl): serviceTask "Decompose" inspector → EXTENSIONS (aef:) block renders
  **Horizon** (now/next/later), **Workflow type** (build/test/refactor/decommission/specification/design/
  inception), **Owner** (human/agent) — all three T-177 dropdowns, correct option sets.
- Visual: `docs/reports/assets/T-178-live-inspector-governance-fields.png` (screenshot READ, dropdowns present).
- Non-fatal: 1 console error `GET /api/health → 404` (page renders fully; captured for T-179's render-check).

## Verification

python3 tests/test_editor_bridge_meta_parity.py
# ── REPAIRED BY T-354 (2026-08-03) ──────────────────────────────────────────────
# Three lines here were RED and blocking this task's completion:
#     grep -q '^0.2.0$' VERSION
#     m=$(grep '^sha256:' dist/MANIFEST.yaml | …); a=$(sha256sum …-0.2.0.html | …); [ "$m" = "$a" ]
#     grep -q 'latest: "0.2.0"' dist/MANIFEST.yaml
# All three asserted "the project's CURRENT release state is 0.2.0" — VERSION,
# MANIFEST's `latest:`, and MANIFEST's `sha256:`, which always names the LATEST
# release (now 0.8.0, and internally correct: the field matches the 0.8.0 artifact
# byte for byte). Each was true only in the moment 0.2.0 was latest and has been
# false through the eight releases since. G-015 shape — a gate asserting a global,
# always-moving property.
#
# THIS IS NOT A WEAKENED GATE. The artifact is intact: dist/…-0.2.0.html still
# hashes to e301986b…, the sha this task recorded at release time (AC#2/AC#3) and
# which AEF independently confirmed on re-pin. So the three lines were WRONG —
# asserting a property this task never durably had — rather than correctly
# reporting a regression. The property they were reaching for is asserted
# permanently below: the artifact this task shipped is present and unmodified.
# VERSION and `latest:` have no permanent equivalent (they legitimately move) and
# the sha check subsumes what they stood as evidence for.
test -f dist/aef-workflow-designer-0.2.0.html
echo "e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a  dist/aef-workflow-designer-0.2.0.html" | sha256sum -c --status -

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

### 2026-07-10T20:58:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-178-cut-designer-release-020-with-t-177-gove.md
- **Context:** Initial task creation

### 2026-07-10T21:01:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b45bc8ec
- **Timestamp:** 2026-07-27T21:20:19Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — `scripts/release-designer.sh` run: `dist/aef-workflow-designer-0.2.0.html` produced, byte-identical to `src/`.
  - **AC-verify-mismatch** (narrow, heuristic) — `path=scripts/release-designer.sh in: `scripts/release-designer.sh` run: `dist/aef-workflow-designer-0.2.0.html` produced, byte-identical to `src/`.`
