---
id: T-318
name: "T-314 repair is unreachable to AEF: repaired fixtures exist only in untagged
  work, and the file-transfer channel is starving"
description: >
  AEF cannot re-pin the T-314 fixture repair. Two independent reasons, rail 352. (1)
  The termlink file-transfer channel re-serves the SAME earliest historical transfer
  on every replay call (escalation-patterns.yaml, 4957 B) while printing 'SHA-256
  verified' and exiting 0 - it looks exactly like success and hands back a months-old
  file, so both BPMN sends are permanently unreachable through replay. Filed AEF-side
  as OBS-108; affects anything either side sends after the first transfer. (2) Our
  published tag designer-v0.8.0 still carries the PRE-repair bytes (093858.../efb53839...),
  byte-identical to what AEF holds, so the T-314 repair exists only in untagged work
  our side. AEF explicitly does not want a re-send over the mechanism whose integrity
  is in question - they want a durable pullable ref they can verify without our involvement.
  Deliverable is to make the repaired fixtures reachable at a named ref and tell AEF
  which one, without minting a designer release tag for two fixtures (that would trip
  the release process and G-007 for unrelated content).

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T11:37:35Z
last_update: '2026-08-16T14:33:27Z'
date_finished: 2026-07-31T11:40:03Z
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
  - ts: '2026-08-16T12:33:49Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=0 (no-signal); F-RECALL=1 (body:episodic-only); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:27Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 1
      F2: 0
      F4: 3
      F3: 5
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=0 (no-signal); F-RECALL=1 (body:episodic-only); F2=0 (no-signal); F4=3 
      (prose:routing-defect-class); F3=5 (prose:seam-contract); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/fixtures/aef-bpmn/inception-gonogo.bpmn,tests/fixtures/aef-bpmn/two-lane-joint.bpmn);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-318: T-314 repair is unreachable to AEF: repaired fixtures exist only in untagged work, and the file-transfer channel is starving

## Context

Follow-on from T-314 (completed): the fixture repair landed our side and was reported on the
rail, but AEF cannot obtain the bytes. Their re-pin is BLOCKED, correctly — they hold
`CANONICAL_SHA256` as a tamper-detector on their own copy, so moving that constant to a sha
whose bytes they do not have would convert a passing check into a false red. Being behind is
a better state than being falsely red.

Note what did NOT go wrong: we are not out of sync. AEF's bytes are byte-identical to our
published tag. The repair is simply unpublished.

## Acceptance Criteria

### Agent
- [x] The exact reachability failure is established by evidence rather than assumed: confirm
      whether `designer-v0.8.0` carries pre-repair bytes and whether the repair is present on
      a pushed branch ref.
- [x] The repaired fixtures are reachable at a durable, pullable ref, and the ref is named to
      AEF with the commit sha and both expected digests so they can verify without our
      involvement.
- [x] No designer release tag is minted for this. Cutting a release to ship two fixtures would
      drag unrelated in-flight work into a versioned artifact and engage G-007's immutability
      guard for content that has nothing to do with a release.
- [x] The size-parity correction is accepted in writing on the rail, not quietly dropped:
      4314/5491 are the sizes of BOTH the repaired and unrepaired bytes, so size parity is
      consistent with the claim without being evidence for it.
- [x] AEF's replay-starvation finding is recorded our side as affecting the shared channel,
      since it silently degrades anything either side sends after the first transfer.

## Verification

# The repaired bytes must be reachable at the ref we advertise, with the digests we claim.
git cat-file -e origin/master:tests/fixtures/aef-bpmn/inception-gonogo.bpmn
test "$(git show origin/master:tests/fixtures/aef-bpmn/inception-gonogo.bpmn | sha256sum | cut -d' ' -f1)" = "bbfbc5ec48356c3a643efa21e37912994a3fff56532b7e0ef4815f91fbed00ab"
test "$(git show origin/master:tests/fixtures/aef-bpmn/two-lane-joint.bpmn | sha256sum | cut -d' ' -f1)" = "2ba55eedbd90ae7805fa9ad3c8a7037913b4788dfc8c7db2ae9f3953d6d7bf7f"


## Evidence

**AEF was never blocked; the ref they read was stale.** `designer-v0.8.0` — the latest tag —
carries `093858400716…` / `efb53839bfdd…`, exactly as they measured. But the repair landed in
`e133cf9` (T-314) which is an ancestor of `master`, and `master` was pushed at the T-314
handover. Digests re-derived from the git OBJECTS, not the working tree, and identical from
all three sources:

| ref | inception-gonogo | two-lane-joint |
|---|---|---|
| origin/master (0b5d84f) | bbfbc5ec…ed00ab | 2ba55eed…bf7f |
| github/master (0b5d84f) | bbfbc5ec…ed00ab | 2ba55eed…bf7f |
| e133cf9 | bbfbc5ec…ed00ab | 2ba55eed…bf7f |

So the deliverable turned out to be a correction, not a publication: no artifact needed. What
was actually wrong was my own report at rail 350, which pointed a peer at a file transfer when
an immutable commit sha already carried the bytes on two remotes.

**No release tag minted.** `designer-vX.Y.Z` is cut by `release-designer.sh` behind the G-007
immutability guard; using one to ship two fixtures would pull unrelated in-flight work into a
versioned artifact. A commit sha is already immutable and already pullable. Offered a plainly
non-release tag if AEF wants a human-readable name, rather than adding one unasked.

**Size-parity correction accepted on the rail.** The pre-repair bytes are also 4314 / 5491, so
size parity is satisfied identically by repaired and unrepaired bytes — consistent with the
claim, evidence for nothing. It sat one line from the membership/position/uid/flow/height diff
that does discriminate, which is where a non-discriminating check does its damage: it borrows
the credibility of the real proof beside it.

**Replay starvation recorded.** `file receive --replay` re-serves the earliest historical
transfer on every call while printing "SHA-256 verified" and exiting 0. The digest check is
honest; it is verifying the wrong file. Same class as the shellcheck collision and
`grep "0 failed"` matching `10 failed`. Consequence adopted: file_send is not a delivery
mechanism for seam bytes between the two projects until AEF's OBS-108 closes — refs only.


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

### 2026-07-31T11:37:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-318-t-314-repair-is-unreachable-to-aef-repai.md
- **Context:** Initial task creation

### 2026-07-31T11:37:57Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e2690385
- **Timestamp:** 2026-07-31T11:40:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-31T11:40:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
