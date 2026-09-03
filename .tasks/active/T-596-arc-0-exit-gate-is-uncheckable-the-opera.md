---
id: T-596
name: "Arc-0 exit gate is uncheckable: the operator decisions it depends on have no register and no status"
description: >
  Arc-0 exit gate is uncheckable: the operator decisions it depends on have no register and no status

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [arc:ewcr-governed-delivery]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T15:28:58Z
last_update: 2026-09-03T05:18:34Z
date_finished: 2026-08-26T15:34:41Z
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

# T-596: Arc-0 exit gate is uncheckable: the operator decisions it depends on have no register and no status

## Context

The Arc-0 exit gate in `docs/research/executable-workflow/roadmap-5be23719.md:147`
reads: *"topology is non-empty and validated; every blocker finding has a contract
disposition and testable scenario; **no unresolved source-of-truth ambiguity enters
Arc 1**."*

The source-of-truth ambiguities are the six operator decisions H1–H6, and they exist
in exactly one place: a **prose table** at `reflection-designer.md:201-208`. That table
has no status column, no decision record, no source of truth, and nothing reads it.

So the third clause of the Arc-0 exit gate cannot be evaluated by anyone — agent or
operator. This is the week's recurring shape again: **a stated property standing in for
a checked one**. H2 was answered and recorded in the handoff envelope (T-595); nothing
propagated that to a place where "is Arc 0 done?" could be asked. H4 was decided on
T-587 and is likewise invisible.

This task builds the register and the gate. It does **not** answer any open question —
recording an operator decision is not making one.

**Design property (PL-148):** the register must not be able to self-certify. Any entry
claiming `status: resolved` has to name an EXTERNAL `source_of_truth` that independently
carries the resolution, and the gate cross-checks that the two agree. A register that
could mark itself resolved would be the same defect T-593 removed from the envelope.

## Acceptance Criteria

### Agent
- [x] `docs/research/executable-workflow/operator-decisions.yaml` exists, parses as YAML,
      and carries exactly the six questions H1–H6 with `question` text traceable to the
      table at `reflection-designer.md:201-208`
- [x] No entry anywhere in the register carries `decided_by: agent` — the agent may fill
      `agent_recommendation`, never a decision
- [x] Every `status: resolved` entry names a `source_of_truth` whose file EXISTS on disk
      and which independently carries the resolution; the register cannot self-certify (PL-148)
- [x] H2's register entry and the envelope's `to_project_resolution` AGREE on `chosen` and
      `decided_by`, checked by a command that reads both files — divergence is red
- [x] `tools/_t596-arc0-exit-gate.sh` evaluates the Arc-0 exit gate clause by clause, names
      every still-open question by id, and exits non-zero while any blocking question is open
- [x] The gate is proven non-inert in BOTH directions by `--self-test`: the real register
      passes the accept path, and four poison arms each go red — (a) resolved with no
      `source_of_truth`, (b) `source_of_truth` file absent, (c) register/envelope disagree on
      `chosen`, (d) `decided_by: agent`
- [x] H1 and H3 are recorded as **open** with their operative state noted, not as resolved:
      T-587's GO decided the scope of one slice, which is not the same act as answering
      whether Arcs 4–6 supersede the standing DEFERs; and a correlation being in de-facto
      use in T-590 is not a ratification of it

### Human

- [ ] [REVIEW] Confirm the register reads H1 and H3 correctly as **open**, not as already answered

  **Steps:**
  1. Run: `cd /opt/832-Workflow-designer && cat docs/research/executable-workflow/operator-decisions.yaml`
  2. Read the `H1` entry. The agent recorded it as **open**. The reasoning: your GO on
     T-587 approved the scope of one narrow Arc-0 slice and explicitly did not reverse the
     standing DEFERs (T-279/280/281/282) or AEF's T-2669 NO-GO. Deciding a slice's scope is
     not the same act as deciding whether Arcs 4-6 supersede those dispositions. If you
     consider H1 already answered by that GO, the agent has it wrong.
  3. Read the `H3` entry. Also **open**. The correlations `ewcr-v1` and
     `ewcr-v1-designer-fixture` are already in use in T-590 and in the handoff envelope,
     but nothing records that you assigned them. The agent treated in-use as NOT ratified.
  4. Run the gate: `cd /opt/832-Workflow-designer && tools/_t596-arc0-exit-gate.sh`

  **Expected:** The gate exits non-zero and prints `BLOCKED` for the third Arc-0 clause,
  listing the open question ids. With H1/H3/H5/H6 open, four ids should be named. Arc 1
  cannot start until they are answered — that is the gate doing its job, not a failure.

  **If not:** If you consider H1 or H3 already answered, say so and name the artifact that
  records it; the agent will set `status: resolved` with that artifact as `source_of_truth`.
  Do not edit the register to make the gate green — a resolution with no source is exactly
  the defect T-593 removed from the handoff envelope.

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
         1. Run `bin/fw reviewer T-596`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-596 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 -c "import yaml;yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml',encoding='utf-8'))"
tools/_t596-arc0-exit-gate.sh --self-test
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml',encoding='utf-8'));ids=[q['id'] for q in d['questions']];assert ids==['H1','H2','H3','H4','H5','H6'],ids"
python3 -c "s=open('docs/research/executable-workflow/reflection-designer.md',encoding='utf-8').read();missing=[h for h in ['H1','H2','H3','H4','H5','H6'] if ('| '+h+' |') not in s];assert not missing,missing"
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml',encoding='utf-8'));bad=[q['id'] for q in d['questions'] if q.get('decided_by')=='agent'];assert not bad,bad"
python3 -c "import yaml;r=yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml',encoding='utf-8'));e=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml',encoding='utf-8'))['to_project_resolution'];h=[q for q in r['questions'] if q['id']=='H2'][0];assert h['chosen']==e['chosen'],(h['chosen'],e['chosen']);assert h['decided_by']==e['decided_by']=='operator'"
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/operator-decisions.yaml',encoding='utf-8'));bad=[q['id'] for q in d['questions'] if q['status']=='open' and len(q.get('operative_state') or '')<80];assert not bad,bad"

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

**Symptom:** "Is Arc 0 finished?" had no answer. The exit gate's third clause —
*no unresolved source-of-truth ambiguity enters Arc 1* — referred to six operator
decisions that existed only as rows in a markdown table.

**Root cause:** the questions were written down in a form that records them but cannot
report on them. A prose table has no status, so the difference between *asked*,
*answered*, and *answered-and-checkable* is invisible in it. Two of the six had in fact
been decided — H2 by the operator in session (recorded in the handoff envelope under
T-595), H4 by a recorded inception GO on T-587 — and neither decision reached the place
where the exit gate would be evaluated. The gate was not blocked by missing decisions;
it was blocked by having no reader.

**Why structurally allowed:** an exit gate written as prose is indistinguishable from
one that has been satisfied. Nothing in the framework requires that a stated gate be
executable, so a roadmap can define a fence that no instrument can stand at. This is
the same shape as T-592 (verification legs that assert nothing), T-593 (a resolution
field with no source) and T-594 (a claim surviving in prose where the key-walker could
not see it): **a stated property standing in for a checked one, with the failure
rendering as health.**

**Prevention:** the register is now the reader, and `tools/_t596-arc0-exit-gate.sh`
is the instrument. Its `--self-test` proves it can fail — five poison arms, each
requiring exit code 2 specifically, so a gate that had gone blind cannot pass by being
red about the open questions that were already there. The self-certification rule
(PL-148) is what makes the register worth reading: an entry cannot assert its own
resolution, so the next fabricated decision has nowhere to land silently.

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

### 2026-08-26 — H1 and H3 recorded as open rather than resolved

- **Chose:** treat H1 and H3 as still open, with an `operative_state` describing what
  holds in the absence of a decision.
- **Why:** T-587's GO decided the scope of one slice. Its rationale explicitly names the
  absence of an H1 answer — *"without a superseding decision"* — so reading that GO as
  also answering H1 would manufacture a decision out of an adjacent one. H3 is the softer
  case and the more dangerous: `ewcr-v1` and `ewcr-v1-designer-fixture` are already in use
  in T-590 and the envelope, and repetition is how an unratified value comes to look
  decided. In-use is not ratified.
- **Rejected:** marking both resolved with T-587 as `source_of_truth`. It would have
  turned the gate green today and left two operator decisions permanently unmade.

### 2026-08-26 — exit code 2 for integrity, separate from exit code 1 for blocked

- **Chose:** three exit codes — 0 satisfied, 1 blocked-but-honest, 2 integrity violation.
- **Why:** the real register is red and will stay red until the operator answers four
  questions. If integrity failures also returned 1, every poison arm would "pass" simply
  because the gate was already red for an unrelated reason. The controls would have proven
  nothing. Separating the codes is what makes the poison arms discriminating.
- **Rejected:** a boolean pass/fail gate. It reads more simply and cannot be tested.

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

## Recommendation

**Recommendation:** GO — accept the register's reading that H1 and H3 are open.

**Rationale:** Two of the six questions are genuinely answered and now checkable: H2 by
your own words in session on 2026-08-26, H4 by your recorded GO on T-587. The other four
are not, and the temptation worth naming is H1 and H3, because each has something nearby
that resembles an answer. T-587's GO sits next to H1 — but its rationale names the gap
itself, *"without a superseding decision"*, so reading it as an answer would invent one.
H3 is the quieter risk: `ewcr-v1` and `ewcr-v1-designer-fixture` are already in use in
T-590 and in the envelope, and a value carried forward by repetition starts to look
decided without anyone deciding it.

The gate is red, and that is the correct output. Arc 1 should not start on four open
source-of-truth questions — which is exactly what the Arc-0 exit gate says, and until now
nothing could tell you whether it held.

**Evidence:**
- `tools/_t596-arc0-exit-gate.sh` → `BLOCKED by 4 open question(s)`; open H1, H3, H5, H6;
  resolved H2, H4 (exit 1 = blocked with integrity intact)
- `tools/_t596-arc0-exit-gate.sh --self-test` → 7/7, including five poison arms that must
  each return exit code 2 specifically: register self-certifies, source file absent,
  register contradicts envelope, agent recorded as decider, open question flipped to
  resolved without a source
- P-011: 7/7 legs pass. The register↔envelope agreement leg was poison-tested by hand —
  it failed with `('/opt/0503-codex-cli-playground', '/opt/999-Agentic-Engineering-Framework')`
  and recovered green on restore
- H2 source: `handoff-ewcr-v1-designer-fixture.yaml` `to_project_resolution` (T-595)
- H4 source: `.tasks/completed/T-587-…md` `## Decision` — GO, narrow Arc-0 slice only
- Clauses 1 and 2 of the Arc-0 exit gate remain **NOT-CHECKED**; they have no executable
  definition. A clause-3 pass would not mean Arc 0 is done, and the gate says so in its
  own output rather than leaving it to be inferred.

## Updates

### 2026-08-26T15:28:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-596-arc-0-exit-gate-is-uncheckable-the-opera.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0013e349
- **Timestamp:** 2026-08-26T15:34:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T15:34:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-09-03T05:18:34Z — status-update [task-update-agent]
- **Change:** tags: +arc:ewcr-governed-delivery
