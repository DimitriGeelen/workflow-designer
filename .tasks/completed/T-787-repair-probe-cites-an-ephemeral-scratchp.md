---
id: T-787
name: "repair probe cites an ephemeral scratchpad path: the 16/16 evidence under the SQ-2 ruling no longer reproduces"
description: >
  repair probe cites an ephemeral scratchpad path: the 16/16 evidence under the SQ-2 ruling no longer reproduces

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t353-repair-probe.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T07:33:28Z
last_update: 2026-09-22T07:38:48Z
date_finished: 2026-09-22T07:38:48Z
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

# T-787: repair probe cites an ephemeral scratchpad path: the 16/16 evidence under the SQ-2 ruling no longer reproduces

## Context

The SQ-2 ruling request on T-353 (`may an agent edit `## Verification` blocks inside
`.tasks/completed/`?`) tells the operator, as step 1, to run `tools/_t353-repair-probe.sh`
and see **16/16**. Measured today it reports **12 passed, 1 failed**.

The probe is not wrong. Its fourth target is
`/tmp/claude-0/.../scratchpad/draft-task-creation-v2.bpmn` — and it points there because
**T-299's archived Verification line points there** (`.tasks/completed/T-299-*.md:138`). That
document arrived from AEF over rail 314 and was never committed to this repo; the scratchpad
has since been reaped. The probe detects the missing file and refuses to run the four legs,
saying so explicitly: *"target document is missing, so every leg below would measure the
load-error path instead of the pattern. Red on purpose."* That is correct instrument
behaviour — the same class as `score_blast_radius` returning `None` rather than 0.

What decayed is the **evidence citation**, not the instrument. A durable claim ("16/16") was
recorded in a task AC and in the Phase 5 value review while being contingent on a file
outside the repo. PL-284 named this class from the other direction ("a test fixture that can
silently degrade to live state is a false-green generator"); this is the same fixture
fragility degrading to a red instead of a green.

Fix: repoint the T-299 case at a committed document that reproduces the same condition, and
assert the out-of-repo fact mechanically so it stops being prose. `context-memory.bpmn`
validates to `WARN ... 0 error(s), 7 warning(s)` with the string `VALID` appearing **zero**
times — the same shape T-353 recorded for T-299 (`0 error(s), 3 warning(s)`, no `VALID`).

`examples/aef-processes/rendered/` is a seam artefact AEF pins against: this task READS one
of those files and modifies none of them.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the probe reproduces from a clean checkout.** `tools/_t353-repair-probe.sh`
      is green with every target resolving inside the repository. Proof is not "it is
      green": a `portability` leg per target fails any absolute path or any repo-relative
      path that does not exist, so a future target cannot reintroduce the same fragility
      silently.
      **Count corrected before ticking —** the headline is **23/23**, not 16/16. The repair
      added 7 legs (4 portability, 2 substitution, 1 provenance) to the original 16.
      Restating the old number would have made a changed instrument look unchanged.
      Negative-controlled: an absolute-path target → `probe: 18 passed, 2 failed`.
      `PROBE_ROOT` was added so a poisoned COPY can be controlled without re-rooting onto
      the scratchpad it was copied into (PL-193 — the first control attempt did exactly
      that and reported a failure unrelated to the poison).
- [x] **AC2 — the substituted target is proven equivalent, not assumed.** The replacement
      document must reproduce the condition the T-299 case exists to test: validator emits
      `WARN`, reports `0 error(s)`, and the output contains **zero** occurrences of `VALID`
      (so both the original unanchored `grep -q "VALID"` and the repaired `grep -q "^VALID"`
      fail on it, which is what makes "the repair cannot fix a stale document" measurable).
      Asserted by running the validator, not by citing this paragraph.
      Evidence: leg 0b. Negative-controlled by substituting a VALID document into the leg →
      both halves go red (`probe: 21 passed, 2 failed`), so this cannot pass on any document.
- [x] **AC3 — the decayed fact is recorded mechanically rather than lost.** T-299's archived
      Verification line cites a path outside the repository that cannot ever be re-run. The
      probe asserts that this is still true of the archived line, so the finding survives in
      the instrument instead of only in this prose. If someone ever commits that document,
      the assertion goes red and a human has to come back and say so — the same declared-
      expectation discipline the probe already applies to `valid_doc`.
      Evidence: leg 0c, which DERIVES the path from the archived line rather than hardcoding
      it — so it measures the record, not a copy of it. Negative-controlled by creating a
      file at that path → `FAIL provenance: ... now EXISTS — the finding has changed,
      re-rule it` (`probe: 22 passed, 1 failed`); removed, and green restored.
- [x] **AC4 — the stale "16/16" citations are corrected where they were published.** The
      Phase 5 report (`docs/reports/VALUE-REVIEW-repo-2026-09-21.md`) states a proven 16/16
      patch set sits unapplied. It is corrected in place to say what was actually measured
      and why, so the operator's ruling does not rest on a number that did not reproduce.

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
         1. Run `bin/fw reviewer T-787`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-787 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: the probe is green and reproduces from the repository alone ──────────
bash tools/_t353-repair-probe.sh 2>&1 | grep -q 'probe: 23 passed, 0 failed'

# ── AC1/AC3: the '/tmp/claude-0' absence in the probe, with its sibling control.
# Leg (a) is the POSITIVE control (T-560): it greps the SAME string where it IS
# present — T-299's archived Verification line — so leg (b)'s silence is evidence
# that the probe is clean, not evidence that the pattern is broken. Leg (a) is
# also AC3 on its own: it asserts the archived line still cites an out-of-repo
# path, so if that document is ever committed this goes red and someone must say so.
grep -q '/tmp/claude-0' .tasks/completed/T-299-task-creation-pair-round-leg-aef-t-2666-.md
! grep -q '/tmp/claude-0' tools/_t353-repair-probe.sh

# ── AC2: the substituted target reproduces T-299's condition, measured ────────
# WARN with zero errors:
out=$(timeout 60 python3 tools/validate-workflow.py examples/aef-processes/rendered/context-memory.bpmn 2>&1); echo "$out" | grep -q '^WARN'
out=$(timeout 60 python3 tools/validate-workflow.py examples/aef-processes/rendered/context-memory.bpmn 2>&1); echo "$out" | grep -q '0 error(s)'
# ...and 'VALID' absent from its output, with leg (a) the POSITIVE control on the
# SAME string against a document that IS valid. Without leg (a), a validator that
# crashed would produce an empty output and score the absence green.
out=$(timeout 60 python3 tools/validate-workflow.py examples/aef-processes/rendered/tier0-escalation.bpmn 2>&1); echo "$out" | grep -q 'VALID'
out=$(timeout 60 python3 tools/validate-workflow.py examples/aef-processes/rendered/context-memory.bpmn 2>&1); ! echo "$out" | grep -q 'VALID'

# ── AC4: the stale 16/16 citation is corrected where it was published ─────────
# Both published copies carry the correction, and the report names the instrument so a
# reader can re-run it rather than take the number on trust.
grep -q 'Correction, T-787' docs/reports/VALUE-REVIEW-repo-2026-09-21.md
grep -q '_t353-repair-probe' docs/reports/VALUE-REVIEW-repo-2026-09-21.md
grep -q '23/23 as of T-787' docs/reports/VALUE-REVIEW-repo-2026-09-21-evidence.md

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
     fw inception decide T-787 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T07:33:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-787-repair-probe-cites-an-ephemeral-scratchp.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cbc1038e
- **Timestamp:** 2026-09-22T07:38:52Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 49
     - evidence: `bash tools/_t353-repair-probe.sh 2>&1 | grep -q 'probe: 23 passed, 0 failed'`
  2. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 68
     - evidence: `out=$(timeout 60 python3 tools/validate-workflow.py examples/aef-processes/rendered/context-memory.bpmn 2>&1); ! echo "$out" | grep -q 'VALID'`

### 2026-09-22T07:38:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
