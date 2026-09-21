---
id: T-742
name: "Value review: the Workflow Designer product itself — src/, the editor, chain
  stage 1"
description: >
  Phase 0-5 value review under the operator's pasted PROMPT, scope option 3: the product
  itself, not the AEF seam (T-740 covered that and is parked unruled). Subject: src/aef-workflow-designer.html
  (single file, 997254 bytes, 254 function decls), tests/ (49 files), scripts/, and
  the release path. Yardstick carried forward from T-740's confirmed yardstick. External
  data: none (T-559 blocks 999-AEF). GATHERER/JUDGE/HUMAN role separation per the
  prompt; gatherers dispatched as TermLink workers. Research is not authorization
  - Phase 6 executes nothing without item-by-item operator approval.

status: work-completed
workflow_type: specification
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-20T21:47:33Z
last_update: '2026-09-21T20:24:53Z'
date_finished: 2026-09-20T22:52:21Z
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
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 4
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md,docs/reports/VALUE-REVIEW-designer-product-2026-09-20/00-yardstick.md);
      tier=4 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-742: Value review: the Workflow Designer product itself — src/, the editor, chain stage 1

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Phase 0–1: the purpose yardstick, the shape of the subject and the data availability
      map are written and were confirmed by the operator before any gathering began —
      `docs/reports/VALUE-REVIEW-designer-product-2026-09-20/00-yardstick.md`.
- [x] Phases 2–3: evidence collected by GATHERERs that were separate sessions from the
      JUDGE, read-only apart from their own evidence file, five legs on disjoint paths.
- [x] **DG-8 closed.** The test suite's pass state, recorded UNKNOWN by T-740 and carried
      open, is now measured — including the discrepancy between `tests/` run alone
      (48 pass) and the gating aggregator (131 passed / 7 failed, exit 1).
- [x] Phase 4–5: one report at exactly `docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md`
      carrying all twelve required sections, each appearing exactly once.
- [x] **Role separation held mechanically, not by promise.** The JUDGE's tool grant was
      `Read,Grep,Glob,Write,Edit` with no Bash; its instructions closed its inputs to the
      six evidence files. It could not open `src/`, could not run a command, could not
      gather. A classification it could not support from the evidence had to be recorded
      as insufficient rather than researched away.
- [x] **The DELETE axis is capped by the missing instrument, and the report says so.**
      With no product usage telemetry, an unobserved item reads D (UNMEASURED) and routes
      to INVESTIGATE. One of 22 findings reached DELETE, on positive evidence (an inert
      body plus a recorded reason the caller is gone), and fifteen went to INVESTIGATE
      with a named instrument. "No data" was not permitted to render as "no value".
- [x] Nothing was executed, weakened or re-scored. No test, gate, audit check or
      verification leg was altered to improve any number in this review.

### Human
<!-- NEVER ticked by the agent. Phase 5 and Phase 6 are the operator's by construction. -->

- [ ] **[REVIEW] Phase 5 — rule the 22 findings item by item.**
      **Steps:** 1. `cd /opt/832-Workflow-designer && sed -n '/^## 6\./,/^## 7\./p' docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md | less`
      2. For each finding F-01…F-22 record approve / reject / defer.
      3. Approved items become their own tasks — one deliverable each, per the sizing rules.
      **Expected:** every finding carries a disposition; no finding is executed without one.
      **If not:** the report stays unruled and nothing is built from it. That is a valid
      resting state, not a failure — but it is the second such report in the queue.

- [ ] **[REVIEW] The 12 Sovereign questions in §12.**
      **Steps:** `cd /opt/832-Workflow-designer && sed -n '/^## 12\./,$p' docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md`
      **Expected:** Q1–Q12 answered, or explicitly parked with a reason. Q1 (the 0.8.0 pin
      against 0.12.0 src) and Q6 (whether `rendered/` is regenerated or the editor-saved
      bytes are ratified) gate other work; the rest do not.
      **If not:** F-06's conformance check cannot be specified (needs Q3), the
      `aef:endpoint` contradiction stays live (Q2), and `laneProvenance` keeps recording
      without deciding (Q12).

## Verification

# Each leg is a single command whose OWN exit code is the verdict — no chaining, so the
# T-352 errexit exposure cannot produce a false green here. Each leg is written to go RED
# if the thing it names degrades, which is the PL-178 bar: a leg that would stay green
# with the deliverable deleted is asserting nothing.

# L1 — the report exists at the exact required path and carries all twelve sections,
# each EXACTLY once. Goes red on a missing section and on the duplicate "_pending_"
# stub that the incremental-write skeleton actually left behind once.
python3 -c "import re,sys,collections; t=open('docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md').read(); n=[int(m) for m in re.findall(r'^## (\d+)\.', t, re.M)]; c=collections.Counter(n); sys.exit(0 if sorted(c)==list(range(1,13)) and set(c.values())=={1} else 1)"

# L2 — all six inputs the JUDGE was restricted to still exist, each above a floor that a
# truncated or skeleton-only file cannot clear. The 02 floor is deliberately high: that
# leg was lost once to a SIGTERM and came back as a 1KB skeleton.
python3 -c "import os,sys; d='docs/reports/VALUE-REVIEW-designer-product-2026-09-20/'; f={'00-yardstick.md':4000,'01-feature-inventory.md':30000,'02-test-baseline.md':30000,'03-release-path.md':15000,'04-ledger-history.md':15000,'05-schema-fidelity.md':20000}; sys.exit(0 if all(os.path.exists(d+k) and os.path.getsize(d+k)>=v for k,v in f.items()) else 1)"

# L3 — no residual skeleton markers anywhere in the review. The workers were told to
# write incrementally precisely so a kill would leave partial evidence; this leg is what
# stops a partially-filled section from being mistaken for a finished one.
python3 -c "import glob,os,sys; ps=[p for p in glob.glob('docs/reports/VALUE-REVIEW-designer-product-2026-09-20*')+glob.glob('docs/reports/VALUE-REVIEW-designer-product-2026-09-20/*') if os.path.isfile(p)]; sys.exit(1 if [p for p in ps if '_pending_' in open(p).read() or 'IN PROGRESS' in open(p).read()] else 0)"

# L4 — the evidence is durable, not merely on disk. All six inputs plus the report are
# tracked by git. Evidence that lives only in a worker's scratch directory is evidence
# that a cleanup deletes.
python3 -c "import subprocess,sys; o=subprocess.run(['git','ls-files','docs/reports/VALUE-REVIEW-designer-product-2026-09-20','docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md'],capture_output=True,text=True).stdout.split(); sys.exit(0 if len(o)==7 else 1)"

# L5 — section 12 is intact: twelve Sovereign questions, Q1 through Q12, none dropped.
# These are the items that are NOT the agent's to answer, so a silently truncated §12
# would be the review quietly shedding the operator's own decisions.
python3 -c "import re,sys; t=open('docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md').read(); s=t[t.index('## 12.'):]; q=set(re.findall(r'\*\*Q(\d+)', s)); sys.exit(0 if q=={str(i) for i in range(1,13)} else 1)"

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

**Recommendation:** GO

**Scope of that word, stated because the vocabulary is narrower than the position I
hold (PL-287).** GO here means **accept the review as delivered evidence** — the
gathering was honest, the role separation held, the report is complete. It does **not**
mean approve its findings. Accepting this review authorises nothing: research is not
authorization, and every one of the 22 findings still needs its own ruling before any of
it becomes work. If the decision surface could carry it, the accurate verdict would be
*"accept the artefact, rule the contents separately."*

**Rationale**

The review answered the question it was given and closed a gap that was open before it.
DG-8 — the test suite's pass state, recorded UNKNOWN by T-740 — is now measured, and the
measurement was not the reassuring one: `tests/` run alone is green, while the gating
aggregator is red at 131/7, and the seven failures live in `tools/`, outside the directory
that looks like the test suite.

The three highest-consequence findings are the same shape seen through three independent
instruments: the released bytes a consumer pins are four releases behind `src/`; the audit
check over that gap prints PASS because it escalates on the age of our own tag rather than
on the distance the peer is behind; and the gating suite that would have caught drift is
red and unscheduled. Each instrument is green or silent over precisely the condition it
was believed to cover. That is worth a ruling on its own, independent of anything else in
the report.

I am recommending GO on the artefact rather than DEFER because the evidence is durable and
committed, and deferring the artefact would not make the twelve Sovereign questions any
more answerable — they are waiting on the operator, not on more gathering.

**Evidence**

- `docs/reports/VALUE-REVIEW-designer-product-2026-09-20.md` — 1,264 lines, 12 sections,
  22 findings (1 DELETE / 4 REFACTOR / 14 ADD / 3 INVESTIGATE-only), 12 Sovereign questions.
- Six evidence files under `docs/reports/VALUE-REVIEW-designer-product-2026-09-20/`,
  written by five GATHERER sessions separate from the JUDGE, all committed
  (`4ebf9168`, `0e6e06de`).
- Five verification legs pass; L3 proven able to fail under a planted stub.
- **The DELETE axis is capped and the report says so.** No product usage telemetry exists,
  so an unobserved item reads D (UNMEASURED) → INVESTIGATE. Exactly one finding reached
  DELETE, on positive evidence; fifteen went to INVESTIGATE with a named instrument.
- **Two places the JUDGE declined the easy call**, which is the main reason I trust the
  rest of it: Q9 — re-pinning the drifted third-party goldens would turn a red leg green,
  and it refused to recommend that as a review outcome, asking instead what caused the
  drift; Q2 — it corrected four `schema.md` defects and deliberately left the fifth, the
  `aef:endpoint` contradiction, because the frozen standard is not agent-editable.

**What this recommendation is not**

Not a recommendation to execute any finding. Not a re-scoring of anything. Not a claim
that the product is healthy or unhealthy — that is §5's reading and it is the operator's
to accept or reject. **T-740's nine Sovereign questions remain open ahead of these twelve**,
and this is now the second unruled review in the queue.

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
     fw inception decide T-742 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-20T21:47:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-742-value-review-the-workflow-designer-produ.md
- **Context:** Initial task creation

### 2026-09-20T21:47:40Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8b1893cb
- **Timestamp:** 2026-09-20T22:52:22Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-20T22:52:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
