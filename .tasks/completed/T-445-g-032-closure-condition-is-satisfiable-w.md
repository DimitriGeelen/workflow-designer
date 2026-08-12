---
id: T-445
name: "G-032 closure condition is satisfiable while the route is still broken: AEF's tree returns 1 of 112"
description: >
  TITLE FALSIFIED BY THE FIRST MEASUREMENT, KEPT SO THE CORRECTION IS TRACEABLE. AEF (DM 549 §1) fixed handover.sh both sites, measured their own tree at 1 row of 112 pending (and 1 of 3 at :386), and reported that G-032's closure condition would have been satisfied by it. Checked against the register before building: the condition already demanded line-count EQUALITY with `fw note count`, so their partial listing fails it and G-032 would NOT have closed. What survives the correction is the instrument, not the register - _t436-inbox-route-probe.sh tested rows==0 and left the equality in a failure-message string, and my tree is pinned in DEFECT so the PARTIAL and FIXED arms had never once fired. Delivered: three named states in probe and register with PARTIAL called out as worse than the zero it replaces, a mutation harness driving all three through the probe's real entry point, and G-032 as the first entry ever to carry closure_check_command.

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
created: 2026-08-11T22:52:35Z
last_update: 2026-08-11T22:59:29Z
date_finished: 2026-08-11T22:59:29Z
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

# T-445: G-032 closure condition is satisfiable while the route is still broken: AEF's tree returns 1 of 112

## Context

Found by the peer, in the peer's tree, against my register — the useful direction.

I reported the dead observation-listing route in `handover.sh` (DM 545) and registered
**G-032** with a closure condition written from **my** tree, where the block emits **0 of
24**. AEF fixed both sites and measured theirs: **1 of 112** at `:931`, and **1 of 3** at
`:386` — the site I called latent, correctly for my tree and wrongly for the class.

Their words, and the reason this is a defect and not a footnote: *"a zero could read as
'nothing pending'. One well-formed row under a '112 pending' heading reads as a section
that worked — and it is the row an eye lands on."*

So the partial answer is **worse than the empty one**. AEF then wrote that my G-032
closure condition "is written against a non-empty inbox, and ours would have satisfied
it while still being wrong."

### I checked that against the register before building anything, and it is not true

`concerns.yaml` G-032 `decision_trigger`, verbatim: *"a `## Observation Inbox` section
whose line count matches `fw note count`, **verified against a non-empty inbox**"*. The
bar is **count equality**; "non-empty inbox" is a qualifier on how it is verified, added
because an empty inbox makes the block unreachable. **Their 1-of-112 fails that
condition.** G-032 would not have closed on their tree.

I very nearly built a repair for a defect that was not there, on a peer report I had not
checked — the exact shape I have been reporting to them all week, pointed the other way.

### What IS real, and it is the half they were actually right about

Two things survive the correction:

1. **The wording invites the misreading.** The reader who misread it is the most careful
   reader this register has, holding the matching bug in their own tree. A closure
   condition whose bar can be misread as "non-empty" by that reader is under-specified,
   and the fix is to name the **partial** state explicitly rather than leave it implied
   by an equality.
2. **The instrument does not hold the bar the register states.**
   `tools/_t436-inbox-route-probe.sh` leg A tests `a_lines -eq 0` and treats every
   non-zero as CHANGED — its failure text names `fw note count` as the real bar but
   defers the comparison to whoever reads the message. A bar stated in prose inside a
   failure string is not a bar the instrument holds. On AEF's tree the probe would print
   "if this is the fix landing" about a route still dropping 111 of 112 rows.

## Acceptance Criteria

### Agent
- [x] G-032's closure condition names the **partial** state explicitly as non-closing, with AEF's 1-of-112 as the specimen — the count-equality bar was already there and is recorded as already-there, not as a fix
- [x] `_t436-inbox-route-probe.sh` distinguishes three states, not two: DEFECT (0 rows), PARTIAL (0 < rows < pending), FIXED (rows == pending); PARTIAL exits non-zero and says in words that it reads as working
- [x] The PARTIAL arm is mutation-proven — driven against a synthetic inbox that produces strictly fewer rows than pending, the probe reports PARTIAL rather than the fix landing
- [x] The FIXED arm is mutation-proven — driven against an inbox the block fully matches, the probe reports FIXED
- [x] Attribution recorded in-file: the partial state was measured by AEF, not by me, and my tree cannot exhibit it while the vendored bytes are unfixed
- [x] The register HOLDS the bar mechanically, not only in prose: G-032 carries `closure_check_command:` and `lib/gaps.py` resolves it to a verdict

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

bash tools/_t445-partial-state-mutation.sh
bash tools/_t436-inbox-route-probe.sh
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
grep -q "PARTIAL 0<rows<N" .context/project/concerns.yaml
python3 -c "import sys; sys.path.insert(0,'.agentic-framework/lib'); import gaps; from pathlib import Path; d=gaps.load_concerns_yaml(Path('.')); g=[c for c in d['concerns'] if c['id']=='G-032'][0]; sys.exit(0 if gaps.run_closure_gauge(g['closure_check_command'], project_root=Path('.'))[0]=='NOT_READY' else 1)"

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

**Symptom:** A peer holding the same bug in their own tree read my G-032 closure
condition as "non-empty inbox" and told me their still-broken route would have satisfied
it. It would not have — but the instrument backing that condition would have said
"if this is the fix landing" about a route dropping 111 of 112 rows.

**Root cause:** The bar lived in two places at two strengths. `concerns.yaml` demanded
count EQUALITY; `_t436-inbox-route-probe.sh` tested `rows -eq 0` and put the equality in
a **failure-message string**. Prose in a failure branch is documentation, not a check.

**Why structurally allowed:** My tree can only ever be in one of the three states. With
the vendored `handover.sh` unfixed, leg A is pinned at 0 forever, so PARTIAL and FIXED
were unreachable and untested — and an arm that has never fired is indistinguishable
from one that cannot. Nothing in the register requires a gap's closure condition to be
mechanically evaluable at all: `closure_check_command:` has been read by `lib/gaps.py`
since T-2185 and **carried by zero entries**, so every closure condition in this register
has been prose that a human compares by eye.

**Prevention:** `tools/_t445-partial-state-mutation.sh` drives all three states through
the probe's real entry point against fixtures, so the two arms my tree cannot reach are
exercised on every run. G-032 now carries `closure_check_command:`, making the register
answer READY/NOT_READY/UNKNOWN mechanically instead of by reading. Distinct from the fix:
the fix names the partial state; the prevention is that the naming is now executable and
its unreachable branches are proven live.

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

### 2026-08-11T22:52:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-445-g-032-closure-condition-is-satisfiable-w.md
- **Context:** Initial task creation

### 2026-08-11T22:52:51Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d003c766
- **Timestamp:** 2026-08-11T22:59:32Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#6 (Agent)** — The register HOLDS the bar mechanically, not only in prose: G-032 carries `closure_check_command:` and `lib/gaps.py` resolves it to a verdict
  - **AC-verify-mismatch** (narrow, heuristic) — `path=lib/gaps.py in: The register HOLDS the bar mechanically, not only in prose: G-032 carries `closure_check_command:` and `lib/gaps.py` resolves it to a verdict`

### 2026-08-11T22:59:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
