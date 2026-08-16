---
id: T-341
name: "An unresolvable flowNodeRef silently reassigns the orphaned node to the human
  (sovereignty) lane"
description: >
  A node whose lane reference does not resolve is re-homed to the human lane with
  no notice. Measured framework-to-human on 5 of 24 corpus maps. No data loss (aef:uid
  and all counts preserved) but lane is WHO in this project (IW-9), so an unresolvable
  reference silently promotes a step into the sovereignty lane and renumbers its siblings
  display ids. Found by T-339.

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
created: 2026-08-02T10:39:07Z
last_update: '2026-08-16T13:57:12Z'
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
  - ts: '2026-08-16T12:33:27Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:12Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-397-import-repair-semantics-brief.md,src/aef-workflow-designer.html,tools/_norec-verify.py,tools/_t338-input-fidelity-cdp.mjs);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-341: An unresolvable flowNodeRef silently reassigns the orphaned node to the human (sovereignty) lane

## Context

A `<bpmn:flowNodeRef>` naming a node that does not exist leaves that node with no lane. The
importer then assigns it to the **`human`** lane. Measured by T-339 over all 24 corpus maps:
`framework→human` on 5 of them (the rest were already in `human`, so nothing was visible).

**This is not data loss.** Every `aef:uid` survives, and node/flow/lane counts are unchanged —
which is exactly why the existing instruments were all green on it. What changes is *semantics*:
lane is **who** in this project (IW-9, "Lane = who; workflow_type = kind"), and the Authority
Model puts Human at SOVEREIGNTY. So an unresolvable reference silently promotes a step into the
sovereignty lane. It also recomputes that node's display id (`frw_6_x` → `hum_1_x`) and renumbers
its siblings, because display ids are derived from lane + ordinal + name.

**How it was nearly mis-measured, twice** (worth keeping — both traps are general):
1. Keyed on display id, the before/after comparison measures *renumbering*, not re-homing. It
   read 2 where the answer is 5, and on one map read "still present" because a *different* node
   had inherited the vacated name.
2. Keyed on uid but baselined on the *mutated* input, the comparison excludes the victim — the
   mutation replaces its ref with a ghost, so the one node whose fate is the question is not in
   the comparison set. That version reported 0, confidently. Baseline must come from the
   ORIGINAL document.

**Decision needed, not obvious.** An unassigned node must go somewhere. The question is whether
the default should be the sovereignty lane, and whether the reassignment should be announced
(a validator finding) rather than silent. Related: `E-XML-LANEREF-DANGLING` is one of the three
ERROR rules T-309 IW-3 measured as *repaired inside `parseBpmnXml`* — so no surface can ever
show it. This task and that finding are the same seam.

## CORRECTION (2026-08-03, measured) — the destination is POSITIONAL, not the sovereignty lane

**This task's own title and description are wrong, and the ruling they ask for is the wrong
ruling.** `parseBpmnXml` does not assign orphans to `human`. It says:

```js
let laneId = lanes[0]?.id;      // src/aef-workflow-designer.html:9751
```

— the **first lane declared in the laneSet**. `human` is first on only **13 of the 24** rendered
corpus maps; `agent` is first on 10 and `working` on 1. So "reassigns to the human (sovereignty)
lane" is true on just over half the corpus and false on the rest.

**Why the existing figure could not have caught this.** T-339's mutation ghosts the *first*
`<bpmn:flowNodeRef>` in the document, which belongs to the first **non-empty** lane. On a
human-first map with an empty human lane that reads `framework→human` — and that reading is
predicted *equally well* by both hypotheses. A measurement consistent with both is evidence for
neither, and the prose then took the semantic one because it was the alarming one.

**The discriminating measurement** (`tools/_t341-orphan-lane-probe.mjs`): orphan a node belonging
to a lane *other* than `lanes[0]`, on maps whose first lane is not `human`, and see where it
lands. The probe refuses to emit a verdict unless the population actually contains more than one
distinct first-lane value — otherwise both hypotheses predict the same thing and the run proves
nothing. Victim identity is read from the **original** document, per trap 2 above.

Result, 24 maps probed, 0 skipped, first-lane values seen = `agent, human, working`:

| measure | result |
|---|---|
| landed in the **first declared lane** | **24 / 24** |
| landed in the `human` lane | 13 / 24 |

**VERDICT: POSITIONAL.**

**Why this makes the defect worse rather than milder.** "Always sovereignty" would at least be a
stated, auditable policy that happens to be wrong. Positional means **WHO owns an orphaned node is
decided by laneSet declaration order** — and this project explicitly treats that order as
adjustable presentation. `tools/validate-workflow.py:1335` emits, as remedy advice:

> `every node on both sides crosses, so this is a wholesale inversion: reorder the laneSet (zero-semantic repair)`

Stated precisely, because the contradiction is conditional rather than flat: reordering a laneSet
*is* zero-semantic **while every `flowNodeRef` resolves**. Introduce one dangling ref and the same
reorder silently changes which authority owns the orphan. The advice carries no such condition,
and nothing checks for the condition before offering it.

**What this does NOT change:** every `aef:uid` still survives, node/flow/lane counts are still
unchanged, and `LANE-REHOMED+UID-KEPT` in `tools/_t338-input-fidelity-cdp.mjs` is still the
correct gated verdict. The defect was never data loss. It is authority assignment — and the
measurement moves it from *the wrong lane* to *no lane policy at all*.


## Recommendation

**Recommendation:** ABSTAIN — the agent declines to recommend, and the two positions below
are what you are being asked to reconcile.

> **2026-08-12 (T-454) — I tried to make this parseable and nearly got it wrong.** This block
> opened with "Option **(2) fixed lane by authority**", which `tools/_norec-verify.py` cannot
> read, so the task showed in your queue as having nothing to act on. My first edit simply
> re-tokenised it to `GO on option (2)`. That was wrong, and I reverted it:
>
> **Two positions exist in this tree, five days apart, and they disagree about whether an
> agent should recommend here at all.**
>
> - **2026-08-03** (`fc8e7cc7`, below, unchanged) — proposes option (2) + announce, explicitly
>   framed as *"a proposal, ruling is yours"*.
> - **2026-08-08** (`e361047c`, `docs/reports/T-397-import-repair-semantics-brief.md:34,211`)
>   — the consolidated brief lists Q2a as **"operator only — no agent recommendation"**, on
>   the ground that *"Q1 has a ratified precedent. Q2 has none, and should not acquire one
>   from an agent."* The brief reproduces the three options *without* endorsing one.
>
> The later position is the more restrictive one, and it is restrictive about sovereignty:
> which lane authority defaults to when a reference fails is a question about where power
> lands, not an implementation choice. Promoting the earlier proposal to a machine-readable
> GO would have put a superseded verdict in front of you wearing the same badge as a live
> one — the precise failure this whole task exists to stop.
>
> **What I am NOT doing:** deciding which of my own two positions is current. That choice is
> the sovereignty question itself, so resolving it silently would beg it.
>
> The 2026-08-03 analysis is preserved verbatim below because it is good evidence *for* a
> ruling even where it is not a recommendation — the probe results and code anchors hold
> regardless of who decides.

**Rationale:** The three options differ in what happens when a reference fails, and only one of
them cannot make things *worse* than the author wrote. (1) positional lets a presentation-level
edit move authority, and leaves the validator advising a laneSet reorder as a "zero-semantic
repair" while that reorder is not semantically neutral in the presence of a dangling ref. (3)
refuse-to-place is the most correct in principle and the most costly in practice: it makes the
designer unable to open a document it could otherwise repair, which is the same failure mode
rejected as option (c) in T-337 one task ago. (2) keeps the document openable while guaranteeing
the failure direction is *demotion, never promotion* — an unresolvable reference can lose a step's
authority, which is visible and recoverable, but can never silently grant sovereignty. Announcing
is orthogonal and cheap, and without it the repair stays invisible: `E-XML-LANEREF-DANGLING`
exists as an ERROR rule that no surface can ever show, because `parseBpmnXml` repairs the
condition before anything can report it.

**Evidence:** `tools/_t341-orphan-lane-probe.mjs` — 24/24 orphans land in the first *declared*
lane, 13/24 in `human`, across three distinct first-lane values (`agent`, `human`, `working`);
the probe withholds a verdict unless that variation exists, so it could have returned SEMANTIC.
`src/aef-workflow-designer.html:9751` is `let laneId = lanes[0]?.id`.
`tools/validate-workflow.py:1335` is the unconditioned "zero-semantic repair" advice.
`tools/_t338-input-fidelity-cdp.mjs` gates the behaviour today as
`flowNodeRef-dangling: LANE-REHOMED+UID-KEPT`.

**Known gap in this recommendation:** option (2) needs a tie-break for documents with no
authority ordering. `context-memory` lanes by memory type (Working / Project / Episodic), so all
three carry `authority="none"` — the same map that already makes `W-LANE-NO-OWNER` fire seven
times and that T-189 parks as a v1.1 question. Whatever you rule, that map has no lowest-authority
lane to fall to, and (2) reduces to (1) or (3) there. I have not resolved it because the same
open v1.1 question decides it.


## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The question the operator is being asked is the right one.** The filed question ("should
      the default be the sovereignty lane?") presupposes a semantic default that does not exist.
      Discriminating probe built and run: **24/24 land in the first DECLARED lane, 13/24 in
      `human`**, over a population containing three distinct first-lane values — and the probe
      withholds its verdict if that variation is absent, so the result could have come out the
      other way. See `## CORRECTION`.

- [ ] **BLOCKED on the Human AC below** — the repair is surfaced rather than silent (interacts
      with T-309 IW-1/IW-3)
- [ ] **BLOCKED on the Human AC below** — `EXPECTED_REFS` in `tools/_t338-input-fidelity-cdp.mjs`
      updated to record the change
- [ ] **BLOCKED on the Human AC below** — bridge suite green with the changed expectation

**Every remaining agent AC is downstream of a ruling an agent may not make.** They are left
unticked rather than reworded into something satisfiable; a task whose scope is blocked should
look blocked.

### Human

- [ ] [REVIEW] **Rule on the default-lane policy for an orphaned flow node.**

  > **Consolidated view: `docs/reports/T-397-import-repair-semantics-brief.md`.** One of four
  > open rulings. The brief classifies this one as **Q2 (fabrication)** and holds it apart from
  > the T-340/T-347 fidelity rulings on purpose: those decide what we do with content we failed
  > to read, this decides what we *invent*. The Q1 precedent (T-337, ruled `(a)`) does not reach
  > it, and the brief **offers no recommendation on this ruling** — deliberately, for the reason
  > stated below. **T-358 follows from whatever is decided here**; ruling one without the other
  > is how the two acquire inconsistent policies.
  >
  > ### 2026-08-09 — AEF's comparable, and it bears on the *announce* half only (rail 487, T-403)
  >
  > AEF report they **do not invent lanes or participants the input never had**; they derive
  > `owner` from the node's lane and fabricate only scheduling/lifecycle fields. So they have no
  > orphan-lane policy to compare against — they never reach the situation, because they do not
  > manufacture the container. That means **their answer does not transfer to this ruling**, and
  > the brief still offers **no recommendation here**. Unchanged, deliberately.
  >
  > What *does* transfer is the announce question. Where their derivation is weakest they are
  > **loud**: a `serviceTask` in a human lane resolves lane-wins *with a WARN*, and an
  > `authority`-lane node falls back to `agent` under our own ratified wording (rail 95). Our
  > reassignment is silent. Whichever lane policy wins, that contrast is evidence for
  > announcing — and it is available without settling the policy itself.

  This is a sovereignty call, not a technical one: it decides which authority silently acquires a
  step when a `flowNodeRef` fails to resolve. **It was filed as an Agent AC, which was a
  mis-classification** — P-010 would have gated on an agent ticking a box only you may tick, and
  the only ways out of that are `--force` or a wrong decision made quietly. Moved here (the safe
  direction; the T-1811/T-1878 conversion rule restricts Human→Agent, not Agent→Human).

  **Steps:**
  1. `cd /opt/832-Workflow-designer && node tools/_t341-orphan-lane-probe.mjs`
  2. Read `## CORRECTION` above, then choose **one** default and whether it is announced:
     - **(1) Keep positional (`lanes[0]`).** Zero change. Accepts that laneSet order decides
       authority for orphans, and that `validate-workflow.py:1335`'s "zero-semantic repair"
       advice is unconditioned.
     - **(2) Fixed lane by authority.** Orphans always land in a named lane regardless of
       order — e.g. the lowest-authority lane present, so an unresolvable reference can never
       *promote* a step. Deterministic and auditable; needs a rule for maps with no such lane
       (`context-memory` lanes by memory type, so all three are `authority="none"`).
     - **(3) Refuse to place.** Import fails, or the node is held unlaned and the document is
       reported invalid — no silent repair at all.
  3. Independently: should the reassignment be **announced**? `E-XML-LANEREF-DANGLING` exists as
     an ERROR rule but T-309 IW-3 measured it as repaired *inside* `parseBpmnXml`, so no surface
     can ever show it. Announcing is orthogonal to (1)/(2)/(3) and can be adopted with any of them.

  **Expected:** one option recorded in `## Decisions` with rationale, plus a yes/no on announcing.

  **If not:** the task stays blocked. Do not let an agent pick — the three options differ in *who
  ends up accountable for a step*, which is the one thing the Authority Model reserves to you.

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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
# T-341: the probe is a DECISION-SUPPORT instrument, not a standing guard, and is
# run here rather than wired into the gating runner on purpose. Gating it would pin
# the CURRENT (positional) behaviour as expected — i.e. pin the defect. The
# behaviour itself is already gated: EXPECTED_REFS in _t338-input-fidelity-cdp.mjs
# holds `flowNodeRef-dangling: LANE-REHOMED+UID-KEPT`, which fails in either
# direction if the re-homing changes. This block keeps the probe from becoming a
# tool nobody runs.
node tools/_t341-orphan-lane-probe.mjs
node tools/_t338-input-fidelity-cdp.mjs

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

### 2026-08-02T10:39:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-341-an-unresolvable-flownoderef-silently-rea.md
- **Context:** Initial task creation

### 2026-08-03T11:50:39Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
