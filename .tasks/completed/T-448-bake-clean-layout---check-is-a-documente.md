---
id: T-448
name: "bake-clean-layout --check is a documented corpus gate that nothing invokes
  and that has been red on all 24 maps"
description: >
  Found while repairing T-447 (zero-population blindness in the same tool). Two facts
  that conceal each other: (1) tools/README documents 'python3 tools/bake-clean-layout.py
  --check' as the assertion that the rendered corpus is a Clean fixpoint, but NOTHING
  invokes it - not T-101's Verification block (which runs check-corpus-geometry.sh,
  run-bridge-tests.sh, run-validator-tests.sh, test_editor_bridge_structured_parity.py,
  _corpus-adopt-verify.py), not any test, hook or cron line. (2) It returns rc=1 with
  '0/24 maps are a Clean fixpoint' on the real corpus, proven pre-existing by running
  'git show HEAD:tools/bake-clean-layout.py' before any T-447 edit. Nobody saw it
  go red because nothing runs it; wiring it now would block on all 24 maps. The failure
  is NOT geometry - 22 of 24 maps report moved=0 and messinessBefore=0, and every
  one reports byte_stable=False, so the editor's current buildBpmnXml() serialization
  has drifted from the committed bytes since the T-300 bake. First step is to characterise
  that byte delta on one map (diff the driver's xml against the committed file), decide
  whether the corpus should be re-baked or the check's byte-equality contract is wrong,
  and only then decide whether --check gets wired to a gate. Do not re-bake 24 maps
  before knowing what the delta is.

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: [tools/_t448-drift-classification-teeth.py, tools/_t451-unwired-guard-census.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T09:30:37Z
last_update: 2026-08-16T22:53:50Z
date_finished: 2026-08-16T22:53:50Z
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
  - ts: '2026-08-16T12:33:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 5
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental); F4=5 
      (prose:routing-engine); F3=1 (prose:AEF seam-incidental); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tools/_roundtrip-serialization-cdp.mjs,tools/_t352-p011-errexit-probe.sh,tools/bake-clean-layout.py,tools/validate-workflow.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:45Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_roundtrip-serialization-cdp.mjs,tools/bake-clean-layout.py);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-448: bake-clean-layout --check is a documented corpus gate that nothing invokes and that has been red on all 24 maps

## Context

Both claims in the title verified by measurement 2026-08-13 (T-490 session), before any build:

- **Nothing invokes it.** `grep -rn bake-clean-layout` over every tracked `.sh`/`.py`/`.md`/`.yaml`
  outside `.context/` and `.tasks/` returns zero call sites. `tools/bake-clean-layout.py:42` states
  "T-101 reads that exit code" — T-101 is an active human-owned task, not a runner.
- **It is red on the whole corpus.** `python3 tools/bake-clean-layout.py --check` →
  `0/24 maps are a Clean fixpoint [scope: all 24 source(s)]`, exit 1. Read-only confirmed:
  `git status --short examples/` clean afterwards.

**The important detail, which the title does not say.** Every one of the 24 fails the same way:

    NOT A FIXPOINT: <map> (byte_stable=False moved=0 messinessBefore=0)

`moved=0` and `messinessBefore=0` mean the Clean layout algorithm changes nothing and the maps are
not messy — the *layout* is already a fixpoint. Only `byte_stable` is false, and that compares the
editor's post-Clean serialization against the committed bytes (`bake-clean-layout.py:232`). So this
gate is red for a **serialization** reason, not a layout-quality one, and a reader who trusts the
gate's name would go looking in the layout engine.

That distinction changes the remedy and must be established before anything is re-baked: re-baking
24 committed corpus files to satisfy a gate whose failure is a byte diff of unknown cause would
write an unexamined exporter delta into the corpus that T-340/T-357 are actively reasoning about.

**Related class (do not conflate — one bug, one task).** T-490 found the same *unwired* half in
`tools/_roundtrip-serialization-cdp.mjs`. This is the fifth recorded instance of the class
(PL-004 from T-052; PL-148 from T-426, itself citing three across two projects), and PL-148's
prescribed remedy — assert registration separately from behaviour — has never been built as a
population-wide check. That prevention belongs in its own task; this one is the instance.

## Diagnosis (measured 2026-08-13, read-only)

Ran the driver over all 24 maps and diffed the committed bytes against the editor's post-Clean
re-emission. **Zero driver errors, and exactly ONE diff shape across all 24 — uniform, no variation:**

    +                  exporter="aef-workflow-designer"
    +  <!-- BPMN DI (visual layout) omitted; node geometry travels as aef:position -->
    -  <!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates -->

Two lines per file, both attributable to named commits, neither a defect:

| delta | origin | what it was |
|---|---|---|
| `exporter="aef-workflow-designer"` | `4c40414c` (T-399) | producer identity — our exports carried none, so AEF's trailer guard inferred authorship from prose |
| DI comment rewording | `07a62951` (T-361) | correctness fix — our exported bytes named AEF as the owner of a step they have never performed |

The corpus was last baked at `bdcfbc86` (T-300), which reported `--check 24/24` green. Both emitter
changes landed afterwards. **Nothing re-ran the check, because nothing invokes it**, so the corpus
left its fixpoint silently and stayed there.

So the red is not a defect in the exporter and not a defect in the layout engine. It is a corpus
that is stale by two lines against two deliberate improvements — and the gate that exists precisely
to say so was not wired to say it. It would have fired the day T-361 landed.

**One discrepancy against this task's own filing, left open rather than smoothed over.** The
description (written 2026-08-12) records "22 of 24 maps report moved=0"; this run showed **24 of
24** at moved=0. The diff-shape census was uniform across all 24 either way, so it does not change
the diagnosis, but it means either the two maps settled between the two runs or `moved` is not
fully deterministic across driver runs. If it is the latter, that is a separate finding about the
layout driver and not about this gate — worth a probe before anyone treats `moved` as a stable
signal.

Worth noting what the stale comment asserts: *"AEF generates it from node coordinates"* — a claim
T-340 has since disproved by measurement on both sides. The committed corpus is currently carrying
a false statement about the arc's central question, which the newer emitter already corrects.

**Remedy — for the operator, not agent initiative (AC4).** A re-bake rewrites 24 committed corpus
files, +2/−1 lines each, no geometry and no DI change. It would give the corpus producer identity
and delete the false DI claim. Blast radius is bounded but the corpus is the live subject of
T-340/T-357, so the call is the operator's:

```
cd /opt/832-Workflow-designer && python3 tools/bake-clean-layout.py && python3 tools/bake-clean-layout.py --check
```

**Wiring — deliberately deferred, and recorded as such (AC5).** Wiring this gate into
`run-bridge-tests.sh` today would make the suite permanently red on a known, diagnosed, benign
staleness. PL-004's prescription is a legacy allowlist, but building an allowlist scaffold for a
state that the single command above eliminates would be scaffolding around a decision rather than
making it. So: wire it immediately AFTER the re-bake ruling — as a fixpoint gate if re-baked, or
with an allowlist carrying this exact two-line delta if the ruling is to defer.

## Re-measured 2026-08-17 — the diagnosis held, its instrument did not

Everything above was measured on 2026-08-13. Re-running it four days later contradicted one
line of it, and the contradiction turned out to be in the gate rather than in the corpus.

**1. Two maps report a non-zero `moved`, and the earlier reading of "24 of 24 at moved=0" was
wrong.** Seven consecutive `--check` runs, deterministic in every one: `audit-process` at
`moved=5` and `error-escalation-ladder` at `moved=9`, the other 22 at 0. `examples/` has no
commits since before this task was filed, so the corpus did not change under the measurement.
A `git worktree` checkout of `c6b02d7c` — the very commit whose message records "all 24 read
moved=0" — reports the same two maps moving today. Same tree, same driver (unchanged since
T-300), different answer four days apart. **The filing (2026-08-12: "22 of 24 report moved=0")
and today agree; the 2026-08-13 reading is the outlier, and it is mine.** The discrepancy this
task recorded and left open is therefore resolved against my own later measurement, not
against the filing.

**2. That mislabelled 2 of 24 maps as a LAYOUT failure — by the repair for mislabelling.**
AC3's verdict fix decided `layout_bad` from the driver's `moved` counter. The reason that is
the wrong source was already in the file, three lines above the call site, written at T-300:

> In-state metrics (moved/netMoved) are unreliable proxies — adoptImportedXml normalizes
> coordinates on import, so transient/net movement can be nonzero while the serialization is
> byte-stable (T-300: audit-process + error-escalation-ladder).

Those are the exact two maps. A comment stating a property, and the code below it using the
property the comment rejects — this week's shape, in the repair for this week's shape.

**Repaired:** `classify_drift()` now decides from the **diff**, which is the artifact the gate
is about, and still reports `moved` with what a non-zero value means. All 24 maps now read
`SERIALIZATION ONLY`, the two moving ones carrying an explicit note. Teeth:
`tools/_t448-drift-classification-teeth.py`, 7 legs, mutation-verified against three mutants
(counter-based rule → 4 legs red; no comment-stripping → 3 red; never-implicate-layout → 2
red). Leg 3 is a bug the new classifier committed on its own first run: the corpus's DI
trailer reads `node geometry travels as aef:position`, so a substring test found the marker in
PROSE and relabelled all 24 as LAYOUT+SERIALIZATION. Kept as a leg rather than quietly fixed.

**3. The re-bake blast radius was UNDERSTATED, and is now measured rather than estimated.**
The estimate in this task read "+2/−1 lines ×24, no geometry, no DI". A real
`bake-clean-layout.py` run in an isolated `git worktree` at HEAD — the live corpus never
touched, verified byte-identical throughout — produces:

| what | measured |
|---|---|
| `examples/aef-processes/rendered/*.bpmn` | **24 modified**, uniform +2/−1, no geometry |
| `.editor-versions/*/index.json` | **15 modified** (store versions minted on byte change) |
| new `.editor-versions/*/vN.bpmn` + `vN.png` | **30 new files** (15 maps × bytes + thumbnail) |
| `examples/aef-processes/*.workflow.yaml` | **0** — sources untouched |
| tracked total | **39 files, +153 −24**, plus 30 new |
| post-bake `--check` | **24/24 fixpoint, rc 0** — one bake settles it, no oscillation |

The estimate missed the store-version half entirely: 45 of the 69 touched paths are
`.editor-versions/` artifacts, including 15 binary PNG thumbnails. Even the two `moved`>0 maps
come out at exactly +2/−1 with no geometry change, which is the same evidence that condemned
the counter.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The byte delta is DIAGNOSED, not assumed: the exact difference between the committed bytes and the editor's post-Clean re-emission is captured for at least one map, and the same delta shown to hold across the corpus (or the variation characterised)
- [x] The cause is attributed to a named mechanism (exporter change, normalisation, trailer, attribute order, DI) with the commit or code path that introduced it — not "the corpus is stale"
- [x] The verdict line distinguishes a LAYOUT failure from a SERIALIZATION failure, so a red gate sends the reader to the right subsystem; today all 24 read `NOT A FIXPOINT` with `moved=0`, which names the layout engine for a byte problem
      → **Found FALSE for 2 of 24 on re-measurement and repaired, not re-ticked on the old
        evidence.** The first fix keyed on the driver's `moved` counter, which the file's own
        T-300 comment declares an unreliable proxy and names these two maps as the case. The
        verdict now comes from the diff; all 24 read `SERIALIZATION ONLY`. Teeth:
        `tools/_t448-drift-classification-teeth.py`, 7/7, three mutants caught.
- [x] A decision is recorded on the remedy — re-bake the corpus, change the gate's contract, or defer — WITH the blast radius stated. Re-baking rewrites 24 committed corpus files whose DI content is the live subject of T-340/T-357, so if that is the remedy it is proposed to the operator, not taken under agent initiative
      → Recorded in `## Decisions` below, with the blast radius **measured in an isolated
        worktree** rather than estimated: 39 tracked files (+153 −24) plus 30 new
        `.editor-versions/` artifacts, and one bake reaches a 24/24 fixpoint. The remedy is
        **proposed, not taken** — the corpus is untouched and the operator's command is in the
        decision entry.
- [x] The gate is either invoked by a runner over its full subject set, or its non-invocation is recorded as a deliberate, reasoned state — an unwired gate must not remain merely absent (PL-004, PL-148)
- [x] No bytes changed under `examples/` unless the re-bake remedy is explicitly approved; `--check` runs read-only and is verified to leave the corpus clean

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

# The verdict classifier, driven directly: 7 legs, mutation-verified against three mutants.
python3 tools/_t448-drift-classification-teeth.py
# Standing caller. The probe this task adds must not join the population it was written about.
grep -q '_t448-drift-classification-teeth.py' tests/run-bridge-tests.sh
# The verdict must not go back to reading the driver's counter. This is the specific line the
# T-300 comment three lines above the call site already argued against.
python3 -c "import sys; s=open('tools/bake-clean-layout.py').read(); sys.exit(0 if 'layout_bad = r[\"moved\"] != 0' not in s else 1)"
# The gate still runs read-only over the real corpus and leaves it untouched. rc 1 is EXPECTED
# and is the finding — the corpus is stale by two lines pending the operator's re-bake ruling
# — so the assertion is on the corpus being unwritten, not on the gate being green.
sh -c 'python3 tools/bake-clean-layout.py --check > /dev/null 2>&1; test -z "$(git status --porcelain examples/ .editor-versions/)"'

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

**Symptom:** `tools/bake-clean-layout.py --check` reports `0/24 maps are a Clean fixpoint` and
exits 1, and has done since the day T-361 landed. Nobody saw it, because nothing calls it.

**Root cause:** two independent failures that hid each other. (1) The gate has no caller — a
grep over every tracked `.sh`/`.py`/`.md`/`.yaml` returns zero call sites, and the comment
claiming "T-101 reads that exit code" names an active human-owned task, not a runner. (2) The
corpus left its fixpoint when two deliberate emitter improvements landed after the last bake
(`exporter=` producer identity, T-399/`4c40414c`; the DI comment rewording, T-361/`07a62951`),
and nothing re-ran the gate that exists to say so. Each fact made the other invisible: an
unwired gate produces no red to investigate, and a red that nobody sees produces no reason to
wire the gate.

**Why structurally allowed:** the framework has no rule that a gate must have a caller.
PL-004 named this class at T-052 and PL-148 re-named it at T-426 citing three more instances
across two projects; this is the fifth recorded case, and PL-148's prescribed remedy — assert
registration separately from behaviour, over the whole population — has still never been
built. So each instance is found by hand, one at a time, by somebody who happened to look.
The second-order cause is narrower and is mine: the verdict repair keyed on the driver's
`moved` counter while the file's own comment, three lines above the call site, declared that
counter unreliable and named the two maps it would mislabel. A property stated in prose next
to code that contradicts it is not a check, and nothing in the tree treats it as one.

**Prevention:** `tools/_t448-drift-classification-teeth.py`, wired into the bridge suite, pins
that the verdict is decided by the diff and not by the counter — 7 legs, mutation-verified
against three mutants, including the exact pre-fix rule. That closes the second-order cause
and gives this gate its first standing caller of any kind. It does NOT close the first cause:
the gate itself over the corpus stays unwired, deliberately and with the reason recorded
(wiring it today makes the suite permanently red on a benign staleness that one operator-owned
command eliminates), and the population-wide unwired-guard check PL-148 asks for remains
unbuilt and belongs in its own task.

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

### 2026-08-17 — the remedy: re-bake, PROPOSED to the operator, not taken (AC4)

- **Chose:** recommend **re-bake**, and leave the corpus untouched pending the operator's
  ruling. The measurement that supports the recommendation was taken in an isolated
  `git worktree`, so the recommendation is evidence-backed without the corpus having been
  written to even once — verified byte-identical before and after every run in this session.

- **Blast radius, measured not estimated.** A real bake produces 39 modified tracked files
  (+153 −24) and 30 new ones:
  - 24 `examples/aef-processes/rendered/*.bpmn`, each exactly +2/−1 — the `exporter=` producer
    identity from T-399 and the DI comment rewording from T-361. **No geometry, on any map,
    including the two the driver reports as `moved`>0.**
  - 15 `.editor-versions/*/index.json`, plus 15 new `vN.bpmn` and 15 new `vN.png` thumbnails.
    The T-145 adopt gate mints a store version on byte change, and 15 of the 24 maps are
    tracked. **This half was missing from the earlier estimate**, and it is the larger half by
    file count: 45 of 69 touched paths, 15 of them binary.
  - 0 `*.workflow.yaml` — the semantic sources are not touched, as the tool's design states.
  - Post-bake `--check` returns **24/24 fixpoint, rc 0**. One bake settles it; there is no
    oscillation to discover afterwards.

- **Why re-bake rather than defer.** The corpus currently ships a sentence T-340 has since
  disproved on both sides — `AEF generates it from node coordinates` — and carries no producer
  identity, which is the gap T-399 closed everywhere else. Both deltas are corrections already
  ruled on under their own tasks; declining to bake keeps the corrected emitter and the
  uncorrected corpus permanently out of step, which is the state that let this drift go
  unnoticed for the weeks nothing ran the gate. The re-bake writes no geometry, so it does not
  touch the DI content T-340/T-357 are reasoning about — which was the stated reason to be
  careful here, and the measurement now answers it rather than deferring to it.

- **Why it is still yours.** It rewrites 24 committed corpus files and mints 15 store versions
  with new thumbnails. Nothing in the "agent may choose the approach" delegation covers
  rewriting a committed corpus that another task is actively reasoning about; and the operator
  may reasonably prefer to sequence it after T-357's DI adoption so the corpus is baked once
  rather than twice.

  ```
  cd /opt/832-Workflow-designer && python3 tools/bake-clean-layout.py && python3 tools/bake-clean-layout.py --check
  ```

- **One caveat on my own recommendation, registered as OBS-272 rather than left implicit.**
  The `moved` reading changed between 2026-08-13 and today with nothing in the repository
  changing — the worktree test rules out every commit since. Either the earlier reading was
  wrong, or the metric depends on something outside the tree: `moved` comes from running the
  real editor headless in Chrome, so viewport, font metrics, DPR and browser version are all
  inputs that no commit records. **The same driver produces the bytes a re-bake would commit.**
  If its output is environment-dependent, then so is the corpus, and two operators baking on
  two machines would produce two different corpora with both gates reporting a fixpoint. That
  is not established and I am not asserting it. It is a reason to want the driver to record
  its browser version and viewport alongside its results before the bake is run, and it is the
  one thing I would check first if the ruling is GO.

- **Rejected — change the gate's contract** (accept the two-line delta as legitimate, e.g. via
  an allowlist): it makes the gate green over a corpus that is genuinely stale, and the
  allowlist entry would have to be removed the day someone bakes anyway. PL-004 prescribes an
  allowlist for legacy debt that cannot be paid; this debt is paid by one command.
- **Rejected — defer indefinitely**: costs nothing operationally today, because the gate is
  unwired and the staleness is benign. But it leaves a false statement in the shipped corpus
  about the arc's central question, and it is the state that hid the drift in the first place.
- **Rejected — bake under agent initiative**: AC4 names this out of scope in its own text, and
  the measured radius (30 new files, 15 of them binary) is larger than the estimate it would
  have been taken on.

### 2026-08-17 — the verdict classifier reads the diff, not the driver's counter

- **Chose:** decide LAYOUT vs SERIALIZATION from the lines that differ between the committed
  bytes and the re-emission, with XML comment spans stripped before matching geometry markers.
- **Why:** the counter and the diff disagree in both directions, and only one of them
  describes the artifact the gate is about. `adoptImportedXml` normalises coordinates on
  import, so Clean can move nodes in the editor's memory and leave the file untouched (T-300,
  which names the exact two maps this mislabelled); conversely a geometry change can reach the
  bytes on a map the driver reports as `moved=0`, which leg 4 pins.
- **Rejected — raise a `moved` threshold** (treat small movements as noise): picks a number
  with nothing behind it, and would still be wrong in the other direction.
- **Rejected — drop the LAYOUT/SERIALIZATION distinction** and print one sentence again: the
  distinction is correct and load-bearing; it was the SOURCE that was wrong.
- **Rejected — suppress `moved` from the output** once it stopped driving the verdict: an
  in-editor movement that leaves no trace in the bytes is a real fact about the driver, and
  leg 2 exists to stop a future repair from quietly deleting it.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-12T09:30:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-448-bake-clean-layout---check-is-a-documente.md
- **Context:** Initial task creation

### 2026-08-13T11:55:03Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f78c24ff
- **Timestamp:** 2026-08-16T22:53:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T22:53:50Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
