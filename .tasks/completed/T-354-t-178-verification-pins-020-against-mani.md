---
id: T-354
name: "T-178 verification pins 0.2.0 against MANIFEST's always-latest sha256 field — blocks a queued human review"
description: >
  T-178 is active, status work-completed, owner human, queued at /review/T-178. Its verification block compares MANIFEST.yaml's sha256 field against dist/aef-workflow-designer-0.2.0.html. That field always names the LATEST release; it is at 0.8.0 and is internally correct (field matches the 0.8.0 artifact byte for byte). The line was true exactly once, when 0.2.0 was latest, and has been false through eight releases since. Consequence: when the operator ticks T-178's Human AC and runs work-completed, the P-011 gate refuses the completion for a reason unrelated to T-178's deliverable, which shipped. This is the G-015 shape — a verification line asserting a global, always-moving property — third carrier found after the designer.html diff family and the hard-coded ports. Found by T-353 while tallying the LATENT bucket's recorded verdict pairs: 30 of 189 are (FAIL/n/a), i.e. already red; 29 are archived and inert, this one is live. Repair is to pin the artifact the task actually released (compare against the 0.2.0 sha recorded at release time) rather than against a field that moves. NOT repaired under T-353: T-178 is another owner's active task.

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
created: 2026-08-03T11:03:24Z
last_update: 2026-08-03T11:15:19Z
date_finished: 2026-08-03T11:15:19Z
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

# T-354: T-178 verification pins 0.2.0 against MANIFEST's always-latest sha256 field — blocks a queued human review

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the full extent of T-178's staleness is measured, not assumed.**
      **Measured: THREE red lines, not one.** `grep -q '^0.2.0$' VERSION` and
      `grep -q 'latest: "0.2.0"' dist/MANIFEST.yaml` were both red and both **invisible to the
      T-352 scan**, which only ever examined lines carrying a top-level `;`. Confirms the AC's
      premise — the scan's reach, not T-178, was what "one red line" described. T-353 found the
      `sha256` line by scanning lines that carry a top-level `;`. That is a SUBPOPULATION, so
      "T-178 has one red line" is a claim about the scan's reach, not about T-178. Every line in
      T-178's `## Verification` block is executed individually and its verdict recorded. The
      count of red lines is reported as measured, whatever it turns out to be.
- [x] **AC2 — the repair pins a baseline that exists independently of the current file.**
      Baseline is `e301986b…`, the literal T-178 recorded in its own AC#2/AC#3 **at release
      time** and which AEF independently confirmed on re-pin — not a value re-derived from the
      artifact today. `sha256sum` of the artifact matches it exactly, so the artifact is intact.
      The fix must NOT be "record whatever `sha256sum dist/…-0.2.0.html` prints today" — that is
      a tolerance answerable only to itself and would pass even if the artifact had been
      corrupted. The baseline is the sha T-178 **recorded at release time** (`e301986b…`, in its
      own AC#2/AC#3 text and confirmed by AEF's independent re-pin), and the repaired line must
      compare the artifact against that literal.
- [x] **AC3 — the repair is proven to discriminate, in both directions.**
      Repaired line vs the real `0.2.0` artifact → **PASS**. Same baseline vs `0.1.0` →
      **FAIL**. Both directions measured, so the PASS is evidence rather than decoration. Run the repaired line
      against the real artifact and require PASS; run it against a different release artifact
      (e.g. `0.1.0`) and require FAIL. A line that passes is not evidence — the line being
      replaced also passed, for eight releases, while asserting nothing true.
- [x] **AC4 — no gate is weakened to make a task completable.**
      All three red lines classified **WRONG, not correctly-failing**: each asserted "the
      project's CURRENT release state is 0.2.0", a global that necessarily moves at the next
      release. The evidence that none was reporting a real regression is that the artifact
      hashes to the sha T-178 recorded at release — it is byte-for-byte what shipped. VERSION
      and `latest:` have no permanent equivalent (they legitimately move) and the sha check
      subsumes what they stood as evidence for; that reasoning is written into T-178's block
      rather than left implicit, so the reduction from 5 lines to 3 is auditable. State explicitly, for each line
      changed, whether the old line was *wrong* (asserting a property T-178 never had) or
      *correctly failing* (reporting a real regression). Only the first may be repaired. If any
      line turns out to be correctly failing, it is left red and reported — "the gate blocks, so
      fix the gate" is a bypass wearing the costume of a repair.
- [x] **AC5 — the scope boundary is recorded.**
      Changed: T-178's `## Verification` block only — three red lines replaced by one sound
      one, with the full reasoning inline in the block itself. Nothing else in T-178 touched;
      **no AC of T-178 ticked** (its Human `[REVIEW]` AC remains the operator's). Visible at
      `/review/T-354`. This is a live, broken, review-blocking gate rather than T-353's inert
      archived corpus, which is why it was repaired instead of parked — but it is the same
      kind of question and is recorded as such. T-178 is another owner's ACTIVE task. Editing
      its verification block is a smaller question than T-353's archived-corpus ruling (this one
      is live, broken, and blocking a queued review) but it is the same *kind* of question. What
      was changed is stated explicitly, and the operator can see it at `/review/T-354`.
- [x] **AC6 — the population question T-178 raises is answered or explicitly deferred.**
      Answered and corrected in place: `docs/reports/T-353-corpus-readiness.md` **§3c** now
      states that 30 is a **FLOOR, not a count** — the T-352 scan's population was only lines
      carrying a top-level `;`, so a red line without one was never a candidate. T-178 supplies
      the concrete proof (2 of its 3 red lines were outside the scan's reach). The corpus-wide
      figure is unmeasured and strictly greater than 30. Same shape as the RAIL-387 retraction:
      a subpopulation's property stated about the tree. Carried to AEF in the next rail post. If
      T-178's second red line is invisible to the T-352 scan because it lacks a top-level `;`,
      then the corpus-wide "30 red lines" figure is a floor, not a count, and that must be
      stated wherever the 30 appears (`docs/reports/T-353-corpus-readiness.md` §3b, RAIL-408).

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

# Every line here is a SINGLE command. This task's whole subject is a verification
# block that asserted a moving global; its own gate should not be the place to get
# clever. Same discipline as T-351/T-352/T-353.

test -f dist/aef-workflow-designer-0.2.0.html
echo "e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a  dist/aef-workflow-designer-0.2.0.html" | sha256sum -c --status -
grep -q "REPAIRED BY T-354" .tasks/active/T-178-cut-designer-release-020-with-t-177-gove.md
grep -q "FLOOR, not a count" docs/reports/T-353-corpus-readiness.md
test -f docs/reports/T-353-corpus-readiness.md

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

### 2026-08-03T11:03:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-354-t-178-verification-pins-020-against-mani.md
- **Context:** Initial task creation

### 2026-08-03T11:11:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0e261d51
- **Timestamp:** 2026-08-03T11:15:20Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-03T11:15:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
