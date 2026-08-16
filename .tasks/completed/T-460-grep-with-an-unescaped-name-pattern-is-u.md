---
id: T-460
name: "grep with an unescaped $name pattern is unsatisfiable: _t350-teeth assert_safe
  guard-intact branch is unreachable"
description: >
  grep with an unescaped $name pattern is unsatisfiable: _t350-teeth assert_safe guard-intact
  branch is unreachable

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
created: 2026-08-12T14:08:42Z
last_update: '2026-08-16T14:33:38Z'
date_finished: 2026-08-12T14:19:59Z
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
  - ts: '2026-08-16T14:33:38Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=0 (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tools/_t350-teeth.sh,tools/_t352-p011-errexit-probe.sh,tools/serve-gallery.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t350-teeth.sh,tools/serve-gallery.sh); tier=2 (no-signal); 
      effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-460: grep with an unescaped $name pattern is unsatisfiable: _t350-teeth assert_safe guard-intact branch is unreachable

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
> **This task was filed on a false premise and is being completed as its own retraction.**
> It began as "an unescaped `$` makes a `grep` pattern unsatisfiable, and that killed a branch
> in the delete-guard harness." That is wrong. GNU grep reads a mid-pattern `$` as a literal;
> the branch was always reachable; nothing was broken. The ACs below are the corrected ones.
> The original claim is preserved in `## RCA` rather than deleted, because a task that quietly
> changes what it found is a worse artefact than one that carries its own retraction.

- [x] **The premise is disproven with both implementations named, not just the counts.**
      Same pattern, same file, same moment:

          grep -c 'case "${OUT%/}" in' tools/serve-gallery.sh
            through my shell        0
            through /usr/bin/grep   1

      `grep` in the agent's interactive shell is a **shell function** — a harness shim that
      routes to **ugrep 7.5.0** — and ugrep anchors on the `$`. GNU grep does not. The
      documented GNU behaviour (mid-pattern `$` is literal) is the correct one, so
      `_t350-teeth.sh:45` was never dead and `assert_safe()`'s `guard intact` branch was always
      reachable.
- [x] **The environment split is measured, not assumed.** `bash -c 'type -t grep; command -v
      grep'` returns `file` and `/usr/bin/grep`. Every subshell, script, hook and P-011 leg
      therefore runs GNU grep. The shim exists **only** in the agent's own tool shell — that
      is, only in the instrument, never in the subject.
- [x] **Three prior findings are withdrawn by name.** (a) `_t350-teeth.sh:45` unreachable
      branch — false. (b) T-459's `grep -q 'diff -q "$tmpl" "$target_tmpl"'` leg "returning 0
      on a file that contains the text" — false; GNU grep returns 1. (c)
      `.tasks/completed/T-148:68` carrying an unmatchable leg — false; it matches. All three
      were artefacts of the same shim, and all three were reported to AEF at rail 570 §5 with
      a request that they sweep their tree. Retracted at rail 571.
- [x] **The `-F` change is KEPT and re-justified, and the wrong reason is removed from the
      tree.** `-q` → `-qF` on `_t350-teeth.sh:45` stays: it is the correct flag for a wholly
      literal pattern and it makes the check agree under both implementations. The call-site
      comment no longer claims the branch was dead — it states that the plain form was correct
      and that `-F` buys implementation-independence on purpose.
- [x] **The real class is named and distinguished from the two already registered.**
      G-034 is a verdict computed from an empty population; G-035 is an instrument with no
      live caller. This is a third: **the instrument and the subject run different
      implementations of the same tool, and nothing announces it.** It cannot be found by
      reading code, because the code is correct in both trees. Its direction of harm is a
      **false absence** — ugrep's extra anchoring makes patterns match *less*, so agent-side
      sweeps under-report, and "I swept and found nothing" is precisely the sentence it
      corrupts.
- [x] **The correction path is recorded, because the gate outperformed the agent.** P-011
      refused to complete this task on a leg asserting `BRE == 0`. The failure was not
      reproducible by hand — "by hand" being the corrupted path — so the leg was rewritten to
      **print its own numbers instead of only asserting them**, and the gate answered
      `BRE=1 FIXED=1 cwd=/opt/832-Workflow-designer grep=/usr/bin/grep opts=[unset]`. One line
      of output ended it. A gate that runs somewhere the agent cannot reach was the more
      reliable instrument, and an assertion that prints its evidence is worth more than one
      that only passes or fails.
- [x] **T-459's record is corrected by appending, not by editing its checkbox.** T-459 is
      completed and committed with an AC asserting the false class. A dated correction is
      appended to that file; the AC text and its tick are left as they were so the mistake
      remains legible in the record it was made in.

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
# Every leg calls /usr/bin/grep BY ABSOLUTE PATH, deliberately. A bare `grep` here would
# resolve to GNU grep under this gate and to the ugrep shim in an agent's tool shell, and
# those two disagree on the very pattern under test — which is the whole finding. Pinning the
# binary is what makes these legs mean the same thing wherever they are run.
#
# Every leg also PRINTS what it saw before asserting on it. The original version of leg 2
# asserted a count and nothing else; when the gate disagreed with the agent there was no way
# to tell which of them was wrong without a separate investigation. An assertion that shows
# its evidence turns a disagreement into an answer in one run.
test 1 -eq "$(/usr/bin/grep -cF -e "-qF 'case" tools/_t350-teeth.sh)"
c=$(/usr/bin/grep -c 'case "${OUT%/}" in' tools/serve-gallery.sh); echo "GNU grep reads mid-pattern dollar as LITERAL: count=$c (the withdrawn premise required 0)"; test "$c" -eq 1
test -n "$(/usr/bin/grep -nE '^[[:space:]]*rm[[:space:]]+-[a-zA-Z]*r' tools/serve-gallery.sh | /usr/bin/grep -v '^[0-9]*:[[:space:]]*#')" && test "$(/usr/bin/grep -c 'refusing to recursively delete' tools/serve-gallery.sh)" -ge 1 && /usr/bin/grep -qF 'case "${OUT%/}" in' tools/serve-gallery.sh
t=$(bash -c 'type -t grep'); p=$(bash -c 'command -v grep'); echo "subshell grep: type=$t path=$p — the shim exists only in the agent tool shell"; test "$t" = file && test "$p" = /usr/bin/grep
/usr/bin/grep -qF 'NOT a bug fix' tools/_t350-teeth.sh && /usr/bin/grep -qF 'always reachable' tools/_t350-teeth.sh
test 0 -eq "$(/usr/bin/grep -cF 'unreachable for every input' tools/_t350-teeth.sh)"

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

**The withdrawn claim, preserved verbatim so the retraction has something to point at.** This
task was filed asserting: *"GNU grep treats the unescaped `$` as an anchor in BRE, ERE and PCRE
alike, making the pattern unsatisfiable — measured BRE 0, `-E` 0, `-P` 0, `-F` 1; the `&&` never
held, so `assert_safe()`'s guard-intact branch was unreachable for every input."* Every sentence
of that is wrong. It was also sent to AEF at rail 570 §5 with a request that they sweep their
tree for the same class. Retracted at rail 571.

**Symptom (the real one):** P-011 refused to complete this task. A verification leg asserting
`grep -c 'case "${OUT%/}" in' == 0` failed under the gate and passed in the agent's shell, and
the disagreement was not reproducible by hand.

**Root cause:** `grep` in the agent's interactive tool shell is a **shell function** — a harness
shim routing to **ugrep 7.5.0** — while every subshell, script, hook and P-011 leg runs
`/usr/bin/grep`. The two disagree on a mid-pattern `$`: GNU grep reads it as a literal (correct,
documented), ugrep anchors on it. Same command, same file, same second: 1 versus 0. The original
"defect" was the shim, observed and mistaken for the subject.

**Why structurally allowed:** nothing announces the substitution. It is not on `$PATH`, it does
not appear in `command -v` in any shell that matters, and it is visible only to `type -t grep`
in the one shell that has it. The agent's measuring instrument and the environment under
measurement were different programs, and every prior finding taken with `grep` inherited that
gap silently. Direction of harm is a **false absence**: the shim's extra anchoring makes
patterns match *less*, so agent-side sweeps under-report — and "I swept and found nothing" is
exactly the sentence being corrupted.

**Prevention:** every leg in `## Verification` now calls `/usr/bin/grep` by absolute path, so
the legs mean the same thing in both environments, and one leg asserts the split itself
(`bash -c 'type -t grep'` is `file` at `/usr/bin/grep`) so a change in the harness surfaces
here rather than in a wrong finding. Every leg also **prints what it saw before asserting on
it** — the original leg asserted a bare count, and when the gate disagreed with the agent there
was no way to tell which was wrong without a separate investigation. The general rule this
earns: *when a gate and your own shell disagree, the gate is the environment that matters, and
the fastest route to the truth is to make the assertion show its evidence rather than to
re-run it by hand.* The class belongs beside G-034 (verdict computed from an empty population)
and G-035 (instrument with no live caller) as a third way an instrument reports something other
than what it means — **instrument and subject running different implementations of the same
tool** — and it cannot be found by reading code, because the code is correct in both trees.

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

### 2026-08-12T14:08:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-460-grep-with-an-unescaped-name-pattern-is-u.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-aa409670
- **Timestamp:** 2026-08-12T14:20:00Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T14:19:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
