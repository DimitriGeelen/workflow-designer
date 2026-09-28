---
id: T-905
name: "The round-trip guard's COMPUTED_SOURCES declares key:'metaKeys' but 'key' iterates
  structList/structDict — the declaration names a source it does not iterate"
description: >
  COMPUTED_SOURCES in tools/_roundtrip-serialization-cdp.mjs (:237-241) exists so
  that a computed access aef[<var>] must NAME THE LIST IT ITERATES - the guard's own
  comment says 'so a new computed access cannot enter the emitter unnoticed by reading
  as a variable'. It declares three entries: k->metaKeys, key->metaKeys, bindField->EVENT_BINDING_FIELD.
  Measured under T-904: inside aefExtensionXml, 'key' does NOT iterate metaKeys. It
  iterates the STRUCTURED literals - structList (src:10177, 'const structList = {
  emits: [...], compensates: [...] }'), and the structDict/itemlist loops at src:10180/10200
  use the same variable name. metaKeys is iterated by 'k'. So key->metaKeys is a MISDECLARATION:
  the mechanism that is supposed to pin a computed access to its source names the
  wrong source, and the guard cannot notice, because it only checks that a declaration
  EXISTS for each computed variable - never that the named source is the one actually
  iterated. Consequence: the structured-key literals (structList/structDict/itemlist)
  are read by NO derivation at all. Every structured key is in EXCLUDED (STRUCTURED,
  T-483) so the verdict is unaffected TODAY - but an exclusion is supposed to be a
  decision, and these keys are reaching it by accident rather than by classification.
  Corroborating datum from T-904's measurement: 'emits' entered the derived dot-set
  ONLY via a comment (i.e. via the very defect T-904 fixed); after stripping comments
  'emits' appears in NO part of the derivation. Fix direction: have COMPUTED_SOURCES
  name the real source AND verify the named source literal exists in the emitter and
  contains the key, so a misdeclaration cannot survive. Filed separately from T-904
  per one bug = one task: T-904's deliverable is comment-stripping, this is a distinct
  defect in a different mechanism of the same guard.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface, false-green]
components: [src/aef-workflow-designer.html, tools/_roundtrip-serialization-cdp.mjs, tools/_t904-denominator-comment-blindness-teeth.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T14:34:45Z
last_update: 2026-09-28T23:32:17Z
date_finished: 2026-09-28T23:32:17Z
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
bvp_scores_proposed: []
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 0
  F3: 4
  F1: 2
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-28T23:28:43Z'
cost_estimate_proposed:
  - ts: '2026-09-28T23:31:47Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 3
      tier: 2
      effort: 8
    rationale: blast_radius=3 (2-components); tier=2 (workflow:build); effort=8 
      (lines=293,acs=8)
    rubric_sha: e4a00f38e801
---

# T-905: The round-trip guard's COMPUTED_SOURCES declares key:'metaKeys' but 'key' iterates structList/structDict — the declaration names a source it does not iterate

## Context

Filed from T-904. The frontmatter description covers `key`; measurement under T-904 then showed
**all three** COMPUTED_SOURCES declarations misdescribe what their variable iterates, so the
deliverable is the mechanism, not one entry. Line numbers are absolute in
`src/aef-workflow-designer.html`; `aefExtensionXml` spans 10024–10214.

| declared | `COMPUTED_SOURCES` says | what `aef[<var>]` actually ranges over |
|---|---|---|
| `k` | `metaKeys` | **three** distinct ranges: `Object.keys(aef)` at :10027 (the node's entire bag), `aefKeys`-derived `carriedKeys` at :10105, and `[...metaKeys.filter(...), ...carriedKeys]` in the `metaAttrs` `.map` at :10109-10110. The declaration names only the first half of the third one. |
| `key` | `metaKeys` | **never** metaKeys. `for (const key in structList)` :10179, `for (const key of ['aggregation','multiInstance','timer'])` :10187 — an inline array literal that is no named source at all — and `for (const key in structItemList)` :10199. |
| `bindField` | `EVENT_BINDING_FIELD` | correct (:10142). |

Two consequences worth separating:

1. **The omission of `carriedKeys` is the load-bearing one.** T-570 carriage re-emits *any*
   `<aef:meta>` attribute present on the node, so `aef[k]` in the `metaAttrs` map ranges over keys
   that appear in **no literal in the source at all** — they come from the document. A denominator
   whose stated job is "derive the projected set FROM the emitter" cannot see them, and the
   declaration asserts a narrower range than the code has.
2. **`structList` / `structItemList` are read by no derivation.** Every structured key is in
   `EXCLUDED` (STRUCTURED, T-483), so the verdict is unaffected *today* — but the guard's own
   comment says an exclusion must cost a sentence so it "stays a decision instead of decaying into
   an absence". These keys reach exclusion by accident, not classification.

The reason the guard cannot notice any of this: `checkDenominator()` only verifies that a
declaration **exists** for each computed variable (`if (!COMPUTED_SOURCES[v])`), never that the
named source is the one iterated, nor that the named source literal exists. A misdeclaration is
therefore indistinguishable from a correct one.

Corroborating datum from T-904: `emits` entered the derived `dot` set **only via a comment** —
i.e. only via the defect T-904 fixed. With comments stripped, `emits` appears in no part of the
derivation, which is how this hole surfaced.

**Do not close by rewording the declarations.** The fix has to make a misdeclaration fail: verify
the named source literal exists in the emitter and that the iterated keys come from it.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **A misdeclaration fails.** `checkDenominator()` derives, from the comment-stripped body of `aefExtensionXml`, the actual binding source(s) of every computed variable `aef[<var>]` (`for (const v of|in EXPR)`, `EXPR.filter(v =>`, `EXPR.map(v =>`, `const v = EXPR`) and compares them to the declaration in `COMPUTED_SOURCES`. A declared source the variable is not bound from, or a binding source the declaration omits, is a `problems` entry naming the variable, the declared source and the actual one — no longer indistinguishable from a correct declaration
- [x] **A declared source must exist.** Each declared source string is found verbatim in the stripped body (or, for module-scope literals such as `EVENT_BINDING_FIELD`, in the file); a declaration naming a literal that is not there fails on its own, before the binding comparison
- [x] **The three live declarations are corrected to what the code iterates**, per the table in Context: `k` ranges over the node's own key bag (`Object.keys(aef)` / `aefKeys` / `carriedKeys`) as well as `metaKeys`; `key` over `structList`, `structItemList` and an inline array literal, never `metaKeys`; `bindField` from `EVENT_BINDING_FIELD`. Open-set sources (the document bag) are declared as such and reported in the output as open, so the denominator states what it cannot enumerate instead of implying it did
- [x] **Keys reachable only through `key` are classified by derivation, not by accident:** the object-literal keys of `structList` / `structItemList` and the elements of the inline array become part of the derived projection, so each must be in `KEYSPEC` or carry a reasoned `EXCLUDED` entry — the guard's own rule that "an exclusion must cost a sentence" now applies to them
- [x] **Proved by mutation with controls first**, in `--denominators-only` mode (no browser), each mutant applied to a temp copy of the GUARD and never to `src/`: (a) misdeclare `key` back to `'metaKeys'` → red naming `key`; (b) omit one binding source from `k`'s declaration → red naming `k` and the omitted source; (c) declare a source literal that does not exist → red before any binding comparison. Each mutant is asserted applied before it is scored, and a broken control set reports `MUTATION SETUP BROKEN`
- [x] The full guard's static section still passes on the unmutated tree (`--denominators-only` exit 0), and the summary line carries the computed-source verdict alongside the three denominators

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

# Teeth: controls first, then three guard-copy mutants (misdeclare key; omit a k source; declare a nonexistent literal).
out=$(bash tools/_t905-computed-sources-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
# The static section is green on the unmutated tree and the summary carries the computed-source verdict.
node tools/_roundtrip-serialization-cdp.mjs --denominators-only | grep -q 'computed sources 3 verified'
# The mechanism is wired into checkDenominator (property, not prose).
grep -q 'const cs = checkComputedSources(body, srcAllForCs, computed);' tools/_roundtrip-serialization-cdp.mjs
# The table now declares `key` as a LIST of kinded sources (positive fact, no negation): the old scalar form cannot coexist with it.
grep -qE "^  key: \[" tools/_roundtrip-serialization-cdp.mjs
node --check tools/_roundtrip-serialization-cdp.mjs
# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** `COMPUTED_SOURCES` declared `key: 'metaKeys'` while `key` iterated `structList`, an inline array and `structItemList`; `k: 'metaKeys'` while `k` ranged over the node's whole key bag. The guard was green.
**Root cause:** `checkDenominator()` verified only that a declaration existed for each computed variable, never that the named source was the one iterated or that it existed at all.
**Why structurally allowed:** The declaration was prose in code form — a string nothing compared against the program. The structured literals were reached by no derivation, so their keys sat in `EXCLUDED` by accident and the guard's "an exclusion must cost a sentence" rule never applied to them.
**Prevention:** `deriveBindingSources()` reads every binding site of the variable from the stripped body and the declaration must match it both ways; every declared source must exist where its kind says; object/inline sources contribute their keys to the projection so they are classified by derivation; the bag is reported as an open set rather than implied enumerated. Pinned by three mutants in `tools/_t905-computed-sources-teeth.sh`.

## Evolution

### 2026-09-29 — the declaration became a claim the code can refute
- **What changed:** The table's VALUES changed shape from a name to a list of kinded sources, because the three variables draw from four different kinds of thing and only two of those contribute enumerable keys. The bag (`Object.keys(aef)` / `aefKeys` / `carriedKeys`) is the load-bearing case from Context: it cannot be derived from the emitter, and pretending otherwise is the false green in a new coat. It is reported as `openSources` — "k <- carriedKeys" — so the summary now says what the denominator cannot see.
- **Plan impact:** `derivedTotal` stayed 37 exactly as Context predicted: every key the structured literals contribute was already in `EXCLUDED`, so the verdict did not move; what moved is that those keys now reach exclusion by derivation. Two parser corrections during build, both caught by the guard going red on the unmutated tree rather than by me: a chained `.map(k =>` beginning on the next line, and a spread element's `...` being read as part of the identifier.
- **Triggered:** Nothing filed. One mutant's teeth grep initially failed on JSON-escaped quotes while the guard itself had gone red correctly — the harness, not the subject.

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-27T14:34:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-905-the-round-trip-guards-computedsources-de.md
- **Context:** Initial task creation

### 2026-09-28T23:26:56Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-338ac6dc
- **Timestamp:** 2026-09-28T23:32:26Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 4
     - evidence: `node tools/_roundtrip-serialization-cdp.mjs --denominators-only | grep -q 'computed sources 3 verified'`

### 2026-09-28T23:32:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
