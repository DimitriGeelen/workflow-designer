---
id: T-344
name: "fabric watch-patterns.yaml is the untailored fw context init default and expands
  to zero files"
description: >
  The generated default watches src/**/*.py, lib/**/*.py, web/, agents/, bin/, crates/
  — none of which describe this repo (web, agents, bin, crates absent; src holds only
  .html; lib empty). Expansion yields 0 files, so the audit's coverage checks scan
  nothing. Widening to tools/tests/src patterns makes the audit immediately report
  49 unregistered source files. Real tracked source population is 115, of which 15
  are carded.

status: started-work
workflow_type: build
owner: human
horizon: later
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T11:15:56Z
last_update: 2026-08-23T10:24:10Z
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
  - ts: '2026-08-16T12:33:27Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:01Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 3
      F2: 1
      F4: 1
      F3: 4
      F1: 2
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=1 
      (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=2 (prose:process-editor-capability)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/audit/audit.sh,.agentic-framework/agents/fabric/lib/expand_patterns.py,.fabric/watch-patterns.yaml,src/aef-workflow-designer.html);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-344: fabric watch-patterns.yaml is the untailored fw context init default and expands to zero files

## Context

Found by T-342. `.fabric/watch-patterns.yaml` is the file that defines *which source files
the fabric coverage checks range over*. Ours is the generic default, unchanged since it was
stamped out — its own header says so:

```
# Generated automatically by fw context init
# Edit to match your project's source layout
patterns:
  - glob: "src/**/*.py"      - glob: "web/**/*.py"     - glob: "bin/*"
  - glob: "src/**/*.rs"      - glob: "agents/**/*.sh"  - glob: "**/*.ts"
  - glob: "crates/*/src/**/*.rs"  - glob: "agents/**/*.py"  - glob: "**/*.go"
  - glob: "lib/**/*.py"      - glob: "lib/**/*.sh"
```

Against this repo: `web/`, `agents/`, `bin/`, `crates/` **do not exist** (our agents live
in `.agentic-framework/agents/`); `src/` contains exactly one file and it is `.html`, not
`.py`/`.rs`; `lib/` is empty. Nothing here is written in Go or TypeScript. The two
directories holding essentially all our source — `tools/` (53 files) and `tests/` (47) —
are not watched at all, nor is `src/aef-workflow-designer.html`, the ~10k-line file this
whole arc is about.

**Expansion measured: 0 files.** So the audit's coverage checks compare an empty set
against the registry and report complete coverage:

```
[PASS] Fabric: 15 registered, 0 unregistered
[PASS] Fabric drift: All watched source files registered (15 cards)
```

The `(15 cards)` reads as "15 files were checked". Zero were. This is an unreachable
witnessing state, not a clean result — see [[unreachable-witnessing-state]].

**Proven fillable** (the zero's kind is occupancy of the pattern list, not construction):
the same expander, given `tools/**/*.py` + `src/**/*.html`, returns 17 files; and a real
audit run with `tools/**/*.py`, `tests/**/*.py`, `src/**/*.html` immediately reports

```
[WARN] Fabric drift: 49 source file(s) have no fabric card
```

Real tracked source population (`.py`/`.sh`/`.mjs`/`.js`/`.html`/`.ts`, excluding the
vendored framework): **115 files, of which 15 are carded — 13%, currently reported as 100%.**

**Why this is owner:human.** Choosing what to watch is a scope decision, not a defect fix:
it determines how large a registration debt this project formally carries. Tailoring the
patterns turns a standing green into a WARN of ~50–100 immediately. That is the honest
number, but it is the operator's call whether to take it now, and whether `dist/` and
one-shot `_*-verify.py` probes belong in the denominator at all.

**Ordering constraint:** land T-345 first or together. T-345 is a second, independent
coverage check that reports `0 unregistered` regardless of configuration; fixing the
patterns without it makes the audit print two contradictory fabric lines side by side.

## Acceptance Criteria

### Agent
- [x] `.fabric/watch-patterns.yaml` describes this repo: patterns that expand to a non-empty
      set, with the excluded categories (`dist/`, vendored, one-shot probes) named explicitly
      rather than omitted by accident.
- [x] The expansion count is recorded in this task alongside the resulting unregistered
      count, so the accepted debt is a stated number and not a surprise at the next audit.
- [x] A guard fails if the watch set ever expands to zero again — a coverage check whose
      denominator is empty must be red, not green. This is the actual prevention: without it
      the next `fw context init` regenerates the inert default and the pass returns.
- [x] The audit's new standing verdict (pass/warn/fail totals) is reported before and after.


### Human
- [ ] [REVIEW] Approve the watch scope and the registration debt it makes visible
      **Steps:**
      1. `cd /opt/832-Workflow-designer && python3 .agentic-framework/agents/fabric/lib/expand_patterns.py .fabric/watch-patterns.yaml /opt/832-Workflow-designer | wc -l`
      2. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw audit --section structure 2>&1 | grep -i fabric`
      **Expected:** the expansion is non-empty and the reported unregistered count is a
      number you are willing to carry as a standing WARN until the cards are written.
      **If not:** narrow the patterns (e.g. exclude `dist/` and `tools/_*-verify.py`) and
      re-run both commands.
      <!-- T-499 session: this ### Human block was under ## Measurements, outside the
           ## Acceptance Criteria section the /approvals queue parses. count_unchecked_human_acs
           returned 0 and the task never appeared in the review queue. Relocated, NOT ticked. -->

## Measurements

All taken at `8b60b22d` (the commit before this task's changes), except where noted.

**Expansion, before and after.** The eleven default patterns expand to **0** files — measured
per pattern, all eleven are zero, not ten-plus-one. The tailored set expands to **147**.

| | watched | carded | unregistered |
|---|---|---|---|
| default (as shipped) | 0 | 17 | 0 *(vacuous)* |
| **as landed (broad)** | **147** | **14** | **133** |
| narrow alternative (drop `_`-prefixed probes) | 61 | 8 | 53 |

Three of the 17 cards are `tests/fixtures/**` XML — outside the watch set under either scope,
and deliberately so (fixtures are data). That is why `carded` is 14, not 17.

**These numbers have already moved, and that is the point.** Writing this task's guard took the
set from 146 to 147 (`tools/_t344-watch-set-denominator.sh` is a `.sh` under `tools/`), and
T-374's probe took it to 148/134 the same afternoon. Every count here is therefore stamped with
its commit and none of them live in a gate or a config comment — a literal integer in an
assertion is the moving-global defect wearing prose (G-015). The current figure is whatever
`expand_patterns.py` prints today.

**Audit standing verdict.**

```
BEFORE   Pass: 19  Warn: 1  Fail: 0
         [PASS] Fabric: 17 registered, 0 unregistered
         [PASS] Fabric drift: All watched source files registered (17 cards)

AFTER    Pass: 17  Warn: 3  Fail: 0
         [WARN] Fabric: 17 registered, 133 unregistered (of 147 watched)
         [WARN] Fabric drift: 133 source file(s) have no fabric card
```

Two PASS lines became two WARN lines. Neither number changed because coverage got worse —
they were never measured. The pre-existing `13/17 cards have no edges` WARN is unrelated and
unchanged.

**T-345 is now demonstrated, which it was not at its own completion.** I closed T-345 stating
plainly that the totals were unchanged and that this was *not* evidence the fix worked, because
the watch set expanded to zero and both checks agreed at 0 either way. With a real population
the two builds separate: the pre-T-345 expander (no `PROJECT_ROOT` join, no `recursive=True`,
no `isfile` guard) returns **0** over this same tailored watch set, while the fixed one returns
**133** — and the sibling check independently returns **133**. Had T-344 landed first, the audit
would have printed `0 unregistered` directly above `133 source file(s) have no fabric card`.

**The pre-fix defect, reproduced rather than inferred.** Driving both original verdict branches
with the empty-denominator input emits, verbatim:

```
PASS|Fabric: 17 registered, 0 unregistered
PASS|Fabric drift: All watched source files registered (17 cards)
```

Those are the exact strings the audit had been printing since 28 Jul.

## RCA

**Symptom:** two audit checks reporting complete fabric coverage over a repo where 13% of
source files are registered.

**Root cause:** the watch-pattern file is the untailored `fw context init` default and
matches nothing in this project's layout, so the coverage denominator is empty.

**Why structurally allowed:** the generator ships a plausible-looking default and nothing
ever checks that it matches the project it was written into. An empty denominator produces
the same output as full coverage — a passing check and an absent check are
indistinguishable to every reader ([[failure-direction-bounds-population]]). The failure
direction here is green, so no moment of attention was ever created; it sat from 28 Jul.

**Prevention:** the empty-expansion guard in the ACs above. Tailoring the patterns fixes
this instance; only the guard fixes the class, since `fw context init` can regenerate the
default at any time.

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

**Recommendation:** NO-GO on approving the scope as it stands. **Tailor
`.fabric/watch-patterns.yaml` first, then approve the debt the tailored scope reports.**

**Rationale — the current 206 is not a scope anyone chose.** The file is the untailored
`fw context init` default, and against this repo most of its globs match nothing:
`web/`, `agents/`, `bin/` and `crates/` do not exist here (our agents live under
`.agentic-framework/agents/`), `src/` holds exactly one file and it is `.html` not
`.py`/`.rs`, `lib/` is empty, and nothing here is Go or TypeScript. What the file
actually selects is the residue of its two generic globs. Approving a debt figure
produced by patterns aimed at a different project's layout would ratify an accident.

**Evidence — both AC steps run today, 2026-08-12:**

    expand_patterns.py .fabric/watch-patterns.yaml   ->  206 files
    fw audit --section structure | grep -i fabric    ->  38 registered, 171 unregistered
                                                         34/38 cards have no edges

Composition of the 206, which is the part that decides the ruling:

    tools    154        <- 75% of the watch scope
    tests     48
    scripts    3
    src        1        <- the product. One file in 206.

    of the 206, one-shot instruments (*-teeth / *-probe / *-mutation-check / *-cdp):  83

**So 83 of the 171 unregistered are instruments that ran once and will never be edited
again.** The Component Fabric exists to answer *"what depends on this file, and what
breaks if I change it"* (CLAUDE.md §Component Fabric). That question is not meaningful for
a mutation-check written to prove a guard had teeth on the day it was authored. Writing
cards for them buys nothing and dilutes the 38 real ones — and note the second WARN:
34 of the existing 38 cards already have **no edges**, so the fabric's problem is depth,
not breadth. Adding 171 shallow cards makes that ratio worse, not better.

**Suggested narrowing** (yours to set — I am recommending that a line be *chosen*, not
that this exact line is the right one):

    exclude   tools/*-teeth.*  tools/*-probe.*  tools/*-mutation-check.*
    keep      src/**  tests/**  scripts/**  and standing guards under tools/

**Why this is worth your minute rather than a WARN you learn to scroll past.** These three
fabric lines are the **only** WARNs in the structure audit — Pass 19 / Warn 3 / Fail 0 —
so they are the entire standing noise floor of the gate that runs before every push. A
permanent WARN nobody intends to clear trains everyone to read "Warn: 3" as "clean", and
the next real warning arrives into that habit.

**What your ruling unblocks:** either a bounded card-writing campaign against a scope that
means something, or a documented decision to carry the debt knowingly. Both are better
than the present state, which is neither.

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

# The guard: watch set non-empty, product file in it, both audit verdict branches
# (extracted from audit.sh at runtime) reporting an empty denominator rather than
# passing over it, and the audit's two coverage checks agreeing on the count.
# Exit code only — no "N passed" literal, which would rot the moment a leg is added.
bash tools/_t344-watch-set-denominator.sh

# audit.sh must remain parseable — the first draft of the T-344 comment used
# backticks and double quotes inside a python3 -c "..." bash string and broke
# the whole audit with a syntax error at the set() line.
bash -n .agentic-framework/agents/audit/audit.sh

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

### 2026-08-08 — WARN, not FAIL, for an empty watch set

- **Chose:** the empty-denominator guard raises WARN in both audit blocks; the FAIL-capable
  assertion lives in `tools/_t344-watch-set-denominator.sh` (exit 1), which is a P-011
  verification line here.
- **Why:** measured the consequence before choosing. `git/lib/hooks.sh:~843` blocks `git push`
  on audit exit 2, and the bypass is `--no-verify`, which is Tier 0. A freshly-initialised
  project is in the empty-expansion state *by construction* — `fw context init` stamps out
  patterns for a Python/Rust layout — so FAIL would make a new project unpushable before it
  had been told the config exists. The defect being repaired is a check that could not recruit
  attention; WARN recruits it, and the WARN text names the inertness rather than printing a
  flattering zero.
- **Rejected:** FAIL gated on `cards > 0 && watched == 0` (project adopted the fabric, then
  lost its denominator). That is non-circular and strictly better than a bare FAIL, and it is
  deliberately *not* taken here: this file is vendored and goes upstream as G-008, and severity
  for another project's push gate is that operator's call, not mine. Named in the code comment
  so the choice is available rather than invisible.

### 2026-08-08 — broad watch scope (147) over durable-source-only (61)

- **Chose:** watch all authored code including the 85 one-shot `_t###-*` task probes.
  Standing debt: 133 unregistered.
- **Why:** the probes are the *dependents* of the product file. `fw fabric blast-radius` on
  `src/aef-workflow-designer.html` is meant to answer "what exercises this", and the probe set
  is that answer. The registry already agrees — 6 of the 17 existing cards are `_`-prefixed
  probes, so excluding them would put the watch set at odds with the registry it is compared
  against.
- **Rejected:** narrowing to 61 watched / 53 unregistered. Defensible — 133 is large enough to
  become wallpaper, which is how the `13/17 cards have no edges` WARN has been treated. This is
  the [REVIEW] Human AC; narrowing is a one-line edit and the number is stated above so the
  choice is made against evidence.

### 2026-08-08 — no `exclude:` key, exclusions named in comments instead

- **Chose:** express the scope entirely in include globs; name the excluded categories
  (`.agentic-framework/`, `dist/`, `vendor/`, `docs/`, `examples/`, `.editor-versions/`,
  `tests/fixtures/`) in comments.
- **Why:** `exclude:` is honored by `expand_patterns.py` (which `fw fabric drift` and
  `fw fabric scan` use) and **silently ignored by both audit.sh blocks**. Measured on one
  config: `tools/**/*.mjs` with `exclude: ["tools/_*"]` gives **1** from the expander and **50**
  from the audit's logic. Writing excludes today would hand the operator a config where the two
  surfaces disagree 50-fold — and narrowing the scope is exactly the [REVIEW] action they are
  most likely to take. Filed separately as its own bug.
- **Rejected:** writing the excludes anyway as belt-and-braces. Under a precise include set they
  would exclude nothing today, so they would be inert entries that read as protection — a
  guard that cannot discriminate is worse than a comment, because it invites trust.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-02T11:15:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-344-fabric-watch-patternsyaml-is-the-untailo.md
- **Context:** Initial task creation

### 2026-08-08T12:06:56Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-08-23T10:24:10Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: preserved at started-work (T-1589 shipping evidence)
