---
id: T-552
name: "_t525 hermeticity leg cannot pass on the first audit of any day"
description: >
  _t525 hermeticity leg cannot pass on the first audit of any day

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
created: 2026-08-16T23:11:25Z
last_update: 2026-08-16T23:11:25Z
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

# T-552: _t525 hermeticity leg cannot pass on the first audit of any day

## Context

`tools/_t525-fabric-coverage-teeth.py` leg 7 asserts that running the probe leaves the
subject's write-set — `.context/audits`, excluding `cron/` — unchanged. It does that by
comparing `git status --porcelain` output before and after (`tree_state()`, line 242).

Found on 2026-08-17 when the instrument sweep went red at rc=1 on `_t525` while `_t525`
standalone was 8/8 minutes later. The cause is the date rolling over: leg 1 runs the real
`fw audit` against this repository, and the first audit of a new day **creates**
`.context/audits/<today>.yaml`. That creation adds a `??` line to porcelain output, so
`before != after` and the leg goes red — on a write the audit is supposed to perform.

The same reading shows the assertion is weak in the other direction. `git status --porcelain`
reports *status letters*, not content: once today's report exists in any state, every
subsequent rewrite of it — and every rewrite of any *historical* audit file already in the
working tree — leaves the porcelain line byte-identical. So the leg is blind to content
mutation on every run except the one it is guaranteed to fail. It cannot see a run that
rewrites `.context/audits/2026-08-09.yaml`, which is the class the immutable-historical-record
rule exists to protect.

Registered as OBS-273. This is the second scoping repair to the same leg: T-533 narrowed it
from the whole tree to this write-set (PL-234). That narrowing was correct and is retained —
what is wrong is the *comparand*, not the scope.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Leg 7 compares **content**, not porcelain status letters: the before/after comparand is a
      path→digest map of the subject's write-set, so a mutation of an existing file under
      `.context/audits` (excluding `cron/`) that leaves its git status letter unchanged still
      turns the leg RED. Proven against the old form, which is green on that stimulus.
- [x] The permitted delta is an explicit allow-list **derived from measurement**, not guessed:
      two consecutive `fw audit` runs are observed and every path they touch under the
      write-set is recorded in the task's `## Measured` section before the allow-list is
      written. Any path outside that list, created or modified, turns the leg RED.
- [x] Leg 7 is GREEN on the first audit of a day. Proven deterministically by driving the
      comparison over a synthetic before-state in which today's report does not yet exist —
      not by waiting for midnight and not by asserting it in prose.
- [x] A mutated **historical** audit file (e.g. a rewritten `.context/audits/2026-08-09.yaml`)
      turns leg 7 RED. The old status-line form cannot see this; this is a capability the
      repair adds, not one it preserves.
- [x] PL-234's two arms still hold, re-measured against the new form: an unrelated writer
      elsewhere in the repo leaves leg 7 GREEN (the T-533 defect stays fixed), and the
      subject's own write-set being dirtied outside the allow-list still turns it RED
      (the invariant has not been narrowed into a decoration — PL-206).
- [x] `tools/_t552-writeset-hermeticity-teeth.py` exists, drives the extracted comparison
      function directly over synthetic states, is wired into `tests/run-bridge-tests.sh`, and
      is mutation-verified: the pre-fix comparand reconstructed behind its env seam turns
      legs red, and the count of red legs per mutant is recorded in `## Measured`.
- [x] `_t525` passes standalone and the full instrument sweep passes with the tree
      byte-identical after the run.

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
python3 tools/_t552-writeset-hermeticity-teeth.py
python3 tools/_t525-fabric-coverage-teeth.py
grep -q '_t552-writeset-hermeticity-teeth.py' tests/run-bridge-tests.sh
# Comments stripped before the check (PL-235): the T-552 comment in _t525 explains the defect
# by naming `git status --porcelain`, so a raw substring test fails on the fix's own prose.
python3 -c "import re,sys; s=open('tools/_t525-fabric-coverage-teeth.py').read(); code=re.sub(r'#[^\n]*', '', s); sys.exit(0 if 'write_set_violations' in code and 'declared_writes_observed' in code and 'porcelain' not in code else 1)"

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## Measured

All figures below are readings, not estimates.

**What `fw audit` actually writes** (two consecutive runs, digest snapshot of the 46 files
under `.context/audits` excluding `cron/`):

| Path | run 1 | run 2 |
|---|---|---|
| `.context/audits/2026-08-17.yaml` | MODIFIED | MODIFIED |
| `.context/audits/discoveries/LATEST.yaml` | MODIFIED | MODIFIED |
| *(the other 44 files)* | — | — |

That measurement is the whole allow-list. Nothing was inferred from reading `audit.sh`.

**The two blindness arms**, measured on the live tree and restored byte-identically after:

- Appending to `.context/audits/2026-08-16.yaml` (already ` M`) moved its digest
  `f42311649879 -> 47b2499bdbf7` and left `git status --porcelain` **byte-identical**. Both
  files the audit writes are in this state on every run after the first of the day, so the old
  assertion was passing on silence.
- Appending to `.context/audits/2026-08-09.yaml` (committed and clean) *did* add a ` M` line —
  so the old form could see a historical rewrite only when the file happened to be clean. This
  correction matters: the first reading of the defect overstated the blindness, and the
  narrower true statement is "blind to any file already dirty".
- Removing today's report from the before-state reproduces the daily red exactly: the
  `?? .context/audits/2026-08-17.yaml` line is present after and absent before.

**Mutation verification** (`T552_MODULE` seam, 10 legs):

| Mutant | Red legs | Which |
|---|---|---|
| A — pre-fix comparand (path-set only, no allow-list) | 6 | 1, 3, 4, 6, 7, 8 |
| B — digests but no allow-list | 4 | 1, 2, 7, 8 |
| C — always hermetic | 5 | 3, 4, 6, 7, 8 |
| D — did-it-run guard always fires | 1 | 9 (uniquely) |

Legs 5 and 10 are never red on any mutant by design: they are the must-stay-green arms
(PL-234's first arm, and anti-vacuity).

**Runs:** `_t552` 10/10 in <1s. `_t525` 8/8 standalone, 42.0s. Instrument sweep **40/40**
(population grew 39 → 40 with this probe). Tree byte-identical afterwards; both live-file
probe mutations verified restored with no `T-552 probe` marker surviving in any audit diff.

## RCA

**Symptom:** the instrument sweep exited rc=1 on `_t525` on 2026-08-17 while `_t525` standalone
passed 8/8 minutes later. Leg 7 — the hermeticity assertion — was red.

**Root cause:** leg 7's comparand was `git status --porcelain`, which reports status letters
rather than content. The first `fw audit` of any day *creates* `.context/audits/<today>.yaml`;
that adds a `??` line, so `before != after` and the leg failed on a write the subject is
supposed to perform. The date had just rolled over.

**Why structurally allowed:** two separate reasons, and the second is the more serious one.

1. T-533 repaired this leg once already, narrowing it from the whole tree to this write-set,
   and PL-234 was written from that repair. The scope was fixed; the comparand was never
   examined. A repair that corrects *where* a check looks does not automatically make *what* it
   compares correct, and nothing in the process asks the second question.
2. The comparand was wrong in the opposite direction the other 23 hours of the day, and that
   half was invisible precisely because it produced greens. A check blind to content passes;
   a check red once a day gets investigated. The framework noticed the half that complained
   and could not notice the half that agreed — which is this week's recurring shape, a stated
   property standing in for a checked one, with the failure rendering as health.

**Prevention:** `tools/_t552-writeset-hermeticity-teeth.py`, ten legs wired into the bridge
suite and mutation-verified against four mutants. Legs 3 and 4 are the blindness half and go
red under the reconstructed pre-fix comparand; leg 1 is the daily red; leg 9 refuses to call a
subject that never wrote anything hermetic. The comparison now lives in
`tools/_writeset_hermeticity.py` as a pure function, so the next probe that needs a write-set
assertion inherits both halves instead of copying the porcelain idiom a third time.

**Not prevented, and named as such:** nothing checks the *population* of hermeticity assertions
for the porcelain idiom. T-532's census judges pathspec scope syntactically and would not flag
a scoped-but-status-letter comparand. That is the same population-wide gap PL-148 has now been
recorded against five times and it still belongs in its own task, not this one.

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

### 2026-08-16T23:11:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-552-t525-hermeticity-leg-cannot-pass-on-the-.md
- **Context:** Initial task creation
