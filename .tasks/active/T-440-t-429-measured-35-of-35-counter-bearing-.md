---
id: T-440
name: "Zero-leg blindness beyond bash: the 60+ .mjs CDP probes and every python check
  that prints PASS on a zero count"
description: >
  Promoted from OBS-023 (T-436 triage). Original observation text:
  T-429 measured 35 of 35 counter-bearing suites in tools/ as able to exit 0 having
  run no legs. The class generalises beyond bash: any check whose verdict derives
  from a tally of FAILURES alone reports 'clean' when it means 'empty'. Unasked so
  far: the 60+ .mjs CDP probes (out of T-429 scope entirely) and every python check
  that prints PASS on a zero finding count without printing what it examined.

status: captured
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
created: 2026-08-11T22:02:17Z
last_update: 2026-08-23T10:24:11Z
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
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 4
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=4 
      (prose:routing-structural); F3=1 (prose:AEF seam-incidental); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/project/concerns.yaml,tools/_t352-p011-errexit-probe.sh,tools/_t440-drive-empty.sh,tools/_t440-zero-population-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:45Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/concerns.yaml,tools/_t440-drive-empty.sh,tools/_t440-zero-population-census.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-440: T-429 measured 35 of 35 counter-bearing suites in tools/ as able to exit 0 having run no legs. The class generalises beyond bash: any check whose verdict derives from a tally of FAILURES alone reports 'clean' when it means 'empty'. Unasked so far: the 60+ .mjs CDP probes (out of T-429 scope entirely) and every python check that prints PASS on a zero finding count without printing what it examined.

## Context

T-429 asked one question of 35 bash suites — *can this exit 0 having run no legs?* — and got
35 yeses. T-430 then built teeth for one of them. This task asks the **same question of the
languages T-429 never touched**: the `.mjs` CDP probes (the instruments that produce every
"bridge green" number I have reported to AEF) and the `.py` checks.

**Scoped to the census, not the repair.** T-429 measured and T-430 repaired; this is the
T-429 half for `.mjs`/`.py`. Repairs are separate tasks, one per instrument that needs one —
because a repair per file is a deliverable per file, and bundling them would make one task's
completion depend on N unrelated fixes.

**The measurement must not have the defect it looks for.** A census that finds zero blind
checks, and does not say over what population, is itself a PASS on an unstated denominator
(PL-084). So the census states its denominator, and abstains (rc 2) rather than passing when
it cannot classify — the T-430 rule applied to the instrument doing the counting.

## Findings (measured 2026-08-12)

    population    73 of 101 .mjs/.py files in tools/ compute their exit code from a tally
    driven        14
    BLIND          5
    guarded        9
    CANNOT-DRIVE  59

**The five that report success having examined nothing.** Each was run out of a copy of
this tree with every population directory emptied, against a poisoned control copy that
proves the drive moved something:

| Instrument | What it printed on an empty tree | rc |
|---|---|---|
| ~~`bake-clean-layout.py`~~ | `Baked Clean into 0 maps; 0 store versions minted; gallery mirror synced.` | 0 | **REPAIRED — T-447** |
| ~~`_norec-verify.py`~~ | `0 task(s) with pending Human ACs lack a Recommendation verdict` | 0 | **REPAIRED — T-450** |
| `_clean-layout-cdp.mjs` | `{}` | 0 |
| `_node-cuts-cdp.mjs` | `{}` | 0 |
| `_t125-lane-compaction-cdp.mjs` | `}` | 0 |

### Re-measured 2026-08-12, after the first repair (T-447)

    population    73        driven  14        BLIND  4        guarded  10        CANNOT-DRIVE  59
                            (was 14)         (was 5)         (was 9)            (was 59)

**The denominator did not move.** That is the whole point of re-running the full sweep
rather than the single instrument: G-034's closure condition refuses a falling BLIND count
over a *shrinking* driven count, because an instrument that becomes untestable leaves the
same trace as one that got fixed. 14 → 14 with BLIND 5 → 4 is the one shape that means a
repair actually happened.

It did not come for free. The first post-repair run of the harness reported **BLIND 0 over
driven 0** — the false finish, fired by the very first repair the gap was written to govern.
The harness's poison wrote `_t440-poison.yaml` while `bake-clean-layout.py`'s population is
`*.workflow.yaml`, so the control never landed in the population it was controlling for and
the repair emitted a signature identical to a sealed instrument. **PL-160, committed by the
file that records PL-160, one week after recording it.** Fixed under T-447 by having the
poison also write the `*.workflow.yaml` spelling, with a matching basename so a tool checking
source↔rendered correspondence sees a complete corpus of one rather than a second flavour of
emptiness.

Also corrected here: this task claimed `bake-clean-layout.py` was load-bearing because
**T-101 reads that exit code**. Measured under T-447, **nothing reads it** — T-101's
Verification block runs five other checks and never invokes it. A caller was inferred from
provenance instead of grepped for. What replaced the false urgency is filed as T-448: the
tool's `--check` is documented as the corpus fixpoint assertion, is invoked by nothing, and
returns `0/24` on the real corpus — un-wired and red, each fact concealing the other.

`bake-clean-layout.py` is the sharpest *sentence*: it says **synced** in the same sentence
as **0 maps**. ~~and T-101 … is an open arc task that reads its exit code~~ — struck, see
the correction above: nothing reads it, and I inferred that caller rather than grepping for
one. Sharpest wording, not the most load-bearing.
`_norec-verify.py` takes that title instead — it is the operator's
approvals-queue guard, built *because* a silent zero once misled the operator into
believing there was nothing to approve, and it reports its own zero the same way.
`_t125-lane-compaction-cdp.mjs` is the probe for open task T-125.

**The nine that refused** — `_t338`, `_t341`, `_t367`(+teeth), `_t308-export-byte-identity`
exit **2** on an emptied tree, not 1. They abstain rather than fail, which is the shape
T-430 argued for. That discrimination is what makes the 5 above a finding rather than a
property of the harness.

**59 could not be driven, and that is the larger number.** Their populations are not in any
directory this harness can empty — they hit a live URL, read `src/`, or derive the set from
somewhere else entirely. They are not covered by any verdict here. An instrument whose
population cannot be emptied from outside cannot be tested for this defect by anyone,
which is why they are counted in their own bucket instead of folded into "no findings".

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Population named and counted, not sampled: every `.mjs` and `.py` check under `tools/`
      is classified counter-bearing / not, and the census prints both the numerator and the
      denominator it ranged over — 73 in population, 28 NO-VERDICT, 101 of 102 examined
- [x] Blindness is **measured by execution**, not inferred from source reading — a check
      counts as blind only when it was driven to a zero-population state and observed to
      report success. All 5 were driven; static classification was abandoned mid-task
      because it is not decidable here (see Context)
- [x] The census abstains (rc 2, `ABSTAINED` line) rather than reporting 0 blind when it
      cannot classify or cannot drive a file, so "no findings" and "could not look" stay
      distinguishable — both instruments abstain, and the drive harness's PASS line names
      the CANNOT-DRIVE count so it can never be read as coverage
- [x] Every instrument found blind is recorded by name in this task, with the evidence line
      that proved it — a count alone is not actionable (table above)
- [x] The finding is escalated where it can be acted on after this task closes — registered
      as **G-034**, because the class now has four independent instances in the register
      (G-016, G-017, G-031, plus T-429's 35-of-35 bash suites) and no entry describing the
      class itself

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

# 1. The census names a non-empty population and states the denominator it drew from.
python3 tools/_t440-zero-population-census.py > /tmp/.t440-census.out 2>&1 && grep -qE "IN-POPULATION +[1-9]" /tmp/.t440-census.out
# 2. The denominator is printed, not implied — PL-084, and the reason the tally-regex bug was caught.
grep -qE "examined +[0-9]+ of [0-9]+" /tmp/.t440-census.out
# 3. The census ABSTAINS (rc 2) on a tools/ dir with no population, rather than printing PASS.
D=$(mktemp -d) && mkdir -p "$D/tools" && T440_ROOT="$D" python3 tools/_t440-zero-population-census.py > /dev/null 2>&1; test $? -eq 2
# 4. The drive harness ABSTAINS (rc 2) when its filter drives nothing — T-430 discipline.
bash tools/_t440-drive-empty.sh __no_such_instrument__ > /dev/null 2>&1; test $? -eq 2
# 5. The approvals-queue guard REFUSES a corpus it cannot read (was: reported success over it).
#    Rewritten by T-450, which repaired it. The original leg asserted the DEFECT —
#    `grep -q "^0 task(s)"` at rc 0 — and would now be red for the right reason. A leg
#    that pins a defect has to be re-pointed at the repair, not deleted, or the corpus
#    loses its record that the defect was ever real. rc is read from the process, never
#    through a pipeline (rail 553/557).
R="$PWD"; D=$(mktemp -d); (cd "$D" && python3 "$R/tools/_norec-verify.py" > /tmp/.t440-norec.out 2>&1); test $? -eq 2
grep -q "REFUSING" /tmp/.t440-norec.out
# 6. The class is registered where it survives this task's archival.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); sys.exit(0 if any(c['id']=='G-034' and c['status']=='watching' for c in d['concerns']) else 1)"

## RCA

**Symptom:** T-429 measured 35 of 35 bash suites able to exit 0 having run no legs, and
stopped at bash. The `.mjs` CDP probes — the instruments behind every "bridge green" count
reported across the AEF seam — and the `.py` checks cited in P-011 Verification blocks had
never been asked the question. Measured now: 5 of 14 drivable instruments report success on
an emptied tree, and 59 of 73 cannot be driven at all.

**Root cause:** a verdict computed from a tally of failures alone is arithmetically correct
and semantically empty. `bake-clean-layout.py` prints `Baked Clean into 0 maps; … gallery
mirror synced.` and exits 0 — every clause true, the sentence false. Nothing in the shape of
the code distinguishes "found no problems" from "looked at nothing", so nothing in the
output can either.

**Why structurally allowed:** the register held four instances of this class (G-016, G-017,
G-031, T-429) and no entry describing the class, so each new instance was findable only by
someone who happened to be looking. Worse, the property is not testable from outside for 59
of 73 instruments: they resolve their population from their own file path
(`const REPO = join(HERE, '..')`), so no caller can hand them an empty world. A sealed
instrument and a correct one are indistinguishable — the same can't-tell-empty-from-clean
failure, one level up.

**Prevention** (distinct from the fix, which is per-instrument and filed separately):
G-034 registers the class with a closure condition that runs (`_t440-drive-empty.sh`) rather
than one that is read, and that condition refuses two false finishes explicitly — BLIND 0
over a *shrinking* driven count, and fixing the five while leaving the 59 untestable. Both
of those read as progress on the summary line, which is how this class survives.

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

### 2026-08-11T22:02:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-440-t-429-measured-35-of-35-counter-bearing-.md
- **Context:** Initial task creation

### 2026-08-11T22:03:02Z — status-update [task-update-agent]
- **Change:** horizon: now → next

### 2026-08-12T06:04:32Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-08-23T10:24:11Z — status-update [task-update-agent]
- **Change:** horizon: now → later
- **Change:** status: started-work → captured (auto-sync)
