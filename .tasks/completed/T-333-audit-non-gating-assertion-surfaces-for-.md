---
id: T-333
name: "Audit non-gating assertion surfaces for unreachable pass states (AEF OBS-124
  counterpart)"
description: >
  AEF OBS-124: nothing anywhere asks 'can this check PASS at all?'. Their 19-hook
  bug survived because the check's passing state was UNREACHABLE for the config their
  own framework generates — a capability zero presenting as an occupancy zero — and
  their installer exits 0 while printing validation errors, so nothing could gate
  on it. For 832 the gating suites are protected by construction: they gate on exit
  0 and are green, so no check inside them sits in a permanent-fail state. That argument
  does NOT cover surfaces whose failure is PRINTED but not gated — the parity known-gap
  NOTEs, the geometry sweep's known-legacy bucket, and any INFO-severity rule. Those
  are the places to measure. Note the dual is already instrumented (a vacuous pass,
  where the check evaluates nothing) but the unreachable pass is not.

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
created: 2026-08-02T07:05:14Z
last_update: '2026-08-16T14:33:28Z'
date_finished: 2026-08-02T07:36:15Z
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
  - ts: '2026-08-16T12:33:51Z'
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
  - ts: '2026-08-16T14:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 4
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=4 
      (prose:routing-structural); F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:tests/check-corpus-geometry.sh,tests/run-bridge-tests.sh,tests/run-validator-tests.sh,tests/test_check_pass_reachability.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-333: Audit non-gating assertion surfaces for unreachable pass states (AEF OBS-124 counterpart)

## Context

AEF's OBS-124 (rail 380): their 19-hook validator bug survived because the
check's PASSING STATE WAS UNREACHABLE for the config their own framework
generates — `os.path.exists("bash")` is False for every wrapper hook, so the
check failed on 100% of runs, carried no information, and read as decoration.
Their installer exits 0 while printing "completed with validation errors", so
nothing could gate on it even in principle.

Two duals, and this arc has instrumented only one:

| | the check | reads as | instrumented here |
|---|---|---|---|
| **vacuous pass** | never evaluates | confirmation | yes — teeth, discrimination probes, PAIRED_SAME_ID |
| **unreachable pass** | always fails | decoration | never once asked |

Our GATING suites answer the unreachable-pass question by construction and it
is worth being exact about why: the runners exit non-zero, P-011 and the
gating runner consume that exit code, and they are green — so no assertion
inside them is in a permanent-fail state. That is not discipline, it is that
the exit code is wired.

But green proves only NO PERMANENT-FAIL. It does not prove each check is
exercised, and it says nothing about surfaces whose non-clean state is
**PRINTED rather than gated**: the counted-tolerance NOTE printers, the
INFO-severity validator rules (`exit_code()` maps INFO to 0), and the corpus
warning I declared myself in T-331. Those are the population to measure.

## Acceptance Criteria

### Agent
**AC1–AC5 were written against a premise the measurement disproved.** They
named the four printed-not-gated surfaces from rail 381 as the population.
Three of the four turned out to be protected already, and the real exposure was
somewhere I had not looked. Corrected in place, with the original wording and
the reason for the change recorded under `## Evolution` — the AC block should
describe what was established, not what I guessed before measuring.

- [x] AC1 — The population is enumerated MECHANICALLY from the OUTPUT of green
      runs, not from recall and not from a hand-written grep vocabulary. Recall
      is what produced the T-331 AC9 failure, and a hand-written signal
      vocabulary is AEF's own "not on the list" defect.
- [x] AC2 — The four rail-381 surfaces each carry a verdict from reading the
      code that consumes them, and three are PROTECTED: the counted-tolerance
      NOTEs (parity gaps, dialect carriers, emitter-fidelity, fixture pins) all
      sit behind a count assertion inside a green gating suite, and both
      INFO-severity rules are asserted in `test_t312_lane_geometry.py:213` and
      `test_t313_lane_capacity.py:219`. My rail-381 claim that these were
      unprotected was wrong, and is corrected on the rail.
- [x] AC3 — The reachability question is asked in its MECHANICAL form — per
      predicate, is there a reachable input where it does not fire, and one
      where it does — over all 52 validator rules, 90 corpus documents and 48
      fixtures, with FORM-SCOPED denominators.
- [x] AC4 — The instrument DISCRIMINATES, proven by teeth rather than argued:
      an injected unconditional rule lands in ALWAYS-FIRES (fires=47,
      silent=0). Without this leg, "0 always-fire" would be a zero of unknown
      kind — the exact capability-vs-occupancy confusion OBS-124 is about, in
      my own answer to it.
- [x] AC5 — Findings reported with WITNESSES, not counts: each never-witnessed
      rule is named with its missing carrier, and E-LOAD is named with the
      structural reason no fixture can reach it.
- [x] AC6 — Prevention, not just mitigation (G-019):
      `tests/test_check_pass_reachability.py` is in the gating runner, so the
      property is standing rather than a one-off measurement. Two genuinely
      unexercised rules FIXED (fixtures for `E-YAML-PARSE`, `E-NOT-MAPPING`);
      one witnessed by direct probe (`E-LOAD`); six declared, counted and
      answerable in both directions.
- [x] AC7 — No-regression baselines, each RUN this session and quoted from the
      run: bridge 67/0 (was 66, +1 new leg), validator 48/0 (was 46, +2 new
      fixtures), cross-form 20 pairs / 17 AGREE / 0 DISAGREE, parity OK,
      dialect 49 rules / 42 universal, geometry 24 clean / 0 known-legacy.
- [x] AC8 — Result posted to the AEF rail, including the correction to my own
      rail-381 claim. I committed to sending it whichever way it came out,
      before knowing that one of the ways would be "you were wrong about your
      own surfaces."

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

## Measurement

Population read from the OUTPUT of green runs (bridge 66/0, validator 46/0,
geometry 24 clean at the time of measurement), never from recall.

**The four rail-381 surfaces — three protected, my claim was wrong:**

| surface | verdict | why |
|---|---|---|
| counted-tolerance NOTEs (parity ×11, dialect ×2, emitter-fidelity ×2, fixture pins ×4) | PROTECTED | the NOTE explains a check; the CHECK is a count assertion inside a green gating suite |
| INFO-severity rules (`I-XML-LANE-GEOMETRY-SKIP`, `I-XML-LANE-CAPACITY-SKIP`) | PROTECTED | asserted at `test_t312_lane_geometry.py:213`, `test_t313_lane_capacity.py:219` |
| geometry known-legacy bucket | PROTECTED | 0 entries, count asserted, sweep gated |
| T-331 declared corpus warning | PROTECTED | fails clean, fails on count move, fails on a new rule |

**Then the real question, asked mechanically over all 52 rules** — for each
predicate, is there a reachable input where it does NOT fire and one where it
DOES? Form-scoped denominators; 90 corpus documents + 48 fixtures.

| bucket | count | meaning |
|---|---|---|
| ALWAYS-FIRES | **0** | no rule has an unreachable passing state (AEF's shape) |
| BOTH-BRANCHES | 45 | both branches witnessed on real inputs |
| NEVER-WITNESSED | 7 → **6** | fire branch never observed anywhere |

**Finding 1 — six of the never-witnessed are exactly six of the eleven declared
parity gaps** (`E-CONST-DUP`, `E-CONST-SHAPE`, `W-CONST-FIELD`,
`E-SCOPEOF-DANGLING`, `E-SCOPEOF-SELF`, `W-SCOPEOF-TYPE`). The parity NOTE
argues priority from carrier counts on the form that has NO rule
("aef:constituents carried by 23/96 bpmn") while the form that HAS the rule has
zero witnessed firings. The gap is between an *unwitnessed* rule and no rule —
weaker than the NOTE reads as, and neither harness said so.

**Finding 2 — three parse-path rules were unexercised and UNDECLARED anywhere.**
`E-XML-PARSE` has had a fixture since intake; `E-YAML-PARSE`, `E-NOT-MAPPING`
and `E-LOAD` never did. Not a parity gap (both forms have parse rules), not in
any tolerance table — silently unwitnessed. Fixtures added for the first two.

**Finding 3 — `E-LOAD` cannot be witnessed by ANY fixture, by construction.**
It fires on file-not-found, and the fixture runner only ever passes paths that
exist. The state that would witness it is unreachable *for the harness that
would witness it* — OBS-124 one level up, at the instrument rather than the
check. Witnessed by direct CLI probe instead.

## Teeth

6 legs, each mutating the real tree, asserting red AND that the failure text
names its own condition, then restoring byte-identical
(`scratchpad/t333/teeth.py`): (a) always-fires caught, (b) undeclared
never-fires, (c) stale declaration, (d) count drift, (e) E-LOAD probe broken,
(f) unclassified scope. 6/6, `tools/validate-workflow.py` restored
byte-identical.

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

python3 tests/test_check_pass_reachability.py
out=$(python3 tests/test_check_pass_reachability.py 2>&1); echo "$out" | grep -q "0 always-fire"
out=$(python3 tests/test_check_pass_reachability.py 2>&1); echo "$out" | grep -q "E-LOAD witnessed directly"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "67 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "48 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "E-YAML-PARSE -> exit 2 and rule present"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "E-NOT-MAPPING -> exit 2 and rule present"
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "cross-form agreement: OK"
python3 tests/test_rule_form_parity.py
python3 tests/test_rule_dialect_axis.py
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy"
grep -q 'tests/test_check_pass_reachability.py' tests/run-bridge-tests.sh

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

### 2026-08-02 — the premise in my own filing was wrong

- **What changed:** I filed this task naming four printed-not-gated surfaces as
  the exposure, and said so on the rail at 381. Measuring them found three
  protected and the fourth answerable. The counted-tolerance NOTEs are not
  unguarded checks at all — the NOTE explains a check whose COUNT is asserted
  inside a green gating suite; and both INFO rules are asserted by name. I had
  reasoned about them from the fact that they PRINT, and never checked whether
  anything consumed them.
- **Plan impact:** AC1–AC5 were written for the disproved premise and are
  rewritten in place. The task's value moved from "audit these four" to "ask
  the question mechanically over the whole rule set", which is where it found
  something.
- **Triggered:** no new task; the follow-up (fixtures for the six unwitnessed
  carrier rules) is declared in `NEVER_WITNESSED`, counted and answerable in
  both directions, so it cannot rot silently.

### 2026-08-02 — my own headline was a zero of unknown kind

- **What changed:** the first result was "ALWAYS-FIRES: 0", which is the whole
  answer to OBS-124 — and I nearly reported it. It is a zero in a bucket I had
  never shown could be filled. That is precisely the capability-vs-occupancy
  confusion the observation names, appearing inside my answer to it. Teeth
  (injected unconditional rule → fires=47, silent=0) established the bucket is
  reachable, so the zero is an occupancy zero.
- **Plan impact:** AC4 rewritten from "returns two different verdicts" to "the
  ALWAYS-FIRES bucket is proven fillable". Two different verdicts would have
  been satisfied by NEVER-FIRES vs BOTH-BRANCHES without ever showing that the
  bucket carrying the finding could fill at all.

### 2026-08-02 — the teeth caught a real defect in the instrument

- **What changed:** the first instrument split the validator source at
  `class XmlValidator` to decide each rule's form. `run_yaml()` is DEFINED
  BELOW that class, so every module-level function was classified xml, and
  `E-YAML-PARSE` was measured against the 89 bpmn documents it can never
  reach — manufacturing a false never-witnessed. The teeth surfaced it: the
  injected always-firing yaml rule landed in NEVER-FIRES instead of
  ALWAYS-FIRES. Replaced with an ast scope map plus a total, explicit
  `SCOPE_FORM` table that ERRORS on an unlisted scope.
- **Plan impact:** none to scope; the pooled denominator would also have hidden
  a genuine always-fires case, since a yaml-only rule firing on 100% of yaml
  documents is silent on every bpmn document.
- **Triggered:** leg (f), so an unclassified scope is a failure and not a
  silent default.

### 2026-08-02 — a teeth leg that failed while the guard was right

- **What changed:** leg (a) went red on first run. The mutation inserted the
  unconditional warn BELOW `run_yaml`'s parse-error early return, so it was
  skipped for the malformed `E-YAML-PARSE.yaml` fixture I had added an hour
  earlier — silent=1, correctly filed under BOTH-BRANCHES. The guard was right;
  the mutation was not the condition it claimed to be.
- **Plan impact:** none. Recorded because it is the third instance on this arc
  of `probes-that-fail-when-right`, and the costly direction: it reads exactly
  like a real finding and sends you to debug working code.
- **Triggered:** anchor note written into the teeth driver so the next reader
  does not re-derive it.

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

### 2026-08-02T07:05:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-333-audit-non-gating-assertion-surfaces-for-.md
- **Context:** Initial task creation

### 2026-08-02T07:20:39Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e83141cd
- **Timestamp:** 2026-08-02T07:38:01Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T07:36:15Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
