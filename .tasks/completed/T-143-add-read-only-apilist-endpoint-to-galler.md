---
id: T-143
name: "Add read-only /api/list endpoint to gallery-serve.py"
description: >
  T-142 GO, build task 1 of 2-3. Add a read-only /api/list endpoint to tools/gallery-serve.py
  returning per map {id,title,sources[],latest,openTarget} — the corpus (rendered/*.bpmn)
  merged with saved maps (.editor-versions/*), resolving each map's latest saved version.
  Shape + cost validated in T-142 Spike 1 (24 maps, 6KB, 4.2ms). Read-only, stdlib-only,
  _valid_id guard, no path traversal; must not disturb T-138 corpus gate. Stdlib-only
  verifier like _gallery-save-allowlist-verify.py.

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
created: 2026-07-08T06:09:39Z
last_update: '2026-08-16T12:33:39Z'
date_finished: 2026-07-08T07:22:33Z
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
      D3: 0
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-143: Add read-only /api/list endpoint to gallery-serve.py

## Context

Build task 1 of the T-142 GO (in-editor Open-from-project browser). Adds the read-only
enumeration endpoint the browser needs. Shape + cost validated in T-142 Spike 1
(`scratchpad/spike1_api_list.py`): 24 maps, 6 KB, 4.2 ms. Backend only — the modal is a
separate build task. See `docs/reports/T-142-in-editor-open-from-project-browser.md`.

## Acceptance Criteria

### Agent
- [x] `GET /api/list` added to `tools/gallery-serve.py` `do_GET`, returning JSON
      `{"maps":[{id,title,sources:[rendered|saved],latest:{v,ts,count}|null,
      openTarget:{kind:'version',v}|{kind:'rendered'}}...]}` — live: 24 maps, 3.8 KB
- [x] Merges the rendered corpus (`examples/aef-processes/rendered/*.bpmn`) with saved maps
      (`.editor-versions/*`); `latest` resolved from each `index.json`; `openTarget` is the
      latest saved version when present, else the rendered baseline — live: 11/24 have saved
      versions (arc-lifecycle → openTarget version v4)
- [x] Read-only and safe: no writes; every id validated via the existing `_valid_id`/`ID_RE`
      guard; no path traversal; reuses `read_index`/`versions_dir` (no logic duplication)
- [x] Does NOT alter existing routes or the POST /api/save corpus gate (T-138) —
      `_gallery-save-allowlist-verify.py` still passes 6/6 unchanged
- [x] New stdlib-only verifier `tools/_gallery-list-verify.py` spins the server on an
      ephemeral port against a temp repo and asserts the shape + latest/openTarget resolution
      + id-safety; exits 0 (12/12)
- [x] `gallery-serve.py` parses (py_compile) and the served gallery still boots (live health OK)

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
python3 -m py_compile tools/gallery-serve.py
grep -q "/api/list" tools/gallery-serve.py
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-save-allowlist-verify.py

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

### 2026-07-08 — merged list with a `sources[]` array (not two separate lists)
- **Chose:** One list where each map carries `sources:[rendered|saved]`, plus `latest` and a
  resolved `openTarget`.
- **Why:** The client renders one browse view; a map that is both a corpus baseline and has
  saved edits is one entry, not two. Keeps the payload small (3.8 KB / 24 maps) and the
  open logic on the server (`openTarget`), so the client just follows it.
- **Rejected:** Separate `corpus`/`saved` arrays — pushes merge + latest-resolution logic
  into the client and duplicates entries for maps that are in both.

## Recommendation

**Recommendation:** GO (finalize — all Agent ACs verified; no Human AC, completes cleanly)

**Rationale:** The read-only `/api/list` endpoint is implemented, documented, and verified
three ways: a new 12/12 stdlib verifier, the T-138 save-gate regression still 6/6, and a
live check on the real corpus (24 maps, 3.8 KB, 11 with saved versions resolving to their
latest). Read-only, reuses existing guards/helpers, no change to existing routes. This is
build task 1 of the T-142 GO; the in-editor Open modal is the next task (T-144).

**Evidence:**
- `python3 tools/_gallery-list-verify.py` → 12/12
- `python3 tools/_gallery-save-allowlist-verify.py` → 6/6 (T-138 intact)
- Live: `curl :8834/api/list` → 24 maps, `arc-lifecycle` openTarget `{version, v:4}`

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-08T06:09:39Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-143-add-read-only-apilist-endpoint-to-galler.md
- **Context:** Initial task creation

### 2026-07-08T07:22:33Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
