---
id: T-808
name: "Render the product version in the designer UI (F-10)"
description: >
  Value review T-742 finding F-10: no product version string renders anywhere in the designer UI. This is the instrument whose absence made F-01 — served bytes four releases behind src — invisible from inside the product for weeks. The operator could not tell which build they were looking at. Add a visible version string to the UI, sourced so it cannot silently drift from VERSION.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [scripts/release-designer.sh, src/aef-workflow-designer.html, tools/_t808-version-parity.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T12:40:40Z
last_update: 2026-09-22T12:51:39Z
date_finished: 2026-09-22T12:51:39Z
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

# T-808: Render the product version in the designer UI (F-10)

## Context

Value review T-742, finding **F-10** (`docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md`):
no product version string rendered anywhere in the designer UI. That absence is why F-01 —
served bytes four releases behind `src/` — stayed invisible from inside the product for weeks,
and it cashed out as a field bug report (T-293) that was *"a faithful test of old code"* (FP-009).

**The obvious implementation was already rejected, by name.** T-399, in `src` itself:

> "exporterVersion is DELIBERATELY NOT EMITTED. src carries no version constant, so sourcing it
> would mean a second copy of VERSION living inside this file, kept in step with the real one by
> good intentions — the exact duplicate-constant class T-361 exists to prevent... if a
> per-release marker is ever wanted it needs build-time substitution and a guard, which is a
> separate task."

This is that separate task, and it takes the second half of that sentence seriously: the
objection is not to a constant, it is to an *unguarded* constant.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `src/aef-workflow-designer.html` carries a single `APP_VERSION` constant whose value equals the `VERSION` file
- [x] The version renders visibly in the header, in a class of its own — NOT the orphaned `.brand-version`, which T-158 retired and which meant the *workflow's* contract version, not the app's
- [x] A mechanical guard asserts `APP_VERSION == VERSION`; drift is a hard failure, not a warning
- [x] The guard is wired into `scripts/release-designer.sh` and fires BEFORE any write to `dist/`, so a drifted release is refused rather than cut and then noticed
- [x] CONTROL: the guard is proven to FAIL when the two disagree, by actually making them disagree in a throwaway copy — a guard that has only ever been seen passing is not known to work (PL-206)
- [x] The artifact stays byte-identical to src: `release-designer.sh`'s `diff -q SRC ARTIFACT` contract is untouched, so no build-time substitution is introduced
- [x] Visual verification: the rendered header is screenshotted and read with the Read tool, in every visual mode this change can affect, confirming the string is legible rather than merely present in the DOM. (Written as "both themes" before measuring; the designer has exactly ONE appearance — `--text-dim`/`--surface-3` each defined once, no `data-theme`, no `prefers-color-scheme`, no density or font modes — so the matrix is one screenshot. Corrected rather than left, because an AC naming a mode that does not exist can only be satisfied by pretending.)


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-808 legs. Each line's exit code is its own verdict; no chaining. ---
./tools/_t808-version-parity.sh
test -x tools/_t808-version-parity.sh
test "$(grep -c '^const APP_VERSION = ' src/aef-workflow-designer.html)" = "1"
grep -q 'id="brand-appversion"' src/aef-workflow-designer.html
grep -q 'brand-appversion' src/aef-workflow-designer.html
grep -q '_t808-version-parity.sh' scripts/release-designer.sh
# THE CONTROL, inline and permanent (PL-206): the guard must FAIL on a drifted copy.
# A leg that only ever sees the guard pass cannot tell a working guard from an inert one.
# Runs entirely in a throwaway dir; the live tree is never mutated.
bash -c 'd=$(mktemp -d); mkdir -p "$d/src" "$d/tools"; cp src/aef-workflow-designer.html "$d/src/"; cp tools/_t808-version-parity.sh "$d/tools/"; echo 9.9.9 > "$d/VERSION"; if T808_REPO_ROOT="$d" bash "$d/tools/_t808-version-parity.sh" >/dev/null 2>&1; then rm -rf "$d"; exit 1; else rm -rf "$d"; exit 0; fi'
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
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

### 2026-09-22 — A guarded literal, not build-time substitution

- **Chose:** a single `APP_VERSION` literal in `src/`, rendered in the header, with
  `tools/_t808-version-parity.sh` wired into `release-designer.sh` ahead of every write to
  `dist/`. Fail-closed, and deliberately with no bypass env var.
- **Why:** `release-designer.sh` asserts `diff -q SRC ARTIFACT` — the released artifact IS the
  source byte for byte, and AEF pins that sha256. Build-time substitution, which T-399 named as
  the route, would break that contract for the sake of a header string. A literal preserves it;
  the guard is what makes the literal safe. T-399's real objection was to a duplicate "kept in
  step by good intentions" — a gate that refuses the release answers it.
- **Rejected — build-time substitution:** would end the byte-identity contract AEF depends on.
  Restructuring the release script's core guarantee is not proportionate to rendering a version.
- **Rejected — fetching VERSION at runtime:** the designer is a single-file artifact, opened
  standalone and vendored into AEF. A fetch fails in exactly the deployments that matter.
- **Rejected — reusing `.brand-version`:** it is orphaned CSS from T-158, and it meant the
  *workflow's* contract version, not the app's. One class name, two meanings, and T-158's
  tombstone comment would read as if the old badge were back.
- **Consequence handled:** adding the constant made T-399's own comment false — it opened
  "src carries no version constant". Corrected in the same edit rather than left, because a
  comment whose claim has quietly stopped being true is the T-361 defect itself, and this exact
  block has twice been reviewed for *where* it appears without anyone asking whether it was
  *true*. `exporterVersion` is still not emitted: that changes bytes AEF pins and is theirs to
  agree to.

## Visual Verification

Screenshot: `.playwright-mcp/t808-header-light.png` — header element, read with the Read tool,
not inferred from the DOM. `v0.12.0` renders as a muted monospace pill between "Workflow
Designer" and the separator; legible, unobtrusive, not colliding with adjacent controls.

**Modes covered: all of them, and that is measured rather than assumed.** The designer has a
single appearance — `--text-dim` and `--surface-3` (the two tokens this badge uses) are each
defined exactly once, there are no `data-theme` attributes, no `prefers-color-scheme` query, and
zero density/font-mode switching anywhere in `src`. So one screenshot is the whole matrix here.

Two console errors present and both pre-existing/environmental: `/api/health` 404 (the documented
`detectSaveApi` probe, which is *supposed* to fail without the gallery server) and a missing
`favicon.ico` on the static preview server. Neither touches `APP_VERSION`.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-808 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T12:40:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-808-render-the-product-version-in-the-design.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b25fdc97
- **Timestamp:** 2026-09-22T12:51:40Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `rm -rf`

### 2026-09-22T12:51:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
