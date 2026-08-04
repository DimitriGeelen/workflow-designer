---
id: T-358
name: "Importer FABRICATES lane and pool structure the input never had: every third-party document gains 3 lanes and 1 participant on open"
description: >
  Measured T-356: all 5 third-party fixtures come out of open->save carrying lanes 0->3 and participants 0->1. None of the input documents contains a single lane or pool. The catalogued import-loss class (T-337/340/347/348) is subtraction; this is the opposite direction and needs a different repair.

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
created: 2026-08-03T16:12:36Z
last_update: 2026-08-04T10:06:19Z
date_finished: null
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
---

# T-358: Importer FABRICATES lane and pool structure the input never had: every third-party document gains 3 lanes and 1 participant on open

## Context

Measured 2026-08-03 by `tools/_t356-third-party-fidelity-cdp.mjs`; full table in
`docs/reports/T-356-third-party-fidelity.md`.

All **five** third-party fixtures gain `lanes 0->3` and `participants 0->1` on
open->save. **None of the input documents contains a single lane or pool.**

The whole import-loss class this arc has catalogued -- T-337 foreign tags, T-340 DI,
T-347 accepted-element content, T-348 root shapes -- shares one sentence: *what the
importer does not enumerate is invisible, and export writes only what `state`
holds*. That sentence describes **subtraction**.

This is the other direction. Export also writes what `state` holds **that the input
never did**, because `state` is initialised into our own lane skeleton and *an
absent lane set is indistinguishable from an empty one*. Same root shape as T-341
(an unresolvable `flowNodeRef` silently reassigns a node to the human lane) and the
same shape as the `n/a`-means-agreement family: a missing thing and a default thing
share one representation.

**Why this is worse than dropping.** A dropped element leaves a gap somebody may
notice. An invented lane assignment is **positively asserted governance metadata**
-- Lane=who, per the frozen mapping standard -- and it reads exactly like the
author's intent. Node counts stay plausible, the validator stays green, and the
document now says a third party's task is owned by a role their tool never
mentioned.

Blocked-adjacent, not blocked: the repair choice interacts with T-341's orphan-lane
ruling (both are "what do we do when lane membership is absent or unresolvable")
and should be decided with it, not before it.

## Acceptance Criteria

### Agent
> ### Investigation 2026-08-03 — site named, and the partition is NOT total
>
> **The site.** In `parseBpmnXml`, immediately after the `laneSet` read loop:
> `if (!lanes.length) lanes.push(...defaultLanes());` (`src` ~9647 — anchor on the
> `defaultLanes()` call inside `parseBpmnXml`, not the line number).
>
> **`defaultLanes()` (`src` ~1620) is not a neutral skeleton — it is the Authority
> Model.** It returns `human / Human · Sovereignty / authority: 'sovereignty'`,
> `framework / Framework · Authority / authority: 'authority'`, and
> `agent / Agent · Initiative / authority: 'initiative'`.
>
> **And every node lands in the first one.** Node lane membership resolves via
> `let laneId = lanes[0]?.id;` then searches `flowNodeRef` entries for a match. A
> document with no lanes has no `flowNodeRef` to match, so the initialiser stands:
> **`lanes[0]` is `human`, `authority: 'sovereignty'`.**
>
> So the accurate statement of this defect is not "three lanes appear". It is:
> **opening a third-party BPMN file silently asserts that every task in it is
> human-sovereign** — the highest authority level in the model, the one that means
> "can override anything, is accountable" — and saving makes that assertion the
> document. The author's tool has no concept of any of this.
>
> **AC2 is NOT satisfied, and that is the result the AC was written to force.**
> There are **three** paths into `!lanes.length`, not the two anticipated:
> (i) the input has no `laneSet` at all; (ii) a `laneSet` exists but yields zero
> `lane` children; (iii) `laneSets[0]` is empty while a *later* laneSet has lanes —
> the T-348 first-only read. **All three produce byte-identical output.** They
> cannot be separated by any current instrument, so per this AC's own terms the
> repair is blocked on making the partition total, not on choosing a default.
>
> Same landing site as T-341 (unresolvable `flowNodeRef` → human lane) reached by a
> different cause, which is why the two must be ruled on together: a fix that only
> changes the default value leaves three causes still sharing one output.

- [x] **The fabrication is reproduced and its SITE named** -- the specific line(s)
      where `state` acquires lanes/participants absent from the input, not "somewhere
      in parseBpmnXml". Anchor on a function signature, never a line number (they
      drift; T-340's filed anchor already did).

- [x] **The two causes are separated before any repair.** "Input had no lane set" and
      "input had a lane set we failed to read" currently produce the same output and
      must not share a verdict. Required evidence: one fixture of each, with
      different measured outcomes. If they cannot be separated, that is the finding
      and the repair is blocked on making the partition total.

      **Done — and the AC's own escape clause is what fired.** The investigation found
      **three** causes, not two, so "separate the two" was not satisfiable as written;
      the partition had to be *made* total first. `parseBpmnXml` now records
      `laneProvenance` over four disjoint values — `authored`, `defaulted:no-laneset`,
      `defaulted:empty-laneset`, `defaulted:later-laneset-ignored` — assigned on every
      path, so no document can leave the function without one.

      Evidence: `tests/fixtures/lane-provenance/` (four independently authored XML
      shapes, one per branch) run through the real importer in headless Chrome by
      `tools/_t358-lane-provenance-cdp.mjs` → **4 fixtures, 4 distinct verdicts**. The
      run fails if any two collide, so "separable" is asserted, not assumed.

      Branch order is load-bearing: (iii) is tested before (ii) because a document
      satisfying (iii) also satisfies (ii)'s surface condition, and reporting it as a
      plain empty laneSet would file **our** T-348 first-only read under **the
      author's** omission — the one case where the data was present and we discarded it.

      This chooses no default and changes no emitted byte: `_t308` byte-identity
      **24/24 identical, 0 drifted**. T-341's ruling is untouched and still the
      operator's.

- [x] **A negative control proves the probe can report NO fabrication.** A designer-
      produced corpus map genuinely has 3 lanes, so a probe that merely counts lanes
      in the output reads "3" for both the honest and the fabricated case and
      discriminates nothing. The control must be input-derived: lanes-in equals
      lanes-out for a map that carried them.

      **Done.** `authored-lanes.bpmn` carries 2 lanes named `Operations` / `Finance`
      and comes back `authored`, **2 in / 2 out**, with those exact names — a count of
      3 could not have distinguished it. Checked as its own assertion (control must be
      the only non-defaulted case, and its lane *names* must be input-derived), so it
      cannot pass by riding on the provenance check.

      `tools/_t358-teeth.py` proves both ACs' instruments can fail: control green plus
      **6 mutations, each red for its own predicted reason** — including one that
      changes only what a fabricated lane *asserts* (`sovereignty` → `none`), since the
      assertion and not the lane count is the defect this task names.

      **The teeth found a real defect in my own probe, which is why they exist.** The
      totality check was written as `seen.some(v => v === undefined)` over an array
      built with `.filter(Boolean)` — which strips exactly the values it looked for, so
      it could never fire. Mutation 3 was green when it should have been red. Totality
      is now tested before anything is filtered. An unreachable check is a constant,
      and a constant discriminates nothing.

- [ ] **Repair does not silently reverse into the opposite defect.** Emitting zero
      lanes for a lane-less input must be checked against the corpus: if any existing
      map relies on the fabricated default, that reliance is a finding to file, not a
      reason to keep fabricating.

      > ### Measurement 2026-08-04 — the AC fires. NOT ticked, and that is the result.
      >
      > `tools/_t358-empty-lanes-blast-radius.mjs` — round-trips fixtures through the
      > REAL importer and REAL emitter in headless Chrome, on two builds served side by
      > side: the tree as it stands, and a temp copy with the fabrication suppressed
      > (the real tree is never edited — same discipline as `_t358-teeth.py`).
      >
      > **F1 — the naive repair reverses into the opposite defect, as this AC suspected.**
      > The fabrication sites are guarded by **different predicates**: the importer on
      > *emptiness* (`!lanes.length`, ~9705), every downstream site on *nullishness*
      > (`s.lanes || defaultLanes()` ~9511, `getLanes()` ~2087, `addLane` ~8068). `[]` is
      > truthy, so an empty array flows through all of them untouched and reaches an
      > emitter that opens `<bpmn:laneSet id="LaneSet_1">` unconditionally. Measured:
      > suppressing the importer default gives `lanes=0`, and we emit `laneSet=1,
      > lane=0` — **we would emit cause (ii) "empty laneSet", the exact shape our own
      > partition classifies as a third-party defect**, and our own output then
      > re-imports as `defaulted:empty-laneset`. Rendering survives (`renderAll()` ok on
      > all rows), so the opposite defect is semantic, not a crash — which is worse,
      > because nothing announces it.
      >
      > **F2 — NOT predicted, and it bounds what T-358 shipped: the fabrication
      > LAUNDERS ITSELF in one round-trip.** On the current build, `no-laneset.bpmn`
      > imports as `defaulted:no-laneset` — then our own emitted output re-imports as
      > **`authored`**, 3 lanes, with `authority="sovereignty"` in the bytes. Open a
      > third-party file, save it, reopen it: the second open reports the fabricated
      > assertion as human-authored, **by my own instrument**.
      >
      > So `laneProvenance` is a **parse-time** property, not a **document** property.
      > It survives exactly one hop. Saving is precisely what makes the assertion the
      > document, so the signal dies at the moment it would matter. Consequence for the
      > ruling: **any repair must act at or before the first save — a report-only
      > remedy cannot reach the corpus**, and cannot reach any file already saved.
      >
      > **The corpus half, answered — and the zero is a capability zero.** 141 `.bpmn`
      > in tree: 9 no-laneSet + 1 empty-laneSet = 10 that would import to `lanes=0`.
      > All 10 are test fixtures (8 authored for this defect class) plus one
      > hand-authored e2e probe under `.editor-versions/_trash/`. So **no production map
      > relies on the fabricated default** — but 122/141 carry `aef:position`, our own
      > exporter's fingerprint, and per F2 any third-party file that ever passed through
      > the editor was laundered into the "has lanes" bucket at its first save. The
      > census measures our generator, not the population — the same shape as the T-340
      > DI census (126 files, 0 with DI). Quoted as a bound on the evidence, not as
      > reassurance.
      >
      > This AC stays unticked: the obvious repair fails it. That is the AC working.
      >
      > ### Candidates MEASURED 2026-08-04 — so the ruling is a choice between outcomes
      >
      > `tools/_t358-repair-options-cdp.mjs` applies each candidate to a temp copy and
      > round-trips it through the real importer/emitter. No candidate is applied to
      > the tree; the default choice remains the operator's.
      >
      > | candidate | fabricates | asserts sovereignty | provenance survives save | emits empty laneSet | corpus bytes |
      > |---|---|---|---|---|---|
      > | current (no repair) | yes (3) | **true** | **no** | no | identical |
      > | **A** drop (importer + emitter) | no | false | yes | no | identical |
      > | **B** mark (provenance into the doc) | yes (3) | **true** | yes | no | identical |
      > | **C** neutral default (1 lane, `unassigned`) | yes (1) | false | no | no | identical |
      > | **AB** drop + mark | no | false | yes | no | identical |
      >
      > `renderAll()` ok on every candidate. Reading the table: **A alone ends the
      > fabrication; B alone ends the laundering; neither ends the other.** A's
      > "survives save" is not the signal being preserved — it is the *input property*
      > being preserved, which is the point of A. C keeps a lane for the downstream
      > consumers that assume one, at the cost of still inventing structure. Note A
      > requires BOTH halves: dropping only the importer half emits cause (ii) (F1).
      >
      > ### The probe's own instrument was wrong first, and it exposed a separate defect
      >
      > The first run printed "this candidate also changed the AUTHORED control's
      > output" for **all four** candidates — including ones that touch only the
      > defaulted path. Shape of the result said probe defect, not finding: the base row
      > compared its own sha against itself and so could never fire. Added an instrument
      > self-check (emit the same document twice in the same build). Result: **the build
      > is not byte-stable with itself** on those documents, so the comparison was void
      > rather than the candidates faulty.
      >
      > Diagnosed by `tools/_t358-export-determinism.mjs`: **`aef:uid` is minted fresh
      > per parse for any node that lacks one.** Designer-produced maps carry uids and
      > emit deterministically (`audit-process` 13563 bytes, `arc-lifecycle` 12270 —
      > stable); every third-party fixture is unstable (`kitchen-sink` differs on **81
      > lines** between two consecutive emits of the same input).
      >
      > **Consequence for this arc's main instrument:** `_t308` byte-identity 24/24 is
      > sound, and is sound *only for designer-produced maps* — the population that
      > happens to carry uids. It is structurally incapable of reporting on third-party
      > documents, which is the population every repair in this arc is aimed at. Not a
      > flaw in the 24/24 result; a bound on what it can be cited for, and I have cited
      > it repeatedly without that bound. Filed separately — one bug, one task.

- [ ] Bridge suite green; `_t308` byte-identity still 24/24 (a repair here must not
      change what we emit for existing maps)

- [ ] `tools/_t356-third-party-fidelity-cdp.mjs` re-run: `lanes` and `participants`
      deltas gone from all five rows, with the other columns unchanged (this task
      repairs fabrication only, not the DI/pool/node losses those rows also carry)

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

bash tests/run-bridge-tests.sh
node tools/_t356-third-party-fidelity-cdp.mjs

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

### 2026-08-03T16:12:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-358-importer-fabricates-lane-and-pool-struct.md
- **Context:** Initial task creation

### 2026-08-03T16:42:23Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
