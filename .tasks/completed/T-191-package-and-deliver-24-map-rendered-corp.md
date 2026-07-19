---
id: T-191
name: "Package and deliver 24-map rendered corpus to AEF as rail fixture drop (T-559 boundary)"
description: >
  Package and deliver 24-map rendered corpus to AEF as rail fixture drop (T-559 boundary)

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
created: 2026-07-12T13:12:21Z
last_update: 2026-07-12T13:19:33Z
date_finished: 2026-07-12T13:19:33Z
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

# T-191: Package and deliver 24-map rendered corpus to AEF as rail fixture drop (T-559 boundary)

## Context

AEF explicitly requested (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` offset 28) that 832 **package** the 24
rendered `.bpmn` + README as a fixture drop on the rail — pull-from-832-HEAD is impossible for AEF because of
the project-boundary (T-559): AEF has no cross-repo read into `/opt/832`. 832 is source-of-truth and ships
the rendered corpus as a vendored fixture (established pattern, per rail offset 23). Content/ids are canonical;
geometry may re-vendor once T-101 (Clean-layout bake) is human-reviewed — AEF accepted one re-vendor (offset 28).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Package built under `build/aef-corpus-drop/`: a single `aef-rendered-corpus-11e2826.tar.gz` containing all 24 rendered `.bpmn` + `README.md` + `MANIFEST.txt` (HEAD sha, count) + `MANIFEST.sha256` (per-file sha256)
- [x] Integrity: the package is sourced from git HEAD (NOT the dirty working tree — see Decision), count = 24, staged copies self-consistent, and every staged file byte-matches its HEAD blob (`git hash-object` == `HEAD:<path>`)
- [x] Delivered to AEF over the termlink chunked file transfer — transfer_id `xfer-mcp-2054011` → session `tl-dlwor5gh` (aef); archive SHA256 `cbb318ff19e1ee7f094a5f8dae0c66a531f59dff12236e97f3cb69a42d73eb6c`
- [x] Rail message posted (offset 31) with: archive filename + SHA256, 832 HEAD `11e2826`, file count, `termlink file_receive` instructions, and the T-101 re-vendor caveat

### Human — none (fully agent-verifiable; delivery + integrity are mechanical)

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

# Package holds the canonical 24-map set + README (sourced from git HEAD, NOT the working tree —
# 3 maps carry uncommitted in-flight T-101/T-105 edits that must NOT ship as canonical)
test "$(ls build/aef-corpus-drop/*.bpmn | wc -l)" -eq 24
test -f build/aef-corpus-drop/README.md
ls build/aef-corpus-drop/aef-rendered-corpus-*.tar.gz
test "$(wc -l < build/aef-corpus-drop/MANIFEST.sha256)" -eq 25
# Staged copies are self-consistent (tarball integrity)
bash -c 'cd build/aef-corpus-drop && sha256sum -c MANIFEST.sha256'
# Every staged file byte-matches its HEAD blob (proves drop == HEAD, immune to a dirty working tree)
bash -c 'cd /opt/832-Workflow-designer && for f in $(git ls-tree --name-only HEAD examples/aef-processes/rendered | grep -E "\.(bpmn|md)$"); do [ "$(git hash-object build/aef-corpus-drop/$(basename $f))" = "$(git rev-parse HEAD:$f)" ] || { echo "MISMATCH $f"; exit 1; }; done; echo HEAD-match'

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

### 2026-07-12 — Package from git HEAD, not the working tree
- **Chose:** Source the drop from `git archive HEAD` (canonical committed corpus).
- **Why:** On packaging, the integrity check surfaced that 3 maps (audit-process, review-emission, verification-gate) carry UNCOMMITTED working-tree edits (703 ins / 486 del, touching aef:uid/name/geometry) — in-flight, unreviewed T-101 Clean re-bake / T-105 edge-label work from a prior session. The corpus AEF vendors must be the git-tracked canonical set; shipping unreviewed working-tree geometry as canonical would violate the "832 ships reviewed fixtures" contract (rail offsets 23/26). AEF explicitly accepted a re-vendor once T-101 lands (offset 28).
- **Rejected:** (a) Package the working tree — would deliver unreviewed geometry as canonical. (b) Commit/revert the 3 dirty files to clean the tree — they are a prior session's in-flight work; not mine to commit or discard without the owner/operator. Left untouched.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-12T13:12:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-191-package-and-deliver-24-map-rendered-corp.md
- **Context:** Initial task creation

### 2026-07-12T13:19:33Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
