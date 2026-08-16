---
id: T-431
name: "A-012 is measurable without AEF - does the frozen mapping still cover their
  enumeration"
description: >
  A-012 is measurable without AEF - does the frozen mapping still cover their enumeration

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-11T15:31:33Z
last_update: '2026-08-16T13:58:55Z'
date_finished: 2026-08-11T15:37:36Z
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
  - ts: '2026-08-16T12:33:58Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.agentic-framework/lib/enums.sh,.context/project/assumptions.yaml,docs/standards/aef-bpmn-mapping-v1.md,tools/_t352-p011-errexit-probe.sh);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:55Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/lib/enums.sh,.context/project/assumptions.yaml,docs/standards/aef-bpmn-mapping-v1.md,tools/_t431-a012-enumeration-probe.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-431: A-012 is measurable without AEF - does the frozen mapping still cover their enumeration

## Context

T-428 found that the arc anchor T-175 stands on three assumptions nobody had ever put to
the only party that could answer them, and put them to AEF at DM 527 §1. The first is:

> **A-012** — Every AEF `workflow_type` and `owner` is representable by (BPMN type +
> `aef:` extension) with no new BPMN shape.

At 529 §5 AEF declined to answer yet — correctly, their budget is at warn and they will not
give a structural answer badly. But **A-012 does not actually need them.** It is a claim
about an enumeration, and that enumeration is vendored in this tree at
`.agentic-framework/lib/enums.sh:65`. Waiting for a reply to a question we can measure is
the same shape as waiting for a ruling that was already given.

A-013 and A-014 genuinely need AEF — they are about what their model can *receive* and
whether their record is *reconstructible*. A-012 is not in that class and should never have
been sent in it.

**What makes this worth an instrument rather than one grep:** the frozen standard
`docs/standards/aef-bpmn-mapping-v1.md` makes a **closed-world claim about somebody else's
enumeration**, written weeks ago, with nothing re-checking it. Every re-vendor can add a
`workflow_type` and the standard would go on reading true. That is the T-402 shape exactly
— a sentence about someone else's code that rots silently — and the remedy is the same one
AEF adopted from us at 529 §1: **extract both sides at run time, retype neither.**

## Acceptance Criteria

### Agent
- [x] A probe extracts AEF's `workflow_type` enumeration from the shipping vendored file at
      run time (not a copy typed into the probe), and extracts the standard's enumeration
      from `docs/standards/aef-bpmn-mapping-v1.md` at run time as well — neither side retyped
- [x] The probe reports the comparison in BOTH directions: values AEF ships that the
      standard does not cover, and values the standard names that AEF does not ship
- [x] The same is done for `owner`, whose mapping is structural (lane) rather than a
      key/value, and the probe states which carrier each side uses rather than only counting
- [x] Extraction failure exits 2 with a distinct message — a probe that cannot find the
      enumeration must not report "no gaps found"
- [x] The probe is proven discriminating by mutation: an added AEF value and a removed
      standard value each move the verdict, asserted against ONE scratch fixture
- [x] The measured verdict for A-012 is recorded in the task with the evidence that produced
      it, and `.context/project/assumptions.yaml` is updated ONLY if the evidence supports a
      disposition — with the evidence recorded, never a bare status flip (T-428)
- [x] `docs/standards/aef-bpmn-mapping-v1.md` is byte-unchanged and no file under
      `.agentic-framework/` is modified (both asserted in Verification)

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

## Findings

### A-012 is answered, and the answer is yes — on the half that was ever in doubt

    workflow_type
      AEF ships    (7): build decommission design inception refactor specification test
      standard has (7): build decommission design inception refactor specification test
      exact match in both directions

Seven for seven, both sides extracted at run time from the files that ship them. The
`workflow_type` half of A-012 holds without qualification.

**The `owner` half holds too, but not for the reason the register implies.** v1.1 derives
`owner` from the LANE (§3: "the Lane is the sole authority-of-record for who-performs"),
and a lane can carry any label, so no owner value can require a new BPMN shape. A-012 asks
about representability and representability is not in danger. Recorded as **validated**
with that evidence.

### What the measurement turned up that A-012 does not cover

    owner
      standard names       : human agent
      AEF ships            : human claude-code
      practised in .tasks/ : agent=304  human=118  claude-code=9
      is_valid_owner() call sites in the vendored tree: 0

**Three incompatible vocabularies in simultaneous use, and nothing reconciles them.** The
standard maps to `agent`, which AEF does not ship. AEF ships `claude-code`, which the
standard does not name. This tree runs on `agent` — 304 tasks — a value absent from AEF's
own enumeration.

Nothing ever complained because **`is_valid_owner()` is defined at
`.agentic-framework/lib/enums.sh:101` and called from nowhere.** Zero call sites. A
validator that is never invoked and one that accepts everything have identical output —
the T-429 family again, this time in the vendored tree rather than ours.

Filed as **OBS-025**, deliberately NOT folded into A-012's disposition: a disposition is an
evidence claim about one statement, and smearing an unrelated defect into it is how a
register stops meaning anything. "Which is authoritative, `agent` or `claude-code`" is
AEF's question to answer, and no edit to their tree is made from here.

### Two bugs in the probe, both kept as legs

1. **Split the allowed-values cell on bare `|`.** The standard writes `build \| test \| …`;
   a plain split tears that apart and returns the first item as the entire enumeration.
   The probe reported six of AEF's seven `workflow_type`s as unmapped — a confident,
   specific, entirely wrong finding produced by an extractor that under-read in silence.
2. **Required backticks on values the `workflowType` row writes bare.** Extraction found
   nothing, and the probe exited 2. That one at least failed loudly, which is the direction
   it was built to fail in.

Both are M1 and M2. A bug that has happened once is the cheapest available test case.

### And one in the teeth

The first mutation legs used `sed` with `|` delimiters against expressions full of escaped
pipes. Two seds died with ``unknown option to `s'``, wrote no mutant file, and **the legs
went green** — a missing mutant makes the grep find nothing, which is what the leg
asserted. Replaced with a mutator that exits non-zero when its anchor is absent. T-429's
finding one layer in: a leg that passes because its mutation never applied.

### Side effect worth recording

Disposing A-012 moved T-428's register check for the first time by our own measurement
rather than a rail question: `dangling 16 → 15`, `disposed 4 → 5`, `unevidenced 0`. And
`validation_method` stayed **`TBD` on the row that now carries real evidence** — 20 of 20
still inert, exactly as OBS-021 recorded. `fw assumption validate --evidence` does not set
it. The field has still never steered a disposition.

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

bash tools/_t431-enumeration-teeth.sh
python3 tools/_t431-a012-enumeration-probe.py > /tmp/.t431-verify.out 2>&1; test $? -ne 2
git diff --quiet HEAD -- docs/standards/aef-bpmn-mapping-v1.md
git diff --quiet HEAD -- .agentic-framework
grep -q "A-012" .context/project/assumptions.yaml

# Line 2 asserts the probe can ANSWER, not that it found nothing: it exits 1 while the
# owner value sets disagree, and that disagreement is a real finding rather than a
# regression. Exit 2 — an enumeration that stopped being extractable — is the failure.
# Lines 3 and 4 are the frozen-standard and vendored-tree boundaries, asserted rather
# than promised.

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

### 2026-08-11T15:31:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-431-a-012-is-measurable-without-aef---does-t.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fc6b1505
- **Timestamp:** 2026-08-11T15:37:38Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-11T15:37:36Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
