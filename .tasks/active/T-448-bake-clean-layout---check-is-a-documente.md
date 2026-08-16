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

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T09:30:37Z
last_update: '2026-08-16T12:33:29Z'
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

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The byte delta is DIAGNOSED, not assumed: the exact difference between the committed bytes and the editor's post-Clean re-emission is captured for at least one map, and the same delta shown to hold across the corpus (or the variation characterised)
- [x] The cause is attributed to a named mechanism (exporter change, normalisation, trailer, attribute order, DI) with the commit or code path that introduced it — not "the corpus is stale"
- [x] The verdict line distinguishes a LAYOUT failure from a SERIALIZATION failure, so a red gate sends the reader to the right subsystem; today all 24 read `NOT A FIXPOINT` with `moved=0`, which names the layout engine for a byte problem
- [ ] A decision is recorded on the remedy — re-bake the corpus, change the gate's contract, or defer — WITH the blast radius stated. Re-baking rewrites 24 committed corpus files whose DI content is the live subject of T-340/T-357, so if that is the remedy it is proposed to the operator, not taken under agent initiative
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

### 2026-08-12T09:30:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-448-bake-clean-layout---check-is-a-documente.md
- **Context:** Initial task creation

### 2026-08-13T11:55:03Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
