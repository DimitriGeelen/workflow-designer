---
id: T-189
name: "IW-9: v1.1 mapping-standard delta — collapse triple-encoded authority (Lane=who, workflow_type=kind, remove node owner-override)"
description: >
  AEF IW-9 design finding (T-2523). Node-level owner duplicates the lane; collapse to two orthogonal axes. v1.1 delta to FROZEN v1 mapping standard — needs operator sign-off. Agent can draft the delta on GO.

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
created: 2026-07-11T16:56:45Z
last_update: 2026-08-01T23:50:53Z
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

# T-189: IW-9: v1.1 mapping-standard delta — collapse triple-encoded authority (Lane=who, workflow_type=kind, remove node owner-override)

## Context

AEF design finding IW-9 (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, offset 20): authority
is triple-encoded across `workflow_type ⊕ Lane ⊕ owner`, which can disagree with no
reconciliation rule. 832-side BPMN read (offset 24): the genuinely redundant carrier is the
node-level `owner` override — BPMN already gives Lane = who-performs and task-type
(userTask vs service/scriptTask) = human-vs-agent execution. Proposed v1.1 delta: two
orthogonal axes only — **Lane = authority-of-record for who-performs** (owner:human|agent ⇔
two lanes, per IW-7); **workflow_type = kind-of-work** (inception=decision vs
build/test/refactor=execution, intrinsic to type); **node-level `owner` override REMOVED**
(a node's owner is its lane, full stop). Zero redundant third encoding, no three-way drift.

**AEF operator RATIFIED this framing** (offset 25, 2026-07-11): "framings ratified as sent —
take them up when you're back." That clears the AEF side. **832-side graduation still needs
Dimitri's sign-off** — this is a v1.1 delta to the FROZEN v1 mapping standard
(`docs/standards/aef-bpmn-mapping-v1.md`), so it requires the standard's governance + operator
sign-off and stacks with the child-1 Part II provisional items already awaiting his ruling.
Agent may draft the delta on operator GO; agent must NOT unilaterally edit frozen v1.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] v1.1 authority-collapse delta is drafted as a PROPOSAL document at `docs/reports/T-189-iw9-authority-collapse-delta.md` — the FROZEN v1 standard (`docs/standards/aef-bpmn-mapping-v1.md`) is NOT edited under agent control
- [x] The proposal specifies exact before→after textual changes to BOTH standards IW-9 touches — `aef-bpmn-mapping-v1.md` §2/§3 and `aef-bpmn-forward-compile-v1.md` §2/§3.1/§3.2/§5.1 (its §8 anticipates a v1.1 of both) — realizing: Lane authority (4-valued `aef:laneMeta authority`) = sole who-performs carrier; workflow_type = kind-of-work; node-level `owner` override REMOVED
- [x] The proposal states the graduation blast-radius across both test paths (`tests/test_mapping_standard_conformance.py` and `tests/test_forward_fixtures.py`, plus editor/bridge `metaKeys`/`META_KEYS`) — both verified conformance-safe/green as written, so the version bump is scoped before it happens
- [x] Open sub-questions that genuinely need an operator ruling (e.g. lane-vs-task-type tiebreak when a serviceTask sits in a human lane) are enumerated rather than silently resolved
- [x] Proposal document is referenced from this task and AEF is informed on the DM rail that the 832-side delta is drafted and awaiting Dimitri's sign-off (rail offset 27)

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
- [ ] [REVIEW] Operator sign-off to graduate the IW-9 delta into the FROZEN v1 standard (v1 → v1.1)
  **Steps:**
  1. Read the drafted delta: `docs/reports/T-189-iw9-authority-collapse-delta.md` (exact before→after changes to `docs/standards/aef-bpmn-mapping-v1.md` §2/§3, plus graduation blast-radius on the conformance test)
  2. Rule on the enumerated open sub-questions (esp. the lane-vs-task-type tiebreak) — the delta cannot be finalized until these are decided
  3. If GO: authorize the agent to graduate — apply the §2/§3 edits to frozen v1, bump to v1.1, and update `tests/test_mapping_standard_conformance.py` to match — then run the conformance suite green and complete this task. If NO-GO/refine: annotate the delta and hand back.
  **Expected:** A recorded GO/refine/NO-GO decision on the delta; on GO, explicit authorization to edit the frozen standard (that edit is gated on this sign-off — see Context)
  **If not:** The delta stays a proposal; frozen v1 is untouched and this task holds in partial-complete

## Verification

# Delta proposal exists and carries the exact-change and blast-radius content
test -f docs/reports/T-189-iw9-authority-collapse-delta.md
grep -q "conformance-governance-meta-keys" docs/reports/T-189-iw9-authority-collapse-delta.md
# Standard↔implementation conformance MUST be green — both before graduation and
# after (the delta is written to stay green: removing owner from the frozen fence
# keeps frozen ⊆ editor/bridge — see proposal §4.1).
python3 tests/test_mapping_standard_conformance.py

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

## v1.1 items accumulated after the proposal was written (2026-08-02)

Recorded here rather than left on the AEF rail, where they are invisible to the
operator ruling this task. Each is a DISTINCT item; none is prejudged.

**(1) The authority-owner question — and a scope error in a ratification we
co-own.** Our `AUTHORITY_OWNER` maps `authority` → **agent**; AEF's T-2717 maps
it → **no owner**. AEF measured the separating case (rail 375) by flipping a
`serviceTask` to `userTask` in a Framework lane:

| | owner | warning |
|---|---|---|
| AEF | **human** | none |
| 832 | agent | `W-TYPE-LANE-MISMATCH` fires |

So on their side a Framework lane yields a HUMAN-owned task — the inverse of
what the lane means — and nothing warns, for two independent reasons: their O-1
mismatch check sits inside `if lane_owner is not None` (a no-owner authority
SKIPS the branch rather than satisfying it), and the name-based fallback matches
none of their owner tokens, so the owner comes from the node type.

The part that is OURS: the agent-fallback ratified on rail 95 carries the
sentence "the executor is still the agent; what's lost is provenance". Measured
by AEF: true for `serviceTask` and `scriptTask`, **FALSE for `userTask`**. The
ratified sentence generalised over three node types after two were checked. The
mapping was not wrong; the PROSE describing its scope was — the same shape as a
table answerable only to itself, applied to a comment. v1.1 should state the
scope the ratification was actually measured over.

FLIP CONDITION, measured both sides: **0 `userTask`-in-authority-lane nodes
across our 174 documents and their 31.** Live and unfired, not agreed. AEF has
this open as OBS-119 and will not act unilaterally — it waits on this ruling.

**(2) Documentation carrier.** `<bpmn:documentation>` is not merely unused: it
is UNEMITTABLE — 0 occurrences across 175 `.bpmn`, and 0 in the designer export,
`yaml-to-bpmn.py` or `bpmn-to-yaml.py`. `aef:meta note` carries 100% of the
explanatory load on both sides. Recommendation into this batch: carry BOTH with
a stated precedence, NOT migration — migration pays a portability gain with an
immediate legibility loss on every existing note until re-authored. AEF backs
this shape and will not move the carrier unilaterally.

**(3) Audience of the note field.** One field silently picks a reader, and today
it has picked the implementer. If v1.1 admits an audience-tagged pair it should
also state what makes the pair answerable to something outside itself; the
admission test AEF has adopted is that the newcomer note MUST NOT be derivable
by truncating the implementer note. Absent such a test, one field with its
audience DECLARED is the more honest artifact.

Carried separately from the §1 carrier-class hole and the lane-geometry origin
item already in this batch.

### Item 6 — `authority: none`, and a lane axis that is not the actor axis (T-331)

**The question for you:** may a lane axis mean something other than *who
performs*? IW-9 says no by construction. Our own corpus says yes in one map.

**Measured, not argued.** `authority: none` is accepted by
`AUTHORITIES` (validate-workflow.py:62) and defined in
`docs/designer/schema.md:380` as "pool-level lanes that don't carry authority
semantics". It appears in **no collapse map in the frozen standard** — §3 names
four outcomes (`sovereignty→human`, `initiative→agent`, `authority→agent`,
`external→no task`) and the vocabulary has five members.

**Where it bites.** `examples/aef-processes/context-memory.workflow.yaml` lanes
its nodes by *memory type* — Working / Project / Episodic — so all three lanes
carry `authority: none` and hold **7 task nodes with no derivable owner**:

| lane | authority | task nodes |
|---|---|---|
| Working Memory · session-local | `none` | 2 |
| Project Memory · durable cross-task | `none` | 4 |
| Episodic Memory · completed histories | `none` | 1 |

This is not a modelling slip to be corrected — the map is legible and the axis
is deliberate. It is a **counterexample to the ratified collapse**, and it ships
to AEF in `build/aef-corpus-drop/`.

**Why it is urgent rather than academic.** AEF's compiler (their OBS-120, rail
377) resolves a lane that yields no owner via `owner = type_owner or "agent"`,
**silently**. So these 7 nodes acquire `owner: agent` downstream — a value no
table on either side ever granted them.

**The options, none of them taken here:**
1. Widen the collapse map: give `none` a stated outcome (`no task`, like
   `external`? or `agent`?). Cheapest, and it decides by fiat what the lane
   meant.
2. Narrow the vocabulary: drop `none` from `AUTHORITIES`, forcing every lane to
   be an actor lane, and re-lane `context-memory`. Preserves IW-9 exactly;
   costs a legitimate way of drawing a map.
3. Admit a second lane axis in v1.1 — lanes carry `authority` OR a declared
   non-actor role, with node ownership sourced elsewhere for the latter. Most
   expressive, largest delta, and it reopens "the lane is the sole
   authority-of-record".

**What was built instead (T-331):** `W-LANE-NO-OWNER` now *reports* the
condition on both forms, and the collapse map is a total explicit partition of
`AUTHORITIES` so a sixth value cannot be admitted without stating its outcome.
The 7 warnings are declared in `tests/run-bridge-tests.sh` citing this item, and
that declaration fails if the count moves or the map goes clean. **The finding
is instrumented; the ruling is yours.**

## Recommendation

**Recommendation:** GO
**Rationale:** The delta proposal is complete and decision-ready: exact before→after text for BOTH touched standards, graduation blast-radius enumerated, and the FROZEN v1 standard untouched under agent control (the sovereignty boundary held). GO here means "ready for your ruling" — the ruling itself (graduate v1→v1.1, incl. the lane-vs-task-type tiebreak) is yours and is not prejudged.
**Evidence:**
- Proposal at `docs/reports/T-189-iw9-authority-collapse-delta.md` (15KB, all 5 Agent ACs checked)
- `docs/standards/aef-bpmn-mapping-v1.md` unedited (frozen-standard discipline)
- Blast radius across `test_mapping_standard_conformance.py` + `test_forward_fixtures.py` stated in the proposal

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

### 2026-07-11T16:56:45Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-189-iw-9-v11-mapping-standard-delta--collaps.md
- **Context:** Initial task creation

### 2026-07-11T21:38:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-85f8e8ca
- **Timestamp:** 2026-07-29T13:13:42Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#3 (Agent)** — The proposal states the graduation blast-radius across both test paths (`tests/test_mapping_standard_conformance.py` and `tests/test_forward_fixtures.py`, plus editor/bridge `metaKeys`/`META_KEYS`) — 
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/test_forward_fixtures.py in: The proposal states the graduation blast-radius across both test paths (`tests/test_mapping_standard_conformance.py` and `tests/test_forward_fixtures.`
