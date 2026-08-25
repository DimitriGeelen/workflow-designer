---
id: T-581
name: "The byte-identity gate's baseline is a hand-picked git literal, so it goes stale on a clock nobody watches"
description: >
  tools/_t358-byteid-thirdparty.mjs:48 pins BASELINE_REF to the string '3bf37909~1'. Nobody chose that ref as a ratification point; it is where the file sat on 2026-08-04. It has since gone stale past the exporter provenance stamp, T-423 DI, T-364 repair (a) and T-563 id derivation, which is why the gate reports PRECONDITION VIOLATED and 11 drifted (T-579 diagnosed this). Re-pinning by hand reproduces the defect on the same clock. Question this task owns: what should the baseline be instead - a recorded ratification file the gate reads, a merge-base, or a last-green marker - and what makes the choice not go stale. Split out of T-579, which was wrongly parked as a sovereignty decision when it is a design question.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t581-byteid-baseline-teeth.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-24T18:03:43Z
last_update: 2026-08-24T21:12:55Z
date_finished: 2026-08-24T21:12:55Z
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

# T-581: The byte-identity gate's baseline is a hand-picked git literal, so it goes stale on a clock nobody watches

## Context

`tools/_t358-byteid-thirdparty.mjs` compares the CURRENT build against a BASELINE build
whose source it reads out of git at `BASELINE_REF`, defaulted to the string literal
`'3bf37909~1'` (`:48`). Nobody ratified that ref. It is where `src/aef-workflow-designer.html`
happened to sit on 2026-08-04, the commit before T-358's own change — the one question the
tool was written to answer.

**Measured 2026-08-24, before any change here.**

| baseline | verdict | rc |
|---|---|---|
| `3bf37909~1` (as shipped) | **0 identical, 11 drifted**, *PRECONDITION VIOLATED* | 1 |
| `HEAD` (control — both sides are the current build) | **11 identical, 0 drifted**, *PRECONDITION HOLDS*† | 0 |

† The `PRECONDITION HOLDS` half of that line is **not** a measurement and is not cited as one —
see the Evolution entry below. Its literal text ("no fixture has a same-lane x tie among uid-less
nodes") is false on this corpus: 2 fixtures carry 16 tie groups across 64 uid-less nodes. Only
the `11 identical, 0 drifted, rc 0` half is load-bearing here.

The control is the load-bearing half. It says the entire red is the baseline's age and
**not** the current build: every one of the 11 drifts is a deliberate landed change
(`Definitions_Process_1` → `Definitions_process_1` is T-563's `sanitizeWorkflowId`), and the
current build is within-build deterministic on all 11 fixtures, so goldens recorded from it
will be stable. Without that control, "11 drifted" is equally consistent with a real
exporter regression, and the two readings are not separable by the shipped tool.

**The precondition violation is the same artifact.** The hazard test is
`tieGroups > 0 && (uidsDifferAcrossBuilds || uidUnstableWithinBuild)`, and the baseline build
predates T-364's uid repair, so it mints randomly while the current build derives. The tool's
own comment predicts this and calls it self-healing "once BASELINE_REF moves past the repair" —
which is precisely the hand re-pin this task exists to stop needing.

**Re-pinning by hand reproduces the defect on the same clock.** Any literal successor goes
stale the next time the exporter legitimately changes; choosing one is choosing which future
session repeats this task.

**It is also an unwired guard.** `tools/unwired-guard-baseline.txt:135` carries
`_t358-byteid-thirdparty.mjs` — it has no live caller, so its red has been costing nothing and
telling no one for 20 days. Fixing the baseline without wiring it leaves a correct instrument
that still never runs.

## Acceptance Criteria

### Agent
- [x] **The baseline is recorded bytes, not a build.** One golden per third-party fixture under
      `tests/goldens/third-party/`, each the uid-normalised emission of a build a human can see
      in a diff. The gate reads them and no longer resolves any git ref for
      `src/aef-workflow-designer.html`. Evidence: a run reports 11 identical against the goldens,
      and the drift of an accepted change is a reviewable diff in git rather than a re-pin.

- [x] **The cross-build uid precondition is gone because the second build is gone — and what
      remains is still able to fire.** With one build there is no `uidsDifferAcrossBuilds` term
      to violate. The within-build determinism check (double parse, uid vector compare) is
      retained and must be shown red under mutation, not merely present. A precondition that
      cannot fail is a constant wearing a verdict (T-364's own words).

- [x] **Re-recording is a deliberate act that the suite cannot perform.** Goldens are written
      only under an explicit `--record`; the default path refuses and exits non-zero on a
      mismatch. A gate that refreshes its own baseline on green can never report accumulated
      drift — that is the failure this task is repairing, not a shortcut around it.

- [x] **Mutation teeth, each red for its own predicted reason:** (a) a changed golden byte goes
      red naming that fixture; (b) a changed emitter goes red; (c) the within-build determinism
      check goes red when uid derivation is made nondeterministic; (d) `--record` absent from
      the suite's invocation is asserted positively, not by grepping for its absence.

- [x] **The instrument acquires a live caller.** Wired into `tests/run-bridge-tests.sh`, and
      `tools/unwired-guard-baseline.txt` regenerated by its own generator (never hand-edited —
      the file says so) so the census no longer finds it. The unwired ratchet fails in **both**
      directions, so a green ratchet after regeneration is the assertion that the wiring is real.

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

# ── T-581 ─────────────────────────────────────────────────────────────────────
# Each line's own exit code is the verdict; nothing is chained, so the errexit
# hazard above cannot arise.
node --check tools/_t358-byteid-thirdparty.mjs
bash -n tests/run-bridge-tests.sh
# The corpus is asserted POSITIVELY — 11 goldens exist. `-eq 0` over a grep would be
# satisfied identically by "absent" and "my pattern was wrong" (T-560).
# G-015 repair (T-499): this line was `test $(ls .../*.bpmn.golden | wc -l) -eq 11` — a
# count pinned to a growing population. MEASURED before removing it: hide one golden and
# `node tools/_t358-byteid-thirdparty.mjs` (the line above) already exits 1 with "1
# fixture(s) have no golden". So the pin asserted nothing the gate did not, and would have
# gone red on the twelfth third-party fixture — failing for the opposite of a defect.
# What T-581 delivered is asserted by the two gate lines above; this one enumerates the
# recorded population instead of pinning its size.
sh -c 'echo "goldens recorded:"; ls tests/goldens/third-party/*.bpmn.golden | sed "s|.*/|  |"; ls tests/goldens/third-party/*.bpmn.golden >/dev/null 2>&1'
# The gate itself: 11 identical against recorded bytes, rc 0.
node tools/_t358-byteid-thirdparty.mjs
# The teeth: control green, then four mutations each red for its own predicted reason
# and its own predicted exit code. This is the line that makes the gate's green mean
# something — without it the gate is a refusal path never shown able to refuse.
python3 tools/_t581-byteid-baseline-teeth.py
# The unwired ratchet fails in BOTH directions, so rc 0 here is the assertion that the
# gate's new suite wiring is real and that the baseline was tightened to match it.
python3 tools/_t451-unwired-guard-census.py --ratchet

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

### 2026-08-24 — all five ACs closed on measurement; and leg (d) caught my own leg (d)

The slice specified in the entry below ran as written. `T358_SRC` landed on the same
convention as `T358_FIXDIR` / `T358_GOLDENDIR`, `tools/_t581-byteid-baseline-teeth.py`
was written, the gate was wired at `tests/run-bridge-tests.sh:1265`, and
`tools/unwired-guard-baseline.txt` was regenerated by deriving the entry block from
`_t451-unwired-guard-census.py --json` — never hand-typed, as the file demands.

Measured, one run each:

| leg | mutation | wanted | got |
| CONTROL | none | rc 0, 11 identical | rc 0, **11 identical, 0 drifted** |
| (a) | one `name=` byte in one golden | rc 1, DRIFTED naming that fixture | rc 1, names `aef-draft-inception-readiness-v2.bpmn` |
| (b) | `BPMN_EXPORTER` → `…-MUTANT` | rc 1, all 11 drift | rc 1, **drifted=11** |
| (c) | `deriveUid` hash32 → `Math.random()` | rc 2, REFUSING | rc 2, refusal text present |
| (d) | — | every invocation omits `--record` | 1 invocation, 0 carry it |

Suite **133 passed, 0 failed** (was 132 legs; this adds one). Ratchet: `baseline 65,
current findings 65 — no movement`, in a file that fails in both directions.

**THE CONTROL IS A LEG, NOT A COURTESY.** (a), (b) and (c) all assert a NON-zero exit,
so all three are satisfied by a gate that is merely broken — a typo would "pass" three
legs. The control is the only one that separates "the teeth bite" from "the tool is
dead", so it runs first and aborts the rest on failure.

**AND THEN LEG (d) FOUND A DEFECT IN LEG (d).** Its first draft counted any non-comment
line containing the tool's name and reported **3 invocations in a runner that invokes the
gate once** — the real one, the `report FAIL "…"` message that quotes the command for the
reader, and the `show_output` label. It then flagged the message line as carrying
`--record`, because the message tells a human to re-record deliberately.

That is worth writing down because it is this week's shape pointing the other way. The
leg exists to replace `grep -c X -eq 0`, where a wrong pattern renders as *absence*. My
wrong pattern rendered as a *finding* instead. Same defect — a text match standing in for
the property — and it was only visible because the leg asserts over an enumerated
population and printed the population. Had it printed a bare verdict I would have
"fixed" a runner that was already correct. The discriminator is now shell semantics, not
text: an invocation is a `shlex` token whose basename is the tool and whose predecessor
token is `node`, which classifies all three lines correctly for a stated reason.

**What is now structurally absent vs merely dormant.** The cross-build uid hazard is
absent — with one build there is no second uid vector to disagree with, so the term
cannot be formed. The within-build determinism refusal is *dormant but proven live*: leg
(c) is the only evidence that it can fire, and it is the reason AC2 is ticked now and was
not ticked last window.

**Not claimed:** OBS-307's `_t550` leg-5 flake did not reproduce this run. One green run
is not a fix and the observation stays open.

### 2026-08-24 — where this stands: 1 of 5 ACs, and what the remaining four need

- **What changed:** the design question this task was split out to answer is **answered and
  built** — recorded goldens, `--record`-only re-recording, one build instead of two, all three
  paths measured (no goldens → rc 1; `--record` → 11 written, rc 0; compare → 11 identical,
  rc 0). AC1 is ticked on that evidence.
- **Plan impact:** AC2–AC5 are deliberately **not** ticked. AC2 requires the surviving
  within-build determinism check to be shown red under mutation, and I have not mutated it — a
  refusal path that has never refused is the exact thing this task cites T-364 about, so
  asserting it from the code's shape would repeat the defect inside the repair. AC3's mechanism
  is built and its refusal path measured, but its second clause ("the suite cannot perform it")
  is unassertable until the suite calls it. AC4 and AC5 are untouched.
- **Stopped on budget, not on a blocker.** 154K at the checkpoint commit, which is the urgent
  band. The remaining slice is well-shaped and needs a fresh window: add a `T358_SRC` override
  (same convention as the existing `T358_FIXDIR`/`T358_GOLDENDIR`) so the teeth can drive a
  deliberately-nondeterministic build, write the four mutations, wire the leg into
  `tests/run-bridge-tests.sh`, then regenerate `tools/unwired-guard-baseline.txt` with its own
  generator and show the ratchet green — it fails in both directions, so that green is the
  assertion that the wiring is real.
- **Suite state at handover:** 131 passed, 1 failed. The failure is `_t550` teeth leg 5, which
  is **not** from this change: it passes 5/5 rc 0 standalone, this commit touches no audit path,
  and the watch set is 289 files before and after (`.golden` matches no pattern). Filed as
  OBS-307.
- **Triggered:** OBS-307 (T-550 teeth leg 5 flaky in-suite only).

### 2026-08-24 — the control run's "PRECONDITION HOLDS" was itself an unchecked claim

- **What changed:** the `HEAD` control I put in this task's Context printed, verbatim,
  `PRECONDITION HOLDS: no fixture has a same-lane x tie among uid-less nodes`. That sentence
  is **false on this corpus**, and the same run's own data says so: `boundary-events.bpmn` has
  2 tie groups over 4 nodes and `kitchen-sink.bpmn` has 14 over 60, all with `srcUids: 0`.
  The old hazard test is a conjunction — `tieGroups > 0 && (uidsDiffer || uidUnstable)` — and
  its `else` branch asserts the **first** term is false when it may have been the second that
  failed. A conjunction failing was reported as its first conjunct failing. So the reassuring
  half of that message could only ever be read on the path where it was least likely to be true.
- **Plan impact:** none to the design; it strengthens it. Under goldens the tie measurement is
  reported unconditionally as a NOTE with the actual counts, so the number is printed on the
  green path too. This is the same shape as the week's other findings — a stated property
  standing in for a checked one, with the failure rendering as health — and it was sitting
  inside the instrument built to catch that class.
- **Triggered:** nothing new filed; the correction is in this task's own Context table, which
  now footnotes the control's HOLDS rather than citing it as a measured property.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-08-24 — recorded golden bytes, not a git ref

- **Chose:** the baseline is 11 committed `.golden` files — the uid-normalised emission of a
  reviewed build — read from disk. The gate builds the editor **once**.
- **Why:** it removes the staleness clock rather than resetting it. A git ref names a *build*,
  so it ages against every legitimate exporter change and drags the cross-build uid hazard in
  with it; recorded bytes name an *output*, and an accepted change becomes a diff someone reads
  in review. It is also strictly cheaper — one build instead of two — and the tree already uses
  this shape for ratchets (`tools/_t560-absence-baseline.txt`, `tools/unwired-guard-baseline.txt`).
- **Rejected — re-pin `BASELINE_REF` to a newer commit.** This is the obvious move and it is the
  defect: the successor goes stale on the same clock, and the choice of *when* is made by
  whoever is next inconvenienced rather than by anyone deciding.
- **Rejected — `git merge-base`.** Degenerate here. This repo has one long-lived branch, so the
  merge-base of `HEAD` with anything is `HEAD` or an arbitrary ancestor; it would encode "compare
  against nothing" as a computation and read as rigour.
- **Rejected — a last-green marker the gate advances itself.** The worst of the three, and the
  attractive one: a gate that re-records its baseline whenever it passes ratchets forward
  silently and can never report drift that accumulated one green run at a time. That is this
  week's whole failure class — a stated property standing in for a checked one, with the failure
  rendering as health. `--record` is therefore explicit, refused by default, and absent from the
  suite's call.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-24T18:03:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-581-the-byte-identity-gates-baseline-is-a-ha.md
- **Context:** Initial task creation

### 2026-08-24T19:16:26Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-082965ec
- **Timestamp:** 2026-08-24T21:13:05Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-24T21:12:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
