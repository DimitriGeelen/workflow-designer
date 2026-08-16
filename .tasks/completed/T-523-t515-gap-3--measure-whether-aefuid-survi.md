---
id: T-523
name: "_t515 gap 3 — measure whether aef:uid survives on nodes nested inside a subProcess,
  the last gap on our side of the seam"
description: >
  _t515 gap 3 — measure whether aef:uid survives on nodes nested inside a subProcess,
  the last gap on our side of the seam

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t523-nesting-teeth.py, tools/_t523-subprocess-nesting.mjs, 
      tools/_t523-xml-structure.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T14:28:47Z
last_update: '2026-08-16T14:33:44Z'
date_finished: 2026-08-15T14:43:15Z
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
  - ts: '2026-08-16T12:34:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 3
      F3: 4
      F1: 3
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=3 (prose:routing-defect-class); F3=4 
      (prose:seam-fixture-or-pin); F1=3 (prose:process-conformance)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-523: _t515 gap 3 — measure whether aef:uid survives on nodes nested inside a subProcess, the last gap on our side of the seam

## Context

`tools/_t515-external-uid-conformance.mjs` declares four things it does **not** cover. Two are
now measured: uid collision by `_t518` (two authored uids with the same value both survive —
§6.3 requires no uniqueness and the editor enforces none), and XML-attribute safety by `_t520`
(escaping was correct except newline/tab, fixed in T-521 at the shared escaper). The two
remaining are **subProcess-nested nodes** and the **reverse renderer**. The reverse renderer is
AEF-side and now blocked on their operator's inception decision about the fixture-pair contract
(rail 11912/11915) — so this is the last gap on our side of the boundary.

The measurement is not obviously "does the uid survive", because it is not yet established
that nesting is representable here at all. The editor has a `subProcess` node type with an
FC-15 "collapsed scope" marker and a `scopeOf` field, which suggests scope is modelled as a
LINK between flat nodes rather than as containment. If that is right, an imported document
with genuine `<bpmn:subProcess>` containment gets flattened, and the question becomes what
happens to the uid of a node whose parent relationship no longer exists. Either answer is a
seam fact AEF keys records on, and neither is currently written down anywhere.

Same discipline as T-518 and T-520: **characterisation, not verdict.** Nobody has ratified
what SHOULD happen to a nested node's uid, so this pins observed behaviour and goes red on a
CHANGE rather than legislating a co-designed standard from a test file. And per T-520's
lesson, verdicts come from a conforming parser — the browser's own DOMParser is the producer's
parser and will agree with the producer's defect.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The prior question is answered from the editor source and recorded: is node containment
      inside `subProcess` represented in the editor's model, or is scope a link between flat
      nodes? The answer determines what the probe can even ask
- [x] A probe stages a BPMN document carrying `aef:uid` on at least one node genuinely nested
      inside `<bpmn:subProcess>`, round-trips it through the editor, and reports a per-node
      outcome — including the subProcess element itself, not only its children
- [x] Every verdict comes from a conforming XML reader (expat, via `tools/_t520-xml-read.py`
      or equivalent). If the browser read disagrees, the disagreement is REPORTED as evidence
      rather than smoothed away
- [x] Outcomes are classified, not reduced to pass/fail — at minimum: uid survives / uid
      dropped / node dropped / containment flattened — and what is ours to change is separated
      from what the model or BPMN makes inevitable
- [x] The probe is pinned so it goes red on a CHANGE, and refuses with a distinct exit code
      when the corpus is missing, staging fails, or the negative control did not survive —
      a refusal must be distinguishable from a pass (PL-205)
- [x] The pin is proved non-vacuous: a stimulus that should move it does move it, and the
      leg that goes red does so for the NAMED reason (PL-206), not merely non-zero
- [x] `_t515`'s `does_not_cover` is updated to point at this probe — three of four gaps closed,
      with the reverse renderer named as the remainder and why it stays out of reach
- [x] Wired into `tests/run-bridge-tests.sh` with a rationale block a reader can act on; suite
      green and the T-451 unwired-guard ratchet unmoved at 67
- [x] Result posted to AEF on the rail with the finding stated plainly, including whichever
      answer is inconvenient

<!-- No Human ACs: every criterion above is a deterministic check on our own tooling.
     Removed per the template's own instruction rather than left as unchecked boilerplate.

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

# The teeth are the load-bearing check: they MUTATE the editor so nested nodes are dropped —
# making true the claim the source comment used to assert — and require the probe to go red,
# on the NESTED arm specifically, leaving the FLAT arm alone. rc 2 is a refusal, not a pass.
python3 tools/_t523-nesting-teeth.py
# The probe itself against the real tree: measured behaviour still matches the pin.
node tools/_t523-subprocess-nesting.mjs
# The false claim in parseBpmnXml is corrected in place, not just contradicted in a test file.
grep -q 'T-523 CORRECTION' src/aef-workflow-designer.html
# _t515 now names three of its four gaps as measured elsewhere, and says why the fourth stays open.
grep -q 'THREE of the four gaps' tools/_t515-external-uid-conformance.mjs
# The pin records the finding that matters — uid survives, containment does not.
python3 -c "import json; d=json.load(open('tools/_t523-nesting.pin.json')); assert d['nested']['child_a']['outcome']=='survived-flattened' and d['nested']['sub']['outcome']=='survived' and d['nested']['edge']=='preserved'"
# Deliberately NOT verifying "the bridge suite is green": global moving state would go red for
# someone else's change under a daily re-runner (T-508's learning).

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

### 2026-08-15T14:28:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-523-t515-gap-3--measure-whether-aefuid-survi.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6b525b40
- **Timestamp:** 2026-08-15T14:43:22Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#3 (Agent)** — Every verdict comes from a conforming XML reader (expat, via `tools/_t520-xml-read.py`
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t520-xml-read.py in: Every verdict comes from a conforming XML reader (expat, via `tools/_t520-xml-read.py``
- **AC#8 (Agent)** — Wired into `tests/run-bridge-tests.sh` with a rationale block a reader can act on; suite
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/run-bridge-tests.sh in: Wired into `tests/run-bridge-tests.sh` with a rationale block a reader can act on; suite`

### 2026-08-15T14:43:15Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
