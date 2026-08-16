---
id: T-447
name: "bake-clean-layout reports success on an empty corpus: --check prints '0/0 maps
  are a Clean fixpoint' and exits 0 over a denominator it never asserts (title corrected
  — the original named T-101 as the caller; measured, T-101 does not invoke it and
  nothing does, see T-448)"
description: >
  bake-clean-layout reports success on an empty corpus: --check prints '0/0 maps are
  a Clean fixpoint' and exits 0 over a denominator it never asserts (title corrected
  — the original named T-101 as the caller; measured, T-101 does not invoke it and
  nothing does, see T-448)

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T09:24:23Z
last_update: '2026-08-16T13:57:23Z'
date_finished: 2026-08-12T09:33:00Z
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
  - ts: '2026-08-16T12:33:59Z'
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
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:examples/aef-processes/rendered/task-lifecycle.bpmn,examples/aef-processes/task-lifecycle.workflow.yaml,tools/_t352-p011-errexit-probe.sh,tools/_t440-drive-empty.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-447: bake-clean-layout reports success on an empty corpus: --check prints '0/0 maps are a Clean fixpoint' and exits 0 over a denominator it never asserts (title corrected — the original named T-101 as the caller; measured, T-101 does not invoke it and nothing does, see T-448)

## Context

One of the five instruments T-440 **measured** blind (not inferred): driven against a tree
whose population directories were emptied, `tools/bake-clean-layout.py` printed

    Baked Clean into 0 maps; 0 store versions minted; gallery mirror synced.

and exited **0**. Every clause in that sentence is true and the sentence is false.

This is the repair for that one instrument. T-440 deliberately filed no repairs — one bug,
one task — and registered the class as **G-034**. The other four are separate tasks.

**Why this one first, and a correction to the reason.** Its `--check` mode is shaped as a
gate: `--check: 0/0 maps are a Clean fixpoint` → `return 1 if fail else 0` → **0**. A
fixpoint assertion over an empty set is vacuously true, which is PL-081's vacuous-pass dual.

T-440 reported this instrument as load-bearing "because open arc task T-101 reads that exit
code". **Measured here, that is false.** T-101's `## Verification` block runs
`check-corpus-geometry.sh`, `run-bridge-tests.sh`, `run-validator-tests.sh`,
`test_editor_bridge_structured_parity.py` and `_corpus-adopt-verify.py` — it never invokes
`bake-clean-layout.py`. Nothing in the tree does. The association came from the tool being
built under T-101, and I inferred a caller from provenance instead of grepping for one —
the same mention-vs-instance step AEF took at rail 552 (`ls <path>` answering "is there a
file at this PATH", reported as "do I have this FIXTURE").

So the blindness is real and the urgency claim was not. What replaces it is worse in a
quieter way and is filed separately (one bug, one task): **`--check` is documented in
`tools/README` as the corpus fixpoint assertion, is invoked by nothing, and returns rc=1 /
`0/24` on the real corpus today** — proven pre-existing by running `git show HEAD:` of this
file before any edit. Un-wired and red, and each fact conceals the other: nobody saw it go
red because nothing runs it, and wiring it now would block on 24 maps.

**Why a floor of 24 would be the wrong fix.** The docstring already states the denominator —
"no map args → all 24 rendered maps" — as *prose*. Restating it as a constant makes the guard
rot the day the corpus grows to 25, and PL-158 (T-444) says a guard must DERIVE its checked
set from the authority it guards, never restate it. Measured today: 24 `*.workflow.yaml`
sources, 24 `rendered/*.bpmn`, **exact 1:1, zero orphans in either direction**. So the
authority is the source set, and the derived expectation is *every source has a rendered
counterpart* — which catches a total zero and a partial loss (3 of 24), and cannot go stale.

The relation is deliberately `sources ⊆ rendered`, not equality: a rendered map with no
YAML source is **permitted and not refused**. The docstring's own design note says the YAML
is the semantic source and `rendered/*.bpmn` the visual truth, so a hand-authored map with
no generator input is legitimate. An earlier draft of this Context claimed the guard also
catches orphans; it does not, and the claim is removed rather than the behaviour changed.

**Scoped to this instrument.** `_clean-layout-cdp.mjs` is separately blind (T-440 measured it
printing `{}` at exit 0) and gets its own task. Note the two compose only through the empty
path: with a non-empty `maps`, the driver returning `{}` is already caught here (`bad += 1`
→ SystemExit in bake mode, `fail += 1` in --check). Emptiness is what silences both at once.

## Acceptance Criteria

### Agent
- [x] The corpus expectation is DERIVED from `examples/aef-processes/*.workflow.yaml`, not
      restated as a constant — proven BEHAVIOURALLY rather than by grepping for the digits
      `24`: add a 25th source+rendered pair in a throwaway copy of the tree and the tool
      must report a scope of 25 with no edit (PL-158). A grep would also have matched the
      comments that explain why not to hard-code it, and would pass on a tool that hard-coded
      the number under a different spelling
- [x] `--check` over an empty rendered corpus exits NON-ZERO and says what it examined,
      rather than printing `0/0 maps are a Clean fixpoint` and exiting 0
- [x] The bake path over an empty rendered corpus exits NON-ZERO instead of printing
      `Baked Clean into 0 maps; ...; gallery mirror synced.` at exit 0
- [x] A PARTIAL corpus (sources present, some rendered counterparts missing) is refused too —
      the repair is not limited to the total-zero case that T-440 happened to drive
- [x] An explicitly named map that does not exist is refused by name, rather than silently
      shrinking the corpus to the names that do exist
- [x] The instrument's verdict on the REAL corpus is byte-for-byte unchanged by this repair.
      Originally written as "still exits 0 over the true 24" — that assumed a green which
      does not exist: measured, the real corpus gives rc=1 / `0/24` both before and after
      (pre-change version run from `git show HEAD:`). The invariant that matters is that the
      floor changed no verdict, not that the verdict is green
- [x] `tools/_t440-drive-empty.sh bake-clean-layout` no longer files it BLIND, and the run is
      still classed `driven` (a repair that merely made it undrivable is not a repair)

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

# 1. An EMPTY corpus refuses with rc 2 in --check mode. rc is read from the tool, never
#    through a pipeline: `cmd | tail` reports tail's status, which is how a refusal at 2
#    reads as 0 — the exact swallow this task exists to remove (AEF rail 553).
S=$(mktemp -d); mkdir -p "$S/tools" "$S/examples/aef-processes/rendered"; cp tools/bake-clean-layout.py "$S/tools/"; (cd "$S" && python3 tools/bake-clean-layout.py --check > /tmp/.t447-1.out 2>&1); test $? -eq 2
# 2. ...and says so, rather than printing the old vacuous success sentence.
grep -q "REFUSING" /tmp/.t447-1.out && grep -q "not a pass" /tmp/.t447-1.out
# 3. The BAKE path refuses too — the old 'Baked Clean into 0 maps; ...; gallery mirror synced.'
S=$(mktemp -d); mkdir -p "$S/tools" "$S/examples/aef-processes/rendered"; cp tools/bake-clean-layout.py "$S/tools/"; (cd "$S" && python3 tools/bake-clean-layout.py > /tmp/.t447-3.out 2>&1); test $? -eq 2
# 4. A PARTIAL corpus is refused, not reported on. A zero-guard alone would miss this.
S=$(mktemp -d); mkdir -p "$S/tools" "$S/examples/aef-processes/rendered"; cp tools/bake-clean-layout.py "$S/tools/"; cp examples/aef-processes/*.workflow.yaml "$S/examples/aef-processes/"; cp $(ls examples/aef-processes/rendered/*.bpmn | head -3) "$S/examples/aef-processes/rendered/"; (cd "$S" && python3 tools/bake-clean-layout.py --check > /tmp/.t447-4.out 2>&1); test $? -eq 2
# 5. ...naming the shortfall against the derived denominator, not a constant.
grep -qE "have no rendered counterpart" /tmp/.t447-4.out
# 6. A named map that does not exist is refused BY NAME rather than shrinking the corpus.
python3 tools/bake-clean-layout.py --check __no_such_map__ > /tmp/.t447-6.out 2>&1; test $? -eq 2 && grep -q "__no_such_map__" /tmp/.t447-6.out
# 7. The denominator DERIVES: add a 25th source+rendered pair to a throwaway tree and the
#    tool reports 25 with no edit. Behavioural, not a grep for the digits (a grep would
#    match the comments explaining why not to hard-code, and would miss another spelling).
S=$(mktemp -d); mkdir -p "$S/tools"; cp tools/bake-clean-layout.py "$S/tools/"; cp -r examples "$S/examples"; cp examples/aef-processes/task-lifecycle.workflow.yaml "$S/examples/aef-processes/zz-t447-growth.workflow.yaml"; cp examples/aef-processes/rendered/task-lifecycle.bpmn "$S/examples/aef-processes/rendered/zz-t447-growth.bpmn"; python3 -c "import importlib.util,sys; s=importlib.util.spec_from_file_location('b',sys.argv[1]+'/tools/bake-clean-layout.py'); m=importlib.util.module_from_spec(s); s.loader.exec_module(m); sys.exit(0 if len(m.sources())==25 else 1)" "$S"
# 8. The REAL corpus verdict is unchanged by this repair: still rc 1 with 0/24, exactly as
#    the pre-change file gives. The floor must not have inverted or masked a verdict.
python3 tools/bake-clean-layout.py --check > /tmp/.t447-8.out 2>&1; test $? -eq 1 && grep -q "0/24 maps are a Clean fixpoint" /tmp/.t447-8.out
# 9. The T-440 harness classes it driven+guarded — NOT 'BLIND 0' over a driven count of 0,
#    which is the false finish G-034's closure condition names. This failed on first run and
#    is the reason the harness's poison now also writes the *.workflow.yaml spelling.
bash tools/_t440-drive-empty.sh bake-clean-layout > /tmp/.t447-9.out 2>&1 && grep -qE "driven +1" /tmp/.t447-9.out && grep -qE "BLIND +0" /tmp/.t447-9.out && grep -qE "CANNOT-DRIVE +0" /tmp/.t447-9.out

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

**Symptom:** `tools/bake-clean-layout.py` reported success having examined nothing. On an
emptied tree the bake path printed `Baked Clean into 0 maps; 0 store versions minted;
gallery mirror synced.` and `--check` printed `0/0 maps are a Clean fixpoint`, both at
exit 0. Measured by T-440's drive harness, not inferred.

**Root cause:** `maps = names or all_maps()` sourced the corpus from a directory listing
and nothing downstream compared that list to any expectation. `len(maps) - fail` over an
empty list is 0, `0/0` formats cleanly, and `return 1 if fail else 0` returns 0 because
zero maps produced zero failures. The verdict was computed from a tally whose denominator
was never asserted — so "clean" and "empty" were literally the same code path.

**Why structurally allowed:** the tool DID know its denominator. The docstring said "no map
args → all 24 rendered maps". Prose is not a check, and there is no gate anywhere that asks
whether a documented count is enforced. More generally this is G-034: the class had four
registered instances before T-440 named it, and there was no instrument that drove any
Python or .mjs check against an empty population until T-440 built one.

**Prevention (distinct from the fix):**
1. `tools/_t440-drive-empty.sh bake-clean-layout` is Verification leg 9 and asserts
   `driven 1 / BLIND 0 / CANNOT-DRIVE 0` — three counts, not one. Asserting BLIND 0 alone
   would pass on a tool that had merely become undrivable, which is what happened on the
   first run of this repair.
2. Verification leg 7 proves the denominator DERIVES by growing a throwaway corpus to 25
   and expecting the tool to follow with no edit. A grep for `24` would have passed on a
   hard-coded count spelled differently, and would have failed on the comments explaining
   why not to hard-code — measuring the wrong thing in both directions.
3. G-034 holds the class open; this repair closes one of five and its closure condition
   explicitly refuses "fixed the five, left the 59".

**Two errors of my own, recorded because both were caught by instruments rather than care:**
- I stated T-101 reads this exit code, carried from T-440's framing. It does not, and
  nothing does. I inferred a caller from provenance (the tool was built under T-101)
  instead of grepping for one — mention-vs-instance, the same step AEF took at rail 552.
  The correction is in the Context and in the task title; the real finding is T-448.
- I first recorded the refusal as `rc=0` because I read the exit code through
  `python3 ... | tail -3`, where the status is `tail`'s. That is the identical swallow AEF
  described at rail 553 (`(exit 75) | logger → rc=0`), committed while measuring a fix for
  exit-code blindness. Every rc in the Verification block is now read directly.

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

### 2026-08-12T09:24:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-447-bake-clean-layout---check-passes-on-an-e.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d93b79c3
- **Timestamp:** 2026-08-12T09:33:12Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T09:33:00Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
