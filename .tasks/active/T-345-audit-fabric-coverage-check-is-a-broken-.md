---
id: T-345
name: "audit fabric coverage check is a broken duplicate of its own sibling and cannot
  report non-zero"
description: >
  audit.sh's first fabric block globs watch patterns with bare glob.glob(p['glob'])
  — no PROJECT_ROOT join and no recursive=True — while the correct sibling at line
  1499 uses os.path.join(PROJECT_ROOT, g) with recursive=True. Both branches of its
  verdict call pass(). Measured: in one audit run with widened patterns it printed
  'Fabric: 15 registered, 0 unregistered' [PASS] while its sibling printed 'Fabric
  drift: 49 source file(s) have no fabric card' [WARN].

status: started-work
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T11:15:57Z
last_update: '2026-08-16T14:33:02Z'
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
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:02Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F2: 1
      F4: 4
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=1 
      (body/components:component-fabric-incidental); F4=4 
      (prose:routing-structural); F3=0 (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/audit/audit.sh,tools/_t345-fabric-check-agreement.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-345: audit fabric coverage check is a broken duplicate of its own sibling and cannot report non-zero

## Context

Found by T-342. `agents/audit/audit.sh` contains **two** fabric-coverage checks over the
same question. The second is correct. The first is a strictly-broken duplicate of it.

Broken (≈:1405):
```python
for match in glob.glob(p['glob']):
```
Correct sibling (:1499):
```python
for match in glob.glob(os.path.join(PROJECT_ROOT, g), recursive=True):
```

Three independent defects in the first check:

1. **No `PROJECT_ROOT` join** — the pattern resolves against the process CWD, not the project.
2. **No `recursive=True`** — in Python's `glob`, `**` without it does not recurse; every
   pattern in the shipped watch file uses `**` except `bin/*`. So even with the right root,
   `src/**/*.py` would match only one directory level.
3. **Both verdict branches call `pass()`** —
   ```bash
   if [ "$fabric_unreg" -gt 0 ]; then pass "... $fabric_unreg unregistered (coverage growing)"
   else                               pass "... 0 unregistered"
   ```
   so no value of the metric can ever raise a warning. `pass()` increments `PASS_COUNT` and
   contributes no PRIORITY ACTION.

Defects 1–2 mean the number is structurally zero; defect 3 means it would not recruit
attention even if it weren't. Either alone would be enough to make the line carry no
information.

**Measured, in a single real audit run** (`--section structure`, watch patterns temporarily
widened to `tools/**/*.py`, `tests/**/*.py`, `src/**/*.html`, then reverted):

```
[PASS] Fabric: 15 registered, 0 unregistered
[WARN] Fabric drift: 49 source file(s) have no fabric card
```

Two sibling checks over the same question, in the same run, disagreeing by 49 — and the
one that reads as reassurance is the PASS. Note this was *predicted* from reading the
branch as "both arms pass", and the run showed the operative mechanism was the glob root
instead; reading gave the weaker half of the answer.

Vendored framework code — G-008 (fix in-tree, upstream to AEF) applies.

**Ordering constraint (interacts with T-344):** T-344 tailors the watch patterns so the
coverage checks scan a real population. Landing T-344 *without* this task makes the audit
print two contradictory fabric lines side by side — exactly the output reproduced above.
This task should land first, or with it.

## Acceptance Criteria

### Agent
- [x] The first fabric block either resolves patterns identically to the sibling at :1499
      (PROJECT_ROOT-joined, `recursive=True`) **or** is removed as a duplicate — with the
      choice recorded in `## Decisions

### 2026-08-08 — repair vs remove: repaired provisionally, human call preserved

- **Chose:** repair all three defects in the first block; do NOT delete it.
- **Why:** delete is irreversible under agent action and the retain-vs-remove call is an
  explicit `[REVIEW]` Human AC on this task. Repair leaves the tree in a correct state
  under either outcome — if the human chooses removal it is a one-line follow-up, whereas
  a deletion I made unilaterally would have taken their decision and lost what the check
  reported. The repaired block is now a near-duplicate of the sibling and that is a real
  argument for removal; I have not made that argument into a decision.
- **Rejected:** removing it now (takes a decision reserved to the human); leaving it inert
  (an always-PASS line over a structurally-empty input set is worse than no line, because
  it answers the question that would otherwise be asked).`, since the sibling already covers the question.
      → REPAIRED (provisionally — the retain-vs-remove call is the Human AC below and is
        not mine to make). All three defects fixed: PROJECT_ROOT join, `recursive=True`,
        and an `isfile()` guard the sibling had and this one did not. Repair rather than
        delete because repair is reversible under review and delete is not: if the human
        chooses removal, that is a trivial follow-up; if I had deleted and they wanted it
        kept, the check would be gone with no record of what it said.
- [x] If retained: the `unregistered > 0` branch no longer reports `pass`. The severity
      chosen is stated; "coverage growing" as a PASS is not carried forward unexamined.
      → now `warn`. Severity chosen to MATCH THE SIBLING at ~:1510, which warns on exactly
        this condition — two checks over one question disagreeing on severity is the same
        defect one level up, and matching is the only choice that does not invent a new
        opinion about how bad this is. "(coverage growing)" is dropped: it framed a rising
        count of UNREGISTERED files as good news.
- [x] Teeth: with the shipped watch patterns widened to a set that matches real files, the
      first check and the sibling report the **same** count. A leg that reverts either of
      the two glob fixes makes them disagree and fails naming which one diverged.
      → `tools/_t345-fabric-check-agreement.sh`, 9/9. Population asserted first (83 real
        files) because over an empty watch set both checks return 0 and agree perfectly
        while measuring nothing.
      **The probe corrected me on fix 1.** Its first run reported the PROJECT_ROOT join as
      INERT — reverting it changed nothing, because CWD already *was* the project root. I
      would otherwise have reported three fixes verified when the run had evidence for two.
      Re-exercised under the condition it addresses (audit invoked from another CWD) it is
      load-bearing: 76 -> 0. Both facts are now printed, because "load-bearing" and
      "load-bearing always" are different claims and only the first is true.
- [x] The audit's own PASS/WARN/FAIL totals are re-baselined and the change to the standing
      verdict is stated explicitly in the completion report (this alters what the operator
      sees at every audit).
      → Post-fix full audit: **Pass 120 / Warn 28 / Fail 60**, and the two fabric lines now
        read consistently (`Fabric: 17 registered, 0 unregistered` + `Fabric drift: All
        watched source files registered`).
      **Today's totals are UNCHANGED, and that is not evidence the fix works.** The shipped
      `watch-patterns.yaml` is the untailored default that expands to zero files (T-344), so
      both checks report 0 over an empty population — they would agree at 0 whether or not
      this fix landed. The real change to the standing verdict is conditional: once T-344
      gives the checks a real population, this line becomes capable of emitting WARN and
      contributing a PRIORITY ACTION, which it never could before at any input value.

### Human
- [ ] [REVIEW] Decide retain-and-fix vs remove-as-duplicate for the first fabric block
      **Steps:**
      1. `cd /opt/832-Workflow-designer && sed -n '1377,1435p' .agentic-framework/agents/audit/audit.sh`
      2. Compare with the sibling: `cd /opt/832-Workflow-designer && sed -n '1469,1510p' .agentic-framework/agents/audit/audit.sh`
      3. Decide whether the first block reports anything the second does not.
      **Expected:** a recorded choice — repair or delete — in this task's `## Decisions`.
      **If not:** leave as-is; the check is inert, so no regression follows from deferring.

## RCA

**Symptom:** `[PASS] Fabric: 15 registered, 0 unregistered` printed in the same audit run
in which a sibling check found 49 unregistered files.

**Root cause:** a duplicated coverage check whose glob resolves against CWD without
`recursive=True`, so its input set is empty regardless of configuration; and whose verdict
calls `pass()` on both arms, so its output is constant regardless of its input.

**Why structurally allowed:** the correct version was written later (:1499) and the earlier
one was never removed. Two checks answering one question, and the audit has no rule that
they must agree — so the broken one's constant zero was read as corroboration of the good
one's zero, when in fact the good one's zero had the *same* upstream cause (T-344) and
neither was measuring anything. Green agreeing with green is not agreement; see
[[checks-that-discriminate-nothing]] and [[differential-instruments-share-blindness]].

**Prevention:** the teeth leg requiring the two checks to report the same count — which
makes a future divergence red rather than invisible.

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

**Recommendation:** GO on **remove-as-duplicate — reported upstream, not patched here.**

**Rationale.** The two blocks answer the same question and the second one answers it
correctly. Repairing the first would leave two checks computing the same figure, which is
how they drift into disagreeing and how a reader learns to trust whichever is quieter.
Nothing is lost by deletion: the sibling at `:1499` already ranges over the same watch
patterns with the joins the first block is missing.

**The three defects are not independent bugs — they compound into a check that cannot
report anything:**

1. **No `PROJECT_ROOT` join** — `glob.glob(p['glob'])` resolves against the process CWD,
   not the project.
2. **No `recursive=True`** — in Python's `glob`, `**` without it does not recurse. Every
   pattern in the shipped watch file uses `**` except `bin/*`, so even from the right
   directory `src/**/*.py` would match one level.
3. **Both verdict branches call `pass()`** — so whatever the count, the check reports
   PASS.

**Defect 3 is the one that matters, and it is G-034 exactly.** A check whose every branch
is a pass has no failing state, so a green from it and a green from a working check are
the same string. This is the fourth instance of that class in this tree
(`_norec-verify.py` T-450, `bake-clean-layout.py` T-447, the five T-440 measured BLIND,
and this) and the first found in **vendored** code. Worth saying on the rail as a class,
not just as a file — AEF ran our census against their tree last week and found the sibling
shape there.

**Evidence:** `.agentic-framework/agents/audit/audit.sh` ≈`:1405` (broken) vs `:1499`
(correct), the two reachable by the AC's own two `sed` commands. The block is **inert
today** — with defects 1 and 2 it matches nothing, and with defect 3 it could not report
it if it did — which is why deferring this costs nothing operationally and why it went
unnoticed.

**Why upstream and not here.** `agents/audit/audit.sh` is vendored
(`.agentic-framework/`), and a local patch is silently reverted by the next bump — the
gate would then read as fixed in our history and not be. Same disposition as T-402 and
T-422, and AEF's instruction at DM 522 §5. **G-008 makes this the upstreamable kind**, so
the deliverable of your ruling is a rail report with the two line numbers, not an edit.

**What your ruling unblocks:** nothing blocking here — the value is entirely that a
peer's audit stops carrying a check that cannot fail. If you rule remove, I post it; if
you rule retain-and-fix, I post that instead with the repair shape.

## Verification

```
bash tools/_t345-fabric-check-agreement.sh
```

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

### 2026-08-02T11:15:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-345-audit-fabric-coverage-check-is-a-broken-.md
- **Context:** Initial task creation

### 2026-08-08T07:59:30Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
