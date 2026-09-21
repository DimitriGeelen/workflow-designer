---
id: T-732
name: "Drain the H-register: four open operator rulings are the only Arc-0 exit path on our side of the fence"
description: >
  Clause 3 is the sole Arc-0 exit clause not owned by AEF. It is gated on operator-decisions.yaml, where H1/H3/H5/H6 are open and each blocks_arc_0_exit. H3, H5 and H6 already carry prepared agent recommendations and measured evidence; H1 is a strategic ruling governing four hv-lc tasks (T-279/280/281/282). Clause 3 additionally needs definition_ratified via T-596's Human AC. Assemble one decision dossier so all four can be ruled in a single sitting, and surface it to /approvals.

status: started-work
workflow_type: build
owner: human
horizon: now
tags: [arc-002, ewcr, arc-0-exit, h-register]
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T18:48:54Z
last_update: 2026-09-21T14:08:43Z
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

# T-732: Drain the H-register: four open operator rulings are the only Arc-0 exit path on our side of the fence

## Context

The EWCR Arc-0 exit gate has three clauses (`docs/research/executable-workflow/arc-0-exit-clauses.yaml`).
**Two are counterparty-owned and neither can be moved from this side:**

- **clause-1** (topology non-empty and validated) — AEF answered on 2026-08-27 (rail offset 650,
  thread T-3127) and the answer is **red on their own numbers**: 1134 cards, 52 edgeless,
  749 outside any watch pattern. They explicitly declined to attest: *"I would rather hand you
  a red number I trust than a green one neither of us can reproduce."* `attestation: null`.
- **clause-2** (contract/refusal matrix complete) — the artifact does not exist in this
  repository and was never the Designer side's to build. `attestation: null`.

**clause-3 is the one on our side of the fence**, and it is `method: local-register`. It is
satisfied when every question in `operator-decisions.yaml` carrying `blocks_arc_0_exit: true`
reaches `status: resolved`. Measured 2026-09-16: **H2 and H4 resolved, H1/H3/H5/H6 open.**

**Correction to this task's own title, found while assembling the dossier.** The title says these
four rulings are "the only Arc-0 exit path on our side of the fence." Three of them are. **H6 is
not:** the register's own recommendation states it *"resolves when AEF answers and the operator
accepts the answer"* — so H6 is partly counterparty-blocked through R6/R7, which is the same
object as clause 2. The operator can rule today that routing was correct and the §2.3 boundary
held; that does not close H6. The title is left standing rather than rewritten, and corrected
here, because a task that quietly repairs its own overclaim leaves no trace that the overclaim
was made.

Nothing in arc-002 currently holds this work. T-596 built the register and closed; T-620 routed
R6/R7 and closed. The four open questions have been sitting with prepared recommendations and no
task to carry them to a ruling — which is why the arc reads as "22 of 23 complete" while its exit
gate stands at **0 of 3 clauses satisfied**.

Two of the four recommendations are **superseded by their own later observations** (H3: there are
now three correlation identifiers in use, not two; H6: transport completed but §2.3 holds that
transport is not collaboration completion). A dossier that presented the original recommendation
without its supersession would route the operator to an answer the file itself already retracted.

**Deliberately out of scope:** filing tasks for roadmap Arcs 1/3/5/6. T-681's GO — the operator's
own ruling of 2026-09-05 — recommends **against** opening them: *"decomposing work whose inputs
are counterparty-blocked manufactures a backlog that measures as progress and cannot move."*
Adding them would contradict a standing decision, not add scope.

Sources: `arc-0-exit-clauses.yaml`, `operator-decisions.yaml`, `.tasks/active/T-681-*.md` §Recommendation.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `docs/reports/T-732-h-register-dossier.md` exists and carries one `## H<N>` section for **every** question in `operator-decisions.yaml` whose `status: open` — derived from the register at verification time, not hard-coded, so a question opened later makes the gate red
- [x] Each section quotes the question verbatim, the recorded `agent_recommendation` verbatim (PL-323 — never paraphrase), and the evidence already on file
- [x] Each section states explicitly whether the recorded recommendation is **ratifiable as written** or **superseded** — H3 and H6 both carry superseding observations that contradict their own earlier recommendation, and a dossier that hid that would route the operator to a stale answer
- [x] The `/approvals` URL is printed to the operator

### Human
- [ ] [REVIEW] Rule H1 — do roadmap Arcs 4–6 supersede the standing DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO?
  **Steps:**
  1. `cd /opt/832-Workflow-designer && cat docs/reports/T-732-h-register-dossier.md`
  2. Open http://192.168.10.107:3013/approvals
  3. Record the ruling against H1
  **Expected:** `operator-decisions.yaml` H1 carries `status: resolved` and a `source_of_truth`
  **If not:** the four tasks named above stay parked at a flat BVP 126 with nothing distinguishing them

- [ ] [RUBBER-STAMP] Rule H3 — ratify the correlation identifiers. **Note: the filed recommendation is superseded.** It says "the two values already in use"; there are now three, the third (`EWCR-ARC0-ATTEST-832`) minted by an agent on the rail and adopted by repetition.
  **Steps:** read §H3 of the dossier, then record which identifiers are authoritative
  **Expected:** H3 `status: resolved`, naming the identifier set explicitly
  **If not:** an unratified value keeps accruing the appearance of a decision through repetition

- [ ] [RUBBER-STAMP] Rule H5 — reconcile the four disclosed governance deviations in `reflection-designer.md` §9. Agent evidence already measured 2026-08-27: T-587's hand-written file is conforming against the inception template.
  **Expected:** H5 `status: resolved`
  **If not:** disclosure stands in for reconciliation indefinitely

- [ ] [REVIEW] Rule H6 — was the R6/R7 routing correct and was the §2.3 boundary held? Transport is done (offset 643); §2.3 says transport is **not** collaboration completion, so this does not self-resolve.
  **Expected:** H6 `status: resolved`
  **If not:** Arc-0 clause 3 cannot reach `satisfied` even if H1/H3/H5 are ruled

- [ ] [REVIEW] Tick T-596's Human AC to set `definition_ratified: true` on clause 3 — without it the clause refuses to be satisfiable at all, and all four rulings above buy nothing

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
# The dossier must cover every question the register currently reports open. The open set is
# DERIVED from the register at gate time rather than hard-coded, so a question re-opened after
# this task was written turns the gate red instead of passing on a stale list.
python3 -c 'import yaml,re,sys;d=yaml.safe_load(open("docs/research/executable-workflow/operator-decisions.yaml"));op=[q["id"] for q in d["questions"] if q.get("status")=="open" and q.get("blocks_arc_0_exit")];t=open("docs/reports/T-732-h-register-dossier.md").read();miss=[i for i in op if not re.search(r"^## "+re.escape(i)+r"\b",t,re.M)];print("open:",op,"| missing sections:",miss);sys.exit(1 if miss else 0)'
# Supersession must be stated, not implied. H3 and H6 each carry a superseding observation in
# the register; the dossier is red if it names neither.
grep -qi "supersed" docs/reports/T-732-h-register-dossier.md

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
     fw inception decide T-732 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T18:48:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-732-drain-the-h-register-four-open-operator-.md
- **Context:** Initial task creation

### 2026-09-21T14:08:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
