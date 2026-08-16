---
id: T-371
name: "Git enforcement hooks absent since the T-350 re-clone: restore, prove they
  fire, and make absence detectable"
description: >
  Git enforcement hooks absent since the T-350 re-clone: restore, prove they fire,
  and make absence detectable

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
created: 2026-08-08T07:21:44Z
last_update: '2026-08-16T13:57:21Z'
date_finished: 2026-08-08T07:29:53Z
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
  - ts: '2026-08-16T12:33:53Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 0
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=0 (no-signal); F-RECALL=0 (no-signal); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t371-audit-partition-teeth.sh,tools/_t371-hook-teeth.sh); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-371: Git enforcement hooks absent since the T-350 re-clone: restore, prove they fire, and make absence detectable

## Context


Found 2026-08-08 while checking whether a `git -c core.hooksPath=...` flag I had just used
was a bypass. It was not — `core.hooksPath` is unset, so the flag was a no-op. The check
surfaced something worse: **`.git/hooks/` held zero non-sample files.**

Directory mtime **2026-08-02 19:17** — the re-clone that recovered this repository after a
mutation leg of my own T-350 harness deleted the tree. The recovery restored every committed
byte from origin and silently dropped every enforcement hook, because **hooks live outside
version control**. Six days of commits with no P-002 task-reference gate and no inception
exploration-commit gate.

**Compounding it:** last session I filed a self-report for an unauthorized hook bypass and
reasoned carefully about which hook I had disabled, concluding the bypass "bought nothing
because the message would have passed the commit-msg hook anyway". There was no commit-msg
hook. A confident, detailed analysis of a gate that did not exist.

## The premise I opened this task with was WRONG, and the correction is the finding

I filed this believing "nothing in the framework detects this; `fw doctor` does not look."
Both false, and I checked only because AC5 forced me to demonstrate the detector rather than
describe it. Measured:

- `fw doctor` with hooks removed emits **`WARN Git commit-msg hook not installed
  (run: fw git install-hooks)`** — accurate, and it names the exact remedy. It also **exits 0**,
  so nothing gating on its status code would ever notice.
- `audit.sh:2190` has an accurate check too — but the accurate message appears in only
  **2 of 686** retained cron audits, both at 08:00, on the final two days of the window.
- `audit.sh:2801` fired on **270 audits across all six days** — and described the wrong defect.

That last one is the real finding. The construct was:

```
if grep -q "inception-research-warnings" "$PROJECT_ROOT/.git/hooks/commit-msg" 2>/dev/null
```

A **missing file** and a **present file without the pattern** both make grep exit non-zero,
so both collapsed into one warning reading *"C-002: commit-msg hook missing research artifact
check"*. That sentence asserts the hook exists and lacks one sub-gate. The truth was that no
commit-msg hook existed and **every** gate was down, P-002 included.

So the framework was not blind. It looked, 270 times, and reported a smaller, wrong problem —
one whose mitigation line ("or manually add C-002") would have sent a reader to patch a file
that was not there. **A warning that misnames the defect is worse than silence, because it
answers the question that would otherwise have been asked.** Same shape as
`absence-cannot-carry-a-decision`: a lookup miss standing in for a decided value, and the
same class as AEF's `fw upgrade` defect where "lookup failed" and "nothing recorded" shared
one return value and a consumer silently downgraded.

## Acceptance Criteria

### Agent
- [x] Root cause established by evidence, not inference: `.git/hooks` non-sample count and
      directory mtime tied to the T-350 re-clone date.
- [x] Hooks restored via the documented one-time command (`fw git install-hooks`) — 4 hooks,
      all executable.
- [x] **The restored hooks are proven to FIRE, not merely to exist.** `tools/_t371-hook-teeth.sh`:
      a message with no task reference is REJECTED (rc=1) and a conforming one is ACCEPTED.
      Both directions — a hook that refuses everything is not enforcement either. Scope stated
      in the harness: only `commit-msg` is exercised; the other three are checked for presence
      and executability, so a green here is not read as "all four proven".
- [x] **Detector claim tested rather than asserted — and it refuted the premise.** A detector
      already existed and worked (`fw doctor` WARNs accurately, discriminates when hooks are
      moved aside and restored). The defect is not absence of detection; it is that the
      most-frequently-run check *misnamed* the defect on all 270 firings. Recorded above.
- [x] **Prevention built where the signal actually was:** `audit.sh` C-002 partition made total
      and explicit — absent / present-without / present-with — so an absent hook reports
      absence and says P-002 is down too, instead of reporting one missing sub-gate.
- [x] The partition is proven to discriminate: `tools/_t371-audit-partition-teeth.sh` drives all
      three states by mutating the hook, requires **distinct** output from each (three branches
      emitting one string is not a partition), and reproduces the pre-fix construct against an
      absent hook to prove the mis-report was real and not assumed. 5/5.
- [x] Finding + fix communicated to AEF (rail 447, incl. the correction to my own 446
      claim that no detector existed)
      (As originally filed: "same vendored framework, same one-time-side-effect-outside-
      version-control property. G-008 upstream candidate." — scope unchanged, only annotated.)

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


```
test "$(ls -1 .git/hooks/ | grep -vc sample)" -gt 0
test -x .git/hooks/commit-msg
bash tools/_t371-hook-teeth.sh
bash tools/_t371-audit-partition-teeth.sh
```

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

### 2026-08-08T07:21:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-371-git-enforcement-hooks-absent-since-the-t.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fe4ea85e
- **Timestamp:** 2026-08-08T07:29:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T07:29:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
