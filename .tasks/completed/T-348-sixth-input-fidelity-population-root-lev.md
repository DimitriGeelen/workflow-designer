---
id: T-348
name: "Sixth input-fidelity population: root-level siblings of the process element"
description: >
  Populations 1-5 all ask about a single bpmn:process and what lives inside it (unknown tag, unknown branch, malformed doc, unresolvable ref, content of an accepted element). Nothing has ever asked what happens to definitions' OTHER children — bpmn:collaboration, participant/messageFlow, bpmn:message, bpmn:signal, bpmn:error, bpmn:dataStore, or a second bpmn:process. These are referenced BY nodes, so dropping them may emit a document with dangling references rather than merely a poorer one: a different consequence class from T-347.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T12:44:22Z
last_update: 2026-08-16T09:25:15Z
date_finished: 2026-08-16T09:25:15Z
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

# T-348: Sixth input-fidelity population: root-level siblings of the process element

## Context

Five input-fidelity populations exist on `tools/_t338-input-fidelity-cdp.mjs`. Every one
of them asks a question about **a single `bpmn:process` and what lives inside it**:

| # | task | question |
|---|---|---|
| 1 | T-337 | an unknown flow-node **tag** |
| 2 | T-340 | an unknown **branch** (the whole `bpmndi` sub-tree) |
| 3 | — | a **malformed** document |
| 4 | T-341 | an **unresolvable ref** (`flowNodeRef`) |
| 5 | T-347 | the **content** of an element already accepted |

Nothing has asked what happens to `bpmn:definitions`' **other children**:
`bpmn:collaboration` (with `participant` / `messageFlow` — what every mainstream
modeller emits for pools), root-level `bpmn:message`, `bpmn:signal`, `bpmn:error`,
`bpmn:dataStore`, and a **second `bpmn:process`**.

The reason to ask separately rather than assume T-347's answer: these root elements are
**referenced by nodes**. If the designer drops the referent but keeps the referencing
construct, the emitted document has a **dangling reference** — invalid BPMN, not merely
poorer BPMN. That is a different consequence class from every population so far, all of
which lose data while leaving the output well-formed. If instead it drops both ref and
referent, the output is self-consistent and this collapses into T-347's decision.

**Which of those two it is, is the whole point of the task.**

## The answer

**SELF-CONSISTENT. The dangling-reference hypothesis is false** — and that is the
result, not a disappointment. Measured over 24 corpus maps:

| row | verdict | applied |
|---|---|---|
| `pool-identity` **(positive control)** | **ROOT-PRESERVED** | 24/24 |
| `second-process` | ROOT-DROPPED | 24/24 |
| `root-message` | ROOT-DROPPED | 24/24 |
| `root-signal` | ROOT-DROPPED | 24/24 |
| `root-error` | ROOT-DROPPED | 24/24 |
| `root-datastore` | ROOT-DROPPED | 24/24 |
| `second-participant` | ROOT-DROPPED | 24/24 |
| `message-flow` | ROOT-DROPPED | 24/24 |

**Dangling references introduced: none. Baseline: clean.**

The reason is structural and worth stating, because it makes the result robust rather
than lucky: `buildBpmnXml` emits a **fixed root skeleton** — one `collaboration`, one
`participant` with `processRef="Process_<id>"`, one `process` with that id. It does not
copy references from the input. So there is no mechanism by which a kept reference could
outlive a dropped referent. The output is always internally consistent; it is simply
smaller than what came in.

**Consequence: this folds into T-347 and does not open a second operator decision.**
The repair question is identical — (a) preserve-and-re-emit, (b) consume-as-typed,
(c) refuse — and answering it for unconsumed element *content* answers it for unconsumed
root *siblings* too.

**One qualification the operator should carry into that decision.** The rows are not
equally weighty. `root-signal` losing a declaration is a nuisance; `second-process`
losing an entire pool's worth of nodes is a different order of magnitude — a two-pool
collaboration opened and saved comes back as a one-pool document, with node/flow/lane
counts *of the surviving pool* completely unchanged, so every count-based instrument and
the validator stay green. Option (c) *refuse* is far more defensible for that row than
for a `documentation` string. If T-347 is answered uniformly, this row is the one most
likely to make the uniform answer wrong.

## What the corpus could not tell us

All 24 corpus maps are editor exports, so they carry exactly one process and one
participant. The entire population is therefore **injected**, and the finding is about
what the importer *would* do to a mainstream modeller's file, not about damage already
done to anything in this repo. `REFUSED` is never observed and no designer mutation was
written to produce it — recorded as **unwitnessed, not unreachable**.

## Acceptance Criteria

### Agent
- [x] A sixth population is added to `tools/_t338-input-fidelity-cdp.mjs` covering the
      root-level siblings of the process element: `second-process`, root `message`,
      root `signal`, root `error`, `dataStore`, `second-participant`, `messageFlow`
      (7 shapes + 1 control).
- [x] **(AMENDED — see Evolution.)** The population contains a positive control that must
      survive: **pool identity**, not the process element. A predicate on the process
      element would be permanently true — `buildBpmnXml` hard-codes `<bpmn:process …>` —
      so it could not have been false and would have proved nothing (T-335's near-miss).
      Pool identity is input-derived (`partEl?.name || procName` → `state.pool.name` →
      re-emitted on `bpmn:participant`), so it is answerable to the subject.
- [x] Every row records whether injection actually reached the input (marker present
      before round-trip). A row that applied to 0 maps is a failure, not a zero.
- [x] The dangling-reference question is answered explicitly, from the emitted document:
      every IDREF attribute is resolved against the ids present in the output, and the
      result is differenced against an **unmutated-corpus baseline** so a pre-existing
      dangling ref cannot be mistaken for one the injection caused.
- [x] Teeth 6/6. Legs (a)/(b) mutate the **designer**: (a) teaching the importer to carry
      a root `bpmn:message` into pool identity flips `root-message` DROPPED→PRESERVED;
      (b) neutering the pool-identity read flips the control PRESERVED→DROPPED. Both
      buckets proven producible in the subject. Every leg requires the failure text to
      name its own condition.
- [x] `CONTENT-MOVED`-equivalent buckets recorded honestly: `REFUSED` is never observed in
      this population and **no designer mutation was written to produce it**, so it is
      recorded as unwitnessed rather than left to read as "the designer never refuses a
      root sibling".
- [x] The instrument stays green (`rc=0`) with `EXPECTED_ROOT` declared, and every row is
      re-measured each run — a row that flips PRESERVED must be recorded deliberately, so
      the expectation set cannot decay into a permission list.
- [x] **Folded into T-347, no new operator decision opened** — see "The answer" below.

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
# G-015 note: no global count is pinned below. The instrument re-measures every
# row each run and fails on DRIFT from EXPECTED_ROOT, which is what makes it a
# gate rather than a snapshot.

out=$(timeout 1200 node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "^OK:"
out=$(timeout 1200 node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "pool-identity          ROOT-PRESERVED"
out=$(timeout 1200 node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "dangling refs: none introduced"
node --check tools/_t338-input-fidelity-cdp.mjs

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

### 2026-08-02 — the positive control I specified could not have failed

- **What changed:** the AC named "the first `bpmn:process` itself" as the positive
  control. `buildBpmnXml` **hard-codes** `<bpmn:process id="Process_${…}">`, so that
  predicate is true whatever the importer does — it would have reported PRESERVED over an
  empty document. A control that cannot fail certifies nothing and would have made the
  seven DROPPED rows look verified when they were merely unopposed.
- **Plan impact:** control changed to **pool identity**, whose value is read from the
  input (`partEl?.name || procName`) and re-emitted, so it is answerable to the subject.
  Teeth leg (b) proves it: neutering that read flips it to DROPPED.
- **Triggered:** AC amended in place. Same family as T-335's `REPAIRED` near-miss and
  T-336's permanently-green VALUE check — the third time on this arc that a predicate was
  written against something the emitter guarantees.

### 2026-08-02 — the dangling-ref checker invented 21 findings before it found any

- **What changed:** the first version matched any attribute whose name ended in `ref`.
  That swept up AEF's own semantic `ref="…"` payloads — `ref="G-019"`,
  `ref="P-010 [--skip-acceptance-criteria]"`, `ref="docs/reports/*.md"` — and reported
  **21 pre-existing dangling references in every corpus export**. Entirely an artefact of
  the instrument. Caught by printing the *members* rather than trusting the count.
- **Plan impact:** predicate narrowed to an explicit `IDREF_ATTRS` set. Because that is a
  large narrowing, the checker now runs its own **positive, negative and exclusion
  controls** before it is used on anything, and teeth leg (e) re-widens it to the broken
  form and requires the exclusion control to fire — the retracted assumption installed as
  a failing leg rather than resolved-to-be-more-careful.
- **Triggered:** learning recorded. An anomaly *count* is not a finding until its
  *members* have been read; 21 looked like a serious result and was noise.

### 2026-08-02 — a teeth leg went red for the wrong reason, for the third time on this arc

- **What changed:** leg (c) (empty the population) failed its own check: `rc=1` but the
  output never named the condition. The mutation had missed a blank line, leaving
  `.concat([` unclosed — node died at parse.
- **Plan impact:** none to the finding. The leg **worked**: requiring the failure text to
  name its own condition is precisely what stopped a syntax error being banked as proof.
- **Triggered:** nothing new — this is T-338 leg (d) and T-343 leg (d) again. Worth
  recording that the requirement has now paid three times, which is a stronger argument
  for it than the reasoning that introduced it.

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

### 2026-08-02T12:44:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-348-sixth-input-fidelity-population-root-lev.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0e080acb
- **Timestamp:** 2026-08-16T09:25:39Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T09:25:15Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
