---
id: T-776
name: "create-task.sh rewrites the task name when the name contains the id placeholder token"
description: >
  create-task.sh rewrites the task name when the name contains the id placeholder token

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
created: 2026-09-21T14:52:54Z
last_update: 2026-09-21T14:57:44Z
date_finished: 2026-09-21T14:57:44Z
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

# T-776: create-task.sh rewrites the task name when the name contains the id placeholder token

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The defect is reproduced against the shipped script, on both branches.**
      Re-measured here rather than cited from T-774, because a reproduction inherited from
      another task is a claim and not evidence:

      ```
      build     --name 'build tasks ship the literal <placeholder> placeholder'
                ->  name: "build tasks ship the literal T-996 placeholder"
      inception --name 'inception ACs ship the literal <placeholder> placeholder'
                ->  name: "inception ACs ship the literal T-997 placeholder"
      ```

      The operator's own words, rewritten in place, on both code paths.

- [x] **The id substitution runs before any user text enters the document.** Moved to
      immediately after the template is read — one pass, while the template is still the
      template. The late second pass is removed, and the H1 anchors now carry the real id
      because the pass has already run.

      **The defect was ORDER, not intent.** T-660's body-wide substitution was correct and
      is kept; it simply ran after the name had been injected, so it could not tell the
      operator's text apart from the template's. PL-164 once more — the task most likely
      to contain the placeholder is the task filed about the placeholder.

- [x] **T-660's original purpose is verified, not preserved by assertion.** An inception
      created after this change still carries a pasteable command with the real id:

      ```
      1. Run: `fw task review T-997` (opens Watchtower with recommendation, assumptions, …)
      ```

      This matters more than it looks. **Deleting the substitution outright would have made
      the name-survival legs pass**, while silently restoring the exact defect T-660 was
      built to fix — nine of ten unruled inceptions shipping an unpastable first step. Two
      probe legs exist only to close that door: one asserts the review command keeps its
      id, the other asserts an ordinary task comes out with zero literal placeholders
      anywhere in the file, which is what proves the pass still ranges over the whole
      document rather than just the title.

- [x] **A probe covers it, with a negative control from the genuine pre-fix script.**
      `tools/_t776-create-task-placeholder-probe.sh` — **5 legs, 5 pass**. The control runs
      the real previous script via
      `git show 7892bb66:.agentic-framework/agents/task-create/create-task.sh` and shows the
      name still being rewritten there. Regressions re-run: T-774's probe 13 pass, T-775's
      6 pass.

      One detail worth keeping: the probe assembles the placeholder token at runtime rather
      than writing it literally, so the probe file is not itself a candidate for the class
      of substitution it tests.

- [x] **The vendor divergence is declared.** Appended as `T-776`, `upstream: fix` —
      fourth entry for this path after T-660, T-774 and T-775, which is the file's
      one-entry-per-task convention. `python3 tools/_t517-vendor-divergence.py` stays
      green.

- [x] **G-061 is NOT closed by this task, and this is the third fix in a row that does
      not close it.** OBS-363, OBS-364 and OBS-365 are all now fixed. The gap they share —
      `create-task.sh` writes a file and exits 0 without ever parsing what it produced — is
      untouched. Three consecutive green fixes are exactly the pattern that makes a
      structural gap look handled, which is why it is written here rather than left to be
      inferred from the register.

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
         1. Run `bin/fw reviewer T-776`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-776 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

./tools/_t776-create-task-placeholder-probe.sh
./tools/_t775-create-task-linebreak-probe.sh
./tools/_t774-create-task-substitution-probe.sh
bash -n .agentic-framework/agents/task-create/create-task.sh
python3 tools/_t517-vendor-divergence.py
test -f .fabric/components/tools-_t776-create-task-placeholder-probe.yaml

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

**Symptom:** a task whose name contained the id placeholder had its own name rewritten to
carry the allocated id, on both template branches.

**Root cause:** T-660 substitutes the placeholder across the whole document so inception ACs
ship a pasteable review command. That pass ran last, after the user-supplied name had been
injected, and a body-wide `str.replace` cannot tell the operator's text from the template's.

**Why structurally allowed:** same as OBS-363 and OBS-364 — nothing parses the file the
generator has just written, so a rewritten name is indistinguishable at creation time from
an intended one. Registered as **G-061**, still open after all three fixes.

**The wrong fix, named because it was available.** Deleting the substitution would have made
every name-survival assertion pass while restoring T-660's defect — an operator queue full of
inceptions whose first step cannot be pasted. A probe that only checks the reported symptom
would have certified it. Two legs guard that direction explicitly.

**Prevention:** the probe, with a control driven from the genuine pre-fix script. Still a
probe, not a gate; G-061 carries that limitation rather than this task claiming it away.

**Pattern across the three.** OBS-363, OBS-364 and OBS-365 are one defect shape seen three
times: user-supplied text is injected into a document that is still being mechanically
rewritten. T-774 anchored the rewrites to lines. T-775 stopped a value from becoming a line.
T-776 moved the remaining rewrite ahead of the injection. The general form of the fix is
**substitute the template before you fill it**, and the general form of the missing guard is
**read back what you wrote** — which is G-061 and is still not built.

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
     fw inception decide T-776 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T14:52:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-776-create-tasksh-rewrites-the-task-name-whe.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cdfb82b7
- **Timestamp:** 2026-09-21T14:58:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T14:57:44Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
