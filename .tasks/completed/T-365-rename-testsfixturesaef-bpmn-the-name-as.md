---
id: T-365
name: "fixtures/aef-bpmn asserts a provenance it lacks — claim fixed at source; the rename is a two-party standard delta, not a refactor"
description: >
  T-364/RAIL-438 surfaced this: the directory name reads as 'AEF's BPMN fixtures' and every file in it was added by an 832 task commit (T-183/192/204/208/214/215/219/235/308/310/311/312/313; three labelled pair-draft, rest ours outright). AEF has 5 files at the same path; we have 18; one of theirs is absent here. I read the name as provenance and published a corroboration claim to the peer that had to be retracted at RAIL-438 — the measurement was careful and the noun came from the filesystem. Blast radius measured: 150 files reference the string, including .context/episodic/* (historical records that must NOT be rewritten — they record what was true when written) and .agentic-framework/docs/reports/* (vendored AEF material, G-008 territory). Needs scoping before any git mv: which reference classes get rewritten, which are frozen history, and whether a rename or a split (seam-fixtures-ours vs genuinely-peer-supplied) is correct.

status: work-completed
workflow_type: refactor
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-04T13:18:53Z
last_update: 2026-08-11T22:29:03Z
date_finished: 2026-08-11T22:29:03Z
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

# T-365: fixtures/aef-bpmn asserts a provenance it lacks — claim fixed at source; the rename is a two-party standard delta, not a refactor

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

**REWRITTEN 2026-08-11.** The original ACs below the fold assumed a `git mv`. That
premise was falsified: the path is normative inside the frozen two-party standard (see
`## Decisions`), so the rename is a standard delta, not a refactor. These ACs implement
**option C** — fix the claim where it can be fixed — and hand **option D** to AEF and
the operator.

### Agent
- [x] The rename is NOT performed, and the reason is recorded with evidence:
      `aef-bpmn-mapping-v1.md:142` (Part I frozen, Part II begins at 146) and
      `aef-bpmn-forward-compile-v1.md:21`/§5 both name the path normatively.
- [x] Blast radius re-measured rather than quoted, on the PRECISE string. The
      recorded 37 was measuring `aef-bpmn`, which also matches the two standards
      (46 files) — a blanket rewrite would have edited the frozen document
      itself. True live set on `fixtures/aef-bpmn`: **22 files**. The drift in
      the previously-recorded figures (37→22, 17→18 fixtures) is stated.
- [x] `PROVENANCE.md` states explicitly that the directory name asserts **scope,
      never authorship**, names the per-file table as the only provenance source,
      and records why the name cannot be changed unilaterally.
- [x] A mechanical guard exists for the half that is mechanizable:
      `tools/_t365-normative-fixture-guard.py` asserts every fixture path the
      standards name normatively resolves on disk.
- [x] The guard DERIVES paths by reading the standards rather than restating
      them, so a standard revision moves the checked set instead of leaving the
      guard passing on an old promise.
- [x] The guard is mutation-proven in both directions: the exact rename option A
      would have performed drives it to `fails=2, rc=1`; standards that name no
      fixture path drive it to `rc=2 ABSTAINED`, never a green.
- [x] No frozen or historical bytes edited: `git diff --exit-code` clean on
      `docs/standards/`, and `.context/episodic/`, `.tasks/completed/`,
      `docs/reports/`, `.agentic-framework/` untouched.
- [x] Option D (rename as a standard delta) is put to AEF on the rail rather than
      decided here.

<details><summary>Original ACs (superseded — kept, not deleted)</summary>

1. ~~Scoping decision recorded: single rename vs. split~~
2. ~~Move performed with `git mv`~~
3. ~~Every LIVE reference updated (37 files)~~
4. ~~PROVENANCE.md updated to explain what the NEW name asserts~~

(Rendered as a numbered list, not checkboxes — leaving `- [ ]` here would make P-010
count superseded criteria as outstanding work.)

Superseded because all four presuppose the rename. Kept visible so the reversal is
auditable rather than tidied away.

</details>

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

# --- T-365 (option C) ---
# 1. Every fixture path the standards name normatively resolves. Derives paths by
#    reading the standards, so a revision moves the checked set. Abstains (2) rather
#    than passing if the extraction stops matching.
python3 tools/_t365-normative-fixture-guard.py
# 2. The frozen two-party standards are unmodified under agent control.
git diff --exit-code -- docs/standards/
# 3. The normative path still exists — i.e. no rename was performed by this task.
test -d tests/fixtures/aef-bpmn
# 4. PROVENANCE.md carries the scope-not-authorship statement the whole option rests on.
grep -q "asserts SCOPE, not AUTHORSHIP" tests/fixtures/aef-bpmn/PROVENANCE.md

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

### 2026-08-08 — picked up as "mechanical", stopped when it wasn't

- **Chose:** do not `git mv`; hand over with the scoping decision stated.
- **Why:** I selected this at 79% budget as a bounded mechanical rename, having
  read only the title. The task's own `description` says the open question is
  *rename vs. split*, and ends "Needs scoping before any git mv." Three fixtures
  (`session-handover` T-214, `dispatch-loop` T-215, `offpage-seam` T-219) are
  genuine pair-drafts with AEF; the other 14 are ours outright. A single rename
  asserts one provenance over a directory that demonstrably has two.
- **Rejected:** renaming to `aef-seam/` anyway and noting the split as a
  follow-up. That is the same error the directory already embodies — a name
  asserting a uniform provenance the contents do not have — committed a second
  time, in a task that exists to fix exactly that.

### 2026-08-11 — the rename is not ours to make, and A/B were the wrong question

Both options below assume the path is an internal implementation detail. It is not.
Measured before touching anything:

- **`docs/standards/aef-bpmn-mapping-v1.md:142`** names
  `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` as a **Reference fixture**. That line
  is at 142; `# Part II — Provisional` begins at 146. **It is inside Part I — Frozen**,
  the two-party standard this project may not edit under agent control.
- **`docs/standards/aef-bpmn-forward-compile-v1.md:21`** names
  `tests/fixtures/aef-bpmn/*.bpmn` as **"the reference corpus"**, and **§5 at :106 is
  titled after the path**.

So the directory name is **normative in a frozen shared contract**. Renaming it
unilaterally would (a) strand a reference in a document I cannot edit, and (b) move a
path AEF's forward-compile contract names as the corpus — a seam change dressed as
housekeeping.

**A near-miss worth recording, because it is the same class the task exists to fix.**
My first census returned "42 live references" and I nearly acted on it. The string
`aef-bpmn` matches TWO unrelated things: the fixture directory, and
`docs/standards/aef-bpmn-mapping-v1.md` / `-forward-compile-v1.md`. **46 files
reference the standards.** A blanket `sed s/aef-bpmn/aef-seam/` — the obvious
mechanical execution of option A — would have rewritten every reference to the frozen
standard, including inside the standard itself. Re-censused on `fixtures/aef-bpmn`:
**22 live files**, not 37 and not 42.

The recorded "so the next pickup does not re-measure" numbers had also drifted: 37 → 22
live (different string), and 17 → 18 fixtures. A measurement filed as durable aged
silently, which is why it was re-measured rather than quoted.

**Revised options:**

- **C — do not rename; fix the claim where it can be fixed.** The name stays because
  the standard makes it normative. `PROVENANCE.md` states explicitly that the directory
  name asserts SCOPE (fixtures about the AEF seam), never AUTHORSHIP, and the per-file
  table is the only provenance source. Add a mechanical guard that the fixtures the
  standards name normatively actually exist, so the seam contract is checked rather
  than assumed.
- **D — propose the rename to AEF as a standard delta**, queued with the v1.1 deltas
  already drafted by T-189 and T-195. Two-party, operator-governed, not a refactor.

**Recommended: C now, D offered to AEF.** C removes the actual failure mode — the
original incident was reading a directory NAME as provenance and publishing a
corroboration claim that had to be retracted at rail 438. AEF reads the same path from
their own standard and would read it the same way, so making the name's meaning
explicit at the source protects both sides. A rename does not: it produces a *new* name
that a future reader will also interpret, in a document neither side may edit.

C is agent-executable. D is AEF's and the operator's. **No `git mv` performed.**

### The decision needed — SUPERSEDED by the entry above (A/B assumed the path was ours)

**A — single rename** to `tests/fixtures/aef-seam/`. Cheapest, one path to
update, PROVENANCE.md carries the per-file nuance as it already does. The name
becomes "fixtures about the AEF seam", which is true of all 17.

**B — split** into `tests/fixtures/seam-ours/` (14) and
`tests/fixtures/seam-pairdraft/` (3). Encodes the distinction in the filesystem,
where it cannot be missed by someone who does not open PROVENANCE.md. Costs a
second path, and the 3 pair-drafts are co-authored rather than AEF-supplied, so
even this split does not produce a "theirs" directory — arguably it invents a
distinction finer than the evidence supports.

**Weight for A:** the original failure was reading a *directory name* as
provenance and publishing a corroboration claim to AEF that had to be retracted
(rail 438). What prevents a recurrence is that no name claims provenance at all
— which A achieves and B partially undoes by reintroducing provenance into
paths.

### Established this session (so the next pickup does not re-measure)

- 186 files reference `aef-bpmn`; **37 are live** (tests/ tools/ scripts/ src/
  lib/ web/ docs/ minus docs/reports/). The rest are episodic memory, completed
  tasks, and vendored AEF reports — all frozen history.
- Directory holds 17 fixtures + `PROVENANCE.md` + one subdirectory
  (`t257-eventdef-roundtrip`).
- `PROVENANCE.md` already contains the per-file authorship table and names this
  task as the tracked rename, so no re-measurement of authorship is needed.

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

### 2026-08-04T13:18:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-365-rename-testsfixturesaef-bpmn-the-name-as.md
- **Context:** Initial task creation

### 2026-08-08T19:24:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2f244a7d
- **Timestamp:** 2026-08-11T22:29:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-11T22:29:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
