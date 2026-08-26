---
id: T-592
name: "Verification legs that pipe a self-reporting command into grep discard its exit status"
description: >
  Verification legs that pipe a self-reporting command into grep discard its exit status

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
created: 2026-08-26T12:31:10Z
last_update: 2026-08-26T12:47:17Z
date_finished: 2026-08-26T12:47:17Z
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

# T-592: Verification legs that pipe a self-reporting command into grep discard its exit status

## Context

Peer-driven. 010-termlink ran our `grep -qv` advisory against their tree (rail 479), found one
live vacuous leg on an active task, and then generalised the finding past `-v` in a way that
applies to us harder than the original did:

> Every instance we found PIPES a build command into grep. That discards the command's own exit
> status and substitutes a text heuristic on its output. `cmd | grep -q ...` can only ever
> assert something about cmd's OUTPUT, never about whether cmd SUCCEEDED. Where a command
> already exits non-zero on failure, the honest leg is the bare command — the pipe can only
> subtract.

We are clean on the loud form: **0** `grep -qv` in active tasks. We are not clean on the quiet
one: **24** live legs of the shape `out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"`,
across 15 active tasks.

(My first ad-hoc scan said 27. That was a *broader predicate* — it also matched intermediate
`tail`/`head` stages — not a different count of the same thing. Two independently written
scanners, one Python and one awk with different anchoring logic, both return 24. Reconciled
rather than published over, because 010-termlink published 10 for a population of 42 by reading
it off a `tail -20`, and the fix for that is a second implementation, not more care.)

The uncomfortable part is that this is the form **CLAUDE.md itself recommends** (L-387,
SIGPIPE-safe) while separately documenting that it is errexit-blind (T-352: P-011 runs each
line as the condition of an `if`, so `a; b` is judged on `b` alone and `a`'s exit code is
discarded). Both halves are written down; nobody joined them. The genuinely safe form is the
other one CLAUDE.md offers — `cmd > /tmp/.out 2>&1 && grep -q PATTERN /tmp/.out` — where `&&`
preserves the command's exit status.

Scope: prove the class, build a detector that separates live risk from historical residue, and
prove the detector can see dirt. Fixing the 24 call sites is deliberately NOT in scope — the
detector is what stops the 25th, and turning it into a blocking gate would redden 15 active
tasks, which is the operator's call and not mine (see ## Recommendation).

## Acceptance Criteria

### Agent
- [x] The false green is **proven with a poisoned control**, not argued: a command that exits
      non-zero while printing the success word is fed to the exact idiom, under P-011's real
      runner shape (`eval` inside an `if`-condition subshell), and the leg reports PASS.
- [x] The same control run against the honest form (bare command, or `&&`-chained) reports
      FAIL — so the control discriminates and the difference is attributable to the idiom.
- [x] A detector exists that reports occurrences in `## Verification` blocks, parsing from the
      **LAST** `## Verification` heading (the T-588 first-wins defect must not be reintroduced
      into the thing that checks for defects).
- [x] The detector **separates live risk from historical residue**: active-task occurrences are
      failures, completed-task occurrences are advisory. Completed blocks are never re-run, so
      reporting them as failures buries the ones that can actually fire.
- [x] The detector has a `--self-test` that **plants** a poisoned leg and a clean leg in a
      temp dir and requires exactly one hit, the poisoned one — it must prove it can see dirt
      before its clean runs are worth anything.
- [x] `--self-test` is proven to fail when the detector is broken: running it against a
      deliberately crippled predicate reports failure rather than success.
- [x] The live population is reported as an exact count with file names, and that count is
      reproducible by a second, independently-written scan that agrees with it (010-termlink
      published a count of 10 that was really 42, because they read it off a `tail -20`).

**Evidence for the above, in one place.** A command exiting 1 while printing
`3 passed, 2 FAILED` PASSES `out=$(cmd 2>&1); echo "$out" | grep -q "passed"` under P-011's
real runner shape, and FAILS the bare form — both directions run, both in `## Verification`.
`tools/check-vacuous-verification.py --self-test` plants one poisoned and one clean file and
requires exactly one hit. Two teeth legs cripple the detector deliberately and require its
self-test to go red: a BLIND predicate (finds nothing) and an OVER-EAGER one (flags the honest
`&&` file form). Live 24 / advisory 292, the 24 confirmed by an independent awk scan.

**One flaw the teeth found in my own detector.** The first draft excluded any line containing
`&&`, reasoning that `&&` preserves exit status. It does — but the honest file form has no
*pipe* into grep, so it was already outside the predicate. The guard spared nothing and
silently created false negatives for `out=$(cmd); echo "$out" | grep -q X && ...`. It was
caught because deleting it left the over-eager control passing unchanged, which is only
visible if you run controls in both directions. Removed.

### Human

- [ ] [REVIEW] Decide whether the vacuous-verification detector becomes a blocking gate
  **Steps:**
  1. See the live population for yourself — 24 legs across 15 active tasks:
     `cd /opt/832-Workflow-designer && python3 tools/check-vacuous-verification.py`
  2. Confirm the detector is not blind, by making it prove it can see a planted defect:
     `cd /opt/832-Workflow-designer && python3 tools/check-vacuous-verification.py --self-test`
  3. Pick one:
     **(a) Gate now** — reddens 15 active tasks immediately, all written in good faith
     against CLAUDE.md's own recommended idiom.
     **(b) Fix forward, then gate (my recommendation)** — land the detector advisory,
     fix the 24 legs in a follow-up task, gate after. Each fix is mechanical: the bare
     command, or `cmd > /tmp/.out 2>&1 && grep -q PAT /tmp/.out`.
     **(c) Advisory only, permanently** — cheapest, and it will rot, because the defective
     form is the one CLAUDE.md recommends.
  4. Whichever you pick, the CLAUDE.md fix is separate and is the one that stops the 25th:
     L-387 recommends the capture form, T-352 says the gate judges `a; b` on `b` alone.
     Both are in the same file and nobody joined them.
  **Expected:** one of (a)/(b)/(c) recorded, plus a yes/no on the CLAUDE.md paragraph edit.
  **If not:** the detector stays advisory and unreferenced by any gate; new instances keep
  arriving, because the guidance that produces them is unchanged.

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

## Recommendation

**Recommendation:** GO on the detector. **DEFER the gate to you.**

**Rationale:** The class is real and proven, and the detector now discriminates in both
directions. What I have deliberately NOT done is make it blocking, because 24 live legs across
15 active tasks would go red the moment it became a gate — and that is a decision about other
people's tasks, not a measurement. Measure first, gate second; gating before measuring is a
decision wearing a check's clothes, which is the mistake this whole thread is about.

Three options, and I recommend (b):

  (a) **Gate now.** `fw hook-enable` it as a PreToolUse on commit. Honest, and immediately
      reddens 15 active tasks whose legs were written in good faith against CLAUDE.md's own
      recommended idiom.
  (b) **Fix forward, gate after.** Land the detector advisory now, fix the 24 legs in a
      follow-up task, then gate. The 24 are mechanical — each becomes either the bare command
      or the `&&` file form.
  (c) **Advisory only, permanently.** Cheapest, and it will rot: the idiom is what CLAUDE.md
      recommends, so new instances arrive faster than anyone removes them.

**The CLAUDE.md half matters more than the 24.** L-387 recommends the capture form for SIGPIPE
safety; T-352 separately documents that P-011 judges `a; b` on `b` alone. Both are written
down, in the same file, and nobody joined them — so the guidance actively produces the defect.
Whichever option you pick, the doc fix is the one that stops the 25th, and it is a one-paragraph
edit to the Verification hints block.

**What I am NOT claiming:** that any of the 24 has actually masked a real failure. They are
capable of it; I have not gone back through history to see whether one did.

## Verification

# The detector must prove it can see dirt before any clean run of it means anything.
python3 tools/check-vacuous-verification.py --self-test

# TEETH A: a BLIND detector (predicate that never matches) must FAIL its own self-test.
D=$(mktemp -d); sed "s#^RE_QUIET = .*#RE_QUIET = re.compile(r'ZZZ_NEVER')#" tools/check-vacuous-verification.py > "$D/x.py"; python3 "$D/x.py" --self-test >/dev/null 2>&1; rc=$?; rm -rf "$D"; test "$rc" -ne 0

# TEETH B: an OVER-EAGER detector (drops the pipe requirement, so it flags the honest
# && file form) must also FAIL — a detector that flags the remedy pushes authors back
# onto the defect.
D=$(mktemp -d); sed "s#^RE_QUIET = .*#RE_QUIET = re.compile(r'grep\s+-[a-zA-Z]*q')#" tools/check-vacuous-verification.py > "$D/x.py"; python3 "$D/x.py" --self-test >/dev/null 2>&1; rc=$?; rm -rf "$D"; test "$rc" -ne 0

# THE CLASS ITSELF, proven not argued: a command exiting 1 while printing the success word
# passes the piped idiom under P-011's real runner shape (eval inside an if-condition).
if ( eval 'out=$( { echo "3 passed, 2 FAILED"; exit 1; } 2>&1 ); echo "$out" | grep -q "passed"' ); then rc=0; else rc=1; fi; test "$rc" -eq 0

# ...and the honest bare form correctly FAILS the same control.
if ( eval '{ echo "3 passed, 2 FAILED"; exit 1; } >/dev/null 2>&1' ); then rc=0; else rc=1; fi; test "$rc" -eq 1

# ...and the honest bare form correctly FAILS the same control.

# The scanner anchors on the LAST ## Verification heading (T-588 first-wins must not recur).
grep -q "matches\[-1\]" tools/check-vacuous-verification.py

# NOT GATED ON A CLEAN TREE, deliberately: 24 live occurrences exist and turning this into a
# blocking gate would redden 15 active tasks. That is the operator's call, surfaced as a
# Human AC. Measure first, gate second — see this task's ## Decisions.

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

### 2026-08-26T12:31:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-592-verification-legs-that-pipe-a-self-repor.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a9b39f52
- **Timestamp:** 2026-08-26T12:47:18Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `rm -rf`

### 2026-08-26T12:47:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
