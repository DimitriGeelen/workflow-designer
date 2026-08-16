---
id: T-542
name: "populate cost estimates so the HV/HC and HV/LC quadrants are answerable"
description: >
  populate cost estimates so the HV/HC and HV/LC quadrants are answerable

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-16T13:51:30Z
last_update: 2026-08-16T14:34:52Z
date_finished:
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/.vendor-divergence.yaml,tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/.vendor-divergence.yaml,tests/run-bridge-tests.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:48Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/.vendor-divergence.yaml,policy/value-drivers.yaml,tests/run-bridge-tests.sh,tools/_t517-vendor-divergence.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
bvp_scores_proposed:
  - ts: '2026-08-16T14:33:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
---

# T-542: populate cost estimates so the HV/HC and HV/LC quadrants are answerable

## Context

The operator asked to focus on HV/HC and HV/LC tasks. Neither quadrant can be
answered today: `fw bvp --quadrant hv-hc` and `--quadrant hv-lc` both print
"No tasks match", with and without `--include-proposed`. T-540 measured why —
`cost_estimate:` is absent on all active tasks, so `compute_cost` returns
`source: absent`, `quadrant()` returns `-`, and the filter matches nothing.

T-540 recorded that as "`driver --init` bootstraps the value half and silently
not the cost half". That is half right and the half it got wrong matters: the
cost half EXISTS. `fw bvp estimate-cost {one,all,sweep,determinism}` is fully
built (T-1935, `lib/bvp.sh:1553`) and routes to `estimate_cost` in the vendored
estimator. It is simply **absent from `fw bvp --help`**, which lists `estimate`
but never `estimate-cost` — so the verb is undiscoverable by the only means a
reader has. Nothing was missing; a door was uncut.

Before running it over the corpus this task measures whether the number it
produces is worth having, because `blast_radius` carries weight 0.6 — the
dominant term — and is derived from the task's `components:` frontmatter list,
which the fabric populates. The fabric sits at 56 registered of 249 watched.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The three F8 cost components are measured across the non-completed corpus
      BEFORE any write, and the distribution of each is recorded here — a cost
      whose dominant term is constant is a cost that cannot sort
- [x] `fw bvp estimate-cost all` has run and `cost_estimate_proposed:` is
      present on the non-completed active tasks (59/59)
- [x] `fw bvp --quadrant hv-hc --include-proposed` and `--quadrant hv-lc
      --include-proposed` both return a non-empty ranking (13 and 17)
- [x] The `fw bvp --help` omission of `estimate-cost` is fixed, and the fix is
      declared in `.agentic-framework/.vendor-divergence.yaml` (G-008) if it
      touches vendored files
- [x] A probe defends the property that the cost composite discriminates
      (>= 3 distinct values, not all-tasks-identical), and it is wired into
      `tests/run-bridge-tests.sh`
- [x] `cost_estimate:` (confirmed) is NOT written by this task — that field is
      the operator's, same boundary as `bvp_scores:`

## What was measured

**Before any write** (59 non-completed active tasks):

| component | weight | distribution before | verdict |
|---|---|---|---|
| `blast_radius` | **0.6** | `{0: 46, 3: 13}` | binary |
| `tier` | 0.3 | `{1: 3, 2: 40, 3: 1, 4: 15}` | mostly constant |
| `effort` | 0.1 | `{6: 16, 7: 8, 8: 35}` | saturated at the cap |
| F8 composite | — | 10 distinct values, **29 of 59 tied at 1.4** | cannot sort |

`components:` was empty on **59 of 59**. So every one of the 46 non-inception
tasks reached `→0 (no-components)` and the 13 with `br=3` were *all* inceptions
arriving via `target_blast_radius`. The cost axis was `inception ? 3.6 : 1.4` —
a two-valued flag on the dominant term, dressed as a continuous measure.

The 0 is the part that matters. It is not "this task touches nothing"; it is
"the fabric has never registered this task", and it renders as the **cheapest
value on the scale** — which is precisely what an HV/LC filter promotes on. The
failure does not render as health here, it renders as *attractiveness*.

**After** (same corpus, same commands):

| component | distribution after |
|---|---|
| `blast_radius` | `{1, 3, 5, 7, 9}` — five levels, plus **absent on 14** |
| F8 composite | 13 distinct values, range 2.0–6.8, largest tie 15 |

Honest about what did *not* improve: 15 tasks still share the modal composite,
and the top of the value ranking is still the T-540 placeholder tie (12 tasks at
BVP 108 / NORM 0.40, 11 of them inceptions carrying `voi_score: 0.5`). The cost
axis sorts now; the value axis still does not, and no amount of cost work fixes
that. The three product drivers remain latent pending the operator's approval.

## What this cost the register to learn

**AEF had already named this exact shape, one population earlier.** T-2189's own
docstring reads: the count *"always returns 0 — making inceptions look
artificially cheap"*. They saw it, wrote it down, and repaired the one
population where it was visible. The same sentence was true of 100% of the
non-inception corpus and nothing re-asked. This is T-509's shape again — an
exemption granted to the case that prompted it, never generalised to the class.

Three further findings, all generic and all owed upstream (declared in
`.agentic-framework/.vendor-divergence.yaml`, findings 3–5):

1. **`score_blast_radius` returned a blind read as the cheapest value.** Fixed
   with a third evidence source (source paths named in the body *and present in
   the tree*) and, more importantly, by returning `None` when nothing is
   knowable. `None` propagates to an **omitted** `blast_radius` key, which
   `compute_cost` already reads as `source: 'absent'` → `quadrant: '-'` →
   excluded. Declining to rank is honest; ranking cheapest is not. No consumer
   change was needed — the honest state was already representable and unused.

2. **The new signal immediately scored the task template.** The first
   `estimate-cost all` run scored **T-542 itself** at `blast_radius=5`, and two
   of the four paths in its own rationale came from `templates/default.md`'s
   errexit warning. 7 of 59 tasks had no signal *except* the template. This is
   the T-541 D3 finding recurring in a second handler — and note the template's
   path citations are **shell**-comment lines, not HTML comments, so T-541's
   comment-stripping remedy would not have caught them. The general rule is
   PL-239 stated properly: subtract what every member of the corpus shares.

3. **`PROJECT_ROOT`'s fallback is wrong under vendoring** — reported, not
   patched. `parents[3]` is the repo root in AEF's layout and
   `.agentic-framework` in ours, and it lands on a directory that *exists* with
   a plausible `policy/` and `.tasks/`, so nothing errors. Found by a probe leg
   going red for the wrong reason: 5 real fixture paths scored as 3, because
   `policy/value-drivers.yaml` exists under **both** roots.

And the smaller one that cost T-540 a wrong entry in the register:
`fw bvp estimate-cost` was **fully built under T-1935** and simply absent from
`fw bvp --help`. T-540 recorded "`driver --init` bootstraps the value half and
silently not the cost half" — the cost half was there. A capability nobody can
find is indistinguishable from one nobody built, and the register recorded the
wrong one.

## Verification of the probe itself

`tools/_t542-cost-blast-radius-teeth.py`, 8 legs, **mutation-verified rather
than asserted** (PL-206 — T-541's probe passed against a broken mutant):

| mutant | killed by |
|---|---|
| existence check removed | leg 3 (+ leg 2b anti-vacuity) |
| blind read scores 0 (pre-T-542 behaviour) | legs 2, 2b, 3 |
| body-path fallback disabled | legs 1, 5 |
| template subtraction removed | leg 8 |

Each mutant was killed by the leg that owns it, not incidentally by another.

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

# The cost axis discriminates and declines to guess. rc 2 is a REFUSAL, not a pass.
python3 tools/_t542-cost-blast-radius-teeth.py
# The verb the whole task turned on is reachable from the only doc a reader has.
.agentic-framework/bin/fw bvp --help > /tmp/.t542-help 2>&1 && grep -q "estimate-cost" /tmp/.t542-help
# Both high-value quadrants answer. Deliberately NOT asserting a task count or a
# specific task id: those move with every estimate run and with the operator's
# driver approvals, and a control that goes red for someone else's change is a
# control that gets ignored. What must hold is that the filter resolves at all.
.agentic-framework/bin/fw bvp --quadrant hv-lc --include-proposed > /tmp/.t542-hvlc 2>&1 && grep -q "hv-lc" /tmp/.t542-hvlc
.agentic-framework/bin/fw bvp --quadrant hv-hc --include-proposed > /tmp/.t542-hvhc 2>&1 && grep -q "hv-hc" /tmp/.t542-hvhc
# Sovereignty: this task writes the advisory field only. `cost_estimate:` is the
# operator's, same boundary as `bvp_scores:`. Inverted grep — a match is the failure.
! grep -rq "^cost_estimate:" .tasks/active/ .tasks/completed/
# Vendored divergence is declared (G-008). Catches an estimator or lib/bvp.sh edit
# that never reached the manifest — it already caught one during this task.
python3 tools/_t517-vendor-divergence.py

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

### 2026-08-16T13:51:30Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-542-populate-cost-estimates-so-the-hvhc-and-.md
- **Context:** Initial task creation
