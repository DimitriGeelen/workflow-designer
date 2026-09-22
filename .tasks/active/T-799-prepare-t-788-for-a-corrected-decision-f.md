---
id: T-799
name: "Prepare T-788 for a corrected decision: fix the two reviewer citation findings and establish the re-decide path"
description: >
  Prepare T-788 for a corrected decision: fix the two reviewer citation findings and establish the re-decide path

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T09:23:38Z
last_update: 2026-09-22T09:23:38Z
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

# T-799: Prepare T-788 for a corrected decision: fix the two reviewer citation findings and establish the re-decide path

## Context

T-788's recorded decision reads `**Decision**: GO` with a rationale that literally begins
*"DEFER because the decisive fact is not ours to establish…"* and ends *"…GO would be building
on an assumption."* The verdict and its own rationale argue opposite things: `fw inception
decide` carried forward the `--recommendation DEFER` text filed at creation.

The operator confirmed they meant GO, then — on being shown the rationale — established that
their instinct was aimed at the **instance layer** (T-797, T-798), not the compiler. So the
compiler question resolves to NO-GO and the instance question is separate and now with AEF.

This task prepares the correction. **It does not make it.**

## The prepared command (operator runs this; the agent must not)

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw inception decide T-788 no-go --rationale "NO-GO on 832 building any part of the workflow-to-application executor. CORRECTS an earlier GO whose stored rationale was the DEFER text from filing and argued the opposite of its own verdict. The decisive fact arrived after filing: AEF at agent-chat-arc offset 1631 answered that Child-2 is shipped and pinned, not a spike - wired as the CLI verb fw bpmn compile, on master, contained in release tag v1.6.768, maintained, with no planned break in the seam. Their expectation of 832 is one artefact, the .bpmn file, and explicitly NOT a translator, compile document, staging area or task writer, because the .tasks/ write never leaves their task-gate perimeter. Building any part of it here would duplicate shipped maintained code, contradict the frozen standard's No translator is built here, and fork governance across two projects against a yardstick that puts AEF integration at 9. Measured on receipt: aef:uid present in 24 of 24 rendered maps, aef:laneMeta in 24 of 24, inception subProcess 0 of 24 and therefore untested rather than absent-by-defect. Evidence: docs/reports/T-788-executor-ownership-inception.md sections 7.2 and 8. THE OPERATOR'S GO INSTINCT WAS NOT WRONG, IT WAS AIMED AT A DIFFERENT LAYER: T-797 measured that nothing anywhere models a workflow RUN, and T-798 found those runs already exist unmodelled - roughly 1500 across 7 designs, with workflow_type already carrying the class name as a bare string that never resolves, unlike arc_id which does. That question is now with AEF at sidecar offset 6 and is a SEPARATE decision. This NO-GO closes the compiler question only."
```

**What it does to the record:** `lib/inception.sh` rewrites the `## Decision` block in place on
a second call (old content skipped, new written), while `update-task.sh` APPENDS a new dated
`### inception-decision` entry. So the original GO survives in the Updates history and only the
live verdict changes — which is the right shape for correcting a sovereignty record.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the re-decide path is established from the implementation, not assumed.**
      Whether `fw inception decide` accepts a SECOND decision on an already-decided inception
      decides whether the operator can correct the record at all. `--help` cannot be read —
      Tier 0 blocks the verb on command text — so the answer comes from the source.
      Evidence: `lib/inception.sh` — on encountering `## Decision` it writes the new block
      and sets `decision_written`, then SKIPS all old decision content until the next H2+
      heading. A second call therefore overwrites rather than refusing, and `update-task.sh`
      appends a new dated `### inception-decision` entry, so the original GO survives in the
      Updates history. `--help` could not be read: the Tier 0 gate matches the verb in the
      command TEXT and blocked it, which is correct behaviour.
- [x] **AC2 — the corrected decision is NOT recorded by this agent.** `fw inception decide`
      is Tier 0 and agents must not invoke it at all. This task prepares a copy-pasteable
      line and stops. Preparing it is not deciding it.
      Evidence: T-788's `## Decision` still reads GO. The Verification block asserts that
      directly — if this agent had run the decide verb, that leg would go red. Preparing a
      command is not deciding; the distinction is the whole point of the Tier 0 gate.
- [x] **AC3 — the prepared rationale ARGUES the verdict it carries.** The defect being
      corrected is precisely a decision whose stored rationale argued the opposite. Repeating
      that shape while fixing it would be absurd, so the text must stand on its own and cite
      evidence in a form the reviewer recognises.
      Evidence: the prepared rationale opens with the verdict it carries ("NO-GO on 832
      building any part of…") and cites `docs/reports/T-788-executor-ownership-inception.md`
      sections 7.2 and 8 — a `docs/reports/` path, which is one of the forms the reviewer
      heuristic recognises. It also names what it does NOT close: the instance question.
- [x] **AC4 — the two reviewer findings are handled honestly, including if they cannot be
      fixed here.** `IW-1` and `IW-2` are flagged `disposition-incomplete` because their
      rationales cite a rail offset in a form the heuristic does not read as evidence. T-788
      now lives in `.tasks/completed/`, so fixing them means editing a completed task file —
      which is the exact question SQ-2 asks. Whether that is done or deferred, the reason is
      stated rather than the finding being quietly left.
      **NOT FIXED, and deferred for a stated reason rather than left quietly.** T-788 now
      lives in `.tasks/completed/`, so correcting IW-1's and IW-2's citations means editing a
      completed task file — which is exactly what SQ-2 asks and what T-353 is blocked on.
      Fixing it here would be deciding SQ-2 by doing it. The findings are `partial,
      heuristic` and the underlying evidence is real and quoted in the artifact; what is
      missing is a citation FORM, not a fact. **This is now a live worked example for SQ-2
      rather than a hypothetical** — a two-line edit, to another owner's completed task,
      that fixes a real reviewer finding.

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
         1. Run `bin/fw reviewer T-799`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-799 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: the overwrite-on-second-call behaviour this rests on ────────────────
grep -q 'Skip old decision content' .agentic-framework/lib/inception.sh
grep -q 'decision_written = True' .agentic-framework/lib/inception.sh

# ── AC2: THIS AGENT DID NOT DECIDE. T-788 still reads GO. ────────────────────
# If the agent had run the Tier 0 verb, this leg goes red — which is the point.
grep -q '^\*\*Decision\*\*: GO' .tasks/completed/T-788-does-832-build-any-part-of-the-workflow-.md

# ── AC3: the prepared command exists, is NO-GO, and cites recognised evidence ─
grep -q 'inception decide T-788 no-go' .tasks/active/T-799-prepare-t-788-for-a-corrected-decision-f.md
grep -q 'docs/reports/T-788-executor-ownership-inception.md sections 7.2 and 8' .tasks/active/T-799-prepare-t-788-for-a-corrected-decision-f.md

# ── AC4: the reviewer findings are STILL THERE, deliberately, and said so ────
grep -q 'disposition-incomplete' .tasks/completed/T-788-does-832-build-any-part-of-the-workflow-.md
grep -q 'live worked example for SQ-2' .tasks/active/T-799-prepare-t-788-for-a-corrected-decision-f.md

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
     fw inception decide T-799 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T09:23:38Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-799-prepare-t-788-for-a-corrected-decision-f.md
- **Context:** Initial task creation
