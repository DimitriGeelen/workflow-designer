---
id: T-886
name: "uuid can be dropped from the editor writer and every guard stays green — three
  workflowMeta attributes are bare"
description: >
  Filed on the T-885 census, which measured coverage by mutation rather than by reading
  test names. BARE (mutant survived, nothing went red): uuid, description, kind. COVERED
  (mutant killed): title, tier_default. NOT EXERCISABLE: pageWidth — no fixture carries
  it, so nothing was measured, which per T-3105 is not a pass. WRITE-ONLY: source
  — the writer emits it, the reader never reads it, and no map anywhere carries it.
  uuid is the serious one: T-224 connector-referenceable identity, what off-page links
  resolve against, pinned cross-agent in AEF's copies of offpage-seam.bpmn and s4-exemplar.bpmn.
  Stop emitting it and link resolution breaks on both sides of the seam with no test
  saying so. Likely cause of the coverage gap: exactly ONE of 20 round-trip fixtures
  carries a uuid, so the population that would exercise it is a single file — which
  means the instrument probably needs fixtures as much as it needs assertions. Whoever
  builds it should mutate rather than read: two of three predictions made from reading
  the harness were inverted by measurement.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [arc:process-instances]
components: []
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
created: 2026-09-26T23:46:38Z
last_update: 2026-09-27T11:35:15Z
date_finished:
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
  - ts: '2026-09-27T11:35:15Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 4
      F1: 2
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=4 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L4:keyword=round-trip);
      F1=2 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-886: uuid can be dropped from the editor writer and every guard stays green — three workflowMeta attributes are bare

## Context

The T-885 census measured, by mutation, what guards the document-level `aef:workflowMeta`
seam. Result: **BARE** (mutant survived, nothing went red) `uuid`, `description`, `kind`;
**COVERED** `title`, `tier_default`; **NOT EXERCISABLE** `pageWidth` (no fixture carries it);
**WRITE-ONLY** `source` (the writer emits it, the reader never reads it back).

The cause is structural, not an oversight: `checkDenominator()` in
`tools/_roundtrip-serialization-cdp.mjs` derives its ~36 keys from the NODE-level projection
function `aefExtensionXml`, so document-level attributes are outside its denominator **by
construction**. The round-trip projection at `_roundtrip-serialization-cdp.mjs:459` then
compares a **hand-typed list of four** — `id, tier_default, version, title` — while the
emitter (`src/aef-workflow-designer.html:10431-10450`) writes **ten**.

This task builds the instrument the census refused to build. It is sequenced **before**
T-889/T-890 and T-895 by the T-888 ruling's own words — *"the migration is sequenced behind a
guard that does not yet exist... migrating governance values into that seam before the guard
exists is the wrong order"* — and it is why T-875 is parked at `issues`.

The design mirrors the node-level guard that already works: a **derived** denominator plus a
**reasoned** exclusion map, so the seam is closed by construction rather than by whoever
remembers to add the next attribute.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The document-level denominator is **derived from the emitter**, not hand-typed: the guard reads the `wmAttrs` construction out of the editor source and enumerates every `aef:workflowMeta` attribute the editor can write. Proved by adding a throwaway attribute to the emitter and observing the guard go red **because it is unclassified**, then reverting — a hand-maintained list would have stayed green
      → `deriveWmKeys()`/`checkWmDenominator()` derive **10** attributes where the projection compared 4. Proof: injected `authority=` into the emitter (deliberately T-889's own attribute) → exit **2**, `1 emitter-written aef:workflowMeta attribute(s) in NEITHER WMSPEC nor WM_EXCLUDED: authority`, before a browser was spent. Reverted; `cmp` byte-identical.
- [x] Every derived attribute is classified **either** COMPARED (present in the round-trip projection) **or** EXCLUDED with a non-empty reason, and an exclusion whose reason is empty is itself a failure — the node-level `EXCLUDED` contract, applied to the document level
      → both directions proved, not just coded: the orphan path above, and setting `WM_EXCLUDED.source = ''` → exit **2**, `wm exclusion "source" has no reason`. Harness restored byte-identical.
- [x] The three BARE attributes from the census — `uuid`, `description`, `kind` — are COMPARED, and coverage is established **by mutation, not by reading the projection**: with each one suppressed in the writer the harness exits non-zero, recorded per attribute. This is T-885's own lesson, which inverted two of its three predictions
      → `tools/_t886-writer-mutation.py`, all mutants KILLED: `uuid` exit 1 (drift on **s4-exemplar.bpmn**, one of the two files AEF byte-pins — the census's stated worst case, now caught); `description` exit 1 (dispatch-loop.bpmn); `kind` exit 1 (t875-kind-marker.bpmn). `tier_default` carried as a **positive control** (census said COVERED, so it must still die): exit 1.
- [x] `schemaVersion` is reported explicitly whatever the result: it is written **unconditionally** and is absent from the four-key projection, making it a fourth bare candidate the census never tested. Measured by the same mutation, not assumed
      → **confirmed a fourth bare attribute.** Written unconditionally at src:10434, absent from the old 4-key projection, and untested by T-885. Now COMPARED and LIVE; `writer-delete` mutation killed at exit **2** via the dead-coverage branch.
- [x] An attribute that is COMPARED but carried by **no fixture** is reported `NOT EXERCISABLE` and is **not** counted as covered; the guard prints exercised-vs-comparable counts. `pageWidth` is the known case. Per PL-175 a name in a coverage list is a claim, not evidence
      → guard reports `8 LIVE / 0 BLIND / 1 NEVER-PRESENT / 1 EXCLUDED` over 20 fixtures and `exercised_fraction: 8/10`. `pageWidth` is NEVER-PRESENT (0 of 20 fixtures author it) and is excluded from the LIVE count rather than counted as a pass.
- [x] Fixture coverage is raised so that `uuid`, `description` and `kind` are each carried by at least one round-trip fixture (`uuid` was carried by exactly 1 of 20), so each comparison is evidence rather than a vacuous pass
      → **satisfied as measured; nothing was changed, and the AC's premise was partly wrong.** Counted across the 20 fixtures: `uuid` 1, `kind` 1, `description` 3 — each already ≥1, so each mutation above is real evidence. The census's "the instrument needs fixtures as much as assertions" is true **only of `pageWidth`** (0 fixtures), which is why that one is NEVER-PRESENT. Fixtures deliberately left untouched: `test_corpus_fixture_pins.py` pins them and two are byte-pinned by AEF, so editing one to chase a count is the wrong trade. See Evolution.
- [x] `source` is EXCLUDED carrying the write-only reason, and the product question — stop emitting it, or read it back — is **filed as its own task and not decided here**
      → `WM_EXCLUDED.source` carries the full reason; **T-898** filed (inception, DEFER, revisit trigger = the first map that actually sets `source=`). Not decided here.
- [x] The source tree is left byte-identical to its pre-mutation state: every mutation reverted and the revert **verified with `cmp`**, not assumed
      → `filecmp.cmp(shallow=False)` after **every** mutation inside the script plus a final check, `cmp` after the two hand mutations, and `git diff --name-only src/` reports **0 files**.
- [x] The harness passes on the unmutated tree **both before and after** the change, so no fixture regressed and the new assertions are satisfied by the real corpus
      → before: exit 0, `36 keys / 36 LIVE / 0 BLIND`, `proven_fraction 36/36`. After: exit 0, node level unchanged at 36/36 **plus** the document level at 8 LIVE / 0 BLIND. Suite wrapper `tests/test_roundtrip_serialization.py` exit 0.

<!-- No ### Human section: this task changes a test harness and its fixtures only. There is
     no UI surface and no subjective-quality question, so every criterion above is
     agent-verifiable by mutation. Per CLAUDE.md the section is removed rather than left
     empty — an unchecked Human AC nobody can act on is what strands a task in
     partial-complete (G-027, G-075).

     Template guidance retained below for the next reader, commented out.

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

# The guard itself, on the real corpus, ONCE — and the document-level leg is present in its
# verdict. Exit 0 = every fixture is a semantic fixed point; exit 2 = a self-test found the guard
# vacuous, which is the failure this task exists to make reachable at the document level.
# Lines below read this capture rather than paying for another 20-fixture browser run each.
node tools/_roundtrip-serialization-cdp.mjs > /tmp/.t886-rt.out 2>&1 && grep -q '"wm_selftest"' /tmp/.t886-rt.out
# Every attribute the emitter writes is classified. The PROPERTY, not a count, so the line
# survives T-889 adding the next attribute — it goes red until that attribute is classified.
grep -qE "wm-denominator: 0 unclassified" /tmp/.t886-rt.out
# The three census-BARE attributes are LIVE in the guard's OWN self-report — read out of the
# instrument's verdict, not out of a source grep and not out of this task file. A source grep
# would pass on a comment mentioning the word (PL-175: a name is a claim, a value is evidence).
python3 -c "import json,sys; d=json.load(open('/tmp/.t886-rt.out')); live=set(d['wm_selftest']['live']); missing=sorted({'uuid','description','kind'}-live); sys.exit('census-BARE attribute(s) not LIVE: %s' % missing if missing else 0)"
# pageWidth is reported NEVER-PRESENT rather than silently counted as covered — NOT EVALUATED is
# not PASSED. This asserts the honest-reporting property, not that the state persists forever:
# if a fixture later carries pageWidth it moves to LIVE and the assertion below is what changes.
python3 -c "import json,sys; d=json.load(open('/tmp/.t886-rt.out')); w=d['wm_selftest']; sys.exit(0 if (set(w['live'])|set(w['never_present'])|{e['key'] for e in w['excluded']}) >= set(w['wm_denominator']['derived']) else 'an emitter-written attribute is in no reported bucket')"
# The suite wrapper, so the new assertions ride the normal Python test path rather than only a
# hand-run harness (G-035: a block nothing can run is not a standing guard).
python3 tests/test_roundtrip_serialization.py > /tmp/.t886-suite.out 2>&1 && grep -q "OK:" /tmp/.t886-suite.out
# THE TEETH. Suppress each attribute in the writer and require the guard to go red; a coverage
# claim nothing has ever falsified is the defect this task repairs, one level up. Also asserts
# every mutation APPLIED and that the source tree is restored byte-identically.
python3 tools/_t886-writer-mutation.py > /tmp/.t886-mut.out 2>&1 && grep -q "every mutant killed" /tmp/.t886-mut.out

## RCA

**Symptom:** `uuid`, `description` and `kind` could each be removed from the editor's
`aef:workflowMeta` writer and every guard in the repository stayed green (T-885, by mutation).
For `uuid` that is a seam-integrity defect, not a cosmetic one: it is T-224
connector-referenceable identity, what off-page links resolve against, and AEF holds byte-pinned
copies of `offpage-seam.bpmn` and `s4-exemplar.bpmn`.

**Root cause:** two hand-typed lists, neither checked against the emitter. The round-trip
projection compared a four-key object literal (`id, tier_default, version, title`) while the
emitter writes ten attributes. The completeness check that would have caught this —
`checkDenominator()` — derives its keys from *inside* `aefExtensionXml()`, the **node-level**
projection function, so document-level attributes were outside its denominator **by
construction**: not omitted, structurally unreachable.

**Why structurally allowed:** the node level had already learned this lesson and the document
level did not inherit it. T-490 replaced the node-level hand-typed list with a derived
denominator precisely because "a hand-typed list can only ever be checked by the person who typed
it re-reading the same source, which is the one check guaranteed to reproduce the original
omission". That reasoning was never applied one scope up, and nothing noticed the asymmetry —
because the instrument that would notice was the same instrument that was scoped too narrowly.
The node-level guard reported an honest, complete-looking `36/36` the whole time, and that number
is what a reader quotes.

**Prevention** (distinct from the fix): `checkWmDenominator()` derives the document-level
attribute set **from the emitter** and fails when an attribute is in neither `WMSPEC` nor
`WM_EXCLUDED`. So the fix is not "three attributes added to a list" — the next attribute cannot
enter the writer unclassified. Proved against the real next case: injecting `authority=`, the
attribute T-889 is about to add, turns the guard red naming it. Plus
`tools/_t886-writer-mutation.py`, which keeps the coverage claim falsifiable rather than asserted.

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

### 2026-09-27 — the fixture premise was half wrong, and the denominator was the real prize

- **What changed:** the task was filed on the census's reading that the instrument "needs
  fixtures as much as it needs assertions", from `uuid` being carried by 1 of 20 fixtures. On
  measurement that is true of **`pageWidth` only** (0 of 20). `uuid` 1, `kind` 1, `description` 3
  — thin, but ≥1 each, so every mutation is real evidence and no fixture work was needed. The
  actual defect was entirely on the assertion side: a four-key literal against a ten-attribute
  emitter.
- **Plan impact:** AC 6 was satisfied by measurement rather than by action, and is annotated to
  say so rather than quietly ticked. Fixtures left untouched on purpose —
  `test_corpus_fixture_pins.py` pins them and two are byte-pinned by AEF, so editing one to move
  a coverage count would trade a real pin for a cosmetic number.
- **Triggered:** T-898 (`source=` write-only, DEFER). `pageWidth` left NEVER-PRESENT and
  reported, not papered over.

### 2026-09-27 — a fourth bare attribute the census never tested

- **What changed:** `schemaVersion` is written **unconditionally** and was absent from the old
  four-key projection, so it was bare too. T-885 enumerated six attributes and did not include
  it, so it was neither BARE nor COVERED — it was unexamined, which reads like neither.
- **Plan impact:** none structurally — it is exactly the case the derived denominator exists to
  stop being possible. It is worth recording that the census, itself built to find what was
  outside a denominator, had its own.
- **Triggered:** nothing new; it is covered by the same WMSPEC.

### 2026-09-27 — sequencing, confirmed from the ruling's own words

- **What changed:** nothing in the plan; the ordering claim was checked rather than inherited.
  The T-888 ruling states the 67-value migration "is sequenced behind a guard that does not yet
  exist… migrating governance values into that seam before the guard exists is the wrong order",
  and T-875 sits at `issues` for the same reason. Both are the same missing instrument.
- **Plan impact:** this task is the unblock for **T-875** (arc-005 S1, goal G2) and for
  **T-889/T-890/T-895** (arc-001, the authority migration). The `authority=` injection proof is
  not a contrived example — it is literally T-889's attribute meeting this guard.
- **Triggered:** no new tasks; the sequencing is recorded so the next session does not re-derive it.

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

### 2026-09-26T23:46:38Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-886-uuid-can-be-dropped-from-the-editor-writ.md
- **Context:** Initial task creation

### 2026-09-27T11:35:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
