---
id: T-670
name: "EWCR has no arc: fourteen tasks and three exit clauses with no arc to hold them"
description: >
  The EWCR work (T-590..T-620, fourteen tasks) is not tagged to any arc. arc-001 covers the designer authoring surface only. Establish the EWCR arc, bring existing EWCR tasks under it, evaluate whether the roadmap's Arc-0 scope is fully covered by tasks, and file whatever scope has no task.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-03T05:17:04Z
last_update: 2026-09-05T10:56:45Z
date_finished: 2026-09-05T10:56:45Z
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

# T-670: EWCR has no arc: fourteen tasks and three exit clauses with no arc to hold them

## Context

arc-002 `ewcr-governed-delivery` created (draft), anchor T-590, eleven tasks tagged.
Membership decided by reading names: T-609 and T-660 mention EWCR but are not part of it.

### Arc-0 scope coverage — roadmap §4 "Candidate tasks" mapped to owner and task

Ownership from roadmap §2.1: **AEF owns** runtime schemas, invariants, refusal matrix,
task/evidence contracts, AEF topology. **We own** inventory visual/mapping schema, stable
IDs, import/export and round-trip constraints. **Joint**: version matrix, canonical IDs,
diagnostic shape, worked procedure fixture.

| # | Arc-0 candidate task | Owner | Carried by |
|---|---|---|---|
| 1 | Register/enrich Component Fabric, validate edges | **us** (our tree) / AEF (theirs) | **NOTHING — now T-671** |
| 2 | Freeze v1 schemas (procedure, instance, transition envelope, attempt, evidence ref, refusal, deadline) | AEF | no task here, correctly |
| 3 | Consolidated refusal/threat matrix (Claude, Z.ai, DeepSeek, Mistral) | AEF | requested via DM; AEF-owned |
| 4 | Pilot task lifecycle + task-state revalidation contract | AEF | T-619 carries only the Designer-side declaration |
| 5 | Evidence snapshot/hash ordering, compensation idempotency | AEF | no task here, correctly |
| 6 | Worked human-gate → registered-script → human-gate procedure | joint | **T-590, T-591 — done this side** |

### Exit clauses mapped

| Clause | Owner | State | Task |
|---|---|---|---|
| 1 topology non-empty and validated | aef | AEF **refused it on their own numbers** (rail @650: 1134 cards, enriched false, validated false, 749 outside any watch pattern). Their coverage criticism of us was ACCEPTED. | T-671 (our half) |
| 2 every blocker has disposition + testable scenario | aef | no attestation | T-610, T-620 requested it |
| 3 no source-of-truth ambiguity into Arc 1 | shared | unratified | T-596, T-597 record why it cannot be checked from here |

### The finding

**Five of the six Arc-0 candidate tasks are AEF-owned or joint, and our half of the joint
one is already done.** EWCR is not stalled on our capacity — it is stalled on counterparty
attestation, with four DMs sent and zero replies. Exactly **one** item is ours, uncovered,
and executable: the Component Fabric fence. That is now T-671, horizon `next`.

No further tasks were filed. Items 2, 3, 4 and 5 belong to AEF; filing agent tasks for work
this side cannot execute would manufacture queue depth without moving the arc, which is what
AC 4 forbids.

### AC 2 cannot be ticked — `fw arc tag` does not write what its own help calls the source of truth

`fw arc --help` states: *"Legacy: also appends to arc's constituent_tasks: if present
(T-1851 deprecation). Source-of-truth is task-side `arc_id:` (T-1849)."* But `fw arc tag`
writes **only** `tags: [… arc:ewcr-governed-delivery]`; every one of the eleven tasks still
has `arc_id:` commented out. So the field the CLI names as authoritative is the one field it
does not set, while the audit separately carries a check named *"No inline `arc:<slug>`
tag-only scans outside canonical lib (T-1881)"* — i.e. the mechanism actually used is the one
being deprecated.

`fw arc show` resolves membership anyway, because it reads the tag. That is exactly what makes
this the hand-maintained-claim shape again: the display agrees with the intent, so nothing
reddens, and the divergence between the documented source of truth and the written one is
visible only to someone who opens a task file. Left unticked and unfixed here — writing
`arc_id:` by hand across eleven tasks would paper over a CLI defect with hand-maintained data,
which is the wrong direction. Filed as a finding for the framework, not patched in the corpus.

**Overlap noted, not resolved:** T-501 and T-564 (load-time id normalisation) carry the
"stable IDs" surface that Arc-0 §2.1 assigns to us, but they are tagged `arc-001` where they
also legitimately belong. A task holds one arc, so they were left where they are rather than
moved to inflate arc-002's membership.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] An arc exists for EWCR with a headline mechanic stating a **user-observable**
      deliverable — an operator doing a thing and getting a governed result — not a
      substrate description. `fw arc show` resolves it and `fw arc list` prints it.
- [x] Every existing EWCR task carries `arc_id:` pointing at that arc, verified by
      counting tasks whose body mentions EWCR against tasks tagged to the arc. The two
      numbers are reported even when they differ; a silent subset would recreate the
      problem this task exists to fix one level down.
      **Done 2026-09-05. The numbers differ in BOTH directions, and neither is the
      membership count — see `## AC2 measurement` below.**
- [x] The arc's scope is checked against `docs/research/executable-workflow/roadmap-5be23719.md`
      **Arc-0** and the three clauses in `arc-0-exit-clauses.yaml`, and each clause is
      mapped to the task(s) that carry it — or recorded as carried by no task, which is
      the finding.
- [x] Scope with no task is **filed as tasks**, one deliverable each per the sizing rules.
      Scope that is counterparty-owned (AEF) or operator-owned is recorded as such rather
      than filed as agent work — filing a task for something we cannot execute manufactures
      queue depth without moving the arc.
- [x] The arc is left in `draft` unless the roadmap's own entry condition for Arc-0 is met.
      `fw arc start` is a state claim about readiness; making it to tidy the display would
      be the same class of error as ticking an AC to clear a queue.

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
         1. Run `bin/fw reviewer T-670`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-670 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## AC2 measurement — 2026-09-05

**The two counts, as the AC demands, reported before they were reconciled:**

| | count |
|---|---|
| tasks whose body mentions `EWCR` | **15** |
| tasks in arc `ewcr-governed-delivery` | **12** |
| union of `EWCR` + `Arc-0` + `executable-workflow` mentions | **20** |
| arc membership after reconciliation | **16** |

**The keyword scan is wrong in both directions, which is the finding.** The AC anticipated
a difference; it turned out not to be a subset relation at all.

*Mentions that are not membership* (4). `T-609` (review cards drop Steps/Expected —
one prose line: "EWCR question is settled when it may not be"), `T-660` (gate-green vs
operator-actionable — cites EWCR as evidence of queue drainage), `T-669` (absence-assertion
ratchet — "EWCR was made the priority mid-session"), `T-673` (audit remediation — cites
Arc-0 cards as an instance of a tree-wide condition). Each is *about* something else and
mentions EWCR while making its point. This is the mention-is-not-invocation class T-669 is
itself named for, which is a pleasing place to find it.

*Membership that is not a mention* (1). `T-596` — "Arc-0 exit gate is uncheckable" — is
squarely EWCR work and never spells the acronym. A grep for `EWCR` under-counts as readily
as it over-counts; widening to `Arc-0` / `executable-workflow` raised the mention set from
15 to 20 and still needed judgement on all five newcomers.

*Added after judgement* (4): `T-587` (ingest the AEF executable workflow-contract source
packet), `T-608` (draft the Arc-0 clause 1+2 attestation request — the other half of
`T-610`, which was already a member), `T-623` (AEF answered clause 1 red), `T-670` (this
task; establishing the arc is arc scope).

**Then the AC's literal wording bit, and correctly.** It says every EWCR task *carries
`arc_id:`* — not "is in the arc". Twelve of the sixteen recorded membership only in the
legacy `tags: [arc:...]` form, so they were arc members by the union reader and carried no
canonical field at all. `fw arc tag` could not have upgraded them this morning; T-467 taught
it to, and T-679 taught it to do so without destroying anything on the way.

**Final: 14 of 16 carry a live `arc_id:`.** The two that do not are the honest residue.

### Operator decision: T-611 and T-620 belong to two arcs

Both carry `tags: [arc:designer-authoring-surface, arc:ewcr-governed-delivery]`. The legacy
tag form is a list and permitted dual membership; `arc_id:` is single-valued and cannot
represent it. Writing the field would silently drop one of the two, so `fw arc tag` refuses
(T-679) and names both arcs.

This is a scope decision, not a defect. Both readings are defensible — Arc 4
diagram-Fabric navigation (T-611) and the Arc-0 landing (T-620) are EWCR deliverables that
land *on the designer surface*. **Left for the operator.** Recording it here rather than
resolving it is the point of the AC's "a silent subset would recreate the problem this task
exists to fix one level down": collapsing them quietly is exactly that problem.

Nothing is broken meanwhile — every reader unions both forms, so both tasks remain visible
in both arcs today.

## Verification

# The arc resolves and holds the four tasks added by judgement in AC2.
.agentic-framework/bin/fw arc show ewcr-governed-delivery > /tmp/.t670-arc.out 2>&1 && grep -qE '^  T-587' /tmp/.t670-arc.out && grep -qE '^  T-608' /tmp/.t670-arc.out && grep -qE '^  T-623' /tmp/.t670-arc.out && grep -qE '^  T-670' /tmp/.t670-arc.out
# At least 14 tasks carry a live arc_id: for this arc, counted from FRONTMATTER only —
# a document-wide grep would count the prose in this very file, which is the defect class
# the whole task pair is about.
python3 -c "import glob,re,sys;ps=glob.glob('.tasks/active/T-*.md')+glob.glob('.tasks/completed/T-*.md');ms=[re.match(r'^---\n(.*?\n)---\n',open(p,errors='replace').read(),re.S) for p in ps];n=sum(1 for m in ms if m and re.search(r'^arc_id:[ \t]*ewcr-governed-delivery',m.group(1),re.M));print(n);sys.exit(0 if n>=14 else 1)"
# The verb that wrote them still refuses to destroy membership (T-467 + T-679).
python3 tools/_t467-arc-tag-source-of-truth.py

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

### 2026-09-05 — AC2 could not be executed by the command that exists to execute it

- **What changed:** AC2 says every EWCR task must *carry `arc_id:`*. At filing this read as
  a bookkeeping step. It was not executable at all: `fw arc tag` — the documented way to
  record membership — wrote the T-1851-deprecated `tags: [arc:<slug>]` and never `arc_id:`,
  and *nothing in the framework wrote that field anywhere*. The only route to the canonical
  field was hand-editing frontmatter. AC2 was blocked on a defect nobody had connected to
  it, filed separately as T-467 three weeks earlier.
- **Plan impact:** AC2 stopped being bookkeeping and became "fix the writer first". T-467
  landed (`78cf7d75`), and running it end-to-end on the real corpus immediately produced a
  second defect (T-679, `97d399b2`): the new reassignment guard read only `arc_id:` while
  every reader unions `arc_id:` with the legacy tag, so 26 legacy-tag-only tasks could be
  silently reassigned. T-590 was reassigned by my own probe and reverted.
- **Triggered:** T-467 (fixed, landed), T-679 (filed and fixed in the same session), plus
  an operator decision recorded under `## AC2 measurement` — T-611 and T-620 carry two arc
  tags each and single-valued `arc_id:` cannot represent dual membership.

### 2026-09-05 — a keyword scan is not a membership test, in both directions

- **What changed:** AC2 prescribed comparing "tasks whose body mentions EWCR" against arc
  members, expecting a subset. It is not a subset relation. Four tasks mention EWCR while
  being about something else (`T-609`, `T-660`, `T-669`, `T-673`), and one member never
  spells the acronym at all (`T-596`, which says "Arc-0"). Widening the scan to
  `Arc-0`/`executable-workflow` raised mentions from 15 to 20 and still required judgement
  on every newcomer.
- **Plan impact:** the AC's own instrument needed the finding the AC was written to prevent.
  Reporting both numbers — which the AC did demand — was the part that held up; treating
  either as the membership count would not have.
- **Triggered:** no new task. The discrimination is recorded in `## AC2 measurement` and the
  class already has a name in this tree (T-669, mention-is-not-invocation).

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
     fw inception decide T-670 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-03T05:17:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-670-ewcr-has-no-arc-fourteen-tasks-and-three.md
- **Context:** Initial task creation

### 2026-09-03 — the AEF seam was never silent; we were writing to the wrong mailbox

**Five DMs on `dm:3bba15e681b3a078:d1993c2c3ec44c94` went to 010-termlink, not 999-AEF.**

`session.discover` resolves `3bba15e681b3a078` to `framework-agent-systemd` —
`cwd=/opt/termlink`, `tags project=termlink`, uid 0. That is termlink's systemd unit.
Our own DM at offset 7 **quoted that exact field** and still concluded *"this mailbox is
addressed correctly and is live by heartbeat, but no agent process is consuming it."*
The refutation was inside the sentence that drew the wrong conclusion; `project=termlink`
was read as context rather than as the answer.

**AEF was reachable the entire time, on our own hub.** They post to `agent-chat-arc` from
.107 — the same hub whose log we read. Verified rather than assumed: `@650` on OUR log is
their Clause 1 refusal in full, and `@651` says *"Measured here … from .107"*. Their last
rail post is **`@806`, 2026-08-29** — active until five days ago, never silent since the
27th as the DM thread implied.

**Not to be confused with the federation defect filed the same day.** ring20-management
(fp `9219671e28054458`) reports `agent-chat-arc` does not replicate .122 ↔ .107 — their
max offset 3715 against our 1030, disjoint logs at the same numbers. That is real, and it
is explicitly routed to 010-termlink's queue, not ours. It does **not** touch this seam:
AEF and 832 are co-resident on .107, so no federation is involved. Recording both together
because either could otherwise be used to explain away the other.

**Acted on:** posted the Arc-0 update to `agent-chat-arc @1031` with the routing correction
first — the path where the peer's posts demonstrably land on our own log. Captured as
**PL-310**.

**What this does NOT change:** clause 1 remains AEF's refusal on AEF's numbers, recorded as
refused and never as satisfied; `definition_ratified:` stays false on all three clauses; and
per roadmap §2.3 a delivered post is transport evidence, not collaboration completion. The
correction fixes who hears us, not what has been agreed.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-dc06afbb
- **Timestamp:** 2026-09-05T10:56:48Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-05T10:56:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
