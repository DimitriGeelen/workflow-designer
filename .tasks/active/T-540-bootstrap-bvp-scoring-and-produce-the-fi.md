---
id: T-540
name: "bootstrap BVP scoring and produce the first ranking of actionable work"
description: >
  bootstrap BVP scoring and produce the first ranking of actionable work

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
created: 2026-08-16T12:32:01Z
last_update: '2026-08-16T14:33:05Z'
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:30Z'
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
  - ts: '2026-08-16T14:33:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 1
      F1: 3
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=1 (prose:AEF seam-incidental); F1=3 (prose:process-conformance)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/termlink/bvp-estimator/estimator.py,policy/bvp-scoring-rubric.md,policy/value-drivers.yaml,tools/_t352-p011-errexit-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/termlink/bvp-estimator/estimator.py,policy/bvp-scoring-rubric.md,policy/value-drivers.yaml);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-540: bootstrap BVP scoring and produce the first ranking of actionable work

## Context

Operator asked for a BVP. `fw bvp` errors out: `policy/value-drivers.yaml` does not exist in this
project. BVP has never been bootstrapped here.

**Measured coverage before starting: 0 of 539 task files carry a real score.** The first grep said
494 and was wrong — `bvp_scores:` and `bvp_scores_proposed:` appear as *commented template lines*
in every task file created since the newer template landed, so a naive `grep -rl` matches the
template, not the data. Anchoring to `^bvp_scores:` gives 0 / 0 / 0 for scores, proposed scores and
cost estimates. Recorded because it is the same failure this week's five findings share — a count
standing in for the thing counted — and because a wrong 494 would have made this task look like a
repair job rather than a bootstrap.

**The driver-fit question is the real content of this task.** `fw bvp driver --init` copies
AEF's `policy/value-drivers.yaml` v3. D1–D4 are the Constitutional Directives and transfer
cleanly. The five *free* drivers do not obviously transfer: F-RECALL, F-AUTONOMY, F3
(V_PROMPT_QUALITY), F1 (V_CONTEXT_FABRIC) and F2 (V_COMPONENT_FABRIC) are axes for building an
agentic framework, and this project is a BPMN workflow designer that *uses* one. Importing them
unexamined would rank product work against framework-development value. The free-driver slots are
also at cap (5 of 5), so adopting them wholesale means there is no room to add an axis that
actually describes this project's focus without dropping one.

## Results

Bootstrapped (`policy/value-drivers.yaml` + `policy/bvp-scoring-rubric.md`), estimator run over
**540 tasks in 34.7s, 540 wrote / 0 errored**, ranking produced. Top of the ranking:

| task | BVP | norm | name |
|---|---|---|---|
| T-432 | **111** | 0.41 | Full fw audit reports 60 FAIL across non-structure sections — never assessed |
| T-155, T-184, T-185, T-186, T-277, T-279, T-280, T-281, T-282, T-301, T-309, T-357, T-426, T-498, T-501 | **108** | 0.40 | *fifteen-way tie* |
| T-344 | 104 | 0.39 | fabric watch-patterns.yaml is the untailored fw copy |

T-432's breakdown: D1 4×9=36, D2 4×7=28, D3 0, D4 2×3=6, F-RECALL 2×6=12,
F-AUTONOMY 4×4=16, F3 0, F1 1×7=7, F2 1×6=6 → **111**.

### The ranking runs. It is not yet decision-grade, and that is the finding.

Measured across the 69 active tasks that now carry proposed scores:

| driver | weight | non-zero | mean | values it ever takes |
|---|---|---|---|---|
| D1 Antifragility | **9** | 69/69 | 3.57 | **{2, 4}** |
| D2 Reliability | 7 | 20/69 | 0.64 | {0, 2, 4} |
| D3 Usability | 5 | 60/69 | 1.80 | {0, 2, 4} |
| D4 Portability | 3 | 68/69 | 2.13 | {0, 2, 3, 4} |
| F-RECALL | 6 | 45/69 | 1.38 | {0, 1, 2, 3} |
| F-AUTONOMY | 4 | 15/69 | 0.46 | {0, 2, 4} |
| F3 V_PROMPT_QUALITY | 7 | 17/69 | 0.55 | {0, 1, 2, 3} |
| F1 V_CONTEXT_FABRIC | 7 | 17/69 | 0.45 | {0, 1, 2} |
| F2 V_COMPONENT_FABRIC | 6 | 27/69 | 0.59 | {0, 1, 2} |

Four things fall out, and none of them are opinion:

1. **The heaviest driver discriminates the least.** D1 carries weight 9 and takes exactly two
   values across the whole corpus, 2 or 4. It is a binary flag worth a flat 18-point gap. The
   single loudest term in the model sorts every task into one of two buckets.
2. **24 distinct totals across 69 tasks**, with a 16-way tie at 52 and a **15-way tie at the top
   band**. A ranking whose first row is followed by fifteen identical rows cannot answer "what
   next" — it can band work coarsely and nothing finer.
3. **No driver ever scores 5.** The top rubric level is unreachable by the v1 heuristic estimator
   on this corpus, so every rubric's ceiling is decorative and the effective scale is 0–4.
4. **Cost is absent for all 69.** `cost_estimate` is empty everywhere, so the `COST` and `QUAD`
   columns are blank, `--quadrant` filters over nothing, and `auto_promote` — which gates on
   `cost_max` — could never fire even if enabled. F8 needs `blast_radius`, which needs fabric
   registration, and the fabric is at 56 of 248 watched files (22%, three standing audit warns).
   **The cost half of BVP is not bootstrapped by `driver --init` and nothing said so.**

### Why the top band is a 15-way tie — it is a placeholder, not a judgement

Composition of the tie at 108: **14 inception tasks and one build task landing there by
coincidence** (T-426). Thirteen of the fourteen carry `voi_score: 0.5`; T-155 carries none.

`inception_scoring_exception` (T-2189) routes every `workflow_type: inception` through
`_score_inception_voi`, which returns **the same score for every driver** — rank between
inceptions is voi alone. T-2193 backfilled historic inceptions with a default `voi_score: 0.5`
so they would rank rather than null out. Nothing has scored them for real since. `0.5 × 5 = 2.5`,
rounds to 2, on all nine drivers, for all thirteen.

So the top of this ranking is thirteen tasks sorted by a backfill default, and T-155 sitting with
them on the grandfather path (`→2 (voi-absent-grandfathered)`). The ranking is not wrong; it is
**reporting a placeholder with the same confidence it reports a measurement** — the same shape as
this week's other five findings, and the reason the tie exists at all.

### The three requested drivers cannot be scored by the estimator today — measured, not inferred

Operator asked for three global drivers, **all at weight 9**: **A** workflow routing / clean
workflows, **B** integration into AEF, **C** workflow capability supporting a software-development
process built on the workflows. These are the axes the fit analysis below says are missing, so the
direction is right. The mechanism is not ready for them.

`estimate_task` dispatches on a hand-written handler table (`estimator.py:2295-2345`). Every
active driver — D1–D4, F-RECALL, F-AUTONOMY, F3/F1/F2 via `_load_driver_aliases()` — has a
dedicated Python scorer. Anything else falls through to `score_free_driver`
(`estimator.py:2225`), which is **keyword-on-driver-id only**: it looks for the driver's own id as
a literal substring in the task body/tags, scores 1–2 on hit count, 0 otherwise.

Ran the real `estimate_task` over the 69 active tasks with three hypothetical drivers
(`F-ROUTING`, `F-AEF-INTEGRATION`, `F-SDLC` — weights are irrelevant to this probe, which measures
whether the estimator can produce a *score* at all):

| | non-inception (55) | inception (14) |
|---|---|---|
| tasks scoring non-zero | **0** | 14 |
| score returned | 0 | **2, identical on every driver** |

All three ids returned byte-identical results — 14/69 non-zero, mean 0.41 — which is the tell:
the hits are not the ids matching anything, they are the inception voi echo firing regardless of
driver. **On real build work the three new drivers would score zero everywhere.**

The consequence is worse than inert. At the requested weights (9 / 9 / 9) they would add
`(9+9+9) × 2 = 54` points to **every inception** and `0` to **every build task**, driving all
fourteen inceptions decisively to the top of the ranking for a reason unrelated to routing, AEF
integration or SDLC support. For scale: T-432 currently leads the whole ranking on 111.

A second consequence is structural and holds even once the handlers exist. Three drivers at weight
9 carry **27 combined weight against the Constitutional chassis's 24** (D1 9 + D2 7 + D3 5 + D4 3).
The free drivers would outweigh D1–D4 put together, and each individually ties D1 Antifragility as
the loudest single term in the model. That may well be the intent — this project's value genuinely
is workflow routing, the AEF seam and SDLC support, and the directives are means rather than ends
here. Recorded so it is a decision rather than a side effect; the weights are the operator's to
set and I have not changed them.

**What the drivers need to work:** a dedicated `score_*` handler each, in
`.agentic-framework/agents/termlink/bvp-estimator/estimator.py`, plus a rubric in
`policy/bvp-scoring-rubric.md`. That is vendored AEF code — fixable in-tree and upstreamable under
G-008, but it is estimator work, not a config change. Filed as the follow-up rather than smuggled
into this task.

### Driver fit — the five free drivers are AEF's, not this project's

D1–D4 are the Constitutional Directives and transfer without argument. The free drivers were
selected to rank work on *building an agentic framework*. This project is a BPMN workflow designer
that consumes one. The numbers agree: F1 (V_CONTEXT_FABRIC, weight 7) fires on 17 of 69 with mean
0.45, F-AUTONOMY on 15 of 69 with mean 0.46, F3 on 17 of 69 with mean 0.55. Three drivers carrying
a combined weight of 18 contribute almost nothing to rank order here, while no driver at all
describes the axes this project actually competes on — BPMN standard conformance, round-trip
fidelity, editor ergonomics, or the AEF seam.

**Free-driver slots are at cap: 5 of 5 (9 of 9 total).** Adding a driver that fits this project
therefore requires dropping one, which is a policy edit and §ACD-gated. Put to the operator; not
acted on.

## Acceptance Criteria

### Agent
- [x] `policy/value-drivers.yaml` exists, parses as YAML, and `fw bvp` no longer exits on the
      missing-policy error.
- [x] Every non-completed active task carries `bvp_scores_proposed:` — i.e. the estimator ran over
      the real corpus, not a sample. Verified by an anchored `^bvp_scores_proposed:` count against
      the active task count, not by a template-matching grep.
- [x] A ranking of actionable work is produced and recorded in this task, with the top entries
      named and their driver breakdown shown for at least the top item.
- [x] **No `bvp_scores:` written under agent control.** `fw bvp confirm` is the sovereignty
      boundary (F7/D8, §ACD-gated); an autonomous directive delegates initiative, not authority.
      Verified by an anchored `^bvp_scores:` count of 0 across all task files.
- [x] **Driver fit assessed against this project, not assumed.** Each of the five imported free
      drivers is judged transferable or not, with a reason, and the finding is put to the operator
      rather than acted on — changing driver weights or membership is §ACD-gated.
- [x] **The three operator-requested drivers filed to the approval queue, not applied.** Proposed
      via `fw bvp driver --propose` — verified non-Sovereign by reading `_driver_propose`
      (`lib/bvp.sh:1011`), which carries no `acd_gate` call, stamps `actor_prefix: 'agent'` under
      `$CLAUDECODE=1` and writes to `.context/bvp-driver-proposals.jsonl` rather than `policy/`.
      `_driver_add` (`lib/bvp.sh:~941`) *does* gate, and `acd_gate` (`lib/bvp.sh:91-96`) refuses
      under `$CLAUDECODE=1` without `--i-am-human`/`--from-watchtower`. Passing that flag on the
      operator's behalf would be the agent asserting the operator's own sovereignty marker, which
      is the one thing the flag exists to prevent.

<!-- T-621: this criterion named the operator as decider while filed under ### Agent, which
     made it invisible to /approvals while P-010 blocked completion on it. Moved verbatim in
     substance to ### Human below. Guard: tools/_t621-operator-ac-classification-guard.py -->

**Operator ruling on the three driver proposals has moved to the `### Human` section below.**
It was never an agent-verifiable criterion: `fw bvp driver --add/--remove` and `fw bvp confirm`
are §ACD-gated and refuse under `$CLAUDECODE=1`, so the agent cannot satisfy it even in
principle.

### Proposals filed (pending operator approval)

| id | driver | weight | proposed drop | drop rationale (measured over 69 active tasks) |
|---|---|---|---|---|
| `P-bced1426` | `V_WORKFLOW_ROUTING` | 9 | F1 V_CONTEXT_FABRIC | 17/69 non-zero, mean 0.45 — weakest in the free set |
| `P-0b1db872` | `V_AEF_INTEGRATION` | 9 | F3 V_PROMPT_QUALITY | 17/69 non-zero, mean 0.55 — framework-authoring axis |
| `P-86588453` | `V_SDLC_ENABLEMENT` | 9 | F-AUTONOMY | 15/69 non-zero, mean 0.46 — AEF's axis, not this project's |

Kept: **F-RECALL** (45/69, mean 1.38 — the strongest free driver and genuinely cross-cutting) and
**F2 V_COMPONENT_FABRIC** (27/69, mean 0.59 — the fabric is load-bearing here because `blast_radius`
feeds the F8 cost composite, so dropping it would further damage the cost side that is already
unpopulated).

Approve at Watchtower `/approvals` (BVP Driver Proposals) or `/bvp`. Each proposal's rationale
carries the estimator caveat, so it cannot be approved without the reader seeing that the driver
scores 0 until a handler exists.

### Human

- [ ] [REVIEW] Approve or reject the three driver proposals, and rule on the displaced drivers

  **Why this is yours:** the driver register is §ACD-gated — `fw bvp driver --add/--remove`
  and `fw bvp confirm` refuse under `$CLAUDECODE=1`. The cap is 9 total (`lib/bvp.sh:950`) and
  the register is already at 9 (4 protected + 5 free), so **each add requires a drop**. The
  drops below were proposed on measured contribution across 69 active tasks, not on taste.

  | id | driver to add | weight | proposed drop | drop rationale (measured) |
  |---|---|---|---|---|
  | `P-bced1426` | `V_WORKFLOW_ROUTING` | 9 | F1 `V_CONTEXT_FABRIC` | 17/69 non-zero, mean 0.45 — weakest in the free set |
  | `P-0b1db872` | `V_AEF_INTEGRATION` | 9 | F3 `V_PROMPT_QUALITY` | 17/69 non-zero, mean 0.55 — framework-authoring axis |
  | `P-86588453` | `V_SDLC_ENABLEMENT` | 9 | F-AUTONOMY | 15/69 non-zero, mean 0.46 — AEF's axis, not this project's |

  **Steps:**
  1. Review the three rows above. Each is independent — you may take none, some, or all.
  2. For each one you accept, run (single line, substituting the row's values):
     `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw bvp driver --add "V_WORKFLOW_ROUTING" --weight 9 --drop F1 --rationale "<your reason>" --i-am-human`
  3. For any you reject, no command is needed — rejection is the default and the proposal lapses.

  **Expected:** `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw bvp driver --list`
  shows the drivers you accepted, and the register still totals 9.

  **If not:** If the cap makes the trade unattractive, say so and the agent will re-measure
  contribution with a different window rather than pushing the same three proposals again.
  Note the agent must NOT pass `--i-am-human` on your behalf — that flag asserts your
  sovereignty marker, so these commands are yours to run or not run.

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

# The policy the whole subsystem reads must parse.
python3 -c "import yaml; yaml.safe_load(open('policy/value-drivers.yaml'))"
# fw bvp must get past the missing-policy error and produce a ranking table.
.agentic-framework/bin/fw bvp --include-proposed > /tmp/.t540-bvp.out 2>&1 && grep -q "BVP" /tmp/.t540-bvp.out
# Sovereignty: zero confirmed scores written under agent control. Anchored, so the
# commented template lines in every task file cannot satisfy it (the 494 trap).
test "$(grep -rlE '^bvp_scores:' .tasks/ | wc -l)" -eq 0
# The estimator ran over the real corpus, not a sample.
test "$(grep -rlE '^bvp_scores_proposed:' .tasks/active/ | wc -l)" -ge 60

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

## Recommendation

**Recommendation:** Ready for your ruling. The scoring bootstrap is done and measured; the
driver-register change is yours because the CLI refuses it from me.

**What was established:** 69 active tasks now carry estimator-proposed scores, the ranking runs,
and `fw bvp --quadrant hv-lc/hv-hc --include-proposed` returns a usable ordering. No task carries
confirmed `bvp_scores:` — correctly, since `fw bvp confirm` is §ACD-gated.

**Why the remaining criterion is yours:** `fw bvp driver --add/--remove` and `fw bvp confirm`
refuse under `$CLAUDECODE=1` unless passed `--i-am-human`. That flag asserts *your* sovereignty
marker, so passing it on your behalf is not something I will do — it would make the gate
decorative. The cap is 9 (`lib/bvp.sh:950`) and the register is full, so **each add requires a
drop**, and the three proposed drops are ranked on measured contribution across 69 tasks, not on
taste.

**Why it sat invisible until now:** filed under `### Agent` while naming you as approver, so
`/approvals` never surfaced it. T-621 reclassified it and guarded the shape.

**Each of the three rows is independent** — take none, some, or all. Rejection needs no command.

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

### 2026-08-16T12:32:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-540-bootstrap-bvp-scoring-and-produce-the-fi.md
- **Context:** Initial task creation
