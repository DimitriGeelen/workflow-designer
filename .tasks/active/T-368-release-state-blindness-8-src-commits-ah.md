---
id: T-368
name: "Release-state blindness: 8 src commits ahead of the 0.8.0 pin, AEF re-reporting
  a defect fixed 9 days ago"
description: >
  Release-state blindness: 8 src commits ahead of the 0.8.0 pin, AEF re-reporting
  a defect fixed 9 days ago

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T06:47:02Z
last_update: '2026-08-16T12:33:28Z'
date_finished: 2026-08-08T06:52:17Z
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
  - ts: '2026-08-16T12:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 4
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=4 
      (body:framework-level-ux); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-368: Release-state blindness: 8 src commits ahead of the 0.8.0 pin, AEF re-reporting a defect fixed 9 days ago

## Context

**Discovered 2026-08-08 while answering AEF's RAIL-443.** Their operator asked "is
there a release after 0.8.0?" and the answer exposed something bigger than the question.

AEF is pinned to and serving **0.8.0** (sha `cab3c751…0935`, 903600 B — pin matches
served bytes exactly, they verified). That cut was made **2026-07-29**. Since then
**8 commits have touched `src/aef-workflow-designer.html`**: T-308, T-310, T-311,
T-315, T-337, T-358, T-361, T-364. `src` is now 934239 B against the pinned 903600.

**The harm is concrete and already paid.** At RAIL-443 AEF reported the leading-XML-doc-
comment destruction (their T-2682 / G-071) at **four instances across three maps and two
months**, two of them dated 2026-08-08. They repaired their only detail-authority map
(`aef-task-lifecycle` v3) and re-raised a standard proposal from RAIL-332 to work around
it.

That defect was diagnosed and fixed here as **T-311 on 2026-07-30 — one day after the
0.8.0 cut**. Measured, not recalled:

```
grep -c docComment  src/aef-workflow-designer.html   -> 5
grep -c docComment  dist/…-0.8.0.html                -> 0
grep -c docComment  dist/…-0.7.1.html                -> 0
```

So a consumer spent two months hitting a defect, and nine days of that was *after* we
had fixed it, because the fix was never cut. Neither side's instruments said so. Mine
had no reason to — every gate here runs against `src`.

**This is not "we forgot to cut a release".** The release cut is operator-gated and
staying that way; an agent cutting releases is not the fix. The defect is that
**nothing on either side compares what a consumer runs against what we have fixed**, so
the gap is invisible until a human asks a direct question. It survived nine days and
would have survived longer — I only found it because their operator asked about
versions, and my RAIL-440 gave them three commit hashes and no version at all.

Sits next to G-007 (release immutability) and G-015 (assertions about a moving global):
same family, opposite direction — those guard the artifact once cut, this is about the
window before it is cut.

## Acceptance Criteria

### Agent
- [x] **The `src`-vs-pin gap is stated per commit with its consumer visibility.** Not a
      count. For each of the 8 commits: task ID, one line, and whether it changes
      anything a consumer can observe (emitted bytes / seam contract / UI only). A
      count invites "cut a release"; the per-commit split is what tells the operator
      whether this is urgent or housekeeping, and which of the 8 AEF is actually
      waiting on.

      | commit | date | task | what | consumer-visible? |
      |---|---|---|---|---|
      | `b11d3945` | 07-29 | T-308 | bare catch event renders neutrally when unbound | render only |
      | `cc72cc9e` | 07-29 | T-310 | declared lane membership beats conflicting geometry | **YES — emitted lane assignment** |
      | `8c54906b` | 07-30 | T-311 | authored doc block survives the round-trip | **YES — AEF IS WAITING ON THIS** |
      | `6d75b281` | 07-31 | T-315 | grow an under-declared lane band instead of moving nodes | **YES — emitted geometry** |
      | `bd536f05` | 08-03 | T-337 | import no longer deletes flow nodes with out-of-allowlist tags | **YES — prevents node loss** |
      | `07a62951` | 08-03 | T-361 | exported bytes named AEF as owner of a step they never performed | **YES — and it is about AEF** |
      | `3bf37909` | 08-04 | T-358 | lane-origin partition made total (`laneProvenance`) | no — recorded, not emitted (`_t308` 24/24 identical) |
      | `652364f1` | 08-04 | T-364 | `aef:uid` derives from the BPMN element id | no-op **for AEF's corpus** (see below) |

      **5 of 8 are consumer-visible in emitted bytes.** This is not housekeeping.

      Two of the eight are *not* reasons for AEF to re-pin, and saying so matters as
      much as the five: **T-358** deliberately emits nothing (the task's own byte-identity
      evidence is 24/24 identical), and **T-364**'s derivation path executes only where
      `aef:uid` is ABSENT — `corpus_spec` emits a uid on every map AEF generates, so it
      never runs for them. Recommending a re-pin *for T-364* would be advice issued from
      a capability zero, which is the failure this arc has caught three times now.

- [x] **AEF's specific harm is evidenced with dates**, so the escalation is not a
      characterisation: T-311 fix date, 0.8.0 cut date, and the dates of their four
      reported instances, with the `grep -c docComment` measurement across `src`,
      0.8.0 and 0.7.1 as the proof the fix is absent from the pinned artifact.

      | date | event |
      |---|---|
      | 2026-07-29 | **0.8.0 cut** (`1a13035c`), sha `cab3c751…0935`, 903600 B |
      | 2026-07-29 | AEF instance 1 — `draft-knowledge-leveling` v5→v6 |
      | 2026-07-29 | AEF instance 2 — `draft-trigger-handling` v1→v2 |
      | 2026-07-30 | **T-311 fixed here** (`8c54906b`) — one day after the cut |
      | 2026-08-08 | AEF instance 3 — `draft-inception-readiness` v1→v2 |
      | 2026-08-08 | AEF instance 4 — `aef-task-lifecycle` v1→v2 (their only detail-authority map) |

      Proof the fix is absent from what they run:
      `grep -c docComment` → `src` **5**, `0.8.0` **0**, `0.7.1` **0**.

      **Nine days between our fix and their instances 3 and 4.** In that window they
      diagnosed it independently, repaired their detail-authority map by hand as v3, and
      re-raised a standard proposal (RAIL-332) partly to work around it. All of that
      effort was spent on a defect already fixed on this side.

- [x] **The structural question is answered, not the instance.** Why was this invisible
      for 9 days? Name the specific missing check — what would have to exist for a
      consumer-visible fix sitting unreleased to be *reported* rather than *asked
      about*. "Cut a release" is mitigation; this AC is about prevention, and per G-019
      a >7-day blindness gets registered even as a single incident.

      **Every gate in this project runs against `src`.** The bridge suite, the geometry
      sweep, `_t308` byte-identity, the render gate, all 38 CDP probes — all of them
      open `src/aef-workflow-designer.html`. They answer "is the code correct", and
      they answer it well. **Not one of them answers "is the code the consumer runs
      correct", and no instrument holds both artifacts at once.**

      `dist/MANIFEST.yaml` is the consumer-facing contract and it records `latest`,
      `sha256` and `bytes` — the identity of what was cut. It records nothing about
      what has happened since. So the state "a consumer-visible fix exists and is not
      in the pinned artifact" **has no representation anywhere in the system.** It is
      not that a check failed; there is no place where the two facts meet.

      That is why it took a direct human question to surface. It is also why it would
      have kept surviving: nothing degrades, nothing goes red, the number just grows.
      The nearest thing to a signal was my own RAIL-440, which shipped AEF three commit
      hashes and no version — I told them *what changed* in a vocabulary that cannot
      express *whether they have it*.

      **The missing check, named:** a standing, visible delta between `src` and the
      pinned release — count of commits, count that are consumer-visible in emitted
      bytes, and the age of the oldest. Surfaced where it is read without being asked
      for (`fw doctor` / the audit / Watchtower), and reported as a number rather than
      a gate. It must NOT block: development ahead of a pin is normal and healthy, and
      a gate here would either be bypassed daily or would stop the work. The defect is
      silence, so the remedy is a report.

      **Consumer half.** AEF had no way to ask "am I current?" other than asking me.
      `MANIFEST.yaml` is already the file they read at re-pin, so it is the natural
      carrier for an unreleased-delta line — but that is a protocol change and belongs
      in `docs/aef-designer-integration-protocol.md`, not in a task I close today.

      **Prevention vs mitigation, explicitly:** cutting 0.9.0 removes today's instance
      and resets the counter to zero. Tomorrow's first consumer-visible commit
      re-creates the identical condition with nothing watching. The release is the
      mitigation. The report is the prevention. This task delivers neither — it
      delivers the diagnosis and the escalation, and the concern below is what keeps it
      from being closed by the mitigation.

- [x] **A concern is registered in `concerns.yaml`** with a trigger that is closable by
      evidence, not by intent — and NOT closed by cutting 0.9.0. The gap is the
      blindness; cutting a release removes today's instance and restores the same
      condition tomorrow.

      **G-024 registered, severity high, status watching.** Register goes 16 → 17
      watching; `fw gaps` renders it. Its trigger asks for a standing visible delta
      (commits / consumer-visible count / age of oldest) surfaced without being asked
      for, plus the consumer half so AEF can answer "am I current?" without asking me.
      The detail states explicitly that cutting 0.9.0 does not close it.

- [x] **The escalation packet is delivered to the operator in one copy-pasteable
      block**, since the release cut is theirs. It must state what is in the 8, what
      AEF is waiting on, and what re-pinning does NOT fix (T-364 is a no-op for AEF's
      corpus — every map they generate carries an authored `aef:uid`, so the derivation
      path never executes; recommending a re-pin *for T-364* would be advice from a
      capability zero).

      Delivered in-session, and recorded here so it survives the conversation. The cut
      itself is the operator's and is NOT attempted under agent control:

      ```
      cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-368 --status work-completed
      ```

      Release cut, when the operator decides to make it (VERSION bump then cut):
      ```
      cd /opt/832-Workflow-designer && echo "0.9.0" > VERSION && bash scripts/release-designer.sh
      ```

### Human

- [ ] [REVIEW] **Decide whether to cut 0.9.0, and whether AEF should be told to re-pin.**

  This is a judgement call, not a mechanical one: 5 of the 8 unreleased commits change
  emitted bytes, one of them (T-311) is a defect AEF has reported four times and
  hand-repaired around, and the arc has an open release-immutability gap (G-007) that
  bears on how a cut is made.

  **Steps:**
  1. Read the per-commit table in AC1 above — 5 consumer-visible, 2 explicitly not
     reasons to re-pin (T-358 emits nothing; T-364 is a no-op for AEF's corpus).
  2. Decide: cut 0.9.0 now, cut after some subset lands, or hold.
  3. If cutting: `cd /opt/832-Workflow-designer && echo "0.9.0" > VERSION && bash scripts/release-designer.sh`
  4. If cutting, tell me so I can post the version + sha to AEF on the rail — they are
     pinned at 0.8.0 and asked directly at RAIL-443 whether a newer release exists.

  **Expected:** a decision recorded; if cut, `dist/MANIFEST.yaml` `latest:` reads
  `0.9.0` and the new artifact's sha256 matches the file.

  **If not:** holding is a legitimate answer — but AEF is currently spending real effort
  on T-311, so if the answer is "hold", say roughly for how long and I will tell them
  to stop working around it rather than leaving them to keep paying for it.

- [ ] [REVIEW] **Is a notation/routing revision actually planned?**

  AEF's operator told them I am "improving and revising the NOTATION and ROUTING" and
  they are holding a mid-draft 3-lane cycle map on the answer. **I searched my task tree
  and found no such revision** — the routing-adjacent active tasks are T-286 (arrowhead
  z-order), T-102 (a layout-heuristic false positive) and T-289 (typing-vocab note,
  horizon `later`). I told AEF at RAIL-444 to draft into the current notation and that I
  would correct within the day if you contradict me.

  **Steps:** confirm or deny that a notation/routing revision is planned, and if it is,
  say whether it touches lane semantics, cycle/return-edge authoring, or the frozen
  standard's §1 presentational clause (`aef:routing` / `routingHint` / `loopDetour` /
  `anchors`).

  **Expected:** yes-with-scope, or no.

  **If not (i.e. if it IS planned):** tell me today — AEF is drafting against the
  current notation on my say-so and would rather draft into the new one than re-cut.

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

## Recommendation

**Recommendation:** GO — cut 0.9.0, and tell AEF to re-pin.

**Rationale:** 5 of the 8 unreleased commits change bytes a consumer observes, and one
of them is a defect AEF has reported four times over two months and is actively paying
to work around. The cost of holding is being borne by the peer right now, in hand
repairs to their only detail-authority map. The cost of cutting is a version bump and a
rail post.

The safety objection that would normally apply does not: **G-007 (no immutability guard
in `release-designer.sh`) is about RE-CUTTING an already-released version and silently
mutating bytes a consumer has pinned.** 0.9.0 is a fresh version, so no existing pin can
move. The guard must stay respected in the obvious way — bump `VERSION` to `0.9.0`
first, never re-run the cut at `0.8.0`.

Two things I explicitly do NOT recommend re-pinning for, because saying so is part of
the advice: **T-358** emits nothing (its own byte-identity evidence is 24/24 identical),
and **T-364**'s uid derivation executes only where `aef:uid` is absent — `corpus_spec`
emits a uid on every map AEF generates, so the path never runs for them. Both are real
fixes; neither is a reason for AEF to move.

**Evidence:**
- Per-commit consumer-visibility table, AC1 above — 5 YES, 2 no, 1 render-only.
- `grep -c docComment` → `src` 5, `dist/…-0.8.0.html` 0, `dist/…-0.7.1.html` 0. The
  T-311 fix is measurably absent from the pinned artifact.
- T-311 fixed `8c54906b` 2026-07-30; 0.8.0 cut `1a13035c` 2026-07-29. One day apart.
- AEF instances 3 and 4 dated 2026-08-08 (RAIL-443), nine days after the fix.
- AEF's pin verified against our artifact: sha256 `cab3c751…0935`, 903600 B, exact match.
- `src` is 934239 B against the pinned 903600.
- G-024 registered high/watching; `fw gaps` 16 → 17.

**What this does NOT close:** G-024. Cutting resets the counter to zero and restores the
same silence tomorrow. The release is the mitigation; a standing visible src-vs-pin
delta is the prevention, and it is not built.

## Verification

python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
.agentic-framework/bin/fw gaps 2>&1 | grep -q "G-024"

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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-08T06:47:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-368-release-state-blindness-8-src-commits-ah.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ae15cd46
- **Timestamp:** 2026-08-08T06:52:18Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 2
     - evidence: `.agentic-framework/bin/fw gaps 2>&1 | grep -q "G-024"`

### 2026-08-08T06:52:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
