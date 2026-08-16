---
id: T-370
name: "Deliver the frozen BPMN mapping standard to AEF as a pinnable ref + sha (they
  hold no copy of it)"
description: >
  Deliver the frozen BPMN mapping standard to AEF as a pinnable ref + sha (they hold
  no copy of it)

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
created: 2026-08-08T07:13:32Z
last_update: '2026-08-16T14:33:31Z'
date_finished: 2026-08-08T07:21:27Z
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
  - ts: '2026-08-16T14:33:31Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 4
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 
      (no-signal); F4=1 (prose:routing/geometry-incidental); F3=4 
      (prose:seam-fixture-or-pin); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/standards/aef-bpmn-mapping-v1.md,tools/_t370-standard-ref-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-370: Deliver the frozen BPMN mapping standard to AEF as a pinnable ref + sha (they hold no copy of it)

## Context

At RAIL-445 AEF disclosed that **they hold no copy of `docs/standards/aef-bpmn-mapping-v1.md`.**
Their own measurement: one grep hit across their repo, and it is their report quoting *our
rail messages*. Every clause they have cited on this arc — §1's two-class partition, §6.3's
subject, lines 42-45's "derived, never authoritative" — they have been quoting out of my
paraphrases. They have been reasoning about a frozen document by hearsay, confidently.

They will not produce the §6.3 reading (owed since RAIL-442) or rule on the §1 enumeration
hole until they hold the bytes, and they are right not to: *"a ratifying party that does not
hold the document is not a fence, it is a rubber stamp."* This is now the blocking item on
**our** side, ahead of everything else on the arc.

Constraints: `file_send` is not a delivery mechanism until their OBS-108 closes (refs only),
and the standard itself must not be edited under agent control — this task **serves** it
read-only, it does not touch it.

## Acceptance Criteria

### Agent
- [x] The subject is a **specific pushed commit**, not the working tree and not a branch name.
      A branch ref would move under them — the same moving-global shape as G-015, and pinning
      a document to `master` reproduces it exactly. Record commit sha + path.
- [x] Whole-file sha256 and byte count recorded, derived from `git show <commit>:<path>`
      (the committed bytes), not from the working-tree file.
- [x] The **Part I / Part II boundary** is stated as a byte range with its own sha256, so the
      frozen half can be pinned independently of the provisional half they are being asked to rule on.
- [x] A ref AEF can fetch **resolves and returns byte-identical content** — fetched sha256
      equals the committed sha256. Same protocol they used for their own fixture at RAIL-445.
- [x] **Negative controls, both directions:** (a) a wrong revision and a wrong path each return
      non-200 — proving the ref is revision-pinned and does not silently fall back to HEAD or to
      a rendered page; (b) a 200 with a non-matching sha is reported as FAIL, not as success.
      Motivation is measured, not hypothetical: Watchtower's `/file/...` route returned
      **HTTP 404 with a 67,274-byte HTML body**, so fetch-and-hash without a status check
      would have "delivered" a dashboard page.
- [x] Reachability is established by **rule, not by a local probe** — T-253's RCA is that
      agent-side probes originate on-host and bypass inbound filtering, so a local fetch is
      never evidence the peer can reach anything.
      **AC rewritten mid-task, and the rewrite is the point.** As first written it said "the
      serving port carries a ufw ALLOW entry, recorded verbatim" — that belonged to an
      HTTP-delivery design I abandoned once the T-247 pull-at-tag channel turned out to
      already exist. There is no serving port, so ticking the original text would have
      asserted a check that was never run and could not be run. What actually establishes
      reachability: the ref lives in the **same repo and transport AEF has itself exercised
      for every dist re-pin since 0.4.0** — evidence about the peer's real access, which is
      strictly better than a firewall rule on our side.
      **Residual uncertainty, stated rather than papered over:** whether their intake tooling
      exposes arbitrary repo paths or only the `dist/` artifact is a property of *their*
      tooling, which I must not run (T-559). Handled by offering the 7,905-byte inline
      fallback in the same message rather than by assuming.
- [x] The rail message to AEF carries: pinned ref, whole-file sha256 + bytes, Part I range +
      sha256, and an explicit statement of which half is frozen and which is provisional.

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
bash tools/_t370-standard-ref-probe.sh
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


**D1 — Reuse the T-247 pull-at-tag channel; do not stand up an HTTP server.**
Considered: (a) a route on Watchtower `:3000`, (b) a static server on a free ufw-allowed
port, (c) OneDev raw, (d) the existing git origin. Rejected (a): Watchtower's `/file/<path>`
is 404 for `docs/` and renders markdown to **HTML**, so it cannot return the bytes anyone
would pin. Rejected (b): this arc has already paid for six orphaned servers (T-351), and a
document does not need a daemon. Rejected (c): OneDev `~raw` returns **401**, and the other
URL forms return a 751-byte JS bootstrap shell rather than the file — pinning that would
have pinned a loading page. Chose (d): AEF already fetches from this exact origin for every
dist re-pin since 0.4.0, so the channel is proven by their own use, not by our assumption.

**D2 — Pin a commit, never a branch.**
`origin/master:<path>` is the natural thing to quote and it is wrong: the ref moves under
the consumer. That is the G-015 moving-global shape applied to a document whose whole value
is being frozen. Published `4a1a30e1…` (the last commit that touched the file) and included
git's **blob id** `6b256a34…`, which is content-addressed and therefore identifies the bytes
independently of any commit we name or of our own hashing being correct.

**D3 — Hard-coded expected shas in the probe are a guard, not the G-015 defect.**
Normally a literal expectation in a gate is the moving-global-in-a-gate smell. Inverted here:
Part I is frozen and must not be edited under agent control, so a literal sha goes **red on
any edit**, which is the desired direction. Re-deriving the expectation from the subject —
the reflex — would pass silently over exactly the event the pin exists to catch.

**D4 — The probe went RED on a correct document on its first run, in the expensive direction.**
`part1 | head -1 | grep -q '^# Part I'` reported the range did not start at the Part I
heading. It does. `head` exits early, upstream `git cat-file` takes SIGPIPE (141), and
`pipefail` promotes that 141 over grep's successful match. A red that sends you to debug
working bytes costs more than a green that hides a defect, because it spends attention on a
non-existent problem and erodes trust in the instrument. Fixed by materialising the range
once and asserting against the file. Same pipefail class already measured on this arc under
P-011 — third appearance, and this one arrived through `head`, not through a capture.

**D5 — Deliver both halves separately.**
Part I (frozen, bytes `[1906, 9811)`, 7,905 B, sha `970dd530…`) is pinnable on its own, so
their `policy/` vendor pin does not churn when Part II changes. Part II is the provisional
half they are being asked to rule on; conflating them would make their pin move every time
their own ruling landed.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T07:13:32Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-370-deliver-the-frozen-bpmn-mapping-standard.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-26fe4791
- **Timestamp:** 2026-08-08T07:21:28Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T07:21:27Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
