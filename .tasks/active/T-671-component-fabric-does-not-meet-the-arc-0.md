---
id: T-671
name: "Component Fabric does not meet the Arc-0 fence for the EWCR scope"
description: >
  Roadmap section 6 makes 'Component Fabric non-empty, enriched, validated' a fence required BEFORE implementation decomposition, with evidence owner 'Arc 0 task owner'. Our fabric is 79 registered / 278 unregistered of 354 watched (22 percent) with 49 of 79 cards edgeless, and has WARNed 12 times in 14 days. AEF refused exit clause 1 on their own numbers and separately criticised our coverage; that criticism was ACCEPTED as valid in arc-0-exit-clauses.yaml. This is the only part of clause 1 this side can move.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [ewcr, fabric, arc-0-fence, arc:ewcr-governed-delivery]
components: [tools/_t671-arc0-card-gen.py, tools/_t671-arc0-edge-derive.py, tools/_t671-arc0-fabric-fence.py]
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-03T05:31:57Z
last_update: 2026-09-03T10:04:25Z
date_finished: 2026-09-03T10:04:25Z
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

# T-671: Component Fabric does not meet the Arc-0 fence for the EWCR scope

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The **Arc-0 component set is defined explicitly** — which files the fence actually
      ranges over — before any carding begins. The fence reads "sufficient topology to
      decompose code safely"; that is a scope, not the whole tree. Carding 278 files to
      move a percentage would be optimising the metric rather than clearing the fence.
      → **28 files**, manifest `arc-0-component-set.txt`, rationale `arc-0-component-set.md`.
      Derived from the §2.1 Designer row ("inventory visual/mapping schema, stable IDs,
      import/export and round-trip constraints"). 256 of the 358 watched files are
      `tools/_tNNN` one-off probes and are deliberately excluded.
- [x] Every file in that set has a component card with **real `depends_on`/`depended_by`
      edges**, not a stub. An edgeless card raises `registered` while feeding the separate
      "49/79 cards have no edges" warning — it moves one number by worsening another.
      → 28/28 carded, **0 edgeless, 0 stub purposes**. Edges are DERIVED from each file's
      own non-comment bytes (164 forward + 135 inbound), not asserted. Repo edgeless count
      went 49/80 → 46/102: 22 new cards added zero edgeless and 3 old stubs gained edges.
- [x] The fence's three words are each evidenced separately: **non-empty** (count),
      **enriched** (edge coverage over the Arc-0 set), **validated** (`fw fabric drift`
      reports no unregistered or orphaned member of that set). A single aggregate number
      cannot show which of the three is unmet, and clause 1 names all three.
      → `tools/_t671-arc0-fabric-fence.py` prints three independent verdicts. All three
      red arms driven (`--self-test`); doing so found a false green in my own gate.
- [x] The denominator is stated and defended. AEF's clause-1 refusal turned on exactly this
      — 749 of their 1134 cards point outside any watch pattern, so their drift check ranged
      over a silently shrinking population. `tools/_t623-fabric-denominator-scope-probe.py`
      already asserts ours does not have that defect; this task must not introduce it.
      → Re-run after the work: **3 PASS**, outside-ratio **2.9%** (3 cards, all documented
      fixtures) against AEF's 66%. All 28 members are inside the watch set, so an absent
      card for any of them is REPORTED, never silently out of scope.
- [x] The audit's fabric WARNs are re-read **after** the work and the residual reported.
      If the whole-tree WARN persists because the Arc-0 set is a subset, that is stated
      plainly as a scoped pass, never as a cleared warning.
      → Residual, unchanged in kind: `102 registered, 259 unregistered (28% covered)` and
      `46/102 cards have no edges`. Both **persist by design**. This is a scoped pass over
      28 files; the 22%→28% whole-tree movement is a side effect and is explicitly not
      claimed as the deliverable (`arc-0-component-set.md` §5).

### Human
- [ ] [REVIEW] The Arc-0 component set is the right scope
  **Steps:**
  1. `cd /opt/832-Workflow-designer && cat docs/research/executable-workflow/arc-0-component-set.md`
  2. Compare against roadmap §4 Arc 0 "Candidate tasks" and the Designer column of §2.1
  **Expected:** the set covers the mapping/inventory, stable-ID and import/export-round-trip
  surfaces this side owns, and excludes runtime schemas (AEF-owned)
  **If not:** name the file that is wrongly in or out and why

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
         1. Run `bin/fw reviewer T-671`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-671 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# The fence itself: three words, three independent verdicts, one exit code.
python3 tools/_t671-arc0-fabric-fence.py

# The fence still has TEETH, not just a green light (PL-308). Drives all three red
# arms against a throwaway fixture and exits 0 only if every one of them REFUSES.
# Without this leg the leg above is a hand-maintained claim.
python3 tools/_t671-arc0-fabric-fence.py --self-test

# The denominator is honest: cards outside the watch set stay inside the trust fence.
# This is the defect that sank AEF's own clause-1 numbers; asserting we did not
# introduce it is part of the deliverable, not a courtesy.
python3 tools/_t623-fabric-denominator-scope-probe.py

# The cards match what the tools produce. Regenerating from the derived edges must
# leave the tree byte-identical — if someone hand-edits a generated card, this goes
# red instead of the edit being silently destroyed on the next regeneration.
python3 tools/_t671-arc0-edge-derive.py > /tmp/.t671-verify.tsv 2>/dev/null && python3 tools/_t671-arc0-card-gen.py /tmp/.t671-verify.tsv >/dev/null 2>&1 && git diff --quiet .fabric/components/

# The prose scope document and the machine-readable manifest agree. Two files naming
# the same population WILL drift; this is the leg that notices.
python3 -c "import sys; t=[l.strip() for l in open('docs/research/executable-workflow/arc-0-component-set.txt') if l.strip() and not l.startswith('#')]; m=open('docs/research/executable-workflow/arc-0-component-set.md').read(); missing=[p for p in t if p not in m]; sys.exit(1 if missing else 0)"

# Every Arc-0 member is inside the watch set. Asserted POSITIVELY: a member that fell
# out of scope would make its missing card invisible rather than reported, which is
# the failure this fence exists to prevent.
python3 -c "import subprocess,sys,os; w=set(subprocess.run([sys.executable,'.agentic-framework/agents/fabric/lib/expand_patterns.py','.fabric/watch-patterns.yaml','.'],capture_output=True,text=True,check=True).stdout.split()); t=[l.strip() for l in open('docs/research/executable-workflow/arc-0-component-set.txt') if l.strip() and not l.startswith('#')]; sys.exit(0 if all(p in w for p in t) else 1)"

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

### 2026-09-03 — "registered" was counting stubs, and the product was not carded at all

- **What changed:** The task was filed against the coverage ratio (79/278). The ratio
  was the wrong quantity. Of the 6 Arc-0 members that already had cards, **all 6 were
  stubs** carrying `purpose: "TODO: describe what this component does"`, and 3 had no
  edges at all — so the honest count of *complete* Arc-0 cards was **0 of 28**, not 6.
  Separately, `src/aef-workflow-designer.html` — the ~10k-line product this arc exists
  for, with 112 inbound references — **had no card at all.** The file the fence most
  needed to describe was the one it was silent about.
- **Plan impact:** "Raise coverage" was never the deliverable and would have been
  actively harmful: registering 278 stubs raises `registered` while every one lands in
  the *separate* "cards have no edges" warning. The work became scope definition +
  derived topology + a three-word fence, with the whole-tree ratio explicitly disowned
  as a side effect.
- **Triggered:** No new task. The scope decision is recorded in
  `docs/research/executable-workflow/arc-0-component-set.md` §1 rather than deferred.

### 2026-09-03 — mention is not invocation, and the fix hid one language over

- **What changed:** First derivation produced 173 forward edges. Inspecting the outliers
  showed `tests/run-bridge-tests.sh` contributing 127, most of them comment references
  to sibling probes, and `src/aef-workflow-designer.html` "depending on" its own
  generator and its own test — **one of those backwards in direction**. This is the
  T-669 finding (`SEARCH_SOURCED` matching `grep` inside a quoted payload) reappearing
  in a different instrument. Stripping `#` comments fixed `.py`/`.sh` and was **silently
  inert on `.html`/`.mjs`**, so the false edges survived exactly where the fix could not
  reach. ~70 candidate edges were comment mentions.
- **Plan impact:** Edge derivation had to become language-aware rather than lexical. It
  also had to stop refusing *all* basenames: the stated objection was ambiguity, and
  `_bpmn-claim-cli-verify.py` invokes `os.path.join(HERE, 'bpmn-cli.py')` — a real edge a
  full-path-only scan misses entirely. Refusing only basenames that more than one tracked
  path ends in keeps the guarantee and recovers the edge.
- **Triggered:** No new task — both corrections landed inside this one. Worth carrying
  forward as a class: *a comment-stripping guard is only as wide as the languages it
  knows about, and it fails silently on the rest.*

### 2026-09-03 — driving the red arm found a false green in my own gate

- **What changed:** The fence reported three PASSes on the real set. Driving its red arms
  against a throwaway fixture (PL-308) showed that with **no card present at all**,
  `ENRICHED` still reported **PASS** — it ranged over the cards that existed, and an
  empty population trivially satisfies "all of them are enriched". A missing card cannot
  be enriched; the check was covering for the one next to it.
- **Plan impact:** ENRICHED now counts absent cards as its own failures, so the two
  checks fail together instead of one masking the other. The red-arm drive became a
  permanent `--self-test` and a Verification leg, so the green above it is not a
  hand-maintained claim.
- **Triggered:** No new task. Records the general form: *a check that iterates over what
  it found, rather than over what it was asked about, passes vacuously when the thing is
  missing entirely.*

## Recommendation

**Recommendation:** GO

**Rationale:** All five Agent ACs are met and every one of the six Verification legs is
green, including the two that could only pass after commit. The single open item is a
`[REVIEW]` Human AC asking whether the **scope** is right — which is genuinely a taste
judgment about ownership boundaries, not something I can settle by measurement. The
fence itself is mechanically evidenced; what needs your eye is whether 28 files is the
correct reading of the §2.1 Designer row.

The one thing I want to flag rather than bury: **this fence is an input to Arc-0 exit
clause 1, not the clause.** All three clauses remain `definition_ratified: false` in
`arc-0-exit-clauses.yaml`, and that ratification is yours and AEF's, not mine. A green
fence here does not move a clause, and I have not recorded anything as if it did.

**Evidence:**
- `python3 tools/_t671-arc0-fabric-fence.py` → PASS/PASS/PASS over 28 members
  (NON-EMPTY 28/28, ENRICHED 28/28, VALIDATED 28/28, 0 dangling targets)
- `python3 tools/_t671-arc0-fabric-fence.py --self-test` → all three red arms refuse
  independently; this is what caught a false green in the fence itself (a missing card
  was reporting ENRICHED PASS because an empty population satisfies "all are enriched")
- `python3 tools/_t623-fabric-denominator-scope-probe.py` → 3 PASS, outside-ratio 2.9%
  vs AEF's 66%; the denominator defect that sank their clause-1 numbers is not ours
- Baseline measured, not assumed: **0 of 28 Arc-0 members had a complete card**. All 6
  pre-existing cards were `TODO` stubs; 3 were edgeless; `src/aef-workflow-designer.html`
  (112 inbound references) had **no card at all**
- Idempotence leg proves the cards match what the tools generate — it went red once and
  correctly caught two stale cards (commit `c17a3087`)
- Scope + rationale: `docs/research/executable-workflow/arc-0-component-set.md`;
  manifest: `arc-0-component-set.txt`
- Residual, deliberately not claimed as cleared: repo-wide `102 registered, 259
  unregistered (28% covered)` and `46/102 cards have no edges` both persist

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-03 — the fence ranges over 28 files, not 358

- **Chose:** Scope the Arc-0 fence to the 28 files implementing or pinning the §2.1
  Designer row (mapping schema, stable IDs, import/export round-trip) plus the joint
  handoff surface (canonical IDs, diagnostic shape, worked fixture).
- **Why:** The fence's own words are "sufficient topology to decompose code **safely**",
  and the exit gate says "non-empty and validated" — neither says "every file". 256 of
  the 358 watched files are `tools/_tNNN` one-off probes that answer a single past
  question and are never called again; their topology has no bearing on decomposing
  Arc-1 code.
- **Rejected:** *Card the whole watch set.* Would move 28%→100% while adding no
  decomposition-relevant topology, and would worsen the "cards have no edges" warning it
  appeared to fix. *Leave the scope implicit.* Then the fence's denominator is whatever
  the last person assumed, which is the exact defect that sank AEF's clause-1 numbers.

### 2026-09-03 — edges are derived from source bytes, never hand-written

- **Chose:** Extract every edge with `_t671-arc0-edge-derive.py` from each referring
  file's own non-comment bytes, and write cards with a generator. Purpose overrides live
  in the generator, not in the cards.
- **Why:** A hand-written card is a hand-maintained claim — it is true when written and
  silently false forever after. A derived card can be regenerated and diffed, which is
  what the idempotence Verification leg does. Putting the one purpose override in the
  generator keeps regeneration lossless; an edit made directly to a generated card would
  be destroyed on the next run, which is how generated files drift.
- **Rejected:** *`fw fabric enrich`.* It is the right framework function for the general
  case and I called `fw fabric register` for the three instruments, but it cannot express
  the "mention is not invocation" rule that this corpus demonstrably needs — 70 of the
  first 173 edges were comment references, one of them backwards in direction.

### 2026-09-03 — reported as a SCOPED pass, with the whole-tree warning left standing

- **Chose:** State in the fence output, the scope document, and the task ACs that the
  repo-wide fabric WARNs persist and are not cleared by this work.
- **Why:** The whole-tree ratio moved 22%→28% as a side effect of carding 28 files. That
  movement is real but is not the deliverable, and citing it as one would convert a
  genuine scoped pass into a false green — the precise failure this fence exists to
  prevent.
- **Rejected:** *Claim the coverage improvement.* It is the number AEF criticised, and
  answering their criticism with a side effect rather than with topology would be
  arguing with the metric instead of fixing the thing.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-671 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-03T05:31:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-671-component-fabric-does-not-meet-the-arc-0.md
- **Context:** Initial task creation

### 2026-09-03T05:32:46Z — status-update [task-update-agent]
- **Change:** tags: +arc:ewcr-governed-delivery

### 2026-09-03T05:32:46Z — status-update [task-update-agent]
- **Change:** horizon: now → next

### 2026-09-03T09:48:30Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5b526449
- **Timestamp:** 2026-09-03T10:04:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-03T10:04:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
