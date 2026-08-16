---
id: T-468
name: "Discharge the owed axis-2 baseline re-measure: which recorded numbers could
  a repo-root agent-side grep -r have undercounted"
description: >
  Discharge the owed axis-2 baseline re-measure: which recorded numbers could a repo-root
  agent-side grep -r have undercounted

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
created: 2026-08-12T19:49:01Z
last_update: '2026-08-16T12:34:00Z'
date_finished: 2026-08-12T19:55:34Z
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
  - ts: '2026-08-16T12:34:00Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-468: Discharge the owed axis-2 baseline re-measure: which recorded numbers could a repo-root agent-side grep -r have undercounted

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] EXPOSURE SURFACE MEASURED FIRST, before any assertion is written against it (PL-071).
      The set of files invisible to a repo-root agent-side recursive sweep is enumerated with
      a count, using ugrep's actual predicate — *does any in-scope ignore pattern match this
      path* — not "is it gitignored". `git check-ignore --no-index` is the index-blind test;
      plain `git check-ignore` is not, and using it would re-commit the exact under-general
      predicate AEF caught in T-462.
- [x] The TRACKED-yet-invisible set is reported separately with its own count. This is the
      dangerous class: a baseline counting tracked files can undercount silently. If it is
      non-empty, my "§3-i does not reproduce here" report to AEF at rail 576 needs an
      addendum, and issuing that addendum is part of this task rather than a later intention.
- [x] The verdict is stated as a number, not a reassurance (PL-084). If exposure is zero the
      answer is "the debt was vacuous, here is the denominator that makes it vacuous" — and
      per PL-095 a re-measure run where the subject can do nothing is reported AS vacuous,
      not as a clean bill of health.
- [x] Every recorded baseline that COULD have been undercounted is named, or the reasoning
      for why the candidate set is empty is given with the enumeration that produced it.
      No "I checked and it's fine" without the list.
- [x] The measurement is reproducible by the operator and by AEF from the commands in the
      report, and every grep in it is spelled `/usr/bin/grep` (G-037) so the reproduction
      does not silently swap pattern engines relative to where the numbers were taken.
- [x] Result posted to AEF on the rail. The debt has been declared three rounds by both
      sides; this task does not close until the answer is actually sent.

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
# HONEST LIMIT, stated as leg 6 rather than left implicit (T-465 precedent): the agent-only
# divergence of 0 is the load-bearing number and NO leg below can re-measure it. These run
# GNU; spawning is what escapes the shim. A leg claiming to check it would produce a GNU
# number wearing a ugrep label — the confusion G-037 exists to name.

# 1. The deliverable exists and states the inverted verdict, not a reassurance.
test -f docs/reports/T-468-axis2-baseline-remeasure.md && /usr/bin/grep -qF 'the premise of the debt was' docs/reports/T-468-axis2-baseline-remeasure.md

# 2. Tracked-yet-invisible is 0 — on the INDEX-BLIND predicate. If this ever goes non-zero the
#    report's central claim is stale and this leg says so before a reader trusts it.
test "$(git ls-files | git check-ignore --no-index --stdin 2>/dev/null | wc -l)" = "0"

# 3. ...and the probe can actually see: the tracked population is non-trivial, so leg 2 is not
#    passing because `git ls-files` returned nothing (PL-084 — prove the denominator exists).
test "$(git ls-files | wc -l)" -gt 1000

# 4. The third mechanism holds: .git/ is excluded by ugrep WITHOUT any ignore pattern, so an
#    exposure audit built on check-ignore alone misses it. Non-match => exit 1, hence the `!`.
! git check-ignore --no-index -q .git/index

# 5. The contamination vector is real and not hypothetical: .git/ carries project vocabulary
#    that a repo-root gate-side sweep would count.
test "$(/usr/bin/grep -c census .git/logs/HEAD 2>/dev/null)" -gt 0

# 6. Live exposure is zero: no P-011 verification leg in the repo runs a recursive grep rooted
#    at the repo root. Scoped roots below .git/ are safe.
#    The first form of this leg matched ONE line: its own explanatory comment, two lines above.
#    The leg's documentation sat inside the leg's search surface. AEF's T-456 remedy in a new
#    carrier — so the fix is the same shape: exclude what P-011 itself excludes. A leading `#`
#    is a comment to the gate, so it must be a comment to this leg too, or the leg and the gate
#    disagree about what a verification command IS.
test "$(/usr/bin/grep -rhE '^[^#].*grep -r[a-zA-Z]* [^|]*\.$' .tasks/active/ .tasks/completed/ 2>/dev/null | wc -l)" = "0"

# 6b. ...and leg 6 is not passing because the filter eats everything: the scoped recursive legs
#     that DO exist (T-211, T-273) must still be visible to the same expression minus its
#     repo-root anchor. Without this, deleting every task file would turn leg 6 green.
test "$(/usr/bin/grep -rhE '^[^#].*grep -r' .tasks/completed/ 2>/dev/null | wc -l)" -ge 2

# 7. The near-miss is recorded, not buried — it is the reason to trust the table above it.
/usr/bin/grep -qF '320 out of 320' docs/reports/T-468-axis2-baseline-remeasure.md

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

### 2026-08-12T19:49:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-468-discharge-the-owed-axis-2-baseline-re-me.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4ecc4755
- **Timestamp:** 2026-08-12T19:55:35Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T19:55:34Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
