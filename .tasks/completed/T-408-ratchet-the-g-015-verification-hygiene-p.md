---
id: T-408
name: "Ratchet the G-015 verification-hygiene population: grandfather the 85 known
  carriers, fail on any new one"
description: >
  The G-015 carrier population is growing under an open gap: the register measured
  11 hard-coded-port verification lines on 2026-08-02; today there are 17 (75 serve-root-diff
  lines unchanged, 85 distinct task files). CLAUDE.md's ban on hard-coded ports is
  prose read by nothing, and _t350-verification-hygiene.py checks a single task by
  ID. Build a tree-wide ratchet: baseline the known carriers, fail only on NEW ones,
  so leg 1 (the convention change) stays the operator's ruling while the population
  stops growing silently.

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
created: 2026-08-09T10:47:56Z
last_update: '2026-08-16T14:33:34Z'
date_finished: 2026-08-09T10:54:17Z
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
  - ts: '2026-08-16T12:33:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:build/gallery/designer.html,src/aef-workflow-designer.html,tools/_t350-verification-hygiene.py,tools/_t352-p011-errexit-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:55Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:build/gallery/designer.html,src/aef-workflow-designer.html,tools/_t350-verification-hygiene.py,tools/_t408-hygiene-teeth.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-408: Ratchet the G-015 verification-hygiene population: grandfather the 85 known carriers, fail on any new one

## Context

G-015 records that 75 `## Verification` lines assert a GLOBAL, always-moving
property (`diff src/aef-workflow-designer.html build/gallery/designer.html`) plus
11 more that hard-code a port, and that the remedy has two legs. **Leg 2 is done**
(T-350 gave `serve-gallery.sh` a `--build-only` path). **Leg 1 — narrowing or
dropping the convention across 75 lines — is a convention change the register
explicitly reserves for the operator:** *"NOT APPLIED. T-093/T-102/T-105 gates
belong to their owners... Reported with the measurement so the operator can rule."*
This task touches neither leg.

It closes the third thing the register names and neither leg covers:

> *"nothing in the tree stops the next author writing :3001, and CLAUDE.md's ban on
> hard-coded ports is prose, read by nothing — exactly the status of AEF's own
> T-1376 ban."*

**That is no longer hypothetical.** Re-measured today against the register's own
2026-08-02 numbers:

| carrier | 2026-08-02 (register) | 2026-08-09 (now) |
|---|---|---|
| serve-root `diff`/`cmp` lines | 75 | **75** (unchanged) |
| hard-coded port lines | 11 | **17** (+6 in 7 days) |

The prose ban held zero of the six. The population grows silently because nothing
reads it: `tools/_t350-verification-hygiene.py` checks exactly ONE task by ID.

**Approach — a ratchet, not a sweep.** Baseline the 85 currently-carrying task
files; fail only on a carrier that is not in the baseline. This keeps leg 1 with
the operator (no existing line is edited, narrowed, or greened) while making the
population unable to grow unnoticed. Same shape as T-399's ledger: a grandfathered
population keyed on path, with the live rule applying to everything else.

**Explicitly NOT in scope:** rebuilding `build/gallery/` — the register pre-rejects
that ("Closing because *we rebuilt the gallery* is not closure"), and
`_t350-build-only-probe.sh` already refuses to touch the real serve root for the
same reason.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/verification-hygiene.py` scans EVERY task file in `.tasks/active/` and `.tasks/completed/` (not one task by ID) and detects both G-015 carrier shapes: a `diff`/`cmp` against the serve root, and a hard-coded `:PORT` literal — 408 files, 1553 executable lines, 75 + 17 carriers across 85 files
- [x] A baseline file records the carriers present at this commit; the scanner exits 0 on the tree as it stands today and exits non-zero when a carrier appears in a file not in the baseline (the ratchet direction) — `tools/verification-hygiene-baseline.json`, 85 files / 92 lines; teeth (a) (b)
- [x] Removing a carrier is always allowed and never fails the scan; the baseline is keyed on the sha256 of the carrier LINE (not per-file counts) so a grandfathered file cannot become a free slot for a different carrier — teeth (b2); and after `--tighten` a cleaned file cannot re-acquire one — teeth (c2)
- [x] Anti-vacuity (PL-084): the scanner reports the size of the population it scanned and FAILS (rc=2 VACUOUS) if that population is zero or if the baseline resolves to no carriers — a clean verdict over nothing is a bug, not a pass — teeth (d) (e)
- [x] A teeth harness proves each arm produces its own stated outcome: (a) new port carrier → rc=1 naming file+kind, (b) new serve-root diff → rc=1 naming file+kind, (b2) new carrier line inside a grandfathered file → rc=1 quoting the line, (c) baseline entry whose line is gone → **rc=0 with a standing `RATCHET AVAILABLE` notice, not a red** (removal must never be punished; the standing notice is what makes re-acquisition non-silent), (c2) re-acquire after `--tighten` → rc=1, (d)/(e) vacuity → rc=2; plus a reciprocal control proving a legitimately-clean NEW task file still passes, and (f) a behavioural agreement check against `_t350`. 10/10 legs green
- [x] `_t350-verification-hygiene.py` still passes for T-350 (the single-task check is not regressed or deleted) — `hygiene ok: ... 5 executable line(s)`
- [x] No existing `## Verification` line anywhere in the tree is edited by this task (leg 1 stays the operator's ruling) — `git diff .tasks/` shows only T-408 (new) and a `last_update:` metadata bump on T-102 from `fw work-on`; census still reads exactly 75 / 17

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
#
# NOTE: this block deliberately carries NEITHER G-015 shape — no serve-root diff and no
# port literal. A task remedying that gap must not commit the subject error (T-350 AC8).
python3 tools/verification-hygiene.py
bash tools/_t408-hygiene-teeth.sh
python3 tools/_t350-verification-hygiene.py T-350
# Leg 1 untouched: the carrier totals must still be exactly what was measured at filing.
# If either moves, someone edited existing verification lines and that is the operator's ruling.
out=$(python3 tools/verification-hygiene.py --census 2>&1); echo "$out" | grep -q "serve-root-diff=75"
out=$(python3 tools/verification-hygiene.py --census 2>&1); echo "$out" | grep -q "hardcoded-port=17"

## RCA

**Symptom:** G-015's hard-coded-port carrier population grew from 11 (measured
2026-08-02, in the register itself) to 17 (measured 2026-08-09) — six new carriers
in seven days, authored while the gap was open, documented, and severity-medium.

**Root cause:** the only thing standing between an author and a new carrier was
prose. CLAUDE.md bans hard-coded ports in the Verification Gate section; the gap
register describes the defect at length; `_t350-verification-hygiene.py` enforces
it — but only for **one task, by ID, passed as argv[1]**. Nothing scanned the
population. The register predicted this exactly ("nothing in the tree stops the
next author writing :3001... prose, read by nothing") and was right within a week.

**Why structurally allowed:** the remedy was scoped as one decision — narrow the 75
lines or drop the convention — and that decision is correctly the operator's. While
it waited, there was no *containment*. A gap whose remedy needs a ruling still needs
a ratchet in the meantime, or the ruling gets more expensive every week it waits.
The 75-line figure has been stable since 2026-08-02; the port figure has not. The
population the operator will eventually rule on was moving under them.

**Prevention:** `tools/verification-hygiene.py` fails on any carrier outside the
committed baseline, so the population can no longer grow silently. This is
containment, not closure — G-015 stays `watching` and leg 1 stays unruled. What
changes is that the number the operator rules on is now pinned.

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

### 2026-08-09 — the agreement leg was built the wrong way, and said so
- **What changed:** leg (f) originally checked that this tool and `_t350`'s classify
  lines identically by *scraping the regexes out of T-350's source*. It could not
  recover them and reported itself **vacuous** rather than passing — the harness
  working as intended, catching a defect in its own leg within a minute.
- **Plan impact:** source-shaped agreement is the wrong subject. It would keep
  breaking on reformatting while saying nothing about what the tools do, and would
  quietly pass the day someone rewrote the regex in an equivalent form.
- **Triggered:** rewrote (f) to compare BEHAVIOUR — run both tools over the same
  synthetic tree and require identical verdicts on 3 probe tasks (2 carrier, 1
  clean), with a guard that fails if T-350's tool misclassifies the probes, so
  "agreement" can never be agreement about nothing.

### 2026-08-09 — leg (c) is deliberately not a red
- **What changed:** the first sketch had "baseline entry whose file is gone" fail
  the scan. That punishes exactly the behaviour the gap wants: cleaning a carrier up.
- **Plan impact:** AC3 splits into two properties that needed different mechanisms —
  *removal never fails* (rc=0) and *re-acquisition is not silent* (a standing notice
  plus `--tighten`). One exit code could not carry both.
- **Triggered:** added leg (c2) — the property only holds after `--tighten`, so the
  teeth prove the ratchet turns one way rather than assuming it.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-08-09 — grandfather by line-hash, not by count or by directory
- **Chose:** baseline keyed on (task file, sha256 of the normalised carrier line).
- **Why:** it makes "this file is already excused" mean *this line*, not *one free
  slot*. Same shape as T-399's ledger, where scope was keyed on path and exemption
  on sha precisely so that changing the bytes drops a document back under the live
  rule.
- **Rejected:** per-file counts (`current <= baseline`) — a file cleaned 1→0 could go
  0→1 with a *different* carrier and still satisfy the inequality; proven catchable
  by teeth (b2). Also rejected: excluding `.tasks/completed/` wholesale — 72 of the
  75 diff carriers live there, so the baseline would have looked almost empty and
  the census assertion in `## Verification` would have been meaningless.

### 2026-08-09 — containment now, ruling later; do NOT touch the 75 lines
- **Chose:** change zero existing verification lines, and pin the census at 75/17 in
  this task's own `## Verification` so a future edit to them fails THIS gate.
- **Why:** G-015 says in terms that narrowing 75 lines is a convention change and
  "T-093/T-102/T-105 gates belong to their owners". An autonomous directive delegates
  initiative, not authority; a convention change across 75 files is authority.
- **Rejected:** rebuilding `build/gallery/` to green all 75 at once. The register
  pre-rejects it ("Closing because *we rebuilt the gallery* is not closure — the line
  goes red again on the next edit to src"), and `_t350-build-only-probe.sh` already
  refuses to touch the real serve root for exactly this reason. It would have closed
  four stuck tasks today and re-opened all 75 on the next edit to src.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-09T10:47:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-408-ratchet-the-g-015-verification-hygiene-p.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-bac5cd93
- **Timestamp:** 2026-08-09T10:54:21Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — A baseline file records the carriers present at this commit; the scanner exits 0 on the tree as it stands today and exits non-zero when a carrier appears in a file not in the baseline (the ratchet dir
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/verification-hygiene-baseline.json in: A baseline file records the carriers present at this commit; the scanner exits 0 on the tree as it stands today and exits non-zero when a carrier appe`

### 2026-08-09T10:54:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
