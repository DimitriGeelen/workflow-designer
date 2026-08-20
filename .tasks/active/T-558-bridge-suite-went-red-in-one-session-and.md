---
id: T-558
name: "bridge suite went red in one session and four tasks shipped green through it"
description: >
  bridge suite went red in one session and four tasks shipped green through it

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-19T23:32:23Z
last_update: 2026-08-19T23:32:23Z
date_finished: null
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

# T-558: bridge suite went red in one session and four tasks shipped green through it

## Context

**AT FILING** `bash tests/run-bridge-tests.sh` reported **109 passed, 4 failed**. At
completion it reports **114 passed, 0 failed** — the four legs were repaired and one was
added, so the suite grew; it did not reach green by shrinking. The state at filing is left
standing below because the four causes are the finding, not the four fixes.

It was found not by
running the suite for its own sake but by executing **T-101's** `## Verification` block
mechanically, to check whether a task whose Agent and Human ACs are all ticked would
actually survive the P-011 completion gate. T-101 leg 2 *is* the bridge suite. It is red,
so T-101 (BVP 139, rank-5 HV/HC) cannot complete, and nothing said so.

**All four failures trace to commits from the session of 2026-08-17** — T-448, T-552 and
T-557, three tasks that each completed green:

| # | Gate | What it says | Introduced by |
|---|------|--------------|---------------|
| 1 | `_t517-vendor-divergence.py` | `.agentic-framework/agents/observe/observe.sh` is a local change to vendored code that no manifest entry claims | T-557 (`faa1dc4b`) |
| 2 | `_t451-unwired-guard-census.py --ratchet` | baseline 67, current 66 — `bake-clean-layout.py` is now wired and its baseline entry is stale | T-448 |
| 3 | `_t327` harness emitter fidelity | `_t448-drift-classification-teeth.py` synthesises `<bpmn:task>`, which neither emitter can produce, undeclared | T-448 |
| 4 | `_t532-hermeticity-scope-census.py` | `tools/_writeset_hermeticity.py` asserts hermeticity over the whole tree | T-552 (`f4a90fc8`) |

**The structural cause is one thing, and it is visible in all three tasks' own
`## Verification` blocks.** Each of them asserts that its new probe is *registered*:

```
grep -q '_t448-drift-classification-teeth.py' tests/run-bridge-tests.sh     # T-448
grep -q '_t552-writeset-hermeticity-teeth.py' tests/run-bridge-tests.sh     # T-552
grep -q  "test_note_capture_refuses_lost_payload" tests/run-bridge-tests.sh # T-557
```

and **not one of them runs `tests/run-bridge-tests.sh`.** Each verified *"I am wired in"*
and none verified *"the suite I just wired myself into is still green."* That is PL-148
(registration must be asserted by something other than the instrument) satisfied to the
letter, and this week's shape one level up: a stated property standing in for a checked
one, with the failure rendering as health. Three tasks shipped green through a suite they
had turned red.

## Acceptance Criteria

### Agent
- [x] **The four are attributed BEFORE any of them is repaired.** Each failure names the
      commit that turned it red and the task that owned that commit, recorded in this file.
      Written first so each repair is judged against a stated cause rather than against the
      suite going green — a green suite is also what deleting four assertions produces.
- [x] **(1) The undeclared vendored patch is DECLARED, not reverted.** The T-557 guard in
      `.agentic-framework/agents/observe/observe.sh` is a deliberate local fix under G-008
      and must survive; `.agentic-framework/.vendor-divergence.yaml` gains an entry that
      says so and names the task. `_t517-vendor-divergence.py` reports 0 unrecorded.
- [x] **(2) The unwired-guard baseline moves only in the direction the census measured,
      and the removal is justified by naming the caller.** `bake-clean-layout.py` is
      removed from `tools/unwired-guard-baseline.txt` only after the executable reference
      that now wires it is cited in this task. No blanket re-baseline: the census reported
      SHRANK, and a GROWTH would be a finding to report rather than absorb.
- [x] **(3) The `<bpmn:task>` synthesis in `_t448-drift-classification-teeth.py` is
      resolved on its merits.** Either the fixture uses the tag an emitter actually
      produces, or un-producibility is the property under test and is DECLARED in
      TOLERATED with a reason. `_t327` reports 0 violations, and the choice is recorded in
      `## Decisions` with what the teeth still prove afterwards.
- [x] **(4) The whole-tree hermeticity assertion is scoped to the write-set its callers
      declare**, or shown to be correctly scoped already. `_t532-hermeticity-scope-census.py`
      reports 0 whole-tree assertions. The repair must not consist of removing the
      assertion — T-552 exists because that comparand was blind, and a deleted comparand
      is blinder.
- [x] **NO REPAIR IS A WIDENED BASELINE OR A DELETED ASSERTION.** For each of the four,
      this task records in one line what the gate can still catch after the repair that it
      could catch before. A gate that now passes because it stopped looking is a
      regression wearing the result of a fix.
- [x] **`bash tests/run-bridge-tests.sh` reports `0 failed`**, and the count of passing
      legs is >= 109 (the repair may not reach green by shrinking the suite).
- [x] **The structural hole is registered, not just fixed.** An observation records that a
      task wiring a probe into `run-bridge-tests.sh` asserts registration and not
      greenness, with the detector shape written down: for any task whose diff touches
      `tests/run-bridge-tests.sh`, require `run-bridge-tests.sh` to appear in that task's
      `## Verification`. Registered here; building it is not this task's deliverable.

_No `### Human` section. Every criterion above is a mechanical check the agent runs. This
task restores four gates the agent itself turned red; asking the operator to sign off on
that would be borrowing their authority to close the agent's own mess._

<!-- Template guidance retained for the next reader.
     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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
#
# THIS TASK'S FIRST LEG IS THE SUITE ITSELF, and that is the whole point of the task.
# T-448, T-552 and T-557 each asserted `grep -q '<probe>' tests/run-bridge-tests.sh` and
# none of them ran it. A registration assertion cannot see the suite go red; only running
# it can. The count floor is asserted too, because "0 failed" is also what deleting four
# legs produces.
bash tests/run-bridge-tests.sh > /tmp/.t558-suite 2>&1 && python3 -c "import re,sys; m=re.search(r'(\d+) passed, 0 failed', open('/tmp/.t558-suite').read()); sys.exit(0 if m and int(m.group(1)) >= 114 else 1)"
# (1) the T-557 vendored patch is DECLARED — and the fix it declares is still there, so the
# manifest entry cannot rot into a claim about code that was re-vendored away.
python3 tools/_t517-vendor-divergence.py > /tmp/.t558-vendor 2>&1 && grep -q "every diverged path is declared" /tmp/.t558-vendor
grep -q "_note_positional_count" .agentic-framework/agents/observe/observe.sh
# (2) the unwired-guard ratchet has no movement in either direction.
python3 tools/_t451-unwired-guard-census.py --ratchet > /tmp/.t558-ratchet 2>&1 && grep -q "no movement" /tmp/.t558-ratchet
# (3) every synthesised <bpmn:*> element is emitter-producible, and T-448's teeth still
# discriminate after the tag change — the gate going green must not have cost the teeth.
python3 tests/test_harness_emitter_fidelity.py > /tmp/.t558-fidelity 2>&1 && grep -q "0 violations" /tmp/.t558-fidelity
python3 tools/_t448-drift-classification-teeth.py > /tmp/.t558-t448 2>&1 && grep -q "7/7 legs passed" /tmp/.t558-t448
# (4) the hermeticity census is clean AND still detects a real one. Leg 5 of the teeth is the
# discrimination arm: without it, "0 whole-tree assertions" is indistinguishable from a
# deleted classifier.
python3 tools/_t532-hermeticity-scope-census.py > /tmp/.t558-herm 2>&1 && grep -q "T-532 OK" /tmp/.t558-herm
python3 tools/_t558-hermeticity-census-teeth.py > /tmp/.t558-teeth 2>&1 && grep -q "5/5 legs passed" /tmp/.t558-teeth
# No mutant residue: the teeth plant files in tools/ and remove them in a finally.
test 0 -eq "$(ls tools/ | grep -c 't558-teeth-mutant')"

## RCA

**Symptom.** `bash tests/run-bridge-tests.sh` reported **109 passed, 4 failed**. Three tasks
(T-448, T-552, T-557) had completed green through it on 2026-08-17, and the handover, the
audit and the metrics all read healthy. The red surfaced only because T-101's `##
Verification` block was executed by hand — to check whether a task with every Agent and
Human AC ticked would survive the P-011 gate — and T-101's leg 2 *is* the suite.

**Root cause.** Each of the three tasks added a probe to `tests/run-bridge-tests.sh` and
verified that the probe was **registered**, never that the host suite still **passed**:

| Task | What its Verification asserted | What it did not do |
|---|---|---|
| T-448 | `grep -q '_t448-drift-classification-teeth.py' tests/run-bridge-tests.sh` | run the suite |
| T-552 | `grep -q '_t552-writeset-hermeticity-teeth.py' tests/run-bridge-tests.sh` | run the suite |
| T-557 | `grep -q "test_note_capture_refuses_lost_payload" tests/run-bridge-tests.sh` | run the suite |

Each ran its own probe in isolation and each of those probes passed. What broke was not the
new probe but three OTHER gates that the same commits tripped — a vendored file patched
without a manifest entry, a fixture synthesising an unproducible element, a new module whose
docstring read as a `git status` invocation. Every one of those gates fired correctly and on
time. Nothing was listening.

**Why structurally allowed.** P-011 runs exactly the commands a task writes, and the three
tasks wrote the wrong assertion — a stated property (*I am wired in*) standing in for a
checked one (*the thing I wired myself into still works*). This is PL-148 one turn further
out: PL-148 says an instrument's registration must be asserted by something other than the
instrument, and here the instrument asserted its own registration while nothing at all
asserted the suite's verdict. The failure rendered as health in every artifact that reports
on the session, which is this week's recurring shape.

**Prevention (registered, not built).** OBS-292 records the detector: for any task whose diff
touches `tests/run-bridge-tests.sh`, require `run-bridge-tests.sh` to appear in that task's
`## Verification`. Both facts are available in the same commit, so it is decidable at
completion time from the task file plus `git diff --name-only`. Not built here — it is a
completion-gate change and belongs in its own task. What IS built here is the narrower thing:
this task's own first verification leg is the suite, with a count floor so that reaching
green by deleting legs fails.

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

### 2026-08-18 — the `<bpmn:task>` fixture: change the tag, not declare a tolerance

- **Chose:** replace `<bpmn:task>` with `<bpmn:scriptTask>` in
  `tools/_t448-drift-classification-teeth.py`.
- **Why:** the T-327 gate offers two exits — use a producible tag, or declare in TOLERATED
  that un-producibility is the property under test. The two existing tolerances are genuine:
  `test_t313_lane_capacity.py` injects `<bpmn:transaction>` precisely to prove lane-capacity
  SKIPS an unknown type, and `test_typed_event_fixture_contract.py` injects a native
  `<bpmn:timerEventDefinition>` to prove the IW-1 guard trips on a thing no emitter emits. In
  both, an emitter-producible tag would not exercise the path at all. Here the node element is
  incidental scaffolding: `classify_drift()` reads diff lines for `aef:position` and
  `dc:Bounds`, and never looks at the element name. So a tolerance would be a declaration that
  the fixture depends on un-producibility when it does not — an exemption bought with a false
  statement.
- **What it still catches after the change:** teeth 7/7, unchanged, including the
  discrimination leg (a marker inside an XML comment must not count as a coordinate) and the
  two carriers. `scriptTask` is the corpus's most common node type (111 occurrences across the
  24 rendered maps) and carries `aef:position` identically, so the stimulus is the same and
  the document around it became one that can actually occur.
- **Rejected:** declaring a tolerance (buys silence with a false claim); leaving it (the gate
  is right).
- **Correction made in passing:** the fixture's comment claimed to be "verbatim from `git
  diff` of a re-bake run". The diff SHAPE is verbatim; the node element was never in the
  corpus at all (0 of 24 files contain `<bpmn:task `). The comment now says which half is
  verbatim.

### 2026-08-18 — the hermeticity census: fix the census, not the module it flagged

- **Chose:** teach `tools/_t532-hermeticity-scope-census.py` to blank Python docstrings before
  classifying, and leave `tools/_writeset_hermeticity.py` untouched.
- **Why:** the census reported `_writeset_hermeticity.py` as the corpus's one WHOLE-TREE
  hermeticity assertion. That module contains **no subprocess call of any kind** — it walks a
  subdirectory and hashes bytes, and takes the subdirectory as a parameter. It was flagged on
  the strength of its module docstring, which explains at length that the FIRST form of the
  assertion used `git status --porcelain` and why a digest comparand replaced it. The census's
  own `strip_comments` docstring names this failure mode exactly — *"a checker that is
  confused by comments ABOUT the pattern it detects gets steadily more wrong as authors
  document the thing"* — and T-533 closed it for `#` comments only. A docstring is a comment
  the tokenizer does not call a comment. The sibling census `_t451-unwired-guard-census.py`
  reached the same conclusion under T-495 and blanks `ast.Expr(Constant str)`; this is that
  fix arriving in the second census, five days later, in the first file to trip it.
- **What it still catches after the change:** proven rather than asserted, by
  `tools/_t558-hermeticity-census-teeth.py` — a planted real unscoped before/after
  `git status` assertion is still flagged AND still drives rc=1, while the same words in a
  docstring are not. Going from one finding to zero is also what deleting the classifier
  produces; those two legs are what separate them.
- **Rejected:** scoping `_writeset_hermeticity.py`'s walk (it is already scoped — the caller
  passes `.context/audits`; there is nothing to fix); adding it to an exemption list (an
  exemption for a file that is correct); stripping every string constant (a real weakening —
  `subprocess.run("...", shell=True)` is a call whose command lives in a string).

### 2026-08-18 — residual limit, recorded rather than absorbed

The census strips `#` comments (T-533) and docstrings (T-558). It does **not** strip a string
literal assigned to a variable or passed as an argument. This was found the hard way: the
first draft of `_t558-hermeticity-census-teeth.py` embedded its mutant sources as literals and
became the corpus's one WHOLE-TREE finding, and a later draft did it again with a single
backticked phrase inside a failure message. Both were reworded rather than fixed in the
census, because the alternative — stripping all string constants — would lose the
`shell=True` case. So the fixture bends and the gate does not. The limit stands: a future
fixture carrying both a call pattern and a `before`/`after` comparison inside an assigned
literal will be misclassified the same way, and nothing yet detects that. Same family as
OBS-292 and PL-148; not filed as a separate observation because it is a known and now-written
property of one instrument rather than a new class.

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

### 2026-08-19T23:32:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-558-bridge-suite-went-red-in-one-session-and.md
- **Context:** Initial task creation
