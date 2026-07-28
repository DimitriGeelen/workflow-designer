---
id: T-274
name: "Re-vendor readiness: unblock the four-concern closure path (upstream coordinates + operator procedure)"
description: >
  Re-vendor readiness: unblock the four-concern closure path (upstream coordinates + operator procedure)

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-28T08:15:36Z
last_update: 2026-07-28T08:18:46Z
date_finished: 2026-07-28T08:18:46Z
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

# T-274: Re-vendor readiness: unblock the four-concern closure path (upstream coordinates + operator procedure)

## Context

Four concerns (G-001, G-004, G-008, G-011) now close on a single operator action: re-vendoring
`.agentic-framework/` from AEF's upstream (their T-2645/T-2646/T-2647 + T-2637/T-2640/T-2641 fixes
all live upstream, confirmed on the rail at 258/259). But the path is NOT currently executable:
`fw update` requires `upstream_repo:` in `.framework.yaml`, which was never configured — the
original vendoring (T-001, 2026-06-04) left no provenance (VERSION reads `dev`). This task makes
the re-vendor a single copy-pasteable operator action: obtain upstream pull coordinates from AEF
over the rail, and write the operator readiness doc (prerequisites, exact commands, post-vendor
checklist incl. shim/shadow deletion and concern flips).

## Acceptance Criteria

### Agent
- [x] Upstream coordinates requested from AEF on the rail (what `upstream_repo` consumers should pin,
      whether a tag/branch is the sanctioned pull point, and whether their fw-upgrade delivers instead) —
      request posted in a dedicated thread with the four-concern context. (Rail offset 262, thread T-274.)
- [x] `docs/reports/T-274-revendor-readiness.md` written: current blocker (missing upstream_repo, VERSION=dev),
      what the re-vendor delivers (per-concern), exact operator procedure (fill-in-coordinates form until
      AEF answers), and the post-vendor checklist (delete lib/dispatch_pause.py shim, delete policy/ shadows,
      re-run local gates, flip G-001/G-004/G-008/G-011 watching→resolved).
- [x] Readiness doc cross-linked from concerns.yaml (one pointer line per affected concern; status fields untouched).
      (4 pointer lines: G-001/G-004/G-008/G-011; YAML parses, 11 concerns.)

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

test -s docs/reports/T-274-revendor-readiness.md
grep -q "T-274-revendor-readiness" .context/project/concerns.yaml
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

### 2026-07-28T08:15:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-274-re-vendor-readiness-unblock-the-four-con.md
- **Context:** Initial task creation

### 2026-07-28 — readiness path built
- **Discovery:** `fw update --check` errors "No upstream_repo in .framework.yaml" — the re-vendor that
  closes G-001/G-004/G-008/G-011 was never executable; original T-001 vendoring left no provenance
  (vendored VERSION = literal `dev`).
- **Rail:** coordinates request posted at offset 262 (thread T-274): upstream_repo value, tagged pull
  point vs master, or their-side `fw upgrade` push. No urgency flagged — concerns just stay watching.
- **Artifact:** docs/reports/T-274-revendor-readiness.md — per-concern delivery table, operator
  procedure (4 copy-pasteable commands incl. --check preview + --rollback), 7-step post-vendor
  checklist (shim/shadow deletion, secret-scan verification, gate re-runs, concern flips).
- **Note:** the dash+bold IW-marker question (rail 260, T-273) is folded into checklist step 4 —
  if canonical rejects `- **IW-N:`, reformat T-155's 3 markers + template BEFORE re-vendor.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-45e25e61
- **Timestamp:** 2026-07-28T08:18:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-28T08:18:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
