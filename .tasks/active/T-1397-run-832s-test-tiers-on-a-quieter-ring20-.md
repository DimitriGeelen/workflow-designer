---
id: T-1397
name: "Run 832's test tiers on a quieter ring20 worker (host .107 runs at load 40-90)"
description: >
  Operator's suggestion 2026-11-12: use other workers via ring20-manager instead of
  waiting hours for load < 15 on .107. Asked proxmox-ring20-management (conversation
  832-test-capacity) for a host with a TermLink worker: git clone, Node 22, Python
  3, Playwright Chromium, ~4 GB RAM. Open: which host, how 832 dispatches, whether
  a remote green can stand in for the pre-push gate's local cache (it cannot today:
  the cache keys on the local tree).

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-11-12T09:20:37Z
last_update: '2026-11-13T00:39:58Z'
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): the two values below are PLACEHOLDERS, not an assessment. The BVP
# estimator ignores any value without `<field>_source: human` and estimates it from this task's own text, so a
# 0.5 nobody chose no longer ranks as "judged middling". They stay filled because AEF's T-2188 schema hook
# refuses an edit to an inception without them (T-1178; T-865 had deleted them before that hook arrived here).
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-11-13T00:39:58Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (voi:open-question~'assumption'); D2=2 
      (voi:open-question~'assumption'); D3=2 (voi:open-question~'assumption'); 
      D4=2 (voi:open-question~'assumption'); F-RECALL=2 
      (voi:open-question~'assumption'); F2=2 (voi:open-question~'assumption'); 
      F4=2 (voi:open-question~'assumption'); F3=2 
      (voi:open-question~'assumption'); F1=2 (voi:open-question~'assumption')
    rubric_sha: e4a00f38e801
---

# T-1397: Run 832's test tiers on a quieter ring20 worker (host .107 runs at load 40-90)

## Problem Statement

832's test tiers (core ~17 min, browser ~17 min when quiet, headless Chromium via CDP) run on .107, which sits at load
40-90 from other projects. Runs wait hours for load < 15; at load ~45 Chrome was killed mid-run and a harness hung 2 h
(T-358's close, 2026-11-11; T-1395 made that a fast red, not a hang). The operator suggested (2026-11-12) using other
workers through ring20-manager.

**ring20-manager's answer (conversation 832-test-capacity, 2026-11-12):** likely yes, through its dispatch pool, which
010-termlink and AEF already use. Four nodes; three are quiet LAN VMs (pool-w1, pool-w2: 8 vCPU, 6-8 GB; pool-132).
Each job is sandboxed: no network (loopback if the entry asks; CDP needs it), code read-only, its own tmpfs, up to 1 h,
results back on a topic. Two cmd entries (832.bridge-core, 832.bridge-browser) in a hash-locked environment they build
once. 832 submits a repo snapshot at the commit (tar via `deploy/remote-node/pool/pool-client.py ref-put` to the .122
hub) and gets back exit code, the result line and the FAIL lines. Their operator decides on adding the client and entries.

**What 832 told them:** no lockfiles (raw CDP, no npm). Python: flask 3.1.2, jinja2 3.1.6, markupsafe 3.0.3, lxml 5.2.1,
PyYAML 6.0.3, pytest 9.0.2, playwright 1.55.0. Node 22.22.1, Python 3.12.3, git 2.43.0. Network loopback only. The
snapshot needs .git (legs read history, tags, a self-clone; ~1 GB packed). Peak RAM not yet measured; to be measured
and sent. Hard rule: the snapshot is built from git at the commit, never the working tree, because the git-ignored
build/peer-data/greenfield/ holds a client's documents that must not leave .107.

**Open for 832 (and likely the operator):** the pre-push gate (T-1288) accepts only a green run of THIS tree here. A remote
green cannot unlock a push unless the gate is taught to trust a pool result for the same commit. That is a design and
trust question, not a configuration one.

## Hypothesis

<!-- REQUIRED before a GO decision (T-866, arc-004). Fill the three blanks below and
     delete this comment. Keep the three phrases — the gate looks for them.

     NOT EVERY INCEPTION HAS ONE, and that is fine. "Research how X works" produces
     understanding, not a delivered outcome, and forcing it into "we will achieve
     <outcome>" would manufacture a fake claim to satisfy a gate — which teaches
     authors to write fiction and is worse than no gate at all.

     If this is that kind of inception, set in the frontmatter:

         inception_kind: research

     and delete this section. The gate then passes. Declare it NOW, while framing the
     work — not later at the decision, when you know whether the hypothesis would have
     been inconvenient. The count of research inceptions is reported, so if the
     exemption quietly becomes the default that is visible rather than silent.

     This is the form the BVP scoring method expects. Every support score in this
     task's value-driver table is an ARGUMENT ABOUT THIS SENTENCE: "support 5 on
     Reliability" means something only once the sentence says what success looks
     like. Without it a score can rank but cannot be wrong, because there is no
     claim for it to be wrong about.

     THE THIRD CLAUSE IS THE ONE THAT BITES. It has to be checkable by someone who
     was not in the room and who reads this in three months. A number, a count, a
     threshold, a named state.

       no  — "...when the system is better"
       no  — "...when the team is more productive"
       yes — "...when 5 consecutive fire-suppression tests pass at every equipped site"
       yes — "...when fw audit reports 0 failures for 3 consecutive nightly runs"
       yes — "...when the importer no longer fabricates a lane for input that has none"

     Writing it is genuinely hard. You are not expected to start from blank: the
     estimator drafts one from this task's own text, and you correct it. Your
     correction is sticky — set `hypothesis_source: human` in the frontmatter and no
     automatic pass will ever overwrite it. -->

We believe that running 832's two test tiers on ring20's sandboxed dispatch pool (quiet amd64 VMs) instead of only on .107,
we will achieve pushes and closes that no longer wait hours for .107's load to drop below 15,
We will know that we are successful when we see three pool runs of the same commits as local runs give the same tier results (pass counts and FAIL legs, pool-only namespace exceptions aside), each finishing within the pool's 3600 s limit.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1397 -->

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->

- **IW-1: Is there a quieter host 832 may use for its tiers?**
  confidence: 3
  disposition: answered
  rationale: ring20-manager, 2026-11-12/13 (conversations 832-test-capacity, consult-…/832-Workflow-designer): yes, its
  sandboxed dispatch pool; ring20's operator gave the GO; entries being built (their T-2651, commit 074e1a518).
- **IW-2: May a pool result count for a push?**
  confidence: 3
  disposition: answered
  rationale: operator's ruling 2026-11-12 (Decisions below): trust the pool; two independent runs on two different
  machines for high-risk changes; releases keep their local run.
- **IW-3: Do pool runs agree with local runs?**
  confidence: 1
  disposition: deferred
  rationale: measurable only once the entries are live; it is the success signal in the Hypothesis and the first job
  of the build (three same-commit comparisons).

## Exploration Plan

Done by dialogue with ring20-manager (no spike needed): capacity, contract, sandbox limits, directories. The comparison
runs (IW-3) are the build's first deliverable, before the push gate trusts a pool result.

## Technical Constraints

- Sandbox: unprivileged uid, no capabilities, own pid+mount+net namespace, loopback only, no user namespaces
  (RestrictNamespaces), tmpfs write area, up to 3600 s, 1 GiB core / 3 GiB browser, amd64 only (pool-w1, pool-w2).
- Code from git only: `git archive` + a git bundle split into <= 64 MB parts; never the working tree (build/peer-data
  holds a client's documents). Staging only from build/pool/stage/, results to build/pool/results/ (both git-ignored).
- Env: Python 3.12 venv with 832's pins, Node 22.22.1, git 2.43; Chromium 1187 under PLAYWRIGHT_BROWSERS_PATH.

## Scope Fence

IN: the launcher tools/pool/run-tier.sh; harnesses honouring PLAYWRIGHT_BROWSERS_PATH; pool-only exceptions for the
mount-namespace tests; staging the bundle; three comparison runs; then teaching the push gate to accept a matching pool
green, with the two-run rule for high-risk changes.
OUT: releases moving off .107 (they keep their local browser run); arm64.

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Why you:** direction — whether a test result from another machine may unlock a push changes what the T-1288 gate
  trusts, which is the operator's rule; and `fw inception decide` is operator-only
  **Steps:**
  1. Run: `fw task review T-1397` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- A host with capacity exists and its owner agrees (yes: ring20's operator, 2026-11-12)
- The operator agrees a pool result may count (yes, with the two-run rule for high-risk, 2026-11-12)
- The contract keeps 832's constraints: code from git only, no client data leaves .107 (yes)

**NO-GO if:**
- The sandbox cannot run the tiers at all (it can: loopback, Chromium 1187, Node 22; only the few mount-namespace
  tests become pool-only exceptions)
- Pool runs disagree with local runs and the cause cannot be found (tested by the build's comparison runs)

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** GO

**Rationale:** Every GO criterion holds. ring20's operator gave the GO for 832 on its pool and the contract is agreed
(amd64 only, git-only code, narrow staging root, full log returned). The operator ruled on 2026-11-12 that a pool
result counts, with two independent runs on different machines for high-risk changes. Evidence for the need: .107 at
load 40-90 from other projects; on 2026-11-12 test runs waited hours for load < 15, and T-358's close hung 2 h at load
~45 (now a fast red, T-1395). The remaining risk, disagreement between pool and local runs, is the build's first
measurement (IW-3), before the push gate trusts the pool.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-11-12 — operator: does a pool result count for a push?
- **Chose (operator, in conversation):** trust the pool. "A node is given, made available, not without reason." Isolation
  is there, and runs can be told apart. Releases keep their local run. For high-impact, high-risk changes: TWO
  independent runs on two different machines.
- **Agent's proposals, for the operator to adjust (not yet ruled):**
  1. High-risk = a fixed list, not a judgement call: releases; framework upgrades; changes to the test gate itself
     (tests/run-bridge-tests.sh, tools/_t1288-*, the census/ratchet tools); changes to the designer's save/load path
     (parseBpmnXml, buildBpmnXml and what they call).
  2. The second machine should differ in setup, not be a second pool node (two nodes share one environment and miss the
     same drift). Releases: pool + .107 (the release job's local browser run already is that). Others: two pool nodes are
     acceptable when .107 is too loaded.
  3. Two runs that disagree is a stop: nothing ships until the difference is explained.
- **Rejected:** local-only (keeps the hours of waiting the pool exists to remove).
- **Before building it:** compare a few pool runs with local runs of the same commit, so the trust starts from measured
  agreement.

## Decision

<!-- Filled at completion via: fw inception decide T-1397 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-13T00:39:55Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
