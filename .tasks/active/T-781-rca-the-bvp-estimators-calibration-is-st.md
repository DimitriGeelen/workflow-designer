---
id: T-781
name: "RCA: the BVP estimator's calibration is structurally blind to un-started work,
  and the defect is upstream in vendored AEF code"
description: >
  Three rounds of autonomous selection under the procAsFit mandate were governed by
  BVP quadrants, and the instrument producing those quadrants misreported the backlog
  in at least four distinct ways. The estimator is AEF's, vendored at .agentic-framework/agents/termlink/bvp-estimator/estimator.py,
  so any calibration defect is upstream and shared by every consumer that vendors
  it - which is why this RCA is written for transmission rather than for local consumption.
  Scope: establish the root cause chain behind (a) 46 of 149 active tasks carrying
  no cost proposal at all, (b) 45 of 103 ranked tasks rendering quadrant '-' and being
  invisible to quadrant-ordered selection, (c) an entire in-progress arc silently
  absent from fw bvp arcs, and (d) zero confirmed scores project-wide against a sovereignty-gated
  confirm verb. Deliverable is a measured RCA document plus a TermLink transmission
  to 999-AEF. Research is not authorization: this task diagnoses and reports, it does
  not change the estimator.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bvp, calibration, rca, aef]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T20:48:56Z
last_update: 2026-09-21T20:53:29Z
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
  - ts: '2026-09-21T20:53:26Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T20:53:27Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/reports/T-781-bvp-calibration-rca.md,docs/research/executable-workflow/arc-0-exit-clauses.yaml,tools/_t781-bvp-calibration-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-781: RCA: the BVP estimator's calibration is structurally blind to un-started work, and the defect is upstream in vendored AEF code

## Context

Full RCA: `docs/reports/T-781-bvp-calibration-rca.md`. Reproduce every figure with
`python3 tools/_t781-bvp-calibration-census.py`. Transmitted to 999-AEF at `agent-chat-arc`
@1606.

## RCA

**Symptom:** Three rounds of autonomous selection were governed by BVP quadrants that
misreported the backlog. 46 of 149 active tasks carried no cost proposal; 45 of 103 ranked
tasks rendered quadrant `-` and were invisible to selection; an entire in-progress arc — the
*focused* one — was silently absent from `fw bvp arcs`; and the census's verdict "0 high-value
tasks are agent-executable" was carried across three sessions as a property of the backlog when
it was an artefact of incomplete measurement.

**Root cause:** The F8 cost composite has three terms, two of which are near-constant on real
data — `tier=2` on 86%, `effort=8` on 87.5%, the latter because `effort = clamp(body_lines//50
+ ac_count, 1, 8)` saturates on the line-count term alone for any task body over ~400 lines.
So `cost = 0.6·blast_radius + 1.4`, verified exactly against live output (br 1→2.0, 3→3.2,
5→4.4). The single live term, `blast_radius`, resolves from `components:` — which is populated
from git history **at completion** — and falls back to source paths named in the body prose.
Only 13% of tasks declare `components:`, so ~79% of costed tasks take their dominant cost term
from documentation density. Measured consequence: `blast_radius` is present on 94% of
work-completed tasks and **42% of captured ones**. A task's cost is least knowable precisely
while it is still un-started, which is the only state a selection mechanism cares about.

**Why structurally allowed:** Nothing asserts that the ranker's input population equals the
backlog. `score_blast_radius` correctly declines to rank without a signal (T-542/T-2189 —
*"declining to rank is honest; ranking it cheapest is not"*, and a blind 0 on the 0.6-weight
term is the defect they already fixed), but the exclusion is **silent**: no output says "N
tasks could not be ranked", they are simply absent. That silence composes upward —
`lib/bvp.sh` takes its medians over rows that *have* a cost, so the high/low boundary is
calibrated on the elaborated population, and the arc rollup drops an arc with no rankable
constituents without a marker. Three layers each behaved correctly in isolation; no layer owned
the question "is what I am ranking the same set as what exists?"

**Prevention:** `tools/_t781-bvp-calibration-census.py` is committed and re-derives every
figure, so the next reader measures rather than trusts. `tools/_t777-selection-eligibility-census.py`
now carries the `exhausted` class with negative controls in both directions, and its control
line distinguishes "nothing is executable" from "the only candidate is barred". The structural
half is **not** closed by this task and must not be claimed as closed: it is registered as
**G-076** with a closure condition requiring both that the count move AND that a task with
genuinely no cost signal still declines to rank — so a "fix" that reinstates a default
`blast_radius` cannot satisfy it by re-opening T-542. The upstream half is transmitted to the
code's owner at @1606; RC-7 (D2 no-signal at 84%) is marked undetermined pending a second
corpus, because one repository cannot distinguish a narrow detector from unrepresentative prose.

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Measured from the population side, 780 task files (150 active / 630 completed).**
      Every figure in the RCA comes from `tools/_t781-bvp-calibration-census.py`, committed
      alongside it so a later reader re-derives rather than trusts. The chain:

      **RC-1 — the cost composite has one effective degree of freedom.** `tier=2` on 668/778
      (86%), `effort=8` on 681/778 (87.5%); where both hold the trailing terms sum to a
      constant, so `cost = 0.6·blast_radius + 1.4`. Checked against live output, exact three
      for three: br 1→2.0, 3→3.2, 5→4.4.

      **RC-2** `effort = clamp(body_lines//50 + ac_count, 1, 8)` — a 400-line body saturates on
      the line term alone. **RC-3** only 102/780 (13%) declare `components:`, so ~79% of costed
      tasks take their dominant cost term from prose. **RC-4** blast_radius present by status:
      work-completed 94%, started-work 91%, **captured 42%** — the blindness tracks lifecycle,
      and `components:` resolves at completion, so cost is least knowable while work is still
      only captured. **RC-6** `lib/bvp.sh` takes medians over rows that *have* a cost, so the
      yardstick is built from the elaborated population and ~half the rankable set is
      "high-value" by construction; membership moved 31→35→36→35 this session from scoring
      activity alone.

- [x] **Defect and correct-but-consequential are separated, and the RCA says so first.**
      RC-5 states plainly that `score_blast_radius` returning `None` is **correct** and that
      nothing in the document argues for re-opening it — quoting their own docstring,
      *"Declining to rank is honest; ranking it cheapest is not"*, and naming T-2189/T-542 as
      the defect it closed. I nearly filed it as a bug; a report that told AEF to re-open a
      defect they had already fixed would have been worse than sending nothing.

      Only the **separable** consequence is reported: the exclusion is silent, and it
      propagates to arc level (RC-6b — `fw bvp arcs` shows two of three in-progress arcs, the
      missing one being the focused arc, dropped without a marker).

- [x] **Local / upstream split tabulated, with one row honestly marked undetermined.**
      Upstream: RC-1, RC-4, RC-5 (reporting only), RC-6, RC-6b, RC-8. Shared: RC-2 (their
      clamp, our long bodies) and RC-3 (their precedence, our 13% `components:` hygiene).
      **RC-7 is marked undetermined rather than assigned** — D2 no-signal at 84% is equally
      consistent with a narrow detector and with our prose not using the vocabulary it looks
      for, and one corpus cannot separate those.

- [x] **Transmitted on `agent-chat-arc` at @1606**, `event_type: finding`,
      `conversation_id: BVP-CALIB-RCA-832`, attribution `from_project: 832-Workflow-designer`.

      **Numbers carried inline, not as a file reference** — they cannot read our disk, so a
      path would have been a citation to nothing. The full per-driver table went in the body.

      **One bounded ask, not a wishlist:** their D2 and F2 no-signal rates over their own
      scored corpus. Framed so either answer pays: if theirs are comparably high the detector
      is narrow and it is worth their time; if theirs are low the finding is about our writing
      and we fix it here. Same shape as the round-2 ask that worked in the last exchange — one
      command, one number, both outcomes named in advance.

      **Ratifies nothing, and said so in the message.** Our Arc-0 clause state is unchanged:
      `attestation: null`, `definition_ratified: false`, `blocks_arc_0_exit: true`. Transport
      evidence is recorded as transport.

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
         1. Run `bin/fw reviewer T-781`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-781 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

test -f docs/reports/T-781-bvp-calibration-rca.md
python3 tools/_t781-bvp-calibration-census.py > /dev/null 2>&1
grep -q 'Declining to rank is honest' docs/reports/T-781-bvp-calibration-rca.md
grep -q 'do not .fix. this' docs/reports/T-781-bvp-calibration-rca.md
grep -q 'undetermined' docs/reports/T-781-bvp-calibration-rca.md
python3 -c "import yaml,sys; y=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml')); s=open('docs/research/executable-workflow/arc-0-exit-clauses.yaml').read(); sys.exit(0 if 'blocks_arc_0_exit: true' in s.lower() else 1)"

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
     fw inception decide T-781 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T20:48:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-781-rca-the-bvp-estimators-calibration-is-st.md
- **Context:** Initial task creation
