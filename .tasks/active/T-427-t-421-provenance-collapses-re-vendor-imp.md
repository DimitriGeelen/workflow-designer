---
id: T-427
name: "T-421 provenance collapses re-vendor imports into authored: any line arriving via a bulk vendor bump is reported as our own drift"
description: >
  T-421 provenance collapses re-vendor imports into authored: any line arriving via a bulk vendor bump is reported as our own drift

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
created: 2026-08-11T11:32:45Z
last_update: 2026-08-11T11:32:45Z
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

# T-427: T-421 provenance collapses re-vendor imports into authored: any line arriving via a bulk vendor bump is reported as our own drift

## Context

T-426 fixed `provenance()` in `tools/_t421-enforcement-claim-drift.py` so the detector
asks "did WE say it?" and not merely "does the tree say this?". The test it uses is
binary: compare the line's introducing commit against the commit that ADDED the file.
Same commit → `inherited`; any later commit → `authored` (ours, reported, exit 1).

**That binary is wrong for any tree that re-vendors.** Found while measuring T-402, not
by re-reading the code:

    file   .agentic-framework/agents/context/budget-gate.sh
    line   152  (the allow-regex)
    added  6b249629  T-001 "AEF setup"                 2026-06-04
    blame  ebf0c721  T-276 "re-vendor .agentic-framework to v1.6.763"

`ebf0c721` is not the seed, so `provenance()` returns **`authored`** — "832 wrote this
line" — for a line that arrived verbatim from upstream in a bulk vendor bump. Every
upstream line touched by any re-vendor since setup is misattributed the same way.

This is the *identical* wrong-owner conclusion T-421 was repaired to stop making, one
layer down. The T-426 fix moved the question from per-file to per-line and stopped
there; the missing axis is not WHERE the line lives or WHEN it arrived, but **HOW it
arrived** — authored here, or imported wholesale.

**The discriminator, measured on this tree** (not assumed):

    ebf0c721  re-vendor v1.6.763     1367 files    <- import
    6b249629  T-001 setup            2241 files    <- import
    86a256fd  T-401 (edits vendored)    6 files    <- authored, under .agentic-framework/
    92021feb  T-426                      3 files    <- authored
    3fcb11c1  T-426 correction           1 file    <- authored

Three orders of magnitude, no overlap. Note 86a256fd: a real local edit to a *vendored*
file. It must stay `authored` — which is precisely why the path test (rejected in T-426)
is still the wrong instrument and a breadth-of-commit test is the right one.

**Consequence if unfixed:** the detector's whole output is an ownership claim. A wrong
`authored` sends the reader to fix upstream's bytes in their own tree — the fork that
AEF's DM §1 (offset 522) explicitly told us not to do, and that T-422 was withdrawn over.
The fix must fail toward `authored` (loud) on any ambiguity, never toward silence.

## Acceptance Criteria

### Agent
- [x] **The defect is reproduced against the real tree before the fix**, using a claim
      line whose blame commit is a re-vendor: `provenance()` returns `authored` for
      `.agentic-framework/agents/context/budget-gate.sh:152`. Recorded as a probe, not
      as a code-read — the T-426 lesson is that my prediction of my own instrument is
      the thing under test.
      **REPRODUCED 2026-08-11, by probe.** `provenance('.agentic-framework/agents/
      context/budget-gate.sh', 152)` returned **`authored`** before the fix — i.e. "832
      wrote this line" about bytes that arrived in re-vendor `ebf0c721`. Control in the
      same run: `.tasks/templates/default.md:13` -> `inherited` (correct). After the
      fix the same two probes return `vendored` / `inherited`.
- [x] **A third verdict `vendored` exists** and is distinct in the report from both
      `authored` and `inherited`, with its own marker string, because the remedy differs:
      `authored` → fix or delete here; `inherited`/`vendored` → attribute upstream, pin,
      do not fork.
      **DONE.** Report now carries three markers — `[authored]`, `[inherited at seed]`,
      `[vendored import]` — and the disposition line distinguishes "claimed by SEEDED
      prose" from "claimed by IMPORTED prose". Kept as separate buckets rather than one
      "not ours" set: same remedy, different evidence, and collapsing them would hide
      exactly the case that produced this fix.
- [x] **The discriminator is breadth-of-introducing-commit, not path.** A commit that
      touches ≥ N files is an import; anything smaller is authorship. The threshold and
      the measured margin are stated in the source, and `86a256fd` (6 files, edits files
      under `.agentic-framework/`) is asserted to remain `authored` so the path test
      cannot creep back in.
      **DONE — `IMPORT_BREADTH = 200`**, with the measured margin recorded in the source:
      imports 1367 / 2241 files, authored commits 6 / 3 / 1. No overlap, so the threshold
      is not delicate. `86a256fd` (T-401, **6 files, editing files under
      `.agentic-framework/`**) measures at breadth 6 -> `authored`, which is the row that
      proves the path test cannot substitute: it is a real local edit to a vendored file
      and the path test would call it upstream's.
- [x] **Ambiguity fails LOUD.** Any git failure, missing history, or unreadable commit
      still yields `authored` — the reporting direction. A detector that goes quiet when
      it cannot measure is the failure this whole line of work is about (M7 already pins
      this for the no-history case; the new path must not weaken it).
      **DONE.** `_commit_breadth()` returns `None` on any git failure and `provenance()`
      maps that to `authored` — the reporting direction. M7 (no git history at all)
      still returns the claim as a finding. The known quiet edge is stated in the source
      rather than left implicit: an authored commit touching 200+ files would read as an
      import.
- [x] **Mutation teeth extended and both directions asserted.** A one-sided test passes
      on an implementation that calls everything `vendored`, i.e. one that can never
      report anything. Scratch tree with real git history: a bulk-import commit yields
      `vendored`, a small later commit yields `authored`, seed still yields `inherited`.
      **DONE — 13 -> 16 legs, all green.** M8a/M8b/M8c assert all three verdicts **in one
      scratch tree with real git history** (seed -> 250-file bulk import -> 1-file edit).
      One tree, not three: separate trees would pass on an implementation returning a
      constant per-tree, and the point of the third verdict is that it coexists with the
      other two. Teeth proven by mutation: with `IMPORT_BREADTH` raised out of reach,
      **M8a fails AND M8b fails** — the vendored claim reappears as our drift, which is
      the defect itself, caught by the leg.
- [x] **The parser-anchor lesson from T-426 is honoured**: the new marker is asserted to
      exist by its own leg, so a rewording fails in one line instead of silently zeroing
      the legs that key on it.
      **DONE.** `vendored()` keys on `[vendored import]`, its own parser rather than a
      widened `upstream()` awk. The marker's existence is asserted transitively by M8a,
      which must return a name THROUGH it — so a rewording turns M8a red instead of
      silently returning empty (the exact failure T-426's P0 was added for).
- [x] **No regression**: `bash tools/_t421-drift-mutation-check.sh` green at its new
      count with every pre-existing leg still passing, and the real tree's verdict for
      `check-arc-id` unchanged (it is `inherited` at seed and must stay so).

      **DONE.** `bash tools/_t421-drift-mutation-check.sh` -> **PASS 16/16**, every
      pre-existing leg (P0, P1, N1, N2, M1-M7) still green. Real-tree verdict unchanged:
      `check-arc-id` still `[inherited at seed]`, still `PASS (with 1 upstream item(s))`,
      exit 0.
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

# T-427. Single commands whose own exit code is the verdict (T-352 errexit rule).
bash tools/_t421-drift-mutation-check.sh
# The three verdict markers must all still be reachable from the report writer.
grep -q "\[vendored import\]" tools/_t421-enforcement-claim-drift.py
grep -q "\[inherited at seed\]" tools/_t421-enforcement-claim-drift.py
# The path test must not creep back in: a 6-file commit editing vendored files stays ours.
python3 -c "import importlib.util as u; s=u.spec_from_file_location('d','tools/_t421-enforcement-claim-drift.py'); m=u.module_from_spec(s); s.loader.exec_module(m); import sys; sys.exit(0 if m._commit_breadth('86a256fd') < m.IMPORT_BREADTH else 1)"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
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

### 2026-08-11T11:32:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-427-t-421-provenance-collapses-re-vendor-imp.md
- **Context:** Initial task creation
